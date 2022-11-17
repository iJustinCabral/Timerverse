//
//  TMVStatusBarGroupView.m
//  Timerverse
//
//  Created by Larry Ryan on 7/12/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVStatusBarGroupView.h"

static CGFloat const kMargin = 10.0f;
static CGFloat const kMinOpacity = 0.0f;
static CGFloat const kMaxOpacity = 1.0f;

@interface TMVStatusBarGroupView ()

@property (nonatomic) NSUInteger showingIndex;
@property (nonatomic) NSUInteger hidingIndex;

@end

@implementation TMVStatusBarGroupView


#pragma mark - Lifecycle -

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        
        _showingIndex = NSNotFound;
        _hidingIndex = NSNotFound;
    }
    return self;
}

- (void)setDataSource:(id<TMVStatusBarGroupViewDatasource>)dataSource
{
    _dataSource = dataSource;
    
    CGFloat newWidth = 0.0f;
    NSUInteger numberOfVisibleItems = 0;
    NSUInteger numberOfItems = [self.dataSource numberOfItemsForGroupView:self];
    
    for (NSUInteger index = 0; index < numberOfItems; index++)
    {
        UIView *item = [self.dataSource groupView:self
                                     itemForIndex:index];
        item.layer.opacity = kMinOpacity;
        item.centerY = self.halfHeight;
        
        if (index > 0)
        {
            UIView *previousVisibleItem = [self nextVisibleView:YES
                                              toTheLeftForIndex:index];
            
            if (previousVisibleItem)
            {
                if ([self itemAtIndex:index
                            isVisible:YES])
                {
                    item.x = previousVisibleItem.right + kMargin;
                    
                    newWidth += item.width;
                    numberOfVisibleItems++;
                }
                else
                {
                    item.x = previousVisibleItem.x;
                }
            }
            else
            {
                if ([self itemAtIndex:index
                            isVisible:YES])
                {
                    newWidth += item.width;
                    numberOfVisibleItems++;
                }
                
                item.x = kMargin;
            }
        }
        else
        {
            item.x = kMargin;
            
            newWidth += item.width;
            numberOfVisibleItems++;
        }
        
        [self addSubview:item];
    }
    
    self.width = newWidth + kMargin + (kMargin * numberOfVisibleItems);
}


#pragma mark - Methods -

#pragma mark Public

- (void)showItemAtIndex:(NSUInteger)index
               animated:(BOOL)animated
{
    // Reset the hiding index since our item is now going to show
    if (self.hidingIndex == index) self.hidingIndex = NSNotFound;
    
    if (self.showingIndex == index) return;
    
    UIView *viewToShow = [self.dataSource groupView:self
                                       itemForIndex:index];
    
    if (viewToShow.layer.opacity == kMaxOpacity) return;
    
    self.showingIndex = index;
    
    // Update width and show the item
    [self updateWidthAnimated:animated
               withCompletion:^{
                   
                   [self showView:viewToShow
                         animated:animated
                   withCompletion:^{
                       
                       self.showingIndex = NSNotFound;
                       
                   }];
                   
                   if ([self.delegate respondsToSelector:@selector(groupView:didShowItemAtIndex:)])
                   {
                       [self.delegate groupView:self didShowItemAtIndex:index];
                   }
                   
               }];
    
    // Shift the items to their correct point
    for (NSUInteger idx = 0; idx < [self.dataSource numberOfItemsForGroupView:self]; idx++)
    {
        if (idx == index) continue;
        
        if (idx > index)
        {
            UIView *view = [self.dataSource groupView:self
                                         itemForIndex:idx];
            
            [self shiftView:view
                  toOriginX:view.x + (viewToShow.width + kMargin)
                   animated:animated];
            
        }
    }
}

- (void)hideItemAtIndex:(NSUInteger)index
               animated:(BOOL)animated
{
    if (self.hidingIndex == index) return;
    
    self.hidingIndex = index;
    
    UIView *viewToHide = [self.dataSource groupView:self
                                       itemForIndex:index];
    
    if (viewToHide.layer.opacity == kMinOpacity) return;
    
    [self hideView:viewToHide
          animated:animated
    withCompletion:^{
        
        [self updateWidthAnimated:animated
                   withCompletion:^{ }];
        
        for (NSUInteger idx = 0; idx < [self.dataSource numberOfItemsForGroupView:self]; idx++)
        {
            if (idx > index)
            {
                UIView *view = [self.dataSource groupView:self
                                             itemForIndex:idx];
                
                [self shiftView:view
                      toOriginX:view.x - (viewToHide.width + kMargin)
                       animated:animated];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(groupView:didHideItemAtIndex:)])
        {
            [self.delegate groupView:self didHideItemAtIndex:index];
        }
        
    }];
}


