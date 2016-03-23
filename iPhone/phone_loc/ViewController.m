//
//  ViewController.m
//  phone_loc
//
//  Created by William Miller on 6/1/14.
//  Copyright (c) 2014 William Miller. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>


@interface ViewController ()
@end

@implementation ViewController



CLLocationManager* locationManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)bundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:bundleOrNil]))
    {
        //do your initialisation here
    }
    return self;
}

- (NSMutableArray*)reportLocation {
    NSMutableArray* ary = [[NSMutableArray alloc] initWithCapacity:3];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone: [NSTimeZone timeZoneWithName:@"GMT"]];
    [formatter setDateFormat:@"ddHHmm"];
    [ary addObject:[NSNumber numberWithFloat:locationManager.location.coordinate.latitude]];
    [ary addObject:[NSNumber numberWithFloat:locationManager.location.coordinate.longitude]];
    [ary addObject:[formatter stringFromDate:[NSDate date]]];
    return ary;
}

- (void)reportInputLocation:(NSString*)lat :(NSString*)lng {
    NSNumberFormatter* f = [[NSNumberFormatter alloc]init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSLog(@"I've been called!");
    NSMutableArray* ary = [[NSMutableArray alloc] initWithCapacity:3];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    NSLog(@"I've inited array!");
    NSNumber* lat_num = [f numberFromString:lat];
    NSNumber* lng_num = [f numberFromString:lng];
    [formatter setTimeZone: [NSTimeZone timeZoneWithName:@"GMT"]];
    [formatter setDateFormat:@"ddHHmm"];
    [ary addObject:lat_num];
    [ary addObject:lng_num];
    [ary addObject:[formatter stringFromDate:[NSDate date]]];
    NSLog(@"I've added location data to array!");
    //NSLog(ary);
    NSMutableDictionary* inputLocData = [NSMutableDictionary dictionaryWithObject:ary forKey:@"location"];
    [self serializeData:inputLocData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary* sessionData = @{@"username": @"_fne", @"password": @"1234"};
    NSData* jsonifiedSessionData = [NSJSONSerialization dataWithJSONObject:sessionData options:NSJSONWritingPrettyPrinted error:nil];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://wcamiller.pythonanywhere.com/"]];
    //NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://localhost:5000/"]];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", [jsonifiedSessionData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonifiedSessionData];
    
    NSURLResponse* response;
    NSError* err;
    
    NSLog(@"request: %@", request);
    NSLog(@"request headers: %@", [request allHTTPHeaderFields]);
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&err];
    NSString *resStr = [[NSString alloc]initWithData:responseData encoding:NSASCIIStringEncoding];
    
    NSLog(@"got response==%@", resStr);
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = 250.0;
    locationManager.delegate = self;
    
    [locationManager startUpdatingLocation];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonTapped:(UIButton*)sender {
    NSString* lat = self.inputLat.text;
    NSString* lng = self.inputLng.text;
    [self reportInputLocation:lat :lng];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    return NO;
}

- (void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*) locations {
    //NSLog(@"%@",[locations lastObject]);
    NSMutableDictionary* locData = [NSMutableDictionary dictionaryWithObject:[self reportLocation] forKey:@"location"];
    [self serializeData:locData];
}

- (void)serializeData:(NSDictionary*)locs {
    //NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://localhost:5000/run_post"]];
    NSData* jsonLocData = [NSJSONSerialization dataWithJSONObject:locs options:NSJSONWritingPrettyPrinted error:nil];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://wcamiller.pythonanywhere.com/run_post"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", [jsonLocData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:jsonLocData];
    NSLog(@"request: %@", request);
    NSLog(@"request headers: %@", [request allHTTPHeaderFields]);
    
    NSError *err;
    NSURLResponse *response;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&err];
    
    NSString *resStr = [[NSString alloc]initWithData:responseData encoding:NSASCIIStringEncoding];
    
    NSLog(@"got response==%@", resStr);
    
    if (resStr)
    {
        NSLog(@"RESPONSE SUCCESSFUL");
    }
    
}


@end
