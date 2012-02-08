//
//  AudioRecordController.m
//  SimpleChat
//
//  Created by ARGELA on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AudioRecordController.h"
#import <AvFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/CAFFile.h>

#define MAX_RECORD_SECONDS 30

@interface AudioRecordController()<AVAudioRecorderDelegate,AVAudioPlayerDelegate>
@property (nonatomic,strong) NSTimer *recordTimer;
@property (nonatomic,strong) NSTimer *playTimer;
@property (nonatomic) int recordCount;
@property (nonatomic) int playCount;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isRecordingFinished;
@end

@implementation AudioRecordController
@synthesize recordTimeLine = _recordTimeLine;
@synthesize recordButton = _recordButton;
@synthesize cancelButton = _cancelButton;
@synthesize sendButton = _sendButton;
@synthesize recordTimer = _recordTimer;
@synthesize recordCount = _recordCount;
@synthesize audioRecorder = _audioRecorder;
@synthesize audioPlayer = _audioPlayer;
@synthesize recordFilePath = _recordFilePath;
@synthesize isRecordingFinished = _isRecordingFinished;
@synthesize playTimer = _playTimer;
@synthesize playCount = _playCount;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

-(void) viewWillAppear:(BOOL)animated
{
    [_sendButton setHidden:YES];
    [_recordButton setTitle:@"RECORD" forState:UIControlStateNormal];
    [_cancelButton setTitle:@"CANCEL" forState:UIControlStateNormal];
    _isRecordingFinished = NO;
    [_recordTimeLine setProgress:0 animated:YES];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [self setRecordTimer:nil];
    [self setPlayTimer:nil];
    [self setAudioPlayer:nil];
    [self setAudioRecorder:nil];
}

- (void)viewDidUnload
{
    [self setRecordTimeLine:nil];
    [self setRecordButton:nil];
    [self setCancelButton:nil];
    [self setSendButton:nil];
    [self setRecordTimer:nil];
    [self setPlayTimer:nil];
    [self setAudioPlayer:nil];
    [self setAudioRecorder:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) initializeRecorder
{
    
    NSURL *recordingFileUrl = [[NSURL alloc] initFileURLWithPath:_recordFilePath];
    //NSLog(@"Recording File Url: %@",[recordingFileUrl description]);

    
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: 16000], AVSampleRateKey,
                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                    
                                    nil];
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:recordingFileUrl settings:recordSettings error:nil];
    _audioRecorder.delegate = self;
}

-(void) initializePlayer
{
     NSURL *recordingFileUrl = [[NSURL alloc] initFileURLWithPath:_recordFilePath];
     NSError *playerError;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordingFileUrl error:&playerError];
    _audioPlayer.delegate = self;
    
    if (playerError) {
        NSLog(@"Player Initialize Error: %@",[playerError description]);
        return;
    }
}

-(void) startRecording
{
    if (!_recordTimer) {
        _recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(recordTimerTimeOut) userInfo:nil repeats:YES];
        _recordCount = 0;
    }
    
    [_audioRecorder record];
    [_recordButton setTitle:@"STOP" forState:UIControlStateNormal];
    [_sendButton setHidden:YES];
    _isRecordingFinished = NO;
}

-(void) stopRecording
{
    if (_audioRecorder.isRecording) {
        [_audioRecorder stop];
    }
    [_recordTimer invalidate];
    [_recordButton setTitle:@"PLAY" forState:UIControlStateNormal];
    [_sendButton setHidden:NO];
    _isRecordingFinished = YES;
}

-(void) playRecordedSound
{
    if (!_playTimer) {
        _playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(playTimeOut) userInfo:nil repeats:YES];
        _playCount = 0;
    }
    else if (!_playTimer.isValid) {  //Pauseden sonra baslatilirsa timeri tekrar baslatir
        //NSLog(@"PlayTimer Durdurulduktan Sonra Basliyor");
        _playTimer = nil;
        _playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(playTimeOut) userInfo:nil repeats:YES];
    }
    
    [_audioPlayer play];
    [_recordButton setTitle:@"PAUSE" forState:UIControlStateNormal];
}

-(void) pauseRecordedSound
{
    if (_audioPlayer.isPlaying) {
        [_audioPlayer pause];
        [_playTimer invalidate];
    }

    [_recordButton setTitle:@"PLAY" forState:UIControlStateNormal];
}

-(void) stopPlayingRecordedSound
{
    [_audioPlayer stop];
    [_playTimer invalidate];
    [_recordButton setTitle:@"PLAY" forState:UIControlStateNormal];
    _playCount=0;
    [_recordTimeLine setProgress:0 animated:YES];
}


-(void) recordTimerTimeOut
{
    //NSLog(@"RecordCount: %d",_recordCount);
    if (_recordCount >= MAX_RECORD_SECONDS) {
        [self stopRecording];
    }

    _recordCount++;
    float percentComplete = (_recordCount*100)/MAX_RECORD_SECONDS;
    float completedPart = percentComplete/100;
    [_recordTimeLine setProgress:completedPart animated:YES];
}

-(void) playTimeOut
{
    //Zaman dolunca calmayi durdurma burada yapilmayacak cunku onu audioplayer kendisi durduracak
    
    //NSLog(@"Play Time Out : %d",_playCount);
    _playCount++;
    float percentComplete = (_playCount*100)/MAX_RECORD_SECONDS;
    float completedPart = percentComplete/100;
    [_recordTimeLine setProgress:completedPart animated:YES];
}

- (IBAction)recordPressed:(id)sender 
{
    
    if (!_audioRecorder) {  //Kaydetmeye baslamadiysa kayit islemi baslatilir
        [self initializeRecorder];
        [self startRecording];
    }
    else {
        if (!_isRecordingFinished) {  //Kayit sirasinda stopa basilirsa kayit islemini bitirir play tusunu getirir
            [self stopRecording];
        } else {
            if (!_audioPlayer) {    //Ilk defa play tusuna basildiginda calisir
                [self initializePlayer];
                [self playRecordedSound];
            }
            else {
                if(_audioPlayer.isPlaying) {  //Kayit calinirken pause a basilirse calan kaydi durdurur
                    [self pauseRecordedSound];
                }
                else {                      //Kayit calinip durdurulduktan sonra tekrar baslatmak icindir
                    [self playRecordedSound];
                }
            }
        }
    }

}


- (IBAction)cancelPressed:(id)sender 
{
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)sendPressed:(id)sender 
{
    [_delegate audioRecordControllerSendPressed:_recordFilePath];
    [self dismissModalViewControllerAnimated:YES];
}



/////DELEGATES


-(void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopPlayingRecordedSound];
}

-(void) audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    
}



@end
