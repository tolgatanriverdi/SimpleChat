//
//  FtpHandler.h
//  SimpleChat
//
//  Created by ARGELA on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FtpHandler : NSObject<NSStreamDelegate>

-(void) downloadFile:(NSString*)fileUrl;
-(void) uploadFile:(NSString*)fileUrl;



@end
