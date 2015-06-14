//
//  NGCarousel.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 14/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "NGCarousel.h"
#import <objc/message.h>

@interface NGCarousel() {
    UIView *_contentView;
    NSMutableDictionary *_itemViews;
    NSMutableSet *_itemViewPool;
    CGFloat _previousScrollOffset;
    NSInteger _previousItemIndex;
    NSInteger _numberOfVisibleItems;
    CGFloat _itemWidth;
    CGFloat _offsetMultiplier;
    CGFloat _startOffset;
    CGFloat _endOffset;
    NSTimeInterval _scrollDuration;
    NSTimeInterval _startTime;
    NSTimeInterval _lastTime;
    CGFloat _startVelocity;
    NSTimer *_timer;
    CGFloat _previousTranslation;
    BOOL _didDrag;
    NSTimeInterval _toggleTime;
    CGFloat _perspective;
    CGFloat _decelerationRate;
    CGFloat _scrollSpeed;
    CGFloat _bounceDistance;
    BOOL _bounces;
    CGFloat _scrollOffset;
    CGSize _contentOffset;
    CGSize _viewpointOffset;
    NSInteger _numberOfItems;
    UIView *_currentItemView;
    NSArray *_indexesForVisibleItems;
    NSArray *_visibleItemViews;
    CGFloat _toggle;
    CGFloat _autoscroll;
    BOOL _stopAtItemBoundary;
    BOOL _scrollToItemBoundary;
    BOOL _ignorePerpendicularSwipes;
    BOOL _centerItemWhenSelected;
}
@property (nonatomic, assign, getter = isWrapEnabled) BOOL wrapEnabled;
@property (nonatomic, assign, getter = isDragging) BOOL dragging;
@property (nonatomic, assign, getter = isDecelerating) BOOL decelerating;
@property (nonatomic, assign, getter = isScrolling) BOOL scrolling;
@property (nonatomic, assign, getter = isScrollEnabled) BOOL scrollEnabled;
@property (nonatomic, assign, getter = isPagingEnabled) BOOL pagingEnabled;
@property (nonatomic, assign, getter = isVertical) BOOL vertical;
@property (nonatomic, assign) NSInteger currentItemIndex;

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, NGCarousel *self);

@end
@implementation NGCarousel

#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setUp];
        if (self.superview) {
            [self startAnimation];
        }
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    _contentView.frame = self.bounds;
    [self layOutItemViews];
}

- (void)dealloc {
    [self stopAnimation];
}

- (void)setUp {
    _decelerationRate = 0.95;
    _scrollEnabled = YES;
    _bounces = YES;
    _offsetMultiplier = 1.0;
    _perspective = -1.0/500.0;
    _contentOffset = CGSizeZero;
    _viewpointOffset = CGSizeZero;
    _scrollSpeed = 1.0;
    _bounceDistance = 1.0;
    _stopAtItemBoundary = YES;
    _scrollToItemBoundary = YES;
    _ignorePerpendicularSwipes = YES;
    _centerItemWhenSelected = YES;
    
    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //add pan gesture recogniser
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    panGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:panGesture];
    
    //add tap gesture recogniser
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tapGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
    [_contentView addGestureRecognizer:tapGesture];
    
    //set up accessibility
    self.accessibilityTraits = UIAccessibilityTraitAllowsDirectInteraction;
    self.isAccessibilityElement = YES;
    
    
    [self addSubview:_contentView];
    
    if (_dataSource) {
        [self reloadData];
    }
}

- (void)setDataSource:(id<NGCarouselDataSource>)dataSource {
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        if (_dataSource) {
            [self reloadData];
        }
    }
}

- (void)setDelegate:(id<NGCarouselDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = delegate;
        if (_delegate && _dataSource) {
            [self setNeedsLayout];
        }
    }
}

- (void)setVertical:(BOOL)vertical {
    if (_vertical != vertical) {
        _vertical = vertical;
        [self layOutItemViews];
    }
}