#pragma mark Private

- (void)updateWidthAnimated:(BOOL)animated
             withCompletion:(void (^)(void))completion
{
    if (animated)
    {
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.width = [self widthForVisibleItems];
                             
                             if (self.centerX < self.superview.centerX)
                             {
                                 self.left = self.superview.left;
                             }
                             else
                             {
                                 self.right = self.superview.right;
                             }
                         }
                         completion:^(BOOL finished) {
                             
                             completion();
                             
                         }];
    }
    else
    {
        self.width = [self widthForVisibleItems];
        
        if (self.centerX < self.superview.centerX)
        {
            self.left = self.superview.left;
        }
        else
        {
            self.right = self.superview.right;
        }
        
        completion();
    }
}

- (void)shiftView:(UIView *)view
        toOriginX:(CGFloat)originX
         animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.3f
                              delay:0.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self shiftView:view
                                   toOriginX:originX
                                    animated:NO];
                         }
                         completion:^(BOOL finished) {}];
    }
    else
    {
        view.x = originX;
    }
}

- (void)showView:(UIView *)view
        animated:(BOOL)animated
  withCompletion:(void (^)(void))completion
{
    if (view.layer.opacity != kMaxOpacity)
    {
        if (animated)
        {
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 view.layer.opacity = kMaxOpacity;
                             }
                             completion:^(BOOL finished) {
                                 
                                 completion();
                                 
                             }];
        }
        else
        {
            view.layer.opacity = kMaxOpacity;
            
            completion();
        }
    }
    else
    {
        completion();
    }
}

- (void)hideView:(UIView *)view
        animated:(BOOL)animated
  withCompletion:(void (^)(void))completion
{
    if (view.layer.opacity != kMinOpacity)
    {
        if (animated)
        {
            [UIView animateWithDuration:0.3f
                                  delay:0.0f
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 view.layer.opacity = kMinOpacity;
                             }
                             completion:^(BOOL finished) {
                                 
                                 completion();
                                 
                             }];
        }
        else
        {
            view.layer.opacity = kMinOpacity;
            
            completion();
        }
    }
    else
    {
        completion();
    }
}


#pragma mark - Helpers -

#pragma mark Public

- (CGFloat)apparentWidth
{
    CGFloat width = [self widthForVisibleItems];
    
    return width;
}

#pragma mark Private

- (UIView *)nextVisibleView:(BOOL)visible toTheLeftForIndex:(NSInteger)index
{
    if (index == 0) return nil;
    
    for (NSInteger idx = index - 1; index <= -1; index--)
    {
        if ([self itemAtIndex:idx isVisible:visible])
        {
            return [self.dataSource groupView:self
                                 itemForIndex:idx];
            
            break;
        }
    }
    
    return nil;
}

- (UIView *)nextVisibleView:(BOOL)visible toTheRightForIndex:(NSUInteger)index
{
    // If we are at the last index, there are no indexs to the right so return
    if (index == [self.dataSource numberOfItemsForGroupView:self] - 1) return nil;
    
    for (NSUInteger idx = index + 1; index >= [self.dataSource numberOfItemsForGroupView:self]; index++)
    {
        if ([self itemAtIndex:idx isVisible:visible])
        {
            return [self.dataSource groupView:self
                                 itemForIndex:idx];
            
            break;
        }
    }
    
    return nil;
}

- (CGFloat)widthForVisibleItems
{
    CGFloat newWidth = 0.0f;
    NSUInteger numberOfItems = [self.dataSource numberOfItemsForGroupView:self];
    NSUInteger numberOfVisibleItems = 0;
    
    for (NSUInteger index = 0; index < numberOfItems; index++)
    {
        if ([self itemAtIndex:index isVisible:YES] || index == self.showingIndex)
        {
            UIView *item = [self.dataSource groupView:self itemForIndex:index];
            
            newWidth += item.width;
            
            numberOfVisibleItems += 1;
        }
    }
    
    if (newWidth == 0.0)
    {
        newWidth = [self widthForItemAtIndex:0] + (kMargin * 2);
    }
    else
    {
        newWidth = newWidth + kMargin + (kMargin * numberOfVisibleItems);
    }
    
    return newWidth;
}

- (CGFloat)widthForItemAtIndex:(NSUInteger)index
{
    UIView *item = [self.dataSource groupView:self itemForIndex:index];
    
    return item.width;
}

- (BOOL)itemAtIndex:(NSUInteger)index isVisible:(BOOL)visible
{
    UIView *view = [self.dataSource groupView:self itemForIndex:index];
    
    return view.layer.opacity == (visible ? kMaxOpacity : kMinOpacity);
}


@end
