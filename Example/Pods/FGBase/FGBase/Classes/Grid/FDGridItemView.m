//
//  FDGridItemView.m
//  FYGOMS
//
//  Created by zhmch on 2017/10/20.
//  Copyright © 2017年 feeyo. All rights reserved.
//

#import "FDGridItemView.h"

@interface FDGridItem ()
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@end

@implementation FDGridItem

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = title;
        _titleFont = [UIFont systemFontOfSize:13];
        _titleColor = [UIColor colorWithRed:0.608 green:0.608 blue:0.608 alpha:1];
    }
    return self;
}

- (void)dealloc {
    _target = nil;
    _action = nil;
}

- (void)setTitle:(NSString *)title {
    if (![_title isEqualToString:title]) {
        _title = [title copy];
        _titleAttributedString = [[NSAttributedString alloc] initWithString:_title attributes:@{NSFontAttributeName: _titleFont, NSForegroundColorAttributeName: _titleColor}];
    }
}

- (NSAttributedString *)titleAttributedString {
    if (!_titleAttributedString) {
        _titleAttributedString = [[NSAttributedString alloc] initWithString:_title attributes:@{NSFontAttributeName: _titleFont, NSForegroundColorAttributeName: _titleColor}];
    }
    return _titleAttributedString;
}

- (NSString *)gridItemViewClassName {
    return @"FDGridItemView";
}

- (void)addTarget:(id)target action:(SEL)action {
    _target = target;
    _action = action;
}

@end

static CGFloat const FDGridItemViewIconWidth = 20;

@implementation FDGridItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleImageView = [[UIImageView alloc] init];
        _titleImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_titleImageView];
    
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.8;
        [self addSubview:_titleLabel];
    }
    return self;
}

- (void)setGridItem:(FDGridItem *)gridItem {
    _gridItem = gridItem;
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat x = 0;
    if (gridItem.titleIcon) {
        _titleImageView.image = gridItem.titleIcon;
        
        CGSize iconSize = _gridItem.titleIcon.size;
        iconSize = CGSizeMake(MIN(iconSize.width, FDGridItemViewIconWidth), MIN(iconSize.height, FDGridItemViewIconWidth));
        _titleImageView.frame = CGRectMake(0, (height/2 - iconSize.height)/2, iconSize.width, iconSize.height);
        x = iconSize.width + 2;
    }
    _titleLabel.attributedText = gridItem.titleAttributedString;
    _titleLabel.frame = CGRectMake(x, 0, width - x, height/2);
    
    if (gridItem.target && gridItem.action) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:gridItem.target action:gridItem.action];
        [self addGestureRecognizer:tap];
    }
}

@end


@implementation FDTextGridItem

- (instancetype)initWithTitle:(NSString *)title content:(NSString *)content {
    self = [super initWithTitle:title];
    if (self) {
        _content = content;
        _contentFont = [UIFont boldSystemFontOfSize:14];
        _contentColor = [UIColor colorWithRed:0.275 green:0.329 blue:0.325 alpha:1.00];
    }
    return self;
}

- (void)setContent:(NSString *)content {
    if (![_content isEqualToString:content]) {
        _content = [content copy];
        _contentAttributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", _content] attributes:@{NSFontAttributeName: _contentFont, NSForegroundColorAttributeName: _contentColor}];
    }
}

- (NSAttributedString *)contentAttributedString {
    if (!_contentAttributedString) {
        _contentAttributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", _content] attributes:@{NSFontAttributeName: _contentFont, NSForegroundColorAttributeName: _contentColor}];
    }
    return _contentAttributedString;
}

- (NSString *)gridItemViewClassName {
    return @"FDTextGridItemView";
}

@end

@implementation FDTextGridItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _contentImageView = [[UIImageView alloc] init];
        _contentImageView.contentMode = UIViewContentModeScaleAspectFit;
        _contentImageView.hidden = YES;
        [self addSubview:_contentImageView];
        
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.adjustsFontSizeToFitWidth = YES;
        _contentLabel.minimumScaleFactor = 0.6;
        [self addSubview:_contentLabel];
    }
    return self;
}

