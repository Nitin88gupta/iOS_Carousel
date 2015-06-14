//
//  NGCoreDataManager.m
//  NGCarouselGallary
//
//  Created by Nitin Gupta on 13/06/15.
//  Copyright (c) 2015 Nitin Gupta. All rights reserved.
//

#import "NGCoreDataManager.h"
#import "GallaryObject.h"
#import "NGUtilities.h"

static NGCoreDataManager *sharedCoreDataInstance;

@implementation NGCoreDataManager
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (instancetype)sharedCoreData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCoreDataInstance = [[NGCoreDataManager alloc] init];
    });
    return sharedCoreDataInstance;
}

- (instancetype)init
{
    NSAssert(!sharedCoreDataInstance, @"Singleton Pattern Class, Use \" sharedCoreData Method \"");
    self = [super init];
    if (self) {
        [self managedObjectContext];
    }
    return self;
}

- (void)intializeCoreData {
    
}

#pragma mark - Core Data stack
- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.NitinGupta.NGCarouselGallary" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NGCarouselGallary" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"NGCarouselGallary.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - MO Operations 
- (void)checkAndInsertGallaryObjectForInfo:(NSDictionary *)objectInfo {
    if (!objectInfo && !objectInfo.count) {
        return;
    }
    NSError * error;
    NSFetchRequest * fetchReq = [[NSFetchRequest alloc] init];
    [fetchReq setEntity:[NSEntityDescription entityForName:@"GallaryObject"
                                        inManagedObjectContext:_managedObjectContext]];
    [fetchReq setFetchLimit:1];
    
    // check whether the entity exists or not
    [fetchReq setPredicate:[NSPredicate predicateWithFormat:@"objectId == %@",[objectInfo objectForKey:@"objectId"]]];
    
    if ([_managedObjectContext countForFetchRequest:fetchReq error:&error]) {
        // if get a entity, that means exists, Nothing To Do.
        NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchReq error:&error];
        GallaryObject *gallaryObj = [fetchedObjects firstObject];
        UIImage *image = [gallaryObj gallaryImage];
        if (!image) {
            [gallaryObj loadGallaryImage:nil];
        }

    } else {
        // if not exists, just insert a new entity
        GallaryObject *gallaryEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([GallaryObject class])
                                               inManagedObjectContext:_managedObjectContext];
        gallaryEntity.author = [[objectInfo objectForKey:@"author"] copy];
        gallaryEntity.createdAt = [[NGUtilities dateFromString:[objectInfo objectForKey:@"createdAt"]] copy];
        gallaryEntity.img_url = [[objectInfo objectForKey:@"img_url"] copy];
        gallaryEntity.objectId = [[objectInfo objectForKey:@"objectId"] copy];
        gallaryEntity.title = [[objectInfo objectForKey:@"title"] copy];
        gallaryEntity.updatedAt = [[NGUtilities dateFromString:[objectInfo objectForKey:@"updatedAt"]] copy];
        [gallaryEntity loadGallaryImage:nil];
    }
    
    // save
    if (![_managedObjectContext save:&error]) {
        NSLog(@"Couldn't save data to %@", NSStringFromClass([self class]));
    } else {
        NSLog(@"_managedObjectContext Saved Successfully");
    }
}

- (void)checkAndDeleteGallaryObject:(NSString *)objectID {
    if (!objectID || !objectID.length) {
        return;
    }
    NSError * error;
    NSFetchRequest * fetchReq = [[NSFetchRequest alloc] init];
    [fetchReq setEntity:[NSEntityDescription entityForName:@"GallaryObject"
                                    inManagedObjectContext:_managedObjectContext]];
    [fetchReq setFetchLimit:1];
    
    // check whether the entity exists or not
    [fetchReq setPredicate:[NSPredicate predicateWithFormat:@"objectId == %@",objectID]];
    if ([_managedObjectContext countForFetchRequest:fetchReq error:&error]) {
        // if get a entity, that means exists, Nothing To Do.
        NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchReq error:&error];
        GallaryObject *gallaryObj = [fetchedObjects firstObject];
        [_managedObjectContext deleteObject:gallaryObj];
    } else {
        NSLog(@"Delete Object Failed , Object For objectID:%@ Not Found",objectID);
    }
    
    // save
    if (![_managedObjectContext save:&error]) {
        NSLog(@"Couldn't save data to %@", NSStringFromClass([self class]));
    } else {
        NSLog(@"_managedObjectContext Saved Successfully");
    }
}

- (NSArray *)fetchGallayObjectListSortedAscending:(BOOL)ascending forKey:(NSString *)key {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"GallaryObject" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key
                                                                   ascending:ascending];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"No Object Found");
    }
    return fetchedObjects;
}


@end
