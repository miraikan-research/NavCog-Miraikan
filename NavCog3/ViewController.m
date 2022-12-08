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
#import "NavTalkButton.h"
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

    UIButton *titleButton;
    NavTalkButton *talkButton;

    NSDictionary *uiState;
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
    BOOL reserveNavigation;
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
    
    navigator.delegate = nil;
    navigator = nil;

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
    _webView.userMode = [ud stringForKey:@"user_mode"];
    _webView.config = @{
                        @"serverHost": [ud stringForKey:@"selected_hokoukukan_server"],
                        @"serverContext": [ud stringForKey:@"hokoukukan_server_context"],
                        @"usesHttps": @([ud boolForKey:@"https_connection"])
                        };
    _webView.delegate = self;
    _webView.tts = self;
    [_webView setFullScreenForView:self.view];
    
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

    checkMapCenterTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkMapCenter:) userInfo:nil repeats:NO];
    checkStateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkState:) userInfo:nil repeats:YES];
    [self updateView];

    if ([self destId]) {
        [talkButton setHidden:true];
    }

    BOOL checked = [ud boolForKey:@"checked_altimeter"];
    if (!checked && ![CMAltimeter isRelativeAltitudeAvailable]) {
        NSString *title = NSLocalizedString(@"NoAltimeterAlertTitle", @"");
        NSString *message = NSLocalizedString(@"NoAltimeterAlertMessage", @"");
        NSString *ok = NSLocalizedString(@"I_Understand", @"");
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: title
                                                                       message: message
                                                                preferredStyle: UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle: ok
                                                  style: UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                  }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self topMostController] presentViewController:alert animated:YES completion:nil];
        });
        [ud setBool:YES forKey:@"checked_altimeter"];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:@"isFooterButtonView"];

    if (!talkButton) {
        double scale = 0.75;
        double size = (113*scale)/2;
        double x = size+8;
        double y = self.view.bounds.size.height + self.view.bounds.origin.y - (size+8);
        y -= self.view.safeAreaInsets.bottom;

        talkButton = [[NavTalkButton alloc] initWithFrame:CGRectMake(x - size, y - size, size * 2, size * 2)];
        [talkButton setHidden:true];
        [self.view addSubview: talkButton];
        [talkButton addTarget:self action:@selector(talkTap:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _webView.delegate = nil;
    
    _settingButton = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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

- (BOOL)initLocation {
    double lat = 0;
    double lng = 0;
    double floor = 0;
    HLPLocation *current = [NavDataStore sharedDataStore].currentLocation;
    if (isnan(current.lat) || isnan(current.lng)) {
        return false;
    }

    lat = current.lat;
    lng = current.lng;
    floor = current.floor + 1;

    NSDictionary *param =
    @{
      @"floor": @(floor),
      @"lat": @(lat),
      @"lng": @(lng),
      @"sync": @(NO)
      };
    HLPLocation *center = [[HLPLocation alloc] initWithLat: lat
                                                       Lng: lng
                                                     Floor: floor];
    [NavDataStore sharedDataStore].mapCenter = center;
    [[NSNotificationCenter defaultCenter] postNotificationName:MANUAL_LOCATION_CHANGED_NOTIFICATION object:self userInfo:param];
    return true;
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
                [talkButton setHidden:true];
//                NSLog(@"%s: %d, %@" , __func__, __LINE__, hash);
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
    
    NSString *script = [NSString stringWithFormat: @"$hulop.route.callService(%@, null)", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"%s: %d, %@" , __func__, __LINE__, script);
        [self.webView evaluateJavaScript:script completionHandler:nil];
        self->isNaviStarted = YES;
    });
}

// NavBlindWebViewと同じ
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
        //NSLog(@"No Landmarks %@", landmarks);
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject: @{@"landmarks":temp} options:0 error:nil];
    NSString *dataStr = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    
    NSString *script = [NSString stringWithFormat: @"$hulop.map.initTarget(%@, null)", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"%s: %d, %@" , __func__, __LINE__, script);
        [self.webView evaluateJavaScript:script completionHandler:nil];
    });
    isInitTarget = true;
}

