//
//  WeatherViewController.m
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import "WeatherViewController.h"
#import "City.h"
#import "WeatherManager.h"
#import "CitiesViewController.h"
#import "ForecastCell.h"
#import <AFNetworking/UIKit+AFNetworking.h>

@interface WeatherViewController ()<UICollectionViewDataSource>
{
    NSArray* _forecast;
}

@property (nonatomic, strong) City* city;

@property (nonatomic, assign, getter=isLoading) BOOL loading;

@property (nonatomic, weak) IBOutlet UIView* loadingView;

@property (nonatomic, weak) IBOutlet UIImageView* mainWeatherIcon;
@property (nonatomic, weak) IBOutlet UILabel* mainWeather;
@property (nonatomic, weak) IBOutlet UILabel* temperature;
@property (nonatomic, weak) IBOutlet UILabel* sunrise;
@property (nonatomic, weak) IBOutlet UILabel* sunset;
@property (nonatomic, weak) IBOutlet UILabel* pressure;
@property (nonatomic, weak) IBOutlet UILabel* humidity;
@property (nonatomic, weak) IBOutlet UILabel* wind;
@property (nonatomic, weak) IBOutlet UICollectionView* collectionView;


-(IBAction)reloadAction:(id)sender;

@end

@implementation WeatherViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(nil == self)
    {
        return nil;
    }
    [[WeatherManager sharedManager] addObserver:self forKeyPath:@"selectedCityIndex" options:NSKeyValueObservingOptionNew context:nil];
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedCityIndex"]) {
        [self updateCity];
    }
}

-(void)updateCity
{
    self.city = [WeatherManager sharedManager].selectedCity;
    self.title = self.city.name;
}

-(void)dealloc
{
    [[WeatherManager sharedManager] removeObserver:self forKeyPath:@"selectedCityIndex"];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self updateCity];
}

-(void)setCity:(City *)city
{
    if(_city != city)
    {
        _city = city;
        [self loadWeather];
    }
}

-(void)loadWeather
{
    self.mainWeather.text = nil;
    self.temperature.text = nil;
    self.pressure.text = nil;
    self.humidity.text = nil;
    self.wind.text = nil;
    self.sunrise.text = nil;
    self.sunset.text = nil;
    _forecast = nil;
    [self.collectionView reloadData];
    self.loading = YES;
    __weak __typeof(self) weakSelf = self;
    [[WeatherManager sharedManager] loadWeatherForCity:self.city withCompletion:^(City *city, NSString *type, NSDictionary *response, NSError *error) {
        __weak __typeof(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(strongSelf.city != city)
            {
                return;
            }
            strongSelf.loading = NO;
            if(nil != error)
            {
                NSString* message;
                if([error.domain isEqualToString:WeatherDomain])
                {
                    if(-1 == error.code)
                    {
                        message = @"Error getting location. Please, try to enable location in Settings.";
                    }
                    else if (-2 == error.code)
                    {
                        message = @"Error loading weather. Please, try later.";
                    }
                }
                else if(nil != error)
                {
                    message = error.localizedDescription;
                }
                [strongSelf showError:message];
            }
            else
            {
                if([CurrentWeatherType isEqualToString:type])
                {
                    [self updateCurrentWeather:response];
                }
                else if ([ForecastWeatherType isEqualToString:type])
                {
                    [self updateForecast:response];
                }
            }
        });
    }];
}

-(void)showError:(NSString*)message
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)setLoading:(BOOL)loading
{
    _loading = loading;
    self.loadingView.hidden = !_loading;
}

-(void)updateCurrentWeather:(NSDictionary*)currentWeather
{
    NSDictionary* weather = [currentWeather[@"weather"] firstObject];
    NSString* icon = weather[@"icon"];
    if(0 < icon.length)
    {
        [self.mainWeatherIcon setImageWithURL:[NSURL URLWithString:[WeatherManager urlStringForIcon:icon]]];
    }
    NSString* description = weather[@"description"];
    self.mainWeather.text = [description capitalizedString];
    NSDictionary* main = currentWeather[@"main"];
    NSNumber* temp = main[@"temp"];
    self.temperature.text = [NSString stringWithFormat:@"%.0f", [temp floatValue]];
    NSNumber* pressure = main[@"pressure"];
    self.pressure.text = [NSString stringWithFormat:@"%ld hPa", [pressure integerValue]];
    NSNumber* humidity = main[@"humidity"];
    self.humidity.text = [NSString stringWithFormat:@"%ld%%", [humidity integerValue]];
    NSDictionary* wind = currentWeather[@"wind"];
    NSNumber* windDeg = wind[@"deg"];
    NSNumber* speed = wind[@"speed"];
    self.wind.text = [NSString stringWithFormat:@"%@ %0.1f m/s", [WeatherManager windDirectionFromDegrees:[windDeg integerValue]], [speed floatValue]];
    NSDictionary* sys = currentWeather[@"sys"];
    NSNumber* sunrise = sys[@"sunrise"];
    NSNumber* sunset = sys[@"sunset"];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    NSString* sunriseString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[sunrise doubleValue]]];
    NSString* sunsetString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[sunset doubleValue]]];
    self.sunrise.text = sunriseString;
    self.sunset.text = sunsetString;
}

-(void)updateForecast:(NSDictionary*)forecast
{
    NSArray* list = forecast[@"list"];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    NSMutableArray* forecastItems = [NSMutableArray array];
    
    for(NSInteger i = 0; i < list.count; ++i)
    {
        NSDictionary* item = list[i];
        NSTimeInterval dt = [item[@"dt"] doubleValue];
        NSDate* forecastDate = [NSDate dateWithTimeIntervalSince1970:dt];
        NSDateComponents* components = [calendar components:NSCalendarUnitWeekday fromDate:forecastDate];
        CGFloat minTemp = MAXFLOAT;
        CGFloat maxTemp = -MAXFLOAT;
        NSInteger weekday = components.weekday;
        NSString* icon = [item[@"weather"] firstObject][@"icon"];
        do
        {
            NSTimeInterval dt = [item[@"dt"] doubleValue];
            NSDate* itemDate = [NSDate dateWithTimeIntervalSince1970:dt];
            NSDateComponents* itemComponents = [calendar components:NSCalendarUnitWeekday fromDate:itemDate];
            weekday = itemComponents.weekday;
            NSDictionary* main = item[@"main"];
            CGFloat minItemTemp = [main[@"temp_min"] floatValue];
            CGFloat maxItemTemp = [main[@"temp_max"] floatValue];
            
            minTemp = MIN(minTemp, minItemTemp);
            maxTemp = MAX(maxTemp, maxItemTemp);
            
            ++i;
            if(i < list.count)
            {
                item = list[i];
            }
        }
        while (weekday == components.weekday && i < list.count);
        --i;
        
        NSMutableDictionary* forecastItem = [NSMutableDictionary dictionary];
        forecastItem[@"min_temp"] = @(minTemp);
        forecastItem[@"max_temp"] = @(maxTemp);
        forecastItem[@"weekday"] = @(components.weekday);
        if(nil != icon)
        {
            forecastItem[@"icon"] = icon;
        }
        [forecastItems addObject:forecastItem];
    }
    NSLog(@"%@", forecastItems);
    _forecast = forecastItems;
    [self.collectionView reloadData];
}

#pragma mark - Collection View Data Source

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _forecast.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ForecastCell* cell = (ForecastCell*)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ForecastCell class]) forIndexPath:indexPath];
    cell.item = _forecast[indexPath.row];
    return cell;
}

#pragma mark - Actions

-(void)reloadAction:(id)sender
{
    [self loadWeather];
}

@end
