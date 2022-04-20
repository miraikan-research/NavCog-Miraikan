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
#import "LocationEvent.h"
#import "NavDebugHelper.h"
#import "NavUtil.h"
#import "NavDataStore.h"
#import "RatingViewController.h"
#import "SettingViewController.h"
#import "ServerConfig.h"
#import "NavDeviceTTS.h"
#import <HLPLocationManager/HLPLocationManager.h>
#import "DefaultTTS.h"
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
    UISwipeGestureRecognizer *recognizer;
    NSDictionary *uiState;
    DialogViewHelper *dialogHelper;
    NSDictionary *ratingInfo;
    
    NSTimeInterval lastLocationSent;
    NSTimeInterval lastOrientationSent;

    NSTimer *checkMapCenterTimer;
    NSTimer *checkStateTimer;

    BOOL isNaviStarted;
}

@end

@implementation ViewController {
    ViewState state;
    UIColor *defaultColor;
}

- (void)dealloc
{
    NSLog(@"dealloc ViewController");
}

//- (void)prepareForDealloc
//{
//    _webView.delegate = nil;
//
//    dialogHelper.delegate = nil;
//    dialogHelper = nil;
//
//    recognizer = nil;
//
//    _settingButton = nil;
//
//    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"developer_mode"];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_LOCATION_STOP object:self];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    defaultColor = self.navigationController.navigationBar.barTintColor;
    
    isNaviStarted = NO;
    state = ViewStateLoading;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _webView = [[HLPWebView alloc] initWithFrame:CGRectMake(0,0,0,0) configuration:[[WKWebViewConfiguration alloc] init]];
    [self.view addSubview:_webView];
    [self showVoiceGuide];
    _webView.isDeveloperMode = [ud boolForKey:@"developer_mode"];
    _webView.userMode = [ud stringForKey:@"user_mode"];
    _webView.config = @{
                        @"serverHost":[ud stringForKey:@"selected_hokoukukan_server"],
                        @"serverContext":[ud stringForKey:@"hokoukukan_server_context"],
                        @"usesHttps":@([ud boolForKey:@"https_connection"])
                        };
    _webView.delegate = self;
    _webView.tts = self;
    [_webView setFullScreenForView:self.view];
    
    /*
    NSString *server = ;
    helper = [[HLPWebviewHelper alloc] initWithWebview:self.webView server:server];
    helper.developerMode = @([[NSUserDefaults standardUserDefaults] boolForKey:@"developer_mode"]);
    helper.userMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"user_mode"];
    helper.delegate = self;
     */
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(openMenu:)];
    recognizer.delegate = self;
    [self.webView addGestureRecognizer:recognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestStartNavigation:) name:REQUEST_START_NAVIGATION object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiStateChanged:) name:WCUI_STATE_CHANGED_NOTIFICATION object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dialogStateChanged:) name:DialogManager.DIALOG_AVAILABILITY_CHANGED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationStatusChanged:) name:NAV_LOCATION_STATUS_CHANGE object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChanged:) name:NAV_LOCATION_CHANGED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(destinationChanged:) name:DESTINATIONS_CHANGED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openURL:) name: REQUEST_OPEN_URL object:nil];
    
    checkMapCenterTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkMapCenter:) userInfo:nil repeats:YES];
    
    [self updateView];
    
    checkStateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkState:) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestRating:) name:REQUEST_RATING object:nil];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"developer_mode" options:NSKeyValueObservingOptionNew context:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareForDealloc) name:REQUEST_UNLOAD_VIEW object:nil];
    
    BOOL checked = [ud boolForKey:@"checked_altimeter"];
    if (!checked && ![CMAltimeter isRelativeAltitudeAvailable]) {
        NSString *title = NSLocalizedString(@"NoAltimeterAlertTitle", @"");
        NSString *message = NSLocalizedString(@"NoAltimeterAlertMessage", @"");
        NSString *ok = NSLocalizedString(@"I_Understand", @"");
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:ok
                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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

- (void)viewWillDisappear:(BOOL)animated {
    _webView.delegate = nil;
    
    dialogHelper.delegate = nil;
    dialogHelper = nil;
    
    recognizer = nil;
    
    _settingButton = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"developer_mode"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [checkMapCenterTimer invalidate];
    [checkStateTimer invalidate];
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
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
            HLPLocation *center = [[HLPLocation alloc] initWithLat:[json[@"lat"] doubleValue]
                                                                Lng:[json[@"lng"] doubleValue]
                                                              Floor:[json[@"floor"] doubleValue]];
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
                if (self.destId && [[NavDataStore sharedDataStore] reloadDestinations:NO]) {
                    [NavUtil showModalWaitingWithMessage:NSLocalizedString(@"Loading preview",@"")];
                }
            }
            
            [timer invalidate];
        }
    }];
}

