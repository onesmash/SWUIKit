//
//  SWAttributedLabel.m
//  SWUIKit
//
//  Created by Xuhui on 16/9/8.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "SWAttributedLabel.h"

#define IOS8            ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 8.0)
#define IOS9            ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 9.0)
#define IsLandscape   (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
#define UIScreenWidth    ((IOS8 || !IsLandscape) ?[UIScreen mainScreen].bounds.size.width:[UIScreen mainScreen].bounds.size.height)
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:1.0]

static NSString *const kSWLinkAttributeName = @"kSWLinkAttributeName";

@implementation SWLinkAttribute

- (instancetype)init
{
    self = [super init];
    if(self) {
        _range = NSMakeRange(0, 0);
        _hilighted = NO;
        _linkType = NSTextCheckingTypeLink;
    }
    return self;
}


@end

@protocol SWAttachmentProtocol <NSObject>

@required
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat baselineOffset;
@end

@interface SWImageAttachment : NSTextAttachment <SWAttachmentProtocol>

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat baselineOffset;

@end

@implementation SWImageAttachment

- (instancetype)initWithImage:(UIImage *)image size:(CGSize)size
{
    self = [super init];
    if(self) {
        self.image = image;
        self.size = size;
        self.baselineOffset = 0;
        self.bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    }
    return self;
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    CGFloat maxXOffsetInLine = position.x - lineFrag.origin.x + self.size.width;
    if(maxXOffsetInLine <= lineFrag.size.width && maxXOffsetInLine <= UIScreenWidth) {
        return CGRectMake(0, self.baselineOffset, self.size.width, self.size.height);
    } else {
        return CGRectMake(0, self.baselineOffset, self.size.width, 0);
    }
}

@end

@interface SWViewAttachment : NSTextAttachment <SWAttachmentProtocol>

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat baselineOffset;
@property (nonatomic, strong) UIView *view;

@end

@implementation SWViewAttachment
- (instancetype)initWithView:(UIView *)view size:(CGSize)size
{
    self = [super init];
    if(self) {
        self.view = view;
        self.size = size;
        self.baselineOffset = 0;
    }
    return self;
}

- (UIImage *)imageForBounds:(CGRect)imageBounds textContainer:(NSTextContainer *)textContainer characterIndex:(NSUInteger)charIndex
{
    self.view.frame = CGRectMake(imageBounds.origin.x, imageBounds.origin.y, CGRectGetWidth(imageBounds), CGRectGetHeight(imageBounds));
    return nil;
}

- (CGRect)attachmentBoundsForTextContainer:(nullable NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    CGFloat maxXOffsetInLine = position.x - lineFrag.origin.x + self.size.width;
    if(maxXOffsetInLine <= lineFrag.size.width && maxXOffsetInLine <= UIScreenWidth) {
        self.view.hidden = NO;
        return CGRectMake(0, self.baselineOffset, self.size.width, self.size.height);
    } else {
        self.view.hidden = YES;
        return CGRectMake(0, self.baselineOffset, self.size.width, 0);
    }
}

@end

@interface SWAttributedLabel () {
    BOOL    _needsUpdateTextStorage;
    BOOL    _needsDetectLink;
    BOOL    _hasLinks;
    BOOL    _hasAttachements;
    BOOL    _linkDetected;
    NSInteger _editCount;
    CGFloat _leading;
}

@property (nonatomic, strong) NSMutableAttributedString *renderedAttributedString;
@property (nonatomic, strong) NSTextStorage *textStorage;

@end

@implementation SWAttributedLabel

@synthesize leading = _leading;

- (instancetype)init
{
    self = [super init];
    if(self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        [self setupUI];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupUI];
}

- (void)setupUI
{
    _linkColor = UIColorFromRGB(0x15d1a5);
    _hilightedLinkColor = UIColorFromRGB(0x1c6352);
    _showLinkUnderline = YES;
    _hasLinks = NO;
    _hasAttachements = NO;
    _leading = 10;
    _linkDetected = NO;
    self.userInteractionEnabled = YES;
}

- (void)dealloc
{
    
}

