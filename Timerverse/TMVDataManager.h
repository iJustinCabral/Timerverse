//
//  TMVDataManager.h
//  Timerverse
//
//  Created by Larry Ryan on 1/24/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings.h"

#define DataManager \
((TMVDataManager *)[TMVDataManager sharedDataManager])

@interface TMVDataManager : NSObject

+ (instancetype)sharedDataManager;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) Settings *settings;

- (void)saveContext;

- (void)deleteObject:(id)object;
- (void)deleteObjects:(NSArray *)objects;

#pragma mark - Helpers

- (NSURL *)applicationDocumentsDirectory;

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName;

- (id)insertObjectForEntityName:(NSString *)entityName;

@end
