//
//  TNKColorPickerDotView.h
//  TNKCube
//
//  Created by Larry Ryan on 5/17/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TNKColorPickerDotViewDelegate;

@interface TNKColorPickerDotView : UIView

@property (nonatomic) id <TNKColorPickerDotViewDelegate> delegate;

- (void)cancelGestures;

@end


@protocol TNKColorPickerDotViewDelegate <NSObject>

- (void)didChangeDotView:(TNKColorPickerDotView *)dotView
                 toColor:(UIColor *)color;

@end
