//
//  SWAttributedLabel.h
//  SWUIKit
//
//  Created by Xuhui on 16/9/8.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SWAttributedLabelVerticalAlignment) {
    SWAttributedLabelVerticalAlignmentTop      = 0,
    SWAttributedLabelVerticalAlignmentCenter   = 1,
    SWAttributedLabelVerticalAlignmentBottom   = 2,
};

@interface SWLinkAttribute : NSObject

@property (nonatomic, assign) NSRange range;
@property (nonatomic, strong) UIColor *linkColor;
@property (nonatomic, strong) UIColor *hilightedLinkColor;
@property (nonatomic, assign) BOOL showUnderline;
@property (nonatomic, assign) BOOL hilighted;
@property (nonatomic, strong) id data;
@property (nonatomic, assign) NSTextCheckingType linkType;

@end

@class SWAttributedLabel;

@protocol SWAttributedLabelDelegate <NSObject>

@optional
- (void)attributedLabel:(SWAttributedLabel *)label didSelectLinkWithLinkType:(NSTextCheckingType)linkType data:(id)data;
- (void)attributedLabeldidSelectNormalText:(SWAttributedLabel *)label ;
@end

@interface SWAttributedLabel : UILabel

@property (nonatomic, assign) CGFloat   leading; // 设置行间距
@property (nonatomic, strong) UIColor   *linkColor;
@property (nonatomic, strong) UIColor   *hilightedLinkColor;
@property (nonatomic, assign) BOOL  showLinkUnderline;
@property (nonatomic, assign) BOOL  autoDetectLink;
@property (nonatomic, assign) BOOL  autoDetectNumber;
@property (nonatomic, strong) SWLinkAttribute   *activeLink;
@property (nonatomic, weak) id<SWAttributedLabelDelegate>   delegate;

- (void)appendText:(NSString *)text;

- (void)appendAttributedText:(NSAttributedString *)attributedText;

- (void)appendImage:(UIImage *)image size:(CGSize)size;
- (void)InsertImage:(UIImage *)image size:(CGSize)size  atIndex:(NSUInteger)loc;

- (void)appendImage:(UIImage *)image size:(CGSize)size verticalAlignment:(SWAttributedLabelVerticalAlignment)alignment;

- (void)appendView:(UIView *)view size:(CGSize)size verticalAlignment:(SWAttributedLabelVerticalAlignment)alignment;

- (void)addLink:(id)data withRange:(NSRange)range;

- (void)addLinkAttribute:(SWLinkAttribute *)attribute;

- (void)beginEditing;

- (void)endEditing;

@end
