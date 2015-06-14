//
//  ViewController.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "ViewController.h"
#import "NGUtilities.h"
#import "NGConstants.h"
#import "NGWebServiceHelper.h"
#import "NGCoreDataManager.h"
#import "GallaryObject.h"
#import "NGCarousel.h"

@import MobileCoreServices;

@interface ViewController ()<NGCarouselDataSource,NGCarouselDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate> {
    ViewControllerMode _mode;
    BOOL _ascending;
    NSInteger _selectedIndex;
    NSMutableArray *_gallaryCollectionArray;
    IBOutlet NGCarousel *carousel;
    IBOutlet UISegmentedControl *sortSegment;
}
@end

@implementation ViewController

#pragma mark - ViewContoller Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupInterface];
    
    [self updateGallaryDataForObjects:nil deleted:NO];

    [self fetchAllObjectsAPI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    if (_gallaryCollectionArray) {
        [_gallaryCollectionArray removeAllObjects];
    }
    _gallaryCollectionArray = nil;
}
/**
 *  Customize the navigation bar properies
 */
#pragma mark - Navigation Customization

- (void)customizeNavigationInterface {
    UINavigationBar *navigationBarAppearance = [[self navigationController] navigationBar];
    CGSize _size = [[self navigationController] navigationBar].frame.size;
    _size.height  = _size.height + [[UIApplication sharedApplication]statusBarFrame].size.height;
    UIImage * backgroundImage = [NGUtilities imageFromColor:Theme_Color withSize:_size];
    
    NSDictionary *textAttributes = @{
                       NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                       NSForegroundColorAttributeName: Text_Color,
                       };
    
    [navigationBarAppearance setBackgroundImage:backgroundImage
                                  forBarMetrics:UIBarMetricsDefault];
    [navigationBarAppearance setTitleTextAttributes:textAttributes];
    [navigationBarAppearance setTintColor:Text_Color];
    
    [self updateNavigationInterface];
}

- (void)updateNavigationInterface {
    switch (_mode) {
        case kDefaultMode: {
            [self navigationForDefualtMode];
        } break;
        case kEditingMode: {
            [self navigationForEditMode];
        } break;
        default: {
            
        } break;
    }
}

