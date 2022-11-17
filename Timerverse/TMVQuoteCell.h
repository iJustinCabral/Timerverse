//
//  TMVQuoteCell.h
//  Timerverse
//
//  Created by Larry Ryan on 4/16/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVQuoteCell : UICollectionViewCell

@property (nonatomic, readonly) UITextView *quoteTextView;
@property (nonatomic, readonly) UITextView *keywordTextView;
@property (nonatomic, readonly) UITextView *signatureTextView;

- (void)setQuote:(NSString *)quote
          person:(NSString *)person;

@end
