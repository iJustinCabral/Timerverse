//
//  TMVIAPHelper.m
//  Timerverse
//
//  Created by Justin Cabral on 10/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVIAPManager.h"

@implementation TMVIAPManager

+ (TMVIAPManager *)sharedIAPManager {
    
    static dispatch_once_t once;
    static TMVIAPManager *sharedInstance;
    
    dispatch_once(&once, ^{
        
        NSSet * productIdentifiers = [NSSet setWithObjects:@"us.thinkr.timerverse.pro", nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    
    });
    
    return sharedInstance;
}

@end