- (void)navigationForDefualtMode {
    [self navigationItem].leftBarButtonItem = nil;
    [self navigationItem].rightBarButtonItem = nil;
    
    UIButton *leftAddButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [leftAddButton addTarget:self action:@selector(addItemsToGallaryAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarItem = [[UIBarButtonItem alloc] initWithCustomView:leftAddButton];
    [self navigationItem].leftBarButtonItem = leftBarItem;
    
    UIButton *rightSortButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightSortButton setFrame:CGRectMake(0, 0, 20, 20)];
    [rightSortButton addTarget:self action:@selector(sortItemsAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightSortButton setImage:[UIImage imageNamed:@"SortIcon.png"] forState:UIControlStateNormal];
    UIBarButtonItem *secondRightBarItem = [[UIBarButtonItem alloc] initWithCustomView:rightSortButton];
    
    UIButton *rightSearchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightSearchButton  setFrame:CGRectMake(0, 0, 20, 20)];
    [rightSearchButton addTarget:self action:@selector(searchItemsAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightSearchButton setImage:[UIImage imageNamed:@"SearchIcon.png"] forState:UIControlStateNormal];
    UIBarButtonItem *firstRightBarItem = [[UIBarButtonItem alloc] initWithCustomView:rightSearchButton];

    [self navigationItem].rightBarButtonItems = @[secondRightBarItem,firstRightBarItem];
}

- (void)navigationForEditMode {
    [self navigationItem].leftBarButtonItem = nil;
    [self navigationItem].rightBarButtonItem = nil;

    UIButton *leftDeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftDeleteButton addTarget:self action:@selector(deleteItemsFromGallaryAction:) forControlEvents:UIControlEventTouchUpInside];
    [leftDeleteButton  setFrame:CGRectMake(0, 0, 20, 25)];
    [leftDeleteButton setImage:[UIImage imageNamed:@"DeleteIcon.png"] forState:UIControlStateNormal];
    UIBarButtonItem *leftBarItem = [[UIBarButtonItem alloc] initWithCustomView:leftDeleteButton];
    [self navigationItem].leftBarButtonItem = leftBarItem;
    
    UIButton *rightDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightDoneButton  setFrame:CGRectMake(0, 0, 60, 30)];
    [rightDoneButton addTarget:self action:@selector(doneButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    UIBarButtonItem *firstItem = [[UIBarButtonItem alloc] initWithCustomView:rightDoneButton];

    [self navigationItem].rightBarButtonItem = firstItem;

}

#pragma mark - View Life Cycle
- (void)setupInterface  {
    _mode = kDefaultMode;
    _ascending = YES;
    _selectedIndex = -1;
    
    [carousel setDataSource:self];
    [carousel setDelegate:self];
    
    [self customizeNavigationInterface];

    [self setTitle:@"Gallary"];

    [sortSegment setTintColor:Theme_Color];
}

- (void)updateGallaryDataForObjects:(NSArray *)objectsArray deleted:(BOOL)delete {
    // Initialize MO
    for (id obj in objectsArray) {
        if (delete) {
            //obj is NSString Object ID while Deleting
            [[NGCoreDataManager sharedCoreData] checkAndDeleteGallaryObject:obj];
        } else {
            //obj is NSDictionary
            [[NGCoreDataManager sharedCoreData] checkAndInsertGallaryObjectForInfo:obj];
        }
    }
    // Fetching Data Request
    if (!_gallaryCollectionArray) {
        _gallaryCollectionArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    [_gallaryCollectionArray removeAllObjects];
   
    NSString *sortKey = nil;
    if (sortSegment.selectedSegmentIndex == 0) {
        sortKey = @"author";
    } else {
        sortKey = @"title";
    }
    
    NSArray *objectArray = [[NGCoreDataManager sharedCoreData] fetchGallayObjectListSortedAscending:_ascending forKey:sortKey];
    [_gallaryCollectionArray addObjectsFromArray:objectArray];

    // Reload Data
    [carousel reloadData];
}

- (void)openPhotoLibrary:(BOOL)library {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    
    [imagePickerController.navigationBar setTranslucent:NO];
    [imagePickerController.navigationBar setOpaque:YES];
    [imagePickerController.navigationBar setTintColor:[UIColor blackColor]];
    imagePickerController.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
    [imagePickerController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        [self presentViewController:imagePickerController animated:YES completion:NULL];
    }
}

- (void)openCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController* imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePickerController.mediaTypes = [NSArray arrayWithObjects:
                                            (NSString *) kUTTypeImage,
                                            (NSString *) kUTTypeMovie, nil];
        [self presentViewController:imagePickerController animated:YES completion:nil];    }
}

#pragma mark - Web Service API
- (void)fetchAllObjectsAPI {
    NGWebServiceHelper *webService = [[NGWebServiceHelper alloc] init];
    if (![_gallaryCollectionArray count]) {
        //First Time
        [NGUtilities showLoadingIndicator:@"Fetching..."];
    } else {
        // Fetching data and Adding to DB, No Indicator
    }
    [webService sendAsynchronousRequest:kQueries withRequestDictionary:nil HTTPMethod:kGetType imageArray:nil completionHandler:^(BOOL status, id response, NSError *error, id service) {
        if (status) {
            __block NSArray *resultArray = [response objectForKey:@"results"];
            if (resultArray.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateGallaryDataForObjects:resultArray deleted:NO];
                });
            }
        } else {
            NSLog(@"error = %@",[error localizedDescription]);
        }
        [NGUtilities hideLoadingIndicator];
        service = nil;
    }];
}

- (void)fecthObjectAPIForID:(NSString *)objectID {
    NGWebServiceHelper *webService = [[NGWebServiceHelper alloc] init];
    [NGUtilities showLoadingIndicator:@"Fetching..."];
    [webService sendAsynchronousRequest:kRetrieve withRequestDictionary:@{ObjectID_Key:objectID} HTTPMethod:kGetType imageArray:nil completionHandler:^(BOOL status, id response, NSError *error, id service) {
        if (status) {
            NSArray *resultArray = [response objectForKey:@"results"];
            if (resultArray.count) {
                //TODO:Flow
            }
        }
        [NGUtilities hideLoadingIndicator];
        service = nil;
    }];
}

- (void)addObjectAPI:(UIImage *)image {
    if (image) {
            NGWebServiceHelper *webService = [[NGWebServiceHelper alloc] init];
            [NGUtilities showLoadingIndicator:@"Adding..."];
            [webService sendAsynchronousRequest:kCreating
                          withRequestDictionary:nil
                                     HTTPMethod:kPostType
                                     imageArray:@[image]
                              completionHandler:^(BOOL status, id response, NSError *error, id service) {
                if (status) {
                    NSArray *resultArray = [response objectForKey:@"results"];
                    if (resultArray.count) {
                        //TODO:Flow
                    } else {
                        NSLog(@"error = %@, code = %@",[response objectForKey:@"error"],[response objectForKey:@"code"]);
                    }
                } else {
                    NSLog(@"error = %@",[error localizedDescription]);
                }
                [NGUtilities hideLoadingIndicator];
                service = nil;
            }];
    } else {
        // Nothing
    }
}

