//
//  NGCoreDataManager.h
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NGCoreDataManager : NSObject

+ (instancetype)sharedCoreData;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)intializeCoreData;
- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;

//MO Operations
- (void)checkAndInsertGallaryObjectForInfo:(NSDictionary *)objectInfo;
- (void)checkAndDeleteGallaryObject:(NSString *)objectID;
- (NSArray *)fetchGallayObjectListSortedAscending:(BOOL)ascending forKey:(NSString *)key;

@end
