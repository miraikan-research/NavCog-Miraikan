//
//  MiraikanMapDelegate.h
//  NavCog3
//
//  Created by SHIN hiroshi/沈 洋 on 2021/10/20.
//  Copyright © 2021 HULOP. All rights reserved.
//

#ifndef MiraikanMapDelegate_h
#define MiraikanMapDelegate_h

#import <UIKit/UIKit.h>

@interface MiraikanMapController : UIViewController

@property (strong, nonatomic) NSString *destId;
@property (nonatomic) int presetId;
@property (nonatomic) BOOL isNaviStarted;
@property (nonatomic) BOOL isDestLoaded;
@property (nonatomic) BOOL isRouteRequested;
@property (nonatomic) BOOL isVoiceGuideOn;

- (void)showVoiceGuide;
- (void)hiddenVoiceGuide;

@end

#endif /* MiraikanMapDelegate_h */
