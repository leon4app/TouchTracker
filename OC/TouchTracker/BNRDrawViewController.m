//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by LeonTse on 15/7/17.
//  Copyright (c) 2015年 LeonTse. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"
@interface BNRDrawViewController ()

@end

@implementation BNRDrawViewController

- (void)loadView
{
    self.view = [[BNRDrawView alloc] initWithFrame:CGRectZero];
}

@end
