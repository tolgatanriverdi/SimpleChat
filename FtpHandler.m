//
//  FtpHandler.m
//  SimpleChat
//
//  Created by ARGELA on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//TODO Readstream icin hata dondugunda baglantiyi kapatmayi ekle
//TODO Butun hardcoded girilen stringleri property dosyalarindan al

#import "FtpHandler.h"
#import <CFNetwork/CFFtpStream.h>




@interface FtpHandler()

@property (nonatomic,strong) NSString *ftpUsername;
@property (nonatomic,strong) NSString *ftpPass;
@property (nonatomic,strong) NSString *ftpUploadHost;

//Download Icin Gerekli Olanlar
@property (nonatomic,strong) NSInputStream *ftpReadStream;
@property (nonatomic,strong) NSOutputStream *fileStream;
@property (nonatomic,strong) NSString *downloadingFileName;
@property (nonatomic,strong) NSString *downloadingRemoteFileName;


//Upload Icin Gerekli Olanlar
@property (strong) NSOutputStream *ftpCreateDirStream;
@property (strong) NSOutputStream *ftpWriteStream;
@property (strong) NSInputStream *ftpWriteFileStream;
@property (strong) NSURL *uploadURLWithFolder;
@property (strong) NSString *uploadingFileName;

@property (nonatomic, readonly) uint8_t *   buffer;
@property (nonatomic, assign)   size_t      bufferOffset;
@property (nonatomic, assign)   size_t      bufferLimit;


@property (nonatomic,strong) NSMutableArray *mediaUploadQueue;
@property (nonatomic,strong) NSMutableArray *mediaDownloadQueue;
@property (nonatomic,strong) NSMutableArray *remoteLocalFileNames;

@end

@implementation FtpHandler

@synthesize ftpUsername = _ftpUsername;
@synthesize ftpPass = _ftpPass;
@synthesize ftpReadStream = _ftpReadStream;
@synthesize fileStream = _fileStream;
@synthesize ftpUploadHost = _ftpUploadHost;
@synthesize ftpCreateDirStream = _ftpCreateDirStream;
@synthesize ftpWriteStream = _ftpWriteStream;
@synthesize ftpWriteFileStream = _ftpWriteFileStream;
@synthesize uploadURLWithFolder = _uploadURLWithFolder;
@synthesize uploadingFileName = _uploadingFileName;
@synthesize downloadingFileName = _downloadingFileName;
@synthesize downloadingRemoteFileName = _downloadingRemoteFileName;
@synthesize buffer = _buffer;
@synthesize bufferOffset = _bufferOffset;
@synthesize bufferLimit = _bufferLimit;
@synthesize delegate = _delegate;
@synthesize mediaDownloadQueue = _mediaDownloadQueue;
@synthesize mediaUploadQueue = _mediaUploadQueue;
@synthesize remoteLocalFileNames = _remoteLocalFileNames;


- (uint8_t *)buffer
{
    return self->buffer;
}


-(id) init
{
    if (!self) {
        self = [super init];    
    }

    self.ftpUsername = @"ftpuser";
    self.ftpPass = @"ftp*123";
    self.ftpUploadHost = @"ftp://95.0.221.23";
    //self.ftpUploadHost = @"ftp://192.168.3.104";
    
    
    _mediaDownloadQueue = [[NSMutableArray alloc] init];
    _mediaUploadQueue = [[NSMutableArray alloc] init];
    _remoteLocalFileNames = [[NSMutableArray alloc] init];
    
    return self;
}

-(NSString*)getRemoteFileName:(NSString *)forLocalFile
{
    NSString *result;
    for (int i=0;i<[_remoteLocalFileNames count];i++) {
        NSDictionary *fileInfo = [_remoteLocalFileNames objectAtIndex:i];
        if ([fileInfo objectForKey:forLocalFile]) {
            result = [fileInfo objectForKey:forLocalFile];
            [_remoteLocalFileNames removeObjectAtIndex:i];
            break;
        }
    }
    
    return result;
}



