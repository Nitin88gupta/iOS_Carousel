//
//  NGWebServiceHelper.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "NGWebServiceHelper.h"
#import "NGUtilities.h"

static const NSString *kUserName = @"ak4cZjG8I2duP7KYTh7svcwHK7hufmwgJVGRkqoM";
static const NSString *kPassword = @"javascript-key=ma1Ki3CK5lnzM7YqwpIcynAidSOrMQ69nhzsnumw";

@implementation NGWebServiceHelper


- (void)dealloc {
    FunctionLog();
}

#pragma mark - Public Mathods
/**
 *  Sending Asynchronous Request
 */
- (void)sendAsynchronousRequest:(ServiceType)requestType
          withRequestDictionary:(NSDictionary *)dictionary
                     HTTPMethod:(HTTPMethod)method
                     imageArray:(NSArray *)imageArray
              completionHandler:(requestCompletionHandler) handler {
    
    if ([NGUtilities checkNetworkAvailable]) {
        NSURLRequest *request = [self requestWithType:requestType withRequestDictionary:dictionary HTTPMethod:method andImageArray:imageArray];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (connectionError) {
                NSLog(@"%@",[connectionError localizedDescription]);
                handler(FALSE, nil, connectionError,self);
            } else {
                NSDictionary *responseDict = [NGUtilities getDictionaryFromJSONData:data];
                NSLog(@"request = %@ Api Asynchronous request responseDict = %@",request,responseDict);
                BOOL status = responseDict && responseDict.count ? YES : NO;
                handler(status, responseDict, connectionError,self);
            }
        }];
    } else {
        handler(FALSE, nil, nil,self);
    }
}

/**
 *  Sending Synchronous Request
 */
- (void)sendSynchronousRequest:(ServiceType)requestType
         withRequestDictionary:(NSDictionary *)dictionary
                    HTTPMethod:(HTTPMethod)method
                    imageArray:(NSArray *)imageArray
             completionHandler:(requestCompletionHandler)handler {
    
    if ([NGUtilities checkNetworkAvailable]) {
        NSURLRequest *request = [self requestWithType:requestType withRequestDictionary:dictionary HTTPMethod:method andImageArray:imageArray];
        NSURLResponse *response = nil;
        NSError *connectionError = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
        if (connectionError) {
            NSLog(@"%@",[connectionError localizedDescription]);
            handler(FALSE, nil, connectionError,self);
        } else {
            NSDictionary *responseDict = [NGUtilities getDictionaryFromJSONData:data];
            NSLog(@"request = %@ Api Asynchronous request responseDict = %@",request,responseDict);
            BOOL status = responseDict && responseDict.count ? YES : NO;
            handler(status, responseDict, connectionError,self);
        }
    } else {
        handler(FALSE, nil, nil,self);
    }
}

#pragma mark - Private Methods
- (NSURLRequest *)requestWithType:(ServiceType)requestType
            withRequestDictionary:(NSDictionary *)dictionary
                       HTTPMethod:(HTTPMethod)method
                    andImageArray:(NSArray *)imageArray {
    if (method <= 0) {
        return nil;
    }
    NSMutableURLRequest *request = nil;
    NSURL *requestURL = [self urlForType:requestType withInfo:dictionary];
    request = [[NSMutableURLRequest alloc] initWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:URL_Request_Timeout];
    NSString *methodString = [self getMethodStringForType:method];
    [request setHTTPMethod:methodString];
    NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@",kUserName,kPassword];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", AFBase64EncodedStringFromString(basicAuthCredentials)];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    if (imageArray && imageArray.count > 0) {
        NSMutableData *postData = [NSMutableData data];
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString * timeStampValue = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSString *fileName=nil;
        
        if (dictionary) {
            NSString *jsonString = [NGUtilities getJSONStringFromDictionary:dictionary];
            
            [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postData appendData:[@"Content-disposition: form-data; name=\"data\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postData appendData:[ jsonString  dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        for (UIImage *image in imageArray) {
            NSData *data = UIImagePNGRepresentation(image);
            fileName = [NSString stringWithFormat:@"UserImg_%@.png",timeStampValue];
            [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", kPassword,fileName] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postData appendData:[NSData dataWithData:data]];
            
            [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        [request setHTTPBody:postData];
    }
    return request;
}

- (NSURL *)urlForType:(ServiceType)requestType withInfo:(NSDictionary*)infoDict {
    NSURL *url = nil;
    NSString *urlString = nil;
    NSString *objectid = nil;
    if (infoDict && [infoDict count]) {
        objectid = [infoDict objectForKey:ObjectID_Key];
    } else {
        objectid = @"";
    }

    switch (requestType) {
        case kQueries: {
            urlString = [NSString stringWithFormat:@"%@/%@",Base_URL,Queries_API];
        } break;
        case kRetrieve: {
            urlString = [NSString stringWithFormat:@"%@/%@/%@",Base_URL,Retrieves_Object_API,objectid];
        } break;
        case kCreating: {
            urlString = [NSString stringWithFormat:@"%@/%@",Base_URL,Creating_Objects_API];
        } break;
        case kDeleting: {
            urlString = [NSString stringWithFormat:@"%@/%@/%@",Base_URL,Deleting_Objects_API,objectid];
        } break;
        case kNone:
        default: {
            urlString = @"";
        }break;
    }
    url = [NSURL URLWithString:urlString];
    return url;
}

- (NSString *)getMethodStringForType:(HTTPMethod)method {
    NSString *methodString = nil;
    switch (method) {
        case kDeleteType:
            methodString = @"DELETE";
            break;
        case kGetType: {
            methodString = @"GET";
        } break;
        case kPostType: {
            methodString = @"POST";
        } break;
        default:{
            methodString = @"POST";
        }break;
    }
    return methodString;
}

static NSString * AFBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

@end
