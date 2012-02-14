//
//  SimpleChatViewController.m
//  SimpleChat
//
//  Created by ARGELA on 1/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SimpleChatViewController.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import <CommonCrypto/CommonDigest.h>
#import "MBProgressHUD.h"
#import "avClient.h"

#define XMPP_SERVER_HOST @"95.0.221.23"

@interface SimpleChatViewController()<avClientTaskDelegate>
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) NSString *username;
@end

@implementation SimpleChatViewController
@synthesize isInitializingFirstTime = _isInitializingFirstTime;
@synthesize xmppHandler = _xmppHandler;
@synthesize friendListTable = _friendListTable;
@synthesize hud = _hud;
@synthesize username = _username;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


-(void) showMBHUD
{
    if (!_hud) {
        _hud = [[MBProgressHUD alloc] initWithView:self.view];
    }
    
    [self.view addSubview:_hud];
    _hud.dimBackground = YES;
    [_hud show:YES];
}

-(void) hideMBHUD
{
    [_hud show:NO];
    [_hud removeFromSuperview];
}

-(void) configureXMPP
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    NSString *domainPath = [@"@" stringByAppendingString:XMPP_SERVER_HOST];
    NSString *animoUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"twinChatUsername"];
    NSString *animoPass = [[NSUserDefaults standardUserDefaults] objectForKey:@"twinChatPassword"];
    NSString *fullUsername = [animoUser stringByAppendingString:domainPath];
    _username = fullUsername;
    
    if (!self.xmppHandler) {
        self.xmppHandler = [[XMPPHandler alloc] init]; 
    }
    
    [self.xmppHandler setHostname:XMPP_SERVER_HOST];
    [self.xmppHandler setUsername:fullUsername];
    [self.xmppHandler setPassword:animoPass];
    [self.xmppHandler setDelegate:self];
    [self.xmppHandler configure];
    [self.xmppHandler connect];
    
    [self showMBHUD];
}

-(void) configureLocalNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContacts:) name:@"UpdateContacts" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setHidesBackButton:YES];
	// Do any additional setup after loading the view, typically from a nib.
    // Configure logging framework
    
    [self configureXMPP];
    [self configureLocalNotifications];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

//////////////////////////////////////////


-(void) updateContacts:(NSNotification*)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSArray *contactList = [userInfo objectForKey:@"processedContacts"];
    [self.xmppHandler syncContacts:contactList];
}


//////XMPP HANDLER DELEGATE METHODS////////

-(void) setXMPPHandlerConnectionStatus:(BOOL)status
{
    NSLog(@"XMPP Connection Status: %@ %d",self.username,status);
    if (status) {
        //[self performSegueWithIdentifier:@"friendsSegue" sender:self];
        NSLog(@"Baglanti Basariyla Gercekelstirildi");
        avSendContacts *contactTask = [[avSendContacts alloc] init];
        contactTask.delegate = self;
        [[avClient shared] runTask:contactTask];
    }
    else
    {
        //NSLog(@"Baglanti Hatasi");
        
        [self hideMBHUD];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Connecting to Server" 
		                                                    message:@"See console for error details." 
		                                                   delegate:nil 
		                                          cancelButtonTitle:@"Ok" 
		                                          otherButtonTitles:nil];
		[alertView show];
        
    }
    

}

-(void) presenceStatusChanged:(XMPPJID*)jid withStatus:(NSString *)status
{
    //[self.friendListTable presenceStatusChanged:jid withStatus:status];
}

-(void) taskDidSucceed:(avClientTask *)task
{
    [self hideMBHUD];  
}

-(void) taskDidFail:(avClientTask *)task
{
    [self hideMBHUD]; 
}

////////////////////////////////////

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController respondsToSelector:@selector(setContext:)]) {
        if (!self.friendListTable) {
            self.friendListTable = segue.destinationViewController;
        }
        [segue.destinationViewController setContext:[self.xmppHandler getManagedObjectRoster]];
        [segue.destinationViewController setChatThreadContext:[self.xmppHandler getmanagedObjectMessage]];
        [segue.destinationViewController setSelfID:self.username];
        [segue.destinationViewController setSelfJID:[self.xmppHandler getMyJid]];
    }
}

@end
