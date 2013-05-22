//
//  MSRevelationController.h
//  MSRevelationController
//
//  Created by Michael Schwarz on 30.04.13.
//  Copyright (c) 2013 Michael Schwarz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ContentViewPositionRight = 0,
    ContentViewPositionLeft,
    ContentViewPositionCenter
}ContentViewPosition;

@protocol PSCRevelationControllerDelegate <NSObject>

- (void)didMoveContentToViewPosition:(ContentViewPosition)position;

@end

@interface PSCRevelationController : UIViewController

@property (nonatomic, weak) id<PSCRevelationControllerDelegate>delegate;
@property (nonatomic, readonly) ContentViewPosition currentContentViewPosition;

- (void)setLeftBackgroundViewController:(UIViewController *)backgroundViewController openLength:(CGFloat)openLength closedLength:(CGFloat)closedLength;
- (void)setRightBackgroundViewController:(UIViewController *)backgroundViewController openLength:(CGFloat)openLength closedLength:(CGFloat)closedLength;
- (void)setContentViewController:(UIViewController *)contentViewController;

- (void)moveContentViewToContentPostion:(ContentViewPosition)position animated:(BOOL)animated;

@end
