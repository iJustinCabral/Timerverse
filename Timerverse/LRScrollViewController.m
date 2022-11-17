//
//  LRScrollViewController.m
//  Timerverse
//
//  Created by Larry Ryan on 3/23/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "LRScrollViewController.h"

static NSUInteger const kInitialPage = 0;
static CGFloat const kPageMargin = 0.0f;
static CGFloat const kContainerCornerRadius = 0.0f;
static PagingStyle const kDefaultStyle = PagingStyleSwoopDown;
static PagingOrientation const kDefaultOrientation = PagingOrientationHorizontal;

NSString * NSStringFromPagingStyle(PagingStyle Style)
{
    switch (Style)
    {
        case PagingStyleNone:
            return @"PagingStyleNone";
            break;
        case PagingStyleSwoopDown:
            return @"PagingStyleSwoopDown";
            break;
        case PagingStyleHoverOverRight:
            return @"PagingStyleHoverOverRight";
            break;
        case PagingStyleDynamicSprings:
            return @"PagingStyleDynamicSprings";
            break;
        default:
            return @"Invalid Style";
            break;
    }
}

NSString * NSStringFromPagingOrientation(PagingOrientation orientation)
{
    switch (orientation)
    {
        case PagingOrientationHorizontal:
            return @"PagingOrientationHorizontal";
            break;
        case PagingOrientationVertical:
            return @"PagingOrientationVertical";
            break;
        default:
            return @"Invalid Orientation";
            break;
    }
}

NSString * NSStringFromPageSide(PageSide side)
{
    switch (side)
    {
        case PageSideTop:
            return @"PageSideTop";
            break;
        case PageSideRight:
            return @"PageSideRight";
            break;
        case PageSideBottom:
            return @"PageSideBottom";
            break;
        case PageSideLeft:
            return @"PageSideLeft";
            break;
        case PageSideMiddle:
            return @"PageSideMiddle";
            break;
        default:
            return @"Invalid Side";
            break;
    }
}

NSString * NSStringFromTransitionAnimation(TransitionAnimation animation)
{
    switch (animation)
    {
        case TransitionAnimationNone:
            return @"";
            break;
        case TransitionAnimationScale:
            return @"";
            break;
        case TransitionAnimationFade:
            return @"";
            break;
        case TransitionAnimationScaleFade:
            return @"";
            break;
        default:
            return @"Invalid Animation";
            break;
    }
}

NSString * NSStringFromPanDirection(PanDirection direction)
{
    switch (direction)
    {
        case PanDirectionUp:
            return @"PanDirectionUp";
            break;
        case PanDirectionRight:
            return @"PanDirectionRight";
            break;
        case PanDirectionDown:
            return @"PanDirectionDown";
            break;
        case PanDirectionLeft:
            return @"PanDirectionLeft";
            break;
        default:
            return @"Invalid direction";
            break;
    }
}

#pragma mark - Interface (Private)

@interface LRScrollViewController () <UIScrollViewDelegate>

@property (nonatomic) NSMutableArray *sectionContainerArray;

// UIDynamic Properties
@property (nonatomic) UIDynamicAnimator *animator;

// UIScrollView Properties
@property (nonatomic) CGFloat lastScrollDelta;
@property (nonatomic) CGFloat lastContentOffset;
@property (nonatomic) CGFloat lastPercentageScrolled;
@property (nonatomic) NSUInteger destinationIndex;
@property (nonatomic, readwrite) NSUInteger currentIndex;
@property (nonatomic, readwrite, weak) UIViewController *currentViewController;
@property (nonatomic, readwrite, getter = isDragging) BOOL dragging;
@property (nonatomic, readwrite, getter = isHidden) BOOL hidden;

@end


#pragma mark - Implementation

@implementation LRScrollViewController

@dynamic view;


#pragma mark - Lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.pagingStyle = kDefaultStyle;
        self.pagingOrientation = kDefaultOrientation;
        self.initialIndex = kInitialPage;
        self.margin = kPageMargin;
    }
    return self;
}