- (void)deleteObjectAPIForID:(NSString *)objectID {
    NGWebServiceHelper *webService = [[NGWebServiceHelper alloc] init];
    [NGUtilities showLoadingIndicator:@"Deleting..."];
    [webService sendAsynchronousRequest:kDeleting withRequestDictionary:@{ObjectID_Key:objectID} HTTPMethod:kDeleteType imageArray:nil completionHandler:^(BOOL status, id response, NSError *error, id service) {
        if (status) {
            NSString *code = [response objectForKey:@"code"];
            int codeIntValue = (int)[code integerValue];
            if (codeIntValue == 101 || codeIntValue == 200) {
                // Deleteing in both case if Item Deleted Or Not Exist For Deleting
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateGallaryDataForObjects:@[objectID] deleted:YES];
                });
            }
        } else {
            NSLog(@"error = %@, code = %@",[response objectForKey:@"error"],[response objectForKey:@"code"]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _mode = kDefaultMode;
            [carousel deselectAllCheckMarked];
            [self updateNavigationInterface];
        });
        [NGUtilities hideLoadingIndicator];
        service = nil;
    }];
}

#pragma mark - IBActions

-(IBAction)addItemsToGallaryAction:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera",@"Library", nil];
    [actionSheet setTag:1212];
    [actionSheet showInView:self.view];
}

- (IBAction)deleteItemsFromGallaryAction:(id)sender {
    if (_selectedIndex >= 0) {
        GallaryObject *gallaryObj = [_gallaryCollectionArray objectAtIndex:_selectedIndex];
        NSString *objID = [gallaryObj objectId];
        [self deleteObjectAPIForID:objID];
    } else {
        _mode = kDefaultMode;
        [carousel deselectAllCheckMarked];
        [self updateNavigationInterface];
    }
}

- (IBAction)sortItemsAction:(id)sender {
    [(UIButton *)sender setTransform:CGAffineTransformRotate([(UIButton *)sender transform], -M_PI)];
    _ascending = !_ascending;
    
    // Reloading Data
    [self updateGallaryDataForObjects:nil deleted:NO];
}
- (IBAction)searchItemsAction:(id)sender {
    FunctionLog();
    
}

- (IBAction)doneButtonAction:(id)sender {
    _mode = kDefaultMode;
    [carousel deselectAllCheckMarked];
    [self updateNavigationInterface];
}

- (IBAction)sortSegmentValueChanged:(id)sender {
    // Reloading Data
    [self updateGallaryDataForObjects:nil deleted:NO];
}

#pragma mark - NGCarousel Data Delegates

- (NSInteger)numberOfItemsInCarousel:(NGCarousel *)carouselView {
    return [_gallaryCollectionArray count];
}

- (void)carousel:(NGCarousel *)carouselView viewForItemAtIndex:(NSInteger)index {
    FunctionLog();
    [carouselView setGallaryObject:nil];
    GallaryObject *gallaryObj = [_gallaryCollectionArray objectAtIndex:index];
    [carousel setGallaryObject:gallaryObj];
}

#pragma mark - NGCarouselDelegate
- (BOOL)carousel:(NGCarousel *)carouselView shouldSelectItemAtIndex:(NSInteger)index {
    return YES;
}

- (void)carousel:(NGCarousel *)carouselView didSelectItemAtIndex:(NSInteger)index itemView:(UIView *)itemView {
    _selectedIndex = index;
    _mode = kEditingMode;
   
    [self updateNavigationInterface];
    
    [carouselView deselectAllCheckMarked];
    UIImageView * checkMarkImageView = (UIImageView*)[itemView viewWithTag:kCheckMarkImageCarouselTag];
    [checkMarkImageView setHidden:NO];
}

#pragma mark  UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 1212) {
        if (buttonIndex == 0 || buttonIndex == 1) {
            if (buttonIndex == 1) {
                NSLog(@"Library");
            } else {
                NSLog(@"Camera");
            }
            [self openPhotoLibrary:buttonIndex];
        }
        else {
            // Nothing
        }
    } else {
        // Nothing
    }
    
    if(buttonIndex == [actionSheet cancelButtonIndex]) {
        [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    }
}

#pragma mark - ImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    NSString *mediaType;
    if ([[info allKeys] containsObject:@"UIImagePickerControllerMediaType"]) {
        mediaType = [info objectForKey:@"UIImagePickerControllerMediaType"];
    }
    
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *originalImage = nil;
        originalImage = [info objectForKey:UIImagePickerControllerEditedImage];
        [self addObjectAPI:originalImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

@end
