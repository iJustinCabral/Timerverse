//
//  TMVQuoteCell.m
//  Timerverse
//
//  Created by Larry Ryan on 4/16/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVQuoteCell.h"

@interface TMVQuoteCell ()

@property (nonatomic, readwrite) UITextView *quoteTextView;
@property (nonatomic, readwrite) UITextView *keywordTextView;
@property (nonatomic, readwrite) UITextView *signatureTextView;

@end

@implementation TMVQuoteCell

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.clipsToBounds = YES;
    }
    
    return self;
}

#pragma mark - Properties

- (UITextView *)quoteTextView
{
    if (!_quoteTextView)
    {
        _quoteTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 38.0f)];
        _quoteTextView.textAlignment = NSTextAlignmentLeft;
        _quoteTextView.backgroundColor = [UIColor clearColor];
        //        _quoteTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _quoteTextView.userInteractionEnabled = NO;
        _quoteTextView.scrollEnabled = NO;
        _quoteTextView.editable = NO;
        _quoteTextView.selectable = NO;
        //        _quoteTextView.layer.opacity = 0.0f;
    }
    
    return _quoteTextView;
}

- (UITextView *)keywordTextView
{
    if (!_keywordTextView)
    {
        _keywordTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 38.0f)];
        _keywordTextView.textAlignment = NSTextAlignmentLeft;
        _keywordTextView.backgroundColor = [UIColor clearColor];
        //        _keywordTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _keywordTextView.userInteractionEnabled = NO;
        _keywordTextView.scrollEnabled = NO;
        _keywordTextView.editable = NO;
        _keywordTextView.selectable = NO;
        //        _keywordTextView.layer.opacity = 0.0f;
    }
    
    return _quoteTextView;
}

- (UITextView *)signatureTextView
{
    if (!_signatureTextView)
    {
        _signatureTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, self.quoteTextView.frame.size.height, 320.0, 38.0f)];
        
        _signatureTextView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        _signatureTextView.textAlignment = NSTextAlignmentRight;
        _signatureTextView.textColor = [UIColor grayColor];
        _signatureTextView.backgroundColor = [UIColor clearColor];
        //        _signatureTextView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _signatureTextView.userInteractionEnabled = NO;
        _signatureTextView.scrollEnabled = NO;
        _signatureTextView.editable = NO;
        _signatureTextView.selectable = NO;
        //        _signatureTextView.layer.opacity = 0.0f;
    }
    
    return _signatureTextView;
}

#pragma mark - Public Methods

- (void)setQuote:(NSString *)quote
          person:(NSString *)person
{
    // Here we enumerate the quote and find all the time related keywords, and break them out into ranges
    __weak typeof(self) weakSelf = self;
    __block NSArray *localKeywords = [self timeKeywords];
    
    __block NSMutableArray *keywordRanges = [NSMutableArray array];
    __block NSMutableArray *wordRanges = [NSMutableArray array];
    
    [quote enumerateSubstringsInRange:NSMakeRange(0, [quote length])
                              options:NSStringEnumerationByWords | NSStringEnumerationLocalized
                           usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                               
                               if ([weakSelf isString:substring containedIn:localKeywords])
                               {
                                   [keywordRanges addObject:[NSValue valueWithRange:enclosingRange]];
                               }
                               else
                               {
                                   [wordRanges addObject:[NSValue valueWithRange:enclosingRange]];
                               }
                           }];
    
    // Setup the attributed string
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    UIColor *color = [UIColor whiteColor];
    
    // Quote TextView
    NSMutableAttributedString *attributedQuote = [[NSMutableAttributedString alloc] initWithString:quote
                                                                                        attributes:@{NSFontAttributeName : font,
                                                                                                     NSForegroundColorAttributeName : color}];
    
    for (NSValue *value in keywordRanges)
    {
        [attributedQuote addAttribute:NSForegroundColorAttributeName
                                value:[UIColor clearColor]
                                range:[value rangeValue]];
    }
    
    
    self.quoteTextView.attributedText = attributedQuote;
    [self.quoteTextView sizeToFit];
    CGRect textViewRect = self.quoteTextView.frame;
    
    textViewRect.size.width = 320.0f;
    
    self.quoteTextView.frame = textViewRect;
    
    [self.contentView addSubview:self.quoteTextView];
    
    // Keyword TextView
    
    NSMutableAttributedString *attributedKeyword = [[NSMutableAttributedString alloc] initWithString:quote
                                                                                          attributes:@{NSFontAttributeName : font,
                                                                                                       NSForegroundColorAttributeName : color}];
    
    for (NSValue *value in wordRanges)
    {
        [attributedKeyword addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor whiteColor]
                                  range:[value rangeValue]];
    }
    
    self.keywordTextView.attributedText = attributedKeyword;
    
    
    [self.keywordTextView sizeToFit];
    CGRect keywordTextViewRect = self.keywordTextView.frame;
    
    keywordTextViewRect.size.width = 320.0f;
    
    self.keywordTextView.frame = keywordTextViewRect;
    
    [self.contentView addSubview:self.keywordTextView];
    
    // Signiture TextView
    self.signatureTextView.text = person;
    
    [self.signatureTextView sizeToFit];
    
    CGRect rect = self.signatureTextView.frame;
    rect.origin.y = self.quoteTextView.frame.size.height;
    rect.size.width = 320.0f;
    self.signatureTextView.frame = rect;
    
    [self.contentView addSubview:self.signatureTextView];
}


#pragma mark - Helpers

- (NSArray *)timeKeywords
{
    return @[@"time", @"yesterday", @"tomorrow", @"today", @"forever", @"past", @"future", @"present", @"year", @"always", @"day", @"moment", @"now", @"since"];
}

- (BOOL)isString:(NSString *)comparatorString containedIn:(NSArray *)array
{
    for (NSString *string in array)
    {
        if ([string caseInsensitiveCompare:comparatorString] == NSOrderedSame)
            return YES;
    }
    return NO;
}

@end
