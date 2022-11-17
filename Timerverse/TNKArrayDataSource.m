//
//  TNKArrayDataSource.m
//  ArrayDataSource
//
//  Created by Justin Cabral on 5/27/14.
//  Copyright (c) 2014 Justin Cabral. All rights reserved.
//

#import "TNKArrayDataSource.h"

@interface TNKArrayDataSource ()

@property (nonatomic,strong) NSArray *items;
@property (nonatomic,strong) NSString *cellIdentifier;
@property (nonatomic,copy) void (^configureCell)(id cell, id item, NSIndexPath *indexPath);

@end

@implementation TNKArrayDataSource

- (instancetype) initWithItems:(NSArray *)items
                cellIdentifier:(NSString *)identifier
            configureCellBlock:(ConfigureCellBlock)configureCellBlock
{
    if (self = [super init])
    {
        _items = items;
        _cellIdentifier = identifier;
        _configureCell = configureCellBlock;
    }
    
    return self;
}

/*--- DataSource Helper ---*/
- (id)itemAtIndexPath:(NSIndexPath*)indexPath
{
    return self.items[(NSUInteger)indexPath.row];
}

/*--- TableView DataSource ---*/
- (NSInteger)tableView:(UITableView*)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    id cell = [tableView dequeueReusableCellWithIdentifier:self.cellIdentifier
                                              forIndexPath:indexPath];
    id item = [self itemAtIndexPath:indexPath];
    
    self.configureCell(cell,item,indexPath);
    return cell;
}

/*--- CollectionView DataSource ---*/
#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdentifier
                                                        forIndexPath:indexPath];
    
    id item = [self itemAtIndexPath:indexPath];
   
    self.configureCell(cell,item,indexPath);
    return cell;
}

@end
