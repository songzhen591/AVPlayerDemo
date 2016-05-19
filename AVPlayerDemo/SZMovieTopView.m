//
//  SZMovieTopView.m
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/17.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "SZMovieTopView.h"

@interface SZMovieTopView ()

@property (strong, nonatomic) UIButton *backButton; //返回按钮

@property (strong, nonatomic) UILabel *titleLabel;  //标题

@property (strong, nonatomic) UIButton *actionButton;//

@end

@implementation SZMovieTopView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews
{
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backButton setTitle:@"返回" forState:UIControlStateNormal];
    _backButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_backButton];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"精彩视频";
    _titleLabel.font = [UIFont systemFontOfSize:18];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:_titleLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat backButtonWH = 40;
    CGFloat backButtonY = (self.bounds.size.height - backButtonWH) *0.5;
    CGFloat backButtonX = 15;
    _backButton.frame = CGRectMake(backButtonX, backButtonY, backButtonWH, backButtonWH);
    
    CGFloat titleLabelX = CGRectGetMaxX(_backButton.frame) + 10;
    CGFloat titleLabelW = self.bounds.size.width - 2 * titleLabelX;
    _titleLabel.center = self.center;
    _titleLabel.bounds = CGRectMake(0, 0, titleLabelW, backButtonWH);
}

- (void)back
{
    
}

@end
