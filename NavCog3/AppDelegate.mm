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

#import "AppDelegate.h"
#import "Logging.h"
#import "SettingViewController.h"
#import <HLPLocationManager/HLPLocationManager+Player.h>
#import "LocationEvent.h"
#import "NavDataStore.h"
#import "NavDeviceTTS.h"
#import "NavSound.h"
#import <Speech/Speech.h> // for Swift header
#import <AVFoundation/AVFoundation.h>
#import "ScreenshotHelper.h"
#import "NavUtil.h"
#import "ServerConfig.h"

@import HLPDialog;

#define IS_IOS11orHIGHER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.0)

void NavNSLog(NSString* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    if (!isatty(STDERR_FILENO))
    {
        fprintf(stdout, "%s\n", [msg UTF8String]);
    }
    va_start(args, fmt);
    NSLogv(fmt, args);
    va_end(args);
}

@interface AppDelegate ()

@end

@implementation AppDelegate {
    BOOL secondOrLater;
    NSTimeInterval lastActiveTime;
    long locationChangedTime;
    NSString *locationFilePath;
    NSFileHandle *locationFileHandle;

    int temporaryFloor;
    int currentFloor;
    int continueFloorCount;
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // [Logging startLog];

    locationChangedTime = 0;

    // Notification
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    
    // need to call once after install
    [SettingViewController setup];

    // TODO need to move
    NavDataStore *nds = [NavDataStore sharedDataStore];
    nds.userID = [UIDevice currentDevice].identifierForVendor.UUIDString;

    [DialogManager sharedManager];

    [NavDeviceTTS sharedTTS];
    [NavSound sharedInstance];
    [NavUtil switchAccessibilityMethods];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    _backgroundID = UIBackgroundTaskInvalid;
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:HLPSettingChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableAcceleration:) name:DISABLE_ACCELEARATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableAcceleration:) name:ENABLE_ACCELEARATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableStabilizeLocalize:) name:DISABLE_STABILIZE_LOCALIZE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableStabilizeLocalize:) name:ENABLE_STABILIZE_LOCALIZE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocationRestart:) name:REQUEST_LOCATION_RESTART object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocationStop:) name:REQUEST_LOCATION_STOP object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocationHeadingReset:) name:REQUEST_LOCATION_HEADING_RESET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocationReset:) name:REQUEST_LOCATION_RESET object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocationUnknown:) name:REQUEST_LOCATION_UNKNOWN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestBackgroundLocation:) name:REQUEST_BACKGROUND_LOCATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLogReplay:) name:REQUEST_LOG_REPLAY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLogReplayStop:) name:REQUEST_LOG_REPLAY_STOP object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLocationInit:) name:REQUEST_LOCATION_INIT object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverConfigChanged:) name:SERVER_CONFIG_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChanged:) name:NAV_LOCATION_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildingChanged:) name:BUILDING_CHANGED_NOTIFICATION object:nil];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud addObserver:self forKeyPath:@"nSmooth" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"nStates" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"rssi_bias" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"wheelchair_pdr" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"mixProba" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"rejectDistance" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"diffusionOrientationBias" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"location_tracking" options:NSKeyValueObservingOptionNew context:nil];
    
    [ud addObserver:self forKeyPath:@"background_mode" options:NSKeyValueObservingOptionNew context:nil];
    [ud addObserver:self forKeyPath:@"isMoveLogStart" options:NSKeyValueObservingOptionNew context:nil];
    
    return YES;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionSound
                      | UNNotificationPresentationOptionAlert
                      | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // Completion Actions
    completionHandler();
    NSString *eventId = response.notification.request.identifier;
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    NSString *nodeId = userInfo[@"nodeId"];
    NSString *facilityId = userInfo[@"facilityId"];
    NSDate *date = userInfo[@"date"];

    // Remove the notification and open the view
    if (eventId) {
        [center removeDeliveredNotificationsWithIdentifiers:@[eventId]];
        [MiraikanUtil openTalkWithEventId:eventId date:date nodeId:nodeId facilityId:facilityId];
    }
}

