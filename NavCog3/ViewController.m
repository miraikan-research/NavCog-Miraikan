/*******************************************************************************
 * Copyright (c) 2014, 2016  IBM Corporation, Carnegie Mellon University and others
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *******************************************************************************/

#import "ViewController.h"
#import "DefaultTTS.h"
#import "LocationEvent.h"
#import "NavDataStore.h"
#import "NavDebugHelper.h"
#import "NavDeviceTTS.h"
#import "NavUtil.h"
#import "RatingViewController.h"
#import "SettingViewController.h"
#import "SettingDataManager.h"
#import "ServerConfig.h"
#import <HLPLocationManager/HLPLocationManager.h>
#import <CoreMotion/CoreMotion.h>
#import <NavCogMiraikan-Swift.h>

typedef NS_ENUM(NSInteger, ViewState) {
    ViewStateMap,
    ViewStateSearch,
    ViewStateSearchDetail,
    ViewStateSearchSetting,
    ViewStateRouteConfirm,
    ViewStateNavigation,
    ViewStateTransition,
    ViewStateRouteCheck,
    ViewStateLoading,
};

@interface ViewController () {
    NavNavigator *navigator;

    UISwipeGestureRecognizer *recognizer;
    NSDictionary *uiState;
    DialogViewHelper *dialogHelper;
    UIButton *titleButton;
    NSDictionary *ratingInfo;
    NSArray *landmarks;
    
    NSTimeInterval lastLocationSent;
    NSTimeInterval lastOrientationSent;

    NSTimer *checkMapCenterTimer;
    NSTimer *checkStateTimer;

    long locationChangedTime;
    BOOL isNaviStarted;
    BOOL isRouteNavi;
    BOOL isSetupMap;
    BOOL isInitTarget;
    BOOL isSetupNavigation;
}

@end

@implementation ViewController {
    ViewState state;
    UIColor *defaultColor;
}

- (void)dealloc
{
    NSLog(@"%s: %d" , __func__, __LINE__);
}

