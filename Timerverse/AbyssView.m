//
//  AbyssView.m
//  AbyssView
//
//  Created by Larry Ryan on 10/26/13.
//  Copyright (c) 2013 Thinkr LLC. All rights reserved.
//

#import "AbyssView.h"

@interface AbyssView ()

@property (nonatomic) CAEmitterLayer *emitterLayer;

@end

@implementation AbyssView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
    {
		self.backgroundColor = [UIColor blackColor];
        self.particleColor = [UIColor clearColor];
        self.type = AbyssParticleTypeTimer;
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
    {
		self.backgroundColor = [UIColor blackColor];
        self.particleColor = [UIColor clearColor];
        self.type = AbyssParticleTypeTimer;
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                         type:(AbyssParticleType)type
             andParticleColor:(UIColor *)color
{
    self = [super initWithFrame:frame];
	
	if (self)
    {
		self.backgroundColor = [UIColor blackColor];
        self.clipsToBounds = YES;
        
        self.particleColor = color;
        self.type = type;
	}
	
	return self;
}

+ (Class)layerClass
{
    // configure the UIView to have emitter layer
    return [CAEmitterLayer class];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self configureEmitterLayer];
}

#pragma mark - Properties

- (void)setParticleColor:(UIColor *)particleColor
{
    _particleColor = particleColor;
    
    [self updateEmitterCells];
}

- (void)setType:(AbyssParticleType)type
{
    _type = type;
    
    [self updateEmitterCells];
}

#pragma mark - Emitter

- (void)configureEmitterLayer
{
    if (!self.emitterLayer)
    {
        self.emitterLayer = (CAEmitterLayer *)self.layer;
    }
    
    self.emitterLayer.beginTime = CACurrentMediaTime();
	self.emitterLayer.name = @"emitterLayer";
	self.emitterLayer.emitterPosition = CGPointMake(self.halfWidth, -50.0f);
	self.emitterLayer.emitterZPosition = 0;
    
	self.emitterLayer.emitterSize = CGSizeMake(self.width, self.height + 50.0f);
	self.emitterLayer.emitterDepth = 0.00;
    
	self.emitterLayer.emitterShape = kCAEmitterLayerLine;
    
	self.emitterLayer.emitterMode = kCAEmitterLayerSurface;
    
	self.emitterLayer.renderMode = kCAEmitterLayerOldestLast;
    
	self.emitterLayer.seed = arc4random_uniform(4067248050);
    
    [self updateEmitterCells];
}

- (void)updateEmitterCells
{
    switch (self.type)
    {
        case AbyssParticleTypeAlarm:
        {
            self.emitterLayer.emitterCells = @[[self emitterCellAlarmWithColor:self.particleColor]];
        }
            break;
        case AbyssParticleTypeTimer:
        {
            self.emitterLayer.emitterCells = @[[self emitterCellTimerWithColor:self.particleColor]];
        }
            break;
        case AbyssParticleTypeAll:
        {
            self.emitterLayer.emitterCells = @[[self emitterCellAlarmWithColor:self.particleColor], [self emitterCellTimerWithColor:self.particleColor]];
        }
            break;
    }
}

- (CAEmitterCell *)emitterCellTimerWithColor:(UIColor *)color
{
	// Create the emitter Cell
	CAEmitterCell *emitterCell = [CAEmitterCell emitterCell];
	
	emitterCell.name = @"timer";
	emitterCell.enabled = YES;
    
	emitterCell.contents = (id)[UIImage imageNamed:@"circleParticle"].CGImage;
	emitterCell.contentsRect = CGRectMake(0.00, 0.00, 1.00, 1.00);
    
	emitterCell.magnificationFilter = kCAFilterLinear;
	emitterCell.minificationFilter = kCAFilterLinear;
	emitterCell.minificationFilterBias = 0.00;
    
	emitterCell.scale = 0.48;
	emitterCell.scaleRange = 0.00;
	emitterCell.scaleSpeed = 0.01;
    
	emitterCell.color = [self.particleColor CGColor];
	emitterCell.redRange = 0.00;
	emitterCell.greenRange = 0.00;
	emitterCell.blueRange = 0.00;
	emitterCell.alphaRange = 1.00;
    
	emitterCell.redSpeed = 0.00;
	emitterCell.greenSpeed = 0.00;
	emitterCell.blueSpeed = 0.00;
	emitterCell.alphaSpeed = 10.00;
    
	emitterCell.lifetime = 5.0;
	emitterCell.lifetimeRange = 0.00;
	emitterCell.birthRate = self.type == AbyssParticleTypeAll ? 5.0 : 10.0;
	emitterCell.velocity = 160.0;
	emitterCell.velocityRange = 126.00;
	emitterCell.xAcceleration = 0.00;
	emitterCell.yAcceleration = 0.00;
	emitterCell.zAcceleration = 0.00;
    
	// these values are in radians, in the UI they are in degrees
	emitterCell.spin = 0.000;
	emitterCell.spinRange = 0.000;
	emitterCell.emissionLatitude = 0.000;
	emitterCell.emissionLongitude = 3.142;
	emitterCell.emissionRange = 0.000;

    
    return emitterCell;
}

- (CAEmitterCell *)emitterCellAlarmWithColor:(UIColor *)color
{
	// Create the emitter Cell
	CAEmitterCell *emitterCell = [CAEmitterCell emitterCell];
	
	emitterCell.name = @"alarm";
	emitterCell.enabled = YES;
    
	emitterCell.contents = (id)[UIImage imageNamed:@"alarmParticle"].CGImage;
	emitterCell.contentsRect = CGRectMake(0.00, 0.00, 1.00, 1.00);
    
	emitterCell.magnificationFilter = kCAFilterLinear;
	emitterCell.minificationFilter = kCAFilterLinear;
	emitterCell.minificationFilterBias = 0.00;
    
	emitterCell.scale = 0.48;
	emitterCell.scaleRange = 0.00;
	emitterCell.scaleSpeed = 0.01;
    
	emitterCell.color = self.particleColor.CGColor;
	emitterCell.redRange = 0.00;
	emitterCell.greenRange = 0.00;
	emitterCell.blueRange = 0.00;
	emitterCell.alphaRange = 1.00;
    
	emitterCell.redSpeed = 0.00;
	emitterCell.greenSpeed = 0.00;
	emitterCell.blueSpeed = 0.00;
	emitterCell.alphaSpeed = 10.00;
    
	emitterCell.lifetime = 1.0;
	emitterCell.lifetimeRange = 0.00;
	emitterCell.birthRate = self.type == AbyssParticleTypeAll ? 5.0 : 10.0;
	emitterCell.velocity = 160.0;
	emitterCell.velocityRange = 126.00;
	emitterCell.xAcceleration = 0.00;
	emitterCell.yAcceleration = 0.00;
	emitterCell.zAcceleration = 0.00;
    
	// these values are in radians, in the UI they are in degrees
	emitterCell.spin = 0.000;
	emitterCell.spinRange = 0.000;
	emitterCell.emissionLatitude = 0.000;
	emitterCell.emissionLongitude = 3.142;
	emitterCell.emissionRange = 0.000;
    
    
    return emitterCell;
}

@end
