//
//  FtpHandler.h
//  SimpleChat
//
//  Created by ARGELA on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kSendBufferSize 32768

@protocol FtpHandlerDelegate <NSObject>

-(void) ftpUploadStatusChanged:(BOOL)suceed withLocalFileName:(NSString*)fileName andRemoteFileName:(NSString*)remoteFileName andType:(NSString*)type toUser:(NSString*)userId;
-(void) ftpDownloadStatusChanged:(BOOL)suceed withFileName:(NSString*)fileName withType:(NSString*)type fromUser:(NSString*)userId;
@end

@interface FtpHandler : NSObject<NSStreamDelegate>
{
    uint8_t  buffer[kSendBufferSize];
}

@property (nonatomic,assign) id<FtpHandlerDelegate> delegate;

-(void) downloadFile:(NSString*)fileUrl inFolder:(NSString*)folderName withType:(NSString*)type fromUser:(NSString*)userId;
-(void) uploadFile:(NSString*)fileName withFolder:(NSString *)folder withType:(NSString*)type toUser:(NSString*)userId;
-(NSString*) getRemoteFileName:(NSString*)forLocalFile;

@end
