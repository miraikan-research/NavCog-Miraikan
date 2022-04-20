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

#import "BlindViewController.h"
#import "NavSound.h"
#import "NavDeviceTTS.h"
#import "LocationEvent.h"
#import "NavUtil.h"
#import "NavDataStore.h"
#import "SettingViewController.h"
#import "NavBlindWebView.h"
#import "POIViewController.h"
#import "ServerConfig+Preview.h"
#import "ExpConfig.h"
#import "Logging.h"
#import "WebViewController.h"


#import <CoreMotion/CoreMotion.h>


@interface BlindViewController () {
}

@end


@implementation BlindViewController {
    HLPPreviewer *previewer;
    HLPPreviewCommander *commander;
    NSTimer *locationTimer;

    NSArray<NSObject*>* showingFeatures;
    NSDictionary*(^showingStyle)(NSObject* obj);
    NSObject* selectedFeature;
    HLPLocation *center;
    BOOL loaded;
    
    HLPPreviewEvent *current;
    HLPLocation *userLocation;
    HLPLocation *animLocation;
    
    CMMotionManager *motionManager;
    NSOperationQueue *motionQueue;
    
    double baseYaw;
#define YAWS_MAX 100
    double yaws[YAWS_MAX];
    long yawsMax;
    int yawsIndex;
    NSTimeInterval lastGyroCommand;
    double prevDiff;
    
    double duration;
    int activeCount;
    NSString *logFile;
    NSTimer *timeout;

    NSTimer *checkMapCenterTimer;
}

- (void)dealloc
{
    _webView.delegate = nil;
    _webView = nil;
    
    _settingButton = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"developer_mode"];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.devUp setTitle:@"Up" forState:UIControlStateNormal];
    [self.devDown setTitle:@"Down" forState:UIControlStateNormal];
    [self.devLeft setTitle:@"Left" forState:UIControlStateNormal];
    [self.devRight setTitle:@"Right" forState:UIControlStateNormal];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    _webView = [[NavBlindWebView alloc] initWithFrame:CGRectMake(0,0,0,0) configuration:[[WKWebViewConfiguration alloc] init]];
    _webView.isDeveloperMode = [ud boolForKey:@"developer_mode"];
    [self.view addSubview:_webView];
    for(UIView *v in self.view.subviews) {
        if (v != _webView) {
            [self.view bringSubviewToFront:v];
        }
    }
    _webView.userMode = [ud stringForKey:@"user_mode"];
    _webView.config = @{
                        @"serverHost":[ud stringForKey:@"selected_hokoukukan_server"],
                        @"serverContext":[ud stringForKey:@"hokoukukan_server_context"],
                        @"usesHttps":@([ud boolForKey:@"https_connection"])
                        };
    _webView.delegate = self;
    //_webView.tts = self;
    [_webView setFullScreenForView:self.view];
    
    _indicator.accessibilityLabel = NSLocalizedString(@"Loading, please wait", @"");
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, _indicator);
    
    checkMapCenterTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkMapCenter:) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:ROUTE_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged:) name:UIAccessibilityVoiceOverStatusChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configChanged:) name:EXP_ROUTES_CHANGED_NOTIFICATION object:nil];
    
    motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 0.1;
    motionQueue = [[NSOperationQueue alloc] init];
    
    previewer = [[HLPPreviewer alloc] init];
    previewer.delegate = self;
    
    commander = [[HLPPreviewCommander alloc] init];
    commander.delegate = self;

    _cover.delegate = self;
}

- (void) voiceOverStatusChanged:(NSNotification*)note
{
    [self updateView];
}

- (void) resetMotionAverage
{
    [motionQueue addOperationWithBlock:^{
        yawsIndex = 0;
        lastGyroCommand = 0;
    }];
}

double average(double array[], long count) {
    double x = 0;
    double y = 0;
    for(int i = 0; i < count; i++) {
        x += cos(array[i]);
        y += sin(array[i]);
    }
    return atan2(y, x);
}

