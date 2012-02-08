//
//  MapViewController.h
//  SimpleChat
//
//  Created by ARGELA on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "XMPPMessageCoreDataObject.h"

@interface MapViewController : UIViewController
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

-(void) setMessage:(XMPPMessageCoreDataObject*)messageObj;

@end
