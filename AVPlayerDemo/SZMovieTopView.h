//
//  SZMovieTopView.h
//  AVPlayerDemo
//
//  Created by 又土又木 on 16/5/17.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SZMovieTopView;
@protocol  SZMovieTopViewDelegate<NSObject>

@optional
- (void)didTapMovieTopView:(SZMovieTopView *)topView index:(NSInteger)index;

@end

@interface SZMovieTopView : UIView

@property (assign, nonatomic) id<SZMovieTopViewDelegate> delegate;

@end
