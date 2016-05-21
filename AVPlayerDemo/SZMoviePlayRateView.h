//
//  SZMoviePlayRateView.h
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/20.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SZMoviePlayRateView : UIView

@property (strong, nonatomic) UILabel *timeLabel;

@property (strong, nonatomic) UILabel *durationLabel;

/**
 *  是否正在快进
 */
@property (assign, nonatomic) BOOL isGoForward;

@end
