//
//  FlightGridView.h
//  FYGOMS
//
//  Created by wangkun on 15/9/7.
//  Copyright (c) 2015年 feeyo. All rights reserved.
//

@import UIKit;
 
@interface FlightGridView : UIView

@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *contentColor;
@property (nonatomic, strong) UIFont *contentFont;
@property (nonatomic, assign) NSTextAlignment titleAlign;
@property (nonatomic, assign) NSTextAlignment contentAlign;

@property (nonatomic, assign) CGFloat rowSpace;
@property (nonatomic, assign) CGFloat topBottomSpace;

/**
 多列单行表格

 @param frame 大小
 @param colum 列数
 @return self
 */
- (instancetype)initWithFrame:(CGRect)frame gridColum:(NSInteger)colum;


/**
 多列多行表格

 @param frame size
 @param count 总共多少个
 @param columnOfRow 一行多少列
 @return self
 */
- (instancetype)initWithFrame:(CGRect)frame
                    totalGrid:(NSUInteger)count
                   columOfRow:(NSUInteger)columnOfRow;

- (void)reloadViewWith:(NSArray *)titleArray content:(NSArray *)contentArray;

- (void)reloadViewWith:(NSArray *)titleArray content:(NSArray *)contentArray leftFlag:(NSArray *)leftArray;

 
@end


