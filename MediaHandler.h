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
-(UIStoryboard*) mediaHandlerGetStoryBoard;

@end

@interface MediaHandler : NSObject<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,assign) NSString *toChatJid;
@property (nonatomic,assign) XMPPJID *selfJid;
@property (nonatomic,assign) id<MediaHandlerDelegate> delegate;

-(void) takePhoto;
-(void) takeFromGallery;
-(void) recordSound;


@end
