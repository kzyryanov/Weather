//
//  City.h
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

@interface City : NSObject

@property (nonatomic, assign) NSInteger weatherCityId;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) CLLocation* location;

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;

-(NSDictionary*)dictionaryRepresentation;

@end