- (void) startNavi: (HLPLocation*) center {
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
    });
}

- (void) destinationChanged: (NSNotification*) note
{
    [self initTarget:[note userInfo][@"destinations"]];
    
    NavDataStore *nds = [NavDataStore sharedDataStore];
    NavDestination *from = [NavDataStore destinationForCurrentLocation];
    NavDestination *to = [nds destinationByID:[self destId]];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    [self startNavi:from.location];
    
    __block NSMutableDictionary *prefs = [@{
                            @"dist":@"500",
                            @"preset":@"9",
                            @"min_width":@"8",
                            @"slope":@"9",
                            @"road_condition":@"9",
                            @"deff_LV":@"9",
                            @"stairs":[ud boolForKey:@"route_use_stairs"]?@"9":@"1",
                            @"esc":[ud boolForKey:@"route_use_escalator"]?@"9":@"1",
                            @"elv":[ud boolForKey:@"route_use_elevator"]?@"9":@"1",
                            @"mvw":[ud boolForKey:@"route_use_moving_walkway"]?@"9":@"1",
                            @"tactile_paving":[ud boolForKey:@"route_tactile_paving"]?@"1":@"",
                            } mutableCopy];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [nds requestRouteFrom:from.singleId
                       To:to._id withPreferences:prefs complete:^{
        __weak typeof(self) weakself = self;
        nds.previewMode = [MiraikanUtil isPreview];
        nds.exerciseMode = NO;
        [weakself showRoute];
    }];
}

- (void)initTarget:(NSArray *)landmarks
{
    NSMutableArray *temp = [@[] mutableCopy];
    NSError *error;
    for(id obj in landmarks) {
        [temp addObject:[MTLJSONAdapter JSONDictionaryFromModel:obj error:&error]];
    }
    
    if ([temp count] == 0) {
        //NSLog(@"No Landmarks %@", landmarks);
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"landmarks":temp} options:0 error:nil];
    NSString *dataStr = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    
    NSString *script = [NSString stringWithFormat:@"$hulop.map.initTarget(%@, null)", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView evaluateJavaScript:script completionHandler:nil];
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
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:0 error:nil];
    NSString *dataStr = [[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding];
    
    NSString *script = [NSString stringWithFormat:@"$hulop.map.showRoute(%@, null, true, true);$('#map-page').trigger('resize');", dataStr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NavUtil hideModalWaiting];
        [_webView evaluateJavaScript:script completionHandler:nil];
    });
}

- (void) requestRating:(NSNotification*)note
{
    if ([[ServerConfig sharedConfig] shouldAskRating]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ratingInfo = [note userInfo];
            [self performSegueWithIdentifier:@"show_rating" sender:self];
        });
    }
}

- (void) checkState:(NSTimer*)timer
{
    if (state != ViewStateLoading) {
        [timer invalidate];
        return;
    }
    NSLog(@"checkState");
    [_webView getStateWithCompletionHandler:^(NSDictionary * _Nonnull json) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WCUI_STATE_CHANGED_NOTIFICATION object:self userInfo:json];
    }];
}

- (void) openURL:(NSNotification*)note
{
    [NavUtil openURL:[note userInfo][@"url"] onViewController:self];
}


- (void)dialogViewTapped
{
    [dialogHelper inactive];
    dialogHelper.helperView.hidden = YES;
    [self performSegueWithIdentifier:@"show_dialog_wc" sender:self];
    
}

- (void)dialogStateChanged:(NSNotification*)note
{
    [self updateView];
}

