//
//  SWUITextField.m
//  SWUIKit
//
//  Created by Xuhui on 15/12/1.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "YXUITextField.h"

@interface SWUITextField () {
}

@end

@implementation YXUITextField

- (void)setPlaceholder:(NSString *)placeholder
{
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder];
    [self updateAttributedPlaceHolder];
}

- (UIColor *)placeHolderColor
{
    if(!_placeHolderColor) {
        _placeHolderColor = [UIColor colorWithWhite:0.7 alpha:1];
    }
    return _placeHolderColor;
}

- (void)setPlaceHolderColor:(UIColor *)placeHolderColor
{
    _placeHolderColor = placeHolderColor;
    [self updateAttributedPlaceHolder];
}


- (void)setPlaceHolderInsetLeft:(CGFloat)placeHolderInsetLeft
{
    _placeHolderInsetLeft = placeHolderInsetLeft;
    [self updateAttributedPlaceHolder];
}

- (void)updateAttributedPlaceHolder
{
    NSMutableAttributedString *attibutedText = [self.attributedPlaceholder mutableCopy];
    NSRange textRange = NSMakeRange(0, attibutedText.length);
    [attibutedText addAttribute:NSFontAttributeName value:self.font range:textRange];
    [attibutedText addAttribute:NSForegroundColorAttributeName value:self.placeHolderColor range:textRange];
    NSMutableParagraphStyle *pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    pStyle.firstLineHeadIndent = self.placeHolderInsetLeft;
    [attibutedText addAttribute:NSParagraphStyleAttributeName value:pStyle range:textRange];
    self.attributedPlaceholder = attibutedText;
}

@end
