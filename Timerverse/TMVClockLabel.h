//
//  TMVClockLabel.h
//  Timerverse
//
//  Created by Larry Ryan on 2/1/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMVClockLabel : UIView

@property (nonatomic, getter = isDragging) BOOL dragging; // Set by status bar
@property (nonatomic, readonly, getter = isShowingSeconds) BOOL showSeconds;
@property (nonatomic, readonly) UILabel *secondLabel;
@property (nonatomic, readonly) CGFloat apparentWidth; // The clock changes size depending on what elements are shown. The actual size stays the same but we shift the view to make it look like the width has changed. "apparentWidth" will return what appears to be the clocks width;

- (void)snapToNearestCornerAnimated:(BOOL)animated;

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation;

@end