- (void)prepareForDealloc
{
    [_webView triggerWebviewControl:HLPWebviewControlEndNavigation];

    _webView.delegate = nil;
    
    dialogHelper.delegate = nil;
    dialogHelper = nil;
    
    navigator.delegate = nil;
    navigator = nil;

    recognizer = nil;
    
    _settingButton = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    defaultColor = self.navigationController.navigationBar.barTintColor;
    
    isRouteNavi = YES;
    isNaviStarted = NO;
    state = ViewStateLoading;
    locationChangedTime = 0;
    lastLocationSent = 0;

    titleButton = [[UIButton alloc] init];
    [titleButton addTarget:self action:@selector(titleAction) forControlEvents:UIControlEventTouchUpInside];
    [titleButton setIsAccessibilityElement: false];
    [self setTitleButton:NSLocalizedStringFromTable(@"Miraikan", @"BlindView", @"")];
    self.navigationItem.titleView = titleButton;

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _webView = [[HLPWebView alloc] initWithFrame:CGRectMake(0,0,0,0) configuration:[[WKWebViewConfiguration alloc] init]];
    [self.view addSubview:_webView];
    BOOL devMode = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"developer_mode"]) {
        devMode = [ud boolForKey: @"developer_mode"];
    }
    _webView.isDeveloperMode = devMode;
    _webView.userMode = [ud stringForKey: @"user_mode"];
    _webView.config = @{
                        @"serverHost": [ud stringForKey: @"selected_hokoukukan_server"],
                        @"serverContext": [ud stringForKey: @"hokoukukan_server_context"],
                        @"usesHttps": @([ud boolForKey: @"https_connection"])
                        };
    _webView.delegate = self;
    _webView.tts = self;
    [_webView setFullScreenForView:self.view];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openMenu:)];
    recognizer.delegate = self;
    [self.webView addGestureRecognizer:recognizer];
    
    navigator = [[NavNavigator alloc] init];
    navigator.delegate = self;

    [NSNotificationCenter.defaultCenter removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestStartNavigation:) name:REQUEST_START_NAVIGATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiStateChanged:) name:WCUI_STATE_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dialogStateChanged:) name:DialogManager.DIALOG_AVAILABILITY_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationStatusChanged:) name:NAV_LOCATION_STATUS_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChanged:) name:NAV_LOCATION_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(destinationChanged:) name:DESTINATIONS_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openURL:) name: REQUEST_OPEN_URL object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestRating:) name:REQUEST_RATING object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForDealloc) name:REQUEST_UNLOAD_VIEW object:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"developer_mode" options:NSKeyValueObservingOptionNew context:nil];

    checkMapCenterTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkMapCenter:) userInfo:nil repeats:YES];
    checkStateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkState:) userInfo:nil repeats:YES];
    [self updateView];

    if ([self destId]) {
        dialogHelper.helperView.hidden = YES;
        [self hiddenVoiceGuide];
    }

    BOOL checked = [ud boolForKey: @"checked_altimeter"];
    if (!checked && ![CMAltimeter isRelativeAltitudeAvailable]) {
        NSString *title = NSLocalizedString(@"NoAltimeterAlertTitle", @"");
        NSString *message = NSLocalizedString(@"NoAltimeterAlertMessage", @"");
        NSString *ok = NSLocalizedString(@"I_Understand", @"");
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: title
                                                                       message: message
                                                                preferredStyle: UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle: ok
                                                  style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                  }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self topMostController] presentViewController:alert animated:YES completion:nil];
        });
        [ud setBool:YES forKey:@"checked_altimeter"];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (!dialogHelper) {
        dialogHelper = [[DialogViewHelper alloc] init];
        double scale = 0.75;
        double size = (113*scale)/2;
        double x = size+8;
        double y = self.view.bounds.size.height + self.view.bounds.origin.y - (size+8);
        if (@available(iOS 11.0, *)) {
            y -= self.view.safeAreaInsets.bottom;
        }
        dialogHelper.scale = scale;
        [dialogHelper inactive];
        [dialogHelper setup:self.view position:CGPointMake(x, y)];
        dialogHelper.delegate = self;
        dialogHelper.helperView.hidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    _webView.delegate = nil;
    
    dialogHelper.delegate = nil;
    dialogHelper = nil;
    
    recognizer = nil;
    
    _settingButton = nil;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [checkMapCenterTimer invalidate];
    [checkStateTimer invalidate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].windows.firstObject.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void)checkMapCenter:(NSTimer*)timer
{
    NSString *script = @"(function(){var a=$hulop.map.getCenter();var f=$hulop.indoor.getCurrentFloor();f=f>0?f-1:f;return {lat:a[1],lng:a[0],floor:f};})()";
    [_webView evaluateJavaScript:script completionHandler:^(id _Nullable state, NSError * _Nullable error) {
        NSDictionary *json = state;
        if (json) {
            HLPLocation *center = [[HLPLocation alloc] initWithLat: [json[@"lat"] doubleValue]
                                                                Lng: [json[@"lng"] doubleValue]
                                                              Floor: [json[@"floor"] doubleValue]];
            [NavDataStore sharedDataStore].mapCenter = center;
            HLPLocation *current = [NavDataStore sharedDataStore].currentLocation;
            if (isnan(current.lat) || isnan(current.lng)) {
                NSDictionary *param =
                @{
                  @"floor": @(center.floor),
                  @"lat": @(center.lat),
                  @"lng": @(center.lng),
                  @"sync": @(YES)
                  };
                [[NSNotificationCenter defaultCenter] postNotificationName:MANUAL_LOCATION_CHANGED_NOTIFICATION object:self userInfo:param];
                // Start navigating here within iBeacon environment
                if ([self destId] && [[NavDataStore sharedDataStore] reloadDestinations:NO]) {
                    [NavUtil hideWaitingForView:self.view];
                    [NavUtil showModalWaitingWithMessage:NSLocalizedString(@"Loading preview", @"")];
                }
            }
            
            [timer invalidate];
        }
    }];
}

- (void)startNavi: (HLPLocation*)center {
    
    if (isRouteNavi) {
        if ([self destId] != nil) {
            if (!isNaviStarted) {
                __block NSMutableDictionary *prefs = SettingDataManager.sharedManager.getPrefs;
                NSString *elv = [NSString stringWithFormat: @"&elv=%@", prefs[@"elv"]];
                NSString *stairs = [NSString stringWithFormat: @"&stairs=%@", prefs[@"stairs"]];
                NSString *esc = [NSString stringWithFormat: @"&esc=%@", prefs[@"esc"]];
                NSString *dist = [NSString stringWithFormat: @"&dist=%@", prefs[@"dist"]];
                NSString *hash = [NSString stringWithFormat: @"navigate=%@&dummy=%f%@%@%@%@",
                                  [self destId], [[NSDate date] timeIntervalSince1970], elv, stairs, esc, dist];
                state = ViewStateNavigation;
                dialogHelper.helperView.hidden = YES;
                [self hiddenVoiceGuide];
                [_webView setLocationHash:hash];
                isNaviStarted = YES;
                return;
            }
        }
    }

    NSDictionary *target =
        @{
          @"action": @"start",
          @"lat": @(center.lat),
          @"lng": @(center.lng),
          @"dist": @(YES)
          };
        
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:target requiringSecureCoding:NO error:nil];
    NSString *dataStr = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    
    NSString *script = [NSString stringWithFormat:@"$hulop.route.callService(%@, null)", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView evaluateJavaScript:script completionHandler:nil];
        isNaviStarted = YES;
    });
}

