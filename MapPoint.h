//
//  MapPoint.h
//  SimpleChat
//
//  Created by ARGELA on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapPoint : NSObject<MKAnnotation>
{
    CLLocationCoordinate2D coordinate; 
	NSString *title; 
	NSString *subtitle;
}

@property (nonatomic, assign) CLLocationCoordinate2D coordinate; 
@property (nonatomic, copy) NSString *title; 
@property (nonatomic, copy) NSString *subtitle;

@end