- (instancetype)initWithPagingStyle:(PagingStyle)pagingStyle
                  pagingOrientation:(PagingOrientation)orientation
                     andInitialPage:(NSUInteger)page
{
    self = [super init];
    if (self)
    {
        // Custom initialization
        self.pagingStyle = pagingStyle;
        self.pagingOrientation = orientation;
        self.initialIndex = page;
        self.margin = kPageMargin;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (void)viewDidLoad
{
    [self configueScrollView];
    
    [super viewDidLoad];
    
    self.currentIndex = self.initialIndex;
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    self.view.layer.allowsEdgeAntialiasing = YES;
    self.view.layer.allowsGroupOpacity = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Properties
#pragma mark Setters

- (void)setPagingStyle:(PagingStyle)pagingStyle
{
    if (_pagingStyle == pagingStyle) return;
    
    _pagingStyle = pagingStyle;
    
    if (_animator)
    {
        _animator = nil;
    }
}

- (void)setCurrentIndex:(NSUInteger)currentIndex
{
    if (_currentIndex == currentIndex) return;
    
    _currentIndex = currentIndex;
    
    // Update the currentViewController to match the currentIndex
    UIViewController *viewController = [self.datasource viewControllerAtIndex:currentIndex
                                                      forScrollViewController:self];
    self.currentViewController = viewController;
    
    // TODO: Find better place for method
    // Let the delegate know we did move to new index
    if ([self.delegate respondsToSelector:@selector(scrollViewController:didMoveToIndex:)])
    {
        [self.delegate scrollViewController:self didMoveToIndex:currentIndex];
    }
}

#pragma mark Getters

- (UIDynamicAnimator *)animator
{
    if (!_animator)
    {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    
    return _animator;
}


#pragma mark - Helpers

- (NSUInteger)numberOfViewControllers
{
    return [self.datasource numberOfViewControllersForScrollViewController:self];
}

- (PanDirection)panDirectionFromVelocity:(CGPoint)velocity
{
    PanDirection direction;
    
    switch (self.pagingOrientation)
    {
        case PagingOrientationHorizontal:
        {
            direction = velocity.x > 0 ? PanDirectionRight : PanDirectionLeft;
        }
            break;
        case PagingOrientationVertical:
        {
            direction = velocity.y > 0 ? PanDirectionDown : PanDirectionUp;
        }
            break;
    }
    
    return direction;
}


#pragma mark - Memory Management

- (void)removeViewControllersAtRange:(NSRange)range
{
    
}

- (void)removeViewControllersAtRanges:(NSArray *)ranges
{
    
}

- (void)restoreViewControllersAtRange:(NSRange)range
{
    
}

- (void)restoreViewControllersAtRanges:(NSArray *)ranges
{
    
}


#pragma mark - UIScrollView

- (void)configueScrollView
{
    CGRect frame = [UIScreen mainScreen].bounds;
    
    NSUInteger numberOfIndexs = [self.datasource numberOfViewControllersForScrollViewController:self];
    CGFloat marginMass = (numberOfIndexs - 1) * self.margin;
    
    self.view.delegate = self;
    self.view.pagingEnabled = self.margin == 0;
    self.view.showsHorizontalScrollIndicator = NO;
    self.view.showsVerticalScrollIndicator = NO;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.decelerationRate = UIScrollViewDecelerationRateFast;
    
    if (self.pagingOrientation == PagingOrientationHorizontal)
    {
        self.view.contentSize = CGSizeMake((self.view.frame.size.width * numberOfIndexs) + marginMass, self.view.frame.size.height);
    }
    else
    {
        self.view.contentSize = CGSizeMake(self.view.frame.size.width, (self.view.frame.size.height * numberOfIndexs) + marginMass);
    }
    
    // Section Containers
    self.sectionContainerArray = [[NSMutableArray alloc] initWithCapacity:numberOfIndexs];
    
    for (NSUInteger index = 0; index < numberOfIndexs; index++)
    {
        CGFloat marginMass = index * self.margin;
        CGPoint offsetOrigin;
        
        if (self.pagingOrientation == PagingOrientationHorizontal)
        {
            offsetOrigin = CGPointMake((frame.size.width * index) + marginMass, frame.origin.y);
        }
        else
        {
            offsetOrigin = CGPointMake(frame.origin.x, (frame.size.height * index) + marginMass);
        }
        
        frame.origin = offsetOrigin;
        
        UIView *sectionContainerView = [[UIView alloc] initWithFrame:frame];
        sectionContainerView.layer.cornerRadius = kContainerCornerRadius;
        sectionContainerView.layer.masksToBounds = NO;
        
        [self.sectionContainerArray addObject:sectionContainerView];
        
        UIViewController *viewController = [self.datasource viewControllerAtIndex:index
                                                          forScrollViewController:self];
        
        [sectionContainerView addSubview:viewController.view];
        [self.view addSubview:sectionContainerView];
        
        if (self.pagingStyle == PagingStyleDynamicSprings)
        {
            [self addSpringToView:sectionContainerView];
        }
    }
    
    [self moveToIndex:self.initialIndex animated:NO];
}

- (void)moveToIndex:(NSUInteger)index animated:(BOOL)animated
{
    // Update the scroll view to the appropriate page
    CGFloat marginMass = index * self.margin;
    
    CGRect frame = self.view.frame;
    CGFloat pageLength = self.pagingOrientation == PagingOrientationHorizontal ? frame.size.width : frame.size.height;
    frame.origin = CGPointMake((pageLength * index) + marginMass, 0);
    
    [self.view scrollRectToVisible:frame animated:animated];
}

- (CGFloat)percentageToEdgeOfScrollView:(UIScrollView *)scrollView
{
    //    CGFloat width = scrollView.frame.size.width;
    //    CGFloat contentOffset = scrollView.contentOffset.x;
    //    CGFloat endOfContent = scrollView.contentSize.width;
    //    NSInteger numberOfPages = endOfContent / width;
    //    CGFloat offset = contentOffset / width;
    //
    
    
    return 0;
}

- (CGFloat)offsetForPageAtIndex:(NSUInteger)index
{
    CGRect frame = self.view.frame;
    CGFloat pageLength = self.pagingOrientation == PagingOrientationHorizontal ? frame.size.width : frame.size.height;
    CGFloat marginMass = index * self.margin;
    CGFloat pageMass = index * pageLength;
    
    return marginMass + pageMass;
}

#pragma mark Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![scrollView isEqual:self.view]) return;
    
    NSUInteger oldDestinationIndex = self.destinationIndex;
    CGRect frame = self.view.frame;
    CGFloat length = self.pagingOrientation == PagingOrientationHorizontal ? frame.size.width : frame.size.height;
    CGFloat contentOffset = self.pagingOrientation == PagingOrientationHorizontal ? scrollView.contentOffsetX : scrollView.contentOffsetY;
    CGFloat offsetPercentage = contentOffset / length;
    CGFloat currentIndexFromOrigin = 0.0;
    CGFloat percentage;
    
    percentage = fmodf(offsetPercentage, currentIndexFromOrigin);
    
    // Direction of scrolling
    PanDirection direction;
    
    if (self.pagingOrientation == PagingOrientationHorizontal)
    {
        direction = offsetPercentage < self.lastPercentageScrolled ? PanDirectionRight : PanDirectionLeft;
    }
    else
    {
        direction = offsetPercentage < self.lastPercentageScrolled ? PanDirectionDown : PanDirectionUp;
    }
    
    // Set the current page once the page is at its content offset
    if ((int)contentOffset % (int)length == 0)
    {
        int page = contentOffset / length;
        
        if (self.currentIndex != page)
        {
            self.currentIndex = page;
        }
    }
    
    // Get which side of the current page you are on.
    PageSide nearestDestinationSide;
    
    if (offsetPercentage == (float)self.currentIndex)
    {
        nearestDestinationSide = PageSideMiddle;
    }
    else
    {
        if (offsetPercentage < (float)self.currentIndex)
        {
            nearestDestinationSide = self.pagingOrientation == PagingOrientationHorizontal ? PageSideLeft : PageSideTop;
        }
        else
        {
            nearestDestinationSide = self.pagingOrientation == PagingOrientationHorizontal ? PageSideRight : PageSideBottom;
        }
    }
    
    switch (nearestDestinationSide)
    {
        case PageSideTop:
        case PageSideLeft:
        {
            percentage = 1.0f - percentage;
            
            if (self.currentIndex == 0)
            {
                self.destinationIndex = self.currentIndex;
            }
            else if (self.destinationIndex != self.currentIndex - 1)
            {
                self.destinationIndex = self.currentIndex - 1;
            }
        }
            break;
        case PageSideRight:
        case PageSideBottom:
        {
            if (self.currentIndex == [self.datasource numberOfViewControllersForScrollViewController:self] - 1)
            {
                self.destinationIndex = self.currentIndex;
            }
            else if (self.destinationIndex != self.currentIndex + 1)
            {
                self.destinationIndex = self.currentIndex + 1;
            }
        }
            break;
        case PageSideMiddle:
        {
            if (self.destinationIndex != self.currentIndex)
            {
                self.destinationIndex = self.currentIndex;
            }
        }
            break;
    }
    
    
    if (self.destinationIndex != self.currentIndex)
    {
        // Let the delegate know the scrollview scrolled
        if (scrollView.isDecelerating)
        {
            if ([self.delegate respondsToSelector:@selector(scrollViewController:didDecelerateWithPercentage:inDirection:toViewController:)])
            {
                [self.delegate scrollViewController:self
                        didDecelerateWithPercentage:percentage
                                        inDirection:direction
                                   toViewController:[self.datasource viewControllerAtIndex:self.destinationIndex
                                                                   forScrollViewController:self]];
            }
        }
        else
        {
            if ([self.delegate respondsToSelector:@selector(scrollViewController:didScrollWithPercentage:inDirection:toViewController:)])
            {
                [self.delegate scrollViewController:self
                            didScrollWithPercentage:percentage
                                        inDirection:direction
                                   toViewController:[self.datasource viewControllerAtIndex:self.destinationIndex
                                                                   forScrollViewController:self]];
            }
        }
        
        
        //
        if (self.destinationIndex != oldDestinationIndex)
        {
            UIViewController *destinationViewController = [self.datasource viewControllerAtIndex:self.destinationIndex forScrollViewController:self];
            
            if ([self.delegate respondsToSelector:@selector(scrollViewController:didBeginScrollingWithPercentage:inDirection:towardsViewController:fromViewController:)])
            {
                UIViewController *sourceViewController = [self.datasource viewControllerAtIndex:self.currentIndex
                                                                        forScrollViewController:self];
                
                [self.delegate scrollViewController:self
                    didBeginScrollingWithPercentage:percentage
                                        inDirection:direction
                              towardsViewController:destinationViewController
                                 fromViewController:sourceViewController];
            }
        }
    }
    
    // Update the last percentage scrolled, which is used to calculate scrolling direction
    self.lastPercentageScrolled = offsetPercentage;
    
    // Apply the paging trasitions
    switch (self.pagingStyle)
    {
        case PagingStyleNone:
            break;
        case PagingStyleSwoopDown:
            [self pagingStyleSwoopDown];
            break;
        case PagingStyleHoverOverRight:
            [self pagingStyleHoverOverRight];
            break;
        case PagingStyleDynamicSprings:
            if (self.isDragging) [self updateSprings];
            break;
        default:
            break;
    }
    
    // Stretching
    if ([self scrollViewIsStretchingBottom:scrollView])
    {
        if ([self.delegate respondsToSelector:@selector(scrollViewController:didStretchPageSide:forIndex:)])
        {
            [self.delegate scrollViewController:self
                             didStretchPageSide:PageSideBottom
                                       forIndex:self.currentIndex];
        }
    }
    
    
    if ([self scrollViewIsStretchingTop:scrollView])
    {
        if ([self.delegate respondsToSelector:@selector(scrollViewController:didStretchPageSide:forIndex:)])
        {
            [self.delegate scrollViewController:self
                             didStretchPageSide:PageSideTop
                                       forIndex:self.currentIndex];
        }
    }

    
    if ([self.delegate respondsToSelector:@selector(scrollViewControllerAllowsScrolling:)])
    {
        if (![self.delegate scrollViewControllerAllowsScrolling:self])
        {
            [self.delegate contentOffsetTransitionWhileDisabledScrolling:contentOffset];
            
            self.view.contentOffset = CGPointZero;
            
//            if (self.pagingOrientation == PagingOrientationHorizontal)
//            {
//                self.view.contentOffsetX = self.lastContentOffset;
//            }
//            else
//            {
//                self.view.contentOffsetY = self.lastContentOffset;
//            }
        }
    }
    
    if (self.pagingOrientation == PagingOrientationHorizontal)
    {
        self.lastContentOffset = scrollView.contentOffsetX;
    }
    else
    {
        self.lastContentOffset = scrollView.contentOffsetY;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if ([self.delegate respondsToSelector:@selector(scrollViewController:didEndScrollingToViewController:)])
    {
        [self.delegate scrollViewController:self
            didEndScrollingToViewController:[self.datasource viewControllerAtIndex:self.destinationIndex
                                                           forScrollViewController:self]];
    }
}

// Only used when the pageMargin is greater than zero. If the margin IS 0.0f then we used the scrollViews pagingEnabled instead
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (self.margin == 0) return;
    
    CGFloat offset;
    
    CGFloat velocityThreshold = 1;
    
    if (velocity.x > velocityThreshold || velocity.x < -velocityThreshold)
    {
        CGFloat pageWidth = self.view.width;
        NSUInteger currentIndexFromCenter = floor((targetContentOffset->x - pageWidth / 2) / pageWidth) + 1;
        NSUInteger numberOfIndexes = [self.datasource numberOfViewControllersForScrollViewController:self];
        
        if (velocity.x > velocityThreshold) // Going towards right index
        {
            if (currentIndexFromCenter == numberOfIndexes - 1)
            {
                offset = [self offsetForPageAtIndex:currentIndexFromCenter];
            }
            else
            {
                offset = [self offsetForPageAtIndex:currentIndexFromCenter + 1];
            }
        }
        else // Going towards left index
        {
            if (currentIndexFromCenter == 0)
            {
                offset = [self offsetForPageAtIndex:currentIndexFromCenter];
            }
            else
            {
                offset = [self offsetForPageAtIndex:currentIndexFromCenter - 1];
            }
        }
    }
    else
    {
        if (self.lastPercentageScrolled < 0.5)
        {
            offset = [self offsetForPageAtIndex:self.currentIndex];
        }
        else
        {
            offset = [self offsetForPageAtIndex:self.destinationIndex];
        }
    }
    
    targetContentOffset->x = offset;
    
    if ([self.delegate respondsToSelector:@selector(scrollViewController:didEndScrollingToViewController:)])
    {
        [self.delegate scrollViewController:self
            didEndScrollingToViewController:[self.datasource viewControllerAtIndex:self.destinationIndex
                                                           forScrollViewController:self]];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewController:willBeginDeceleratingToViewController:)])
    {
        [self.delegate scrollViewController:self
      willBeginDeceleratingToViewController:[self.datasource viewControllerAtIndex:self.destinationIndex
                                                           forScrollViewController:self]];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewController:didEndDeceleratingToViewController:)])
    {
        [self.delegate scrollViewController:self
         didEndDeceleratingToViewController:[self.datasource viewControllerAtIndex:self.destinationIndex
                                                           forScrollViewController:self]];
    }
}