- (void)initTarget:(NSArray *)landmarks
{
    if (isInitTarget) {
        return;
    }
    NSMutableArray *temp = [@[] mutableCopy];
    NSError *error;
    for(id obj in landmarks) {
        [temp addObject:[MTLJSONAdapter JSONDictionaryFromModel:obj error:&error]];
    }
    
    if ([temp count] == 0) {
        NSLog(@"No Landmarks");
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"landmarks":temp} options:0 error:nil];
    NSString *dataStr = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    
    NSString *script = [NSString stringWithFormat:@"$hulop.map.initTarget(%@, null)", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView evaluateJavaScript:script completionHandler:nil];
    });
    isInitTarget = true;
}

- (void)showRoute
{
    NSArray *route = [[NavDataStore sharedDataStore] route];
    NSMutableArray *temp = [@[] mutableCopy];
    NSError *error;
    for(id obj in route) {
        [temp addObject:[MTLJSONAdapter JSONDictionaryFromModel:obj error:&error]];
    }
    
    if ([temp count] == 0) {
        NSLog(@"No Route %@", route);
        [NavUtil hideModalWaiting];
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:0 error:nil];
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *script = [NSString stringWithFormat:@"$hulop.map.showRoute(%@, null, true, true);$('#map-page').trigger('resize');", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NavUtil hideModalWaiting];
        [_webView evaluateJavaScript:script completionHandler:nil];
    });
}

- (void)checkState:(NSTimer*)timer
{
    if (state != ViewStateLoading) {
        [timer invalidate];
        return;
    }

    [_webView getStateWithCompletionHandler:^(NSDictionary * _Nonnull json) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WCUI_STATE_CHANGED_NOTIFICATION object:self userInfo:json];
    }];
}

- (void)dialogViewTapped
{
    [dialogHelper inactive];
    dialogHelper.helperView.hidden = YES;
    [self performSegueWithIdentifier:@"show_dialog_wc" sender:self];
    
}

- (void)updateView
{
    NavDataStore *nds = [NavDataStore sharedDataStore];
    HLPLocation *loc = [nds currentLocation];
    BOOL validLocation = loc && !isnan(loc.lat) && !isnan(loc.lng) && !isnan(loc.floor);
    BOOL devMode = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"developer_mode"]) {
        devMode = [[NSUserDefaults standardUserDefaults] boolForKey: @"developer_mode"];
    }
    BOOL isPreviewDisabled = [[ServerConfig sharedConfig] isPreviewDisabled];
    BOOL debugFollower = [[NSUserDefaults standardUserDefaults] boolForKey: @"p2p_debug_follower"];
    BOOL peerExists = [[[NavDebugHelper sharedHelper] peers] count] > 0;

    switch(state) {
        case ViewStateMap:
            self.navigationItem.rightBarButtonItems = debugFollower ? @[] : @[self.searchButton];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateSearch:
            self.navigationItem.rightBarButtonItems = @[self.cancelButton];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateSearchDetail:
            self.navigationItem.rightBarButtonItems = @[self.cancelButton];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateSearchSetting:
            self.navigationItem.rightBarButtonItems = @[self.searchButton];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateNavigation:
            self.navigationItem.rightBarButtonItems = @[self.stopButton];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateRouteConfirm:
            self.navigationItem.rightBarButtonItems = @[self.cancelButton];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateRouteCheck:
            self.navigationItem.rightBarButtonItems = @[];
            self.navigationItem.leftBarButtonItems = @[self.doneButton];
            break;
        case ViewStateTransition:
            self.navigationItem.rightBarButtonItems = @[];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
        case ViewStateLoading:
            self.navigationItem.rightBarButtonItems = @[];
            self.navigationItem.leftBarButtonItems = @[self.backButton];
            break;
    }
    
    if (state == ViewStateMap) {
        if ([[DialogManager sharedManager] isAvailable]  && (!isPreviewDisabled || devMode || validLocation) && ![self destId]) {
            if (dialogHelper.helperView.hidden) {
                dialogHelper.helperView.hidden = NO;
                [dialogHelper recognize];
            }
        } else {
            dialogHelper.helperView.hidden = YES;
        }
    } else {
        dialogHelper.helperView.hidden = YES;
    }
    
    if (peerExists) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.9 alpha:1.0];
    } else {
        self.navigationController.navigationBar.barTintColor = defaultColor;
    }
}

