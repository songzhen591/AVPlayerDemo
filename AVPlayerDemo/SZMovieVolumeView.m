//
//  SZMovieVolumeView.m
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/20.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "SZMovieVolumeView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SZMovieVolumeView ()

@property (strong, nonatomic) UIImageView *volumeUpImageView;

@property (strong, nonatomic) UIImageView *volumeDonwnImageView;



@end

@implementation SZMovieVolumeView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        
        [self addSubview:self.volumeUpImageView];
        
        [self addSubview:self.volumeDonwnImageView];
        
        [self addSubview:self.volumeSlider];
        
    }
    return self;
}

- (UIImageView *)volumeUpImageView
{
    if (!_volumeUpImageView) {
        _volumeUpImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yinliangda"]];
        _volumeUpImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _volumeUpImageView;
}

- (UIImageView *)volumeDonwnImageView
{
    if (!_volumeDonwnImageView) {
        _volumeDonwnImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yinliangxiao"]];
        _volumeDonwnImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _volumeDonwnImageView;
}

- (UISlider *)volumeSlider
{
    if (!_volumeSlider) {
        _volumeSlider = [[UISlider alloc] init];
        [_volumeSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateNormal];
        [_volumeSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateHighlighted];
        [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
        [_volumeSlider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _volumeSlider;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat imageWH = 40;
    _volumeUpImageView.frame = CGRectMake(0, 0, imageWH, imageWH);
    
    //旋转
    _volumeSlider.transform =  CGAffineTransformMakeRotation( -M_PI * 0.5 );
    CGFloat sliderH = 120;
    CGFloat sliderX = (self.bounds.size.width - 20 ) * 0.5;
    CGFloat sliderY = CGRectGetMaxY(_volumeUpImageView.frame);
    _volumeSlider.frame = CGRectMake(sliderX, sliderY, 20, sliderH);
    
    
    CGFloat downImageY = CGRectGetMaxY(_volumeSlider.frame);
    _volumeDonwnImageView.frame = CGRectMake(0, downImageY, imageWH, imageWH);
}

- (void)valueChanged:(UISlider *)slider
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(volumeViewDidDragging:)]) {
        [self.delegate volumeViewDidDragging:self];
    }
}


@end