-(void) downloadFile:(NSString *)fileUrl inFolder:(NSString *)folderName withType:(NSString *)type fromUser:(NSString *)userId
{
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:fileUrl,@"fileName",folderName,@"folderName",type,@"type",userId,@"userName", nil];
    [_mediaDownloadQueue addObject:dictionary];
    
    //Dictionary queue nin icindeki ilk objeyi upload etmek icin
    NSDictionary *checkDict;
    if ([_mediaDownloadQueue count] > 0) {
        checkDict = [_mediaDownloadQueue objectAtIndex:0];
    }
    
    if ([[checkDict objectForKey:@"fileName"] isEqualToString:fileUrl]) 
    {
        _downloadingRemoteFileName = fileUrl;
        BOOL success;
        //Indirilecek Dosya Icin URL Olusturur
        NSURL *filePathUrl = [NSURL URLWithString:fileUrl];
        //NSLog(@"Download Starting on %@",[filePathUrl description]);
        
        
        NSString *fileName = [fileUrl lastPathComponent];
        NSArray *documentsTmpPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [documentsTmpPath objectAtIndex:0];
        NSString *outputDirPath = [documentsPath stringByAppendingPathComponent:folderName];
        //NSLog(@"Download File To: %@",outputFilePath);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:outputDirPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:outputDirPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        NSString *outputFilePath = [outputDirPath stringByAppendingPathComponent:fileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
        }
        _downloadingFileName = outputFilePath;
        
        
        //Bu dictionary indirilen local dosyaya karsilik gelen remote url i tutar
        NSDictionary *remoteLocalDictionary = [NSDictionary dictionaryWithObjectsAndKeys:_downloadingRemoteFileName,_downloadingFileName, nil];
        [_remoteLocalFileNames addObject:remoteLocalDictionary];
        
        
        _fileStream = [NSOutputStream outputStreamToFileAtPath:outputFilePath append:NO];
        
        if (self.fileStream) {
            NSLog(@"File Stream Baslatiliyor");
            [_fileStream open];
        }
        
        
        //Readstreami olusturur ve username password assign eder
        CFReadStreamRef readStream = CFReadStreamCreateWithFTPURL(NULL,(__bridge_retained CFURLRef) filePathUrl);
        assert(readStream != NULL);
        _ftpReadStream = objc_unretainedObject(readStream);
        
        success = [_ftpReadStream setProperty:self.ftpUsername forKey:(id) kCFStreamPropertyFTPUserName];
        assert(success);
        
        success = [_ftpReadStream setProperty:self.ftpPass forKey:(id) kCFStreamPropertyFTPPassword];
        assert(success);
        
        [_ftpReadStream setDelegate:self];
        [_ftpReadStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_ftpReadStream open];
        CFRelease(readStream);
        //NSLog(@"Download Waits For CallBack");
        
    }

    
}

-(void) sendFile
{
    if (self.uploadURLWithFolder && self.uploadingFileName) {
        BOOL success = (_uploadURLWithFolder != nil);
        
        if (success) {
            _uploadURLWithFolder = (__bridge_transfer NSURL*) CFURLCreateCopyAppendingPathComponent(NULL, (__bridge_retained CFURLRef) self.uploadURLWithFolder, (__bridge_retained CFStringRef) [self.uploadingFileName lastPathComponent], NO);
            success = (_uploadURLWithFolder != nil);
            NSLog(@"Sending File Url: %@",[_uploadURLWithFolder description]);
        }
        
        if (success) {
            
            NSLog(@"FileName: %@",_uploadingFileName);
            _ftpWriteFileStream = [NSInputStream inputStreamWithFileAtPath:_uploadingFileName];
            assert(_ftpWriteFileStream != nil);
            
            [_ftpWriteFileStream open];
            
            CFWriteStreamRef writeStream = CFWriteStreamCreateWithFTPURL(NULL, (__bridge_retained CFURLRef) self.uploadURLWithFolder);
            assert(writeStream != NULL);
            _ftpWriteStream = objc_unretainedObject(writeStream);
            
            
            success = [_ftpWriteStream setProperty:self.ftpUsername forKey:(id) kCFStreamPropertyFTPUserName];
            assert(success);
            success = [_ftpWriteStream setProperty:self.ftpPass forKey:(id) kCFStreamPropertyFTPPassword];
            assert(success);
            
            [_ftpWriteStream setDelegate:self];
            [_ftpWriteStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_ftpWriteStream open];
            CFRelease(writeStream);
        }
    }
}


