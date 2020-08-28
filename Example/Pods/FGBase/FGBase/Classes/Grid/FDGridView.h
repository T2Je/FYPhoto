//
//  FDGridView.h
//  FYGOMS
//
//  Created by zhmch on 2017/10/16.
//  Copyright © 2017年 feeyo. All rights reserved.
//

@import UIKit;
#import "FDGridItemView.h"


@interface FDGridView : UIView

/// 行间距
@property (nonatomic) CGFloat lineSpacing;
/// 最小列间距
@property (nonatomic) CGFloat minimumInteritemSpacing;
/// item 的大小
@property (nonatomic) CGSize itemSize;

- (void)reloadByGridItems:(NSArray<FDGridItem *> *)items;

@end
