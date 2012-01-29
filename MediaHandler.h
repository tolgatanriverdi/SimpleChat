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

-(void) presentImagePickerController:(UINavigationController*)imagePicker;
-(void) dismissImagePicker;

@end

@interface MediaHandler : NSObject<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,assign) XMPPJID *toJid;
@property (nonatomic,assign) id<MediaHandlerDelegate> delegate;

-(void) takePhoto;


@end
