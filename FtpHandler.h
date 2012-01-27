//
//  FtpHandler.h
//  SimpleChat
//
//  Created by ARGELA on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSendBufferSize 32768

@interface FtpHandler : NSObject<NSStreamDelegate>
{
    uint8_t           buffer[kSendBufferSize];
}

-(void) downloadFile:(NSString*)fileUrl;
-(void) uploadFile:(NSString*)fileName withFolder:(NSString *)folder;



@end
