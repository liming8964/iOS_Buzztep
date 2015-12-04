//
//  Created by Matt Greenfield on 24/05/12
//  Copyright (c) 2012 Big Paua. All rights reserved
//  http://bigpaua.com/
//

#import "MGBox.h"
#import "MGLayoutManager.h"

@implementation MGBox {
  BOOL fixedPositionEstablished;
  BOOL asyncDrawing, asyncDrawOnceing;
}

// MGLayoutBox protocol
@synthesize boxes, parentBox, boxLayoutMode, contentLayoutMode;
@synthesize asyncLayout, asyncLayoutOnce, asyncQueue;
@synthesize margin, topMargin, bottomMargin, leftMargin, rightMargin;
@synthesize padding, topPadding, rightPadding, bottomPadding, leftPadding;
@synthesize attachedTo, replacementFor, sizingMode;
@synthesize fixedPosition, zIndex, layingOut;

// MGLayoutBox protocol optionals
@synthesize tapper, tappable, onTap;
@synthesize swiper, swipable, onSwipe;
@synthesize longPresser, longPressable, onLongPress;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  [self setup];
  return self;
}

- (id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  [self setup];
  return self;
}

+ (id)box {
  MGBox *box = [[self alloc] initWithFrame:CGRectZero];
  return box;
}

+ (id)boxWithSize:(CGSize)size {
  CGRect frame = CGRectMake(0, 0, size.width, size.height);
  MGBox *box = [[self alloc] initWithFrame:frame];
  return box;
}

- (void)setup {
  self.boxLayoutMode = MGBoxLayoutAutomatic;
  self.contentLayoutMode = MGLayoutTableStyle;
  self.sizingMode = MGResizingNone;
}

- (void)layout {
  [MGLayoutManager layoutBoxesIn:self];

  // async draws
  if (self.asyncLayout || self.asyncLayoutOnce) {
    dispatch_async(self.asyncQueue, ^{
      if (self.asyncLayout && !asyncDrawing) {
        asyncDrawing = YES;
        self.asyncLayout();
        asyncDrawing = NO;
      }
      if (self.asyncLayoutOnce && !asyncDrawOnceing) {
        asyncDrawOnceing = YES;
        self.asyncLayoutOnce();
        self.asyncLayoutOnce = nil;
        asyncDrawOnceing = NO;
      }
    });
  }
}

- (void)layoutWithSpeed:(NSTimeInterval)speed
             completion:(Block)completion {
  [MGLayoutManager layoutBoxesIn:self withSpeed:speed completion:completion];

  // async draws
  if (self.asyncLayout || self.asyncLayoutOnce) {
    dispatch_async(self.asyncQueue, ^{
      if (self.asyncLayout && !asyncDrawing) {
        asyncDrawing = YES;
        self.asyncLayout();
        asyncDrawing = NO;
      }
      if (self.asyncLayoutOnce && !asyncDrawOnceing) {
        asyncDrawOnceing = YES;
        self.asyncLayoutOnce();
        self.asyncLayoutOnce = nil;
        asyncDrawOnceing = NO;
      }
    });
  }
}

#pragma mark - Sugar

