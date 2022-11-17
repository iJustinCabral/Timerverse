//
//  TMVSettingsButtonView.m
//  Timerverse
//
//  Created by Larry Ryan on 2/2/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVSettingsButtonView.h"

static CGFloat const kCubeScale = 0.75f;

@interface TMVSettingsButtonView ()

// This view is to allow the cube to expand but get clipped over the abyss view.
@property (nonatomic) TMVNonInteractiveView *clippingContainerView;

// If the cube is moved it will messup the expanding angle. So we need to stick it in a container view to move it around.
@property (nonatomic) TMVNonInteractiveView *containerView;

@property (nonatomic, readwrite) TNKCube *cube;
@property (nonatomic, getter = isAnimatingSun) BOOL animatingSun;
@property (nonatomic) UIImageView *trash;

@property (nonatomic, readwrite, getter = isDraggingOutsideBounds) BOOL draggingOutsideBounds;
@property (nonatomic, readwrite) BOOL canBeTouched;

//@property (nonatomic) UILabel *brightnessLabel;

@end

@implementation TMVSettingsButtonView

#pragma mark - Lifecycle

- (instancetype)initWithState:(TMVSettingsButtonViewState)state
{
    self = [super init];
    if (self)
    {
        self.frame = CGRectMake(0, 0, 54, 54);
        self.tintColor = AppContainer.atmosphere.elementColorBottom;
        self.clipsToBounds = NO;
        
        self.viewState = state;
        
        [self addSubview:self.clippingContainerView];
        
        [self configureCube];
        
//        if (!_brightnessLabel)
//        {
//            _brightnessLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 44, 32)];
//            _brightnessLabel.text = @"";
//            _brightnessLabel.textAlignment = NSTextAlignmentCenter;
//            _brightnessLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
//            _brightnessLabel.textColor = [UIColor whiteColor];
//            _brightnessLabel.bottom = self.cube.top;
//            _brightnessLabel.centerX = self.cube.centerX;
//            
//            [self.containerView addSubview:_brightnessLabel];
//        }
    }
    return self;
}

- (void)cancelTouch
{
    [self contractCube];
    self.draggingOutsideBounds = YES;
}

// Make a container view which will clips the bounds. We can't make the settingsbutton itself clip its subviews, since we can't have a huge hit rect. It is mostly for the cube expanding.
- (TMVNonInteractiveView *)clippingContainerView
{
    if (!_clippingContainerView)
    {
        _clippingContainerView = [[TMVNonInteractiveView alloc] initWithFrame:CGRectMake(0, 0, self.width * 2, self.height * 2)];
//        _clippingContainerView.clipsToBounds = YES;
        _clippingContainerView.bottom = self.bottom;
        _clippingContainerView.centerX = self.centerX;
    }
    
    return _clippingContainerView;
}

- (TMVNonInteractiveView *)containerView
{
    if (!_containerView)
    {
        _containerView = [[TMVNonInteractiveView alloc] initWithFrame:CGRectMake(0, 0, 44, 50)];
        [self addSubview:_containerView];
        _containerView.top = self.top;
        _containerView.centerX = self.centerX;
    }
    return _containerView;
}

- (BOOL)canBeTouched
{
    return self.cube.stateByPercentage == TNKCubeStateDefault;
}

#pragma mark - Touch Events

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if (!self.canBeTouched) return;
    
    self.draggingOutsideBounds = NO;
    
    if ([self.delegate respondsToSelector:@selector(didBeginTouchingSettingsButtonView:)])
    {
        [self.delegate didBeginTouchingSettingsButtonView:self];
    }
    
    [self expandCube];
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if (!self.canBeTouched && self.cube.stateByPercentage != TNKCubeStateExpansion) return;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self.superview];

    if (CGRectContainsPoint(self.frame, currentPosition))
    {
    }
    else
    {
        if (!self.isDraggingOutsideBounds)
        {
            self.draggingOutsideBounds = YES;
            [AppContainer setHUDUserInteraction:YES];
            
            [self contractCube];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(didEndTouchingSettingsButtonView:)])
    {
        [self.delegate didEndTouchingSettingsButtonView:self];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (!self.canBeTouched && self.cube.stateByPercentage != TNKCubeStateExpansion) return;
    
    self.draggingOutsideBounds = NO;
    
    [self contractCube];
}

#pragma mark -

- (void)updateColor:(UIColor *)color
      withAnimation:(BOOL)animation
{
    [self.cube changeToColor:color
                    animated:animation];
}

#pragma mark - Animation

- (void)showAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.6f
                              delay:0.0f
//             usingSpringWithDamping:0.55
//              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self showAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
        
    }
    else
    {
        self.centerY = self.center.y < self.superview.halfHeight ? self.halfHeight : self.superview.height - self.halfHeight;
    }
}

- (void)hideAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.6f
                              delay:0.0f
         //             usingSpringWithDamping:0.55
         //              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self hideAnimated:NO];
                         }
                         completion:^(BOOL finished) {}];
        
    }
    else
    {
        self.centerY = self.center.y < self.superview.halfHeight ? -self.halfHeight : self.superview.height + self.halfHeight;
    }
}
#pragma mark - Cube

- (void)configureCube
{
    if (!self.cube)
    {
        self.cube = [[TNKCube alloc] initWithType:TNKCubeTypeLayers
                                         andState:TNKCubeStateDefault];
        
        self.cube.transform = CGAffineTransformMakeScale(kCubeScale, kCubeScale);
        
        [self.cube changeToColor:AppContainer.atmosphere.state == TMVAtmosphereStateDay ? AppContainer.atmosphere.elementColorBottom : [UIColor whiteColor]
                        animated:NO];
        
        [self.containerView addSubview:self.cube];
    }
}