double stdev(double array[], long count) {
    double ave = average(array, count);
    double dev = 0;
    for(int i = 0; i < count; i++) {
        dev += (array[i] - ave) * (array[i] - ave);
    }
    return sqrt(dev);
}

- (void) routeChanged:(NSNotification*)note
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NavDataStore *nds = [NavDataStore sharedDataStore];
    [previewer startAt:nds.from.location];
    
    yawsMax = 20;
    [self resetMotionAverage];
    [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:motionQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
        if (previewer == nil || previewer.isActive == NO) {
            return;
        }
        
        yaws[yawsIndex] = motion.attitude.yaw;
        yawsIndex = (yawsIndex+1)%yawsMax;
        
        if (stdev(yaws, yawsMax) < M_PI * 2.5 / 180.0) {
            baseYaw = average(yaws, yawsMax);
        }
        
        double diff = [HLPLocation normalizeDegree:(baseYaw - motion.attitude.yaw)/M_PI*180];
        HLPPreviewEvent *right = current.right;
        HLPPreviewEvent *left = current.left;
        if (fabs(diff) > 20 &&  lastGyroCommand + 3 < NSDate.date.timeIntervalSince1970) {
            if (right && diff > right.turnedAngle - 20) {
                if (isnan(prevDiff) || prevDiff < 0) {
                    NSLog(@"gyro,right,%f,%f,%f",right.turnedAngle,diff,NSDate.date.timeIntervalSince1970);
                    [self faceRight];
                    prevDiff = diff;
                    yawsIndex = 0;
                    lastGyroCommand = NSDate.date.timeIntervalSince1970;
                }
            }
            else if (left && diff < left.turnedAngle + 20) {
                if (isnan(prevDiff) || prevDiff > 0) {
                    NSLog(@"gyro,left,%f,%f,%f",left.turnedAngle,diff,NSDate.date.timeIntervalSince1970);
                    [self faceLeft];
                    prevDiff = diff;
                    yawsIndex = 0;
                    lastGyroCommand = NSDate.date.timeIntervalSince1970;
                }
            }
        }
        else {
            prevDiff = NAN;
        }
        
        /*
        if (fabs(diff) > [[NSUserDefaults standardUserDefaults] integerForKey:@"gyro_motion_threshold"]) {
            if (isnan(prevDiff)) {
                if (diff > 0) { // right
                    NSLog(@"gyro,right,%f",NSDate.date.timeIntervalSince1970);
                    [self faceRight];
                } else { // left
                    NSLog(@"gyro,left,%f",NSDate.date.timeIntervalSince1970);
                    [self faceLeft];
                }
                prevDiff = diff;
            }
        } else {
            prevDiff = NAN;
        }
         */
    }];
    
    [self updateView];
}

- (void) _showRoute
{
    NavDataStore *nds = [NavDataStore sharedDataStore];

    NSArray *route = nds.route;
    
    if (!route) {// show all if no route
        route = [[NavDataStore sharedDataStore].features filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            if ([evaluatedObject isKindOfClass:HLPLink.class]) {
                HLPLink *link = (HLPLink*)evaluatedObject;
                return (link.sourceHeight == current.location.floor || link.targetHeight == current.location.floor);
            }
            return NO;
        }]];
    }
    [_webView showRoute:route];
}

