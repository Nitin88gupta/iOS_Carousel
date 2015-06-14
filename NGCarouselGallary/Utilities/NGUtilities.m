//
//  NGUtilities.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "NGUtilities.h"
#import "NGConstants.h"
#import "NGLoadingIndicator.h"

@implementation NGUtilities

#pragma mark - Color Image Utils

+ (UIImage *)imageFromColor:(UIColor *)color withSize:(CGSize)size {
    
    size = CGSizeEqualToSize(size, CGSizeZero) ? CGSizeMake(1, 1) : size;
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSDictionary*)getRGBAComponentDictionayFormColor:(UIColor *)color {
    CGColorRef textColorRef = [color CGColor];
    CGColorSpaceModel _modal = CGColorSpaceGetModel(CGColorGetColorSpace(textColorRef));
    CGFloat compR;
    CGFloat compG;
    CGFloat compB;
    CGFloat compA;
    const CGFloat *components = CGColorGetComponents(textColorRef);
    
    switch (_modal) {
        case kCGColorSpaceModelMonochrome: {
            compR = compG = compB = components[0];
            compA = components[1];
        } break;
        default: {
            compR = components[0];
            compG = components[1];
            compB = components[2];
            compA = components[3];
        } break;
    }
    
    compA = !compA ? 1.0 : compA;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat:compR],Component_Red_Key,
            [NSNumber numberWithFloat:compG],Component_Green_Key,
            [NSNumber numberWithFloat:compB],Component_Blue_Key,
            [NSNumber numberWithFloat:compA],Component_Alpha_Key,nil];
}

#pragma mark - Loading Indicator

+ (void)showLoadingIndicator:(NSString*)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NGLoadingIndicator sharedLoadingIndicator] show:string];
    });
}

+ (void)hideLoadingIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NGLoadingIndicator sharedLoadingIndicator] dismiss];
    });
}

#pragma mark - Network Status Helper

+ (BOOL)checkNetworkAvailable {
    BOOL _returnValue = FALSE;
    CFNetDiagnosticRef dReference;
    dReference = CFNetDiagnosticCreateWithURL (NULL, (__bridge CFURLRef)[NSURL URLWithString:@"www.apple.com"]);
    
    CFNetDiagnosticStatus status;
    status = CFNetDiagnosticCopyNetworkStatusPassively (dReference, NULL);
    
    CFRelease (dReference);
    
    if ( status == kCFNetDiagnosticConnectionUp ) {
        //Connection is Available
        _returnValue = YES;
    } else {
        //Connection is down
        _returnValue = NO;
    }
    return _returnValue;
}

#pragma mark - JSON Handler Methods

+ (NSString *)getJSONStringFromDictionary:(NSDictionary *)_aDict{
    return [[NSString alloc] initWithData:[NGUtilities getJSONDataFromDictionary:_aDict] encoding:NSUTF8StringEncoding];
}

+(NSData *) getJSONDataFromDictionary:(NSDictionary *)_aDict {
    NSError* error = nil;
    NSData *result = [NSJSONSerialization dataWithJSONObject:_aDict options:kNilOptions error:&error];
    if (error != nil)  {
        return nil;
    }
    return result;
}

+(NSDictionary *) getDictionaryFromJSONData:(NSData *)responseData {
    NSError* error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    if (error != nil)  {
        NSLog(@"getDictionaryFromJSONData Error = %@",[error localizedDescription]);
        return nil;
    }
    return result;
}

#pragma mark - Date/ String Conversion
+ (NSDate *)dateFromString:(NSString *)dateStr
{
    NSDateFormatter *datFormatter = [[NSDateFormatter alloc] init];
    [datFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate* date = [datFormatter dateFromString:dateStr];
    return date;
}

+ (NSString *)stringForDate:(NSDate *)date
{
    NSDateFormatter *messageDateFormatter = [[NSDateFormatter alloc] init];
    [messageDateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    NSString *time = [messageDateFormatter stringFromDate:date];
    return time;
}


@end