-(void) uploadFile:(NSString*)fileName withFolder:(NSString *)folder withType:(NSString *)type toUser:(NSString*)userId
{
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:fileName,@"fileName",folder,@"folderName",type,@"type",userId,@"userName", nil];
    [_mediaUploadQueue addObject:dictionary];
    
    //Dictionary queue nin icindeki ilk objeyi upload etmek icin
    NSDictionary *checkDict;
    if ([_mediaUploadQueue count] > 0) {
        checkDict = [_mediaUploadQueue objectAtIndex:0];
    }
    
    
    
    if ([[checkDict objectForKey:@"fileName"] isEqualToString:fileName]) {
        _uploadingFileName = fileName;
        
        NSURL *fullFtpURL = [NSURL URLWithString:self.ftpUploadHost];
        BOOL success = (fullFtpURL != nil);
        
        if (success) {
            // Add the directory name to the end of the URL to form the final URL 
            // that we're going to create.  CFURLCreateCopyAppendingPathComponent will 
            // percent encode (as UTF-8) any wacking characters, which is the right thing 
            // to do in the absence of application-specific knowledge about the encoding 
            // expected by the server.
            
            fullFtpURL = (__bridge_transfer NSURL*) CFURLCreateCopyAppendingPathComponent(NULL,(__bridge_retained CFURLRef)fullFtpURL,(__bridge_retained CFStringRef) folder,true);
            success = (fullFtpURL != nil);
            _uploadURLWithFolder = fullFtpURL;
            NSLog(@"URL for createdir: %@",[fullFtpURL description]);
        }
        
        
        if (success) {
            CFWriteStreamRef writeDirStream = CFWriteStreamCreateWithFTPURL(NULL, (__bridge_retained CFURLRef) fullFtpURL);
            assert(writeDirStream != NULL);
            _ftpCreateDirStream = objc_unretainedObject(writeDirStream);
            
            success = [_ftpCreateDirStream setProperty:self.ftpUsername forKey:(id) kCFStreamPropertyFTPUserName];
            assert(success);
            success = [_ftpCreateDirStream setProperty:self.ftpPass forKey:(id) kCFStreamPropertyFTPPassword];
            assert(success);
            
            [_ftpCreateDirStream setDelegate:self];
            [_ftpCreateDirStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_ftpCreateDirStream open];
            CFRelease(writeDirStream);
        }
        
        NSLog(@"Creating Directory On FtpServer");
        
    }

}

//EVENT HANDLING
/////////////////////////////////////////////////////
- (void)_stopCreateDirStream
{
    if (_ftpCreateDirStream != nil) {
        [_ftpCreateDirStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_ftpCreateDirStream setDelegate:nil];
        [_ftpCreateDirStream close];
        _ftpCreateDirStream = nil;
    }
}

- (void)_stopReadStream
{
    if (_ftpReadStream != nil) {
        [_ftpReadStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_ftpReadStream setDelegate:nil];
        [_ftpReadStream close];
        _ftpReadStream = nil;
    }
    
    if (_fileStream != nil) {
        [_fileStream close];
    }
}

