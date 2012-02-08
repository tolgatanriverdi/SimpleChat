//
//  AudioRecordController.h
//  SimpleChat
//
//  Created by ARGELA on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AudioRecordControllerDelegate <NSObject>

-(void) audioRecordControllerSendPressed:(NSString*)fileName;
@end

@interface AudioRecordController : UIViewController
@property (weak, nonatomic) IBOutlet UIProgressView *recordTimeLine;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (strong, nonatomic) NSString *recordFilePath;
@property (strong, nonatomic) id<AudioRecordControllerDelegate> delegate;

@end