- (void)setScrollOffset:(CGFloat)scrollOffset {
    _scrolling = NO;
    _decelerating = NO;
    _startOffset = scrollOffset;
    _endOffset = scrollOffset;
    
    if (fabs(_scrollOffset - scrollOffset) > 0.0) {
        _scrollOffset = scrollOffset;
        [self depthSortViews];
        [self didScroll];
    }
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex {
    [self setScrollOffset:currentItemIndex];
}

- (void)setPerspective:(CGFloat)perspective {
    _perspective = perspective;
    [self transformItemViews];
}

- (void)setViewpointOffset:(CGSize)viewpointOffset{
    if (!CGSizeEqualToSize(_viewpointOffset, viewpointOffset)) {
        _viewpointOffset = viewpointOffset;
        [self transformItemViews];
    }
}

- (void)setContentOffset:(CGSize)contentOffset {
    if (!CGSizeEqualToSize(_contentOffset, contentOffset)) {
        _contentOffset = contentOffset;
        [self layOutItemViews];
    }
}

- (void)setAutoscroll:(CGFloat)autoscroll {
    _autoscroll = autoscroll;
    if (autoscroll != 0.0) {
        [self startAnimation];
    }
}

- (void)pushAnimationState:(BOOL)enabled {
    [CATransaction begin];
    [CATransaction setDisableActions:!enabled];
}

- (void)popAnimationState {
    [CATransaction commit];
}

#pragma mark - View management

- (NSArray *)indexesForVisibleItems {
    return [[_itemViews allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItemViews {
    NSArray *indexes = [self indexesForVisibleItems];
    return [_itemViews objectsForKeys:indexes notFoundMarker:[NSNull null]];
}

- (UIView *)itemViewAtIndex:(NSInteger)index {
    return _itemViews[@(index)];
}

- (UIView *)currentItemView {
    return [self itemViewAtIndex:self.currentItemIndex];
}

- (NSInteger)indexOfItemView:(UIView *)view {
    NSInteger index = [[_itemViews allValues] indexOfObject:view];
    if (index != NSNotFound) {
        return [[_itemViews allKeys][index] integerValue];
    }
    return NSNotFound;
}

- (NSInteger)indexOfItemViewOrSubview:(UIView *)view {
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound && view != nil && view != _contentView) {
        return [self indexOfItemViewOrSubview:view.superview];
    }
    return index;
}

- (UIView *)itemViewAtPoint:(CGPoint)point {
    for (UIView *view in [[[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self] reverseObjectEnumerator]) {
        if ([view.superview.layer hitTest:point]) {
            return view;
        }
    }
    return nil;
}

- (void)setItemView:(UIView *)view forIndex:(NSInteger)index {
    _itemViews[@(index)] = view;
}

- (void)removeViewAtIndex:(NSInteger)index {
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[_itemViews count] - 1];
    for (NSNumber *number in [self indexesForVisibleItems]) {
        NSInteger i = [number integerValue];
        if (i < index) {
            newItemViews[number] = _itemViews[number];
        } else if (i > index) {
            newItemViews[@(i - 1)] = _itemViews[number];
        }
    }
    _itemViews = newItemViews;
}

- (void)insertView:(UIView *)view atIndex:(NSInteger)index {
    NSMutableDictionary *newItemViews = [NSMutableDictionary dictionaryWithCapacity:[_itemViews count] + 1];
    for (NSNumber *number in [self indexesForVisibleItems]) {
        NSInteger i = [number integerValue];
        if (i < index) {
            newItemViews[number] = _itemViews[number];
        } else {
            newItemViews[@(i + 1)] = _itemViews[number];
        }
    }
    
    if (view) {
        [self setItemView:view forIndex:index];
    }
    _itemViews = newItemViews;
}

#pragma mark - View layout

- (CGFloat)alphaForItemWithOffset:(CGFloat)offset {
    CGFloat fadeMin = -INFINITY;
    CGFloat fadeMax = INFINITY;
    CGFloat fadeRange = 1.0;
    CGFloat fadeMinAlpha = 0.0;

    CGFloat factor = 0.0;
    if (offset > fadeMax) {
        factor = offset - fadeMax;
    } else if (offset < fadeMin) {
        factor = fadeMin - offset;
    }
    return 1.0 - MIN(factor, fadeRange) / fadeRange * (1.0 - fadeMinAlpha);
}

- (CATransform3D)transformForItemViewWithOffset:(CGFloat)offset {
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = _perspective;
    transform = CATransform3DTranslate(transform, -_viewpointOffset.width, -_viewpointOffset.height, 0.0);
    //perform transform
    CGFloat tilt = 0.9f;
    CGFloat spacing = 0.25;
    CGFloat clampedOffset = MAX(-1.0, MIN(1.0, offset));
    
    if (_toggle > 0.0) {
        if (offset <= -0.5) {
            clampedOffset = -1.0;
        } else if (offset <= 0.5) {
            clampedOffset = -_toggle;
        } else if (offset <= 1.5) {
            clampedOffset = 1.0 - _toggle;
        }
    } else {
        if (offset > 0.5) {
            clampedOffset = 1.0;
        } else if (offset > -0.5) {
            clampedOffset = -_toggle;
        } else if (offset > -1.5) {
            clampedOffset = - 1.0 - _toggle;
        }
    }
    
    CGFloat x = (clampedOffset * 0.5 * tilt + offset * spacing) * _itemWidth;
    CGFloat z = fabs(clampedOffset) * -_itemWidth * 0.5;
    
    if (_vertical) {
        transform = CATransform3DTranslate(transform, 0.0, x, z);
        return CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, -1.0, 0.0, 0.0);
    } else {
        transform = CATransform3DTranslate(transform, x, 0.0, z);
        return CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, 0.0, 1.0, 0.0);
    }
}

NSComparisonResult compareViewDepth(UIView *view1, UIView *view2, NGCarousel *self) {
    //compare depths
    CATransform3D t1 = view1.superview.layer.transform;
    CATransform3D t2 = view2.superview.layer.transform;
    CGFloat z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
    CGFloat z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
    CGFloat difference = z1 - z2;
    
    //if depths are equal, compare distance from current view
    if (difference == 0.0) {
        CATransform3D t3 = [self currentItemView].superview.layer.transform;
        if (self.vertical) {
            CGFloat y1 = t1.m12 + t1.m22 + t1.m32 + t1.m42;
            CGFloat y2 = t2.m12 + t2.m22 + t2.m32 + t2.m42;
            CGFloat y3 = t3.m12 + t3.m22 + t3.m32 + t3.m42;
            difference = fabs(y2 - y3) - fabs(y1 - y3);
        } else {
            CGFloat x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
            CGFloat x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
            CGFloat x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
            difference = fabs(x2 - x3) - fabs(x1 - x3);
        }
    }
    return (difference < 0.0)? NSOrderedAscending: NSOrderedDescending;
}

- (void)depthSortViews {
    for (UIView *view in [[_itemViews allValues] sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))compareViewDepth context:(__bridge void *)self]) {
        [_contentView bringSubviewToFront:view.superview];
    }
}