- (void) stopWriteStream
{
    if (_ftpWriteFileStream != nil) {
        [_ftpWriteFileStream close];
        _ftpWriteFileStream = nil;
    }
    
    if (_ftpWriteStream != nil) {
        [_ftpWriteStream setDelegate:nil];
        [_ftpWriteStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_ftpWriteStream close];
        _ftpWriteStream = nil;
    }
}


-(void) informDownloadingFileStatus:(BOOL) status
{
    if (_delegate) {
        NSString *type;
        NSString *username;
        if ([_mediaDownloadQueue objectAtIndex:0]) {
            type = [[_mediaDownloadQueue objectAtIndex:0] objectForKey:@"type"];
            username = [[_mediaDownloadQueue objectAtIndex:0] objectForKey:@"userName"];
        }
        
        
        [_delegate ftpDownloadStatusChanged:status withFileName:self.downloadingFileName withType:type fromUser:username];
    } 
}

-(void) informUploadingFileStatus:(BOOL) status
{
    if (_delegate) {
        NSString *type;
        NSString *username;
        if ([_mediaUploadQueue objectAtIndex:0]) {
            type = [[_mediaUploadQueue objectAtIndex:0] objectForKey:@"type"];
            username = [[_mediaUploadQueue objectAtIndex:0] objectForKey:@"userName"];
        }
        [_delegate ftpUploadStatusChanged:status withLocalFileName:self.uploadingFileName andRemoteFileName:[self.uploadURLWithFolder description] andType:type toUser:username];
    }
}

-(void) removeDownloadedObjectFromQueue
{
    if ([_mediaDownloadQueue count] > 0) {
        NSDictionary *dictionary = [_mediaDownloadQueue objectAtIndex:0];
        if ([[dictionary objectForKey:@"fileName"] isEqualToString:self.downloadingRemoteFileName]) {
            NSLog(@"Removing Downloaded Object From Queue");
            [_mediaDownloadQueue removeObjectAtIndex:0];
        }
    }
    
    //Bir onceki dosyanin transferi bittikten sonra diger dosyanin transferine baslanir
    if ([_mediaDownloadQueue count] > 0) {
        NSDictionary *dictionary = [_mediaDownloadQueue objectAtIndex:0];
        if (dictionary) {
            NSString *fileName = [dictionary objectForKey:@"fileName"];
            NSString *folderName = [dictionary objectForKey:@"folderName"];
            NSString *type = [dictionary objectForKey:@"type"];
            NSString *fromUsername = [dictionary objectForKey:@"userName"];
            [_mediaDownloadQueue removeObjectAtIndex:0];
            [self downloadFile:fileName inFolder:folderName withType:type fromUser:fromUsername];
        }
    }
}

-(void) removeUploadedObjectFromQueue
{
    if ([_mediaUploadQueue count] > 0) {
        NSDictionary *dictionary = [_mediaUploadQueue objectAtIndex:0];
        if ([[dictionary objectForKey:@"fileName"] isEqualToString:self.uploadingFileName]) {
            NSLog(@"Removing Uploaded Object From Queue");
            [_mediaUploadQueue removeObjectAtIndex:0];
        }
    }
    
    //Bir onceki dosyanin transferi bittikten sonra diger dosyanin transferine baslanir
    if ([_mediaUploadQueue count] > 0) {
        NSLog(@"Transfering New File");
        NSDictionary *dictionary = [_mediaUploadQueue objectAtIndex:0];        
        if (dictionary) {
            
            NSString *fileName = [dictionary objectForKey:@"fileName"];
            NSString *folderName = [dictionary objectForKey:@"folderName"];
            NSString *type = [dictionary objectForKey:@"type"];
            NSString *username = [dictionary objectForKey:@"userName"];
            [_mediaUploadQueue removeObjectAtIndex:0];
            [self uploadFile:fileName withFolder:folderName withType:type toUser:username];
            NSLog(@"Transfering New File withFileName: %@ inFolder: %@",fileName,folderName);
        }
        
    }
}


