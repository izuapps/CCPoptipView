//
//  CCPoptipView.m
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

#import "CCPoptipView.h"

BOOL _CCSystemVersionEqualToOrGreaterThan(NSString *version) {
	NSString *system = [[UIDevice currentDevice] systemVersion];
	return [system compare:version options:NSNumericSearch] != NSOrderedAscending;
}
NSString *_CCPoptipViewGetHistoryPath() {
	NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	return [docPath stringByAppendingPathComponent:@"PoptipHistory.plist"];
}
CGAffineTransform _CCTransformForOrientation(UIInterfaceOrientation orientation) {
	switch (orientation) {
	case UIInterfaceOrientationLandscapeLeft:
		return CGAffineTransformMakeRotation(-M_PI / 2);
	case UIInterfaceOrientationLandscapeRight:
		return CGAffineTransformMakeRotation(M_PI / 2);
	case UIInterfaceOrientationPortraitUpsideDown:
		return CGAffineTransformMakeRotation(M_PI);
	default:
		return CGAffineTransformIdentity;
	}
}

#define kCCPoptipDefaultWidth 215.0;

@interface CCTouchWindow : UIWindow
@property(nonatomic, weak) id target;
@end

@implementation CCTouchWindow
- (void)becomeKeyWindow {
	[super becomeKeyWindow];
	[self _updateTransform];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(_updateTransform) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)resignKeyWindow {
	[super resignKeyWindow];
	
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[_target touchesBegan:touches withEvent:event];
}
- (void)_updateTransform {
	UIApplication *app = [UIApplication sharedApplication];
	self.transform = _CCTransformForOrientation(app.statusBarOrientation);
}
@end

// Contains NSStrings of CCPoptipView IDs that have been presented
// in the history of the app. This is a persistent list which can
// be cleared using +clearAllPoptipHistory
static NSMutableSet	*_poptipHistory = nil;
static NSMutableArray	*_poptipQueue = nil;
static NSUInteger	_poptipSuppressionCount = 0;

#define kCCPoptipViewTopMargin 2.0

@implementation CCPoptipView {
	CCTouchWindow	*_dismissWindow;
	
	CGSize		_bubbleSize;
	CGPoint		_targetPoint;
	CGFloat		_textHeight;
	CGFloat		_pointerSize;
	BOOL		_hasForwardedTouchEvent;
}

#pragma mark Class methods

+ (void)beginSuppressingPoptips {
	_poptipSuppressionCount++;
}
+ (void)endSuppressingPoptips {
	if (!_poptipSuppressionCount) // Don't overflow
		return;
	
	if (!--_poptipSuppressionCount)
		[_poptipQueue[0] _presentAnimated:YES];
}
+ (BOOL)poptipHasBeenPresentedWithID:(NSString *)string {
	if (!_poptipHistory) {
		NSString *path = _CCPoptipViewGetHistoryPath();
		
		NSArray *plist = [NSArray arrayWithContentsOfFile:path];
		if ([plist count])
			_poptipHistory = [[NSMutableSet alloc] initWithArray:plist];
		else
			_poptipHistory = [[NSMutableSet alloc] initWithCapacity:10];
	}
	return [_poptipHistory containsObject:string];
}
+ (BOOL)canClearPoptipHistory {
	return [_poptipHistory count] ? YES : NO;
}
+ (void)clearPoptipHistory {
	NSString *path = _CCPoptipViewGetHistoryPath();
	_poptipHistory = nil;
	
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager removeItemAtPath:path error:nil])
		NSLog(@"Error clearing poptip history");
}

#pragma mark Lifecycle

- (instancetype)init {
	return [self initWithFrame:CGRectZero];
}
- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code
		self.opaque = NO;
		
		_borderWidth = 1.0;
		_contentPadding = 2.0;
		_cornerRadius = 10.0;
		_pointerSize = 12.0;
		_poptipWidth = kCCPoptipDefaultWidth;
		
		_borderColor = [UIColor blackColor];
		_poptipColor = [UIColor colorWithRed:0.243 green:0.235 blue:0.604 alpha:1.0];
		_preferredPointDirection = CCPoptipPointDirectionAny;
		_textAlignment = NSTextAlignmentCenter;
		_textColor = [UIColor whiteColor];
		_textFont = [UIFont boldSystemFontOfSize:14.0];
	}
	return self;
}
- (instancetype)initWithMessage:(NSString *)string {
	self = [self initWithFrame:CGRectZero];
	self.message = string;
	return self;
}

#pragma mark Getters & setters

- (void)setCustomView:(UIView *)newValue {
	[_customView removeFromSuperview];
	[self addSubview:newValue];
	
	_customView = newValue;
}

#pragma mark Layout