- (CGFloat)offsetForItemAtIndex:(NSInteger)index {
    //calculate relative position
    CGFloat offset = index - _scrollOffset;
    if (_wrapEnabled) {
        if (offset > _numberOfItems/2.0) {
            offset -= _numberOfItems;
        } else if (offset < -_numberOfItems/2.0) {
            offset += _numberOfItems;
        }
    }
    return offset;
}

- (UIView *)containView:(UIView *)view {
    //set item width
    if (!_itemWidth) {
        _itemWidth = _vertical? view.bounds.size.height: view.bounds.size.width;
    }
    //set container frame
    CGRect frame = view.bounds;
    frame.size.width = _vertical? frame.size.width: _itemWidth;
    frame.size.height = _vertical? _itemWidth: frame.size.height;
    UIView *containerView = [[UIView alloc] initWithFrame:frame];

    //set view frame
    frame = view.frame;
    frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0;
    frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0;
    view.frame = frame;
    [containerView addSubview:view];
    containerView.layer.opacity = 0;
    
    return containerView;
}

- (void)transformItemView:(UIView *)view atIndex:(NSInteger)index {
    CGFloat offset = [self offsetForItemAtIndex:index];
    view.superview.layer.opacity = [self alphaForItemWithOffset:offset];
    view.superview.center = CGPointMake(self.bounds.size.width/2.0 + _contentOffset.width,
                                        self.bounds.size.height/2.0 + _contentOffset.height);
    view.superview.userInteractionEnabled = (!_centerItemWhenSelected || index == self.currentItemIndex);
    view.superview.layer.rasterizationScale = [UIScreen mainScreen].scale;
    CGFloat clampedOffset = MAX(-1.0, MIN(1.0, offset));
    if (_decelerating || (_scrolling && !_dragging && !_didDrag) || (_autoscroll && !_dragging) ||
        (!_wrapEnabled && (_scrollOffset < 0 || _scrollOffset >= _numberOfItems - 1))) {
        if (offset > 0){
            _toggle = (offset <= 0.5)? -clampedOffset: (1.0 - clampedOffset);
        } else {
            _toggle = (offset > -0.5)? -clampedOffset: (- 1.0 - clampedOffset);
        }
    }
    
    CATransform3D transform = [self transformForItemViewWithOffset:offset];
    view.superview.layer.transform = transform;
    BOOL showBackfaces = view.layer.doubleSided;
    view.superview.hidden = !(showBackfaces ?: (transform.m33 > 0.0));
}

- (void)transformItemViews {
    for (NSNumber *number in _itemViews) {
        NSInteger index = [number integerValue];
        UIView *view = _itemViews[number];
        [self transformItemView:view atIndex:index];
    }
}

- (void)updateItemWidth {
    _itemWidth = [_delegate carouselItemWidth:self] ?: _itemWidth;
    if (_numberOfItems > 0) {
        if ([_itemViews count] == 0) {
            [self loadViewAtIndex:0];
        }
    }
}

- (void)updateNumberOfVisibleItems {
    CGFloat spacing = 0.25;
    CGFloat width = _vertical ? self.bounds.size.height: self.bounds.size.width;
    CGFloat itemWidth = _itemWidth * spacing;
    _numberOfVisibleItems = ceil(width / itemWidth) + 2;
    _numberOfVisibleItems = MIN(Max_Visible_Items, _numberOfVisibleItems);
    _numberOfVisibleItems = MAX(0, MIN(_numberOfVisibleItems, _numberOfItems));
}

- (NSInteger)circularCarouselItemCount {
    return _numberOfItems;
}

- (void)layOutItemViews {
    if (!_dataSource || !_contentView) {
        return;
    }
    _wrapEnabled = NO;
    [self updateItemWidth];
    [self updateNumberOfVisibleItems];
    _previousScrollOffset = _scrollOffset;
    _offsetMultiplier = 2.0;
    if (!_scrolling && !_decelerating && !_autoscroll) {
        if (_scrollToItemBoundary) {
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        } else {
            _scrollOffset = [self clampedOffset:_scrollOffset];
        }
    }
    [self didScroll];
}

#pragma mark - View queing

- (void)queueItemView:(UIView *)view {
    if (view) {
        [_itemViewPool addObject:view];
    }
}

- (UIView *)dequeueItemView {
    UIView *view = [_itemViewPool anyObject];
    if (view) {
        [_itemViewPool removeObject:view];
    }
    return view;
}

#pragma mark - View loading

