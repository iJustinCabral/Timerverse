//
//  SAMultisectorControl.m
//  CustomControl
//
//  Created by Snipter on 12/31/13.
//  Copyright (c) 2013 SmartAppStudio. All rights reserved.
//

#import "SATimerControl.h"
#import "TNKDisplayLink.h"

#define saCircleLineWidth 2.0
#define saMarkersLineWidth 2.0

#define IS_OS_LOWER_7    ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)

typedef struct{
    CGPoint circleCenter;
    CGFloat radius;
    
    double fullLine;
    double circleOffset;
    double circleLine;
    double circleEmpty;
    
    double circleOffsetAngle;
    double circleLineAngle;
    double circleEmptyAngle;
    
    CGPoint startMarkerCenter;
    CGPoint endMarkerCenter;
    
    CGFloat startMarkerRadius;
    CGFloat endMarkerRadius;
    
    CGFloat startMarkerFontSize;
    CGFloat endMarkerFontize;
    
    CGFloat startMarkerAlpha;
    CGFloat endMarkerAlpha;
    
} SASectorDrawingInformation;


@interface SATimerControl ()

@property (nonatomic, readwrite) NSMutableArray *sectorsArray;
@property (nonatomic) SATimerSector *trackingSector;
@property (nonatomic) SASectorDrawingInformation trackingSectorDrawInf;
@property (nonatomic) BOOL trackingSectorStartMarker;

@end


@implementation SATimerControl

#pragma mark - Lifecycle -

- (instancetype)init
{
    if (self = [super init])
    {
        [self setupDefaultConfigurations];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setupDefaultConfigurations];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupDefaultConfigurations];
    }
    return self;
}

- (void)setupDefaultConfigurations
{
    self.backgroundColor = [UIColor clearColor];
    
    _sectorsArray = [NSMutableArray new];
    _sectorsRadius = 45.0;
    _startAngle = toRadians(270);
    _minCircleMarkerRadius = 16.0;
    _maxCircleMarkerRadius = 16.0;
    _numbersAfterPoint = 0;
    
    //    self.multipleTouchEnabled = YES;
}

- (void)resetAnimated:(BOOL)animated
{
    if (animated)
    {
        [self.sectorsArray enumerateObjectsUsingBlock:^(SATimerSector *sector, NSUInteger index, BOOL *stop) {
            
            sector.animationStartValue = sector.endValue;
            
        }];
        
        [TNKDisplayLink animateWithDuration:0.5f
                                repeatCount:0
                      autoReversePercentage:NO
                              progressBlock:^(CGFloat progress, NSUInteger repeatIteration) {
           
            [self.sectorsArray enumerateObjectsUsingBlock:^(SATimerSector *sector, NSUInteger index, BOOL *stop) {
                
                if (![self.trackingSector isEqual:sector])
                {
                    sector.endValue = sector.animationStartValue - (sector.animationStartValue * progress);
                    
                    if (sector.endValue < 0.01)
                    {
                        sector.animationStartValue = 0.0f;
                    }
                    
                    [self valueChangedNotification];
                    [self setNeedsDisplay];
                }
                
            }];
            
        }];
    }
    else
    {
        
        
        
    }
}

#pragma mark - Properties -

#pragma mark Setters

- (void)setSectorsRadius:(double)sectorsRadius
{
    _sectorsRadius = sectorsRadius;
    [self setNeedsDisplay];
}


#pragma mark - Sectors manipulations -

- (void)addSector:(SATimerSector *)sector
{
    [self.sectorsArray addObject:sector];
    [self setNeedsDisplay];
}

- (void)removeSector:(SATimerSector *)sector
{
    [self.sectorsArray removeObject:sector];
    [self setNeedsDisplay];
}

- (void)removeAllSectors
{
    [self.sectorsArray removeAllObjects];
    [self setNeedsDisplay];
}


#pragma mark - Events manipulator -