- (void)settingChanged:(NSNotification*)note
{
    if ([note.object isKindOfClass:HLPSetting.class]) {
        HLPSetting* setting = note.object;
        if ([setting.name isEqualToString:@"record_screenshots"]) {
            [self checkRecordScreenshots];
        }
    }
}

- (void)checkRecordScreenshots
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"record_screenshots"]) {
        [self startRecordScreenshots];
    } else {
        [self stopRecordScreenshots];
    }
}

- (void)startRecordScreenshots
{
    [[ScreenshotHelper sharedHelper] startRecording];
}

- (void)stopRecordScreenshots
{
    [[ScreenshotHelper sharedHelper] stopRecording];
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

void uncaughtExceptionHandler(NSException *exception)
{
    NSLog(@"%@", exception.name);
    NSLog(@"%@", exception.reason);
    NSLog(@"%@", exception.callStackSymbols);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    lastActiveTime = [[NSDate date] timeIntervalSince1970];

    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_LOCATION_SAVE object:self];
    [[DialogManager sharedManager] pause];

    UIApplication *app = [UIApplication sharedApplication];
    self->_backgroundID = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:self->_backgroundID];
        self->_backgroundID = UIBackgroundTaskInvalid;
    }];
}

- (void)serverConfigChanged:(NSNotification*)note
{
    NSMutableDictionary *config = [note.userInfo mutableCopy];
    config[@"conv_client_id"] = [NavDataStore sharedDataStore].userID;
    [DialogManager sharedManager].config = config;
}

- (void)locationChanged:(NSNotification*)note
{
    HLPLocation *loc = [NavDataStore sharedDataStore].currentLocation;
    [[DialogManager sharedManager] changeLocationWithLat:loc.lat lng:loc.lng floor:loc.floor];
}

- (void)buildingChanged:(NSNotification*)note
{
    [[DialogManager sharedManager] changeBuilding:note.userInfo[@"building"]];
}

#pragma mark - NotificationCenter Observers

- (void)disableAcceleration:(NSNotification*)note
{
    [HLPLocationManager sharedManager].isAccelerationEnabled = NO;
}

- (void)enableAcceleration:(NSNotification*)note
{
    [HLPLocationManager sharedManager].isAccelerationEnabled = YES;
}

- (void)disableStabilizeLocalize:(NSNotification*)note
{
    [HLPLocationManager sharedManager].isStabilizeLocalizeEnabled = NO;
}

- (void)enableStabilizeLocalize:(NSNotification*)note
{
    [HLPLocationManager sharedManager].isStabilizeLocalizeEnabled = YES;
}

- (void) requestLocationRestart:(NSNotification*) note
{
    [[HLPLocationManager sharedManager] restart];    
}

- (void) requestLocationStop:(NSNotification*) note
{
    [[HLPLocationManager sharedManager] stop];
}

- (void) requestLocationUnknown:(NSNotification*) note
{
    [[HLPLocationManager sharedManager] makeStatusUnknown];
}

- (void) requestLocationReset:(NSNotification*) note
{
    NSDictionary *properties = [note userInfo];
    HLPLocation *loc = properties[@"location"];
    double std_dev = [[NSUserDefaults standardUserDefaults] doubleForKey:@"reset_std_dev"];
    [loc updateOrientation:NAN withAccuracy:std_dev];
    [[HLPLocationManager sharedManager] resetLocation:loc];
}

- (void) requestLocationHeadingReset:(NSNotification*) note
{
    NSDictionary *properties = [note userInfo];
    HLPLocation *loc = properties[@"location"];
    double heading = [properties[@"heading"] doubleValue];
    double std_dev = [[NSUserDefaults standardUserDefaults] doubleForKey:@"reset_std_dev"];
    [loc updateOrientation:heading withAccuracy:std_dev];
    [[HLPLocationManager sharedManager] resetLocation:loc];
}

- (void) requestLocationInit:(NSNotification*) note
{
    HLPLocationManager *manager = [HLPLocationManager sharedManager];
    manager.delegate = self;
}