- (UIView *)carousel:(NGCarousel *)carouselView index:(NSInteger)index customItemView:(UIView *)view {
    UIImage *image = [_gallaryObject gallaryImage];
    CGFloat radius = 5.0f;
    UILabel *authorLabel = nil;
    UILabel *titleLabel = nil;
    UIImageView *itemImageView = nil;
    UIActivityIndicatorView *indicator = nil;
    UIImageView *checkMarkImageView = nil;
    if (view == nil) {
        CGRect viewRect = CGRectMake(0, 0, 200.0f, 250.0);
        view = [[UIView alloc] initWithFrame:viewRect];
        [view setBackgroundColor:[UIColor whiteColor]];
        
        itemImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewRect.size.width, viewRect.size.width)];
        itemImageView.contentMode = UIViewContentModeScaleToFill;
        [itemImageView setBackgroundColor:[UIColor clearColor]];
        [itemImageView setTag:kImageViewCarouselTag];
        [[itemImageView layer] setCornerRadius:radius];
        [[itemImageView layer] setMasksToBounds:YES];
        [view addSubview:itemImageView];
        
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [itemImageView addSubview:indicator];
        [indicator setCenter:itemImageView.center];
        [indicator startAnimating];
        [indicator setTag:kIndicatorCarouselTag];
        [indicator setHidesWhenStopped:YES];
        
        
        authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(viewRect.size.width/10, viewRect.size.width + itemImageView.frame.origin.y, viewRect.size.width/1.25, (viewRect.size.height - viewRect.size.width)/2)];
        [authorLabel setBackgroundColor:[UIColor clearColor]];
        [authorLabel setAdjustsFontSizeToFitWidth:YES];
        [authorLabel setTextAlignment:NSTextAlignmentCenter];
        [authorLabel setFont:[authorLabel.font fontWithSize:15.0f]];
        [authorLabel setTag:kAuthorLabelCarouselTag];
        [authorLabel setNumberOfLines:2];
        [view addSubview:authorLabel];
        
        
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(viewRect.size.width/10, authorLabel.frame.size.height + authorLabel.frame.origin.y, viewRect.size.width/1.25, (viewRect.size.height - viewRect.size.width)/2)];
        [titleLabel setBackgroundColor:[UIColor clearColor]];
        [titleLabel setNumberOfLines:2];
        [titleLabel setAdjustsFontSizeToFitWidth:YES];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];
        [titleLabel setFont:[titleLabel.font fontWithSize:15.0f]];
        [titleLabel setTag:kTitleLabelCarouselTag];
        [view addSubview:titleLabel];
        
        CGFloat checkWH = 30.0f;
        CGFloat offsetXY = 3.0f;
        checkMarkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(viewRect.size.width - checkWH - offsetXY, offsetXY, checkWH, checkWH)];
        checkMarkImageView.contentMode = UIViewContentModeScaleToFill;
        [checkMarkImageView setBackgroundColor:[UIColor clearColor]];
        [checkMarkImageView setTag:kCheckMarkImageCarouselTag];
        [checkMarkImageView setImage:[UIImage imageNamed:@"checkMark.png"]];
        [view addSubview:checkMarkImageView];
        
    } else {
        itemImageView = (UIImageView*)[view viewWithTag:kImageViewCarouselTag];
        indicator  = (UIActivityIndicatorView *)[view viewWithTag:kIndicatorCarouselTag];
        authorLabel = (UILabel *)[view viewWithTag:kAuthorLabelCarouselTag];
        titleLabel = (UILabel *)[view viewWithTag:kTitleLabelCarouselTag];
        checkMarkImageView = (UIImageView*)[view viewWithTag:kCheckMarkImageCarouselTag];
    }
    
    NSString *authorName = [_gallaryObject author];
    authorLabel.text = [NSString stringWithFormat:@"Author: %@",authorName];
    
    NSString *titleString = [_gallaryObject title];
    titleLabel.text = [NSString stringWithFormat:@"Title: %@",titleString];
    
    [checkMarkImageView setHidden:YES];
    
    if (image) {
        [indicator stopAnimating];
        [itemImageView setImage:image];
    } else {
        [_gallaryObject loadGallaryImage:carouselView];
        [indicator startAnimating];
        [itemImageView setImage:[UIImage imageNamed:@"DefaultGallaryImage.jpg"]];
    }
    
    [[view layer] setCornerRadius:radius];
    [[view layer] setMasksToBounds:YES];
    return view;
}

- (UIView *)loadViewAtIndex:(NSInteger)index withContainerView:(UIView *)containerView {
    [self pushAnimationState:NO];
    UIView *view = [self dequeueItemView];
    [_dataSource carousel:self viewForItemAtIndex:index];
    view = [self carousel:self index:index customItemView:view];
    
    if (view == nil) {
        view = [[UIView alloc] init];
    }
    
    [self setItemView:view forIndex:index];
    if (containerView) {
        UIView *oldItemView = [containerView.subviews lastObject];
        [self queueItemView:oldItemView];
    
        CGRect frame = containerView.bounds;
        if(_vertical) {
            frame.size.width = view.frame.size.width;
            frame.size.height = MIN(_itemWidth, view.frame.size.height);
        }
        else {
            frame.size.width = MIN(_itemWidth, view.frame.size.width);
            frame.size.height = view.frame.size.height;
        }
        containerView.bounds = frame;
        
        //set view frame
        frame = view.frame;
        frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0;
        frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0;
        view.frame = frame;
        
        //switch views
        [oldItemView removeFromSuperview];
        [containerView addSubview:view];
    }
    else {
        [_contentView addSubview:[self containView:view]];
    }
    view.superview.layer.opacity = 0.0;
    [self transformItemView:view atIndex:index];
    
    [self popAnimationState];
    
    return view;
}

- (UIView *)loadViewAtIndex:(NSInteger)index {
    return [self loadViewAtIndex:index withContainerView:nil];
}

- (void)loadUnloadViews {
    //set item width
    [self updateItemWidth];
    
    //update number of visible items
    [self updateNumberOfVisibleItems];
    
    //calculate visible view indices
    NSMutableSet *visibleIndices = [NSMutableSet setWithCapacity:_numberOfVisibleItems];
    NSInteger min = 0;
    NSInteger max = _numberOfItems - 1;
    NSInteger offset = self.currentItemIndex - _numberOfVisibleItems/2;
    if (!_wrapEnabled) {
        offset = MAX(min, MIN(max - _numberOfVisibleItems + 1, offset));
    }
    for (NSInteger i = 0; i < _numberOfVisibleItems; i++) {
        NSInteger index = i + offset;
        if (_wrapEnabled) {
            index = [self clampedIndex:index];
        }
        CGFloat alpha = [self alphaForItemWithOffset:[self offsetForItemAtIndex:index]];
        if (alpha) {
            //only add views with alpha > 0
            [visibleIndices addObject:@(index)];
        }
    }
    
    //remove offscreen views
    for (NSNumber *number in [_itemViews allKeys]) {
        if (![visibleIndices containsObject:number]) {
            UIView *view = _itemViews[number];
            [self queueItemView:view];
            [view.superview removeFromSuperview];
            [(NSMutableDictionary *)_itemViews removeObjectForKey:number];
        }
    }
    
    //add onscreen views
    for (NSNumber *number in visibleIndices) {
        UIView *view = _itemViews[number];
        if (view == nil) {
            [self loadViewAtIndex:[number integerValue]];
        }
    }
}

