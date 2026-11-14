//
//  EZTitlebar.h
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EZOpenLinkButton.h"

NS_ASSUME_NONNULL_BEGIN

/// Query window title bar. AI-Dict only shows the pin button here.
@interface EZTitlebar : NSView

@property (nonatomic, assign) BOOL pin;

@property (nonatomic, strong) EZOpenLinkButton *pinButton;

- (void)updatePinButton;

@end

NS_ASSUME_NONNULL_END