- (void)setGridItem:(FDTextGridItem *)gridItem {
    [super setGridItem:gridItem];
    
    _contentImageView.image = gridItem.contentIcon;
    _contentLabel.attributedText = gridItem.contentAttributedString;
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    if (gridItem.contentIcon) {
        _contentImageView.hidden = NO;
        _contentLabel.hidden = YES;
        
        CGSize iconSize = gridItem.contentIcon.size;
        iconSize = CGSizeMake(MIN(iconSize.width, FDGridItemViewIconWidth), MIN(iconSize.height, FDGridItemViewIconWidth));
        _contentImageView.frame = CGRectMake(gridItem.titleIcon.size.width + 2, (height/2 - iconSize.height)/2 + height/2, iconSize.width, iconSize.height);
    } else {
        _contentImageView.hidden = YES;
        _contentLabel.hidden = NO;
        
        _contentLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, height/2, width - self.titleLabel.frame.origin.x, height/2);
    }
}

@end



@implementation FDInputGridItem

- (instancetype)initWithTitle:(NSString *)title inputText:(NSString *)inputText unit:(NSString *)unit {
    self = [super initWithTitle:title];
    if (self) {
        _inputText = inputText;
        _unit = unit;
    }
    return self;
}

- (NSString *)gridItemViewClassName {
    return @"FDInputGridItemView";
}

@end

static CGFloat const FDInputGridItemViewUnitWidth = 20;
@implementation FDInputGridItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        _inputTextField = [[UITextField alloc] init];
        _inputTextField.textColor = [UIColor colorWithRed:0.635 green:0.635 blue:0.635 alpha:1];
        _inputTextField.borderStyle = UITextBorderStyleRoundedRect;
        _inputTextField.textAlignment = NSTextAlignmentCenter;
        _inputTextField.keyboardType = UIKeyboardTypePhonePad;
        _inputTextField.delegate = self;
        [self addSubview:_inputTextField];
        
        _unitLabel = [[UILabel alloc] init];
        _unitLabel.textColor = [UIColor colorWithRed:66/255.0 green:66/255.0 blue:74/255.0 alpha:1/1.0];
        _unitLabel.textAlignment = NSTextAlignmentCenter;
        _unitLabel.font = [UIFont systemFontOfSize:14];
        _unitLabel.adjustsFontSizeToFitWidth = YES;
        _unitLabel.minimumScaleFactor = 0.6;
        [self addSubview:_unitLabel];
    }
    return self;
}

- (void)setGridItem:(FDInputGridItem *)gridItem {
    [super setGridItem:gridItem];
    
    _inputTextField.text = [NSString stringWithFormat:@"%@", gridItem.inputText];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    if ([(FDInputGridItem *)self.gridItem unit].length == 0) {
        _unitLabel.hidden = YES;
        
        _inputTextField.frame = CGRectMake(0, height/2 + 4, width, height/2 - 8);
        self.titleLabel.frame = CGRectMake(0, 0, width, height/2);
    } else {
        _unitLabel.hidden = NO;
        _unitLabel.text = gridItem.unit;
        
        _unitLabel.frame = CGRectMake(width - FDInputGridItemViewUnitWidth, height/2, FDInputGridItemViewUnitWidth, height/2);
        _inputTextField.frame = CGRectMake(0, height/2 + 4, width - FDInputGridItemViewUnitWidth, height/2 - 8);
        self.titleLabel.frame = CGRectMake(0, 0, width - FDInputGridItemViewUnitWidth, height/2);
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSScanner* scan = [NSScanner scannerWithString:string];
    NSInteger val;
    if (([scan scanInteger:&val] && [scan isAtEnd]) || string.length == 0) {
        NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        [(FDInputGridItem *)self.gridItem setInputText:text];
        if ([(FDInputGridItem *)self.gridItem inputDataChange]) {
            [(FDInputGridItem *)self.gridItem inputDataChange](text);
        }
        return YES;
    } else {
        return NO;
    }
    
}

@end
