//
//  SZMoviePlayerViewController.m
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/17.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "SZMoviePlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SZMovieTopView.h"
#import "SZMovieBottomView.h"
#import "SZMovieVolumeView.h"
#import "SZMoviePlayRateView.h"

static const CGFloat topViewH = 50;
static const CGFloat bottomViewH = 50;
static const CGFloat volumeViewW = 40;
static const CGFloat volumeViewH = 200;


typedef NS_ENUM(NSUInteger, PanGestureRecognizerDirection) {
    PanGestureRecognizerDirectionUp,
    PanGestureRecognizerDirectionDown,
    PanGestureRecognizerDirectionLeft,
    PanGestureRecognizerDirectionRight
};


@interface SZMoviePlayerViewController ()<SZMovieTopViewDelegate, SZMovieBottomViewDelegate, SZMovieVolumeViewDelegate>
{
    BOOL _played;                       //是否正在播放
    BOOL _isBlocked;                    //是否是否卡主(网络原因或视频质量)
    NSDateFormatter *_dateFormatter;    //时间格式
    PanGestureRecognizerDirection _panDirection;
    CGPoint _panBeginPoint;             //记录最初滑动的位置
}


@property (strong, nonatomic) SZMovieTopView *topView;                  //顶部view

@property (strong, nonatomic) SZMovieBottomView *bottomView;            //底部view

@property (strong, nonatomic) SZMovieVolumeView *volumeView;            //音量view

@property (strong, nonatomic) SZMoviePlayRateView *rateView;            //进度提示view

//核心播放
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;


//音量
@property (strong, nonatomic) MPVolumeView *systemVolumeView;
@property (strong, nonatomic) UISlider *systemVolumeSlider;             //用来接收系统音量
@property (assign, nonatomic) CGFloat currentVolume;                    //当前的系统音量
@property (assign, nonatomic) CGFloat volumeSliderBeginValue;           //记录音量开始值,垂直滑动的开始值


@property (nonatomic ,strong) id playbackTimeObserver;

//touch event
@property (assign, nonatomic) BOOL isDraggingSlider;                    //是否正在拖动底部slider控件
@property (assign, nonatomic) BOOL isHorizontalSlideOnScreen;           //是否正在屏幕进行水平滑动
@property (assign, nonatomic) BOOL ShowAroundingViews;                  //上，下，音量view是否显示
@property (assign, nonatomic) CGFloat sliderBeginValue;                 //记录slider开始值


@property (strong, nonatomic) UIActivityIndicatorView *activityInficatiorView;//小圈圈


@property (assign, nonatomic) CGFloat movieTotalDuration;               //视频总时长
@property (assign, nonatomic) __block CGFloat movieCurrentTime;         //当前已经播放的长度

@end

@implementation SZMoviePlayerViewController

- (instancetype)init
{
    if (self = [super init]) {
        //默认直接开始播放
        _played = YES;
        _ShowAroundingViews = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self prefersStatusBarHidden];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupAvPlayer];
    
    [self.view addSubview:self.topView];
    
    [self.view addSubview:self.bottomView];
    
    [self.view addSubview:self.volumeView];
    
    [self.view addSubview:self.rateView];
    
    [self.view addSubview:self.activityInficatiorView];
    [self.activityInficatiorView startAnimating];
    
    [self setupSubViewsFrame];
    
    //添加通知
    [self addNotification];
    
    //添加tap和pan手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBackgroundView:)];
    [self.view addGestureRecognizer:tap];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnBackgroundView:)];
    [self.view addGestureRecognizer:pan];
    
    [self viewNoDismiss];
    
    
    //设置默认音量
    self.volumeView.volumeSlider.value = [self deviceVolume];
}

- (void)addNotification
{
    //屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenFrameChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    //添加视频播放完毕通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //监听系统音量变化
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    //让 UIApplication 开始响应远程的控制，必须添加，不然没效果
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}