- (void)reloadData{
    for (UIView *view in [_itemViews allValues]) {
        [view.superview removeFromSuperview];
    }
    
    if (!_dataSource || !_contentView) {
        return;
    }
    
    _itemViews = nil;
    _itemViewPool = nil;
    
    _numberOfVisibleItems = 0;
    _numberOfItems = [_dataSource numberOfItemsInCarousel:self];
    
    _itemViews = [NSMutableDictionary dictionary];
    _itemViewPool = [NSMutableSet set];
    
    [self setNeedsLayout];
}

- (void)deselectAllCheckMarked {
    for (UIView *view in [_itemViews allValues]) {
        UIImageView * checkMarkImageView = (UIImageView*)[view viewWithTag:kCheckMarkImageCarouselTag];
        [checkMarkImageView setHidden:YES];
    }
}

#pragma mark - Scrolling

- (NSInteger)clampedIndex:(NSInteger)index {
    if (_numberOfItems == 0) {
        return -1;
    } else if (_wrapEnabled) {
        return index - floor((CGFloat)index / (CGFloat)_numberOfItems) * _numberOfItems;
    } else {
        return MIN(MAX(0, index), MAX(0, _numberOfItems - 1));
    }
}

- (CGFloat)clampedOffset:(CGFloat)offset {
    if (_numberOfItems == 0) {
        return -1.0;
    } else if (_wrapEnabled) {
        return offset - floor(offset / (CGFloat)_numberOfItems) * _numberOfItems;
    } else {
        return MIN(MAX(0.0, offset), MAX(0.0, (CGFloat)_numberOfItems - 1.0));
    }
}

- (NSInteger)currentItemIndex {
    return [self clampedIndex:round(_scrollOffset)];
}

- (NSInteger)minScrollDistanceFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSInteger directDistance = toIndex - fromIndex;
    if (_wrapEnabled) {
        NSInteger wrappedDistance = MIN(toIndex, fromIndex) + _numberOfItems - MAX(toIndex, fromIndex);
        if (fromIndex < toIndex) {
            wrappedDistance = -wrappedDistance;
        }
        return (ABS(directDistance) <= ABS(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (CGFloat)minScrollDistanceFromOffset:(CGFloat)fromOffset toOffset:(CGFloat)toOffset {
    CGFloat directDistance = toOffset - fromOffset;
    if (_wrapEnabled) {
        CGFloat wrappedDistance = MIN(toOffset, fromOffset) + _numberOfItems - MAX(toOffset, fromOffset);
        if (fromOffset < toOffset)
        {
            wrappedDistance = -wrappedDistance;
        }
        return (fabs(directDistance) <= fabs(wrappedDistance))? directDistance: wrappedDistance;
    }
    return directDistance;
}

- (void)scrollByOffset:(CGFloat)offset duration:(NSTimeInterval)duration {
    if (duration > 0.0) {
        _decelerating = NO;
        _scrolling = YES;
        _startTime = CACurrentMediaTime();
        _startOffset = _scrollOffset;
        _scrollDuration = duration;
        _endOffset = _startOffset + offset;
        if (!_wrapEnabled) {
            _endOffset = [self clampedOffset:_endOffset];
        }
        [_delegate carouselWillBeginScrollingAnimation:self];
        [self startAnimation];
    } else {
        _scrollOffset += offset;
    }
}

- (void)scrollToOffset:(CGFloat)offset duration:(NSTimeInterval)duration {
    [self scrollByOffset:[self minScrollDistanceFromOffset:_scrollOffset toOffset:offset] duration:duration];
}

- (void)scrollByNumberOfItems:(NSInteger)itemCount duration:(NSTimeInterval)duration {
    if (duration > 0.0) {
        CGFloat offset = 0.0;
        if (itemCount > 0) {
            offset = (floor(_scrollOffset) + itemCount) - _scrollOffset;
        } else if (itemCount < 0) {
            offset = (ceil(_scrollOffset) + itemCount) - _scrollOffset;
        } else {
            offset = round(_scrollOffset) - _scrollOffset;
        }
        [self scrollByOffset:offset duration:duration];
    } else {
        _scrollOffset = [self clampedIndex:_previousItemIndex + itemCount];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index duration:(NSTimeInterval)duration {
    [self scrollToOffset:index duration:duration];
}

- (void)scrollToItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    [self scrollToItemAtIndex:index duration:animated? Scroll_Duration: 0];
}

- (void)removeItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    index = [self clampedIndex:index];
    UIView *itemView = [self itemViewAtIndex:index];
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        [UIView setAnimationDelegate:itemView.superview];
        [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
        [self performSelector:@selector(queueItemView:) withObject:itemView afterDelay:0.1];
        itemView.superview.layer.opacity = 0.0;
        [UIView commitAnimations];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDelay:0.1];
        [UIView setAnimationDuration:Insert_Duration];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(depthSortViews)];
        [self removeViewAtIndex:index];
        _numberOfItems --;
        [self updateNumberOfVisibleItems];
        _scrollOffset = self.currentItemIndex;
        [self didScroll];
        [UIView commitAnimations];
    } else {
        [self pushAnimationState:NO];
        [self queueItemView:itemView];
        [itemView.superview removeFromSuperview];
        [self removeViewAtIndex:index];
        _numberOfItems --;
        _scrollOffset = self.currentItemIndex;
        [self didScroll];
        [self depthSortViews];
        [self popAnimationState];
    }
}

- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated {
    _numberOfItems ++;
    [self updateNumberOfVisibleItems];
    
    index = [self clampedIndex:index];
    [self insertView:nil atIndex:index];
    [self loadViewAtIndex:index];
    
    if (fabs(_itemWidth) < Float_Error_Margin) {
        [self updateItemWidth];
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:Insert_Duration];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(didScroll)];
        [self transformItemViews];
        [UIView commitAnimations];
    } else {
        [self pushAnimationState:NO];
        [self didScroll];
        [self popAnimationState];
    }
}