- (CGRect)bubbleFrame {
	CGFloat bubbleY = _pointDirection == CCPoptipPointDirectionUp ? _targetPoint.y + _pointerSize : _targetPoint.y - _pointerSize - _bubbleSize.height;
	return CGRectMake(2.0, bubbleY, _bubbleSize.width, _bubbleSize.height);
}
- (CGRect)contentFrame {
	CGRect rect = self.bubbleFrame;
	return CGRectMake(rect.origin.x + _cornerRadius, rect.origin.y + _cornerRadius, rect.size.width - _cornerRadius * 2, rect.size.height - _cornerRadius * 2);
}
- (void)layoutSubviews {
	[super layoutSubviews];
	
	if (_customView) {
		CGRect viewRect = [self bubbleFrame];
		viewRect.origin.x += _cornerRadius;
		viewRect.origin.y += _cornerRadius;
		viewRect.size.height -= _cornerRadius * 2.0;
		viewRect.size.width -= _cornerRadius * 2.0;
		
		// Adjust for text
		if (_textHeight)
			viewRect.origin.y += _textHeight + 4.0;
		
		[_customView setFrame:viewRect];
	}
}
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0); // black
	CGContextSetLineWidth(context, _borderWidth);
	
	CGMutablePathRef bubblePath = CGPathCreateMutable();
	CGPathMoveToPoint(bubblePath, NULL, _targetPoint.x, _targetPoint.y); // Move to the target point
	
	CGRect frame = self.bubbleFrame;
	CGPoint origin = frame.origin; CGSize size = frame.size;
	if (_pointDirection == CCPoptipPointDirectionUp) {
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x + _pointerSize, _targetPoint.y + _pointerSize);
		
		CGPathAddArcToPoint(bubblePath, NULL, origin.x + size.width, origin.y, origin.x + size.width, origin.y + _cornerRadius, _cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL, origin.x + size.width, origin.y + size.height, origin.x + size.width - _cornerRadius, origin.y + size.height, _cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL, origin.x, origin.y + size.height, origin.x, origin.y + size.height - _cornerRadius, _cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL, origin.x, origin.y, origin.x + _cornerRadius, origin.y, _cornerRadius);
		
		// This can cause a small rendering artifact when the pointer is on the edge of the bubble
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x - _pointerSize, _targetPoint.y + _pointerSize);
	}
	else {
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x - _pointerSize, _targetPoint.y - _pointerSize);
		
		CGPathAddArcToPoint(bubblePath, NULL, origin.x, origin.y + size.height, origin.x, origin.y + size.height - _cornerRadius, _cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL, origin.x, origin.y, origin.x + _cornerRadius, origin.y, _cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL, origin.x + size.width, origin.y, origin.x + size.width, origin.y + _cornerRadius, _cornerRadius);
		CGPathAddArcToPoint(bubblePath, NULL, origin.x + size.width, origin.y + size.height, origin.x + size.width - _cornerRadius, origin.y + size.height, _cornerRadius);
		
		// This can cause a small rendering artifact when the pointer is on the edge of the bubble
		CGPathAddLineToPoint(bubblePath, NULL, _targetPoint.x + _pointerSize, _targetPoint.y - _pointerSize);
	}
	CGPathCloseSubpath(bubblePath);
	
	// Draw shadow
	CGContextAddPath(context, bubblePath);
	CGContextSaveGState(context);
	CGContextSetShadow(context, CGSizeMake(0.0, 3.0), 5);
	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.9);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	// Draw clipped background gradient
	CGContextAddPath(context, bubblePath);
	CGContextClip(context);
	
	// On iOS 7 and later, just do a flat color
	if (_CCSystemVersionEqualToOrGreaterThan(@"7.0")) {
		[_poptipColor setFill];
		UIRectFill(self.bounds);
	}
	// On earlier iOSes, do a gradient
	else {
		CGColorRef bgColor = [_poptipColor CGColor];
		int numComponents = CGColorGetNumberOfComponents(bgColor);
		const CGFloat *components = CGColorGetComponents(bgColor);
		
		CGFloat red, green, blue, alpha;
		if (numComponents == 2) {
			red = components[0];
			green = components[0];
			blue = components[0];
			alpha = components[1];
		}
		else {
			red = components[0];
			green = components[1];
			blue = components[2];
			alpha = components[3];
		}
		CGFloat colorList[] = {
			// red, green, blue, alpha
			red * 1.16, green * 1.16, blue * 1.16, alpha,
			red * 1.16, green * 1.16, blue * 1.16, alpha,
			red * 1.08, green * 1.08, blue * 1.08, alpha,
			red, green, blue, alpha,
			red, green, blue, alpha
		};
		CGFloat locationList[] = { 0.0, 0.4, 0.5, 0.6, 1.0 };
		CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
		CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorSpace, colorList, locationList, 5);
		
		CGPoint endPoint = CGPointMake(0.0, CGRectGetMaxY(self.bounds));
		CGContextDrawLinearGradient(context, myGradient, CGPointZero, endPoint, 0);
		CGGradientRelease(myGradient);
		CGColorSpaceRelease(myColorSpace);
	}
	
	// Draw Border
	[_borderColor setStroke];
	CGContextAddPath(context, bubblePath);
	CGContextDrawPath(context, kCGPathStroke);
	CGPathRelease(bubblePath);
	
	// Draw text
	if (_message) {
		[_textColor set];
		
		CGRect textRect = [self contentFrame];
		textRect.size.height = _textHeight; // There may be a custom view taking up space
		[_message drawInRect:textRect withFont:_textFont lineBreakMode:NSLineBreakByWordWrapping alignment:_textAlignment];
	}
}
- (void)presentAnimated:(BOOL)animated {
	if (!_poptipQueue)
		_poptipQueue = [[NSMutableArray alloc] initWithCapacity:10];
	
	if ([_poptipID length]) {
		[_poptipHistory addObject:_poptipID];
		CCSavePropertyListWithName([_poptipHistory allObjects], @"PoptipHistory");
	}
	
	[_poptipQueue addObject:self];
	if (!_poptipSuppressionCount && [_poptipQueue count] == 1)
		[self _presentAnimated:animated];
}
- (void)finaliseDismiss {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if (_dismissWindow) {
		[_dismissWindow removeFromSuperview];
		_dismissWindow = nil;
	}
	if ([_poptipQueue count])
		[_poptipQueue removeObjectAtIndex:0];
	if (!_poptipSuppressionCount && [_poptipQueue count])
		[_poptipQueue[0] _presentAnimated:YES];
	
	[self removeFromSuperview];
	
	_targetObject = nil;
}
- (void)dismissAnimated:(BOOL)animated {
	if (!animated) {
		[self finaliseDismiss];
		return;
	}
	
	// animate to a bigger size
	[UIView animateWithDuration:0.1 animations:^{
		self.alpha = 0.5;
		self.transform = CGAffineTransformMakeScale(1.1, 1.1);
	} completion:^(BOOL finished) {
		// at the end set to normal size
		[UIView animateWithDuration:0.15 animations:^{
			self.alpha = 0.0;
			self.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
		} completion:^(BOOL finished) {
			[self finaliseDismiss];
		}];
	}];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_hasForwardedTouchEvent)
		return;
	
	// If we have an interactive custom view, don't dismiss
	if (_customView.userInteractionEnabled) {
		NSSet *subset = [event touchesForView:_customView];
		if ([subset count]) {
			_hasForwardedTouchEvent = YES;
			dispatch_async(dispatch_get_main_queue(), ^{
				_hasForwardedTouchEvent = NO;
			});
			[_customView touchesBegan:subset withEvent:event];
			return;
		}
	}
	[self dismissAnimated:YES];
	if (_dismissalBlock)
		_dismissalBlock(self);
}