- (BOOL)beginTrackingWithTouch:(UITouch *)touch
                     withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    
    __block BOOL beginTracking = NO;
    
    [self.sectorsArray enumerateObjectsUsingBlock:^(SATimerSector *sector, NSUInteger index, BOOL *stop) {
        
        SASectorDrawingInformation drawInf = [self sectorToDrawInf:sector index:index];
        
        if ([self touchInCircleWithPoint:touchPoint circleCenter:drawInf.endMarkerCenter])
        {
            self.trackingSector = sector;
            self.trackingSectorDrawInf = drawInf;
            self.trackingSectorStartMarker = NO;
            
            beginTracking = YES;
        }
        
    }];
    
    return beginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch
                        withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    CGPoint center = [self multiselectCenter];
    
    SAPolarCoordinate polar = decartToPolar(center, touchPoint);
    
    double correctedAngle;
    
    if (polar.angle < self.startAngle)
    {
        correctedAngle = polar.angle + (2 * M_PI - self.startAngle);
    }
    else
    {
        correctedAngle = polar.angle - self.startAngle;
    }
    
    double procent = correctedAngle / (M_PI * 2);
    
    double newValue = procent * (self.trackingSector.maxValue - self.trackingSector.minValue) + self.trackingSector.minValue;
    
    if (self.trackingSectorStartMarker)
    {
        if (newValue > self.trackingSector.startValue)
        {
            double diff = newValue - self.trackingSector.startValue;
            if (diff > ((self.trackingSector.maxValue - self.trackingSector.minValue) / 2))
            {
                self.trackingSector.startValue = self.trackingSector.minValue;
                [self valueChangedNotification];
                [self setNeedsDisplay];
                
                return YES;
            }
        }
        
        if (newValue >= self.trackingSector.endValue)
        {
            self.trackingSector.startValue = self.trackingSector.endValue;
            [self valueChangedNotification];
            [self setNeedsDisplay];
            
            return YES;
        }
        
        self.trackingSector.startValue = newValue;
        [self valueChangedNotification];
    }
    else
    {
        if (newValue < self.trackingSector.endValue)
        {
            //            double diff = trackingSector.endValue - newValue;
            //            if(diff > ((trackingSector.maxValue - trackingSector.minValue)/2)){
            //                trackingSector.endValue = trackingSector.maxValue;
            //                [self valueChangedNotification];
            //                [self setNeedsDisplay];
            //                return YES;
            //            }
        }
        if (newValue <= self.trackingSector.startValue)
        {
            self.trackingSector.endValue = self.trackingSector.startValue;
            [self valueChangedNotification];
            [self setNeedsDisplay];
            
            return YES;
        }
        
        self.trackingSector.endValue = newValue;
        [self valueChangedNotification];
    }
    
    [self setNeedsDisplay];
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch
                   withEvent:(UIEvent *)event
{
    self.trackingSector = nil;
    self.trackingSectorStartMarker = NO;
}