- (void)setTitleButton:(NSString*)title
{
    [titleButton setTitle:title forState: UIControlStateNormal];
    [titleButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [titleButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16]];
    [titleButton setIsAccessibilityElement: false];
}

- (void)titleAction
{
    
}

#pragma mark - HLPWebView

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [_indicator startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [_indicator stopAnimating];
    _indicator.hidden = YES;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    _errorMessage.hidden = NO;
    _retryButton.hidden = NO;
}

- (void)speak:(NSString *)text force:(BOOL)isForce completionHandler:(void (^)(void))handler
{
    BOOL isVoiceGuideOn = false;
    [[NavDeviceTTS sharedTTS] speak:isVoiceGuideOn ? text : @"" withOptions: @{@"force": @(isForce)} completionHandler:handler];
}

- (BOOL)isSpeaking
{
    return [[NavDeviceTTS sharedTTS] isSpeaking];
}

- (void)vibrate
{
//    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)webView:(HLPWebView *)webView didChangeLatitude:(double)lat longitude:(double)lng floor:(double)floor synchronized:(BOOL)sync
{
    NSDictionary *loc =
    @{
      @"lat": @(lat),
      @"lng": @(lng),
      @"floor": @(floor),
      @"sync": @(sync),
      };
    [[NSNotificationCenter defaultCenter] postNotificationName:MANUAL_LOCATION_CHANGED_NOTIFICATION object:self userInfo:loc];
}

- (void)webView:(HLPWebView *)webView didChangeBuilding:(NSString *)building
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BUILDING_CHANGED_NOTIFICATION object:self userInfo:(building != nil ? @{@"building": building} : @{})];
}

- (void)webView:(HLPWebView *)webView didChangeUIPage:(NSString *)page inNavigation:(BOOL)inNavigation
{
    NSDictionary *uiState =
    @{
      @"page": page,
      @"navigation": @(inNavigation),
      };
    [[NSNotificationCenter defaultCenter] postNotificationName:WCUI_STATE_CHANGED_NOTIFICATION object:self userInfo:uiState];
}

/// Arrive at destination
- (void)webView:(HLPWebView *)webView didFinishNavigationStart:(NSTimeInterval)start end:(NSTimeInterval)end from:(NSString *)from to:(NSString *)to
{
    NSDictionary *navigationInfo =
    @{
      @"start": @(start),
      @"end": @(end),
      @"from": from,
      @"to": to,
      };
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_RATING object:self userInfo:navigationInfo];
}

- (void)webView:(HLPWebView *)webView openURL:(NSURL *)url
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_OPEN_URL object:self userInfo:@{@"url": url}];
}

#pragma mark -

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", touches);
    NSLog(@"%@", event);
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)openMenu:(UIGestureRecognizer*)sender
{
    NSLog(@"%@", sender);
    
    CGPoint p = [sender locationInView:self.webView];
    NSLog(@"%f %f", p.x, p.y);
}

#pragma mark - notification handlers


- (void)openURL:(NSNotification*)note
{
    [NavUtil openURL:[note userInfo][@"url"] onViewController:self];
}

- (void)dialogStateChanged:(NSNotification*)note
{
    [self updateView];
}

- (void)requestRating:(NSNotification*)note
{
    if ([[ServerConfig sharedConfig] shouldAskRating]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ratingInfo = [note userInfo];
            [self performSegueWithIdentifier:@"show_rating" sender:self];
        });
    }
}

