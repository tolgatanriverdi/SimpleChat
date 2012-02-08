//
//  MediaHandler.m
//  SimpleChat
//
//  Created by ARGELA on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MediaHandler.h"
#import "AudioRecordController.h"

#define IMAGE_FILE_PREFIX @"avt_image_"
#define SOUND_FILE_PREFIX @"avt_sound_"

@interface MediaHandler()<AudioRecordControllerDelegate>
@end


@implementation MediaHandler


@synthesize delegate = _delegate;
@synthesize toChatJid = _toChatJid;
@synthesize selfJid = _selfJid;


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
    
    
    UIGraphicsBeginImageContext(CGSizeMake(960.0, 640.0));
    [image drawInRect:CGRectMake(0.0, 0.0, 960.0, 640.0)];
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



-(void) audioRecordControllerSendPressed:(NSString *)fileName
{
    [self sendFile:fileName withType:@"audio"];
}

@end
