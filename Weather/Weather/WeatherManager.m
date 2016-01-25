//
//  WeatherManager.m
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import "WeatherManager.h"
#import "City.h"
#import <INTULocationManager/INTULocationManager.h>
#import <AFNetworking/AFNetworking.h>

NSString* const WeatherDomain = @"WeatherDomain";

NSString* const CurrentWeatherType = @"weather";
NSString* const ForecastWeatherType = @"forecast";

static NSString* const WeatherApiKey = @"82cf9c055ed6bd6fa1f1022d5470cef2";


static NSString* const kCities = @"kCities";
static NSString* const kSelectedCityIndex = @"kSelectedCityIndex";

static NSString* const APIURL = @"http://api.openweathermap.org/data/2.5";
static NSString* const APIURLFormat = @"http://api.openweathermap.org/data/2.5/%@";

static NSString* const APICurrentLocationFormat = @"%@/%@?appid=%@&lat=%.03f&lon=%.03f";
static NSString* const APICurrentCityFormat = @"%@/%@?appid=%@&q=%@";
static NSString* const APICurrentIdFormat = @"%@/%@?appid=%@&id=%ld";
static NSString* const APIForecastLocationFormat = @"%@/%@?appid=%@&lat=%.03f&lon=%.03f";
static NSString* const APIForecastCityFormat = @"%@/%@?appid=%@&q=%@";
static NSString* const APIForecastIdFormat = @"%@/%@?appid=%@&id=%ld";

static NSString* const APIIconFormat = @"http://openweathermap.org/img/w/%@.png";

@implementation WeatherManager

+(instancetype)sharedManager
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [WeatherManager new];
    });
    
    return instance;
}

+(NSString *)urlStringForIcon:(NSString *)icon
{
    return [NSString stringWithFormat:APIIconFormat, icon];
}

+(NSString *)windDirectionFromDegrees:(NSInteger)degrees
{
    if(22 < degrees && degrees <= 67)
    {
        return @"NE";
    }
    if(67 < degrees && degrees <= 112)
    {
        return @"E";
    }
    if(112 < degrees && degrees <= 157)
    {
        return @"SE";
    }
    if(157 < degrees && degrees <= 202)
    {
        return @"S";
    }
    if(202 < degrees && degrees <= 247)
    {
        return @"SW";
    }
    if(247 < degrees && degrees <= 292)
    {
        return @"W";
    }
    if(292 < degrees && degrees <= 337)
    {
        return @"NW";
    }
    return @"N";
}

+(NSString *)weekdayString:(NSInteger)weekday
{
    switch (weekday) {
        case 1: return @"Mo";
        case 2: return @"Tu";
        case 3: return @"We";
        case 4: return @"Th";
        case 5: return @"Fr";
        case 6: return @"St";
        default: return @"Mo";
    }
}

-(instancetype)init
{
    self = [super init];
    if(nil == self)
    {
        return nil;
    }
    
    NSArray* savedCities =  [[NSUserDefaults standardUserDefaults] objectForKey:kCities];
    
    City* city = [City new];
    city.weatherCityId = -1;
    city.name = @"Current location";
    NSMutableArray* cities = [NSMutableArray arrayWithObject:city];
    
    for (NSDictionary* cityDict in savedCities) {
        [cities addObject:[[City alloc] initWithDictionary:cityDict]];
    }
    
    _cities = cities;
    
    self.selectedCityIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kSelectedCityIndex];
    return self;
}

-(void)saveCities
{
    NSMutableArray* cities = [NSMutableArray new];
    for (City* city in _cities) {
        if(-1 != city.weatherCityId)
        {
            [cities addObject:city.dictionaryRepresentation];
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:cities forKey:kCities];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)addCity:(City *)city
{
    NSAssert(nil != city, @"city must be not null");
    _cities = [self.cities arrayByAddingObject:city];
    [self saveCities];
}

-(void)removeCity:(City *)city
{
    NSAssert(nil != city, @"city must be not null");
    NSPredicate* predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject != city;
    }];
    _cities = [_cities filteredArrayUsingPredicate:predicate];
    [self setSelectedCityIndex:_selectedCityIndex];
    [self saveCities];
}