- (void)setText:(NSString *)text
{
    [super setText:nil];
    NSAttributedString *attributeText = text.length ? [[NSAttributedString alloc]  initWithString:text] : [[NSMutableAttributedString alloc]  initWithString:@""];
    [self beginEditing];
    [self.renderedAttributedString setAttributedString:attributeText];
    if(self.renderedAttributedString.length) {
        NSRange textRange = NSMakeRange(0, self.renderedAttributedString.length);
        if(self.textColor) {
            [self.renderedAttributedString addAttribute:NSForegroundColorAttributeName value:self.textColor range:textRange];
        }
        if(self.font) {
            [self.renderedAttributedString addAttribute:NSFontAttributeName value:self.font range:textRange];
        }
    }
    [self setNeedsDetectLink];
    [self endEditing];
}

- (void)appendText:(NSString *)text
{
    if(text.length) {
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
        [attributedText beginEditing];
        NSRange textRange = NSMakeRange(0, text.length);
        if(self.textColor) {
            [attributedText addAttribute:NSForegroundColorAttributeName value:self.textColor range:textRange];
        }
        if(self.font) {
            [attributedText addAttribute:NSFontAttributeName value:self.font range:textRange];
        }
        [attributedText endEditing];
        [self beginEditing];
        [self.renderedAttributedString appendAttributedString:attributedText];
        [self setNeedsDetectLink];
        [self endEditing];
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [self beginEditing];
    [self.renderedAttributedString setAttributedString:attributedText.length ? attributedText : [[NSAttributedString alloc] initWithString:@""]];
    [self setNeedsDetectLink];
    [self endEditing];
}

- (void)appendAttributedText:(NSAttributedString *)attributedText
{
    if(attributedText.length) {
        [self beginEditing];
        [self.renderedAttributedString appendAttributedString:attributedText];
        [self setNeedsDetectLink];
        [self endEditing];
    }
}

- (void)setFont:(UIFont *)font
{
    if(font != self.font) {
        [self beginEditing];
        [super setFont:font];
        [self endEditing];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    [self beginEditing];
    [super setTextColor:textColor];
    [self endEditing];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    if(textAlignment != self.textAlignment) {
        [self beginEditing];
        [super setTextAlignment:textAlignment];
        [self endEditing];
    }
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if(lineBreakMode != self.lineBreakMode) {
        [self beginEditing];
        [super setLineBreakMode:lineBreakMode];
        [self endEditing];
    }
}

- (void)setLeading:(CGFloat)leading
{
    if(leading != _leading) {
        [self beginEditing];
        _leading = leading;
        [self endEditing];
    }
}

- (CGFloat)leading
{
    return MAX(0, _leading + (self.font ? self.font.descender : 0));
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if(numberOfLines != self.numberOfLines) {
        [self beginEditing];
        [super setNumberOfLines:numberOfLines];
        [self endEditing];
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsUpdateTextStorage];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self setNeedsUpdateTextStorage];
}

//- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
//{
//    CGRect rect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
//    if(self.numberOfLines > 1) {
//        //rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - self.leading);
//    }
//    return rect;
//}

//- (void)drawTextInRect:(CGRect)rect
//{
//    [self.textStorage.layoutManagers.firstObject drawBackgroundForGlyphRange:NSMakeRange(0, self.textStorage.length) atPoint:rect.origin];
//    [self.textStorage.layoutManagers.firstObject drawGlyphsForGlyphRange:NSMakeRange(0, self.textStorage.length) atPoint:rect.origin];
//}

- (void)beginEditing
{
    if(_editCount <= 0) {
        [self.renderedAttributedString beginEditing];
    }
    _editCount++;
}

- (void)endEditing
{
    if(_editCount <= 0) return;
    _editCount--;
    if(_editCount == 0) {
        NSRange textRange = NSMakeRange(0, self.renderedAttributedString.length);
        //        [self.renderedAttributedString addAttribute:NSFontAttributeName value:self.font range:textRange];
        [self.renderedAttributedString endEditing];
        NSMutableAttributedString *attributedText = [self.renderedAttributedString mutableCopy];
        [attributedText beginEditing];
        if(!IOS9 && attributedText.length) {
            id<SWAttachmentProtocol> attachment = [attributedText attribute:NSAttachmentAttributeName atIndex:attributedText.length - 1 effectiveRange:0];
            if(attachment) {
                [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            }
        }
        
        [attributedText addAttribute:NSParagraphStyleAttributeName value:[self paragraphStyle] range:textRange];
        [attributedText endEditing];
        [super setAttributedText:attributedText];
        [self detectLinkIfNeeded];
        [self setNeedsUpdateTextStorage];
    }
}

- (void)detectLinkIfNeeded
{
    
}

- (NSTextStorage *)textStorage
{
    if(_needsUpdateTextStorage) {
        NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
        NSLayoutManager *layoutManager= [[NSLayoutManager alloc] init];
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)];
        textContainer.lineFragmentPadding = 0;
        textContainer.maximumNumberOfLines = self.numberOfLines;
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        _textStorage = textStorage;
        _needsUpdateTextStorage = NO;
    }
    return _textStorage;
}

