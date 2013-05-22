//
//  MSRevelationController.m
//  MSRevelationController
//
//  Created by Michael Schwarz on 30.04.13.
//  Copyright (c) 2013 Michael Schwarz. All rights reserved.
//

#import "PSCRevelationController.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
    BackgroundViewControllerTypeLeft = 0,
    BackgroundViewControllerTypeRight
}BackgroundViewControllerType;

@interface PSCRevelationController ()

@property (nonatomic, strong) NSMutableArray *backgroundViewControllers;
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) NSMutableArray *backgroundClosedLengths;
@property (nonatomic, strong) NSMutableArray *backgroundOpenLengths;

@property (nonatomic, assign) CGFloat leftOpenOriginX;
@property (nonatomic, assign) CGFloat rightOpenOriginX;
@property (nonatomic, assign) CGFloat bothClosedOriginX;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

//Internal Configuration Parameter
@property (nonatomic, assign) BOOL dragElasticity;

@end

@implementation PSCRevelationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _backgroundViewControllers = [@[[NSNull null],[NSNull null]] mutableCopy];
        _backgroundClosedLengths = [@[@0,@0] mutableCopy];
        _backgroundOpenLengths = [@[@0,@0] mutableCopy];
        _dragElasticity = YES;
        _currentContentViewPosition = ContentViewPositionCenter;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)moveContentViewToContentPostion:(ContentViewPosition)position animated:(BOOL)animated {
    [self stopContentViewAnimation];
    CGFloat targetXPostion = [self targetXPostionForContentPostionType:position];
    
    // move to new position
    [UIView animateWithDuration:animated ? 0.25 : 0.0
                          delay:0.
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         // apply offset
                         self.contentViewController.view.frame = CGRectMake(targetXPostion, self.contentViewController.view.frame.origin.y, self.contentViewController.view.frame.size.width, self.contentViewController.view.frame.size.height);
                     } completion:^(BOOL finished) {
                         _currentContentViewPosition = position;
                         if (self.delegate && [self.delegate respondsToSelector:@selector(didMoveContentToViewPosition:)]) {
                             [self.delegate didMoveContentToViewPosition:self.currentContentViewPostion];
                         }
                     }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Getter / Setter
////////////////////////////////////////////////////////////////////////

- (void)setLeftBackgroundViewController:(UIViewController *)backgroundViewController openLength:(CGFloat)openLength closedLength:(CGFloat)closedLength {
    [self setBackgroundViewController:backgroundViewController type:BackgroundViewControllerTypeLeft openLength:openLength closedLength:closedLength];
    backgroundViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
}

- (void)setRightBackgroundViewController:(UIViewController *)backgroundViewController openLength:(CGFloat)openLength closedLength:(CGFloat)closedLength {
    [self setBackgroundViewController:backgroundViewController type:BackgroundViewControllerTypeRight openLength:openLength closedLength:closedLength];
    backgroundViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
}

- (void)setBackgroundViewController:(UIViewController *)backgroundViewcontroller type:(BackgroundViewControllerType)type openLength:(CGFloat)openLength closedLength:(CGFloat)closedLength {
    id oldVC = [self.backgroundViewControllers objectAtIndex:type];
    if ([oldVC isKindOfClass:[UIViewController class]]) {
        [oldVC removeFromSuperview];
        [oldVC removeFromParentViewController];
    }
    [self.backgroundViewControllers insertObject:backgroundViewcontroller atIndex:type];
    
    [self addChildViewController:backgroundViewcontroller];
    [self.view insertSubview:backgroundViewcontroller.view atIndex:0];
    [backgroundViewcontroller didMoveToParentViewController:self];
    backgroundViewcontroller.view.frame = [self rectForBackgroundViewControllerWithType:type length:openLength];
    [self.backgroundClosedLengths insertObject:[NSNumber numberWithFloat:closedLength] atIndex:type];
    [self.backgroundOpenLengths insertObject:[NSNumber numberWithFloat:openLength] atIndex:type];
    
    self.leftOpenOriginX = [[self.backgroundOpenLengths objectAtIndex:BackgroundViewControllerTypeLeft] floatValue];
    self.bothClosedOriginX = [[self.backgroundClosedLengths objectAtIndex:BackgroundViewControllerTypeLeft] floatValue];
    CGFloat rightClosedDistance = [[self.backgroundClosedLengths objectAtIndex:BackgroundViewControllerTypeRight] floatValue];
    self.rightOpenOriginX = -[[self.backgroundOpenLengths objectAtIndex:BackgroundViewControllerTypeRight] floatValue] + self.bothClosedOriginX + rightClosedDistance;
    
    self.contentViewController.view.frame = [self rectForContentViewController];
}

- (void)setContentViewController:(UIViewController *)contentViewController {
    CGRect frame;
    if (_contentViewController) {
        frame = _contentViewController.view.frame;
        [_contentViewController.view removeFromSuperview];
        [_contentViewController.view removeGestureRecognizer:self.panGesture];
        [_contentViewController removeFromParentViewController];
    } else {
        frame = [self rectForContentViewController];
    }
    
    _contentViewController = contentViewController;
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panningAction:)];
    [_contentViewController.view addGestureRecognizer:self.panGesture];
    
    [self addChildViewController:contentViewController];
    [self.view addSubview:contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];
    self.contentViewController.view.frame = frame;
}

