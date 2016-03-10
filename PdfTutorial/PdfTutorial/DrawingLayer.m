//
//  DrawingLayer.m
//  PdfTutorial
//
//  Created by Sasidhar Koti on 04/03/16.
//  Copyright © 2016 Sasidhar Koti. All rights reserved.
//

#import "DrawingLayer.h"

@interface DrawingLayer ()
@property (nonatomic, assign) CGPoint startingPoint;

@end

@implementation DrawingLayer



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self initializeSlate];
    
    return self;
}



- (void)initializeSlate
{
    self.pathArray = [[NSMutableArray alloc] init];
    self.backgroundColor = [UIColor clearColor];
    _drawingPath = [[UIBezierPath alloc]init];
    _drawingPath.lineCapStyle = kCGLineCapSquare;
    _drawingPath.miterLimit = 0;
    self.layer.masksToBounds = YES;
    _drawingColor = [[UIColor redColor] colorWithAlphaComponent:0.5]; //Default color - change with changeColorTo: method.
    _drawingPath.lineWidth = 16;
}

- (void)erasePoint:(CGPoint)point {
    int count = 0;
    for(UIBezierPath *path in self.pathArray)
    {
        CGRect rect = CGPathGetBoundingBox(path.CGPath);
        rect.origin.y -= 10;
        rect.size.height += 20;
        if (CGRectContainsPoint(rect, point)) {
            [self.pathArray removeObjectAtIndex:count];
            [self setNeedsDisplay];
            break;
        }
        count++;
    }
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    if (self.isErasing) {
        [self erasePoint:[touch locationInView:self]];
    }else {
        _drawingPath = [[UIBezierPath alloc]init];
        [self.pathArray addObject:_drawingPath];
        self.startingPoint = [touch locationInView:self];
        [_drawingPath moveToPoint:self.startingPoint];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self];
    if (self.isErasing) {
        [self erasePoint:[touch locationInView:self]];
    } else {
        [_drawingPath addLineToPoint:point];
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    int count = 0;
    for(UIBezierPath *path in self.pathArray)
    {
        [_drawingColor setStroke];
        [path strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
        count++;
    }
}

@end