- (void)clearRoute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:@"$hulop.map.clearRoute()" completionHandler:nil];
    });
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
//        NSLog(@"%s: %d, %@" , __func__, __LINE__, script);
        [NavUtil hideModalWaiting];
        [self.webView evaluateJavaScript:script completionHandler:nil];
    });
}

- (void)checkMapCenter:(NSTimer*)timer
{
    NSString *script = @"(function(){var a=$hulop.map.getCenter();var f=$hulop.indoor.getCurrentFloor();f=f>0?f-1:f;return {lat:a[1],lng:a[0],floor:f};})()";
    [_webView evaluateJavaScript:script completionHandler:^(id _Nullable state, NSError * _Nullable error) {
        NSDictionary *json = state;
        if (json) {
            double lat = [json[@"lat"] doubleValue];
            double lng = [json[@"lng"] doubleValue];
            double floor = [json[@"floor"] doubleValue];
            if (lat == 0 || lng == 0 || floor == 0) {
                return;
            }
            HLPLocation *center = [[HLPLocation alloc] initWithLat: lat
                                                               Lng: lng
                                                             Floor: floor];
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
//                if ([self destId] && [[NavDataStore sharedDataStore] reloadDestinations:NO]) {
//                    [NavUtil hideWaitingForView:self.view];
//                    [NavUtil showModalWaitingWithMessage:NSLocalizedString(@"Loading preview", @"")];
//                }
            }
            
            [timer invalidate];
        }
    }];
}

- (void)checkState:(NSTimer*)timer
{
    if (state != ViewStateLoading) {
        [timer invalidate];
        return;
    }

    [_webView getStateWithCompletionHandler:^(NSDictionary * _Nonnull json) {
//        NSLog(@"%s: %d, %@" , __func__, __LINE__, json);
        [[NSNotificationCenter defaultCenter] postNotificationName:WCUI_STATE_CHANGED_NOTIFICATION object:self userInfo:json];
    }];
}

- (void)talkTap:(id)sender
{
    [self performSegueWithIdentifier:@"show_dialog_wc" sender:self];
}

- (void)updateView
{
    NavDataStore *nds = [NavDataStore sharedDataStore];
    HLPLocation *loc = [nds currentLocation];
    BOOL validLocation = loc && !isnan(loc.lat) && !isnan(loc.lng) && !isnan(loc.floor);
    BOOL isPreviewDisabled = [[ServerConfig sharedConfig] isPreviewDisabled];
    BOOL peerExists = [[[NavDebugHelper sharedHelper] peers] count] > 0;

    switch(state) {
        case ViewStateMap:
            self.navigationItem.rightBarButtonItems =  @[self.searchButton];
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
        if ([[DialogManager sharedManager] isAvailable]  && (!isPreviewDisabled || validLocation) && ![self destId]) {
            [talkButton setHidden:false];
        } else {
            [talkButton setHidden:true];
        }
    } else {
        [talkButton setHidden:true];
    }
    
    if (peerExists) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.9 alpha:1.0];
    } else {
        self.navigationController.navigationBar.barTintColor = defaultColor;
    }
}

- (void)setTitleButton:(NSString*)title
{
    [titleButton setTitle:title forState:UIControlStateNormal];
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

- (void)webView:(HLPWebView *)webView didChangeLatitude:(double)lat longitude:(double)lng floor:(double)floor synchronized:(BOOL)sync
{
    if (floor == 0) {
        return;
    }
    NSDictionary *loc =
    @{
      @"lat": @(lat),
      @"lng": @(lng),
      @"floor": @(floor),
      @"sync": @(sync),
      };
//    NSLog(@"%s: %d, %@" , __func__, __LINE__, loc);
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
//    NSLog(@"%s: %d, %@" , __func__, __LINE__, uiState);
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
//    NSLog(@"%s: %d, %@" , __func__, __LINE__, navigationInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_RATING object:self userInfo:navigationInfo];
}

- (void)webView:(HLPWebView *)webView openURL:(NSURL *)url
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_OPEN_URL object:self userInfo:@{@"url": url}];
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
            self->ratingInfo = [note userInfo];
            [self performSegueWithIdentifier:@"show_rating" sender:self];
        });
    }
}

