//
//  EZTitlebar.m
//  Easydict
//
//  Created by tisfeng on 2022/11/19.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZTitlebar.h"
#import "EZTitleBarMoveView.h"
#import "NSObject+EZWindowType.h"
#import "NSImage+EZResize.h"
#import "NSImage+EZSymbolmage.h"
#import "NSObject+EZDarkMode.h"
#import "EZBaseQueryWindow.h"


@interface EZTitlebar ()

@property (nonatomic, assign) CGFloat buttonWidth;

@end

@implementation EZTitlebar

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.buttonWidth = 24;
    [self addSubview:self.pinButton];
}

- (void)updateConstraints {
    CGFloat margin = EZHorizontalCellSpacing_10;
    CGFloat topOffset = EZTitlebarHeight_28 - self.buttonWidth;

    [self.pinButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(self.buttonWidth);
        make.left.inset(margin);
        make.top.equalTo(self).offset(topOffset);
    }];

    [super updateConstraints];
}

#pragma mark - Getter && Setter

- (EZOpenLinkButton *)pinButton {
    if (!_pinButton) {
        EZOpenLinkButton *pinButton = [[EZOpenLinkButton alloc] init];
        _pinButton = pinButton;
        
        pinButton.contentTintColor = [NSColor clearColor];
        pinButton.clickBlock = nil;
        self.pin = NO;
        
        mm_weakify(self);
        [pinButton setMouseDownBlock:^(EZButton *_Nonnull button) {
//            MMLogInfo(@"pin mouse down, state: %ld", button.buttonState);
            mm_strongify(self);
            self.pin = !self.pin;
        }];
        
        [pinButton setMouseUpBlock:^(EZButton *_Nonnull button) {
//            MMLogInfo(@"pin mouse up, state: %ld", button.buttonState);
            mm_strongify(self);
            BOOL oldPin = !self.pin;
            
            // This means clicked pin button.
            if (button.state == EZButtonHoverState) {
                self.pin = !oldPin;
            } else if (button.buttonState == EZButtonNormalState) {
                self.pin = oldPin;
            }
        }];

        [self executeOnAppearanceChange:^(EZTitlebar *titlebar, BOOL isDarkMode) {
            [titlebar updatePinButtonImage];
        }];
    }
    return _pinButton;
}

- (BOOL)pin {
    EZBaseQueryWindow *window = (EZBaseQueryWindow *)self.window;
    return window.pin;
}

- (void)setPin:(BOOL)pin {
    [(EZBaseQueryWindow *)self.window updateWindowLevel:pin];

    [self updatePinButton];
}

- (NSString *)pinToolTip {
    NSString *shortcutStr = MyConfiguration.shared.pinShortcutString;
    NSString *hint = self.pin ? NSLocalizedString(@"unpin", nil) : NSLocalizedString(@"pin", nil);
    return shortcutStr.length ? [NSString stringWithFormat:@"%@, %@", hint, shortcutStr] : hint;
}

- (void)updatePinButton {
    self.pinButton.toolTip = [self pinToolTip];
    [self updatePinButtonImage];
}

- (void)updatePinButtonImage {
    CGFloat imageWidth = 18;
    CGSize imageSize = CGSizeMake(imageWidth, imageWidth);

    // Since the system's dark picture mode cannot dynamically follow the mode switch changes, we manually implement dark mode picture coloring.
    NSColor *pinNormalLightTintColor = [NSColor mm_colorWithHexString:@"#797A7F"];
    NSColor *pinNormalDarkTintColor = [NSColor mm_colorWithHexString:@"#C0C1C4"];

    NSImage *normalImage = [[NSImage imageNamed:@"new_pin_normal"] resizeToSize:imageSize];
    NSImage *selectedImage = [[NSImage imageNamed:@"new_pin_selected"] resizeToSize:imageSize];

    BOOL isDarkMode = self.pinButton.isDarkMode;
    NSColor *pinTintColor = isDarkMode ? pinNormalDarkTintColor : pinNormalLightTintColor;
    NSImage *normalTintedImage = [normalImage imageWithTintColor:pinTintColor];
    self.pinButton.image = self.pin ? selectedImage : normalTintedImage;
}

@end