#pragma mark -  get
- (SZMovieTopView *)topView
{
    if (!_topView) {
        _topView = [[SZMovieTopView alloc] init];
        _topView.delegate = self;
    }
    return _topView;
}
- (SZMovieBottomView *)bottomView
{
    if (!_bottomView) {
        _bottomView =  [[SZMovieBottomView alloc] init];
        _bottomView.delegate = self;
        _bottomView.playButton.selected = YES;
    }
    return _bottomView;
}
- (SZMovieVolumeView *)volumeView
{
    if (!_volumeView) {
        _volumeView = [[SZMovieVolumeView alloc] init];
        _volumeView.delegate = self;
    }
    return _volumeView;
}
- (SZMoviePlayRateView *)rateView
{
    if (!_rateView) {
        _rateView = [[SZMoviePlayRateView alloc] init];
        _rateView.hidden = YES;
    }
    return _rateView;
}
- (UIActivityIndicatorView *)activityInficatiorView
{
    if (!_activityInficatiorView ) {
        _activityInficatiorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return _activityInficatiorView;
}
- (MPVolumeView *)systemVolumeView
{
    if (!_systemVolumeView) {
        _systemVolumeView = [[MPVolumeView alloc] init];
        _systemVolumeView.hidden = NO;
    }
    return _systemVolumeView;
}

- (UISlider *)systemVolumeSlider
{
    if (!_systemVolumeSlider) {
        for (UIView *view in [self.systemVolumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                _systemVolumeSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _systemVolumeSlider;
}

#pragma mark - 播放器主体
- (void)setupAvPlayer
{
    //http://baobab.cdn.wandoujia.com/14468618701471.mp4
    //http://v.jxvdy.com/sendfile/w5bgP3A8JgiQQo5l0hvoNGE2H16WbN09X-ONHPq3P3C1BISgf7C-qVs6_c8oaw3zKScO78I--b0BGFBRxlpw13sf2e54QA
    AVAudioSession *audioSesstion = [AVAudioSession sharedInstance];
    [audioSesstion setActive:YES error:NULL];
    [audioSesstion setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:@"http://baobab.cdn.wandoujia.com/14468618701471.mp4"]];
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self addObserver];
    _player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:_playerLayer];
}
//添加监听
- (void)addObserver
{
    //监听视频准备情况
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //缓冲进度
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //seekToTime后，缓冲数据为空，而且有效时间内数据无法补充，播放失败
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - APlayerItem属性变化回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            //准备好开始播放
            //获取总长度
            CMTime duration = _playerItem.duration;
            _movieTotalDuration = CMTimeGetSeconds(duration);
            self.bottomView.totalDurationLabel.text = [self convertTime:_movieTotalDuration];
            self.rateView.durationLabel.text = [self convertTime:_movieTotalDuration];
            //自定义UISlider外观
            [self customVideoSlider:duration];
            
            //监听播放状态
            [self monitoringPlayback:self.playerItem];
            
            //开始播放
            [self moviePlay];
            
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            //更显缓冲区
            [self updateBuffer];
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        
        NSLog(@"卡主啦");
        //视频卡主
        _isBlocked = YES;
        [_activityInficatiorView startAnimating];
        
        //暂停视频
        [self moviePause];
        
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        
        NSLog(@"走起");
        if (_isBlocked) {
            [self moviePlay];
            _isBlocked = NO;
        }
        [_activityInficatiorView stopAnimating];
    }
}

#pragma mark - 监听视频播放
- (void)monitoringPlayback:(AVPlayerItem *)playerItem
{
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        
        //视频播放时候，动态改变底部的滑动条和当前已播放时间
        //如果此时用户正在拖动底部的slider或者滑动屏幕，则不由此方法进行控制
        if (!weakSelf.isDraggingSlider && !weakSelf.isHorizontalSlideOnScreen) {
            _movieCurrentTime = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
            [weakSelf updateMovieSlider];
            [weakSelf updateCurrentTimeLabel];
        }
    }];
}

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

#pragma mark - 计算缓冲时间
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;
    [_player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        
        //播放完毕后当前播放时间置0， 停止播放
        weakSelf.movieCurrentTime = 0.0f;
        [weakSelf updateCurrentTimeLabel];
        [self moviePause];
    }];
}

- (void)customVideoSlider:(CMTime)duration {
    self.bottomView.movieProgressSlider.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.bottomView.movieProgressSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.bottomView.movieProgressSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

#pragma mark - ***************SZMovieBottomViewDelegate*************************************

- (void)didStartDragSlider:(UISlider *)movieProgressSlider
{
    _isDraggingSlider = YES;
}
- (void)didEndDragSlider:(UISlider *)movieProgressSlider
{
    [self viewNoDismiss];
    CMTime changedTime = CMTimeMake(movieProgressSlider.value, 1);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf moviePlay];
        _isDraggingSlider = NO;
    }];
}
- (void)didDraggingSlider:(UISlider *)movieProgressSlider
{
    _movieCurrentTime = movieProgressSlider.value;
    [self updateCurrentTimeLabel];
    
}
- (void)playOrPause
{
    [self viewNoDismiss];
    if (!_played) {
        [self moviePlay];
    }else{
        [self moviePause];
    }
}

#pragma mark - 开始播放
- (void)moviePlay
{
    [_player play];
    _played = YES;
    _bottomView.playButton.selected = YES;
    [_activityInficatiorView stopAnimating];
}
#pragma mark - 停止播放
- (void)moviePause
{
    [_player pause];
    _played = NO;
    _bottomView.playButton.selected = NO;
}

