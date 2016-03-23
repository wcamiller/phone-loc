//
//  ViewController.h
//  phone_loc
//
//  Created by William Miller on 6/1/14.
//  Copyright (c) 2014 William Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController : UIViewController <CLLocationManagerDelegate>

- (void)serializeData: (NSDictionary*)latLng;
- (void)reportInputLocation:(NSString*)lat :(NSString*)lng;
- (IBAction)buttonTapped:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UITextField *inputLat;
@property (strong, nonatomic) IBOutlet UITextField *inputLng;

@end
