//
//  NGConstants.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#ifndef NGCarouselGallary_NGConstants_h
#define NGCarouselGallary_NGConstants_h

// Utils
#define Component_Red_Key       @"compR"
#define Component_Green_Key     @"compG"
#define Component_Blue_Key      @"compB"
#define Component_Alpha_Key     @"compA"

#define Text_Color              [UIColor whiteColor]
#define Theme_Color             [UIColor colorWithRed:195.0f/255.0f green:15.0f/255.0f blue:15.0f/255.0f alpha:1.0f]
#define FunctionLog()           NSLog(@"%s",__FUNCTION__)

// Web Service
#define URL_Request_Timeout     180.0f

#define ObjectID_Key            @"objectId"

#define Base_URL                @"https://api.parse.com"
#define Queries_API             @"1/classes/Gallery/"
#define Retrieves_Object_API    @"1/classes/Gallery"
#define Creating_Objects_API    @"1/classes/Gallery"
#define Deleting_Objects_API    @"1/classes/Gallery"

//Carousel
#define Min_Toggle_Duration 0.2
#define Max_Toggle_Duration 0.4
#define Scroll_Duration 0.4
#define Insert_Duration 0.4
#define Decelerate_Threshold 0.1
#define Speed_Scroll_Threshold 2.0
#define Distance_Scroll_Threshold 0.1
#define Deceleration_Multiplier 30.0
#define Float_Error_Margin 0.000001
#define Max_Visible_Items 30

typedef enum {
    kDefaultMode = 0,
    kEditingMode,
    kSearchMode,
}ViewControllerMode;

typedef enum {
    kNone = 0,
    kQueries,
    kRetrieve,
    kCreating,
    kDeleting,
}ServiceType;

typedef enum  {
    kUnknownHTTPType = 0,
    kGetType,
    kPostType,
    kDeleteType,
}HTTPMethod;

typedef enum {
    kImageViewCarouselTag = 11,
    kIndicatorCarouselTag,
    kAuthorLabelCarouselTag,
    kTitleLabelCarouselTag,
    kCheckMarkImageCarouselTag,
}CarouselTag;

#endif