- (UIImage *)screenshot:(float)scale {
  CGRect frame = CGRectMake(0, 0, self.width + 40, self.height + 40);

  // UIImageView of self
  UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
  [[UIBezierPath bezierPathWithRoundedRect:self.bounds
      cornerRadius:self.layer.cornerRadius] addClip];
  [self.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  UIGraphicsEndImageContext();

  // setup the shadow
  CGFloat cx = roundf(frame.size.width / 2), cy = roundf(frame.size.height / 2);
  cy = (int)self.height % 2 ? cy + 0.5 : cy; // avoid blur
  imageView.center = CGPointMake(cx, cy);
  imageView.layer.backgroundColor = UIColor.clearColor.CGColor;
  imageView.layer.borderColor = [UIColor colorWithWhite:0.65 alpha:0.7].CGColor;
  imageView.layer.borderWidth = 1;
  imageView.layer.cornerRadius = self.layer.cornerRadius;
  imageView.layer.shadowColor = UIColor.blackColor.CGColor;
  imageView.layer.shadowOffset = CGSizeZero;
  imageView.layer.shadowOpacity = 0.2;
  imageView.layer.shadowRadius = 10;

  // final UIImage
  UIView *canvas = [[UIView alloc] initWithFrame:frame];
  [canvas addSubview:imageView];
  UIGraphicsBeginImageContextWithOptions(frame.size, NO, scale);
  [canvas.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *final = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return final;
}

#pragma mark - Interaction

- (void)tapped {
  if (self.onTap) {
    self.onTap();
  }
}

- (void)swiped {
  if (self.onSwipe) {
    self.onSwipe();
  }
}

- (void)longPressed {
  if (self.onLongPress) {
    self.onLongPress();
  }
}

#pragma mark - Setters

- (void)setMargin:(UIEdgeInsets)_margin {
  self.topMargin = _margin.top;
  self.rightMargin = _margin.right;
  self.bottomMargin = _margin.bottom;
  self.leftMargin = _margin.left;
}

- (void)setPadding:(UIEdgeInsets)_padding {
  self.topPadding = _padding.top;
  self.rightPadding = _padding.right;
  self.bottomPadding = _padding.bottom;
  self.leftPadding = _padding.left;
}

- (void)setFixedPosition:(CGPoint)pos {
  self.boxLayoutMode = MGBoxLayoutFixedPosition;
  fixedPositionEstablished = YES;
  fixedPosition = pos;
}

- (void)setAttachedTo:(id)buddy {
  self.boxLayoutMode = MGBoxLayoutAttached;
  attachedTo = buddy;
}

- (void)setTappable:(BOOL)can {
  if (tappable == can) {
    return;
  }
  tappable = can;
  if (can) {
    [self addGestureRecognizer:self.tapper];
  } else if (self.tapper) {
    [self removeGestureRecognizer:self.tapper];
  }
}

- (void)setSwipable:(BOOL)can {
  if (swipable == can) {
    return;
  }
  swipable = can;
  if (can) {
    [self addGestureRecognizer:self.swiper];
  } else if (self.swiper) {
    [self removeGestureRecognizer:self.swiper];
  }
}

- (void)setLongPressable:(BOOL)can {
  if (longPressable == can) {
    return;
  }
  longPressable = can;
  if (can) {
    [self addGestureRecognizer:self.longPresser];
  } else if (self.longPresser) {
    [self removeGestureRecognizer:self.longPresser];
  }
}

- (void)setOnTap:(Block)_onTap {
  onTap = [_onTap copy];
  if (onTap) {
    self.tappable = YES;
  }
}

- (void)setOnSwipe:(Block)_onSwipe {
  onSwipe = [_onSwipe copy];
  if (onSwipe) {
    self.swipable = YES;
  }
}

- (void)setOnLongPress:(Block)_onLongPress {
  onLongPress = _onLongPress;
  if (onLongPress) {
    self.longPressable = YES;
  }
}

#pragma mark - Getters

- (NSMutableOrderedSet *)boxes {
  if (!boxes) {
    boxes = NSMutableOrderedSet.orderedSet;
  }
  return boxes;
}

- (UIEdgeInsets)margin {
  return UIEdgeInsetsMake(self.topMargin, self.leftMargin, self.bottomMargin,
      self.rightMargin);
}

- (UIEdgeInsets)padding {
  return UIEdgeInsetsMake(self.topPadding, self.leftPadding, self.bottomPadding,
      self.rightPadding);
}

- (CGPoint)fixedPosition {
  if (!fixedPositionEstablished) {
    fixedPosition = self.frame.origin;
    fixedPositionEstablished = YES;
  }
  return fixedPosition;
}

- (dispatch_queue_t)asyncQueue {
  if (!asyncQueue) {
    asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  }
  return asyncQueue;
}

#pragma mark - Gesture recognisers

- (UITapGestureRecognizer *)tapper {
  if (!tapper) {
    tapper = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(tapped)];
    tapper.delegate = self;
  }
  return tapper;
}

- (UISwipeGestureRecognizer *)swiper {
  if (!swiper) {
    swiper = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(swiped)];
    swiper.delegate = self;
  }
  return swiper;
}

- (UILongPressGestureRecognizer *)longPresser {
  if (!longPresser) {
    longPresser = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressed)];
  }
  return longPresser;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recogniser
       shouldReceiveTouch:(UITouch *)touch {
  return ![touch.view isKindOfClass:UIControl.class];
}

@end