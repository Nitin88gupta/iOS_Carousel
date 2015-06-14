//
//  NGLoadingIndicator.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "NGLoadingIndicator.h"
#import "NGConstants.h"

@interface NGLoadingIndicator ()

@property (nonatomic, assign) BOOL interaction;
@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIView *background;
@property (nonatomic, retain) UIToolbar *hud;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, retain) UILabel *label;

@end

static NGLoadingIndicator *sharedInstance;

@implementation NGLoadingIndicator
@synthesize interaction, window, background, hud, spinner, label;

+ (instancetype)sharedLoadingIndicator {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NGLoadingIndicator alloc] init];
    });
    return sharedInstance;
}

- (void)dismiss {
    [self hudHide];
}

- (void)show:(NSString *)status {
    [self setInteraction:YES];
    [self hudMake:status spin:YES hide:NO];
}

- (void)show:(NSString *)status Interaction:(BOOL)Interaction {
    [self setInteraction:Interaction];
    [self hudMake:status spin:YES hide:NO];
}

#pragma mark - Private Methods
- (instancetype)init {
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self) {
        id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
        if ([delegate respondsToSelector:@selector(window)]) {
            window = [delegate performSelector:@selector(window)];
        }
        else {
            window = [[UIApplication sharedApplication] keyWindow];
        }
        self.alpha = 0;
        return self;
    }
    return self;
}

- (void)hudMake:(NSString *)status spin:(BOOL)spin hide:(BOOL)hide {
    [self hudCreate];
    label.text = status;
    label.hidden = (status == nil) ? YES : NO;
    if (spin) {
        [spinner startAnimating];
    }
    else {
        [spinner stopAnimating];
    }

    [self hudOrient];
    [self hudShow];

    if (hide) {
        [NSThread detachNewThreadSelector:@selector(timedHide) toTarget:self withObject:nil];
    }

}


- (void)hudCreate {
    // Tool Bar
    [self addHudToolBar];
    
    // Activity Indicator
    [self addHudActivityIndicator];
    
    //Label
    [self addHudLabel];
}

- (void)addHudToolBar {
    if (hud == nil) {
        hud = [[UIToolbar alloc] initWithFrame:CGRectZero];
        hud.translucent = YES;
        hud.barStyle = UIBarStyleBlackOpaque;
        hud.tintColor = Theme_Color;
        hud.layer.cornerRadius = 10;
        hud.layer.masksToBounds = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    } else {
        //Nothing
    }
    
    if (hud.superview == nil) {
        if (interaction == NO) {
            CGRect frame = CGRectMake(window.frame.origin.x, window.frame.origin.y, window.frame.size.width, window.frame.size.height);
            background = [[UIView alloc] initWithFrame:frame];
            background.backgroundColor = [UIColor clearColor];
            [window addSubview:background];
            [background addSubview:hud];
        }
        else {
            [window addSubview:hud];
        }
    } else {
        //Nothing
    }

}

- (void)addHudActivityIndicator {
    if (spinner == nil) {
        spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.color = [UIColor blackColor];
        spinner.hidesWhenStopped = YES;
    } else {
        //Nothing
    }
    
    if (spinner.superview == nil)  {
        [hud addSubview:spinner];
    } else {
        //Nothing
    }

}

- (void)addHudLabel {
    if (label == nil) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont boldSystemFontOfSize:16];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.numberOfLines = 0;
    } else {
        //Nothing
    }
    
    if (label.superview == nil) {
        [hud addSubview:label];
    } else {
        //Nothing
    }
}

- (void)rotate:(NSNotification *)notification {
    [self hudOrient];
}

- (void)hudOrient {
    CGFloat rotate = 0.0;
    hud.transform = CGAffineTransformMakeRotation(rotate);
    [self hudSize];
}

- (void)hudSize {
    CGRect labelRect = CGRectZero;
    CGFloat hudWidth = 100, hudHeight = 100;
    if (label.text != nil) {
        NSDictionary *attributes = @{NSFontAttributeName:label.font};
        NSInteger options = NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
        int deviceVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
        if (deviceVersion >= 7) {
            labelRect = [label.text boundingRectWithSize:CGSizeMake(200, 300) options:options attributes:attributes context:NULL];
        } else {
            NSAttributedString *attStr = [[NSAttributedString alloc]initWithString:label.text attributes:attributes];
            labelRect = [attStr boundingRectWithSize:(CGSize){200, 300} options:options context:nil];
        }
        labelRect.origin.x = 12;
        labelRect.origin.y = 66;
        hudWidth = labelRect.size.width + 24;
        hudHeight = labelRect.size.height + 80;
        if (hudWidth < 100) {
            hudWidth = 100;
            labelRect.origin.x = 0;
            labelRect.size.width = 100;
        }
    }
    CGSize screen = [UIScreen mainScreen].bounds.size;
    hud.center = CGPointMake(screen.width/2, screen.height/2);
    hud.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
    label.frame = labelRect;
    spinner.center = CGPointMake(hud.frame.size.width/2, hud.frame.size.height/2-5);
}

- (void)hudShow {
    if (self.alpha == 0) {
        self.alpha = 1;
        hud.alpha = 0;
        hud.transform = CGAffineTransformScale(hud.transform, 1.4, 1.4);
        NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut;
        [UIView animateWithDuration:0.15 delay:0 options:options animations:^{
            hud.transform = CGAffineTransformScale(hud.transform, 1/1.4, 1/1.4);
            hud.alpha = 1;
        } completion:nil];
    }
}

- (void)hudHide {
    if (self.alpha == 1) {
        NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn;
        [UIView animateWithDuration:0.15 delay:0 options:options animations:^{
            hud.transform = CGAffineTransformScale(hud.transform, 0.7, 0.7);
            hud.alpha = 0;
        } completion:^(BOOL finished) {
             [self hudDestroy];
             self.alpha = 0;
         }];
    }
}

- (void)timedHide {
    @autoreleasepool {
        double length = label.text.length;
        NSTimeInterval sleep = length * 0.04 + 0.5;
        [NSThread sleepForTimeInterval:sleep];
        [self hudHide];
    }
}

- (void)hudDestroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [label removeFromSuperview];
    label = nil;
    [spinner removeFromSuperview];
    spinner = nil;
    [hud removeFromSuperview];
    hud = nil;
    [background removeFromSuperview];
    background = nil;
}

@end