- (void)uiStateChanged:(NSNotification*)note
{
    uiState = [note userInfo];

    NSString *page = uiState[@"page"];
    BOOL inNavigation = [uiState[@"navigation"] boolValue];

//    NSLog(@"%s: %d, page:%@, %d" , __func__, __LINE__, page, inNavigation);
    if (page) {
        if ([page isEqualToString: @"control"]) {
            state = ViewStateSearch;
//            [self hiddenVoiceGuide];
        }
        else if ([page isEqualToString: @"settings"]) {
            state = ViewStateSearchSetting;
//            [self hiddenVoiceGuide];
        }
        else if ([page isEqualToString: @"confirm"]) {
            state = ViewStateRouteConfirm;
//            [self hiddenVoiceGuide];
            [NavUtil hideModalWaiting];
            [NavUtil hideWaitingForView:self.view];
        }
        else if ([page hasPrefix: @"map-page"]) {
            if (inNavigation) {
                state = ViewStateNavigation;
//                [self hiddenVoiceGuide];
            } else {
                state = ViewStateMap;
//                [self showVoiceGuide];
                isSetupMap = true;
                
                if (!isInitTarget && landmarks) {
                    [self initTarget:landmarks];
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    if ([self initLocation]) {
                        self->reserveNavigation = true;
                    }
                });
            }
            
            NavDataStore *nds = [NavDataStore sharedDataStore];
            if (isnan(nds.currentLocation.lat) || isnan(nds.currentLocation.lng)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NavUtil hideModalWaiting];
                    [NavUtil showWaitingForView:self.view withMessage:NSLocalizedStringFromTable(@"Locating...", @"BlindView", @"")];
                });
                return;
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

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateView];
        });
    }
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
    [talkButton setHidden:true];
//    NSLog(@"%s: %d, %@" , __func__, __LINE__, hash);
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
            case HLPLocationStatusUnknown:
                break;
            default:
                [NavUtil hideWaitingForView:self.view];
        }
    });
}