-(void)setSelectedCityIndex:(NSInteger)selectedCityIndex
{
    _selectedCityIndex = MIN(self.cities.count-1, MAX(0, selectedCityIndex));
    [[NSUserDefaults standardUserDefaults] setInteger:_selectedCityIndex forKey:kSelectedCityIndex];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(City *)selectedCity
{
    return self.cities[self.selectedCityIndex];
}

+(NSURLRequest*)requestWithType:(NSString*)type forCity:(City*)city
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObject:WeatherApiKey forKey:@"appid"];
    if(-1 == city.weatherCityId && nil != city.location)
    {
        parameters[@"lat"] = @(city.location.coordinate.latitude);
        parameters[@"lon"] = @(city.location.coordinate.longitude);
    }
    else if(0 < city.weatherCityId)
    {
        parameters[@"id"] = @(city.weatherCityId);
    }
    else if(0 < city.name)
    {
        parameters[@"q"] = city.name;
    }
    parameters[@"units"] = @"metric";
    
    NSString* urlString = [NSString stringWithFormat:APIURLFormat, type];
    
    NSError* error = nil;
    NSURLRequest* request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:urlString parameters:parameters error:&error];
    if(nil != error)
    {
        NSLog(@"%@", error.localizedDescription);
    }
    
    return request;
}

-(void)loadWeatherForCity:(City *)city withCompletion:(WeatherRequsetBlock)completion
{
    if(-1 == city.weatherCityId)
    {
        __weak __typeof(self) weakSelf = self;
        [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyCity timeout:5 block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
            if (INTULocationStatusSuccess == status) {
                NSLog(@"%@", currentLocation);
                __strong __typeof(self) strongSelf = weakSelf;
                city.location = currentLocation;
                NSURLRequest* currentRequset = [WeatherManager requestWithType:CurrentWeatherType forCity:city];
                [strongSelf sendRequest:currentRequset forCity:city withType:CurrentWeatherType completion:completion];
                NSURLRequest* forecastRequest = [WeatherManager requestWithType:ForecastWeatherType forCity:city];
                [strongSelf sendRequest:forecastRequest forCity:city withType:ForecastWeatherType completion:completion];
            }
            else
            {
                if(nil != completion)
                {
                    completion(city, CurrentWeatherType, nil, [NSError errorWithDomain:WeatherDomain code:-1 userInfo:nil]);
                }
            }
        }];
    }
    else
    {
        NSURLRequest* currentRequset = [WeatherManager requestWithType:CurrentWeatherType forCity:city];
        [self sendRequest:currentRequset forCity:city withType:CurrentWeatherType completion:completion];
        NSURLRequest* forecastRequest = [WeatherManager requestWithType:ForecastWeatherType forCity:city];
        [self sendRequest:forecastRequest forCity:city withType:ForecastWeatherType completion:completion];
    }
}

-(void)sendRequest:(NSURLRequest*)request forCity:(City*)city withType:(NSString*)type completion:(WeatherRequsetBlock)completion
{
    NSLog(@"%@", request);
    if(nil == request)
    {
        if(nil != completion)
        {
            completion(city, type, nil, [NSError errorWithDomain:WeatherDomain code:-2 userInfo:nil]);
        }
        return;
    }
    
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    __weak __typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (nil != error) {
            NSLog(@"Error: %@", error);
        } else {
            NSLog(@"%@ %@", response, responseObject);
        }
        if(nil != completion)
        {
            NSNumber* cityId = responseObject[@"id"];
            if(-1 != city.weatherCityId && nil != cityId)
            {
                city.weatherCityId = [cityId integerValue];
            }
            [strongSelf saveCities];
            completion(city, type, responseObject, error);
        }
    }];
    [dataTask resume];
}

@end
