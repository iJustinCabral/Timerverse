//
//  TMVIAPHelper.h
//  Timerverse
//
//  Created by Justin Cabral on 10/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "IAPHelper.h"

#define IAPManager \
((TMVIAPManager *)[TMVIAPManager sharedIAPManager])

@interface TMVIAPManager : IAPHelper

+ (TMVIAPManager *)sharedIAPManager;

@end
