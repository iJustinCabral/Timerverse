//
//  TMVSwitchCell.m
//  Timerverse
//
//  Created by Larry Ryan on 2/1/14.
//  Copyright (c) 2014 Thinkr. All rights reserved.
//

#import "TMVSwitchCell.h"

@implementation TMVSwitchCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.cellSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 51, 31)];
        //self.cellSwitch.layer.cornerRadius = 16.0;
        self.accessoryView = self.cellSwitch;
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)switchAction:(UISwitch *)sender
{
}



@end