- (NSMutableParagraphStyle *)paragraphStyle
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = self.textAlignment;
    paragraphStyle.lineBreakMode = self.lineBreakMode;
    if(self.numberOfLines == 1) {
        paragraphStyle.lineSpacing = 0;
        //paragraphStyle.minimumLineHeight = self.font.lineHeight;
        //paragraphStyle.maximumLineHeight = self.font.lineHeight;
    } else {
        paragraphStyle.lineSpacing = self.leading;
    }
    return paragraphStyle;
}

- (NSMutableAttributedString *)renderedAttributedString
{
    if(!_renderedAttributedString) {
        _renderedAttributedString = [[NSMutableAttributedString alloc] init];
    }
    return _renderedAttributedString;
}

- (void)adjustBaseline:(id<SWAttachmentProtocol>)attachment verticalAlignment:(SWAttributedLabelVerticalAlignment)alignment
{
    CGFloat ascender = self.font.ascender;
    CGFloat descender = self.font.descender;
    switch (alignment) {
        case SWAttributedLabelVerticalAlignmentTop: {
            [attachment setBaselineOffset:ascender + descender - [attachment size].height];
        } break;
        case SWAttributedLabelVerticalAlignmentCenter: {
            [attachment setBaselineOffset:(ascender + descender - [attachment size].height) / 2];
        } break;
        case SWAttributedLabelVerticalAlignmentBottom: {
            [attachment setBaselineOffset:0];
        } break;
        default:
            break;
    }
}

- (void)InsertImage:(UIImage *)image size:(CGSize)size  atIndex:(NSUInteger)loc
{
    [self InsertImage:image size:size verticalAlignment:SWAttributedLabelVerticalAlignmentCenter atIndex:loc];
}

- (void)appendImage:(UIImage *)image size:(CGSize)size
{
    [self appendImage:image size:size verticalAlignment:SWAttributedLabelVerticalAlignmentBottom];
}

- (void)appendImage:(UIImage *)image size:(CGSize)size verticalAlignment:(SWAttributedLabelVerticalAlignment)alignment
{
    if (!image) return;
    SWImageAttachment *attachement = [[SWImageAttachment alloc] initWithImage:image size:size];
    [self adjustBaseline:attachement verticalAlignment:alignment];
    [self beginEditing];
    [self.renderedAttributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachement]];
    _hasAttachements = YES;
    [self endEditing];
}

- (void)InsertImage:(UIImage *)image size:(CGSize)size verticalAlignment:(SWAttributedLabelVerticalAlignment)alignment atIndex:(NSUInteger)loc
{
    if (!image) return;
    SWImageAttachment *attachement = [[SWImageAttachment alloc] initWithImage:image size:size];
    [self adjustBaseline:attachement verticalAlignment:alignment];
    [self beginEditing];
    [self.renderedAttributedString insertAttributedString:[NSAttributedString attributedStringWithAttachment:attachement] atIndex:loc];
    _hasAttachements = YES;
    [self endEditing];
}

- (void)appendView:(UIView *)view size:(CGSize)size verticalAlignment:(SWAttributedLabelVerticalAlignment)alignment
{
    if (!view) return;
    SWViewAttachment *attachement = [[SWViewAttachment alloc] initWithView:view size:size];
    [self adjustBaseline:attachement verticalAlignment:alignment];
    [self beginEditing];
    [self.renderedAttributedString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachement]];
    _hasAttachements = YES;
    [self endEditing];
    [self addSubview:view];
}

