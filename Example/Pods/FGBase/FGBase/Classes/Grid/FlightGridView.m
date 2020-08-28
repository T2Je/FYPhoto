//
//  FlightGridView.m
//  FYGOMS
//
//  Created by wangkun on 15/9/7.
//  Copyright (c) 2015年 feeyo. All rights reserved.
//

#import "FlightGridView.h"

#define TITLT_TAG 1000
#define CONTENT_TAG 2000



static const CGFloat leftRight_space = 10;    //左右边距
static const CGFloat colum_space = 2; //列间距

@interface FlightGridView ()
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, assign) NSUInteger colum;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSArray *leftArray;
@end


@implementation FlightGridView

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame totalGrid:4 columOfRow:4];
}

- (instancetype)initWithFrame:(CGRect)frame gridColum:(NSInteger)colum {
    return [self initWithFrame:frame totalGrid:colum columOfRow:colum];
}

- (instancetype)initWithFrame:(CGRect)frame totalGrid:(NSUInteger)count columOfRow:(NSUInteger)colum {
    self = [super initWithFrame:frame];
    if (self) {
        _rowSpace = 10;
        _topBottomSpace = 0;
        
        _count = count;
        _colum = colum;
        [self createView];
    }
    return self;
}

- (void)createView {
    _row = _count%_colum == 0 ? (_count/_colum) : (_count/_colum + 1);
    CGFloat width = (self.frame.size.width - leftRight_space * 2 - (colum_space) * (_colum - 1))/_colum;
    CGFloat height = (self.frame.size.height - _topBottomSpace * 2 - _rowSpace * (_row - 1))/_row;
    
    for (int i = 0; i < _count; i++) {
 
        CGFloat orginX = leftRight_space + (colum_space + width) * (i % _colum);
        CGFloat orginY = _topBottomSpace + (height + _rowSpace) * (i / _colum);
        
        UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectIntegral(CGRectMake(orginX, orginY, width, height/2))];
        titleLabel.textColor = self.titleColor ? : [UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1.00];
        titleLabel.font = self.titleFont ? : [UIFont systemFontOfSize:13];
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.minimumScaleFactor = 0.8;
        titleLabel.tag = TITLT_TAG + i;
        if (self.titleAlign) {
            titleLabel.textAlignment = self.titleAlign;
        }
        [self addSubview:titleLabel];
        
        UILabel * contentLabel = [[UILabel alloc] initWithFrame:CGRectIntegral(CGRectMake(orginX, titleLabel.frame.size.height + titleLabel.frame.origin.y, width, height/2))];
        contentLabel.textColor = self.contentColor ? : [UIColor colorWithRed:0.259 green:0.259 blue:0.259 alpha:1.00];
        if (self.contentAlign) {
            contentLabel.textAlignment = self.contentAlign;
        }
        contentLabel.font = self.contentFont ? : [UIFont boldSystemFontOfSize:14];
        contentLabel.tag = CONTENT_TAG + i;
        contentLabel.adjustsFontSizeToFitWidth = YES;
        contentLabel.minimumScaleFactor = 0.6;
        [self addSubview:contentLabel];
    }
}

- (void)reloadViewWith:(NSArray *)titleArray content:(NSArray *)contentArray {
    [self reloadViewWith:titleArray content:contentArray leftFlag:nil];
}

