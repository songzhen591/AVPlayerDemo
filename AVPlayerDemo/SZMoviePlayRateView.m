//
//  SZMoviePlayRateView.m
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/20.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "SZMoviePlayRateView.h"
static const CGFloat labelFont = 13.0f;

@interface SZMoviePlayRateView ()

@property (strong, nonatomic) UIImageView *imageView;



@property (strong, nonatomic) UILabel *midLabel;



@end

@implementation SZMoviePlayRateView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        
        [self addSubview:self.imageView];
        
        [self addSubview:self.timeLabel];
        
        [self addSubview:self.midLabel];
        
        [self addSubview:self.durationLabel];
    }
    return self;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ad_play_p"]];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.text = @"00:00:00";
        _timeLabel.font = [UIFont systemFontOfSize:labelFont];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor orangeColor];
    }
    return _timeLabel;
}

- (UILabel *)durationLabel
{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.text = @"00:00:00";
        _durationLabel.font = [UIFont systemFontOfSize:labelFont];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = [UIColor whiteColor];
    }
    return _durationLabel;
}

- (UILabel *)midLabel
{
    if (!_midLabel) {
        _midLabel = [[UILabel alloc] init];
        _midLabel.font = [UIFont systemFontOfSize:14];
        _midLabel.textColor = [UIColor whiteColor];
        _midLabel.textAlignment = NSTextAlignmentCenter;
        _midLabel.text = @"/";
    }
    return _midLabel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat imageWH = 50;
    CGFloat imageY= 5;
    CGFloat imageX = (self.bounds.size.width - imageWH) * 0.5;
    _imageView.frame = CGRectMake(imageX, imageY, imageWH, imageWH);
    
    CGFloat labelW = self.bounds.size.width * 0.45;
    CGFloat labelH = 20;
    CGFloat labelY = CGRectGetMaxY(_imageView.frame);
    _timeLabel.frame = CGRectMake(0,labelY, labelW, labelH);
    
    
    _midLabel.frame = CGRectMake(CGRectGetMaxX(_timeLabel.frame), labelY, self.bounds.size.width *0.1, labelH);
    
    _durationLabel.frame = CGRectMake(CGRectGetMaxX(_midLabel.frame),labelY, labelW, labelH);
    
}


@end
