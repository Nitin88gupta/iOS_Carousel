//
//  GallaryObject.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "GallaryObject.h"


@implementation GallaryObject

@dynamic author;
@dynamic createdAt;
@dynamic img_url;
@dynamic objectId;
@dynamic title;
@dynamic updatedAt;

@synthesize delegate;

#pragma mark - Image Loading
- (NSString *)imageFilePath {
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataPath = [documentsPath stringByAppendingPathComponent:@"GallaryImages"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    NSString * imageFile = [NSString stringWithFormat:@"Image_%@.png",self.objectId];
    NSArray *pathComponents = [NSArray arrayWithObjects:dataPath,imageFile,nil];
    NSString *filePath = [NSString pathWithComponents:pathComponents];
    return filePath;
}

- (UIImage *)gallaryImage {
    NSString *filePath = [self imageFilePath];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    UIImage *image = nil;
    if (data) {
        image = [UIImage imageWithData:data];
    }
    return image;
}

- (void)loadGallaryImage:(id<GallaryImageDelegate>)loadDelegate {
    delegate = loadDelegate;
    if (!isLoadingImage) {
        isLoadingImage = YES;
        [self loadImageInBackground];
    }
}

- (void)loadImageInBackground {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *filePath = [self imageFilePath];
        NSData *data = [NSData dataWithContentsOfURL:[[NSURL alloc] initWithString:[self.img_url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        if (data) {
            [data writeToFile:filePath atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delegate && [delegate respondsToSelector:@selector(imageLoadedSuccess)]) {
                    [delegate imageLoadedSuccess];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delegate && [delegate respondsToSelector:@selector(imageLoadedFailed)]) {
                    [delegate imageLoadedFailed];
                }
            });
        }
    });
}

@end
