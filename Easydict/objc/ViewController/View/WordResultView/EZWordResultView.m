//
//  EZWordResultView.m
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZWordResultView.h"
#import "NSColor+MyColors.h"
#import "EZLabel.h"
#import "NSTextView+Height.h"
#import "EZConst.h"
#import "EZWindowManager.h"
#import "EZBlueTextButton.h"
#import "EZCopyButton.h"
#import "NSObject+EZDarkMode.h"

static const CGFloat kHorizontalMargin_8 = 8;
static const CGFloat kToolBarButtonSize_24 = 24;
static const CGFloat kToolBarLeftMargin_6 = 6;
static const CGFloat kToolBarButtonPadding_1 = 1;
static const CGFloat kToolBarBottomMargin_4 = 4;

@interface EZWordResultView () <NSTextViewDelegate>

@property (nonatomic, strong) EZQueryResult *result;
@property (nonatomic, assign) CGFloat bottomViewHeight;
@property (nonatomic, assign) CGFloat fontSizeRatio;

@end


@implementation EZWordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = EZCornerRadius_8;
        self.fontSizeRatio = MyConfiguration.shared.fontSizeRatio;
        [self.layer executeLight:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_resultViewBgLightColor].CGColor;
        } dark:^(CALayer *layer) {
            layer.backgroundColor = [NSColor ez_resultViewBgDarkColor].CGColor;
        }];
    }
    return self;
}

/// Only result text opts into paragraph-direction handling; window chrome is unchanged.
- (EZTranslationResultLabel *)makeResultTextLabel {
    EZTranslationResultLabel *label = [[EZTranslationResultLabel alloc] init];
    label.markdownEnabled = NO;
    return label;
}

- (void)refreshWithResult:(EZQueryResult *)result {
    self.result = result;
    self.fontSizeRatio = MyConfiguration.shared.fontSizeRatio;

    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    __block CGFloat height = 0;
    __block NSView *lastView = nil;
    NSString *errorMessage = result.errorMessage;

    if (result.translatedResults.count || errorMessage.length > 0) {
        CGFloat topOffset = lastView ? 14 : 9;

        NSString *text = nil;
        if (errorMessage.length) {
            text = errorMessage;
        } else if (result.translatedText) {
            text = result.translatedText;
        } else {
            text = NSLocalizedString(@"no_results_found", nil);
        }

        EZTranslationResultLabel *resultLabel = [self makeResultTextLabel];
        resultLabel.markdownEnabled = errorMessage.length == 0 && result.isMarkdownRenderingEnabled;
        resultLabel.font = [NSFont systemFontOfSize:14 * self.fontSizeRatio];
        resultLabel.paragraphSpacing = 0;
        [self addSubview:resultLabel];
        resultLabel.text = text;
        resultLabel.delegate = self;

        [resultLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            if (lastView) {
                make.top.equalTo(lastView.mas_bottom).offset(topOffset);
            } else {
                make.top.equalTo(self).offset(topOffset);
            }
            make.left.equalTo(self).offset(kHorizontalMargin_8);
            make.right.equalTo(self).offset(-kHorizontalMargin_8);

            CGSize labelSize = [self labelSize:resultLabel exceptedWidth:kHorizontalMargin_8 * 2];
            make.size.mas_equalTo(labelSize).priorityHigh();
            height += (topOffset + labelSize.height);
        }];
        resultLabel.mas_key = @"resultLabel_normalResults";
        lastView = resultLabel;

        if (result.promptURL.length) {
            EZBlueTextButton *promptButton = [[EZBlueTextButton alloc] init];
            [self addSubview:promptButton];
            NSString *title = result.promptTitle.length ? result.promptTitle : result.promptURL;
            [promptButton setTitle:title];
            promptButton.openURL = result.promptURL;

            [promptButton mas_makeConstraints:^(MASConstraintMaker *make) {
                CGFloat promptTopOffset = 12;
                make.top.equalTo(lastView.mas_bottom).offset(promptTopOffset);
                make.left.mas_equalTo(kHorizontalMargin_8);
                height += promptTopOffset;
            }];
            height += promptButton.height;
            promptButton.mas_key = @"promptButton";
            lastView = promptButton;
        }
    }

    [self setupBottomToolBarButtons:result lastView:lastView height:height];
}

/// Copy button and Markdown toggle under the result text.
- (void)setupBottomToolBarButtons:(EZQueryResult *)result lastView:(NSView *)lastView height:(CGFloat)height {
    BOOL hasTranslatedText = result.translatedText.length > 0;

    EZCopyButton *textCopyButton = [[EZCopyButton alloc] init];
    [self addSubview:textCopyButton];
    textCopyButton.enabled = hasTranslatedText;
    [textCopyButton setClickBlock:^(EZButton *_Nonnull button) {
        [result.copiedText ns_copyAndShowToast:YES];
    }];
    textCopyButton.mas_key = @"result_copyButton";

    CGFloat topOffset = 6;
    [textCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.top.equalTo(lastView.mas_bottom).offset(topOffset);
        } else {
            make.top.equalTo(self).offset(topOffset);
        }
        make.left.offset(kToolBarLeftMargin_6);
        make.width.height.mas_equalTo(kToolBarButtonSize_24);
    }];

    self.bottomViewHeight = topOffset + kToolBarButtonSize_24 + kToolBarBottomMargin_4;
    height += self.bottomViewHeight;
    _viewHeight = height;

    EDMarkdownToggleButton *markdownToggleButton = [[EDMarkdownToggleButton alloc] init];
    [self addSubview:markdownToggleButton];
    markdownToggleButton.markdownEnabled = result.isMarkdownRenderingEnabled;
    markdownToggleButton.enabled = hasTranslatedText;
    markdownToggleButton.mas_key = @"result_markdownToggleButton";

    mm_weakify(self);
    markdownToggleButton.clickAction = ^{
        mm_strongify(self);
        [result toggleMarkdownRendering];

        // Cross-fade the content swap so toggling Markdown does not flash.
        self.wantsLayer = YES;
        CATransition *fade = [CATransition animation];
        fade.type = kCATransitionFade;
        fade.duration = 0.2;
        fade.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [self.layer addAnimation:fade forKey:@"EDMarkdownToggleFade"];

        EZBaseQueryViewController *queryViewController =
            EZWindowManager.shared.floatingWindow.queryViewController;
        [queryViewController updateCellWithResult:result reloadData:YES];
    };

    [markdownToggleButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(textCopyButton.mas_right).offset(kToolBarButtonPadding_1);
        make.width.height.bottom.equalTo(textCopyButton);
    }];
}

- (CGSize)labelSize:(EZLabel *)label exceptedWidth:(CGFloat)exceptedWidth {
    CGFloat width = self.width - exceptedWidth;
    CGFloat height = [label ez_getTextViewHeightDesignatedWidth:width];
    return CGSizeMake(width, height);
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    // Escape closes the floating window.
    if (commandSelector == @selector(cancelOperation:)) {
        [[EZWindowManager shared] closeFloatingWindow];
        return NO;
    }
    return NO;
}

@end