#pragma mark Internal

- (void)_autodismissAnimated:(BOOL)animated {
	[self dismissAnimated:animated];
	if (_dismissalBlock)
		_dismissalBlock(self);
}
- (void)_presentAnimated:(BOOL)animated {
	UIView *targetView = [_targetObject isMemberOfClass:[UIBarButtonItem class]] ? [_targetObject view] : _targetObject;
	
	// If we want to dismiss the bubble when the user taps anywhere,
	// we need to insert an invisible button over the background.
	_dismissWindow = [[CCTouchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_dismissWindow.backgroundColor = [UIColor clearColor];
	_dismissWindow.opaque = NO;
	_dismissWindow.target = self;
	_dismissWindow.transform = targetView.window.transform;
	_dismissWindow.windowLevel = UIWindowLevelAlert;
	[_dismissWindow makeKeyAndVisible];
	
	CGRect containerFrame = _dismissWindow.frame;
	CGSize containerSize = _dismissWindow.bounds.size;
	CGFloat targetHeight = targetView.bounds.size.height;
	[_dismissWindow addSubview:self];
	
	// For autodismissal
	if (_autodismissInterval > 0.0)
		[self performSelector:@selector(_autodismissAnimated:) withObject:@(animated) afterDelay:_autodismissInterval];
	
	CGSize contentSize = CGSizeZero;
	if (_message) {
		CGFloat maxHeight = containerFrame.size.height;
		contentSize = [_message sizeWithFont:_textFont constrainedToSize:CGSizeMake(_poptipWidth, maxHeight) lineBreakMode:NSLineBreakByWordWrapping];
		
		// The custom view will be shown below the text
		_textHeight = contentSize.height;
		if (_customView) {
			CGSize viewSize = _customView.frame.size;
			contentSize.height += viewSize.height + 4.0;
			contentSize.width = MAX(contentSize.width, viewSize.width);
		}
	}
	else if (_customView)
		contentSize = _customView.frame.size;
	
	_bubbleSize = CGSizeMake(contentSize.width + _cornerRadius * 2, contentSize.height + _cornerRadius * 2);
	
	UIView *targetParent = targetView.superview;
	CGPoint targetRelativeOrigin = [targetParent convertPoint:targetView.frame.origin toView:_dismissWindow];
	
	CGFloat pointerY;	// Y coordinate of pointer target (within containerView)
	if (targetRelativeOrigin.y + targetHeight < containerFrame.origin.y) {
		pointerY = 0.0;
		_pointDirection = CCPoptipPointDirectionUp;
	}
	else if (targetRelativeOrigin.y > containerFrame.origin.y + containerSize.height) {
		pointerY = containerSize.height;
		_pointDirection = CCPoptipPointDirectionDown;
	}
	else {
		_pointDirection = _preferredPointDirection;
		CGPoint targetOriginInContainer = [targetView convertPoint:CGPointZero toView:_dismissWindow];
		CGFloat sizeBelow = containerSize.height - targetOriginInContainer.y;
		
		if (_pointDirection == CCPoptipPointDirectionAny) {
			if (sizeBelow > targetOriginInContainer.y) {
				pointerY = targetOriginInContainer.y + targetHeight;
				_pointDirection = CCPoptipPointDirectionUp;
			}
			else {
				pointerY = targetOriginInContainer.y;
				_pointDirection = CCPoptipPointDirectionDown;
			}
		}
		else if (_pointDirection == CCPoptipPointDirectionDown)
			pointerY = targetOriginInContainer.y;
		else
			pointerY = targetOriginInContainer.y + targetHeight;
	}
	
	// This seems to be where the problem is
	CGFloat x_p = [_dismissWindow convertPoint:targetView.center fromView:targetParent].x;
	CGFloat x_b = x_p - roundf(_bubbleSize.width / 2);
	if (x_b < _contentPadding)
		x_b = _contentPadding;
	
	CGFloat W = containerSize.width;
	if (x_b + _bubbleSize.width + _contentPadding > W)
		x_b = W - _bubbleSize.width - _contentPadding;
	
	if (x_p - _pointerSize < x_b + _cornerRadius)
		x_p = x_b + _cornerRadius + _pointerSize;
	
	if (x_p + _pointerSize > x_b + _bubbleSize.width - _cornerRadius)
		x_p = x_b + _bubbleSize.width - _cornerRadius - _pointerSize;
	
	CGFloat fullHeight = _bubbleSize.height + _pointerSize + 10.0, y_b;
	if (_pointDirection == CCPoptipPointDirectionUp) {
		y_b = pointerY + kCCPoptipViewTopMargin;
		_targetPoint = CGPointMake(x_p - x_b, 0);
	}
	else {
		y_b = pointerY - fullHeight;
		_targetPoint = CGPointMake(x_p - x_b, fullHeight - 2.0);
	}
	
	// For Motion Effects in iOS 7
	if (_CCSystemVersionEqualToOrGreaterThan(@"7.0")) {
		UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
		
		// Tilt up/down, left/right by a maximum of 10 pixels
		UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:0];
		UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:1];
		effectX.minimumRelativeValue = @(-10.0);
		effectX.maximumRelativeValue = @10.0;
		effectY.minimumRelativeValue = @(-10.0);
		effectY.maximumRelativeValue = @10.0;
		
		group.motionEffects = @[ effectX, effectY ];
		[self addMotionEffect:group];
	}
	
	CGRect finalFrame = CGRectMake(x_b - _contentPadding, y_b, _bubbleSize.width + _contentPadding * 2, fullHeight);
	if (animated) {
		self.alpha = 0.5;
		self.frame = finalFrame;
		self.transform = CGAffineTransformMakeScale(0.75, 0.75); // start a little smaller
		
		// animate to a bigger size
		[UIView animateWithDuration:0.15 animations:^{
			self.alpha = 1.0;
			self.transform = CGAffineTransformMakeScale(1.1, 1.1);
		} completion:^(BOOL finished) {
			// at the end set to normal size
			[UIView animateWithDuration:0.1 animations:^{
				self.transform = CGAffineTransformIdentity;
			}];
		}];
	}
	else {
		// Not animated
		[self setNeedsDisplay];
		self.frame = finalFrame;
	}
}
@end