- (void) checkMapCenter:(NSTimer*)timer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView getCenterWithCompletion:^(HLPLocation *loc) {
            if (loc != nil) {
                [NavDataStore sharedDataStore].mapCenter = loc;
                HLPLocation *cloc = [NavDataStore sharedDataStore].currentLocation;
                if (isnan(cloc.lat) || isnan(cloc.lng)) {
                    NSDictionary *param =
                    @{
                      @"floor": @(loc.floor),
                      @"lat": @(loc.lat),
                      @"lng": @(loc.lng),
                      @"sync": @(YES)
                      };
                    [[NSNotificationCenter defaultCenter] postNotificationName:MANUAL_LOCATION_CHANGED_NOTIFICATION object:self userInfo:param];
                    
                }
                [self updateView];
                [timer invalidate];
            }
        }];
    });
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidAppear:(BOOL)animated
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"first_launch"]) {
        NSURL *url = [WebViewController hulopHelpPageURLwithType:@"help" languageDetection:YES];
        __weak typeof(self) weakself = self;
        [WebViewController checkHttpStatusWithURL:url completionHandler:^(NSURL * _Nonnull url, NSInteger statusCode) {
            __weak NSURL *weakurl = url;
            dispatch_async(dispatch_get_main_queue(), ^{
                WebViewController *vc = [WebViewController getInstance];
                if (statusCode == 200) {
                    vc.url = weakurl;
                } else {
                    vc.url = [WebViewController hulopHelpPageURLwithType:@"help" languageDetection:NO];
                }
                vc.title = NSLocalizedString(@"help", @"");
                [weakself.navigationController showViewController:vc sender:weakself];
            });
        }];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"first_launch"];
    }
    
    [self updateView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [checkMapCenterTimer invalidate];
}

#pragma mark - HLPPreivewCommanderDelegate

- (void) playStep
{
    [[NavSound sharedInstance] playStep:nil];
}

- (void) playNoStep
{
    [[NavSound sharedInstance] playNoStep];
}

- (void)playSuccess
{
    [[NavSound sharedInstance] vibrate:nil];
    //[[NavSound sharedInstance] playSuccess];
    [[NavSound sharedInstance] playAnnounceNotification];
}

- (void)playFail
{
    [[NavSound sharedInstance] playFail];
}

- (void) vibrate
{
    [[NavSound sharedInstance] vibrate:nil];
}

- (BOOL)isSpeaking
{
    return [[NavDeviceTTS sharedTTS] isSpeaking];
}

- (void)speak:(NSString *)text force:(BOOL)isForce completionHandler:(void (^)(void))handler
{
    [[NavDeviceTTS sharedTTS] speak:text withOptions:@{@"force": @(isForce)} completionHandler:handler];
}

- (void)speak:(NSString *)text withOptions:(NSDictionary *)options completionHandler:(void (^)())handler
{
    [[NavDeviceTTS sharedTTS] speak:text withOptions:options completionHandler:handler];
}

- (BOOL)isAutoProceed
{
    return previewer.isAutoProceed;
}

#pragma mark - MKWebViewDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [_indicator startAnimating];
    _indicator.hidden = NO;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [_indicator stopAnimating];
    _indicator.hidden = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self insertScript];
    });
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [_indicator stopAnimating];
    _indicator.hidden = YES;
    _retryButton.hidden = NO;
    _errorMessage.hidden = NO;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [_indicator stopAnimating];
    _indicator.hidden = YES;
    _retryButton.hidden = NO;
    _errorMessage.hidden = NO;
}

#pragma mark - HLPPreviewerDelegate

-(void)_active
{
    activeCount = 10;
}

-(void)previewStarted:(HLPPreviewEvent*)event
{
    logFile = [Logging startLog:false];
    duration = 0;
    [self _active];
    
    if ([[ServerConfig sharedConfig] isExpMode]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            timeout = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                if (activeCount > 0) {
                    duration += 1;
                    NSLog(@"Duration:%f",duration);
                    NSDictionary *route = [[ExpConfig sharedConfig] currentRoute];
                    if (route) {
                        double limit = [route[@"limit"] doubleValue];
                        double elapsed_time = [[ExpConfig sharedConfig] elapsedTimeForRoute:route];
                        
                        if (elapsed_time + duration >= limit) {
                            [previewer stop];
                            [self speak:@"Time is up." withOptions:@{@"force":@(NO)} completionHandler:nil];
                            [timer invalidate];
                        } else {
                            if (round(duration) >= 10) {
                                [[ExpConfig sharedConfig] endExpDuration:duration withLogFile:logFile withComplete:^{
                                    duration -= 10;
                                }];
                            }
                        }
                    }
                }
                activeCount--;
            }];
        });
    }
    
    [commander previewStarted:event];
    current = event;
    [self _showRoute];
}

