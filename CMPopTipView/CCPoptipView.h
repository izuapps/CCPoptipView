//
//  CCPoptipView.h
//
//  Created by Chris Miles on 18/07/10.
//  Copyright (c) Chris Miles 2010-2012.
//  Modified by Colin Chivers 2013.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(uint8_t, CCPoptipPointDirection) {
	CCPoptipPointDirectionAny = 0,
	CCPoptipPointDirectionUp,
	CCPoptipPointDirectionDown,
};

@class CCPoptipView;

@interface CCPoptipView : UIView

// Use these methods to stop poptips from being displayed
// on screen, for example while an alert view is being
// presented. Calls to these methods are nestable. When
// +endSuppressingPoptips is called, any poptips that were
// added to the queue during the suppression will be presented
// in order.
+ (void)beginSuppressingPoptips;
+ (void)endSuppressingPoptips;

// CCPoptipView maintains a persistent list of poptip IDs that
// have already been presented. Use these methods to check the
// list to make sure you're not presenting a poptip twice.
+ (BOOL)poptipHasBeenPresentedWithID:(NSString *)string;
+ (BOOL)canClearPoptipHistory;
+ (void)clearPoptipHistory;

- (instancetype)initWithMessage:(NSString *)string;

@property(nonatomic) NSTimeInterval		autodismissInterval; // Default is zero, meaning never autodismiss
@property(nonatomic) UIColor			*borderColor;
@property(nonatomic) CGFloat			borderWidth;
@property(nonatomic) CGFloat			contentPadding;
@property(nonatomic) CGFloat			cornerRadius;
@property(nonatomic) UIView			*customView;
@property(nonatomic, copy)			void (^dismissalBlock)(CCPoptipView *);
@property(nonatomic) NSString			*message;
@property(nonatomic) UIColor			*poptipColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) NSString			*poptipID; // If set, CCPoptipView will record the dismissal of this poptip in its persistent list
@property(nonatomic) CGFloat			poptipWidth;
@property(nonatomic) id				targetObject; // Either a UIView or a UIBarButtonItem
@property(nonatomic) UITextAlignment		textAlignment;
@property(nonatomic) UIColor			*textColor UI_APPEARANCE_SELECTOR;
@property(nonatomic) UIFont			*textFont;

@property(nonatomic, readonly) CCPoptipPointDirection pointDirection;
@property(nonatomic) CCPoptipPointDirection preferredPointDirection;

- (void)presentAnimated:(BOOL)animated; // targetObject and containerView must be set before this is called
- (void)dismissAnimated:(BOOL)animated;

@end