- (void) requestBackgroundLocation:(NSNotification*) note
{
    BOOL backgroundMode = (note && [[note userInfo][@"value"] boolValue]) ||
    [[NSUserDefaults standardUserDefaults] boolForKey:@"background_mode"];
    [HLPLocationManager sharedManager].isBackground = backgroundMode;
}

- (void) requestLogReplay:(NSNotification*) note
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSDictionary *option =
    @{
      @"replay_in_realtime": [ud valueForKey:@"replay_in_realtime"],
      @"replay_sensor": [ud valueForKey:@"replay_sensor"],
      @"replay_show_sensor_log": [ud valueForKey:@"replay_show_sensor_log"],
      @"replay_with_reset": [ud valueForKey:@"replay_with_reset"],
      };
    BOOL bNavigation = [[NSUserDefaults standardUserDefaults] boolForKey:@"replay_navigation"];
    [[HLPLocationManager sharedManager] startLogReplay:note.userInfo[@"path"] withOption:option withLogHandler:^(NSString *line) {
        if (bNavigation) {
            NSArray *v = [line componentsSeparatedByString:@" "];
            if (v.count > 3 && [v[3] hasPrefix:@"initTarget"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_PROCESS_INIT_TARGET_LOG object:self userInfo:@{@"text":line}];
                });
            }
            if (v.count > 3 && [v[3] hasPrefix:@"showRoute"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_PROCESS_SHOW_ROUTE_LOG object:self userInfo:@{@"text":line}];
                });
            }
        }
    }];
}

- (void)requestLogReplayStop:(NSNotification*) note {
    [[HLPLocationManager sharedManager] stopLogReplay];
}

#pragma mark - HLPLocationManagerDelegate

- (void)locationManager:(HLPLocationManager *)manager didLocationUpdate:(HLPLocation *)location
{
    if (isnan(location.lat) || isnan(location.lng)) {
        // handle location information nan here
        return;
    }

    long now = (long)([[NSDate date] timeIntervalSince1970]*1000);

    NSMutableDictionary *data =
    [@{
       //@"x": @(refPose.x()),
       //@"y": @(refPose.y()),
       //@"z": @(refPose.z()),
       @"floor":@(location.floor),
       @"lat": @(location.lat),
       @"lng": @(location.lng),
       @"speed":@(location.speed),
       @"orientation":@(location.orientation),
       @"accuracy":@(location.accuracy),
       @"orientationAccuracy":@(location.orientationAccuracy),
       //@"anchor":@{
       //@"lat":anchor[@"latitude"],
       //@"lng":anchor[@"longitude"]
       //},
       //@"rotate":anchor[@"rotate"]
       } mutableCopy];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DebugMode"]) {
        NSDateFormatter* dateFormatte = [[NSDateFormatter alloc] init];
        NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian];
        [dateFormatte setCalendar: calendar];
        [dateFormatte setLocale:[NSLocale systemLocale]];
        [dateFormatte setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        NSString* dateString = [dateFormatte stringFromDate:[NSDate date]];
        [self writeLocation: [NSString stringWithFormat: @"%@,%@,%@,%@,%@,%@,%@,%@\n", dateString, @(location.lng), @(location.lat), @(location.accuracy), @(location.floor), @(location.speed), @(location.orientation), @(location.orientationAccuracy)]];
    }
    
    // Floor change continuity check
    if (temporaryFloor == location.floor) {
        continueFloorCount++;
    } else {
        continueFloorCount = 0;
    }
    temporaryFloor = location.floor;

    if ((continueFloorCount > 8) &&
        (locationChangedTime + 300 > now)) {
        currentFloor = temporaryFloor;
        [[NSNotificationCenter defaultCenter] postNotificationName:LOCATION_CHANGED_NOTIFICATION object:self userInfo:data];
    }
    locationChangedTime = now;
}

- (void)locationManager:(HLPLocationManager *)manager didLocationStatusUpdate:(HLPLocationStatus)status
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NAV_LOCATION_STATUS_CHANGE
                                                        object:self
                                                      userInfo:@{@"status":@(status)}];
}

