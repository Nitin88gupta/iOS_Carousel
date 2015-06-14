//
//  GallaryObject.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@protocol GallaryImageDelegate <NSObject>
@optional
- (void)imageLoadedSuccess;
- (void)imageLoadedFailed;
@end

@interface GallaryObject : NSManagedObject {
    BOOL isLoadingImage;
}

@property (nonatomic, retain) NSString * author;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * img_url;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updatedAt;

@property (nonatomic, assign) id <GallaryImageDelegate>delegate;


- (UIImage *)gallaryImage;
- (void)loadGallaryImage:(id<GallaryImageDelegate>)loadDelegate;
@end
