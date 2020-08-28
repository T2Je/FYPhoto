//
//  FDGridView.m
//  FYGOMS
//
//  Created by zhmch on 2017/10/16.
//  Copyright © 2017年 feeyo. All rights reserved.
//

#import "FDGridView.h"

static NSInteger const FDGridItemViewTag = 1000;

@implementation FDGridView {
    NSArray<FDGridItem *> *_gridItems;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _lineSpacing = 10;
        _minimumInteritemSpacing = 10;
        _itemSize = CGSizeMake(90, 56);
    }
    return self;
}

- (void)layoutSubviews {
    [self layoutGridItems];
}

- (void)setItemSize:(CGSize)itemSize {
    _itemSize = itemSize;
    [self setNeedsLayout];
}

- (void)setMinimumInteritemSpacing:(CGFloat)minimumInteritemSpacing {
    _minimumInteritemSpacing = minimumInteritemSpacing;
    [self setNeedsLayout];
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    _lineSpacing = lineSpacing;
    [self setNeedsLayout];
}

- (void)reloadByGridItems:(NSArray<FDGridItem *> *)items {    
    if (_gridItems.count == items.count) {
        for (NSInteger index = 0; index < items.count; index ++) {
            [(FDGridItemView *)[self viewWithTag:FDGridItemViewTag + index] setGridItem:items[index]];
        }
    } else if (_gridItems.count > items.count) {
        for (NSInteger index = 0; index < _gridItems.count; index ++) {
            if (index < items.count) {
                [(FDGridItemView *)[self viewWithTag:FDGridItemViewTag + index] setGridItem:items[index]];
            } else {
                [[self viewWithTag:FDGridItemViewTag + index] removeFromSuperview];
            }
        }
    } else {
        for (NSInteger index = 0; index < items.count; index ++) {
            if (index < _gridItems.count) {
                [(FDGridItemView *)[self viewWithTag:FDGridItemViewTag + index] setGridItem:items[index]];
            } else {
                Class aClass = NSClassFromString(items[index].gridItemViewClassName);
                FDGridItemView *itemView = [[aClass alloc] initWithFrame:CGRectMake(0, 0, _itemSize.width, _itemSize.height)];
                itemView.tag = FDGridItemViewTag + index;
                itemView.gridItem = items[index];
                [self addSubview:itemView];
            }
        }
    }
    
    _gridItems = items;
    
    [self setNeedsLayout];
}

- (void)layoutGridItems {
    CGFloat width = self.bounds.size.width;
    NSInteger itemCountForRow = (width + _minimumInteritemSpacing)/(_itemSize.width + _minimumInteritemSpacing);
    if (itemCountForRow > _gridItems.count) {
        itemCountForRow = _gridItems.count;
    }
    CGFloat interitemSpacing = floor((width - _itemSize.width * itemCountForRow)/(itemCountForRow - 1));
    
    for (UIView *view in self.subviews) {
        NSInteger itemColumn = (view.tag - FDGridItemViewTag)%itemCountForRow;
        NSInteger itemRow = (view.tag - FDGridItemViewTag)/itemCountForRow;
        CGFloat x = (_itemSize.width + interitemSpacing) * itemColumn;
        CGFloat y = (_itemSize.height + _lineSpacing) * itemRow;
        view.frame = CGRectMake(x, y, _itemSize.width, _itemSize.height);
    }
}

@end
