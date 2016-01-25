//
//  ForecastCell.m
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import "ForecastCell.h"
#import "WeatherManager.h"
#import <AFNetworking/UIKit+AFNetworking.h>

@interface ForecastCell()

@property (nonatomic, weak) IBOutlet UILabel* dayLabel;
@property (nonatomic, weak) IBOutlet UIImageView* weatherImageView;
@property (nonatomic, weak) IBOutlet UILabel* tempLabel;

@end

@implementation ForecastCell

-(void)setItem:(NSDictionary *)item
{
    if(_item != item)
    {
        _item = [item copy];
    }
    self.dayLabel.text = [WeatherManager weekdayString:[_item[@"weekday"] integerValue]];
    self.weatherImageView.image = nil;
    if(nil != _item[@"icon"])
    {
        [self.weatherImageView setImageWithURL:[NSURL URLWithString:[WeatherManager urlStringForIcon:_item[@"icon"]]]];
    }
    self.tempLabel.text = [NSString stringWithFormat:@"%.0f/%0.f", [_item[@"min_temp"] floatValue], [_item[@"max_temp"] floatValue]];
}

@end
