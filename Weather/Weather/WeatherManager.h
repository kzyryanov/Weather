//
//  WeatherManager.h
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <INTULocationManager/INTULocationManager.h>

@class City;

extern NSString* const CurrentWeatherType;
extern NSString* const ForecastWeatherType;

extern NSString* const WeatherDomain;

typedef void(^WeatherRequsetBlock)(City* city, NSString* type, NSDictionary* response, NSError* error);

@interface WeatherManager : NSObject

+(instancetype)sharedManager;
+(NSString*)urlStringForIcon:(NSString*)icon;
+(NSString*)windDirectionFromDegrees:(NSInteger)degrees;
+(NSString*)weekdayString:(NSInteger)weekday;

@property (nonatomic, assign) NSInteger selectedCityIndex;
@property (nonatomic, readonly) City* selectedCity;
@property (nonatomic, readonly, strong) NSArray* cities;

-(void)addCity:(City*)city;
-(void)removeCity:(City*)city;

-(void)loadWeatherForCity:(City*)city withCompletion:(WeatherRequsetBlock)completion;

@end