-(void) handleReadStreamEvents:(NSStreamEvent) eventCode
{
    NSLog(@"Handling ReadStream Events");
    
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
                [self _stopReadStream];
                [self informDownloadingFileStatus:NO];
                [self removeDownloadedObjectFromQueue];
            } else if (bytesRead == 0) {
                NSLog(@"Receiving Part Done");
                [self _stopReadStream];
                [self informDownloadingFileStatus:YES];
                [self removeDownloadedObjectFromQueue];
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
                        [self informDownloadingFileStatus:NO];
                        [self removeDownloadedObjectFromQueue];
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
            [self _stopReadStream];
            [self informDownloadingFileStatus:NO];
            [self removeDownloadedObjectFromQueue];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

-(void) handleCreateDirStreamEvents:(NSStreamEvent)eventCode
{
    NSLog(@"Handling CreateDir Stream Events");
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Connection Opened");
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);
        } break;
        case NSStreamEventErrorOccurred: {
            CFStreamError   err;
            
            // -streamError does not return a useful error domain value, so we 
            // get the old school CFStreamError and check it.
            
            
            err = CFWriteStreamGetError( (__bridge_retained CFWriteStreamRef) self.ftpCreateDirStream );
            if (err.domain == kCFStreamErrorDomainFTP) {
                NSLog(@"CreateDir FTP Domain Error");
                [self _stopCreateDirStream];
                [self sendFile];
            } else {
                NSLog(@"CreateDir Stream Open Error");
                [self _stopCreateDirStream];
            }
        } break;
        case NSStreamEventEndEncountered: {
            NSLog(@"Creating Directory On Ftp Server Suceed");
            [self _stopCreateDirStream];
            [self sendFile];
        } break;
        default: {
            assert(NO);
        } break;
    }
}

-(void) handleWriteStreamEvents:(NSStreamEvent) eventCode
{
    NSLog(@"Handling Write Stream");
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Connection is Opened");
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"Sending File");
            
            // If we don't have any data buffered, go read the next chunk of data.
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [_ftpWriteFileStream read:self.buffer maxLength:kSendBufferSize];
                
                
                if (bytesRead == -1) {
                    NSLog(@"File Read Error");
                    [self stopWriteStream];
                } else if (bytesRead == 0) {
                    NSLog(@"Dosya Gonderme Islemi Tamamlandi");
                    [self stopWriteStream];
                    [self informUploadingFileStatus:YES];
                    [self removeUploadedObjectFromQueue];

                } else {
                    NSLog(@"Buffer OLaniyor");
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [self.ftpWriteStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    NSLog(@"Network Write Error");
                    [self stopWriteStream];
                    [self informUploadingFileStatus:NO];
                    [self removeUploadedObjectFromQueue];
                } else {
                    self.bufferOffset += bytesWritten;
                }
                NSLog(@"Bytes Written To Ftp : %d",bytesWritten);
            }
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"Stream Open Error");
            [self stopWriteStream];
            [self informUploadingFileStatus:NO];
            [self removeUploadedObjectFromQueue];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
            NSLog(@"Ftpye Yazma Islemi Tamamlandi");
            [self stopWriteStream];
            [self informUploadingFileStatus:YES];
            [self removeUploadedObjectFromQueue];
        } break;
        default: {
            assert(NO);
        } break;
    }
    
}


-(void) stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"Stream Delegate Activated");
    //assert(aStream == self.ftpReadStream);
    
    if (aStream == _ftpReadStream) {
        [self handleReadStreamEvents:eventCode];
    }
    else if (aStream == _ftpCreateDirStream) {
        [self handleCreateDirStreamEvents:eventCode];
    }
    else if (aStream == _ftpWriteStream) {
        [self handleWriteStreamEvents:eventCode];
    }

}

@end