- (void)locationChanged: (NSNotification*) note
{
//    NSLog(@"%s: %d, %@" , __func__, __LINE__, note);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
        if (appState == UIApplicationStateBackground || appState == UIApplicationStateInactive) {
//            NSLog(@"%s: %d", __func__, __LINE__);
            return;
        }
        
        NSDictionary *locations = [note userInfo];
        if (!locations) {
//            NSLog(@"%s: %d", __func__, __LINE__);
            return;
        }
        HLPLocation *location = locations[@"current"];
        if (!location || isnan(location.lat) || isnan(location.lng)) {
//            NSLog(@"%s: %d", __func__, __LINE__);
            return;
        }
        
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        
        double orientation = -location.orientation / 180 * M_PI;
        
        if (self->lastOrientationSent + 0.2 < now) {
            [self.webView sendData:@[@{
                                @"type": @"ORIENTATION",
                                @"z": @(orientation)
                                }]
                      withName: @"Sensor"];
            self->lastOrientationSent = now;
        }
        
        location = locations[@"actual"];
        if (!location || isnan(location.lat) || isnan(location.lng)) {
//            NSLog(@"%s: %d", __func__, __LINE__);
            return;
        }
        
        if (now < self->lastLocationSent + [[NSUserDefaults standardUserDefaults] doubleForKey: @"webview_update_min_interval"]) {
            if (!location.params) {
//                NSLog(@"%s: %d", __func__, __LINE__);
                return;
            }
            //return; // prevent too much send location info
        }
        
        double floor = location.floor;
        
        [self.webView sendData:@{
            @"lat": @(location.lat),
            @"lng": @(location.lng),
            @"floor": @(floor),
            @"accuracy": @(location.accuracy),
            @"rotate": @(0), // dummy
            @"orientation": @(999), //dummy
            @"debug_info": location.params ? location.params[@"debug_info"] : [NSNull null],
            @"debug_latlng": location.params ? location.params[@"debug_latlng"] : [NSNull null]
        }
                      withName:@"XYZ"];

        self->lastLocationSent = now;
        
        [NavUtil hideWaitingForView:self.view];

        if (!self.destId || self->isNaviStarted) {
//            NSLog(@"%s: %d", __func__, __LINE__);
            return;
        }

        if ([self destId]) {
            if ([[NavDataStore sharedDataStore] reloadDestinations:NO]) {
                NSString *msg = [MiraikanUtil isPreview]
                    ? NSLocalizedString(@"Loading preview",@"")
                    : NSLocalizedString(@"Loading, please wait",@"");
                [NavUtil showModalWaitingWithMessage:msg];
            }
            
            if (self->reserveNavigation) {
                [self setupNavigation];
            }
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
//    NSLog(@"%s: %d" , __func__, __LINE__);
    if (isSetupNavigation) {
//        NSLog(@"%s: %d" , __func__);
        return;
    }
    
    NavDataStore *nds = [NavDataStore sharedDataStore];
    if (nds.directory == nil) {
//        NSLog(@"%s: %d" , __func__);
        return;
    }

    NavDestination *from = [NavDataStore destinationForCurrentLocation];
//    NavDestination *to = [nds destinationByID:[self destId]];

    HLPLocation *location = nds.currentLocation;
    if (isnan(location.lat) || isnan(location.lng)) {
        location = from.location;
    }

    isSetupNavigation = true;
    [self startNavi:location];
    
//    __block NSMutableDictionary *prefs = SettingDataManager.sharedManager.getPrefs;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
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
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - IBActions

- (IBAction)doSearch:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl: HLPWebviewControlRouteSearchButton];
}

- (IBAction)stopNavigation:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl: HLPWebviewControlNone];
}

- (IBAction)doCancel:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl: HLPWebviewControlNone];
}

- (IBAction)doDone:(id)sender {
    state = ViewStateTransition;
    [self updateView];
    [_webView triggerWebviewControl: HLPWebviewControlDoneButton];
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
    if ([identifier isEqualToString:@"user_settings"] && (state == ViewStateMap || state == ViewStateLoading)) {
        return YES;
    }
    if ([identifier isEqualToString:@"user_settings"] && state == ViewStateSearch) {
        state = ViewStateTransition;
        [self updateView];
        [_webView triggerWebviewControl:HLPWebviewControlRouteSearchOptionButton];
    }
    
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    segue.destinationViewController.restorationIdentifier = segue.identifier;
    
    if ([segue.identifier isEqualToString:@"user_settings"]) {
        SettingViewController *sv = (SettingViewController*)segue.destinationViewController;
        sv.webView = _webView;
    }
    if ([segue.identifier isEqualToString:@"show_rating"] && ratingInfo) {
        RatingViewController *rv = (RatingViewController*)segue.destinationViewController;
        NavDataStore *nds = [NavDataStore sharedDataStore];
        rv.start = [ratingInfo[@"start"] doubleValue]/1000.0;
        rv.end = [ratingInfo[@"end"] doubleValue]/1000.0;
        rv.from = ratingInfo[@"from"];
        rv.to = ratingInfo[@"to"];
        rv.device_id = [nds userID];
        ratingInfo = nil;
    }
    if ([segue.identifier isEqualToString:@"show_dialog_wc"]) {
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
