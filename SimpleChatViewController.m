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

@implementation SimpleChatViewController
@synthesize username = _username;
@synthesize password = _password;
@synthesize isInitializingFirstTime = _isInitializingFirstTime;
@synthesize xmppHandler = _xmppHandler;



@synthesize uName = _uName;
@synthesize pass = _pass;
@synthesize friendListTable = _friendListTable;


-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"TextFieldBitti");
    [self.xmppHandler setUsername:self.username.text];
    [self.xmppHandler setPassword:self.password.text];
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)connect:(id)sender 
{
    [self.xmppHandler connect];    
}

- (IBAction)disconnect:(id)sender 
{
    [self.xmppHandler disconnect];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
        
    NSLog(@"Buraya Geldii");
        
    [self.password setDelegate:self];
    NSLog(@"Delegate Eklendi");
        // Configure logging framework
        
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        
        // Setup the XMPP stream
    NSString *hostName = @"192.168.12.30";
    NSString *latestPath = [@"@" stringByAppendingString:hostName];
    NSString *fullUName = [self.username.text stringByAppendingString:latestPath];
    [self.username setText:fullUName];
        
    self.xmppHandler = [[XMPPHandler alloc] init];
    [self.xmppHandler setHostname:hostName];
    [self.xmppHandler setUsername:self.username.text];
    [self.xmppHandler setPassword:self.password.text];
    [self.xmppHandler setDelegate:self];
    [self.xmppHandler configure];


}

- (void)viewDidUnload
{
    [self setUsername:nil];
    [self setPassword:nil];
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




//////XMPP HANDLER DELEGATE METHODS////////

-(void) setXMPPHandlerConnectionStatus:(BOOL)status
{
    if (status) {
        [self performSegueWithIdentifier:@"friendsSegue" sender:self];
    }
    else
    {
        NSLog(@"Baglanti Hatasi");
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting" 
		                                                    message:@"See console for error details." 
		                                                   delegate:nil 
		                                          cancelButtonTitle:@"Ok" 
		                                          otherButtonTitles:nil];
		[alertView show];
    }
}

-(void) presenceStatusChanged:(XMPPJID*)jid withStatus:(NSString *)status
{
    [self.friendListTable presenceStatusChanged:jid withStatus:status];
}

////////////////////////////////////

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController respondsToSelector:@selector(setContext:)]) {
        if (!self.friendListTable) {
            self.friendListTable = segue.destinationViewController;
        }
        [segue.destinationViewController setContext:[self.xmppHandler getManagedObjectRoster]];
    }
}

@end
