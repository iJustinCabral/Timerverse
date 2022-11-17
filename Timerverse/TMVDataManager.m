//
//  TMVDataManager.m
//  Timerverse
//
//  Created by Larry Ryan on 1/24/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVDataManager.h"

@interface TMVDataManager ()
@property (nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;


@end

@implementation TMVDataManager

+ (instancetype)sharedDataManager
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Settings

- (Settings *)settings
{
    if (!_settings)
    {
        NSArray *settings = [DataManager fetchObjectsForEntityName:@"Settings"];
        
        if (settings.count == 0 || !settings)
        {
            _settings = [DataManager insertObjectForEntityName:@"Settings"];
            
            // Alerts
            _settings.alertVibrationEnabled = @YES;
            // Effects
            _settings.effectGridLockEnabled = @YES;
            // Stats
            _settings.totalCountedSeconds = @0;
        }
        else
        {
            _settings = settings.firstObject;
        }
    }
    
    return _settings;
}

- (void)saveContext
{
    NSError *error = nil;
    if (_managedObjectContext != nil)
    {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error])
        {
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle]  URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {

    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)deleteObject:(id)object
{
    [_managedObjectContext deleteObject:object];
    
    [self saveContext];
}

- (void)deleteObjects:(NSArray *)objects
{
    for (id object in objects)
    {
        if (!object) return;
        [_managedObjectContext deleteObject:object];
    }
    
    [self saveContext];
}

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *object = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:object];
    
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
}

- (id)insertObjectForEntityName:(NSString *)entityName
{
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                         inManagedObjectContext:self.managedObjectContext];
}

@end
