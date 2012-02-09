//
//  MediaHandler.h
//  SimpleChat
//
//  Created by ARGELA on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "XMPPFramework.h"


@protocol MediaHandlerDelegate

-(void) presentMediaPickerController:(UIViewController*)mediaPicker;
-(void) dismissMediaPicker;
-(void) presentMediaResultController:(UIViewController*)mediaResult;
-(void) dismissMediaResult;
-(void) presentActivityIndicator:(UIActivityIndicatorView*)activityIndicator;
-(void) dismissActivityIndicator:(NSInteger)tag;
-(UIStoryboard*) mediaHandlerGetStoryBoard;

@end

@interface MediaHandler : NSObject<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,assign) NSString *toChatJid;
@property (nonatomic,assign) XMPPJID *selfJid;
@property (nonatomic,assign) id<MediaHandlerDelegate> delegate;

-(void) takePhoto;
-(void) takeFromGallery;
-(void) recordSound;
-(void) getLocation;
-(void) shareContact;
-(void) addContactToList:(NSString*)firstName withLastName:(NSString*)lastName andMobileNo:(NSString*)mobileNo withExtraNumber:(NSString*)extraNo;


@end
