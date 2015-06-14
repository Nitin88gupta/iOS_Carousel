//
//  NGCarousel.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 14/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Availability.h>
#import <QuartzCore/QuartzCore.h>
#import "NGConstants.h"
#import "GallaryObject.h"

@protocol NGCarouselDataSource, NGCarouselDelegate;

@interface NGCarousel : UIView <GallaryImageDelegate>

@property (nonatomic, weak) id<NGCarouselDataSource> dataSource;
@property (nonatomic, weak) id<NGCarouselDelegate> delegate;
@property (nonatomic, weak) GallaryObject *gallaryObject;

- (void)reloadData;
- (void)deselectAllCheckMarked;

@end


@protocol NGCarouselDataSource <NSObject>
@required
- (NSInteger)numberOfItemsInCarousel:(NGCarousel *)carousel;
- (void)carousel:(NGCarousel *)carousel viewForItemAtIndex:(NSInteger)index;
@end


@protocol NGCarouselDelegate <NSObject>
@optional
- (void)carouselWillBeginScrollingAnimation:(NGCarousel *)carousel;
- (void)carouselDidEndScrollingAnimation:(NGCarousel *)carousel;
- (void)carouselDidScroll:(NGCarousel *)carousel;
- (void)carouselCurrentItemIndexDidChange:(NGCarousel *)carousel;
- (void)carouselWillBeginDragging:(NGCarousel *)carousel;
- (void)carouselDidEndDragging:(NGCarousel *)carousel willDecelerate:(BOOL)decelerate;
- (void)carouselWillBeginDecelerating:(NGCarousel *)carousel;
- (void)carouselDidEndDecelerating:(NGCarousel *)carousel;

- (BOOL)carousel:(NGCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index;
- (void)carousel:(NGCarousel *)carousel didSelectItemAtIndex:(NSInteger)index itemView:(UIView *)itemView;

- (CGFloat)carouselItemWidth:(NGCarousel *)carousel;

@end

