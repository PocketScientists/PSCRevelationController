//
//  PSCMenuViewController.m
//  PSCRevelationViewController
//
//  Created by Michael Schwarz on 22.05.13.
//  Copyright (c) 2013 PocketScience. All rights reserved.
//

#import "PSCMenuViewController.h"
#import "PSCContentViewController.h"
#import "PSCRevelationController.h"
#import <QuartzCore/QuartzCore.h>

@interface PSCMenuViewController ()

@property (nonatomic, strong) NSArray *menuCellClasses;

@end

@implementation PSCMenuViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _menuCellClasses = @[[PSCContentViewController class],[PSCContentViewController class],[PSCContentViewController class]];
        self.tableView.backgroundColor = [UIColor lightGrayColor];
        self.tableView.contentInset = UIEdgeInsetsMake(50.f, 0.f, 0.f, 0.f);
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.menuCellClasses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    
    cell.textLabel.text = [NSString stringWithFormat:@"Menu-Entry %d",indexPath.row];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Class contentClass = [self.menuCellClasses objectAtIndex:indexPath.row];
    UIViewController *contentViewController = [[contentClass alloc] init];
    
    contentViewController.view.layer.masksToBounds = NO;
    contentViewController.view.layer.shadowOffset = CGSizeMake(-4, 4);
    contentViewController.view.layer.shadowRadius = 5;
    contentViewController.view.layer.shadowOpacity = 0.5;
    contentViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:contentViewController.view.bounds].CGPath;
    CGFloat count = self.menuCellClasses.count;
    contentViewController.view.backgroundColor = [UIColor colorWithRed:indexPath.row /count green:indexPath.row / count blue:indexPath.row / count alpha:1.f];
    [[self revelationController] setContentViewController:contentViewController];
    
}

- (PSCRevelationController *)revelationController {
    if ([self.parentViewController isKindOfClass:[PSCRevelationController class]]) {
        return (PSCRevelationController *)self.parentViewController;
    } else {
        return nil;
    }
}

@end
