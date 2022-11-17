//
//  IAPHelper.m
//  Timerverse
//
//  Created by Justin Cabral on 10/19/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "IAPHelper.h"

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";

@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, readwrite) NSArray *productArray;
@property (nonatomic, readwrite, getter = isPurchased) BOOL purchased;
@property (nonatomic, readwrite, getter = isTransactionInProgress) BOOL transactionInProgress;
@property (nonatomic, readwrite) IAPHelperPurchaseType purchaseType;

@end


@implementation IAPHelper
{
    SKProductsRequest *_productRequest;
    RequestProductsCompletionHandler _completionHandler;
    NSSet *_productIdentifers;
    NSMutableSet *_purchasedProductIdentifiers;
}

#pragma mark - Lifecycle -

- (instancetype)initWithProductIdentifiers:(NSSet *)productIdentifiers
{
    if ((self = [super init]))
    {
        _productIdentifers = productIdentifiers;
        _purchaseType = IAPHelperPurchaseTypeAd;
        
        _purchasedProductIdentifiers = [NSMutableSet set];
        
//        self.purchased = NO;
        
        ///*
        for (NSString *identifier in _productIdentifers)
        {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:identifier];
            
            self.purchased = productPurchased;
            
            if (productPurchased)
            {
                [_purchasedProductIdentifiers addObject:identifier];
//                NSLog(@"Previously purchased: %@", identifier);
            }
            else
            {
//                NSLog(@"Not purchased: %@", identifier);
                
                __weak typeof(self) weakSelf = self;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    [IAPManager requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
                        
                        if (success)
                        {
                            products = [products copy];
                            
                            weakSelf.productArray = [products copy];
                        }
                    }];
                    
                });
            }
        }
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
         
         //*/
    }
    
    return self;
}


#pragma mark - SKProductDelegate -

- (void)productsRequest:(SKProductsRequest *)request
     didReceiveResponse:(SKProductsResponse *)response
{
//    NSLog(@"Loaded list of products...");
    
    _productRequest = nil;
    
    NSArray *skProducts = response.products;
    
//    for (SKProduct *skProduct in skProducts) {
//        NSLog(@"Found product: %@ %@ %0.2f",
//              skProduct.productIdentifier,
//              skProduct.localizedTitle,
//              skProduct.price.floatValue);
//
//    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
//    NSLog(@"Failed to load a list of products");
    
    _productRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
}


#pragma mark - SKPaymentTransactionDelegate -

#pragma mark Transaction
- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                [self startedTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

#pragma mark Restore

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self postNotificationForTransactionState:IAPHelperTransactionStateFailed];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self postNotificationForTransactionState:IAPHelperTransactionStateRestored];
}


#pragma mark - Methods -

#pragma mark Helpers

- (BOOL)productPurchased:(NSString *)productIdentifier
{
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

#pragma mark Public

- (void)buyProduct:(SKProduct *)product
{
    if (self.isTransactionInProgress) return;
    
    self.transactionInProgress = YES;
    
//    NSLog(@"Buying %@...",product.productIdentifier);
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];

}

- (void)restoreCompletedTransactions
{
    if (self.isTransactionInProgress) return;
    
    self.transactionInProgress = YES;
    
    // When restoring, the SKPaymentTransactionStatePurchasing doesn't get called. Only when buying.
    [self startedTransaction:nil];
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
//    NSLog(@"restore transation");
}

#pragma mark Private

- (void)startedTransaction:(SKPaymentTransaction *)transaction
{
//    NSLog(@"startedTransaction...");
    [self postNotificationForTransactionState:IAPHelperTransactionStateStarted];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
//    NSLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self postNotificationForTransactionState:IAPHelperTransactionStateCompleted];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
//    NSLog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self postNotificationForTransactionState:IAPHelperTransactionStateRestored];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
//    NSLog(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
//        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    [self postNotificationForTransactionState:IAPHelperTransactionStateFailed];
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler
{
    _completionHandler = [completionHandler copy];
    
    _productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifers];
    _productRequest.delegate = self;
    [_productRequest start];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier
{
    [self.productArray enumerateObjectsUsingBlock:^(SKProduct *product, NSUInteger index, BOOL *stop) {
        
        if ([product.productIdentifier isEqualToString:productIdentifier])
        {
            self.purchased = YES;
            
            *stop = YES;
        }
        
    }];
    
    [_purchasedProductIdentifiers addObject:productIdentifier];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)postNotificationForTransactionState:(IAPHelperTransactionState)state
{
    self.transactionInProgress = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification
                                                        object:@(state)
                                                      userInfo:nil];
}

@end
