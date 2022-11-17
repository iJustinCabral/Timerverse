//
//  TNKCube.m
//  Thinkr
//
//  Created by Larry Ryan on 1/2/14.
//  Copyright (c) 2014 Thinkr LLC. All rights reserved.
//

#import "TNKCube.h"
#import "PaintCube.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

static CGFloat const kActionStateReloadThreshold = 0.50; // Percentage limit to trigger the reload action
static CGFloat const kActionStateBackToTopThreshold = 0.70; // Percentage limit to trigger the btt action
static CGFloat const kExpandingLength = 30.0f; // How far the cube expands
static CGFloat const kCubeScale = 0.7f;

// Animation Durations
static CGFloat const kDefaultDuration = 0.3;
//static CGFloat const kSpiralStepDuration = 0.05;
static CGFloat const kExpandingDuration = 0.15;
static CGFloat const kSunDuration = 0.3;
static CGFloat const kXDuration = 0.3;
static CGFloat const kColorDuration = 0.3;

@interface TNKCube ()

@property (nonatomic) NSMutableArray *shapeLayerArray; // Array which holds the shapelayers created from the bezierPaths
@property (nonatomic) NSMutableArray *flickeringLayerIndexes; // When the cube is flickering it holds the non-yet-flickering triangles to be randomly chosen to flick next

@property (nonatomic) CGFloat lastPercentageScrolled; // Helps keep track of which direction

@property (nonatomic) CADisplayLink *displayLink;

@property (nonatomic) BOOL cubedX;

// Pivoting points to tanslate to arrows
@property (nonatomic) CGPoint arrowPivotPointTL;
@property (nonatomic) CGPoint arrowPivotPointTR;
@property (nonatomic) CGPoint arrowPivotPointBL;
@property (nonatomic) CGPoint arrowPivotPointBR;

@property (nonatomic) CGFloat actionStateReloadThreshold;
@property (nonatomic) CGFloat actionStateBackToTopThreshold;

@property (nonatomic, readwrite) TNKCubeType type;
@property (nonatomic, readwrite) TNKCubeState state;
@property (nonatomic, readwrite) TNKCubeState stateByPercentage; // The state may be other than default and have a value of 0.0 percent which is actually the default state.
@property (nonatomic, readwrite) TNKCubeExpansionState expansionState;
@property (nonatomic, readwrite) TNKCubeArrowOrientation arrowOrientation;

@property (nonatomic, readwrite, getter = isFlickering) BOOL flickering;
@property (nonatomic, readwrite) UIColor *color;

@property (nonatomic) UIView *topXFlipView;
@property (nonatomic) UIView *bottomXFlipView;

@end

@implementation TNKCube


#pragma mark - Lifecycle

- (instancetype)init
{
    return [self initWithFrame:CGRectMake(0, 0, 44, 50)];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithType:TNKCubeTypeLayers
                     andState:TNKCubeStateDefault];
}

- (instancetype)initWithType:(TNKCubeType)type
                    andState:(TNKCubeState)state
{
    self = [super initWithFrame:CGRectMake(0, 0, 44, 50)];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        CATransform3D perspectiveTransform = CATransform3DIdentity;
        perspectiveTransform.m34 = -1.0 / 1000.0;
        self.layer.sublayerTransform = perspectiveTransform;
        
        self.type = type;
        self.state = state;
        
        self.actionStateReloadThreshold = kActionStateReloadThreshold;
        self.actionStateBackToTopThreshold = kActionStateBackToTopThreshold;
        
        switch (self.type)
        {
            case TNKCubeTypeLayers:
            {
                for (CAShapeLayer *layer in [self shapeLayerArray])
                {
                    [self.layer addSublayer:layer];
                }
            }
                break;
            case TNKCubeTypeImages:
            {
                
            }
                break;
            case TNKCubeTypeFlat:
            {
                [self addSubview:[[UIImageView alloc] initWithImage:[PaintCube imageOfCube]]];
            }
                break;
        }
    }
    return self;
}

- (void)setState:(TNKCubeState)state
{
    if (_state == state) return;
    
    _state = state;
}

- (void)changeToState:(TNKCubeState)state
             animated:(BOOL)animated
{
    [self transitionToState:state
             withPercentage:1.0f
                   animated:animated];
}

- (void)changeToExpansionState:(TNKCubeExpansionState)expansionState
                      animated:(BOOL)animated
{
    [self transitionToState:TNKCubeStateExpansion
             withPercentage:self.expansionState == TNKCubeExpansionStateContracted ? 0.0f : 1.0f
                   animated:animated];
}

- (void)transitionToState:(TNKCubeState)state
           withPercentage:(CGFloat)percentage
{
    [self transitionToState:state
             withPercentage:percentage
                   animated:NO];
}

- (void)resetCurrentState
{
    CGFloat percentage = 0.0f;
    BOOL animated = YES;
    
    switch (self.state)
    {
        case TNKCubeStateDefault:
            return;
            break;
        case TNKCubeStateSpiral:
        {
            [self transitionToSpiralWithPercentage:percentage
                                          animated:animated];
        }
            break;
        case TNKCubeStateExpansion:
        {
            [self transitionToExpansionWithPercentage:percentage
                                             animated:animated];
        }
            break;
        case TNKCubeStateSun:
        {
            [self transitionToSunWithPercentage:percentage
                                       animated:animated];
        }
            break;
        case TNKCubeStateX:
        {
            [self transitionToXWithPercentage:percentage
                                     animated:animated];
        }
            break;
        case TNKCubeStateArrow:
        {
            [self transitionToArrowWithOrientation:self.arrowOrientation
                                      andPercenage:percentage];
        }
            break;
        case TNKCubeStateShare:
        {
            [self transitionToShareWithPercentage:percentage
                                         animated:animated];
        }
            break;
    }
}

- (void)transitionToState:(TNKCubeState)state
           withPercentage:(CGFloat)percentage
                 animated:(BOOL)animated
{
//    self.state = percentage > 0.0f ? TNKCubeStateExpansion : TNKCubeStateDefault;
    
    switch (state)
    {
        case TNKCubeStateDefault:
        {
            [self resetToDefault];
        }
            break;
        case TNKCubeStateSpiral:
        {
            [self transitionToSpiralWithPercentage:percentage
                                          animated:animated];
        }
            break;
        case TNKCubeStateExpansion:
        {
            [self transitionToExpansionWithPercentage:percentage
                                             animated:animated];
        }
            break;
        case TNKCubeStateSun:
        {
            [self transitionToSunWithPercentage:percentage
                                       animated:animated];
        }
            break;
        case TNKCubeStateX:
        {
            [self transitionToXWithPercentage:percentage
                                     animated:animated];
        }
            break;
        case TNKCubeStateArrow:
        {
            [self transitionToArrowWithOrientation:self.arrowOrientation
                                      andPercenage:percentage];
        }
            break;
        case TNKCubeStateShare:
        {
            [self transitionToShareWithPercentage:percentage
                                         animated:animated];
        }
            break;
    }
    
    self.stateByPercentage = percentage == 0.0f ? TNKCubeStateDefault : state;
    self.state = state;
}

