//
//  SZMovieBottomView.m
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/17.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "SZMovieBottomView.h"

@implementation SZMovieBottomView

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
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setBackgroundImage:[UIImage imageNamed:@"ad_play_p"] forState:UIControlStateNormal];     //正常
    [_playButton setBackgroundImage:[UIImage imageNamed:@"ad_pause_p"] forState:UIControlStateSelected];  //播放
    [_playButton addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_playButton];
    
    
    _currentTimeLabel = [[UILabel alloc] init];
    _currentTimeLabel.text = @"00:00";
    _currentTimeLabel.textColor = [UIColor whiteColor];
    _currentTimeLabel.font = [UIFont systemFontOfSize:14];
    _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_currentTimeLabel];
    
    _totalDurationLabel = [[UILabel alloc] init];
    _totalDurationLabel.text = @"00：00";
    _totalDurationLabel.textColor = [UIColor whiteColor];
    _totalDurationLabel.font = [UIFont systemFontOfSize:14];
    _totalDurationLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_totalDurationLabel];
        
    _progressView = [[UIProgressView alloc] init];
    _progressView.backgroundColor = [UIColor darkGrayColor];
    [self addSubview:_progressView];
    
    _movieProgressSlider = [[UISlider alloc] init];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateHighlighted];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateNormal];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    [_movieProgressSlider addTarget:self action:@selector(scrubbing) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_movieProgressSlider];
    
    _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_fullScreenButton setTitle:@"全屏" forState:UIControlStateNormal];
    [_fullScreenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self addSubview:_fullScreenButton];
}

- (void)layoutSubviews
{
    CGFloat playButtonWH = 40;
    CGFloat playButtonX = 15;
    CGFloat playButtonY = (self.bounds.size.height - playButtonWH) * 0.5;
    _playButton.frame = CGRectMake(playButtonX, playButtonY, playButtonWH, playButtonWH);
    
    CGFloat currentTimeX = CGRectGetMaxX(_playButton.frame) + 10;
    CGFloat currentTimeW = 40;
    CGFloat currentTimeH = 20;
    CGFloat currentTimeY = (self.bounds.size.height - currentTimeH) * 0.5;
    _currentTimeLabel.frame = CGRectMake(currentTimeX, currentTimeY, currentTimeW, currentTimeH);
    
    CGFloat sliderX = CGRectGetMaxX(_currentTimeLabel.frame) + 10;
    CGFloat sliderH = 5;
    CGFloat sliderY = (self.bounds.size.height - sliderH) * 0.5;
    CGFloat sliderW = self.bounds.size.width * 0.5;
    _movieProgressSlider.frame = CGRectMake(sliderX, sliderY, sliderW, sliderH);
    
    
    CGFloat progressViewH = 2;
    CGFloat progressViewY = (self.bounds.size.height - progressViewH ) *0.5;
    _progressView.frame = CGRectMake(_movieProgressSlider.frame.origin.x, progressViewY, _movieProgressSlider.bounds.size.width, progressViewH);

    
    CGFloat totalDurationX = CGRectGetMaxX(_movieProgressSlider.frame) + 10;
    _totalDurationLabel.frame = CGRectMake(totalDurationX, currentTimeY, currentTimeW, currentTimeH);
    
}

//播放或者暂停
- (void)playOrPause
{
    if ([self.delegate respondsToSelector:@selector(playOrPause)]) {
        [self.delegate playOrPause];
    }
}

//按住滑块
-(void)scrubbingDidBegin{
    if ([self.delegate respondsToSelector:@selector(didStartDragSlider:)]) {
        [self.delegate didStartDragSlider:_movieProgressSlider];
    }
}

//释放滑块
-(void)scrubbingDidEnd{
    if ([self.delegate respondsToSelector:@selector(didEndDragSlider:)]) {
        [self.delegate didEndDragSlider:_movieProgressSlider];
    }
}

//滑块处于滑动中
- (void)scrubbing
{
    if ([self.delegate respondsToSelector:@selector(didDraggingSlider:)]) {
        [self.delegate didDraggingSlider:_movieProgressSlider];
    }
}

@end
