//
//  MiraikanMapController.m
//  NavCog3
//
//  Created by SHIN hiroshi/沈　洋 on 2021/10/20.
//  Copyright © 2021 HULOP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MiraikanMapController.h"
#import <NavCogMiraikan-Swift.h>
#import "SettingDataManager.h"

@interface MiraikanMapController() {
    BaseButton *btnVoiceGuide;
}

@end

/**
 @remark
 Icon by: https://icons8.com,
 Sound: https://icons8.com/icon/41562/sound,
 Mute: https://icons8.com/icon/644/mute
 */
@implementation MiraikanMapController : UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"%s: %d, destId: %@, presetId: %@", __func__, __LINE__, _destId, @(_presetId));
    [[SettingDataManager sharedManager] setPresetId: _presetId];

    self.isVoiceGuideOn = [NSUserDefaults.standardUserDefaults boolForKey:@"isVoiceGuideOn"];

    // Cause of the crash
    btnVoiceGuide = [[BaseButton alloc] init];
    [btnVoiceGuide tapAction:^(UIButton* _) {
        [NSUserDefaults.standardUserDefaults setBool:self.isVoiceGuideOn forKey:@"isVoiceGuideOn"];
    }];
}

@end