- (void)addLink:(id)data withRange:(NSRange)range
{
    SWLinkAttribute *linkAttribute = [[SWLinkAttribute alloc] init];
    linkAttribute.data = data;
    linkAttribute.range = range;
    linkAttribute.hilighted = NO;
    linkAttribute.linkColor = _linkColor;
    linkAttribute.hilightedLinkColor = _hilightedLinkColor;
    linkAttribute.showUnderline = self.showLinkUnderline;
    linkAttribute.linkType = NSTextCheckingTypeLink;
    [self addLinkAttribute:linkAttribute];
}

- (void)addLinkAttribute:(SWLinkAttribute *)attribute
{
    if(attribute == nil) return;
    NSRange range = attribute.range;
    [self beginEditing];
    
    UIColor *linkColor = attribute.linkColor ? : _linkColor;
    UIColor *hilightedColor = attribute.hilightedLinkColor ? : _hilightedLinkColor;
    [self.renderedAttributedString addAttribute:NSForegroundColorAttributeName value:linkColor range:range];
    if(attribute.hilighted) {
        [self.renderedAttributedString addAttribute:NSBackgroundColorAttributeName value:hilightedColor range:range];
    }
    [self.renderedAttributedString addAttribute:NSUnderlineStyleAttributeName value:@(attribute.showUnderline) range:range];
    [self.renderedAttributedString addAttribute:kSWLinkAttributeName value:attribute range:range];
    _hasLinks = YES;
    [self endEditing];
}

- (void)setActiveLink:(SWLinkAttribute *)activeLink
{
    if(_activeLink != activeLink) {
        _activeLink.hilighted = NO;
        [self addLinkAttribute:_activeLink];
        activeLink.hilighted = YES;
        [self addLinkAttribute:activeLink];
    }
    _activeLink = activeLink;
}

- (void)setNeedsUpdateTextStorage
{
    _needsUpdateTextStorage = YES;
}

- (void)setNeedsDetectLink
{
    _needsDetectLink = YES;
}

- (SWLinkAttribute *)linkAtPoint:(CGPoint)point
{
    if (!_hasLinks || !CGRectContainsPoint(self.bounds, point)) {
        return nil;
    }
    CGRect textRect = self.bounds;
    if(!CGRectContainsPoint(textRect, point)) {
        return nil;
    }
    
    NSLayoutManager *layoutManager = self.textStorage.layoutManagers.firstObject;
    CGFloat f;
    NSInteger idx = [layoutManager characterIndexForPoint:point inTextContainer:layoutManager.textContainers.firstObject fractionOfDistanceBetweenInsertionPoints:&f];
    SWLinkAttribute *linkAttribute = [self.attributedText attribute:kSWLinkAttributeName atIndex:idx longestEffectiveRange:NULL inRange:NSMakeRange(idx, 1)];
    return linkAttribute;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (![self linkAtPoint:point] || !self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    
    return self;
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    SWLinkAttribute *link = [self linkAtPoint:[touch locationInView:self]];
    
    if (!link) {
        if ([self.delegate respondsToSelector:@selector(attributedLabeldidSelectNormalText:)]) {
            [self.delegate attributedLabeldidSelectNormalText:self];
        }
        else
        {
            [super touchesBegan:touches withEvent:event];
        }
        
    } else {
        self.activeLink = link;
    }
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        UITouch *touch = [touches anyObject];
        SWLinkAttribute *link = [self linkAtPoint:[touch locationInView:self]];
        self.activeLink = link;
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        SWLinkAttribute *link = self.activeLink;
        self.activeLink = nil;
        
        if ([self.delegate respondsToSelector:@selector(attributedLabel:didSelectLinkWithLinkType:data:)]) {
            [self.delegate attributedLabel:self didSelectLinkWithLinkType:link.linkType data:link.data];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        self.activeLink = nil;
    } else {
        [super touchesCancelled:touches withEvent:event];
    }
}
@end
