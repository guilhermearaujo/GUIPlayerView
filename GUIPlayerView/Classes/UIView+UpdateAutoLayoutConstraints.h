//
//  UIView+UpdateAutoLayoutConstant.h
//  ConstraintsCodeDemo
//
//  Created by Damien Romito on 13/03/2014.
//  Copyright (c) 2014 Damien Romito. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (UpdateAutoLayoutConstraints)

- (BOOL) setConstraintConstant:(CGFloat)constant forAttribute:(NSLayoutAttribute)attribute;
- (CGFloat) constraintConstantforAttribute:(NSLayoutAttribute)attribute;
- (NSLayoutConstraint*) constraintForAttribute:(NSLayoutAttribute)attribute;
- (void)hideView:(BOOL)hidden byAttribute:(NSLayoutAttribute)attribute;
- (void)hideByHeight:(BOOL)hidden;
- (void)hideByWidth:(BOOL)hidden;
- (CGSize) getSize;
- (void)sizeToSubviews;

@end