- (CGPoint)multiselectCenter
{
    return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (BOOL)touchInCircleWithPoint:(CGPoint)touchPoint
                  circleCenter:(CGPoint)circleCenter
{
    SAPolarCoordinate polar = decartToPolar(circleCenter, touchPoint);
    
    return (polar.radius >= (self.sectorsRadius / 2)) ? NO : YES;
}

- (void)valueChangedNotification
{
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}


#pragma mark - Drawing -

- (void)drawRect:(CGRect)rect
{
    [self.sectorsArray enumerateObjectsUsingBlock:^(SATimerSector *sector, NSUInteger index, BOOL *stop) {
        
        [self drawSector:sector
                 atIndex:index];
        
    }];
}

- (void)drawSector:(SATimerSector *)sector
           atIndex:(NSUInteger)index
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, saCircleLineWidth);
    
    UIColor *startCircleColor = [sector.color colorWithAlphaComponent:0.3];
    UIColor *circleColor = sector.color;
    UIColor *endCircleColor = [[UIColor grayColor] colorWithAlphaComponent:0.1];
    
    SASectorDrawingInformation drawInf = [self sectorToDrawInf:sector
                                                         index:index];
    
    CGFloat x = drawInf.circleCenter.x;
    CGFloat y = drawInf.circleCenter.y;
    CGFloat r = drawInf.radius;
    
    
    //start circle line
    [startCircleColor setStroke];
    CGContextAddArc(context, x, y, r, self.startAngle, drawInf.circleOffsetAngle, 0);
    CGContextStrokePath(context);
    
    //circle line
    [circleColor setStroke];
    CGContextAddArc(context, x, y, r, drawInf.circleOffsetAngle, drawInf.circleLineAngle, 0);
    CGContextStrokePath(context);
    
    //end circle line
    [endCircleColor setStroke];
    CGContextAddArc(context, x, y, r, drawInf.circleLineAngle, drawInf.circleEmptyAngle, 0);
    CGContextStrokePath(context);
    
    
    //clearing place for start marker
    //    CGContextSaveGState(context);
    //    CGContextAddArc(context, drawInf.startMarkerCenter.x, drawInf.startMarkerCenter.y, drawInf.startMarkerRadius - (saMarkersLineWidth/2.0), 0.0, 6.28, 0);
    //    CGContextClip(context);
    //    CGContextClearRect(context, self.bounds);
    //    CGContextRestoreGState(context);
    
    
    //clearing place for end marker
    CGContextSaveGState(context);
    CGContextAddArc(context, drawInf.endMarkerCenter.x, drawInf.endMarkerCenter.y, drawInf.endMarkerRadius - (saMarkersLineWidth/2.0), 0.0, 6.28, 0);
    CGContextClip(context);
    CGContextClearRect(context, self.bounds);
    CGContextRestoreGState(context);
    
    
    //markers
    CGContextSetLineWidth(context, saMarkersLineWidth);
    
    //drawing start marker
    //    [[circleColor colorWithAlphaComponent:drawInf.startMarkerAlpha] setStroke];
    //    CGContextAddArc(context, drawInf.startMarkerCenter.x, drawInf.startMarkerCenter.y, drawInf.startMarkerRadius, 0.0, 6.28, 0);
    //    CGContextStrokePath(context);
    
    //drawing end marker
    [[circleColor colorWithAlphaComponent:drawInf.endMarkerAlpha] setStroke];
    CGContextAddArc(context, drawInf.endMarkerCenter.x, drawInf.endMarkerCenter.y, drawInf.endMarkerRadius, 0.0, 6.28, 0);
    CGContextStrokePath(context);
    
    //text on markers
    //    NSString *markerStrTemplate = [@"%.0f" stringByReplacingOccurrencesOfString:@"0" withString:[NSString stringWithFormat:@"%i", self.numbersAfterPoint]];
    //    NSString *startMarkerStr = [NSString stringWithFormat:markerStrTemplate, sector.startValue];
    //    NSString *endMarkerStr = [NSString stringWithFormat:markerStrTemplate, sector.endValue];
    
    //drawing start marker's text
    //    [self drawString:startMarkerStr
    //            withFont:[UIFont boldSystemFontOfSize:drawInf.startMarkerFontSize]
    //               color:[[UIColor whiteColor] colorWithAlphaComponent:drawInf.startMarkerAlpha]
    //          withCenter:drawInf.startMarkerCenter];
    //
    //    //drawing end marker's text
    //    [self drawString:endMarkerStr
    //            withFont:[UIFont boldSystemFontOfSize:drawInf.endMarkerFontize]
    //               color:[[UIColor whiteColor] colorWithAlphaComponent:drawInf.endMarkerAlpha]
    //          withCenter:drawInf.endMarkerCenter];
}