- (void)uiStateChanged:(NSNotification*)note
{
    uiState = [note userInfo];

    NSString *page = uiState[@"page"];
    BOOL inNavigation = [uiState[@"navigation"] boolValue];

    if (page) {
        if ([page isEqualToString:@"control"]) {
            state = ViewStateSearch;
        }
        else if ([page isEqualToString:@"settings"]) {
            state = ViewStateSearchSetting;
        }
        else if ([page isEqualToString:@"confirm"]) {
            state = ViewStateRouteConfirm;
        }
        else if ([page hasPrefix:@"map-page"]) {
            if (inNavigation) {
                state = ViewStateNavigation;
            } else {
                state = ViewStateMap;
            }
        }
        else if ([page hasPrefix:@"ui-id-"]) {
            state = ViewStateSearchDetail;
        }
        else if ([page isEqualToString:@"confirm_floor"]) {
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
    if (state == ViewStateSearchDetail) {
        //state = ViewStateTransition;
        //[self updateView];
        [_webView triggerWebviewControl:HLPWebviewControlBackToControl];
    }
}


- (void)updateView
{
    NavDataStore *nds = [NavDataStore sharedDataStore];
    HLPLocation *loc = [nds currentLocation];
    BOOL validLocation = loc && !isnan(loc.lat) && !isnan(loc.lng) && !isnan(loc.floor);
    BOOL devMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"developer_mode"];
    BOOL isPreviewDisabled = [[ServerConfig sharedConfig] isPreviewDisabled];
    BOOL debugFollower = [[NSUserDefaults standardUserDefaults] boolForKey:@"p2p_debug_follower"];
    BOOL peerExists = [[[NavDebugHelper sharedHelper] peers] count] > 0;

    switch(state) {
        case ViewStateMap:
//            self.navigationItem.rightBarButtonItems = debugFollower ? @[] : @[self.searchButton];
//            self.navigationItem.leftBarButtonItems = @[self.settingButton];
            self.navigationItem.rightBarButtonItems = @[self.stopButton];
            self.navigationItem.leftBarButtonItems = @[];
            break;
        case ViewStateSearch:
            self.navigationItem.rightBarButtonItems = @[self.settingButton];
            self.navigationItem.leftBarButtonItems = @[self.cancelButton];
            break;
        case ViewStateSearchDetail:
            self.navigationItem.rightBarButtonItems = @[self.backButton];
            self.navigationItem.leftBarButtonItems = @[self.cancelButton];
            break;
        case ViewStateSearchSetting:
            self.navigationItem.rightBarButtonItems = @[self.searchButton];
            self.navigationItem.leftBarButtonItems = @[];
            break;
        case ViewStateNavigation:
//            self.navigationItem.rightBarButtonItems = @[];
//            self.navigationItem.leftBarButtonItems = @[self.stopButton];
            self.navigationItem.rightBarButtonItems = @[self.stopButton];
            self.navigationItem.leftBarButtonItems = @[];
            break;
        case ViewStateRouteConfirm:
            self.navigationItem.rightBarButtonItems = @[self.cancelButton];
            self.navigationItem.leftBarButtonItems = @[];
            break;
        case ViewStateRouteCheck:
            self.navigationItem.rightBarButtonItems = @[self.doneButton];
            self.navigationItem.leftBarButtonItems = @[];
            break;
        case ViewStateTransition:
            self.navigationItem.rightBarButtonItems = @[];
            self.navigationItem.leftBarButtonItems = @[];
            break;
        case ViewStateLoading:
            self.navigationItem.rightBarButtonItems = @[];
            self.navigationItem.leftBarButtonItems = @[self.settingButton];
            break;
    }
    
    if (state == ViewStateMap) {
        if ([[DialogManager sharedManager] isAvailable]  && (!isPreviewDisabled || devMode || validLocation)) {
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
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"NavCog", @"BlindView", @"");
    
    if (debugFollower) {
        self.navigationItem.title = NSLocalizedStringFromTable(@"Follow", @"BlindView", @"");
    }
    
    if (peerExists) {
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.9 alpha:1.0];
    } else {
        self.navigationController.navigationBar.barTintColor = defaultColor;
    }
}

#pragma mark - HLPWebView

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_indicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_indicator stopAnimating];
    _indicator.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    _errorMessage.hidden = NO;
    _retryButton.hidden = NO;
    
}

- (void)speak:(NSString *)text force:(BOOL)isForce completionHandler:(void (^)(void))handler
{
    [[NavDeviceTTS sharedTTS] speak:text withOptions:@{@"force": @(isForce)} completionHandler:handler];
}

- (BOOL)isSpeaking
{
    return [[NavDeviceTTS sharedTTS] isSpeaking];
}