- (void)resetToDefault
{
    [self resetCurrentState];
    
    //    for (CAShapeLayer *shapeLayer in self.shapeLayerArray)
    //    {
    //        shapeLayer.transform = CATransform3DMakeTranslation(0.0, 0, 0.0);
    //    }
}

#pragma mark -

- (void)updateLayer:(CALayer *)layer
         toPosition:(CGPoint)position
      withAnimation:(BOOL)animation
{
    if (animation)
    {
        layer.position = position;
    }
    else
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        layer.position = position;
        
        [CATransaction commit];
    }
}

- (void)applyBasicAnimation:(CABasicAnimation *)animation
                    toLayer:(CALayer *)layer
        withCompletionBlock:(void (^)(void))completion
{
    animation.fromValue = [layer.presentationLayer ?: layer valueForKeyPath:animation.keyPath];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^{ completion(); }];
    
    [layer setValue:animation.toValue forKeyPath:animation.keyPath];
    
    [layer addAnimation:animation forKey:animation.keyPath];
    
    [CATransaction commit];
}

- (void)updateLayer:(CALayer *)layer
         toPosition:(CGPoint)position
withCustomAnimationUsingSprings:(BOOL)useSprings
{
    
}

#pragma mark - Helpers

- (CGFloat)relativePercentageWithMinRange:(CGFloat)minRange
                                 maxRange:(CGFloat)maxRange
                            andPercentage:(CGFloat)percentage
{
    CGFloat range = maxRange - minRange;
    CGFloat fixedPercentage = percentage - minRange;
    CGFloat relativePercentage = fixedPercentage / range;
    
    return relativePercentage;
}

- (CGFloat)angleBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2
{
    CGFloat deltaX = point2.x - point1.x;
    CGFloat deltaY = point2.y - point1.y;
    
    return atan2(deltaY, deltaX);
}

- (CGFloat)fixPercentage:(CGFloat)percentage
{
    if (percentage < 0.0) percentage = 0.0;
    if (percentage > 1.0) percentage = 1.0;
    
    return percentage;
}

#pragma mark - Color transitions

- (void)changeToDefaultColorsAnimated:(BOOL)animated
{
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *shapeLayer, NSUInteger index, BOOL *stop) {
        if (animated)
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
            animation.duration = kColorDuration;
            animation.toValue = (id)[self colorForTriangleAtIndex:index].CGColor;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
            
            [self applyBasicAnimation:animation
                              toLayer:shapeLayer
                  withCompletionBlock:^{
                      
                  }];
        }
    }];
}

- (void)changeToColor:(UIColor *)color
             animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    switch (self.type)
    {
        case TNKCubeTypeLayers:
        {
            [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *shapeLayer, NSUInteger index, BOOL *stop) {
                
                if (animated)
                {
                    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
                    animation.duration = kColorDuration;
                    animation.toValue = (id)color.CGColor;
                    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                    
                    [self applyBasicAnimation:animation
                                      toLayer:shapeLayer
                          withCompletionBlock:^{
                              
                          }];
                }
                else
                {
                    shapeLayer.fillColor = color.CGColor;
                }
            }];
        }
            break;
        case TNKCubeTypeImages:
        case TNKCubeTypeFlat:
        {
            if (animated)
            {
                [UIView animateWithDuration:kColorDuration
                                      delay:0.0f
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     self.tintColor = color;
                                 }
                                 completion:^(BOOL finished) {}];
            }
            else
            {
                self.tintColor  = color;
            }
        }
            break;
    }
    
    [CATransaction commit];
}

- (void)transitionToColor:(UIColor *)color
           withPercentage:(CGFloat)percentage
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    switch (self.type)
    {
        case TNKCubeTypeLayers:
        {
            [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *shapeLayer, NSUInteger index, BOOL *stop) {
                shapeLayer.fillColor = color.CGColor;
            }];
        }
            break;
        case TNKCubeTypeImages:
        case TNKCubeTypeFlat:
        {
            self.tintColor = color;
        }
            break;
    }
    
    [CATransaction commit];
}


#pragma mark - Expansion Methods

- (void)transitionToExpansionWithPercentage:(CGFloat)percentage
                                   animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *shapeLayer, NSUInteger index, BOOL *stop) {
        // The angle is from the center of the CUBE to the center of the shapeLayer. Once we get the angle we need to adjust it so we can update the shapeLayers origin.
        CGFloat length = kExpandingLength * percentage;
        
        if (index < 3) length /= 3;
        
        CGRect pathRect = CGPathGetBoundingBox(shapeLayer.path);
        CGPoint shapePoint = CGRectGetCenter(pathRect);
        
//        CGPoint point = [self convertPoint:self.layer.position fromView:nil];
        
        CGFloat angle = [self angleBetweenPoint:self.center
                                       andPoint:shapePoint];
        
        double endX = cos(angle) * length;
        double endY = sin(angle) * length;
        
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DMakeTranslation(endX, endY, 0.0);
        
        if (animated)
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
            animation.toValue = [NSValue valueWithCATransform3D:transform];
            animation.duration = kExpandingDuration;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            
            [self applyBasicAnimation:animation
                              toLayer:shapeLayer
                  withCompletionBlock:^{ }];
        }
        else
        {
            shapeLayer.transform = transform;
        }
    }];
    
    [CATransaction commit];
}

#pragma mark - Spiral Transition

- (void)transitionToSpiralWithPercentage:(CGFloat)percentage
                                animated:(BOOL)animated
{
    percentage = 1.0f - percentage;
    
    if (percentage == 0.0)
    {
        for (CAShapeLayer *layer in self.shapeLayerArray)
        {
            if (layer.opacity != 0.0)
            {
                layer.opacity = 0.0;
            }
        }
    }
    
    if (percentage >= 1.0)
    {
        for (CAShapeLayer *layer in self.shapeLayerArray)
        {
            if (layer.opacity != 1.0)
            {
                layer.opacity = 1.0;
            }
        }
    }
    
    CGFloat maxPercentage = 1.0f;
    CGFloat segmentValue = maxPercentage / self.shapeLayerArray.count;
    NSUInteger segmentIndex = floor(percentage / segmentValue);
    
    if (segmentIndex > self.shapeLayerArray.count - 1) segmentIndex = self.shapeLayerArray.count - 1;
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger layerIndex, BOOL *stop) {
        if (layerIndex < segmentIndex)
        {
            if (layer.opacity != 1.0)
            {
                layer.opacity = 1.0;
            }
        }
        else if (layerIndex > segmentIndex)
        {
            if (layer.opacity != 0.0)
            {
                layer.opacity = 0.0;
            }
        }
    }];
    
    CGFloat segmentPercentage = (percentage - (segmentValue * segmentIndex)) / segmentValue;
    
    CAShapeLayer *layer = self.shapeLayerArray[segmentIndex];
    
    if (animated)
    {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.toValue = @(segmentPercentage);
        animation.duration = 1.0f;
        
        [self applyBasicAnimation:animation
                          toLayer:layer
              withCompletionBlock:^{}];
    }
    else
    {
        layer.opacity = segmentPercentage;
    }
}


