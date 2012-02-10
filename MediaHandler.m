//
//  MediaHandler.m
//  SimpleChat
//
//  Created by ARGELA on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//TODO gps sinyali bulunup koordinat alinana kadar activity indicator cikacak

#import "MediaHandler.h"
#import "AudioRecordController.h"
#import <CoreLocation/CoreLocation.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBookUI/ABUnknownPersonViewController.h>

#define IMAGE_FILE_PREFIX @"avt_image_"
#define SOUND_FILE_PREFIX @"avt_sound_"

@interface MediaHandler()<AudioRecordControllerDelegate,CLLocationManagerDelegate,ABPeoplePickerNavigationControllerDelegate,ABUnknownPersonViewControllerDelegate>
@property (nonatomic,strong) CLLocationManager* locationManager;
@property (nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@end


@implementation MediaHandler


@synthesize delegate = _delegate;
@synthesize toChatJid = _toChatJid;
@synthesize selfJid = _selfJid;
@synthesize locationManager = _locationManager;
@synthesize activityIndicator = _activityIndicator;

-(void) sendFile:(NSString*)fileName withType:(NSString*)fileType
{
    NSLog(@"Sending File: %@",fileName);
    //Burasi denemek icindir silinecek
    
    NSArray *keys = [NSArray arrayWithObjects:@"filePath",@"fromUserJid",@"toUserJid",@"type", nil];
    NSArray *objects = [NSArray arrayWithObjects:fileName,_selfJid,_toChatJid,fileType, nil];
    //NSLog(@"Count Of Objects: %d Count Of Keys: %d",[objects count],[keys count]);
    NSDictionary *fileContents = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fileSent" object:nil userInfo:fileContents];
}

-(void) sendCoordinate:(double)lattitude andLongitude:(double)longitude
{
    NSLog(@"Sending Coordinate");
    
    NSDictionary *coordCont = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:lattitude],@"lat",[NSNumber numberWithDouble:longitude],@"lon",_toChatJid,@"toUser", nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"coordSent" object:nil userInfo:coordCont];
    
}

-(void) sendContact:(NSMutableDictionary*)contactInfo
{
    NSMutableDictionary *contactCont = contactInfo;
    [contactCont setObject:_toChatJid forKey:@"toUser"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"contactSent" object:nil userInfo:contactCont];
}

-(void) takePhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([mediaTypes containsObject:(NSString*) kUTTypeImage]) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imagePicker setMediaTypes:[NSArray arrayWithObject:(NSString*) kUTTypeImage]];
            [imagePicker setAllowsEditing:NO];
            [_delegate presentMediaPickerController:imagePicker];
        }
        
    }
}

-(void) takeFromGallery
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) 
    {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
        if ([mediaTypes containsObject:(NSString*) kUTTypeImage]) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
            [imagePicker setMediaTypes:[NSArray arrayWithObject:(NSString*) kUTTypeImage]];
            [_delegate presentMediaPickerController:imagePicker];
        }
    }
}


-(void) recordSound
{
    NSString *folderName = [NSString stringWithFormat:@"%@-%@",_toChatJid,[_selfJid bare]];
    NSArray *documentsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = [documentsDir objectAtIndex:0];
    NSString *documentsFullPath = [documentsDirPath stringByAppendingPathComponent:folderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFullPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsFullPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    int fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsFullPath error:nil] count];
    NSString *fullFilePath = [documentsFullPath stringByAppendingPathComponent:SOUND_FILE_PREFIX];
    NSString *fileExactPath = [NSString stringWithFormat:@"%@%d",fullFilePath,fileCount+1];
    NSString *filePathWithExt = [fileExactPath stringByAppendingString:@".caf"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathWithExt]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePathWithExt error:nil];
    }
    
    UIStoryboard *storyBoard = [_delegate mediaHandlerGetStoryBoard];
    AudioRecordController *audioRecordPick = [storyBoard instantiateViewControllerWithIdentifier:@"audioRecordViewCont"];
    [audioRecordPick setDelegate:self];
    [audioRecordPick setRecordFilePath:filePathWithExt];
    [_delegate presentMediaPickerController:audioRecordPick];
}


-(void) getLocation
{
    if ([CLLocationManager locationServicesEnabled])
    {
        if (!_locationManager) {
            NSLog(@"Location Manager Olusturuluyor");
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.delegate = self;
        }
        
        [_locationManager startUpdatingLocation];
        
        /*
        if (!_activityIndicator) {
            _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            _activityIndicator.frame=CGRectMake(145, 160, 25, 25);
            _activityIndicator.tag = 10;
            [_delegate presentActivityIndicator:_activityIndicator];
        }
        

        [_activityIndicator startAnimating];
         */
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"GPS ERROR"
                                                            message:@"LOCATION SERVICES IS DISABLED ON YOUR IPHONE" 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
}

-(void) shareContact
{
    ABPeoplePickerNavigationController *personPicker = [[ABPeoplePickerNavigationController alloc] init];
    personPicker.peoplePickerDelegate = self;
    [_delegate presentMediaPickerController:personPicker];
}

-(void) addContactToList:(NSString *)firstName withLastName:(NSString *)lastName andMobileNo:(NSString *)mobileNo withExtraNumber:(NSString *)extraNo
{
    NSLog(@"ADD To Contact List FirstName: %@ LastName:%@ MobileNo: %@ IphoneNo: %@",firstName,lastName,mobileNo,extraNo);
    ABRecordRef newPerson = ABPersonCreate();
    if (firstName) {
        CFStringRef fName = (__bridge_retained CFStringRef)firstName; 
        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, fName, nil);
    }
    
    if (lastName) {
        CFStringRef lName = (__bridge_retained CFStringRef)lastName;
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, lName, nil);
    }
    
    if (mobileNo || extraNo) {
        ABMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        if (mobileNo) {
            NSLog(@"Mobile No Bulundu");
            CFStringRef mobilNumber = (__bridge_retained CFStringRef) mobileNo; 
            ABMultiValueIdentifier identifier;
            ABMultiValueAddValueAndLabel(phoneNumbers, mobilNumber, kABPersonPhoneMobileLabel, &identifier);
        }
        
        if (extraNo) {
            CFStringRef extraNumber = (__bridge_retained CFStringRef) extraNo;
            ABMultiValueIdentifier identifier;
            ABMultiValueAddValueAndLabel(phoneNumbers, extraNumber, kABPersonPhoneIPhoneLabel, &identifier);
        }
        ABRecordSetValue(newPerson, kABPersonPhoneProperty, phoneNumbers, nil);
    }


    
    ABUnknownPersonViewController *unknownPersonView = [[ABUnknownPersonViewController alloc] init];
    unknownPersonView.unknownPersonViewDelegate = self;
    unknownPersonView.displayedPerson = newPerson;
    unknownPersonView.allowsAddingToAddressBook = YES;
    [_delegate presentMediaResultController:unknownPersonView];
}




