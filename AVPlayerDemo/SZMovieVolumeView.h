//
//  SZMovieVolumeView.h
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/20.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SZMovieVolumeView;
@protocol SZMovieVolumeViewDelegate <NSObject>

@optional
- (void)volumeViewDidDragging:(SZMovieVolumeView *)volumeView;

@end

@interface SZMovieVolumeView : UIView

@property (strong, nonatomic) UISlider *volumeSlider;

@property (assign, nonatomic) id<SZMovieVolumeViewDelegate> delegate;

@end
