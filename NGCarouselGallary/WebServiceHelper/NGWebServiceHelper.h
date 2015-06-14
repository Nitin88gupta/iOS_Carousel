//
//  NGWebServiceHelper.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGConstants.h"

typedef void(^requestCompletionHandler)(BOOL status, id response, NSError *error, id service);

@interface NGWebServiceHelper : NSObject

/**
 *  Sending Asynchronous Request
 *
 *  @param requestType Request Type To diffentiate
 *  @param dictionary  Info Dict, Could be nil Value ..will be handeled gracefully
 *  @param imageArray In Case Images are associated to upload on server
 *  @param handler     a completion Handler Block
 */
- (void)sendAsynchronousRequest:(ServiceType)requestType
          withRequestDictionary:(NSDictionary *)dictionary
                     HTTPMethod:(HTTPMethod)method
                     imageArray:(NSArray *)imageArray
              completionHandler:(requestCompletionHandler) handler;

/**
 *  Sending Synchronous Request
 *
 *  @param requestType Request Type To diffentiate
 *  @param dictionary  Info Dict, Could be nil Value ..will be handeled gracefully
 *  @param imageArray In Case Images are associated to upload on server
 *  @param handler     a completion Handler Block
 */
- (void)sendSynchronousRequest:(ServiceType)requestType
         withRequestDictionary:(NSDictionary *)dictionary
                    HTTPMethod:(HTTPMethod)method
                    imageArray:(NSArray *)imageArray
             completionHandler:(requestCompletionHandler)handler;

@end