- (void)reloadItemAtIndex:(NSInteger)index animated:(BOOL)animate {
    UIView *containerView = [[self itemViewAtIndex:index] superview];
    if (containerView) {
        if (animate) {
            CATransition *transition = [CATransition animation];
            transition.duration = Insert_Duration;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
            [containerView.layer addAnimation:transition forKey:nil];
        }
        [self loadViewAtIndex:index withContainerView:containerView];
    }
}

#pragma mark - Animation

- (void)startAnimation {
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:1.0/60.0
                                             target:self
                                           selector:@selector(step)
                                           userInfo:nil
                                            repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopAnimation {
    [_timer invalidate];
    _timer = nil;
}

- (CGFloat)decelerationDistance {
    CGFloat acceleration = -_startVelocity * Deceleration_Multiplier * (1.0 - _decelerationRate);
    return -pow(_startVelocity, 2.0) / (2.0 * acceleration);
}

- (BOOL)shouldDecelerate {
    return (fabs(_startVelocity) > Speed_Scroll_Threshold) &&
    (fabs([self decelerationDistance]) > Decelerate_Threshold);
}

- (BOOL)shouldScroll {
    return (fabs(_startVelocity) > Speed_Scroll_Threshold) &&
    (fabs(_scrollOffset - self.currentItemIndex) > Distance_Scroll_Threshold);
}

- (void)startDecelerating {
    CGFloat distance = [self decelerationDistance];
    _startOffset = _scrollOffset;
    _endOffset = _startOffset + distance;
    if (_pagingEnabled) {
        if (distance > 0.0) {
            _endOffset = ceil(_startOffset);
        } else {
            _endOffset = floor(_startOffset);
        }
    } else if (_stopAtItemBoundary) {
        if (distance > 0.0) {
            _endOffset = ceil(_endOffset);
        } else {
            _endOffset = floor(_endOffset);
        }
    }
    
    if (!_wrapEnabled) {
        if (_bounces) {
            _endOffset = MAX(-_bounceDistance, MIN(_numberOfItems - 1.0 + _bounceDistance, _endOffset));
        } else {
            _endOffset = [self clampedOffset:_endOffset];
        }
    }
    distance = _endOffset - _startOffset;
    
    _startTime = CACurrentMediaTime();
    _scrollDuration = fabs(distance) / fabs(0.5 * _startVelocity);
    
    if (distance != 0.0) {
        _decelerating = YES;
        [self startAnimation];
    }
}

- (CGFloat)easeInOut:(CGFloat)time {
    return (time < 0.5)? 0.5 * pow(time * 2.0, 3.0): 0.5 * pow(time * 2.0 - 2.0, 3.0) + 1.0;
}

- (void)step {
    [self pushAnimationState:NO];
    NSTimeInterval currentTime = CACurrentMediaTime();
    double delta = currentTime - _lastTime;
    _lastTime = currentTime;
    
    if (_scrolling && !_dragging) {
        NSTimeInterval time = MIN(1.0, (currentTime - _startTime) / _scrollDuration);
        delta = [self easeInOut:time];
        _scrollOffset = _startOffset + (_endOffset - _startOffset) * delta;
        [self didScroll];
        if (time >= 1.0) {
            _scrolling = NO;
            [self depthSortViews];
            [self pushAnimationState:YES];
            [_delegate carouselDidEndScrollingAnimation:self];
            [self popAnimationState];
        }
    } else if (_decelerating) {
        CGFloat time = MIN(_scrollDuration, currentTime - _startTime);
        CGFloat acceleration = -_startVelocity/_scrollDuration;
        CGFloat distance = _startVelocity * time + 0.5 * acceleration * pow(time, 2.0);
        _scrollOffset = _startOffset + distance;
        [self didScroll];
        if (fabs(time - _scrollDuration) < Float_Error_Margin) {
            _decelerating = NO;
            [self pushAnimationState:YES];
            [_delegate carouselDidEndDecelerating:self];
            [self popAnimationState];
            if ((_scrollToItemBoundary || fabs(_scrollOffset - [self clampedOffset:_scrollOffset]) > Float_Error_Margin) && !_autoscroll) {
                if (fabs(_scrollOffset - self.currentItemIndex) < Float_Error_Margin) {
                    [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                } else {
                    [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                }
            } else {
                CGFloat difference = round(_scrollOffset) - _scrollOffset;
                if (difference > 0.5) {
                    difference = difference - 1.0;
                } else if (difference < -0.5) {
                    difference = 1.0 + difference;
                }
                _toggleTime = currentTime - Max_Toggle_Duration * fabs(difference);
                _toggle = MAX(-1.0, MIN(1.0, -difference));
            }
        }
    } else if (_autoscroll && !_dragging) {
        //autoscroll goes backwards from what you'd expect, for historical reasons
        _scrollOffset = [self clampedOffset:_scrollOffset - delta * _autoscroll];
    } else if (fabs(_toggle) > Float_Error_Margin) {
        NSTimeInterval toggleDuration = _startVelocity? MIN(1.0, MAX(0.0, 1.0 / fabs(_startVelocity))): 1.0;
        toggleDuration = Min_Toggle_Duration + (Max_Toggle_Duration - Min_Toggle_Duration) * toggleDuration;
        NSTimeInterval time = MIN(1.0, (currentTime - _toggleTime) / toggleDuration);
        delta = [self easeInOut:time];
        _toggle = (_toggle < 0.0)? (delta - 1.0): (1.0 - delta);
        [self didScroll];
    } else if (!_autoscroll) {
        [self stopAnimation];
    }
    
    [self popAnimationState];
}

- (void)didMoveToSuperview {
    if (self.superview) {
        [self startAnimation];
    } else {
        [self stopAnimation];
    }
}

- (void)didScroll {
    if (_wrapEnabled || !_bounces) {
        _scrollOffset = [self clampedOffset:_scrollOffset];
    } else {
        CGFloat min = -_bounceDistance;
        CGFloat max = MAX(_numberOfItems - 1, 0.0) + _bounceDistance;
        if (_scrollOffset < min)
        {
            _scrollOffset = min;
            _startVelocity = 0.0;
        }
        else if (_scrollOffset > max)
        {
            _scrollOffset = max;
            _startVelocity = 0.0;
        }
    }
    
    //check if index has changed
    NSInteger difference = [self minScrollDistanceFromIndex:self.currentItemIndex toIndex:_previousItemIndex];
    if (difference) {
        _toggleTime = CACurrentMediaTime();
        _toggle = MAX(-1, MIN(1, difference));
        [self startAnimation];
    }
    
    [self loadUnloadViews];
    [self transformItemViews];
    
    //notify delegate of offset change
    if (fabs(_scrollOffset - _previousScrollOffset) > Float_Error_Margin) {
        [self pushAnimationState:YES];
        [_delegate carouselDidScroll:self];
        [self popAnimationState];
    }
    
    //notify delegate of index change
    if (_previousItemIndex != self.currentItemIndex) {
        [self pushAnimationState:YES];
        [_delegate carouselCurrentItemIndexDidChange:self];
        [self popAnimationState];
    }
    
    //update previous index
    _previousScrollOffset = _scrollOffset;
    _previousItemIndex = self.currentItemIndex;
}

#pragma mark - Gestures and taps

- (NSInteger)viewOrSuperviewIndex:(UIView *)view {
    if (view == nil || view == _contentView) {
        return NSNotFound;
    }
    NSInteger index = [self indexOfItemView:view];
    if (index == NSNotFound) {
        return [self viewOrSuperviewIndex:view.superview];
    }
    return index;
}

- (BOOL)viewOrSuperview:(UIView *)view implementsSelector:(SEL)selector {
    if (!view || view == _contentView) {
        return NO;
    }
    
    Class viewClass = [view class];
    while (viewClass && viewClass != [UIView class]) {
        unsigned int numberOfMethods;
        Method *methods = class_copyMethodList(viewClass, &numberOfMethods);
        for (unsigned int i = 0; i < numberOfMethods; i++) {
            if (method_getName(methods[i]) == selector) {
                free(methods);
                return YES;
            }
        }
        if (methods) free(methods);
        viewClass = [viewClass superclass];
    }
    
    return [self viewOrSuperview:view.superview implementsSelector:selector];
}

- (id)viewOrSuperview:(UIView *)view ofClass:(Class)class {
    if (!view || view == _contentView) {
        return nil;
    } else if ([view isKindOfClass:class]) {
        return view;
    }
    return [self viewOrSuperview:view.superview ofClass:class];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    if (_scrollEnabled) {
        _dragging = NO;
        _scrolling = NO;
        _decelerating = NO;
    }
    
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        //handle tap
        NSInteger index = [self viewOrSuperviewIndex:touch.view];
        if (index == NSNotFound && _centerItemWhenSelected) {
            //view is a container view
            index = [self viewOrSuperviewIndex:[touch.view.subviews lastObject]];
        }
        if (index != NSNotFound) {
            if ([self viewOrSuperview:touch.view implementsSelector:@selector(touchesBegan:withEvent:)]) {
                return NO;
            }
        }
    }
    else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        if (!_scrollEnabled) {
            return NO;
        }
        else if ([self viewOrSuperview:touch.view implementsSelector:@selector(touchesMoved:withEvent:)]) {
            UIScrollView *scrollView = [self viewOrSuperview:touch.view ofClass:[UIScrollView class]];
            if (scrollView) {
                return !scrollView.scrollEnabled ||
                (_vertical && scrollView.contentSize.height <= scrollView.frame.size.height) ||
                (!_vertical && scrollView.contentSize.width <= scrollView.frame.size.width);
            }
            if ([self viewOrSuperview:touch.view ofClass:[UIButton class]] ||
                [self viewOrSuperview:touch.view ofClass:[UIBarButtonItem class]]) {
                return YES;
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        //ignore vertical swipes
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
        CGPoint translation = [panGesture translationInView:self];
        if (_ignorePerpendicularSwipes) {
            if (_vertical) {
                return fabs(translation.x) <= fabs(translation.y);
            } else {
                return fabs(translation.x) >= fabs(translation.y);
            }
        }
    }
    return YES;
}

- (void)didTap:(UITapGestureRecognizer *)tapGesture
{
    //check for tapped view
    UIView *itemView = [self itemViewAtPoint:[tapGesture locationInView:_contentView]];
    NSInteger index = [self indexOfItemView:itemView];
    if (index != NSNotFound) {
        if (!_delegate || [_delegate carousel:self shouldSelectItemAtIndex:index]) {
            if ((index != self.currentItemIndex && _centerItemWhenSelected) ||
                (index == self.currentItemIndex && _scrollToItemBoundary)) {
                [self scrollToItemAtIndex:index animated:YES];
            }
            [_delegate carousel:self didSelectItemAtIndex:index itemView:itemView];
        } else if (_scrollEnabled && _scrollToItemBoundary && _autoscroll) {
            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
        }
    }
}

- (void)didPan:(UIPanGestureRecognizer *)panGesture {
    if (_scrollEnabled && _numberOfItems) {
        switch (panGesture.state) {
            case UIGestureRecognizerStateBegan: {
                _dragging = YES;
                _scrolling = NO;
                _decelerating = NO;
                _previousTranslation = _vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x;
                [_delegate carouselWillBeginDragging:self];
                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed: {
                _dragging = NO;
                _didDrag = YES;
                if ([self shouldDecelerate]) {
                    _didDrag = NO;
                    [self startDecelerating];
                }
                
                [self pushAnimationState:YES];
                [_delegate carouselDidEndDragging:self willDecelerate:_decelerating];
                [self popAnimationState];
                
                if (!_decelerating) {
                    if ((_scrollToItemBoundary || fabs(_scrollOffset - [self clampedOffset:_scrollOffset]) > Float_Error_Margin) && !_autoscroll) {
                        if (fabs(_scrollOffset - self.currentItemIndex) < Float_Error_Margin) {
                            [self scrollToItemAtIndex:self.currentItemIndex duration:0.01];
                        } else if ([self shouldScroll]) {
                            NSInteger direction = (int)(_startVelocity / fabs(_startVelocity));
                            [self scrollToItemAtIndex:self.currentItemIndex + direction animated:YES];
                        } else {
                            [self scrollToItemAtIndex:self.currentItemIndex animated:YES];
                        }
                    } else {
                        [self depthSortViews];
                    }
                } else {
                    [self pushAnimationState:YES];
                    [_delegate carouselWillBeginDecelerating:self];
                    [self popAnimationState];
                }
                break;
            }
            case UIGestureRecognizerStateChanged: {
                CGFloat translation = (_vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x) - _previousTranslation;
                CGFloat factor = 1.0;
                if (!_wrapEnabled && _bounces) {
                    factor = 1.0 - MIN(fabs(_scrollOffset - [self clampedOffset:_scrollOffset]), _bounceDistance) / _bounceDistance;
                }
                
                _previousTranslation = _vertical? [panGesture translationInView:self].y: [panGesture translationInView:self].x;
                _startVelocity = -(_vertical? [panGesture velocityInView:self].y: [panGesture velocityInView:self].x) * factor * _scrollSpeed / _itemWidth;
                _scrollOffset -= translation * factor * _offsetMultiplier / _itemWidth;
                [self didScroll];
                break;
            }
            case UIGestureRecognizerStatePossible:{
                //do nothing
                break;
            }
        }
    }
}


#pragma mark - GallaryImageDelegate
- (void)imageLoadedSuccess {
    UIImageView *itemImageView = (UIImageView*)[self viewWithTag:kImageViewCarouselTag];
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self viewWithTag:kIndicatorCarouselTag];
    UIImage *image = [_gallaryObject gallaryImage];
    if (image) {
        [indicator stopAnimating];
        [itemImageView setImage:image];
    } else {
        [_gallaryObject loadGallaryImage:self];
        [indicator startAnimating];
        [itemImageView setImage:[UIImage imageNamed:@"DefaultGallaryImage.jpg"]];
    }

}

- (void)imageLoadedFailed {
    UIImageView *itemImageView = (UIImageView*)[self viewWithTag:kImageViewCarouselTag];
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self viewWithTag:kIndicatorCarouselTag];
    [indicator startAnimating];
    [itemImageView setImage:[UIImage imageNamed:@"DefaultGallaryImage.jpg"]];
}

@end

// NGCarousel Category to avoid Delegate Crash.
@implementation NSObject (NGCarousel)

- (void)carouselWillBeginScrollingAnimation:(__unused NGCarousel *)carousel {}
- (void)carouselDidEndScrollingAnimation:(__unused NGCarousel *)carousel {}
- (void)carouselDidScroll:(__unused NGCarousel *)carousel {}
- (void)carouselCurrentItemIndexDidChange:(__unused NGCarousel *)carousel {}
- (void)carouselWillBeginDragging:(__unused NGCarousel *)carousel {}
- (void)carouselDidEndDragging:(__unused NGCarousel *)carousel willDecelerate:(__unused BOOL)decelerate {}
- (void)carouselWillBeginDecelerating:(__unused NGCarousel *)carousel {}
- (void)carouselDidEndDecelerating:(__unused NGCarousel *)carousel {}
- (BOOL)carousel:(__unused NGCarousel *)carousel shouldSelectItemAtIndex:(__unused NSInteger)index { return YES; }
- (void)carousel:(__unused NGCarousel *)carousel didSelectItemAtIndex:(__unused NSInteger)index itemView:(UIView *)itemView {}
- (CGFloat)carouselItemWidth:(__unused NGCarousel *)carousel { return 0; }

@end

