//
//  SWUITextView.m
//  SWUIKit
//
//  Created by Xuhui on 15/11/30.
//

#import "SWUITextView.h"

@interface SWUITextView () {
    UIColor *_placeHolderColor;
}

@property (nonatomic, assign) BOOL showPlaceHolder;
@property (nonatomic, strong) UILabel *placeHolderLabel;

@end

@implementation SWUITextView

@dynamic delegate;

@synthesize placeHolderColor = _placeHolderColor;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.font = [UIFont systemFontOfSize:12];
        self.textColor = [UIColor blackColor];
        [self setupUICompenet];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setupUICompenet];
}

- (void)setupUICompenet
{
    self.layoutManager.allowsNonContiguousLayout = NO;
    self.minHeight= 0;
    self.maxHeight = CGFLOAT_MAX;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.minNumberOfVisiableLines = 1;
    self.maxNumberOfVisiableLines = 1;
    self.placeHolder = @"";
    self.showPlaceHolder = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEndEditing:) name:UITextViewTextDidEndEditingNotification object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextDidChange:) name:UITextViewTextDidChangeNotification object:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UILabel *)placeHolderLabel
{
    if(!_placeHolderLabel) {
        _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeHolderLabel.textColor = self.placeHolderColor;
        _placeHolderLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_placeHolderLabel];
    }
    return _placeHolderLabel;
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    _placeHolderLabel.font = font;
    if(self.attributedText.length) {
        self.attributedText = [[NSAttributedString alloc] initWithString:self.attributedText.string attributes:[self textAttributes]];
    }
    [_placeHolderLabel setNeedsDisplay];
    [self setNeedsLayout];
}

- (CGFloat)lineSpaceHeight
{
    return MAX(0, _lineSpaceHeight + (self.font ? self.font.descender : 0));
}

- (NSParagraphStyle *)textParagraphStyle
{
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    pStyle.lineSpacing = self.lineSpaceHeight;
    pStyle.alignment = self.textAlignment;
    return pStyle;
}

- (NSDictionary *)textAttributes
{
    return @{NSFontAttributeName: self.font,
             NSForegroundColorAttributeName: self.textColor,
             NSParagraphStyleAttributeName: [self textParagraphStyle]};
}

- (void)setText:(NSString *)text
{
    if(text.length) {
        self.showPlaceHolder = NO;
        self.attributedText = [[NSAttributedString alloc] initWithString:text attributes:[self textAttributes]];
    } else {
        self.attributedText = nil;
        self.showPlaceHolder = YES;
    }
    
}

- (void)setPlaceHolder:(NSString *)placeHolder
{
    _placeHolder = [placeHolder copy];
    self.placeHolderLabel.text = _placeHolder;
    
}

- (UIColor *)placeHolderColor
{
    if(!_placeHolderColor) {
        _placeHolderColor = [[UIColor alloc] initWithWhite:0.5 alpha:0.7];
    }
    return _placeHolderColor;
}

- (void)setPlaceHolderColor:(UIColor *)placeHolderColor
{
    _placeHolderColor = placeHolderColor;
    self.placeHolderLabel.textColor = _placeHolderColor;
    [self.placeHolderLabel setNeedsDisplay];
}

- (void)setPlaceHolderInsetLeft:(CGFloat)placeHolderInsetLeft
{
    _placeHolderInsetLeft = placeHolderInsetLeft;
    [self setNeedsLayout];
}

- (void)setContentSize:(CGSize)contentSize
{
    [super setContentSize:contentSize];
    BOOL needUpdateHeight = NO;
    CGFloat height = contentSize.height;
    if(self.maxNumberOfVisiableLines > 0) {
        CGFloat minHeight = MAX(self.minHeight, [self contentHeightOfLines:self.minNumberOfVisiableLines]);
        CGFloat maxHeight = MIN(self.maxHeight, [self contentHeightOfLines:self.maxNumberOfVisiableLines]);
        if(contentSize.height < minHeight) {
            height = minHeight;
        } else if (contentSize.height >= minHeight && contentSize.height <= maxHeight) {
            height = contentSize.height;
        } else {
            height = maxHeight;
        }
        if(self.bounds.size.height > maxHeight || self.bounds.size.height < minHeight) {
            needUpdateHeight = YES;
        } else if(!((height >= maxHeight && self.bounds.size.height >= maxHeight) || (height <= minHeight && self.bounds.size.height <= minHeight) || height == self.bounds.size.height)) {
            needUpdateHeight = YES;
        }
    } else {
        if(height != self.bounds.size.height) {
            needUpdateHeight = YES;
        }
    }
    if(needUpdateHeight) {
        if([self.delegate respondsToSelector:@selector(textView:willChangeHeight:)]) {
            [self.delegate textView:self willChangeHeight:height];
        }
        CGSize size = self.bounds.size;
        size.height = height;
        self.bounds = (CGRect){ .origin=self.bounds.origin, .size = size };
        if([self.delegate respondsToSelector:@selector(textViewHeightDidChange:)]) {
            [self.delegate textViewHeightDidChange:self];
        }
    }
}

- (CGFloat)contentHeightOfLines:(NSInteger)lines
{
    if(lines <= 0) return 0;
    NSMutableString *text = [NSMutableString stringWithString:@"-"];
    for (NSInteger i = 1; i < lines; i++) {
        [text appendString:@"\n|w|"];
    }
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: self.font, NSForegroundColorAttributeName: self.textColor, NSParagraphStyleAttributeName: [self textParagraphStyle]}];
    CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    return CGRectGetHeight(rect);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size = [super sizeThatFits:size];
    if(self.minNumberOfVisiableLines > 0) {
        CGFloat height = size.height;
        if(self.maxNumberOfVisiableLines > 0) {
            CGFloat minHeight = MAX(self.minHeight, [self contentHeightOfLines:self.minNumberOfVisiableLines]);
            CGFloat maxHeight = MIN(self.maxHeight, [self contentHeightOfLines:self.maxNumberOfVisiableLines]);
            if(height < minHeight) {
                height = minHeight;
            } else if (height >= minHeight && height <= maxHeight) {
                
            } else {
                height = maxHeight;
            }
        }
        size.height = height;
    }
    return size;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)paste:(nullable id)sender
{
    [super paste:sender];
    if([self.delegate respondsToSelector:@selector(textViewDidPaste:)]) {
        [self.delegate textViewDidPaste:self];
    }
}

- (void)setShowPlaceHolder:(BOOL)showPlaceHolder
{
    _showPlaceHolder = showPlaceHolder;
    self.placeHolderLabel.hidden = !_showPlaceHolder;
}

- (void)onBeginEditing:(NSNotification *)note
{
    
}

- (void)onEndEditing:(NSNotification *)note
{
    
}

- (void)onTextDidChange:(NSNotification *)note
{
    self.showPlaceHolder = (self.text.length <= 0);
//    if(!IOS9) {
//        [self scrollCursorToVisible];
//    }
}

- (void)scrollCursorToVisible
{
    [self scrollRangeToVisible:self.selectedRange];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    _placeHolderLabel.frame = (CGRect){.origin = (CGPoint){.x = self.placeHolderInsetLeft, .y = self.textContainerInset.top}, .size = (CGSize){.width = width - self.placeHolderInsetLeft, .height = self.font.pointSize}};
}

@end
