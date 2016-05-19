//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/17.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "ViewController.h"
#import "SZMoviePlayerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)beginPlay:(UIButton *)sender {
    
    SZMoviePlayerViewController *vc = [[SZMoviePlayerViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
    
}

@end