#pragma mark - Sharing Transition

- (NSArray *)sharingHiddenLayers
{
    return @[];
}

- (NSArray *)sharingArrowLayers
{
    return @[@0, @1, @2, @4, @5, @6, @7, @8, @9, @10, @11];
}

- (void)transitionToShareWithPercentage:(CGFloat)percentage
                               animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop)
     {
         CGFloat length = 13.0f;
         
         if ([[self sharingArrowLayers] containsObject:@(index)])
         {
             if (animated)
             {
                 CATransform3D transform = CATransform3DIdentity;
                 transform = CATransform3DMakeTranslation(0, -length * percentage, 0);
                 
                 CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
                 animation.toValue = [NSValue valueWithCATransform3D:transform];
                 animation.duration = kXDuration;
                 
                 [self applyBasicAnimation:animation
                                   toLayer:layer
                       withCompletionBlock:^{
                           
                       }];
             }
             else
             {
                 layer.transform = CATransform3DMakeTranslation(0, -length * percentage, 0);
             }
         }
     }];
    
    [CATransaction commit];
}


#pragma mark - Arrow

- (NSArray *)arrowLayerForOrientation:(TNKCubeArrowOrientation)orientation
{
    switch (orientation)
    {
        case TNKCubeArrowOrientationUp:
        {
            return @[@4, @5, @6, @7, @8, @9, @10, @11];
        }
            break;
        case TNKCubeArrowOrientationDown:
        {
            return @[@13, @14, @15, @16, @17, @18, @19, @20];
        }
            break;
    }
}

- (NSArray *)hiddenArrowLayerForOrientation:(TNKCubeArrowOrientation)orientation
{
    switch (orientation)
    {
        case TNKCubeArrowOrientationUp:
        {
            return @[@0, @1, @2, @3, @12, @13, @14, @15, @16, @17, @18, @19, @20];
        }
            break;
        case TNKCubeArrowOrientationDown:
        {
            return @[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12];
        }
            break;
    }
}

- (void)transitionToArrowWithOrientation:(TNKCubeArrowOrientation)arrowOrientation
                            andPercenage:(CGFloat)percentage
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CGFloat reversedPercentage = 1.0f - percentage;
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop) {
        
        if ([[self hiddenArrowLayerForOrientation:arrowOrientation] containsObject:@(index)])
        {
            layer.opacity = reversedPercentage;
        }
        
        if ([[self arrowLayerForOrientation:arrowOrientation] containsObject:@(index)])
        {
            
        }
        
    }];
    
    [CATransaction commit];
}

#pragma mark - X Methods

- (NSArray *)topXLayers
{
    return @[@4, @5, @6, @9, @10, @11];
}

- (NSArray *)bottomXLayers
{
    return @[@13, @14, @15, @18, @19, @20];
}

- (NSArray *)middleXLayers
{
    return @[@3, @12];
}

- (NSArray *)hiddenXLayers
{
    return @[@0, @1, @2, @7, @8, @16, @17];
}

- (void)transitionToXWithPercentage:(CGFloat)percentage
                           animated:(BOOL)animated
{
    [self transitionScaleWithIndexes:[self hiddenXLayers]
                      withPercentage:[self fixPercentage:percentage / 0.3]
                            animated:animated];
    
    [self transitionFadeWithIndexes:[self hiddenXLayers]
                     withPercentage:[self fixPercentage:percentage / 0.3]
                           animated:animated];
    
    [self transitionMiddleXLayersWithPercentage:[self fixPercentage:percentage / 0.65]
                                       animated:animated];
    
    [self transitionFlippingXLayersWithPercentage:percentage
                                         animated:animated];
}

- (void)transitionFlippingXLayersWithPercentage:(CGFloat)percentage
                                       animated:(BOOL)animated
{
    NSArray *topLayers = [self topXLayers];
    NSArray *bottomLayers = [self bottomXLayers];
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *shapeLayer, NSUInteger index, BOOL *stop) {
        
        if ([topLayers containsObject:@(index)])
        {
            if (!self.topXFlipView)
            {
                CGPathRef minXPath = (__bridge CGPathRef)(self.shapeLayerArray[4]);
                CGPathRef maxXPath = (__bridge CGPathRef)(self.shapeLayerArray[11]);
                
               // CGFloat minX = CGRectGetMinX(CGPathGetBoundingBox([self.shapeLayerArray[4] path]));
               // CGFloat maxX = CGRectGetMaxX(CGPathGetBoundingBox([self.shapeLayerArray[11] path]));
               // CGFloat minY = CGRectGetMinY(CGPathGetBoundingBox([self.shapeLayerArray[6] path]));
               // CGFloat maxY = CGRectGetMaxY(CGPathGetBoundingBox([self.shapeLayerArray[4] path]));
                
               // self.topXFlipView = [[UIView alloc] initWithFrame:CGRectMake(minX, minY, maxX - minX, maxY - minY)];
                self.topXFlipView.backgroundColor = [UIColor clearColor];
                
                [self addSubview:self.topXFlipView];
            }
            
            if (![shapeLayer.superlayer isEqual:self.topXFlipView])
            {
                shapeLayer.position = CGPointMake(shapeLayer.position.x, CGRectGetMidY(CGPathGetPathBoundingBox(shapeLayer.path)) - self.topXFlipView.top);
                
                [self.topXFlipView.layer addSublayer:shapeLayer];
            }
        }
        else if ([bottomLayers containsObject:@(index)])
        {
            if (!self.bottomXFlipView)
            {
               // CGFloat minX = CGRectGetMinX(CGPathGetPathBoundingBox([self.shapeLayerArray[20] path]));
               // CGFloat maxX = CGRectGetMaxX(CGPathGetPathBoundingBox([self.shapeLayerArray[13] path]));
               // CGFloat minY = CGRectGetMinY(CGPathGetPathBoundingBox([self.shapeLayerArray[20] path]));
               // CGFloat maxY = CGRectGetMaxY(CGPathGetPathBoundingBox([self.shapeLayerArray[18] path]));
                
               // self.bottomXFlipView = [[UIView alloc] initWithFrame:CGRectMake(minX, minY, maxX - minX, maxY - minY)];
                self.bottomXFlipView.backgroundColor = [UIColor clearColor];
                
                [self addSubview:self.bottomXFlipView];
            }
            
            if (![shapeLayer.superlayer isEqual:self.bottomXFlipView])
            {
                shapeLayer.position = CGPointMake(shapeLayer.position.x, CGRectGetMidY(CGPathGetPathBoundingBox(shapeLayer.path)) - self.bottomXFlipView.top);
                [self.bottomXFlipView.layer addSublayer:shapeLayer];
            }
        }
    }];
    
    if (animated)
    {
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DMakeRotation(M_PI * percentage, 1, 0, 0);
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation.toValue = [NSValue valueWithCATransform3D:transform];
        animation.duration = kXDuration;
        
        [self applyBasicAnimation:animation
                          toLayer:self.topXFlipView.layer
              withCompletionBlock:^{
                  
              }];
        
        [self applyBasicAnimation:animation
                          toLayer:self.bottomXFlipView.layer
              withCompletionBlock:^{
                  
              }];
    }
    else
    {
        self.topXFlipView.layer.transform = CATransform3DMakeRotation(M_PI * percentage, 1, 0, 0);
        self.bottomXFlipView.layer.transform = CATransform3DMakeRotation(M_PI * percentage, 1, 0, 0);
    }
    
    [CATransaction commit];
}