- (ContentViewPosition)currentContentViewPostion {
    return _currentContentViewPosition;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Target / Action
////////////////////////////////////////////////////////////////////////

- (void)panningAction:(UIPanGestureRecognizer *)recognizer{
    CGFloat velocity;
    static CGPoint oldPoint;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        oldPoint = [recognizer translationInView:self.contentViewController.view];
    }
    
    CGPoint point = [recognizer translationInView:self.contentViewController.view];
    
    CGFloat offset = (point.x - oldPoint.x);
    velocity = [recognizer velocityInView:self.contentViewController.view].x;
    [self dragContentView:offset];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self snapContentViewToPosition:[self nearestContentSnapPositionForXPostion:self.contentViewController.view.frame.origin.x andSpeed:velocity] withSpeed:velocity];
    }
    
    oldPoint = point;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)stopContentViewAnimation {
    [self.contentViewController.view.layer removeAllAnimations];
}

- (CGRect)rectForBackgroundViewControllerWithType:(BackgroundViewControllerType)type length:(CGFloat)length {
    CGFloat bottom = self.view.frame.size.height;
    CGFloat right = self.view.frame.size.width;
    switch (type) {
        case BackgroundViewControllerTypeLeft:
            return CGRectMake(0.f, 0.f, length, bottom);
        case BackgroundViewControllerTypeRight:
            return CGRectMake(right - length, 0.f, length, bottom);
    }
}

- (CGRect)rectForContentViewController {
    CGFloat left = [[self.backgroundClosedLengths objectAtIndex:BackgroundViewControllerTypeLeft] floatValue];
    CGFloat right = [[self.backgroundClosedLengths objectAtIndex:BackgroundViewControllerTypeRight] floatValue];
    CGFloat top = 0.f;
    CGFloat width = self.view.frame.size.width - left - right;
    CGFloat height = self.view.frame.size.height;
    
    return CGRectMake(left, top, width, height);
}

- (ContentViewPosition)nearestContentSnapPositionForXPostion:(CGFloat)xPos andSpeed:(CGFloat)speed {
    xPos += (speed * 0.050);
    CGFloat distanceClosed = fabs(self.bothClosedOriginX - xPos);
    CGFloat distanceLeftOpen = fabs(self.leftOpenOriginX - xPos);
    CGFloat distanceRightOpen = fabs(self.rightOpenOriginX - xPos);
    
    if (distanceClosed < distanceLeftOpen && distanceClosed < distanceRightOpen) {
        return ContentViewPositionCenter;
    }
    if (distanceLeftOpen < distanceClosed && distanceLeftOpen < distanceRightOpen) {
        return ContentViewPositionRight;
    }
    
    return ContentViewPositionLeft;
}

