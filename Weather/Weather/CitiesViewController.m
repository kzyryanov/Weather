//
//  CitiesViewController.m
//  Weather
//
//  Created by Konstantin Zyryanov on 1/25/16.
//  Copyright © 2016 Konstantin Zyryanov. All rights reserved.
//

#import "CitiesViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "WeatherManager.h"
#import "City.h"


@interface CitiesViewController ()<GMSAutocompleteViewControllerDelegate>

-(IBAction)closeAction:(id)sender;
-(IBAction)addCityAction:(id)sender;

@end

@implementation CitiesViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [WeatherManager sharedManager].cities.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CityCell" forIndexPath:indexPath];
    City* city = [WeatherManager sharedManager].cities[indexPath.row];
    cell.textLabel.text = city.name;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0 != indexPath.row;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        City* city = [WeatherManager sharedManager].cities[indexPath.row];
        [[WeatherManager sharedManager] removeCity:city];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [WeatherManager sharedManager].selectedCityIndex = indexPath.row;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Action

-(void)addCityAction:(id)sender
{
    GMSAutocompleteViewController *acController = [[GMSAutocompleteViewController alloc] init];
    acController.delegate = self;
    [self presentViewController:acController animated:YES completion:nil];
}

-(void)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Auto complete delegate

-(void)viewController:(GMSAutocompleteViewController *)viewController didAutocompleteWithPlace:(GMSPlace *)place {
    // Do something with the selected place.
    if(0 < place.name.length)
    {
        City* city = [City new];
        city.name = place.formattedAddress;
        [[WeatherManager sharedManager] addCity:city];
        [self.tableView reloadData];
    }
    NSLog(@"Place name %@", place.name);
    NSLog(@"Place address %@", place.formattedAddress);
    NSLog(@"Place attributions %@", place.attributions.string);
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewController:(GMSAutocompleteViewController *)viewController didFailAutocompleteWithError:(NSError *)error
{
    NSLog(@"error: %@", error);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)wasCancelled:(GMSAutocompleteViewController *)viewController {
    NSLog(@"Autocomplete was cancelled.");
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