- (void)transitionMiddleXLayersWithPercentage:(CGFloat)percentage
                                     animated:(BOOL)animated
{
    // Fix get get the middle layers to line up right.
    percentage = percentage / 1.02;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if (animated)
    {
        CATransform3D transform3 = CATransform3DIdentity;
        transform3 = CATransform3DMakeTranslation(11.5 * percentage, 0, 0);
        
        CABasicAnimation *animation3 = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation3.toValue = [NSValue valueWithCATransform3D:transform3];
        animation3.duration = kXDuration;
        
        [self applyBasicAnimation:animation3
                          toLayer:self.shapeLayerArray[3]
              withCompletionBlock:^{
                  
              }];
        
        
        CATransform3D transform12 = CATransform3DIdentity;
        transform12 = CATransform3DMakeTranslation(-11.5 * percentage, 0, 0);
        
        CABasicAnimation *animation12 = [CABasicAnimation animationWithKeyPath:@"transform"];
        animation12.toValue = [NSValue valueWithCATransform3D:transform12];
        animation12.duration = kXDuration;
        
        [self applyBasicAnimation:animation12
                          toLayer:self.shapeLayerArray[12]
              withCompletionBlock:^{
                  
              }];
    }
    else
    {
        CAShapeLayer *layer3 = self.shapeLayerArray[3];
        layer3.transform = CATransform3DMakeTranslation(11.5 * percentage, 0, 0);
        
        CAShapeLayer *layer12 = self.shapeLayerArray[12];
        layer12.transform = CATransform3DMakeTranslation(-11.5 * percentage, 0, 0);
    }
    
    [CATransaction commit];
}

#pragma mark - Sun Methods

- (NSArray *)sunLayers
{
    return @[@3, @6, @9, @12, @15, @18];
}

- (NSArray *)sunLayersHidden
{
    return @[@0, @1, @2, @4, @5, @7, @8, @10, @11, @13, @14, @16, @17, @19, @20];
}

- (CALayer *)sunCircleLayer
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 20, 20)] CGPath];
    circle.fillColor = [[UIColor whiteColor] CGColor];
    
    return circle;
}

- (void)transitionToSunWithPercentage:(CGFloat)percentage
                             animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    __block CGFloat percent = percentage;
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *shapeLayer, NSUInteger index, BOOL *stop) {
        
        if ([[self sunLayersHidden] containsObject:@(index)])
        {
            [self transitionFadeWithLayers:@[shapeLayer]
                            withPercentage:percent
                                  animated:animated];
        }
        // The angle is from the center of the CUBE to the center of the shapeLayer. Once we get the angle we need to adjust it so we can update the shapeLayers origin.
        else if ([[self sunLayers] containsObject:@(index)])
        {
            return; //
            
            CGFloat length = 10.0f * percent;
            
            CGRect pathRect = CGPathGetPathBoundingBox(shapeLayer.path);
            CGPoint shapePoint = CGRectGetCenter(pathRect);
            
            CGFloat angle = [self angleBetweenPoint:self.center//[self convertPoint:self.center fromView:nil]
                                           andPoint:shapePoint];
            
            double endX = cos(angle) * length;
            double endY = sin(angle) * length;
            
            if (animated)
            {
                CATransform3D transform = CATransform3DIdentity;
                transform = CATransform3DMakeTranslation(endX, endY, 0.0);
                
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
                animation.toValue = [NSValue valueWithCATransform3D:transform];
                animation.duration = kSunDuration;
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                
                [self applyBasicAnimation:animation
                                  toLayer:shapeLayer
                      withCompletionBlock:^{ }];
            }
            else
            {
                shapeLayer.transform = CATransform3DMakeTranslation(endX, endY, 0.0);
            }
        }
        
    }];
    
    [CATransaction commit];
}

#pragma mark - Fading

- (void)transitionFadeWithIndexes:(NSArray *)indexes
                   withPercentage:(CGFloat)percentage
                         animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    percentage = 1.0f - percentage;
    
    for (NSUInteger index = 0; index < indexes.count; index++)
    {
        NSUInteger shapeIndex = [indexes[index] integerValue];
        
        CAShapeLayer *layer = self.shapeLayerArray[shapeIndex];
        
        if (animated)
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.toValue = @(percentage);
            animation.duration = kDefaultDuration;
            
            [self applyBasicAnimation:animation
                              toLayer:layer
                  withCompletionBlock:^{ }];
        }
        else
        {
            layer.transform = CATransform3DMakeScale(percentage, percentage, 1.0);
        }
    }
    
    [CATransaction commit];
}

- (void)transitionFadeWithLayers:(NSArray *)layers
                  withPercentage:(CGFloat)percentage
                        animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    percentage = 1.0f - percentage;
    
    [layers enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop) {
        
        if (animated)
        {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.toValue = @(percentage);
            animation.duration = kXDuration;
            
            [self applyBasicAnimation:animation
                              toLayer:layer
                  withCompletionBlock:^{ }];
        }
        else
        {
            layer.opacity = percentage;
        }
        
    }];
    
    [CATransaction commit];
}

#pragma mark - Scaling

- (void)transitionScaleWithPercentage:(CGFloat)percentage
                             animated:(BOOL)animated
{
    [self transitionScaleWithLayers:self.shapeLayerArray
                     withPercentage:percentage
                           animated:animated];
}

