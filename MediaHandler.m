//
//  MediaHandler.m
//  SimpleChat
//
//  Created by ARGELA on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MediaHandler.h"

#define IMAGE_FILE_PREFIX @"avt_image_"

@implementation MediaHandler


@synthesize delegate = _delegate;
@synthesize toJid = _toJid;


-(void) sendFile:(NSString*)fileName
{
    NSLog(@"Sending File: %@",fileName);
    //Burasi denemek icindir silinecek
    
    NSArray *keys = [NSArray arrayWithObjects:@"filePath",@"userJid", nil];
    NSArray *values = [NSArray arrayWithObjects:fileName,_toJid, nil];
    NSDictionary *fileContents = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
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
            [imagePicker setAllowsEditing:YES];
            [_delegate presentImagePickerController:imagePicker];
        }
        
    }
}


-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *folderName = [_toJid bare];
    NSArray *documentsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = [documentsDir objectAtIndex:0];
    NSString *documentsFullPath = [documentsDirPath stringByAppendingPathComponent:folderName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsFullPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsFullPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    int fileCount = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsFullPath error:nil] count];
    NSString *fullFilePath = [documentsFullPath stringByAppendingPathComponent:IMAGE_FILE_PREFIX];
    NSString *fileExactPath = [NSString stringWithFormat:@"%@%d",fullFilePath,fileCount];
    
    
    UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    NSData *imageData = UIImagePNGRepresentation(image);
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileExactPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:fileExactPath error:nil];
    }
    
    if([[NSFileManager defaultManager] createFileAtPath:fileExactPath contents:imageData attributes:nil])
    {
        NSLog(@"Resim Dosyasi Kaydedildi Gonderiliyor");
        [self sendFile:fileExactPath];  
    }

    
    [_delegate dismissImagePicker];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [_delegate dismissImagePicker];
}

@end
