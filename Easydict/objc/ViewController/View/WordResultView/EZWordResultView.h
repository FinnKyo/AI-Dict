//
//  EZWordResultView.h
//  Easydict
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EZQueryResult;
@class EZQueryService;

NS_ASSUME_NONNULL_BEGIN

/// Renders one service result: the headword, the (Markdown) result text and a small tool bar.
@interface EZWordResultView : NSView

@property (nonatomic, assign, readonly) CGFloat viewHeight;
@property (nonatomic, strong, readonly) EZQueryResult *result;
@property (nonatomic, strong) EZQueryService *service;

@property (nonatomic, copy) void (^updateViewHeightBlock)(CGFloat viewHeight);

- (void)refreshWithResult:(EZQueryResult *)result;

@end

NS_ASSUME_NONNULL_END