-(void)previewUpdated:(HLPPreviewEvent*)event
{
    [commander previewUpdated:event];
    current = event;
}

-(void)previewStopped:(HLPPreviewEvent*)event
{
    if (timeout) {
        [timeout invalidate];
        timeout = nil;
    }
    
    [motionManager stopDeviceMotionUpdates];
    
    [commander previewStopped:event];
    [_webView clearRoute];
    current = nil;
    userLocation = nil;
    animLocation = nil;
    [locationTimer invalidate];
    locationTimer = nil;
    [self updateView];

    dispatch_async(dispatch_get_main_queue(), ^{
        [Logging stopLog];
        if ([[ServerConfig sharedConfig] isExpMode]) {
            [NavUtil showModalWaitingWithMessage:@"Saving log..."];
            [[ExpConfig sharedConfig] endExpDuration:duration withLogFile:logFile withComplete:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NavUtil hideModalWaiting];
                });
            }];
        }
    });
}

- (void)userMoved:(double)distance
{
    [commander userMoved:distance];
}

- (void)userLocation:(HLPLocation*)location
{
    if (!userLocation) {
        userLocation = [[HLPLocation alloc] init];
        [userLocation update:location];
        [userLocation updateOrientation:location.orientation withAccuracy:0];
        animLocation = [[HLPLocation alloc] init];
        [animLocation update:location];
    } else {
        if (!animLocation) {
            animLocation = [[HLPLocation alloc] init];
        }
        [animLocation update:location];
        [animLocation updateOrientation:location.orientation withAccuracy:0];
    }
    [self startLocationAnimation];
}

- (void)remainingDistance:(double)distance
{
    [commander remainingDistance:distance];
}

- (void)startLocationAnimation
{
    if (!locationTimer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            locationTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer * _Nonnull timer) {
                double r = 0.5;
                [userLocation updateFloor:animLocation.floor];
                [userLocation updateLat:userLocation.lat*r + animLocation.lat*(1-r)
                                    Lng:userLocation.lng*r + animLocation.lng*(1-r)];
                
                double diff = [HLPLocation normalizeDegree:animLocation.orientation - userLocation.orientation];
                double ori = userLocation.orientation + diff * (1-r);

                [userLocation updateOrientation:ori withAccuracy:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showLocation];
                });
            }];
        });
    }
}

- (void) showLocation
{
    double orientation = -userLocation.orientation / 180 * M_PI;
    
    [_webView sendData:@[@{
                           @"type":@"ORIENTATION",
                           @"z":@(orientation)
                           }]
            withName:@"Sensor"];
    
    [_webView sendData:@{
                       @"lat":@(userLocation.lat),
                       @"lng":@(userLocation.lng),
                       @"floor":@(userLocation.floor),
                       @"accuracy":@(1),
                       @"rotate":@(0), // dummy
                       @"orientation":@(999), //dummy
                       @"debug_info":[NSNull null],
                       @"debug_latlng":[NSNull null]
                       }
            withName:@"XYZ"];
}

- (void)routeNotFound
{
    [self speak:@"Route not found" withOptions:@{@"force":@(NO)} completionHandler:nil];
    [[NavSound sharedInstance] playFail];
}

#pragma mark - PreviewCommandDelegate

- (void)speakAtPoint:(CGPoint)point
{
    [self _active];
    // not implemented
    [self stopSpeaking];
}

- (void)stopSpeaking
{
    [self _active];
    [previewer autoStepForwardStop];
    [[NavDeviceTTS sharedTTS] stop:NO];
}

- (void)speakCurrentPOI
{
    [self _active];
    [previewer autoStepForwardStop];
    [commander previewCurrentFull];
}

- (void)selectCurrentPOI
{
    [self _active];
    [previewer autoStepForwardStop];
    if (current && current.targetFacilityPOIs) {
        POIViewController *vc = [[UIStoryboard storyboardWithName:@"Preview" bundle:nil] instantiateViewControllerWithIdentifier:@"poi_view"];
        vc.pois = current.targetFacilityPOIs;
        if ([vc isContentAvailable]) {
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [[NavSound sharedInstance] playFail];
            [self speak:@"No detail information. " withOptions:@{@"force":@(NO)} completionHandler:nil];
        }
    }
}

