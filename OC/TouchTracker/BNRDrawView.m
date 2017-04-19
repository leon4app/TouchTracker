//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by LeonTse on 15/7/17.
//  Copyright (c) 2015年 LeonTse. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;
@property (nonatomic, weak) BNRLine *selectedLine;

@end

@implementation BNRDrawView

- (instancetype)initWithFrame:(CGRect)r
{
    self = [super initWithFrame:r];

    if (self)
    {
        self.linesInProgress      = [[NSMutableDictionary alloc] init];
        self.finishedLines        = [[NSMutableArray alloc] init];
        self.backgroundColor      = [UIColor grayColor];
        self.multipleTouchEnabled = YES;

        //doubleTapRecognizer
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];

        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan   = YES;
        [self addGestureRecognizer:doubleTapRecognizer];

        //tapRecognizer
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan      = YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [self addGestureRecognizer:tapRecognizer];

        //longpressRecognizer
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];

        [self addGestureRecognizer:pressRecognizer];

        //moveRecognizer
        self.moveRecognizer                      = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate             = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.moveRecognizer)
    {
        return YES;
    }
    return NO;
}

#pragma mark - Draw functions

- (void)strokeLine:(BNRLine *)line
{

    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth     = 10;
    bp.lineCapStyle  = kCGLineCapRound;

    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    //用黑色绘制已经完成的线条
    [[UIColor blackColor] set];
    for (BNRLine *line in self.finishedLines)
    {
        [self strokeLine:line];
    }

    //用红色绘制正在画的线条
    [[UIColor redColor] set];
    for (NSValue *key in self.linesInProgress)
    {
        [self strokeLine:self.linesInProgress[key]];
    }

    if (self.selectedLine)
    {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
}

- (BNRLine *)lineAtPoint:(CGPoint)p
{
    //找出离p最近的BNRLine对象
    for (BNRLine *l in self.finishedLines)
    {
        CGPoint start = l.begin;
        CGPoint end   = l.end;

        for (float t = 0.0; t <= 1.0; t += 0.5)
        {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);

            //如果线条的某个点和p的距离在20点以内,就返回相应的BNELine对象
            if (hypot(x - p.x, y - p.y) < 20.0)
            {
                return l;
            }
        }
    }
    //如果没找到符合条件的线条,就返回nil,代表不选择任何线条
    return nil;
}

- (void)deleteLine:(id)sender
{
    [self.finishedLines removeObject:self.selectedLine];

    [self setNeedsDisplay];
}

- (void)moveLine:(UIPanGestureRecognizer *)gr
{
    if (!self.selectedLine)
    {
        return;
    }

    if (gr.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [gr translationInView:self];

        CGPoint begin = self.selectedLine.begin;
        CGPoint end   = self.selectedLine.end;
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;

        self.selectedLine.begin = begin;
        self.selectedLine.end   = end;

        [self setNeedsDisplay];

        [gr setTranslation:CGPointZero inView:self];
    }
}

#pragma mark - touches functions

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    for (UITouch *t in touches)
    {
        CGPoint location = [t locationInView:self];

        BNRLine *line = [[BNRLine alloc] init];
        line.begin    = location;
        line.end      = location;

        NSValue *key              = [NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key] = line;
    }

    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));

    for (UITouch *t in touches)
    {
        NSValue *key  = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];

        line.end = [t locationInView:self];
    }

    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));

    for (UITouch *t in touches)
    {
        NSValue *key  = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];

        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }

    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", NSStringFromSelector(_cmd));

    for (UITouch *t in touches)
    {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        [self.linesInProgress removeObjectForKey:key];
    }
    [self setNeedsDisplay];
}

- (void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognizer Double Tap");

    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];

    [self setNeedsDisplay];
}

- (void)tap:(UITapGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");

    CGPoint point     = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:point];

    if (self.selectedLine)
    {

        [self becomeFirstResponder];

        UIMenuController *menu = [UIMenuController sharedMenuController];

        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        menu.menuItems         = @[ deleteItem ];

        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
    else
    {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    [self setNeedsDisplay];
}

- (void)longPress:(UIGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan)
    {
        CGPoint point     = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];

        if (self.selectedLine)
        {
            [self.linesInProgress removeAllObjects];
        }
    }
    else if (gr.state == UIGestureRecognizerStateEnded)
    {
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}


@end
