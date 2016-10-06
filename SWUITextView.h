//
//  SWUITextView.h
//  SWUIKit
//
//  Created by Xuhui on 15/11/30.
//

#import <UIKit/UIKit.h>

@class SWUITextView;

@protocol SWUITextViewDelegate <UITextViewDelegate>

@optional
- (void)textView:(SWUITextView *)textView willChangeHeight:(CGFloat)height;
- (void)textViewHeightDidChange:(YXUITextView *)textView;
- (BOOL)textViewShouldReturn:(SWUITextView *)textView;
- (void)textViewDidPaste:(SWUITextView *)textView;

@end

@interface SWUITextView : UITextView

@property (nonatomic, weak) id<SWUITextViewDelegate> delegate;
@property (nonatomic, assign) NSInteger minNumberOfVisiableLines;
@property (nonatomic, assign) NSInteger maxNumberOfVisiableLines;
@property (nonatomic, assign) CGFloat lineSpaceHeight;
@property (nonatomic, copy) NSString *placeHolder;
@property (nonatomic, strong) UIColor *placeHolderColor;
@property (nonatomic, assign) CGFloat placeHolderInsetLeft;
@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign) CGFloat maxHeight;

- (CGFloat)contentHeightOfLines:(NSInteger)lines;

- (CGSize)sizeThatFits:(CGSize)size;

@end
