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

static const CGFloat topViewH = 55;
static const CGFloat bottomViewH = 60;


@interface SZMoviePlayerViewController ()<SZMovieTopViewDelegate, SZMovieBottomViewDelegate>
{
    BOOL _played;                       //是否正在播放
    CGFloat _movieTotalDuration;        //视频总时长
    CGFloat _movieCurrentTime;          //当前播放时长
    NSDateFormatter *_dateFormatter;    //时间格式
}

//顶部view
@property (strong, nonatomic) SZMovieTopView *topView;

//底部view
@property (strong, nonatomic) SZMovieBottomView *bottomView;

//核心播放
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (nonatomic ,strong) id playbackTimeObserver;

//touch event
@property (assign, nonatomic) BOOL isDraggingSlider;        //是否正在拖动slider控件
@property (assign, nonatomic) BOOL isSlideOnScreen;         //是否正在滑动屏幕进行快进和音量操作
@property (assign, nonatomic) BOOL isShowTopAndBottomView;  //上下view是否显示
@property (assign, nonatomic) CGPoint touchBeginPoint;      //记录touch起点坐标
@property (assign, nonatomic) CGPoint touchEndPoint;        //记录touch终点坐标
@property (assign, nonatomic) CGFloat sliderBeginValue;     //记录slider开始值

@property (strong, nonatomic) NSTimer *timer;               //计时器
@property (assign, atomic) NSInteger noOperationSeconds; //没有任何操作的秒数(有操作的时候置0)

@end

@implementation SZMoviePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self prefersStatusBarHidden];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupAvPlayer];
    
    [self.view addSubview:self.topView];
    
    [self.view addSubview:self.bottomView];
    
    [self setupSubViewsFrame];
    
    //屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenFrameChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    //添加视频播放完毕通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    //开启计时器
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(keepTime:) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)keepTime:(NSTimer*)timer
{
    _noOperationSeconds++;
    
    if (_noOperationSeconds > 5) {
        [self hideTopAndBottomView];
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        //默认直接开始播放
        _played = YES;
        _isShowTopAndBottomView = YES;
        
    }
    return self;
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

#pragma mark - 播放器主体
- (void)setupAvPlayer
{
    AVAudioSession *audioSesstion = [AVAudioSession sharedInstance];
    [audioSesstion setCategory:AVAudioSessionCategoryPlayback error:nil];
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:@"http://v.jxvdy.com/sendfile/w5bgP3A8JgiQQo5l0hvoNGE2H16WbN09X-ONHPq3P3C1BISgf7C-qVs6_c8oaw3zKScO78I--b0BGFBRxlpw13sf2e54QA"]];
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    //监听属性
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    _player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:_playerLayer];
}

#pragma mark - APlayerItem属性变化
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
            
            // 自定义UISlider外观
            [self customVideoSlider:duration];
            // 监听播放状态
            [self monitoringPlayback:self.playerItem];
            [_player play];
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            [_bottomView.progressView setProgress:timeInterval / _movieTotalDuration];
        }
    }else if ([keyPath isEqualToString:@"NSKeyValueObservingOptionNew"]){
        NSLog(@"aaaaa");
    }
}

#pragma mark - 监听视频播放
- (void)monitoringPlayback:(AVPlayerItem *)playerItem
{
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        if (!weakSelf.isDraggingSlider && !weakSelf.isSlideOnScreen) {
            [weakSelf.bottomView.movieProgressSlider setValue:currentSecond animated:YES];
            NSString *timeString = [weakSelf convertTime:currentSecond];
            weakSelf.bottomView.currentTimeLabel.text = [NSString stringWithFormat:@"%@", timeString];
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
        [weakSelf.bottomView.movieProgressSlider setValue:0.0 animated:YES];
        _bottomView.playButton.selected = NO;
        _played = NO;
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
    _noOperationSeconds = 0;
    _isDraggingSlider = YES;
}
- (void)didEndDragSlider:(UISlider *)movieProgressSlider
{
    _noOperationSeconds = 0;
    _isDraggingSlider = NO;
    CMTime changedTime = CMTimeMake(movieProgressSlider.value, 1);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf.player play];
        _bottomView.playButton.selected = YES;
        _played = YES;
    }];
}
- (void)didDraggingSlider:(UISlider *)movieProgressSlider
{
    _noOperationSeconds = 0;
    //获取滑动到的时间
    CGFloat draggingTime = movieProgressSlider.value;
    NSString *draggingStr = [self convertTime:draggingTime];
    self.bottomView.currentTimeLabel.text = draggingStr;
}
- (void)playOrPause
{
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
}
#pragma mark - 听停止播放
- (void)moviePause
{
    [_player pause];
    _played = NO;
    _bottomView.playButton.selected = NO;
}

#pragma mark - 隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupSubViewsFrame
{
    _topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, topViewH);
    _playerLayer.frame = CGRectMake(0, 0, self.view.layer.bounds.size.width, self.view.layer.bounds.size.height);
    CGFloat bottomViewY = self.view.bounds.size.height - bottomViewH;
    _bottomView.frame = CGRectMake(0, bottomViewY, self.view.bounds.size.width, bottomViewH);
}

- (void)screenFrameChanged:(NSNotification *)notification
{
    [self setupSubViewsFrame];
}


#pragma mark - 关于点击屏幕隐藏上下view
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _noOperationSeconds = 0;
    if (event.allTouches.count == 1) {
        //保存起点位置
        _touchBeginPoint = [[touches anyObject] locationInView:self.view];
        _sliderBeginValue = _bottomView.movieProgressSlider.value;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _noOperationSeconds = 0;
    //判断touch是轻击还是拖动
    _touchEndPoint = [[touches anyObject] locationInView:self.view];
    CGFloat changedX = _touchBeginPoint.x - _touchEndPoint.x;
    CGFloat changedY = _touchBeginPoint.y - _touchEndPoint.y;
    if (_touchEndPoint.x == _touchBeginPoint.x && _touchEndPoint.y == _touchBeginPoint.y) {
        if (_isShowTopAndBottomView) {
            [self hideTopAndBottomView];
        }else{
            [self showTopAndBottomView];
        }
    }else if (fabs(changedX) > fabs(changedY)){
        //水平拖动
        CMTime changedTime = CMTimeMake(_bottomView.movieProgressSlider.value, 1);
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
            [weakSelf.player play];
             _bottomView.playButton.selected = YES;
            _played = YES;
        }];
    }
    _isSlideOnScreen = NO;
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _noOperationSeconds = 0;
    _isSlideOnScreen = YES;
    //记录坐标
    _touchEndPoint = [[touches anyObject] locationInView:self.view];
    
    //改变slider位置
    CGFloat changedX = _touchEndPoint.x - _touchBeginPoint.x;
    CGFloat scale = changedX / self.view.bounds.size.width;
    _bottomView.movieProgressSlider.value = _sliderBeginValue + (_bottomView.movieProgressSlider.maximumValue *scale);
}

- (void)showTopAndBottomView
{
    [UIView animateWithDuration:0.5 animations:^{
        _topView.alpha = 1;
        _bottomView.alpha = 1;
        _isShowTopAndBottomView = YES;
    }];
}
- (void)hideTopAndBottomView
{
    [UIView animateWithDuration:0.5 animations:^{
        _topView.alpha = 0;
        _bottomView.alpha = 0;
        _isShowTopAndBottomView = NO;
    }];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [_timer invalidate];
    _timer = nil;
}


@end