- (void)quit
{
    NSString *title = @"Quit Preview";
    NSString *message = @"Are you sure to quit preview?";
    NSString *quit = @"Quit";
    NSString *cancel = @"Cancel";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:quit
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                  [previewer stop];
                                              }]];
    [alert addAction:[UIAlertAction actionWithTitle:cancel
                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                              }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - PreviewTraverseDelegate

- (void)gotoBegin
{
    [self _active];
    [self resetMotionAverage];
    [previewer gotoBegin];
}

- (void)gotoEnd
{
    [self _active];
    [self resetMotionAverage];
    [previewer gotoEnd];
}

- (void)stepForward
{
    [self _active];
    [self resetMotionAverage];
    [previewer stepForward];
}

- (void)stepBackward
{
    [self _active];
    [self resetMotionAverage];
    [previewer stepBackward];
}

- (void)jumpForward
{
    [self _active];
    [self resetMotionAverage];
    [previewer jumpForward];
}

- (void)jumpBackward
{
    [self _active];
    [self resetMotionAverage];
    [previewer jumpBackward];
}

- (void)faceRight
{
    [self _active];
    [previewer faceRight];
}

- (void)faceLeft
{
    [self _active];
    [previewer faceLeft];
}

- (void)autoStepForwardUp
{
    [self _active];
    [self resetMotionAverage];
    [[NavSound sharedInstance] playStep:nil];
    [previewer autoStepForwardUp];
}

- (void)autoStepForwardDown
{
    [self _active];
    [[NavSound sharedInstance] playStep:nil];
    [previewer autoStepForwardDown];
}

#pragma mark - private

- (void) updateView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NavDataStore *nds = [NavDataStore sharedDataStore];
        
        BOOL hasCenter = [nds mapCenter] != nil;
        
        self.searchButton.enabled = hasCenter;
        if (previewer.isActive) {
            self.cover.hidden = NO;
            [self.cover becomeFirstResponder];
            self.searchButton.title = @"Quit";
            self.searchButton.accessibilityLabel = @"Quit preview";
        } else {
            self.cover.hidden = YES;
            /*
            if ([[ServerConfig sharedConfig] isExpMode]) {
                self.searchButton.title = @"Select";
                self.searchButton.accessibilityLabel = @"Select a route";
            } else {
            }*/
            self.searchButton.title = @"Search";
            self.searchButton.accessibilityLabel = @"Search";
        }
    });
}

- (void) insertScript
{
    NSString *jspath = [[NSBundle mainBundle] pathForResource:@"fingerprint" ofType:@"js"];
    NSString *js = [[NSString alloc] initWithContentsOfFile:jspath encoding:NSUTF8StringEncoding error:nil];
    [_webView evaluateJavaScript:js completionHandler:nil];
}

- (void) showPOIs:(NSArray<HLPObject*>*)pois
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView evaluateJavaScript:@"$hulop.map.clearRoute()" completionHandler:^(id _Nullable ret, NSError * _Nullable error) {
            NSArray *route = [pois filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                if ([evaluatedObject isKindOfClass:HLPLink.class]) {
                    HLPLink *link = (HLPLink*)evaluatedObject;
                    return (link.sourceHeight == center.floor || link.targetHeight == center.floor);
                }
                return NO;
            }]];
            
            [_webView showRoute:route];
        }];
    });
    
    [self showFeatures:pois withStyle:^NSDictionary *(NSObject *obj) {
        if ([obj isKindOfClass:HLPPOI.class]) {
            HLPPOI* p = (HLPPOI*)obj;
            if (isnan(center.floor) || isnan(p.height) || center.floor == p.height){
                NSString *name = @"P";
                if (p.poiCategoryString) {
                    name = [name stringByAppendingString:[p.poiCategoryString substringToIndex:1]];
                }
                
                return @{
                         @"lat": p.geometry.coordinates[1],
                         @"lng": p.geometry.coordinates[0],
                         @"count": name
                         };
            }
        }
        else if ([obj isKindOfClass:HLPFacility.class]) {
            HLPFacility* f = (HLPFacility*)obj;
            /*
             HLPNode *n = [poim nodeForFaciligy:f];
             if (isnan(center.floor) ||
             (n && n.height == center.floor) ||
             (!n && !isnan(f.height) && f.height == center.floor)) {
             
             return @{
             @"lat": f.geometry.coordinates[1],
             @"lng": f.geometry.coordinates[0],
             @"count": @"F"
             };
             }
             */
        }
        return (NSDictionary*)nil;
    }];
}