- (void)expandCube
{
    [self.cube transitionToState:TNKCubeStateExpansion
                  withPercentage:1.0f
                        animated:YES];
}

- (void)contractCube
{
    [self.cube transitionToState:TNKCubeStateExpansion
                  withPercentage:0.0f
                        animated:YES];
}

- (void)changeCubeToSun:(BOOL)changeToSun
               animated:(BOOL)animated
{
    [self.cube transitionToState:TNKCubeStateSun
                  withPercentage:changeToSun ? 1.0f : 0.0f
                        animated:animated];
    
    if (changeToSun)
    {
//        [self p_sunsetPercentage:1.0f - [UIScreen mainScreen].brightness
//                        animated:YES];
    }
    else
    {
        [self p_sunsetPercentage:0.0f
                        animated:YES];
    }
}

- (void)sunsetPercentage:(CGFloat)percentage
{
    [self p_sunsetPercentage:percentage
                    animated:NO];
}

- (void)p_sunsetPercentage:(CGFloat)percentage
                  animated:(BOOL)animated
{
    if (self.isAnimatingSun) return;
    
    if (animated)
    {
        self.animatingSun = YES;
        
        [UIView animateWithDuration:0.3f
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             CGFloat margin = 6.0f;
                             self.cube.y = (self.height * percentage) + margin;
        }
                         completion:^(BOOL finished) {
                         
                             self.animatingSun = NO;
                         
                         }];
    }
    else
    {
        CGFloat margin = 6.0f;
        CGFloat offset = 25.0f;
        
        self.cube.y = ((self.height - offset) * percentage) + margin;
        
//        self.brightnessLabel.bottom = self.cube.y;
//        self.brightnessLabel.text = [NSString stringWithFormat:@"%.f", (1.0f - percentage) * 100];
    }
}

#pragma mark - Cube Forwarding

- (void)updateCubeSharePercentage:(CGFloat)percentage
{
    [self.cube transitionToState:TNKCubeStateShare
                  withPercentage:percentage
                        animated:NO];
}

- (void)updateCubeArrowWithOrientation:(TNKCubeArrowOrientation)orientation
                          andPercenage:(CGFloat)percentage
{
    
}

- (void)changeCubeToX:(BOOL)changeToX
             animated:(BOOL)animated
{
    [self.cube transitionToState:TNKCubeStateX
                  withPercentage:changeToX ? 1.0f : 0.0f
                        animated:animated];
}

#pragma mark - Trash

- (void)configureTrash
{
    if (!self.trash)
    {
        self.trash = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"trash"]
                                                         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.trash.frame = CGRectMake(0, 0, 20.0f, 54);
        self.trash.center = CGPointMake(self.centerX, self.centerY);
        self.trash.layer.opacity = 0.0;
        self.trash.backgroundColor = [UIColor clearColor];
        self.trash.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.containerView addSubview:self.trash];
        [self.containerView sendSubviewToBack:self.trash];
    }
}

#pragma mark - Properties

- (void)setViewState:(TMVSettingsButtonViewState)state
{
    [self setViewState:state
              animated:NO];
}

- (void)setViewState:(TMVSettingsButtonViewState)state
            animated:(BOOL)animated
{
    if (_viewState == state) return;
    
    _viewState = state;
    
    if (animated)
    {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self updateToState:state];
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    }
    else
    {
        [self updateToState:state];
    }
}

- (void)updateToState:(TMVSettingsButtonViewState)state
{
    [self dropInView:state == TMVSettingsButtonViewStateCube ? self.cube : self.trash
      withPercentage:1.0];
    
    [self dropOutView:state == TMVSettingsButtonViewStateCube ? self.trash : self.cube
       withPercentage:1.0];
}

#pragma mark - Interactive Transitions

- (void)interactiveTransitionToState:(TMVSettingsButtonViewState)state
                      withPercentage:(CGFloat)percentage
{
    CGFloat swoopPercentage = percentage / 0.6f;
    CGFloat dropPercentage = percentage / 0.3f;
    
    if (swoopPercentage < 0.0f) swoopPercentage = 0.0f;
    if (swoopPercentage > 1.0f) swoopPercentage = 1.0f;
    if (dropPercentage < 0.0f) dropPercentage = 0.0f;
    if (dropPercentage > 1.0f) dropPercentage = 1.0f;
    
    [self dropInView:state == TMVSettingsButtonViewStateCube ? self.cube : self.trash
      withPercentage:swoopPercentage];
    
    [self dropOutView:state == TMVSettingsButtonViewStateCube ? self.trash : self.cube
       withPercentage:dropPercentage];
}

- (void)dropInView:(UIView *)view
    withPercentage:(CGFloat)percentage
{
    view.layer.opacity = percentage;
    view.y = self.height * (1.0f - percentage);
}

- (void)dropOutView:(UIView *)view
     withPercentage:(CGFloat)percentage
{
    view.layer.opacity = 1.0f - percentage;
    view.y = self.height * percentage;
}

- (void)swoopInView:(UIView *)view
     withPercentage:(CGFloat)percentage
{
    view.layer.opacity = percentage;
    
    CGFloat reversedPercentage = 1.0f - percentage;
    
    view.layer.anchorPoint = CGPointMake(0.5, 1.0);
    view.layer.position = CGPointMake(view.layer.position.x, 30);
    CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
    rotationAndPerspectiveTransform.m34 = 1.0 / -500;
    rotationAndPerspectiveTransform = CATransform3DRotate(view.layer.transform , (-90.0f * reversedPercentage) * M_PI / 180.0f, 1.0f, 0.0f, 0.0f);
    view.layer.transform = rotationAndPerspectiveTransform;
}

@end