- (void)transitionScaleWithIndexes:(NSArray *)indexes
                    withPercentage:(CGFloat)percentage
                          animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    percentage = 1.0f - percentage;
    
    for (NSUInteger index = 0; index < indexes.count; index++)
    {
        NSUInteger shapeIndex = [indexes[index] integerValue];
        
        CAShapeLayer *layer = self.shapeLayerArray[shapeIndex];
        
        if (animated)
        {
            CATransform3D transform = CATransform3DIdentity;
            transform = CATransform3DMakeScale(percentage, percentage, 1.0);
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
            animation.toValue = [NSValue valueWithCATransform3D:transform];
            animation.duration = kColorDuration;
            
            [self applyBasicAnimation:animation
                              toLayer:layer
                  withCompletionBlock:^{ }];
        }
        else
        {
            layer.transform = CATransform3DMakeScale(percentage, percentage, 1.0);
        }
    }
    
    [CATransaction commit];
}

- (void)transitionScaleWithLayers:(NSArray *)layers
                   withPercentage:(CGFloat)percentage
                         animated:(BOOL)animated
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    percentage = 1.0f - percentage;
    
    [layers enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop) {
        
        if (animated)
        {
            CATransform3D transform = CATransform3DIdentity;
            transform = CATransform3DMakeScale(percentage, percentage, 1.0);
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
            animation.toValue = [NSValue valueWithCATransform3D:transform];
            animation.duration = kColorDuration;
            
            [self applyBasicAnimation:animation
                              toLayer:layer
                  withCompletionBlock:^{ }];
        }
        else
        {
            layer.transform = CATransform3DMakeScale(percentage, percentage, 1.0);
        }
        
    }];
    
    [CATransaction commit];
}

#pragma mark - Flickering

- (void)startGlowingLayer:(CAShapeLayer *)layer
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue = [NSNumber numberWithFloat:0.0];
    animation.toValue = [NSNumber numberWithFloat:5.0];
    animation.duration = 1.3;
    [layer addAnimation:animation forKey:@"shadowOpacity"];
    
    layer.shadowRadius = 5.0;
}

- (void)stopGlowingLayer:(CAShapeLayer *)layer
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue = [NSNumber numberWithFloat:5.0];
    animation.toValue = [NSNumber numberWithFloat:0.0];
    animation.duration = 1.3;
    [layer addAnimation:animation forKey:@"shadowOpacity"];
    
    layer.shadowRadius = 0.0;
}

- (void)startFlickering
{
    if (self.isFlickering) return;
    
    self.flickering = YES;
    
    if (!self.flickeringLayerIndexes)
    {
        self.flickeringLayerIndexes = [NSMutableArray array];
        
        [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop) {
            if (index != 0 && index != 1 && index != 2)
            {
                [self.flickeringLayerIndexes addObject:@(index)];
                
                [self startGlowingLayer:layer];
            }
        }];
    }
    
    if (!self.displayLink)
    {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fireRandomNumber)];
        self.displayLink.frameInterval = 3;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopFlickering
{
    if (!self.isFlickering) return;
    
    self.flickering = NO;
    
    if (self.displayLink)
    {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    if (self.flickeringLayerIndexes)
    {
        self.flickeringLayerIndexes = nil;
    }
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop) {
        if (index != 0 && index != 1 && index != 2)
        {
            [layer removeAllAnimations];
            
            [self stopGlowingLayer:layer];
        }
    }];
}

// Called by the display link
- (void)fireRandomNumber
{
    if (self.flickeringLayerIndexes.count > 0)
    {
        NSNumber *randomNumber = self.flickeringLayerIndexes[arc4random_uniform((int32_t)self.flickeringLayerIndexes.count)];
        
        [self fireFlicker:randomNumber.integerValue];
    }
}

- (void)fireFlicker:(NSUInteger)index
{
    [self.flickeringLayerIndexes removeObject:@(index)];
    
    CAShapeLayer *layer = self.shapeLayerArray[index];
    
    [self flickerLayer:layer
               atIndex:index];
}

- (void)flickerLayer:(CAShapeLayer *)layer
             atIndex:(NSUInteger)index
{
    UIColor *baseColor = [UIColor colorWithCGColor:layer.fillColor];
    
    CGFloat hue, saturation, brightness, alpha;
    [baseColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    if (brightness < .1)
    {
        hue = drand48();
    }
    
    UIColor *minColor = [UIColor colorWithHue:hue
                                   saturation:0.5
                                   brightness:drand48()
                                        alpha:drand48()];
    
    UIColor *maxColor = [UIColor colorWithHue:hue
                                   saturation:1.0
                                   brightness:1.0
                                        alpha:1.0];
    
    CGFloat duration = 0.5;
    CGFloat halfDuration = duration / 2;
    CGFloat quaterDuration = halfDuration / 2;
    
    CAKeyframeAnimation *colorsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"fillColor"];
    colorsAnimation.values = @[(id)minColor.CGColor, (id)maxColor.CGColor, (id)baseColor.CGColor];
    colorsAnimation.keyTimes = @[[NSNumber numberWithFloat:quaterDuration], [NSNumber numberWithFloat:halfDuration], [NSNumber numberWithFloat:quaterDuration]];
    colorsAnimation.calculationMode = kCAAnimationPaced;
    colorsAnimation.removedOnCompletion = NO;
    colorsAnimation.fillMode = kCAFillModeForwards;
    colorsAnimation.duration = duration;
    colorsAnimation.autoreverses = YES;
    colorsAnimation.repeatCount = HUGE_VAL;
    
    [layer addAnimation:colorsAnimation forKey:@"fillColor"];
    
    CAKeyframeAnimation *shadow = [CAKeyframeAnimation animationWithKeyPath:@"shadowColor"];
    shadow.values = @[(id)minColor.CGColor, (id)maxColor.CGColor, (id)baseColor.CGColor];
    shadow.keyTimes = @[[NSNumber numberWithFloat:quaterDuration], [NSNumber numberWithFloat:halfDuration], [NSNumber numberWithFloat:quaterDuration]];
    shadow.calculationMode = kCAAnimationPaced;
    shadow.removedOnCompletion = NO;
    shadow.fillMode = kCAFillModeForwards;
    shadow.duration = duration;
    shadow.autoreverses = YES;
    shadow.repeatCount = HUGE_VAL;
    
    [layer addAnimation:shadow forKey:@"shadowColor"];
}

#pragma mark - Arrow Methods

- (NSArray *)arrowLayersHidden
{
    return @[@0, @1, @2, @3, @12];
}

- (NSArray *)arrowLayersLeft
{
    return @[@17, @18, @19, @20];
}

- (NSArray *)arrowLayersRight
{
    return @[@13, @14, @15, @16];
}