- (void)dragContentView:(CGFloat)distance {
    CGRect rect = self.contentViewController.view.frame;
    
    CGFloat newOrigin = rect.origin.x + distance;
    if (newOrigin <= self.leftOpenOriginX && newOrigin >= self.rightOpenOriginX) {
        self.contentViewController.view.frame = CGRectOffset(rect, distance, 0.f);
    } else { // elasticity if you drag over the max / min position
        if (self.dragElasticity) {
            if (newOrigin > self.leftOpenOriginX) {
                CGFloat newDistance = distance * (1.f / fabs(newOrigin - self.leftOpenOriginX) );
                self.contentViewController.view.frame = CGRectOffset(rect, newDistance, 0.f);
            }
            if (newOrigin < self.rightOpenOriginX) {
                CGFloat newDistance = distance * (1.f / fabs(newOrigin - self.rightOpenOriginX) );
                self.contentViewController.view.frame = CGRectOffset(rect, newDistance, 0.f);
            }
        }
    }
}

- (void)snapContentViewToPosition:(ContentViewPosition)position withSpeed:(CGFloat)speed {
    [self stopContentViewAnimation];
    
    CGFloat currentXPostion = self.contentViewController.view.frame.origin.x;
    CGFloat targetXPosition;
    
    targetXPosition = [self targetXPostionForContentPostionType:position];
    
    self.contentViewController.view.layer.anchorPoint = CGPointMake(0.f, 0.5f);
    CAKeyframeAnimation *contentAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    CAMediaTimingFunction *linear = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    CAMediaTimingFunction *easeOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    CAMediaTimingFunction *easeIn = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    BOOL sameDirection = ((targetXPosition - currentXPostion) > 0 && speed > 0) || ((targetXPosition - currentXPostion) <= 0 && speed <= 0);
    BOOL isStreched = (currentXPostion > self.leftOpenOriginX || currentXPostion < self.rightOpenOriginX);
    
    if (!sameDirection && ! isStreched) {
        contentAnimation.values = @[@(currentXPostion), @(currentXPostion + (speed * 0.020)), @(targetXPosition)];
        contentAnimation.timingFunctions = @[easeOut, easeIn,  linear];
        contentAnimation.keyTimes = @[@(0.0), @(0.42), @(1.0)];
        contentAnimation.duration = 0.4;
    } else {
        contentAnimation.values = @[@(currentXPostion), @(targetXPosition)];
        contentAnimation.timingFunctions = @[easeOut,  linear];
        contentAnimation.keyTimes = @[@(0.0), @(1.0)];
        contentAnimation.duration = 0.2;
    }
    
    contentAnimation.delegate = self;
    contentAnimation.removedOnCompletion = NO;
    contentAnimation.fillMode = kCAFillModeBoth;
    
    [contentAnimation setValue:@(targetXPosition) forKey:@"TargetX"];
    [contentAnimation setValue:@(position) forKey:@"TargetViewPostion"];
    
    [self.contentViewController.view.layer addAnimation:contentAnimation forKey:@"ContentAnimation"];
}

- (CGFloat)targetXPostionForContentPostionType:(ContentViewPosition)contentViewPostionType {
    CGFloat targetXPosition;
    
    if (contentViewPostionType == ContentViewPositionRight) {
        targetXPosition = self.leftOpenOriginX;
    } else if (contentViewPostionType == ContentViewPositionLeft) {
        targetXPosition = self.rightOpenOriginX;
    } else {
        targetXPosition = self.bothClosedOriginX;
    }
    return targetXPosition;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - CAAnimationDelegate (Informal Protocol)
////////////////////////////////////////////////////////////////////////

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
    if (finished && animation == [self.contentViewController.view.layer animationForKey:@"ContentAnimation"]) {
        NSNumber *targetX = [animation valueForKey:@"TargetX"];
        NSNumber *targetViewPosition = [animation valueForKey:@"TargetViewPostion"];
        
        // update model layer 
        if (targetX != nil) {
            self.contentViewController.view.frame = CGRectMake([targetX floatValue], self.contentViewController.view.frame.origin.y,self.contentViewController.view.frame.size.width,self.contentViewController.view.frame.size.height);
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didMoveContentToViewPosition:)]) {
            [self.delegate didMoveContentToViewPosition:targetViewPosition.integerValue];
        }
        
        [self.contentViewController.view.layer removeAnimationForKey:@"ContentAnimation"];
    }
}

@end
