//
//  FDGridItemView.h
//  FYGOMS
//
//  Created by zhmch on 2017/10/20.
//  Copyright © 2017年 feeyo. All rights reserved.
//

@import UIKit;

#pragma mark - Base
@interface FDGridItem : NSObject

@property (nonatomic, strong) UIImage *titleIcon;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic, strong) NSAttributedString *titleAttributedString;

/// default is FDGridItemView
@property (nonatomic, readonly) NSString *gridItemViewClassName;

- (instancetype)initWithTitle:(NSString *)title;
- (void)addTarget:(id)target action:(SEL)action;

@end

@interface FDGridItemView : UIView
@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) FDGridItem *gridItem;

@end


#pragma mark - Text
@interface FDTextGridItem : FDGridItem

@property (nonatomic, strong) UIImage *contentIcon;

@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) UIFont *contentFont;
@property (nonatomic, strong) UIColor *contentColor;

@property (nonatomic, strong) NSAttributedString *contentAttributedString;

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content NS_DESIGNATED_INITIALIZER;

@end

@interface FDTextGridItemView : FDGridItemView

@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UILabel *contentLabel;

@end


#pragma mark - Input
@interface FDInputGridItem : FDGridItem

@property (nonatomic, strong) UIImage *contentIcon;

@property (nonatomic, copy) NSString *inputText;
@property (nonatomic, copy) NSString *unit;

- (instancetype)initWithTitle:(NSString *)title inputText:(NSString *)inputText unit:(NSString *)unit;

@property (nonatomic, copy) void(^inputDataChange)(NSString *text);

@end

@interface FDInputGridItemView : FDGridItemView <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *inputTextField;
@property (nonatomic, strong) UILabel *unitLabel;

@end