#pragma mark - 屏幕旋转的响应事件
- (void)screenFrameChanged:(NSNotification *)notification
{
    [self setupSubViewsFrame];
}
#pragma mark - 设置控件frame
- (void)setupSubViewsFrame
{
    //topview
    _topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, topViewH);
    //_playerLayer
    _playerLayer.frame = CGRectMake(0, 0, self.view.layer.bounds.size.width, self.view.layer.bounds.size.height);
    //音量
    CGFloat volumeY = (self.view.bounds.size.height - volumeViewH ) *0.5;
    _volumeView.frame = CGRectMake(20,volumeY , volumeViewW, volumeViewH);
    CGFloat bottomViewY = self.view.bounds.size.height - bottomViewH;
    _bottomView.frame = CGRectMake(0, bottomViewY, self.view.bounds.size.width, bottomViewH);
    _activityInficatiorView.center = self.view.center;
    _activityInficatiorView.bounds = CGRectMake(0, 0, 50, 50);
    _rateView.center = self.view.center;
    _rateView.bounds = CGRectMake(0, 0, 120, 80);
}

#pragma mark - ************** 更新操作

#pragma mark 更新当前播放时间
- (void)updateCurrentTimeLabel
{
    NSString *timeString = [self convertTime:self.movieCurrentTime];
    self.bottomView.currentTimeLabel.text = [NSString stringWithFormat:@"%@", timeString];
    self.rateView.timeLabel.text = [NSString stringWithFormat:@"%@", timeString];
    
    
    if (_panDirection == PanGestureRecognizerDirectionRight) {
        self.rateView.isGoForward = YES;
    }else{
        self.rateView.isGoForward = NO;
    }
}
#pragma mark 更新底部进度条
- (void)updateMovieSlider
{
    [self.bottomView.movieProgressSlider setValue:self.movieCurrentTime animated:YES];
}

#pragma mark 更新缓冲进度
- (void)updateBuffer
{
    NSTimeInterval timeInterval = [self availableDuration];
    [_bottomView.progressView setProgress:timeInterval / _movieTotalDuration];
}

#pragma mark - 更新自定义的音量view
- (void)updateCustomVolumeView
{
    self.volumeView.volumeSlider.value = self.currentVolume;
}
#pragma mark - 更新系统音量
- (void)updateSystemVolume
{
    self.systemVolumeSlider.value = self.currentVolume;
}

