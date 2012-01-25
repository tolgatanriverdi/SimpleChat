//
//  FtpHandler.m
//  SimpleChat
//
//  Created by ARGELA on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FtpHandler.h"
#import <CFNetwork/CFFtpStream.h>


@interface FtpHandler()

@property (nonatomic,strong) NSString *ftpUsername;
@property (nonatomic,strong) NSString *ftpPass;
@property (nonatomic,strong) NSInputStream *ftpReadStream;

@property (nonatomic,strong) NSOutputStream *fileStream;


@end

@implementation FtpHandler

@synthesize ftpUsername = _ftpUsername;
@synthesize ftpPass = _ftpPass;
@synthesize ftpReadStream = _ftpReadStream;
@synthesize fileStream = _fileStream;


-(id) init
{
    if (!self) {
        self = [super init];    
    }

    self.ftpUsername = @"ftpuser";
    self.ftpPass = @"ftp*123";
    
    return self;
}

-(void) downloadFile:(NSString *)fileUrl
{
    BOOL success;
    //Indirilecek Dosya Icin URL Olusturur
    NSURL *filePathUrl = [NSURL URLWithString:fileUrl];
    //NSLog(@"Download Starting on %@",[filePathUrl description]);
    
    
    NSString *fileName = [fileUrl lastPathComponent];
    NSArray *documentsTmpPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [documentsTmpPath objectAtIndex:0];
    NSString *outputFilePath = [documentsPath stringByAppendingPathComponent:fileName];
    //NSLog(@"Download File To: %@",outputFilePath);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
    }
    
    self.fileStream = [NSOutputStream outputStreamToFileAtPath:outputFilePath append:NO];

    if (self.fileStream) {
        NSLog(@"File Stream Baslatiliyor");
        [self.fileStream open];
    }
    
    
    //Readstreami olusturur ve username password assign eder
    CFReadStreamRef readStream = CFReadStreamCreateWithFTPURL(NULL,(__bridge_retained CFURLRef) filePathUrl);
    assert(readStream != NULL);
    self.ftpReadStream = (__bridge_transfer NSInputStream*) readStream;
    
    success = [self.ftpReadStream setProperty:self.ftpUsername forKey:(id) kCFStreamPropertyFTPUserName];
    assert(success);
    
    success = [self.ftpReadStream setProperty:self.ftpPass forKey:(id) kCFStreamPropertyFTPPassword];
    assert(success);
    
    [self.ftpReadStream setDelegate:self];
    [self.ftpReadStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.ftpReadStream open];
    CFRelease(readStream);
    //NSLog(@"Download Waits For CallBack");
    
}


-(void) uploadFile:(NSString *)fileUrl
{
    
}


-(void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    //NSLog(@"Delegate Started");
    assert(aStream == self.ftpReadStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Opened connection");
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];  //32KB
            
            // Pull some data off the network.
            
            bytesRead = [self.ftpReadStream read:buffer maxLength:sizeof(buffer)];
            
            NSLog(@"Receiving Size: %d",bytesRead);
            if (bytesRead == -1) {
                NSLog(@"Network Read Error");
            } else if (bytesRead == 0) {
                NSLog(@"Receiving Part Done");
                [self.fileStream close];
            } else {
                NSInteger   bytesWritten;
                NSInteger   bytesWrittenSoFar;
                
                // Write to the file.
                
                bytesWrittenSoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        NSLog(@"File Write Error");
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"Should Never Happen");
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"Stream Open Error : ");
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

@end
