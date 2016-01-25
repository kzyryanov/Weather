//
//  City.m
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import "City.h"

@implementation City

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(nil == self)
    {
        return nil;
    }
    
    _name = dictionary[@"name"];
    _weatherCityId = [dictionary[@"weatherCityId"] integerValue];
    
    return self;
}

-(NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary* cityDict = [NSMutableDictionary new];
    if (0 < self.name.length) {
        cityDict[@"name"] = self.name;
    }
    cityDict[@"weatherCityId"] = @(self.weatherCityId);
    return cityDict;
}

@end
