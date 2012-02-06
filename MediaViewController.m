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

@interface MediaViewController()
@property (nonatomic,strong) NSArray *messages;
@property (nonatomic,strong) NSMutableDictionary *images;
@property (nonatomic) int selectedIndex;
@end

@implementation MediaViewController

@synthesize fromUsername = _fromUsername;
@synthesize context = _context;
@synthesize scrollView = _scrollView;
@synthesize messages = _messages;
@synthesize selectedIndex = _selectedIndex;
@synthesize images = _images;


-(void)loadPage:(int)page
{
	// Sanity checks
    if (page < 0) return;
    if (page >= [_messages count]) return;
	
    
    NSNumber *pageIndex = [NSNumber numberWithInt:page];
    int imageOffset=0;
    if (page > 0) {
        imageOffset = 20;
    }
    
    if (!_images) {
            _images = [[NSMutableDictionary alloc] init];
    }
    
    if (![_images objectForKey:pageIndex])
    {
        XMPPMessageCoreDataObject *mediaMessage = [_messages objectAtIndex:page];
        if (mediaMessage.type == @"image") {
            UIImage *mediaImage = [UIImage imageWithData:mediaMessage.actualData];
            UIImageView *mediaImageView = [[UIImageView alloc] initWithImage:mediaImage];
            CGRect mediaImageFrame = _scrollView.frame;
            mediaImageFrame.origin.x = (self.view.frame.size.width+imageOffset)*page;
            mediaImageView.frame = mediaImageFrame;
            [_scrollView addSubview:mediaImageView];
            [_images setObject:mediaImageView forKey:pageIndex];
        }        
    }
    
	
}


-(void) setFromUsername:(NSString *)fromUsername
{
    _fromUsername = fromUsername;
    //XMPPJID *fromJid = [XMPPJID jidWithString:userId];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageCoreDataObject"];
    request.predicate = [NSPredicate predicateWithFormat:@"whoOwns.jidStr = %@ AND type != %@",_fromUsername,@"chat"];
    
    NSError *error;
    _messages = [self.context executeFetchRequest:request error:&error];
    
    NSLog(@"MediaView Message Count: %d FromUsername: %@",[_messages count],fromUsername);
    
    if (_scrollView) {
        NSLog(@"Scroll View Siliniyor");
        [_scrollView removeFromSuperview];
        _scrollView.delegate = nil;
        _scrollView = nil;
    }
    
    if (!_scrollView) {
        NSLog(@"Scroll View Yaratiliyor");
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _scrollView.contentSize = CGSizeMake((self.view.frame.size.width+20)*[_messages count], self.view.frame.size.height);
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

-(void) setMessage:(XMPPMessageCoreDataObject*)message
{
    for (int i=0;i<[_messages count];i++) 
    {
        XMPPMessageCoreDataObject *mediaMessage = [_messages objectAtIndex:i];
        if ([mediaMessage isEqual:message]) 
        {
            NSLog(@"Mesaj Bulundu");
            //[_scrollView setContentOffset:CGPointMake(_scrollView.frame.origin.x*i,_scrollView.frame.origin.y) animated:YES];
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
    int currentPage = floor(_scrollView.contentOffset.x/self.view.frame.size.width);
    NSLog(@"Scrolll Did Scroll CurrentPage: %d",currentPage);
    
    [self loadPage:currentPage-1];
    [self loadPage:currentPage];
    [self loadPage:currentPage+1];
}

@end
