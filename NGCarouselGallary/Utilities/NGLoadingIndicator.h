//
//  NGLoadingIndicator.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NGLoadingIndicator : UIView

+ (instancetype)sharedLoadingIndicator;
- (void)dismiss;
- (void)show:(NSString *)status;
- (void)show:(NSString *)status Interaction:(BOOL)Interaction;

@end