- (void)uiStateChanged:(NSNotification*)note
{
    uiState = [note userInfo];

    NSString *page = uiState[@"page"];
    BOOL inNavigation = [uiState[@"navigation"] boolValue];

    if (page) {
        if ([page isEqualToString: @"control"]) {
            state = ViewStateSearch;
            [self hiddenVoiceGuide];
        }
        else if ([page isEqualToString: @"settings"]) {
            state = ViewStateSearchSetting;
            [self hiddenVoiceGuide];
        }
        else if ([page isEqualToString: @"confirm"]) {
            state = ViewStateRouteConfirm;
            [self hiddenVoiceGuide];
            [NavUtil hideModalWaiting];
            [NavUtil hideWaitingForView:self.view];
        }
        else if ([page hasPrefix: @"map-page"]) {
            if (inNavigation) {
                state = ViewStateNavigation;
                [self hiddenVoiceGuide];
            } else {
                state = ViewStateMap;
                [self showVoiceGuide];
                isSetupMap = true;
                
                if (!isInitTarget && landmarks) {
                    [self initTarget:landmarks];
                }
                
                if ([self destId]) {
                    [self setupNavigation];
                }
            }
        }
        else if ([page hasPrefix: @"ui-id-"]) {
            state = ViewStateSearchDetail;
        }
        else if ([page isEqualToString: @"confirm_floor"]) {
            state = ViewStateRouteCheck;
        }
        else {
            NSLog(@"unmanaged state: %@", page);
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateView];
    });
}

- (void)requestStartNavigation:(NSNotification*)note
{
    NSDictionary *options = [note userInfo];
    if (options[@"toID"] == nil) {
        return;
    }
    
    __block NSMutableDictionary *prefs = SettingDataManager.sharedManager.getPrefs;
    NSString *elv = [NSString stringWithFormat: @"&elv=%@", prefs[@"elv"]];
    NSString *stairs = [NSString stringWithFormat: @"&stairs=%@", prefs[@"stairs"]];
    NSString *esc = [NSString stringWithFormat: @"&esc=%@", prefs[@"esc"]];
    NSString *dist = [NSString stringWithFormat: @"&dist=%@", prefs[@"dist"]];
    NSString *hash = [NSString stringWithFormat: @"navigate=%@&dummy=%f%@%@%@%@",
                      options[@"toID"], [[NSDate date] timeIntervalSince1970], elv, stairs, esc, dist];
    state = ViewStateNavigation;
    dialogHelper.helperView.hidden = YES;
    [self hiddenVoiceGuide];
    [_webView setLocationHash:hash];
    isNaviStarted = YES;
}


- (void)locationStatusChanged:(NSNotification*)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        HLPLocationStatus status = [[note userInfo][@"status"] unsignedIntegerValue];
        
        switch(status) {
            case HLPLocationStatusLocating:
                [NavUtil hideModalWaiting];
                [NavUtil showWaitingForView:self.view withMessage:NSLocalizedStringFromTable(@"Locating...", @"BlindView", @"")];
                break;
            default:
                [NavUtil hideWaitingForView:self.view];
        }
    });
}

- (void)locationChanged: (NSNotification*) note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
        if (appState == UIApplicationStateBackground || appState == UIApplicationStateInactive) {
            return;
        }
        
        NSDictionary *locations = [note userInfo];
        if (!locations) {
            return;
        }
        HLPLocation *location = locations[@"current"];
        if (!location || [location isEqual:[NSNull null]]) {
            return;
        }
        
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        
        double orientation = -location.orientation / 180 * M_PI;
        
        if (lastOrientationSent + 0.2 < now) {
            [_webView sendData:@[@{
                                @"type": @"ORIENTATION",
                                @"z": @(orientation)
                                }]
                      withName: @"Sensor"];
            lastOrientationSent = now;
        }
        
        location = locations[@"actual"];
        if (!location || [location isEqual:[NSNull null]]) {
            return;
        }
        
        if (now < lastLocationSent + [[NSUserDefaults standardUserDefaults] doubleForKey: @"webview_update_min_interval"]) {
            if (!location.params) {
                return;
            }
            //return; // prevent too much send location info
        }
        
        double floor = location.floor;
        
        [_webView sendData: @{
                            @"lat": @(location.lat),
                            @"lng": @(location.lng),
                            @"floor": @(floor),
                            @"accuracy": @(location.accuracy),
                            @"rotate": @(0), // dummy
                            @"orientation": @(999), //dummy
                            @"debug_info": location.params?location.params[@"debug_info"] : [NSNull null],
                            @"debug_latlng": location.params?location.params[@"debug_latlng"] : [NSNull null]
                            }
                  withName: @"XYZ"];

        lastLocationSent = now;
        
        [NavUtil hideWaitingForView:self.view];

        if (!self.destId || isNaviStarted) {
            return;
        }
        if ([[NavDataStore sharedDataStore] reloadDestinations:NO]) {
            NSString *msg = [MiraikanUtil isPreview]
                ? NSLocalizedString(@"Loading preview",@"")
                : NSLocalizedString(@"Loading, please wait",@"");
            [NavUtil showModalWaitingWithMessage:msg];
        }

        if(!isInitTarget) {
            return;
        }

        if ([self destId]) {
            [self setupNavigation];
        }
    });
}