- (void) clearFeatures
{
    showingFeatures = @[];
    showingStyle = nil;
    selectedFeature = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView evaluateJavaScript:@"$hulop.fp.showFingerprints([]);" completionHandler:nil];
    });
}

- (void) showFeatures:(NSArray<NSObject*>*)features withStyle:(NSDictionary*(^)(NSObject* obj))styleFunction
{
    showingFeatures = features;
    showingStyle = styleFunction;

    NSMutableArray *temp = [@[] mutableCopy];
    for(NSObject *f in features) {
        NSDictionary *dict = styleFunction(f);
        if (dict) {
            [temp addObject:dict];
        }
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:temp options:0 error:nil];
    NSString* str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSString* script = [NSString stringWithFormat:@"$hulop.fp.showFingerprints(%@);", str];
    //NSLog(@"%@", script);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webView evaluateJavaScript:script completionHandler:nil];
    });
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [_indicator stopAnimating];
    _indicator.hidden = YES;
    _retryButton.hidden = NO;
    _errorMessage.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - HLPWebView

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    [segue destinationViewController].restorationIdentifier = segue.identifier;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NavUtil hideWaitingForView:self.view];
    });
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"show_search"]) {
        if (previewer.isActive) {
            [previewer stop];
            return NO;
        }
        [_webView getCenterWithCompletion:^(HLPLocation *loc) {
            [NavDataStore sharedDataStore].mapCenter = loc;
        }];
        
        UIViewController *vc = nil;
        
        BOOL isExpMode = [[ServerConfig sharedConfig] isExpMode];
        BOOL useDeviceId = [[ServerConfig sharedConfig] useDeviceId];
        NSArray *routes = [[ExpConfig sharedConfig] expUserRoutes];
        
        if (isExpMode) {
            if (!routes) { // require authentication
                if (useDeviceId) {
                    [NavUtil showModalWaitingWithMessage:@"loading..."];
                    NSString *uuid = [UIDevice currentDevice].identifierForVendor.UUIDString;
                    [[ExpConfig sharedConfig] requestUserInfo:uuid withComplete:^(NSDictionary *dic) {
                        if (dic) {
                            [[ExpConfig sharedConfig] requestRoutesConfig:^(NSDictionary *routes) {
                                // noop
                            }];
                        } else {
                            //error
                        }
                    }];
                } else { // require login
                    vc = [[UIStoryboard storyboardWithName:@"Preview" bundle:nil] instantiateViewControllerWithIdentifier:@"exp_view"];
                }
            } else {
                if (routes.count > 0) { // with route
                    vc = [[UIStoryboard storyboardWithName:@"Preview" bundle:nil] instantiateViewControllerWithIdentifier:@"setting_view"];
                    vc.restorationIdentifier = @"exp_settings";
                } else { // no route
                    vc = [[UIStoryboard storyboardWithName:@"Preview" bundle:nil] instantiateViewControllerWithIdentifier:@"search_view"];
                }
            }
        } else {
            vc = [[UIStoryboard storyboardWithName:@"Preview" bundle:nil] instantiateViewControllerWithIdentifier:@"search_view"];
        }
        if (vc) {
            [self.navigationController pushViewController:vc animated:YES];
        }
        return NO;
    }
    return YES;
}

- (void)configChanged:(NSNotification*)note
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self shouldPerformSegueWithIdentifier:@"show_search" sender:self];
    });
}

@end
