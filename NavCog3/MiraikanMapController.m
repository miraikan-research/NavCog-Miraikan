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
    UIView *btnVoiceBase;
    BaseButton *btnVoice;
    UIEdgeInsets insetsVoice;
    BaseButton *btnVoiceGuide;
    UIEdgeInsets insetsVoiceGuide;
    UIImage *imgVoiceGuide;
    UILabel *lblDesc;
}

@end

/**
 @remark
 Icon by: https://icons8.com,
 Sound: https://icons8.com/icon/41562/sound,
 Mute: https://icons8.com/icon/644/mute,
 Mic: https://icons8.com/icon/gHHbmX5R7BJo/mic
 */
@implementation MiraikanMapController : UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[SettingDataManager sharedManager] setPresetId: _presetId];

    self.isVoiceGuideOn = [NSUserDefaults.standardUserDefaults boolForKey:@"isVoiceGuideOn"];

    [self setupVoiceGuideButton];
    [self setupVoiceButton];
}

- (void)setupVoiceGuideButton {
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

- (void)setupVoiceButton {

    UIColor * mainColor = [UIColor colorWithRed: 22.0/255.0 green:94.0/255.0 blue:131.0/255.0 alpha:1.0];

    btnVoiceBase = [[UIView alloc] init];
    btnVoiceBase.layer.cornerRadius = 40;
    btnVoiceBase.backgroundColor = mainColor;

    UIImage *img = [UIImage imageNamed:@"icons8-mic-64.png"];

    btnVoice = [[BaseButton alloc] init];
    btnVoice.backgroundColor = UIColor.whiteColor;
    btnVoice.layer.cornerRadius = 32;
    insetsVoice = UIEdgeInsetsMake(10, 10, 10, 10);
    btnVoice.imageEdgeInsets = insetsVoice;
    [btnVoice setImage:img forState:UIControlStateNormal];
    btnVoice.tintColor = mainColor;

    [btnVoice tapAction:^(UIButton* _) {
        self.delegate.dialogViewTapped;
    }];
    
    [self.view addSubview:btnVoiceBase];
    [btnVoiceBase addSubview:btnVoice];
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

    [btnVoiceBase setFrame:CGRectMake(10, sz.height - 90, 80, 80)];
    [btnVoice setFrame:CGRectMake(8, 8, 64, 64)];
}

- (void)updateButton:(BOOL)isOn {
    lblDesc.text = isOn
        ? NSLocalizedString(@"Voice Guide On", @"")
        : NSLocalizedString(@"Voice Guide Off", @"");
    [lblDesc sizeToFit];
    [btnVoiceGuide setAccessibilityLabel:lblDesc.text];
    NSString *imgName = isOn ? @"icons8-sound-24" : @"icons8-mute-24";
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

- (void)showVoice {
    [self.view bringSubviewToFront:btnVoiceBase];
    btnVoiceBase.hidden = false;
}

- (void)hiddenVoice {
    btnVoiceBase.hidden = true;
}

@end