- (void)locationManager:(HLPLocationManager *)manager didUpdateOrientation:(double)orientation withAccuracy:(double)accuracy
{
    NSDictionary *dic = @{
                          @"orientation": @(orientation),
                          @"orientationAccuracy": @(accuracy)
                          };

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIENTATION_CHANGED_NOTIFICATION object:self userInfo:dic];
}

- (void)locationManager:(HLPLocationManager*)manager didLogText:(NSString *)text
{
    if ([Logging isLogging] && [Logging isSensorLogging]) {
        NSLog(@"%@", text);
    }
}

#pragma mark - AppDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:DATA_INITIALIZE_RESTART object:self userInfo:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication.sharedApplication endBackgroundTask:_backgroundID];
    
    if (secondOrLater) {
        ServerConfig *config = [ServerConfig sharedConfig];
        
        // Initialization data downloaded check
        if (config.checkDataDownloaded) {
            
            HLPLocationManager *manager = [HLPLocationManager sharedManager];
            manager.delegate = self;
            if (!manager.isActive) {
                [manager start];
            }
            if ([[NSDate date] timeIntervalSince1970] - lastActiveTime > 30) {
                [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_LOCATION_RESTART object:self];
            }
            [Logging stopLog];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logging_to_file"]) {
                BOOL sensor = [[NSUserDefaults standardUserDefaults] boolForKey:@"logging_sensor"];
                [Logging startLog:sensor];
            }
        }
    }
    [self checkRecordScreenshots];
    secondOrLater = YES;
    
    [self beginReceivingRemoteControlEvents];
    
    // play nosound audio to activate remote control
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"nosound" withExtension:@"aiff"];
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [player play];
    
    // prevent automatic sleep
    application.idleTimerDisabled = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self endReceivingRemoteControlEvents];
}

- (void) beginReceivingRemoteControlEvents {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}
- (void) endReceivingRemoteControlEvents {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {
        NSLog(@"remoteControlReceivedWithEvent,%ld,%ld", event.type, event.subtype);
        [[NSNotificationCenter defaultCenter] postNotificationName:REMOTE_CONTROL_EVENT object:self userInfo:@{@"event":event}];
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([[url scheme] isEqualToString:@"navcog3"]) {
        if ([[url host] isEqualToString:@"start_navigation"]) {
            NSURLComponents *comp = [[NSURLComponents alloc] initWithString:[url absoluteString]];

            NSMutableDictionary *opt = [@{} mutableCopy];
            for(NSURLQueryItem *item in comp.queryItems) {
                opt[item.name] = item.value;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:REQUEST_START_NAVIGATION object:self userInfo:opt];
            return YES;
        }
    }
    return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"background_mode"]) {
        [self requestBackgroundLocation:nil];
    } else if ([keyPath isEqualToString:@"isMoveLogStart"]) {
        if (![change[@"new"] boolValue]) {
            locationFilePath = nil;
        } else {
            [self setFilePath];
        }
    } else {
        [[HLPLocationManager sharedManager] invalidate];
    }
}

- (void)setFilePath
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
    [df setDateFormat:@"yyyyMMdd-HHmmss"];
    NSDate *now = [NSDate date];
    NSString *strNow = [df stringFromDate:now];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    locationFilePath = [directory stringByAppendingPathComponent: [NSString stringWithFormat: @"move-%@.csv", strNow]];
    
    BOOL isNew = false;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath: locationFilePath];
    if (!result) {
        result = [self createFile: locationFilePath];
        if (!result) {
            return;
        }
        isNew = true;
    }
    locationFileHandle = [NSFileHandle fileHandleForWritingAtPath: locationFilePath];
    
    if (isNew) {
        [self writeLocation: @"date,lng,lat,accuracy,floor,speed,orientation,orientationAccuracy\n"];
    }
}

- (BOOL)writeLocation:(NSString *)writeLine
{
    if (!locationFilePath) {
      return NO;
    }
    NSData *data = [writeLine dataUsingEncoding: NSUTF8StringEncoding];
    [locationFileHandle writeData:data];
    return YES;
}

- (BOOL)createFile:(NSString *)filePath
{
  return [[NSFileManager defaultManager] createFileAtPath:filePath contents:[NSData data] attributes:nil];
}

@end
