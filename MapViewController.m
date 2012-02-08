//
//  MapViewController.m
//  SimpleChat
//
//  Created by ARGELA on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "MapPoint.h"
#import "XMPPMessageUserCoreDataObject.h"


@interface MapViewController()<CLLocationManagerDelegate,MKMapViewDelegate>
@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) NSMutableArray *annotations;
@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize locationManager = _locationManager;
@synthesize annotations = _annotations;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    NSLog(@"View Did Load");
    [super viewDidLoad];
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDistanceFilter:kCLDistanceFilterNone];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [_mapView setDelegate:self];
    //[_mapView setShowsUserLocation:YES];
}


- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) updateMap
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
}

-(void) setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    [self updateMap];
}

-(void)setMessage:(XMPPMessageCoreDataObject *)messageObj
{
    NSString *messageBody = messageObj.body;
    NSArray *coordinates = [messageBody componentsSeparatedByString:@","];
    CLLocationCoordinate2D locationCoord;
    locationCoord.latitude = [[coordinates objectAtIndex:0] doubleValue];
    locationCoord.longitude = [[coordinates objectAtIndex:1] doubleValue];
    
    //NSLog(@"Map View Controllera Geldi Lat: %f Lon: %f",locationCoord.latitude,locationCoord.longitude);
    
    NSString *userDisplay = messageObj.whoOwns.displayName;
    if (messageObj.selfReplied == [NSNumber numberWithInt:1]) {
        userDisplay = messageObj.messageReceipant;
    }
    
    MapPoint *mp = [[MapPoint alloc] init];
    mp.title = userDisplay;
    mp.subtitle = @"Su An Burada";
    mp.coordinate = locationCoord;
    //NSLog(@"MP Title: %@ SubTitle: %@ Latitude: %f Long: %f",mp.title,mp.subtitle,mp.coordinate.latitude,mp.coordinate.longitude);
    if (!_annotations) {
        _annotations = [[NSMutableArray alloc] init];
    }
    
    [_annotations addObject:mp];
    [self updateMap];
}


////DELEGATES

-(void) mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    //NSLog(@"DidAddAnnotatinView Geldii");
    //User location a degil bizden gelen koordinata zoom yapmasi icin degisiklik yapilacak
    MKAnnotationView *annotationView = [views objectAtIndex:0];
    id<MKAnnotation> mp = [annotationView annotation];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate], 250, 250);
    [mapView setRegion:region animated:YES];
}

-(MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //NSLog(@"view for annotation geldiii");
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    NSString *annotationIdentifier = @"PinViewAnnotation";
    MKPinAnnotationView *pinView = (MKPinAnnotationView*) [_mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    

    if (!pinView)
    {
        NSLog(@"Yeni Map Pin Yaratiliyor");
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        [pinView setPinColor:MKPinAnnotationColorGreen];
        pinView.animatesDrop = YES;
        pinView.canShowCallout = YES;        
    }
    else
    {
        NSLog(@"Eski Map Pin Kullaniliyor");
        pinView.annotation = annotation;
    }
    
    return pinView;

}


@end
