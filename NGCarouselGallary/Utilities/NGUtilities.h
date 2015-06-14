//
//  NGUtilities.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

@interface NGUtilities : NSObject

//Color Image Utils
+ (UIImage *)imageFromColor:(UIColor *)color withSize:(CGSize)size;
+ (NSDictionary*)getRGBAComponentDictionayFormColor:(UIColor *)color;

//Loading Indicator
+ (void)showLoadingIndicator:(NSString*)string ;
+ (void)hideLoadingIndicator;

//Network Status Helper
+ (BOOL)checkNetworkAvailable ;

//JSON Handler Methods
+ (NSString *)getJSONStringFromDictionary:(NSDictionary *)_aDict;
+ (NSData *)getJSONDataFromDictionary:(NSDictionary *)_aDict ;
+ (NSDictionary *)getDictionaryFromJSONData:(NSData *)responseData ;

//Date/ String Conversion
+ (NSDate *)dateFromString:(NSString *)dateStr;
+ (NSString *)stringForDate:(NSDate *)date;
@end