- (void)destinationChanged: (NSNotification*) note
{
    if (!isSetupMap) {
        landmarks = [note userInfo][@"destinations"];
        return;
    }
    
    // 到着判定データ
    [self initTarget:[note userInfo][@"destinations"]];
}

- (void)setupNavigation
{
    if (isSetupNavigation) {
        return;
    }
    isSetupNavigation = true;

    NavDataStore *nds = [NavDataStore sharedDataStore];
    NavDestination *from = [NavDataStore destinationForCurrentLocation];
    NavDestination *to = [nds destinationByID:[self destId]];

    HLPLocation *location = nds.currentLocation;
    if (isnan(location.lat) || isnan(location.lng)) {
        location = from.location;
    }

    [self startNavi:location];
    
    __block NSMutableDictionary *prefs = SettingDataManager.sharedManager.getPrefs;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    dispatch_async(dispatch_get_main_queue(), ^{
        [nds requestRouteFrom:from.singleId
                           To:to._id
              withPreferences:prefs complete:^{
                __weak typeof(self) weakself = self;
                nds.previewMode = [MiraikanUtil isPreview];
                nds.exerciseMode = NO;
                [weakself showRoute];
            }
        ];
    });
}

#pragma mark - IBActions

- (IBAction)doSearch:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl:HLPWebviewControlRouteSearchButton];
}

- (IBAction)stopNavigation:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl:HLPWebviewControlNone];
}

- (IBAction)doCancel:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl:HLPWebviewControlNone];
}

- (IBAction)doDone:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl:HLPWebviewControlDoneButton];
}

- (IBAction)doBack:(id)sender {
    [self prepareForDealloc];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)retry:(id)sender {
    [_webView reload];
    _retryButton.hidden = YES;
    _errorMessage.hidden = YES;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString: @"user_settings"] && (state == ViewStateMap || state == ViewStateLoading)) {
        return YES;
    }
    if ([identifier isEqualToString: @"user_settings"] && state == ViewStateSearch) {
        state = ViewStateTransition;
        [self updateView];
        [_webView triggerWebviewControl:HLPWebviewControlRouteSearchOptionButton];
    }
    
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    segue.destinationViewController.restorationIdentifier = segue.identifier;
    
    if ([segue.identifier isEqualToString: @"user_settings"]) {
        SettingViewController *sv = (SettingViewController*)segue.destinationViewController;
        sv.webView = _webView;
    }
    if ([segue.identifier isEqualToString: @"show_rating"] && ratingInfo) {
        RatingViewController *rv = (RatingViewController*)segue.destinationViewController;
        rv.start = [ratingInfo[@"start"] doubleValue]/1000.0;
        rv.end = [ratingInfo[@"end"] doubleValue]/1000.0;
        rv.from = ratingInfo[@"from"];
        rv.to = ratingInfo[@"to"];
        rv.device_id = [[NavDataStore sharedDataStore] userID];
        
        ratingInfo = nil;
    }
    if ([segue.identifier isEqualToString: @"show_dialog_wc"]) {
        DialogViewController* dView = (DialogViewController*)segue.destinationViewController;
        dView.tts = [DefaultTTS new];
        dView.root = self;
        dView.title = @"Ask AI";
        dView.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 50);
        [dView.dialogViewHelper removeFromSuperview];
        [dView.dialogViewHelper setup: dView.view
                             position: CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 40)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"developer_mode"]) {
        _webView.isDeveloperMode = @([[NSUserDefaults standardUserDefaults] boolForKey: @"developer_mode"]);
    }
}

#pragma mark - NavNavigatorDelegate

- (void)didActiveStatusChanged:(NSDictionary *)properties
{

}

- (void)couldNotStartNavigation:(NSDictionary *)properties
{

}

- (void)didNavigationStarted:(NSDictionary *)properties
{

}

- (void)didNavigationFinished:(NSDictionary *)properties
{

}

@end
