//
//  PSCContentViewController.m
//  PSCRevelationViewController
//
//  Created by Michael Schwarz on 22.05.13.
//  Copyright (c) 2013 PocketScience. All rights reserved.
//

#import "PSCContentViewController.h"

@interface PSCContentViewController ()

@property UIButton *openCloseBtn;

@end

@implementation PSCContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.openCloseBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.openCloseBtn addTarget:self action:@selector(openCloseBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.openCloseBtn];
    [self.openCloseBtn setTitle:@"Open / Close" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.openCloseBtn.frame = CGRectMake(0.f, 0.f, 100.f, 50.f);
}

- (void)openCloseBtnPressed:(UIButton *)btn {
    ContentViewPosition currentPos = [self revelationController].currentContentViewPosition;
    if (currentPos == ContentViewPositionLeft || currentPos == ContentViewPositionCenter) {
        [[self revelationController] moveContentViewToContentPostion:ContentViewPositionRight animated:YES];
    } else {
        [[self revelationController] moveContentViewToContentPostion:ContentViewPositionLeft animated:YES];
    }
    
}

- (PSCRevelationController *)revelationController {
    if ([self.parentViewController isKindOfClass:[PSCRevelationController class]]) {
        return (PSCRevelationController *)self.parentViewController;
    } else {
        return nil;
    }
}

@end
