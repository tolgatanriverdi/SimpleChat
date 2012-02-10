//
//  MediaViewController.m
//  SimpleChat
//
//  Created by ARGELA on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MediaViewController.h"
#import <CoreData/CoreData.h>
#import "XMPPFramework.h"
#import <AVFoundation/AVAudioPlayer.h>

@interface MediaViewController()<AVAudioPlayerDelegate>
@property (nonatomic,strong) NSArray *messages;
@property (nonatomic,strong) NSMutableDictionary *images;
@property (nonatomic) int selectedIndex;
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@end

@implementation MediaViewController

@synthesize fromUsername = _fromUsername;
@synthesize context = _context;
@synthesize scrollView = _scrollView;
@synthesize messages = _messages;
@synthesize selectedIndex = _selectedIndex;
@synthesize images = _images;
@synthesize audioPlayer = _audioPlayer;

-(int) getCurrentPage
{
    return floor(_scrollView.contentOffset.x/self.view.frame.size.width);
}


-(void)loadPage:(int)page
{
	// Sanity checks
    if (page < 0) return;
    if (page >= [_messages count]) return;
	
    
    NSNumber *pageIndex = [NSNumber numberWithInt:page];
    int imageOffset=0;
    /*
    if (page > 0) {
        imageOffset = 20;
    }
     */
    
    if (!_images) {
            _images = [[NSMutableDictionary alloc] init];
    }
    

    if (![_images objectForKey:pageIndex])
    {
        if ([_messages count] >= page+1) 
        {
            XMPPMessageCoreDataObject *mediaMessage = [_messages objectAtIndex:page];
            if (mediaMessage.type == @"image") {
                UIImage *mediaImage = [UIImage imageWithData:mediaMessage.actualData];
                UIImageView *mediaImageView = [[UIImageView alloc] initWithImage:mediaImage];
                CGRect mediaImageFrame = self.view.frame;
                mediaImageFrame.origin.x = (self.view.frame.size.width+imageOffset)*page;
                mediaImageView.frame = mediaImageFrame;
                [_scrollView addSubview:mediaImageView];
                [_images setObject:mediaImageView forKey:pageIndex];
            } 
            else if (mediaMessage.type == @"audio") {
                NSString *quickTimeIcon = [[NSBundle mainBundle] pathForResource:@"quicktime" ofType:@"png"];
                NSData *mediaData = [NSData dataWithContentsOfFile:quickTimeIcon];
                UIImage *mediaImage = [UIImage imageWithData:mediaData];
                UIImageView *mediaImageView = [[UIImageView alloc] initWithImage:mediaImage];
                CGRect mediaImageViewFrame = CGRectMake(20, 50, mediaImage.size.width,mediaImage.size.height);
                mediaImageView.frame = mediaImageViewFrame;
                
                CGRect soundViewFrame = self.view.frame;
                soundViewFrame.origin.x = (self.view.frame.size.width+imageOffset)*page;
                CGRect buttonFrame = CGRectMake(120, 120, 80, 60);
                UIButton *soundPlayButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
                [soundPlayButton setTitle:@"PLAY" forState:UIControlStateNormal];
                [soundPlayButton setFrame:buttonFrame];
                [soundPlayButton addTarget:self action:@selector(playSound) forControlEvents:UIControlEventTouchUpInside];
                UIView *soundView = [[UIView alloc] initWithFrame:soundViewFrame];
                [soundView addSubview:mediaImageView];
                [soundView addSubview:soundPlayButton];
                [_scrollView addSubview:soundView];
                [_images setObject:soundView forKey:pageIndex];
                

                NSError *audioError;
                _audioPlayer = [[AVAudioPlayer alloc] initWithData:mediaMessage.actualData error:&audioError];
                _audioPlayer.delegate = self;
                    
            }
        }
       
    }
    
	
}


-(void) setFromUsername:(NSString *)fromUsername
{
    int pageOffset = 0;  //20 Olacak
    _fromUsername = fromUsername;
    //XMPPJID *fromJid = [XMPPJID jidWithString:userId];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageCoreDataObject"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:descriptor];
    
    request.predicate = [NSPredicate predicateWithFormat:@"whoOwns.jidStr = %@ AND type != %@",_fromUsername,@"chat"];
    request.sortDescriptors = sortDescriptors;
    
    NSError *error;
    _messages = [self.context executeFetchRequest:request error:&error];
    
    NSLog(@"MediaView Message Count: %d FromUsername: %@",[_messages count],fromUsername);
    
    if (_scrollView) {
        [_scrollView removeFromSuperview];
        _scrollView.delegate = nil;
        _scrollView = nil;
    }
    
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _scrollView.contentSize = CGSizeMake((self.view.frame.size.width+pageOffset)*[_messages count], self.view.frame.size.height);
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.clipsToBounds = NO;
        _scrollView.delegate = self;
        [self.view addSubview:_scrollView];
    }

    
    
    [self loadPage:0];
    [self loadPage:1];
    
    //NSLog(@"ScrollView Content Width: %f Height: %f",_scrollView.contentSize.width,_scrollView.contentSize.height);
    //NSLog(@"ScrollView Width: %f Height: %f",_scrollView.frame.size.width,_scrollView.frame.size.height);
    //NSLog(@"Self View Width: %f Height: %f Message Count: %d",self.view.frame.size.width,self.view.frame.size.height,[_messages count]);
    
}

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


///////////////////////////////////////////////////////

-(void) playSound
{
    int pageIndex = [self getCurrentPage];
    UIView *soundView = [_images objectForKey:[NSNumber numberWithInt:pageIndex]];
    UIButton *playStopButton;
    if (soundView) {
        for (UIButton *button in [soundView subviews]) {
            playStopButton = button;
        }
    }
    
    if (!_audioPlayer.isPlaying) {
        NSLog(@"Audio Player Starts To Play");
        [_audioPlayer play];
        
        if (playStopButton) {
            [playStopButton setTitle:@"STOP" forState:UIControlStateNormal];
        }
    } else {
        NSLog(@"Audio Player Trying To Stop");
        [_audioPlayer stop];
        
        if (playStopButton) {
            [playStopButton setTitle:@"PLAY" forState:UIControlStateNormal];
        }
    }
}

-(void) setMessage:(XMPPMessageCoreDataObject*)message
{
    for (int i=0;i<[_messages count];i++) 
    {
        XMPPMessageCoreDataObject *mediaMessage = [_messages objectAtIndex:i];
        if ([mediaMessage isEqual:message]) 
        {
            NSLog(@"Mesaj Bulundu");
            CGFloat scrollXOffset = self.view.frame.size.width*i;
            if (i >0) { scrollXOffset += 20;}
            CGRect scrollingTo = CGRectMake(scrollXOffset, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
            [_scrollView scrollRectToVisible:scrollingTo animated:YES];
            break;
        }
    }
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [self setScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


///DELEGATES
-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    int currentPage = [self getCurrentPage];
    //NSLog(@"Scrolll Did Scroll CurrentPage: %d",currentPage);
    
    [self loadPage:currentPage-1];
    [self loadPage:currentPage];
    [self loadPage:currentPage+1];
}

-(void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    int pageIndex = [self getCurrentPage];
    UIView *soundView = [_images objectForKey:[NSNumber numberWithInt:pageIndex]];
    UIButton *playStopButton;
    if (soundView) {
        for (UIButton *button in [soundView subviews]) {
            playStopButton = button;
        }
    }
    
    if (playStopButton)
    {
        [playStopButton setTitle:@"PLAY" forState:UIControlStateNormal];
    }
}

@end