/////////////////////////////////////////////////////////////////////////////
-(void) createThumbnailFromImage:(UIImage*)image inFilePath:(NSString*)filePath
{
    
    if (image) {
        UIGraphicsBeginImageContext(CGSizeMake(60.0, 60.0));
        [image drawInRect:CGRectMake(0.0, 0.0, 60.0, 60.0)];
        UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *thumbnailData = UIImagePNGRepresentation(thumbnailImage);
        
        NSString *thumbnailFullPath = [filePath stringByAppendingString:@"_thumbnail.png"];
        //NSLog(@"Creating Thumbnail at: %@",thumbnailFullPath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFullPath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:thumbnailFullPath error:nil];
        }
        
        if ([[NSFileManager defaultManager] createFileAtPath:thumbnailFullPath contents:thumbnailData attributes:nil])
        {
            [self sendFile:thumbnailFullPath withType:@"thumbnail"];
        }
    }
    
}


////DELEGATES


//Image picker delegates
-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *folderName = [NSString stringWithFormat:@"%@-%@",_toChatJid,[_selfJid bare]];
    NSArray *documentsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = [documentsDir objectAtIndex:0];
    NSString *documentsFullPath = [documentsDirPath stringByAppendingPathComponent:folderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFullPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsFullPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    int fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsFullPath error:nil] count];
    NSString *fullFilePath = [documentsFullPath stringByAppendingPathComponent:IMAGE_FILE_PREFIX];
    NSString *fileExactPath = [NSString stringWithFormat:@"%@%d",fullFilePath,fileCount+1];
    NSString *filePathWithExt = [fileExactPath stringByAppendingString:@".png"];
    
    UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    
    UIGraphicsBeginImageContext(CGSizeMake(320.0, 480.0));
    [image drawInRect:CGRectMake(0.0, 0.0, 320.0, 480.0)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self createThumbnailFromImage:resizedImage inFilePath:fileExactPath];
    
    NSData *imageData = UIImagePNGRepresentation(resizedImage);
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathWithExt]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePathWithExt error:nil];
    }
    
    if([[NSFileManager defaultManager] createFileAtPath:filePathWithExt contents:imageData attributes:nil])
    {
        //NSLog(@"Resim Dosyasi Kaydedildi Gonderiliyor");
        [self sendFile:filePathWithExt withType:@"image"];
    }
    
    [_delegate dismissMediaPicker];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [_delegate dismissMediaPicker];
}

//Audio delegates
-(void) audioRecordControllerSendPressed:(NSString *)fileName
{
    [self sendFile:fileName withType:@"audio"];
}


//Location delegates
-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLLocationCoordinate2D coordinates = [newLocation coordinate];
    [self sendCoordinate:coordinates.latitude andLongitude:coordinates.longitude];
    [_locationManager stopUpdatingLocation];
    //[_activityIndicator stopAnimating];
}


//Adress book delegate
-(void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [_delegate dismissMediaPicker];
}

-(BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    NSMutableDictionary *contactDictionary = [[NSMutableDictionary alloc] init];
    NSString *firstName = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*) ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    
    if (firstName) {
        [contactDictionary setObject:firstName forKey:@"firstName"];
    }
    
    if (lastName) {
        [contactDictionary setObject:lastName forKey:@"lastName"];      
    }

    
    //NSLog(@"FirstName: %@ LastName: %@",firstName,lastName);
    
    
    ABMutableMultiValueRef mutableMultiValue = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (CFIndex i=0;i<ABMultiValueGetCount(mutableMultiValue);i++) {
        CFStringRef phoneLabel =  ABMultiValueCopyLabelAtIndex(mutableMultiValue, i);
        CFStringRef phoneValue =  ABMultiValueCopyValueAtIndex(mutableMultiValue, i);
        NSString *phoneNumber = (__bridge_transfer NSString*) phoneValue;
        
        if (CFStringCompare(phoneLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo) {

            [contactDictionary setObject:phoneNumber forKey:@"mobileNumber"];
        }
        else if (CFStringCompare(phoneLabel, kABPersonPhoneIPhoneLabel, 0) == kCFCompareEqualTo) {
            [contactDictionary setObject:phoneNumber forKey:@"iphoneNumber"];
        }
    }
     

    
    CFRelease(mutableMultiValue);
    
    [self sendContact:contactDictionary];
    [_delegate dismissMediaPicker];
    return NO;
}

-(void) unknownPersonViewController:(ABUnknownPersonViewController *)unknownCardViewController didResolveToPerson:(ABRecordRef)person
{
    [_delegate dismissMediaResult];
}

@end