- (void)transitionArrowWithPercentage:(CGFloat)percentage
                        inOrientation:(TNKCubeArrowOrientation)orientation
{
    CGFloat maxAngle = 2.0;
    CGFloat angleIncrementValue = maxAngle * percentage;
    
    [self.shapeLayerArray enumerateObjectsUsingBlock:^(CAShapeLayer *layer, NSUInteger index, BOOL *stop) {
        
        if ([[self arrowLayersRight] containsObject:@(index)])
        {
            layer.transform = CATransform3DMakeRotation(angleIncrementValue, 0, 0, 1.0);
        }
        else if ([[self arrowLayersLeft] containsObject:@(index)])
        {
            layer.transform = CATransform3DMakeRotation(-angleIncrementValue, 0, 0, 1.0);
        }
        else if ([[self arrowLayersHidden] containsObject:@(index)])
        {
            layer.opacity = 1.0 - percentage;
        }
        
        // Get the original color of the triangle
        /*
         UIColor *triangleColor = [self colorForTriangleAtIndex:index];
         
         CGFloat hue, saturation, brightness, alpha;
         [triangleColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
         
         // Get the current app color
         UIColor *appColor = AppDelegate.appColor;
         CGFloat appColorHue, appColorSaturation, appColorBrightness, appColorAlpha;
         
         [appColor getHue:&appColorHue saturation:&appColorSaturation brightness:&appColorBrightness alpha:&appColorAlpha];
         
         
         CGFloat hueChange = fabsf(hue - appColorHue);
         CGFloat saturationChange = fabsf(saturation - appColorSaturation);
         CGFloat brightnessChange = fabsf(brightness - appColorBrightness);
         CGFloat alphaChange = fabsf(alpha - appColorAlpha);
         
         
         CGFloat hueIncrementValue = hueChange * percentage;
         CGFloat saturationIncrementValue = saturationChange * percentage;
         CGFloat brightnessIncrementValue = brightnessChange * percentage;
         CGFloat alphaIncrementValue = alphaChange * percentage;
         
         
         layer.fillColor = [UIColor colorWithHue:hue - hueIncrementValue
         saturation:saturation - saturationIncrementValue
         brightness:brightness - brightnessIncrementValue
         alpha:alpha - alphaIncrementValue].CGColor;
         //*/
    }];
}

#pragma mark - Helpers

- (CGSize)sizeForCurrentScale
{
    return [self sizeForScale:kCubeScale];
}

- (CGSize)sizeForScale:(CGFloat)scale
{
    CGFloat width = self.width * scale;
    CGFloat height = self.height * scale;
    
    return CGSizeMake(width, height);
}

- (UIColor *)colorForTriangleAtIndex:(NSUInteger)index
{
    switch (index)
    {
        case 0:
            return [UIColor silverColor];
            break;
        case 1:
            return [UIColor concreteColor];
            break;
        case 2:
            return [UIColor asbestosColor];
            break;
        case 3:
        case 12:
            return [UIColor amethystColor];
            break;
        case 4:
        case 13:
            return [UIColor wisteriaColor];
            break;
        case 5:
        case 14:
            return [UIColor belizeHoleColor];
            break;
        case 6:
        case 15:
            return [UIColor greenSeaColor];
            break;
        case 7:
        case 16:
            return [UIColor nephritisColor];
            break;
        case 8:
        case 17:
            return [UIColor emerlandColor];
            break;
        case 9:
        case 18:
            return [UIColor tangerineColor];
            break;
        case 10:
        case 19:
            return [UIColor pumpkinColor];
            break;
        case 11:
        case 20:
            return [UIColor pomegranateColor];
            break;
        default:
            return [UIColor chatFeedGreen];
            break;
    }
}

#pragma mark - Paths / Shapes

- (NSMutableArray *)shapeLayerArray
{
    if (!_shapeLayerArray)
    {
        _shapeLayerArray = [NSMutableArray array];
        
        [[self bezierPaths] enumerateObjectsUsingBlock:^(UIBezierPath *path, NSUInteger index, BOOL *stop)
         {
             CAShapeLayer *layer = [CAShapeLayer new];
             
             layer.path = path.CGPath;
             layer.fillColor = [self colorForTriangleAtIndex:index].CGColor;
             layer.opacity = 1.0;
             
             layer.bounds = CGPathGetPathBoundingBox(path.CGPath);
             
             layer.anchorPoint = CGPointMake(0.5, 0.5);
             
             layer.position = CGRectGetCenter(CGPathGetBoundingBox(layer.path));
             
             // Setup shadow (Glow) on all the triangles
             if (index != 0 && index != 1 && index != 2)
             {
                 layer.shadowColor = layer.fillColor;
                 layer.shadowOffset = CGSizeMake(0, 0);
                 layer.shadowRadius = 5.0;
                 layer.shadowOpacity = 0.0f;
                 layer.shadowPath = path.CGPath;
             }
             
             [_shapeLayerArray addObject:layer];
         }];
    }
    
    return _shapeLayerArray;
}

- (void)scaleBezierPath:(UIBezierPath *)bezierPath
{
    CGPoint beforePoint = bezierPath.currentPoint;
    
    CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
    
    [bezierPath applyTransform:scale];
    
    CGPoint afterPoint = bezierPath.currentPoint;
    
    CGAffineTransform translate = CGAffineTransformMakeTranslation(beforePoint.x - afterPoint.x - 2, beforePoint.y - afterPoint.y);
    
    [bezierPath applyTransform:translate];
}

