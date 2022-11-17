//
//  IAPHelper.h
//  Timerverse
//
//  Created by Justin Cabral on 10/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

@import Foundation;
@import StoreKit;

UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;

typedef NS_ENUM (NSUInteger, IAPHelperTransactionState)
{
    IAPHelperTransactionStateStarted,
    IAPHelperTransactionStateCompleted,
    IAPHelperTransactionStateRestored,
    IAPHelperTransactionStateFailed
};

typedef NS_ENUM (NSUInteger, IAPHelperPurchaseType)
{
    IAPHelperPurchaseTypeDemo,
    IAPHelperPurchaseTypeAd
};

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray *products);

@interface IAPHelper : NSObject

@property (nonatomic, readonly) NSArray *productArray;
@property (nonatomic, readonly, getter = isPurchased) BOOL purchased;
@property (nonatomic, readonly, getter = isTransactionInProgress) BOOL transactionInProgress;
@property (nonatomic, readonly) IAPHelperPurchaseType purchaseType;

- (instancetype)initWithProductIdentifiers:(NSSet *)productIdentifiers;

- (void)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (void)restoreCompletedTransactions;


@end
