//
//  SZMovieBottomView.h
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/17.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SZMovieBottomView;
@protocol SZMovieBottomViewDelegate <NSObject>

@optional
- (void)playOrPause;

- (void)didStartDragSlider:(UISlider *)movieProgressSlider;

- (void)didEndDragSlider:(UISlider *)movieProgressSlider;

- (void)didDraggingSlider:(UISlider *)movieProgressSlider;

@end

@interface SZMovieBottomView : UIView

@property (strong, nonatomic) UIButton *playButton;                 //播放按钮
@property (strong, nonatomic) UILabel *currentTimeLabel;            //当前时间进度
@property (strong, nonatomic) UILabel *totalDurationLabel;          //总时间
@property (strong, nonatomic) UISlider *movieProgressSlider;        //滑动
@property (strong, nonatomic) UIProgressView *progressView;         //进度条
@property (strong, nonatomic) UIButton *fullScreenButton;           //全屏按钮

@property (assign, nonatomic) id<SZMovieBottomViewDelegate> delegate;

@end
