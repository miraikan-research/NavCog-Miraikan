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
    UIEdgeInsets insetsVoiceGuide;
    UIImage *imgVoiceGuide;
    NSString *imgName;
    UILabel *lblDesc;
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
    [[SettingDataManager sharedManager] setPresetId: _presetId];

    self.isVoiceGuideOn = [NSUserDefaults.standardUserDefaults boolForKey:@"isVoiceGuideOn"];
    
    lblDesc = [[UILabel alloc] init];
    lblDesc.textColor = UIColor.whiteColor;
    [lblDesc adjustsFontSizeToFitWidth];
    lblDesc.textAlignment = NSTextAlignmentCenter;
    lblDesc.numberOfLines = 2;
    lblDesc.isAccessibilityElement = NO;
    [self.view addSubview:lblDesc];
    
    btnVoiceGuide = [[BaseButton alloc] init];
    btnVoiceGuide.layer.backgroundColor = UIColor.whiteColor.CGColor;
    btnVoiceGuide.layer.cornerRadius = 10;
    insetsVoiceGuide = UIEdgeInsetsMake(10, 10, 10, 10);
    btnVoiceGuide.imageEdgeInsets = insetsVoiceGuide;
    [self updateButton:self.isVoiceGuideOn];
    [btnVoiceGuide tapAction:^(UIButton* _) {
        self.isVoiceGuideOn = !self.isVoiceGuideOn;
        [NSUserDefaults.standardUserDefaults setBool:self.isVoiceGuideOn forKey:@"isVoiceGuideOn"];
        [self updateButton:self.isVoiceGuideOn];
    }];
    
    [self.view addSubview:btnVoiceGuide];
}

- (void)viewDidLayoutSubviews {
    CGSize sz = self.view.frame.size;
    CGSize szDesc = lblDesc.frame.size;
    CGRect frameDesc = CGRectMake(sz.width - szDesc.width - 16,
                                  sz.height - 45,
                                  szDesc.width, szDesc.height);
    [lblDesc setFrame:frameDesc];
    CGSize szVoiceGuide = CGSizeMake(imgVoiceGuide.size.width + insetsVoiceGuide.left + insetsVoiceGuide.right,
                                     imgVoiceGuide.size.height + insetsVoiceGuide.top + insetsVoiceGuide.bottom);
    [btnVoiceGuide setFrame:CGRectMake(0, 0, szVoiceGuide.width, szVoiceGuide.height)];
    [btnVoiceGuide setCenter:CGPointMake(lblDesc.center.x, lblDesc.frame.origin.y - 5 - szVoiceGuide.height / 2)];
}

- (void)updateButton:(BOOL)isOn {
    lblDesc.text = isOn
        ? NSLocalizedString(@"Voice Guide On", @"")
        : NSLocalizedString(@"Voice Guide Off", @"");
    [lblDesc sizeToFit];
    [btnVoiceGuide setAccessibilityLabel:lblDesc.text];
    imgName = isOn ? @"icons8-sound-24" : @"icons8-mute-24";
    imgVoiceGuide = [UIImage imageNamed:imgName];
    [btnVoiceGuide setImage:imgVoiceGuide forState:UIControlStateNormal];
}

- (void)showVoiceGuide {
    lblDesc.hidden = false;
    btnVoiceGuide.hidden = false;
    [self.view bringSubviewToFront:lblDesc];
    [self.view bringSubviewToFront:btnVoiceGuide];
}

- (void)hiddenVoiceGuide {
    lblDesc.hidden = true;
    btnVoiceGuide.hidden = true;
}

@end