- (void)vibrate
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
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
    NSDictionary *uiState_ =
    @{
      @"page": page,
      @"navigation": @(inNavigation),
      };
    [[NSNotificationCenter defaultCenter] postNotificationName:WCUI_STATE_CHANGED_NOTIFICATION object:self userInfo:uiState_];
}

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

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)requestStartNavigation:(NSNotification*)note
{
    NSDictionary *options = [note userInfo];
    if (options[@"toID"] == nil) {
        return;
    }
    NSString *elv = @"";
    if (options[@"use_elevator"]) {
        elv = [options[@"use_elevator"] boolValue]?@"&elv=9":@"&elv=1";
    }
    NSString *stairs = @"";
    if (options[@"use_stair"]) {
        stairs = [options[@"use_stair"] boolValue]?@"&stairs=9":@"&stairs=1";
    }
    NSString *esc = @"";
    if (options[@"use_escalator"]) {
        esc = [options[@"use_escalator"] boolValue]?@"&esc=9":@"&esc=1";
    }
    
    NSString *hash = [NSString stringWithFormat:@"navigate=%@&dummy=%f%@%@%@", options[@"toID"],
                      [[NSDate date] timeIntervalSince1970], elv, stairs, esc];
    [_webView setLocationHash:hash];
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
        rv.start = [ratingInfo[@"start"] doubleValue]/1000.0;
        rv.end = [ratingInfo[@"end"] doubleValue]/1000.0;
        rv.from = ratingInfo[@"from"];
        rv.to = ratingInfo[@"to"];
        rv.device_id = [[NavDataStore sharedDataStore] userID];
        
        ratingInfo = nil;
    }
    if ([segue.identifier isEqualToString:@"show_dialog_wc"]){
        DialogViewController* dView = (DialogViewController*)segue.destinationViewController;
        dView.tts = [DefaultTTS new];
    }
}

- (IBAction)retry:(id)sender {
    [_webView reload];
    _errorMessage.hidden = YES;
    _retryButton.hidden = YES;
}

- (void)locationStatusChanged:(NSNotification*)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        HLPLocationStatus status = [[note userInfo][@"status"] unsignedIntegerValue];
        
        switch(status) {
            case HLPLocationStatusLocating:
                [NavUtil showWaitingForView:self.view withMessage:NSLocalizedStringFromTable(@"Locating...", @"BlindView", @"")];
                break;
            default:
                [NavUtil hideWaitingForView:self.view];
        }
    });
}

- (void) locationChanged: (NSNotification*) note
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
                                     @"type":@"ORIENTATION",
                                     @"z":@(orientation)
                                     }]
                      withName:@"Sensor"];
            lastOrientationSent = now;
        }
        
        
        location = locations[@"actual"];
        if (!location || [location isEqual:[NSNull null]]) {
            return;
        }
        
        /*
         if (isnan(location.lat) || isnan(location.lng)) {
         return;
         }
         */
        
        if (now < lastLocationSent + [[NSUserDefaults standardUserDefaults] doubleForKey:@"webview_update_min_interval"]) {
            if (!location.params) {
                return;
            }
            //return; // prevent too much send location info
        }
        
        double floor = location.floor;
        
        [_webView sendData:@{
                             @"lat":@(location.lat),
                             @"lng":@(location.lng),
                             @"floor":@(floor),
                             @"accuracy":@(location.accuracy),
                             @"rotate":@(0), // dummy
                             @"orientation":@(999), //dummy
                             @"debug_info":location.params?location.params[@"debug_info"]:[NSNull null],
                             @"debug_latlng":location.params?location.params[@"debug_latlng"]:[NSNull null]
                             }
                  withName:@"XYZ"];
        
        lastLocationSent = now;
        
        if (!self.destId || isNaviStarted) {
            return;
        }
        if ([[NavDataStore sharedDataStore] reloadDestinations:NO]) {
            NSString *msg = [MiraikanUtil isPreview]
                ? NSLocalizedString(@"Loading preview",@"")
                : NSLocalizedString(@"Loading, please wait",@"");
            [NavUtil showModalWaitingWithMessage:msg];
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"developer_mode"]) {
        _webView.isDeveloperMode = @([[NSUserDefaults standardUserDefaults] boolForKey:@"developer_mode"]);
    }
}

@end