- (BOOL)scrollViewIsStretchingTop:(UIScrollView *)scrollView
{
    return scrollView.contentOffsetY < 0.0f;
}

- (BOOL)scrollViewIsStretchingBottom:(UIScrollView *)scrollView
{
    return scrollView.contentOffsetY + scrollView.height > scrollView.contentSizeHeight;
}



#pragma mark Show/Hide Methods

- (void)showWithAnimation:(TransitionAnimation)transitionAnimation
{
    switch (transitionAnimation)
    {
        case TransitionAnimationNone:
        {
            self.view.layer.transform = CATransform3DIdentity;
            self.view.alpha = 0.0;
            self.view.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0f);
        }
            break;
        case TransitionAnimationFade:
        {
            [UIView animateWithDuration:0.2
                                  delay:0.1
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.view.layer.transform = CATransform3DIdentity;
                                 self.view.alpha = 1.0;
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
            break;
        case TransitionAnimationScale:
        {
            [UIView animateWithDuration:0.2
                                  delay:0.1
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.view.layer.transform = CATransform3DIdentity;
                                 self.view.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0f);
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
            
            break;
        case TransitionAnimationScaleFade:
        {
            [UIView animateWithDuration:0.2
                                  delay:0.1
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.view.layer.transform = CATransform3DIdentity;
                                 self.view.alpha = 1.0;
                                 self.view.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0f);
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
            break;
    }
    
    self.hidden = NO;
}

- (void)hideWithAnimation:(TransitionAnimation)transitionAnimation
{
    switch (transitionAnimation)
    {
        case TransitionAnimationNone:
        {
            self.view.layer.transform = CATransform3DIdentity;
            self.view.alpha = 0.0;
            self.view.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0f);
        }
            break;
        case TransitionAnimationFade:
        {
            [UIView animateWithDuration:0.2
                                  delay:0.1
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.view.layer.transform = CATransform3DIdentity;
                                 self.view.alpha = 0.0;
                             }
                             completion:^(BOOL finished)
             {
                 
             }];
        }
            break;
        case TransitionAnimationScale:
        {
            [UIView animateWithDuration:0.2
                                  delay:0.1
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.view.layer.transform = CATransform3DIdentity;
                                 self.view.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0f);
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
            
            break;
        case TransitionAnimationScaleFade:
        {
            [UIView animateWithDuration:0.2
                                  delay:0.1
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.view.layer.transform = CATransform3DIdentity;
                                 self.view.alpha = 0.0;
                                 self.view.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0f);
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        }
            break;
    }
    
    self.hidden = YES;
}

#pragma mark Transition Animations

- (void)pagingStyleSwoopDown
{
    for (UIView *sectionContainer in self.sectionContainerArray)
    {
        NSUInteger sectionIndex = [self.sectionContainerArray indexOfObject:sectionContainer];
        NSUInteger numberOfSections = self.sectionContainerArray.count;
        self.view.layer.transform = CATransform3DIdentity;
        
        // Easier reference to these
        CGFloat scrollViewWidth = self.view.bounds.size.width;
        CGFloat offset = self.view.contentOffset.x;
        
        // Do some initial calculations to see how far off it is from being the center card
        CGFloat nearestToCenterPage = (offset / scrollViewWidth);
        CGFloat pageDifference = (sectionIndex - nearestToCenterPage);
        
        // And the default values
        CGFloat scale = 1.0f;
        
        if (sectionIndex == 0) // First Section
        {
            if (nearestToCenterPage > 0)
            {
                scale = 1 + (pageDifference / 10);
            }
            else
            {
                
            }
        }
        else if (sectionIndex == numberOfSections - 1) // Last Section
        {
            if (nearestToCenterPage > numberOfSections - 1)
            {
                
            }
            else
            {
                scale = 1 - (pageDifference / 10);
            }
        }
        else // Between Cards
        {
            if (nearestToCenterPage > sectionIndex)
            {
                scale = 1 + (pageDifference / 10);
            }
            else
            {
                scale = 1 - (pageDifference / 10);
            }
        }
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        sectionContainer.layer.transform = CATransform3DMakeScale(scale, scale, 1.0f);
        [CATransaction commit];
    }
}

- (void)pagingStyleHoverOverRight
{
    for (UIView *sectionContainer in self.sectionContainerArray)
    {
        NSUInteger sectionIndex = [self.sectionContainerArray indexOfObject:sectionContainer];
        
        self.view.layer.transform = CATransform3DIdentity;
        
        // Easier reference to these
        CGFloat scrollViewWidth = self.view.bounds.size.width;
        CGFloat offset = self.view.contentOffset.x;
        
        // Do some initial calculations to see how far off it is from being the center card
        CGFloat currentIndex = (offset / scrollViewWidth);
        CGFloat pageDifference = (sectionIndex - currentIndex);
        
        // And the default values
        CGFloat scale = 1.0f;
        CGFloat alpha = 1.0f;
        
        // Scale it based on how far it is from being centered
        scale += (pageDifference * 0.2);
        
        // If it's meant to have faded into the screen fade it out
        if (pageDifference > 0.0f)
        {
            alpha = 1 - pageDifference;
        }
        
        // Don't let it get below nothing (like reversed is -1)
        if (scale < 0.0f)
        {
            scale = 0.0f;
        }
        
        // If you can't see it disable userInteraction so as to stop it preventing touches on the one bellow.
        if (alpha <= 0.0f)
        {
            alpha = 0.0f;
            self.view.userInteractionEnabled = NO;
        }
        else
        {
            self.view.userInteractionEnabled = YES;
        }
        
        // Set effects
        self.view.alpha = alpha;
        
        // We could do just self.transform = but it comes by default with an animation.
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.view.layer.transform = CATransform3DMakeScale(scale, scale, 1.0f);
        [CATransaction commit];
    }
}

#pragma mark - UIDynamic Behaviors

- (void)addSpringToView:(UIView *)view
{
    UIAttachmentBehavior *spring = [[UIAttachmentBehavior alloc] initWithItem:view
                                                             attachedToAnchor:view.center];
    
    spring.length = 0;
    spring.damping = 0.7;
    spring.frequency = 0.8;
    
    [self.animator addBehavior:spring];
}

- (void)updateSprings
{
    CGPoint touchLocation = [self.view.panGestureRecognizer locationInView:self.view];
    CGFloat scrollDelta = self.view.bounds.origin.x - self.lastScrollDelta;
    
    self.lastScrollDelta = self.view.bounds.origin.x;
    
    for (UIAttachmentBehavior *spring in self.animator.behaviors)
    {
        UIView *container = spring.items.firstObject;
        
        CGPoint anchorPoint = spring.anchorPoint;
        CGFloat distanceFromTouch = fabsf(touchLocation.x - anchorPoint.x);
        CGFloat scrollResistance = distanceFromTouch * (1 / 2000.0f);
        
        CGFloat axisValue = container.center.x;
        
        if (scrollDelta < 0)
        {
            axisValue += MAX(scrollDelta, scrollDelta * scrollResistance);
        }
        else
        {
            axisValue += MIN(scrollDelta, scrollDelta * scrollResistance);
        }
        
        container.center = CGPointMake(axisValue, container.center.y);
        
        [self.animator updateItemUsingCurrentState:container];
    }
}

//- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
//{
//    for (UIView *view in self.view.subviews)
//    {
//        if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self.view convertPoint:point toView:view] withEvent:event])
//            return YES;
//    }
//
//    return NO;
//}

@end