#pragma mark - ************************关于手势的操作*******************************************
#pragma mark 轻击手势
- (void)tapBackgroundView:(UITapGestureRecognizer *)tap
{
    [self viewNoDismiss];
    //轻击隐藏上下view
    if (_ShowAroundingViews) {
        [self hideAroundingViews];
    }else{
        [self showAroundingViews];
    }
}
#pragma mark 拖动手势
- (void)panOnBackgroundView:(UIPanGestureRecognizer *)pan
{
    [self viewNoDismiss];
    
    CGPoint velocityPoint = [pan velocityInView:self.view];
    //确定滑动方向
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{
            //判断移动方向
            BOOL isVerticalGesture = (fabs(velocityPoint.y) > fabs(velocityPoint.x));
            if (isVerticalGesture) {
                if (velocityPoint.y > 0) {
                    _panDirection = PanGestureRecognizerDirectionDown;
                }else{
                    _panDirection = PanGestureRecognizerDirectionUp;
                }
            }else{
                if (velocityPoint.x > 0) {
                    _panDirection = PanGestureRecognizerDirectionRight;
                }else{
                    _panDirection = PanGestureRecognizerDirectionLeft;
                }
            }
            //记录开始的位置
            _panBeginPoint = [pan locationInView:self.view];
            //记录进度条最初位置
            _sliderBeginValue = _bottomView.movieProgressSlider.value;
            //记录开始音量
            _volumeSliderBeginValue = _volumeView.volumeSlider.value;
            break;
        }
        case UIGestureRecognizerStateChanged:{
            switch (_panDirection) {
                case PanGestureRecognizerDirectionLeft: case PanGestureRecognizerDirectionRight:
                    
                    //需要继续判断用户左滑还是右滑
                    if (velocityPoint.x > 0) {
                        _panDirection = PanGestureRecognizerDirectionRight;
                    }else{
                        _panDirection = PanGestureRecognizerDirectionLeft;
                    }
                    //显示rateview
                    self.rateView.hidden = NO;
                    //水平滑动中
                    [self horizontalMovingOnScreen:pan];
                    
                    break;
                case PanGestureRecognizerDirectionUp: case PanGestureRecognizerDirectionDown:
                    //垂直滑动中
                    [self verticalMovingOnScreen:pan];
                    break;
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{
            switch (_panDirection) {
                case PanGestureRecognizerDirectionRight: case PanGestureRecognizerDirectionLeft:
                    [self horizontalMoveEnd:pan];
                    break;
                case PanGestureRecognizerDirectionDown: case PanGestureRecognizerDirectionUp:
                    [self verticalMoveEnd:pan];
                    break;
                    
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - 横向滑动， 视频快进
- (void)horizontalMovingOnScreen:(UIPanGestureRecognizer *)pan
{
    _isHorizontalSlideOnScreen = YES;
    
    //更改底部slider和当前时间
    CGFloat changedX = [pan locationInView:self.view].x - _panBeginPoint.x;
    CGFloat panScale = changedX / self.view.bounds.size.width;
    _movieCurrentTime = _sliderBeginValue + (_bottomView.movieProgressSlider.maximumValue *panScale);
    
    //保证已播放时间可用
    if (_movieCurrentTime < 0) {
        _movieCurrentTime = 0;
    }
    if (_movieCurrentTime > _movieTotalDuration) {
        _movieCurrentTime = _movieTotalDuration;
    }
    
    //更新UI
    [self updateMovieSlider];
    [self updateCurrentTimeLabel];
    
}
- (void)horizontalMoveEnd:(UIPanGestureRecognizer *)pan
{
    self.rateView.hidden = YES;
    
    //滑动停止时，视频跳转
//    CMTime changedTime = CMTimeMake(_bottomView.movieProgressSlider.value, 1);
//    NSLog(@"%f , %d" , _currentVolume, self.player.currentItem.asset.duration.timescale);
    CMTime changedTime = CMTimeMakeWithSeconds(_movieCurrentTime, self.player.currentItem.asset.duration.timescale);
    
    
    
    __weak typeof(self) weakSelf = self;
//    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
//        
//        [weakSelf moviePlay];
//        _sliderBeginValue = _bottomView.movieProgressSlider.value;
//        _isHorizontalSlideOnScreen = NO;
//    }];

    [self.player seekToTime:changedTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf moviePlay];
        _sliderBeginValue = _bottomView.movieProgressSlider.value;
        _isHorizontalSlideOnScreen = NO;
    }];
}

#pragma mark - 竖直滑动手势， 关于音量操作
- (void)verticalMovingOnScreen:(UIPanGestureRecognizer *)pan
{
    //改变系统音量
    CGFloat changedY = _panBeginPoint.y - [pan locationInView:self.view].y;
    CGFloat panScale = changedY / self.view.bounds.size.height;
    self.currentVolume = _volumeSliderBeginValue +  panScale;
    [self updateCustomVolumeView];
    [self updateSystemVolume];
}

- (void)verticalMoveEnd:(UIPanGestureRecognizer *)pan
{
    _volumeSliderBeginValue = self.currentVolume;
}

#pragma mark 获取系统音量
- (CGFloat)deviceVolume
{
    return [[AVAudioSession sharedInstance] outputVolume];
}

#pragma mark  系统音量变化(通知)
- (void)volumeChanged:(NSNotification *)notification
{
    _currentVolume = [notification.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    [self updateSystemVolume];
    [self updateCustomVolumeView];
}

#pragma mark - 拖动音量滑块
- (void)volumeViewDidDragging:(SZMovieVolumeView *)volumeView
{
    self.currentVolume = volumeView.volumeSlider.value;
    [self updateSystemVolume];
}

- (void)showAroundingViews
{
    [UIView animateWithDuration:0.5 animations:^{
        _topView.alpha = 1;
        _bottomView.alpha = 1;
        _volumeView.alpha = 1;
        _ShowAroundingViews = YES;
    }];
}
- (void)hideAroundingViews
{
    [UIView animateWithDuration:0.5 animations:^{
        _topView.alpha = 0;
        _bottomView.alpha = 0;
        _volumeView.alpha = 0;
        _ShowAroundingViews = NO;
    }];
}

#pragma mark - 计时隐藏
//做任何操作之前调用此方法，重新计时，3秒后隐藏视图
- (void)viewNoDismiss
{
//    [UIView cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAroundingViews) object:nil];
//    [self performSelector:@selector(hideAroundingViews) withObject:nil afterDelay:3];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

#pragma mark - 屏幕旋转
//隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}
////允许横屏旋转
//- (BOOL)shouldAutorotate{
//    return YES;
//}
//
////支持左右旋转
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
//    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft;
//}
//
////默认为右旋转
//- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
//    return UIInterfaceOrientationLandscapeRight;
//}


@end