- (SASectorDrawingInformation) sectorToDrawInf:(SATimerSector *)sector
                                         index:(NSInteger)index
{
    SASectorDrawingInformation drawInf;
    
    drawInf.circleCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height /2);
    drawInf.radius = self.sectorsRadius * (index + 1);
    
    drawInf.fullLine = sector.maxValue - sector.minValue;
    drawInf.circleOffset = sector.startValue - sector.minValue;
    drawInf.circleLine = sector.endValue - sector.startValue;
    drawInf.circleEmpty = sector.maxValue - sector.endValue;
    
    drawInf.circleOffsetAngle = (drawInf.circleOffset/drawInf.fullLine) * M_PI * 2 + self.startAngle;
    drawInf.circleLineAngle = (drawInf.circleLine/drawInf.fullLine) * M_PI * 2 + drawInf.circleOffsetAngle;
    drawInf.circleEmptyAngle = M_PI * 2 + self.startAngle;
    
    
    drawInf.startMarkerCenter = polarToDecart(drawInf.circleCenter, drawInf.radius, drawInf.circleOffsetAngle);
    drawInf.endMarkerCenter = polarToDecart(drawInf.circleCenter, drawInf.radius, drawInf.circleLineAngle);
    
    CGFloat minMarkerRadius = 16; // i changed this
    CGFloat maxMarkerRadius = 16;
    
    drawInf.startMarkerRadius = ((drawInf.circleOffsetAngle / (self.startAngle + 2* M_PI)) * (maxMarkerRadius - minMarkerRadius)) + minMarkerRadius;
    drawInf.endMarkerRadius = ((drawInf.circleLineAngle / (self.startAngle + 2 * M_PI)) * (maxMarkerRadius - minMarkerRadius)) + minMarkerRadius;
    
    CGFloat minFontSize = 12.0;
    CGFloat maxFontSize = 18.0;
    
    drawInf.startMarkerFontSize = ((drawInf.circleOffset / drawInf.fullLine) * (maxFontSize - minFontSize)) + minFontSize;
    drawInf.endMarkerFontize = ((drawInf.circleLine / drawInf.fullLine) * (maxFontSize - minFontSize)) + minFontSize;
    
    CGFloat markersCentresSegmentLength = segmentLength(drawInf.startMarkerCenter, drawInf.endMarkerCenter);
    CGFloat markersRadiusSumm = drawInf.startMarkerRadius + drawInf.endMarkerRadius;
    
    if (markersCentresSegmentLength < markersRadiusSumm)
    {
        
        drawInf.startMarkerAlpha = markersCentresSegmentLength / markersRadiusSumm;
    }
    else
    {
        drawInf.startMarkerAlpha = 0.0;
    }
    
    drawInf.endMarkerAlpha = 1.0;
    
    return drawInf;
}

- (void)drawString:(NSString *)s
          withFont:(UIFont *)font
             color:(UIColor *)color
        withCenter:(CGPoint)center
{
    CGSize size = CGSizeMake(0, 0);
    CGFloat x = center.x - (size.width / 2);
    CGFloat y = center.y - (size.height / 2);
    CGRect textRect = CGRectMake(x, y, size.width, size.height);
    
    if (IS_OS_LOWER_7)
    {
        [color set];
    }
    else
    {
        NSMutableDictionary *attr = [NSMutableDictionary new];
        attr[NSFontAttributeName] = font;
        attr[NSForegroundColorAttributeName] = color;
        [s drawInRect:textRect withAttributes:attr];
    }
}


@end






@implementation SATimerSector

- (instancetype)init
{
    if (self = [super init])
    {
        self.minValue = 0.0;
        self.maxValue = 100.0;
        self.startValue = 0.0;
        self.endValue = 0.0;
        self.tag = 0;
        self.color = [UIColor greenColor];
        self.name = [NSString new];
        
        self.animationStartValue = 0.0f;
    }
    return self;
}

+ (instancetype)sector
{
    return [[SATimerSector alloc] init];
}

+ (instancetype)sectorWithColor:(UIColor *)color
{
    SATimerSector *sector = [self sector];
    sector.color = color;
    return sector;
}

+ (instancetype)sectorWithColor:(UIColor *)color
                       maxValue:(double)maxValue
{
    SATimerSector *sector = [self sectorWithColor:color];
    sector.maxValue = maxValue;
    return sector;
}

+ (instancetype)sectorWithColor:(UIColor *)color
                       minValue:(double)minValue
                       maxValue:(double)maxValue
{
    SATimerSector *sector = [self sectorWithColor:color maxValue:maxValue];
    sector.minValue = minValue;
    return sector;
}

@end
