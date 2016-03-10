//
//  DrawingLayer.h
//  PdfTutorial
//
//  Created by Sasidhar Koti on 04/03/16.
//  Copyright © 2016 Sasidhar Koti. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrawingLayer : UIView

//UIBezierPath class used to drawpath on the screen
@property(strong, nonatomic) UIBezierPath *drawingPath;
@property(strong, nonatomic) UIColor *drawingColor;
@property (nonatomic, strong) NSMutableArray *pathArray;
@property (nonatomic, assign) BOOL isErasing;
@end