- (void)reloadViewWith:(NSArray *)titleArray content:(NSArray *)contentArray leftFlag:(NSArray *)leftArray {
    if (titleArray.count <= 0) {
        return;
    }
    
    if (titleArray.count != contentArray.count) {
        return;
    }
    
    if (leftArray) {
        if (titleArray.count != leftArray.count) {
            return;
        }
    }
    
    if (contentArray.count != self.count) {
        for (UILabel *label in self.subviews) {
            [label removeFromSuperview];
        }
        _count = contentArray.count;
        if (_colum > _count) {
            _colum = _count;
        }
        [self createView];
    }
    if (leftArray) {
        _leftArray = leftArray;
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
 
    for (int i = 0; i < _count; i++) {
        UILabel * titleLabel = (UILabel *)[self viewWithTag:TITLT_TAG + i];
        UILabel * contentLabel = (UILabel *)[self viewWithTag:CONTENT_TAG + i];
 
        if ([titleArray[i] isKindOfClass:[NSString class]]) {
            titleLabel.text = titleArray[i];
        } else if ([titleArray[i] isKindOfClass:[NSAttributedString class]]) {
            titleLabel.attributedText = (NSAttributedString *)(titleArray[i]);
        }
        
        id contentInfo = contentArray[i];
        if ([contentInfo isKindOfClass:[NSString class]]) {
            contentLabel.text = (NSString *)contentInfo;
        } else if ([contentInfo isKindOfClass:[NSAttributedString class]]) {
            contentLabel.attributedText = (NSAttributedString *)contentInfo;
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat selfwidth = self.frame.size.width;
    CGFloat selfheight = self.frame.size.height;
    if (!self.leftArray) {
        if (selfwidth > 0) {
            NSMutableArray * leftFlag = [NSMutableArray new];
            for (int i = 0; i < _colum; i++) {
                [leftFlag addObject:@((int)(selfwidth/_colum)* i)];
            }
            self.leftArray = leftFlag;
        }
    }
    for (int i = 0; i < _count; i++) {
        UILabel * titleLabel = (UILabel *)[self viewWithTag:TITLT_TAG + i];
        UILabel * contentLabel = (UILabel *)[self viewWithTag:CONTENT_TAG + i];
        CGFloat width = 0;
        CGFloat height = (selfheight - _topBottomSpace * 2 - _rowSpace * (_row - 1))/_row;
        
        int j = i % _colum;
        
        if ((i+1) % _colum != 0) {
            width = [_leftArray[j+1] floatValue] - [_leftArray[j] floatValue];
        } else {
            width = selfwidth - [_leftArray[j] floatValue];
        }
        
        titleLabel.frame = CGRectIntegral(CGRectMake([_leftArray[j] floatValue], titleLabel.frame.origin.y, width, height/2));
        contentLabel.frame = CGRectIntegral(CGRectMake([_leftArray[j] floatValue], titleLabel.frame.origin.y + titleLabel.frame.size.height, width, height/2));
    }
}

- (void)setRowSpace:(CGFloat)rowSpace {
    _rowSpace = rowSpace;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setTopBottomSpace:(CGFloat)topBottomSpace {
    _topBottomSpace = topBottomSpace;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    for (int i = 0; i < _count; i++) {
        UILabel * titleLabel = (UILabel *)[self viewWithTag:TITLT_TAG + i];
        titleLabel.font = titleFont;
    }
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    for (int i = 0; i < _count; i++) {
        UILabel * titleLabel = (UILabel *)[self viewWithTag:TITLT_TAG + i];
        titleLabel.textColor = titleColor;
    }
}

- (void)setTitleAlign:(NSTextAlignment)titleAlign {
    _titleAlign = titleAlign;
    for (int i = 0; i < _count; i++) {
        UILabel * titleLabel = (UILabel *)[self viewWithTag:TITLT_TAG + i];
        titleLabel.textAlignment = titleAlign;
    }
}


- (void)setContentFont:(UIFont *)contentFont {
    _contentFont = contentFont;
    for (int i = 0; i < _count; i++) {
        UILabel * contentLabel = (UILabel *)[self viewWithTag:CONTENT_TAG + i];
        contentLabel.font = contentFont;
    }
}

- (void)setContentColor:(UIColor *)contentColor {
    _contentColor = contentColor;
    for (int i = 0; i < _count; i++) {
        UILabel * contentLabel = (UILabel *)[self viewWithTag:CONTENT_TAG + i];
        contentLabel.textColor = contentColor;
    }
}
    
- (void)setContentAlign:(NSTextAlignment)contentAlign {
    _contentAlign = contentAlign;
    for (int i = 0; i < _count; i++) {
        UILabel * contentLabel = (UILabel *)[self viewWithTag:CONTENT_TAG + i];
        contentLabel.textAlignment = contentAlign;
    }
}
    


@end
