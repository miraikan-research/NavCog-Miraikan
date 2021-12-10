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
    
    self.isVoiceGuideOn = [NSUserDefaults.standardUserDefaults boolForKey:@"isVoiceGuideOn"];
    
    lblDesc = [[UILabel alloc] init];
    lblDesc.textColor = UIColor.whiteColor;
    [lblDesc adjustsFontSizeToFitWidth];
    lblDesc.textAlignment = NSTextAlignmentCenter;
    lblDesc.numberOfLines = 2;
    lblDesc.text = self.isVoiceGuideOn
        ? NSLocalizedString(@"Voice Guide On", @"")
        : NSLocalizedString(@"Voice Guide Off", @"");
    [lblDesc sizeToFit];
    lblDesc.isAccessibilityElement = NO;
    [self.view addSubview:lblDesc];
    
    btnVoiceGuide = [[BaseButton alloc] init];
    [btnVoiceGuide setAccessibilityLabel:lblDesc.text];
    imgName = self.isVoiceGuideOn ? @"icons8-sound-24" : @"icons8-mute-24";
    imgVoiceGuide = [UIImage imageNamed:imgName];
    [btnVoiceGuide setImage:imgVoiceGuide forState:UIControlStateNormal];
    btnVoiceGuide.layer.backgroundColor = UIColor.whiteColor.CGColor;
    btnVoiceGuide.layer.cornerRadius = 10;
    insetsVoiceGuide = UIEdgeInsetsMake(10, 10, 10, 10);
    btnVoiceGuide.imageEdgeInsets = insetsVoiceGuide;
    [btnVoiceGuide tapAction:^(UIButton* _) {
        self.isVoiceGuideOn = !self.isVoiceGuideOn;
        [NSUserDefaults.standardUserDefaults setBool:self.isVoiceGuideOn forKey:@"self.isVoiceGuideOn"];
        imgName = self.isVoiceGuideOn ? @"icons8-sound-24" : @"icons8-mute-24";
        imgVoiceGuide = [UIImage imageNamed:imgName];
        [btnVoiceGuide setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
        lblDesc.text = self.isVoiceGuideOn
            ? NSLocalizedString(@"Voice Guide On", @"")
            : NSLocalizedString(@"Voice Guide Off", @"");
        [btnVoiceGuide setAccessibilityLabel:lblDesc.text];
        [lblDesc sizeToFit];
    }];
    
    [self.view addSubview:btnVoiceGuide];
}

- (void)viewDidLayoutSubviews {
    CGSize sz = self.view.frame.size;
    CGSize szDesc = lblDesc.frame.size;
    CGRect frameDesc = CGRectMake(sz.width - szDesc.width - 16,
                                  sz.height - 125,
                                  szDesc.width, szDesc.height);
    [lblDesc setFrame:frameDesc];
    CGSize szVoiceGuide = CGSizeMake(imgVoiceGuide.size.width + insetsVoiceGuide.left + insetsVoiceGuide.right,
                                     imgVoiceGuide.size.height + insetsVoiceGuide.top + insetsVoiceGuide.bottom);
    [btnVoiceGuide setFrame:CGRectMake(0, 0, szVoiceGuide.width, szVoiceGuide.height)];
    [btnVoiceGuide setCenter:CGPointMake(lblDesc.center.x, lblDesc.frame.origin.y - 5 - szVoiceGuide.height / 2)];
}

- (void)showVoiceGuide {
    [self.view bringSubviewToFront:lblDesc];
    [self.view bringSubviewToFront:btnVoiceGuide];
}

@end
