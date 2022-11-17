//
//  TNKArrayDataSource.h
//  ArrayDataSource
//
//  Created by Justin Cabral on 5/27/14.
//  Copyright (c) 2014 Justin Cabral. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ConfigureCellBlock)(id cell,id item, NSIndexPath *index);


@interface TNKArrayDataSource : NSObject <UITableViewDataSource, UICollectionViewDataSource>

- (instancetype) initWithItems:(NSArray *)items
                cellIdentifier:(NSString *)identifier
            configureCellBlock:(ConfigureCellBlock)configureCellBlock;



- (id)itemAtIndexPath:(NSIndexPath*)indexPath;

@end