- (NSArray *)bezierPaths
{
    NSMutableArray *bezierArray = [NSMutableArray array];
    
    //// Square 0 Drawing
    UIBezierPath *graphic0Path = [UIBezierPath bezierPath];
    [graphic0Path moveToPoint:CGPointMake(11.39, 18.47)];
    [graphic0Path addLineToPoint:CGPointMake(22, 12.39)];
    [graphic0Path addLineToPoint:CGPointMake(32.61, 18.47)];
    [graphic0Path addLineToPoint:CGPointMake(22, 24.55)];
    [graphic0Path addLineToPoint:CGPointMake(11.39, 18.47)];
    [graphic0Path closePath];
    
    //    [self scaleBezierPath:graphic0Path];
    
    
    [bezierArray addObject:graphic0Path];
    
    
    //// Square 1 Drawing
    UIBezierPath *graphic1Path = [UIBezierPath bezierPath];
    [graphic1Path moveToPoint:CGPointMake(22.39, 25.22)];
    [graphic1Path addLineToPoint:CGPointMake(33, 19.14)];
    [graphic1Path addLineToPoint:CGPointMake(33, 31.37)];
    [graphic1Path addLineToPoint:CGPointMake(22.39, 37.39)];
    [graphic1Path addLineToPoint:CGPointMake(22.39, 25.22)];
    [graphic1Path closePath];
    
    //    [self scaleBezierPath:graphic1Path];
    
    [bezierArray addObject:graphic1Path];
    
    //// Square 2 Drawing
    UIBezierPath *graphic2Path = [UIBezierPath bezierPath];
    [graphic2Path moveToPoint:CGPointMake(21.61, 37.39)];
    [graphic2Path addLineToPoint:CGPointMake(21.61, 25.22)];
    [graphic2Path addLineToPoint:CGPointMake(11, 19.14)];
    [graphic2Path addLineToPoint:CGPointMake(11, 31.3)];
    [graphic2Path addLineToPoint:CGPointMake(21.61, 37.39)];
    [graphic2Path closePath];
    
    [bezierArray addObject:graphic2Path];
    
    //// Triangle 3 Drawing
    UIBezierPath *graphic3Path = [UIBezierPath bezierPath];
    [graphic3Path moveToPoint:CGPointMake(0, 25)];
    [graphic3Path addLineToPoint:CGPointMake(10.22, 19.14)];
    [graphic3Path addLineToPoint:CGPointMake(10.22, 30.86)];
    [graphic3Path addLineToPoint:CGPointMake(0, 25)];
    [graphic3Path closePath];
    
    [bezierArray addObject:graphic3Path];
    
    //// Triangle 4 Drawing
    UIBezierPath *graphic4Path = [UIBezierPath bezierPath];
    [graphic4Path moveToPoint:CGPointMake(0, 12.84)];
    [graphic4Path addLineToPoint:CGPointMake(0, 24.1)];
    [graphic4Path addLineToPoint:CGPointMake(9.83, 18.47)];
    [graphic4Path addLineToPoint:CGPointMake(0, 12.84)];
    [graphic4Path closePath];
    
    [bezierArray addObject:graphic4Path];
    
    //// Triangle 5 Drawing
    UIBezierPath *graphic5Path = [UIBezierPath bezierPath];
    [graphic5Path moveToPoint:CGPointMake(10.22, 17.8)];
    [graphic5Path addLineToPoint:CGPointMake(10.22, 6.53)];
    [graphic5Path addLineToPoint:CGPointMake(0.39, 12.16)];
    [graphic5Path addLineToPoint:CGPointMake(10.22, 17.8)];
    [graphic5Path closePath];
    
    [bezierArray addObject:graphic5Path];
    
    //// Triangle 6 Drawing
    UIBezierPath *graphic6Path = [UIBezierPath bezierPath];
    [graphic6Path moveToPoint:CGPointMake(11, 6.08)];
    [graphic6Path addLineToPoint:CGPointMake(11, 17.8)];
    [graphic6Path addLineToPoint:CGPointMake(21.22, 11.94)];
    [graphic6Path addLineToPoint:CGPointMake(11, 6.08)];
    [graphic6Path closePath];
    
    [bezierArray addObject:graphic6Path];
    
    //// Triangle 7 Drawing
    UIBezierPath *graphic7Path = [UIBezierPath bezierPath];
    [graphic7Path moveToPoint:CGPointMake(21.61, 11.27)];
    self.arrowPivotPointTL = CGPointMake(21.61, 0);
    [graphic7Path addLineToPoint:self.arrowPivotPointTL];
    [graphic7Path addLineToPoint:CGPointMake(11.78, 5.63)];
    [graphic7Path addLineToPoint:CGPointMake(21.61, 11.27)];
    [graphic7Path closePath];
    
    [bezierArray addObject:graphic7Path];
    
    //// Triangle 8 Drawing
    UIBezierPath *graphic8Path = [UIBezierPath bezierPath];
    [graphic8Path moveToPoint:CGPointMake(32.22, 5.63)];
    [graphic8Path addLineToPoint:CGPointMake(22.39, 11.27)];
    self.arrowPivotPointTR = CGPointMake(22.39, 0);
    [graphic8Path addLineToPoint:self.arrowPivotPointTR];
    [graphic8Path addLineToPoint:CGPointMake(32.22, 5.63)];
    [graphic8Path closePath];
    
    [bezierArray addObject:graphic8Path];
    
    //// Triangle 9 Drawing
    UIBezierPath *graphic9Path = [UIBezierPath bezierPath];
    [graphic9Path moveToPoint:CGPointMake(33, 6.08)];
    [graphic9Path addLineToPoint:CGPointMake(33, 17.8)];
    [graphic9Path addLineToPoint:CGPointMake(22.79, 11.94)];
    [graphic9Path addLineToPoint:CGPointMake(33, 6.08)];
    [graphic9Path closePath];
    
    [bezierArray addObject:graphic9Path];
    
    //// Triangle 10 Drawing
    UIBezierPath *graphic10Path = [UIBezierPath bezierPath];
    [graphic10Path moveToPoint:CGPointMake(33.78, 17.8)];
    [graphic10Path addLineToPoint:CGPointMake(33.78, 6.53)];
    [graphic10Path addLineToPoint:CGPointMake(43.61, 12.16)];
    [graphic10Path addLineToPoint:CGPointMake(33.78, 17.8)];
    [graphic10Path closePath];
    
    [bezierArray addObject:graphic10Path];
    
    //// Triangle 11 Drawing
    UIBezierPath *graphic11Path = [UIBezierPath bezierPath];
    [graphic11Path moveToPoint:CGPointMake(44, 12.84)];
    [graphic11Path addLineToPoint:CGPointMake(44, 24.1)];
    [graphic11Path addLineToPoint:CGPointMake(34.18, 18.47)];
    [graphic11Path addLineToPoint:CGPointMake(44, 12.84)];
    [graphic11Path closePath];
    
    [bezierArray addObject:graphic11Path];
    
    //// Triangle 12 Drawing
    UIBezierPath *graphic12Path = [UIBezierPath bezierPath];
    [graphic12Path moveToPoint:CGPointMake(44, 25)];
    [graphic12Path addLineToPoint:CGPointMake(33.78, 19.14)];
    [graphic12Path addLineToPoint:CGPointMake(33.78, 30.86)];
    [graphic12Path addLineToPoint:CGPointMake(44, 25)];
    [graphic12Path closePath];
    
    [bezierArray addObject:graphic12Path];
    
    //// Triangle 13 Drawing
    UIBezierPath *graphic13Path = [UIBezierPath bezierPath];
    [graphic13Path moveToPoint:CGPointMake(44, 25.9)];
    [graphic13Path addLineToPoint:CGPointMake(34.18, 31.53)];
    [graphic13Path addLineToPoint:CGPointMake(44, 37.16)];
    [graphic13Path addLineToPoint:CGPointMake(44, 25.9)];
    [graphic13Path closePath];
    
    [bezierArray addObject:graphic13Path];
    
    //// Triangle 14 Drawing    8
    UIBezierPath *graphic14Path = [UIBezierPath bezierPath];
    [graphic14Path moveToPoint:CGPointMake(43.61, 37.84)];
    [graphic14Path addLineToPoint:CGPointMake(33.78, 43.47)];
    [graphic14Path addLineToPoint:CGPointMake(33.78, 32.2)];
    [graphic14Path addLineToPoint:CGPointMake(43.61, 37.84)];
    [graphic14Path closePath];
    
    [bezierArray addObject:graphic14Path];
    
    //// Triangle 15 Drawing
    UIBezierPath *graphic15Path = [UIBezierPath bezierPath];
    [graphic15Path moveToPoint:CGPointMake(33, 32.2)];
    [graphic15Path addLineToPoint:CGPointMake(33, 43.92)];
    [graphic15Path addLineToPoint:CGPointMake(22.79, 38.06)];
    [graphic15Path addLineToPoint:CGPointMake(33, 32.2)];
    [graphic15Path closePath];
    
    [bezierArray addObject:graphic15Path];
    
    //// Triangle 16 Drawing
    UIBezierPath *graphic16Path = [UIBezierPath bezierPath];
    [graphic16Path moveToPoint:CGPointMake(32.22, 44.37)];
    self.arrowPivotPointBR = CGPointMake(22.39, 50);
    [graphic16Path addLineToPoint:self.arrowPivotPointBR];
    [graphic16Path addLineToPoint:CGPointMake(22.39, 38.73)];
    [graphic16Path addLineToPoint:CGPointMake(32.22, 44.37)];
    [graphic16Path closePath];
    
    [bezierArray addObject:graphic16Path];
    
    //// Triangle 17 Drawing
    UIBezierPath *graphic17Path = [UIBezierPath bezierPath];
    [graphic17Path moveToPoint:CGPointMake(11.78, 44.37)];
    self.arrowPivotPointBL = CGPointMake(21.61, 50);
    [graphic17Path addLineToPoint:self.arrowPivotPointBL];
    [graphic17Path addLineToPoint:CGPointMake(21.61, 38.74)];
    [graphic17Path addLineToPoint:CGPointMake(11.78, 44.37)];
    [graphic17Path closePath];
    
    [bezierArray addObject:graphic17Path];
    
    //// Triangle 18 Drawing
    UIBezierPath *graphic18Path = [UIBezierPath bezierPath];
    [graphic18Path moveToPoint:CGPointMake(11, 32.2)];
    [graphic18Path addLineToPoint:CGPointMake(11, 43.92)];
    [graphic18Path addLineToPoint:CGPointMake(21.22, 38.06)];
    [graphic18Path addLineToPoint:CGPointMake(11, 32.2)];
    [graphic18Path closePath];
    
    [bezierArray addObject:graphic18Path];
    
    //// Triangle 19 Drawing
    UIBezierPath *graphic19Path = [UIBezierPath bezierPath];
    [graphic19Path moveToPoint:CGPointMake(10.22, 32.2)];
    [graphic19Path addLineToPoint:CGPointMake(10.22, 43.47)];
    [graphic19Path addLineToPoint:CGPointMake(0.39, 37.84)];
    [graphic19Path addLineToPoint:CGPointMake(10.22, 32.2)];
    [graphic19Path closePath];
    
    [bezierArray addObject:graphic19Path];
    
    //// Triangle 20 Drawing
    UIBezierPath *graphic20Path = [UIBezierPath bezierPath];
    [graphic20Path moveToPoint:CGPointMake(0, 25.9)];
    [graphic20Path addLineToPoint:CGPointMake(9.83, 31.53)];
    [graphic20Path addLineToPoint:CGPointMake(0, 37.16)];
    [graphic20Path addLineToPoint:CGPointMake(0, 25.9)];
    [graphic20Path closePath];
    
    [bezierArray addObject:graphic20Path];
    
    return [bezierArray copy];
}

#pragma mark - Images

- (NSArray *)cubeImageViews
{
    NSMutableArray *imageViews = [@[] mutableCopy];
    NSArray *cubeImages = [self cubeImages];
    NSArray *cubeFrames = [self cubeImageFrames];
    
    for (NSUInteger index = 0; index < cubeImages.count; index++)
    {
        [imageViews addObject:[self imageViewWithImage:cubeImages[index]
                                              andFrame:[cubeFrames[index] CGRectValue]]];
    }
    
    return imageViews;
}

- (UIImageView *)imageViewWithImage:(UIImage *)image
                           andFrame:(CGRect)frame
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    imageView.frame = frame;
    
    return imageView;
}

- (NSArray *)cubeImages
{
    return @[[UIImage imageNamed: @"image0Image"],
             [UIImage imageNamed: @"image1Image"],
             [UIImage imageNamed: @"image2Image"],
             [UIImage imageNamed: @"image3Image"],
             [UIImage imageNamed: @"image4Image"],
             [UIImage imageNamed: @"image5Image"],
             [UIImage imageNamed: @"image6Image"],
             [UIImage imageNamed: @"image7Image"],
             [UIImage imageNamed: @"image8Image"],
             [UIImage imageNamed: @"image9Image"],
             [UIImage imageNamed: @"image10Image"],
             [UIImage imageNamed: @"image11Image"],
             [UIImage imageNamed: @"image12Image"],
             [UIImage imageNamed: @"image13Image"],
             [UIImage imageNamed: @"image14Image"],
             [UIImage imageNamed: @"image15Image"],
             [UIImage imageNamed: @"image16Image"],
             [UIImage imageNamed: @"image17Image"],
             [UIImage imageNamed: @"image18Image"],
             [UIImage imageNamed: @"image19Image"],
             [UIImage imageNamed: @"image20Image"]];
}


- (NSArray *)cubeImageFrames
{
    return @[[NSValue valueWithCGRect:CGRectMake(11, 12, 22, 14)],
             [NSValue valueWithCGRect:CGRectMake(22, 19, 11, 20)],
             [NSValue valueWithCGRect:CGRectMake(11, 19, 11, 20)],
             [NSValue valueWithCGRect:CGRectMake(0, 19, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(0, 12, 10, 13)],
             [NSValue valueWithCGRect:CGRectMake(0, 6, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(11, 6, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(11, 0, 11, 12)],
             [NSValue valueWithCGRect:CGRectMake(22, 0, 11, 12)],
             [NSValue valueWithCGRect:CGRectMake(22, 6, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(33, 6, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(34, 12, 10, 13)],
             [NSValue valueWithCGRect:CGRectMake(33, 19, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(34, 26, 10, 13)],
             [NSValue valueWithCGRect:CGRectMake(33, 32, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(22, 32, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(22, 39, 11, 12)],
             [NSValue valueWithCGRect:CGRectMake(11, 39, 11, 12)],
             [NSValue valueWithCGRect:CGRectMake(11, 32, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(0, 32, 11, 13)],
             [NSValue valueWithCGRect:CGRectMake(0, 26, 10, 13)]];
}

#pragma mark - Touch Overrides

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Let the touch go through to the superview
    return NO;
}

@end
