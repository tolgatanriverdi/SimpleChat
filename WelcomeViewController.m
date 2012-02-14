//
//  WelcomeViewController.m
//  SimpleChat
//
//  Created by ARGELA on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WelcomeViewController.h"
#import "avClient.h"

@interface WelcomeViewController()<avClientTaskDelegate>
@property (nonatomic,strong) avRegisterTask *registerTask;
@property (nonatomic,strong) avActivateTask *activationTask;
@end

@implementation WelcomeViewController
@synthesize countryMobileCode = _countryMobileCode;
@synthesize phoneNumber = _phoneNumber;
@synthesize activationCodeText = _activationCodeText;
@synthesize registerView = _registerView;
@synthesize activationView = _activationView;
@synthesize registerTask = _registerTask;
@synthesize activationTask = _activationTask;

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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    /*
    NSString *splashLogoPath = [[NSBundle mainBundle] pathForResource:@"Splash" ofType:@"jpg"];
    UIImage *splashImage = [UIImage imageWithContentsOfFile:splashLogoPath];
    UIImageView *splashView = [[UIImageView alloc] initWithImage:splashImage];
    splashView.frame = self.view.frame;
    NSLog(@"Resim Yuklendi");
     */
}


-(void) accountFlow
{
    NSNumber *accountState = [[NSUserDefaults standardUserDefaults] objectForKey:@"twinChatAccountState"];
    if (!accountState || accountState == [NSNumber numberWithInt:0]) {
        [self.registerView setHidden:NO];
        [self.activationView setHidden:YES];
    } else if (accountState == [NSNumber numberWithInt:1]) {
        [self.registerView setHidden:YES];
        [self.activationView setHidden:NO];
        self.activationView.frame = self.registerView.frame;
    } else {
        [self.registerView setHidden:YES];
        [self.activationView setHidden:YES];
        [self performSegueWithIdentifier:@"mainSegue" sender:self];
    } 
}

-(void) viewWillAppear:(BOOL)animated
{
    [self accountFlow];
}

- (void)viewDidUnload
{
    [self setCountryMobileCode:nil];
    [self setPhoneNumber:nil];
    [self setActivationCodeText:nil];
    [self setRegisterView:nil];
    [self setActivationView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)registerSelf:(id)sender 
{
    NSString *phoneNo = [NSString stringWithFormat:@"%@%@",self.countryMobileCode.text,self.phoneNumber.text];
    if (self.countryMobileCode.text.length < 3 && [phoneNo characterAtIndex:0] != '+') {
        NSString *alertBody = @"Phone Number Should Start With International Format \n(Such As +90)";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ERROR"
                                                            message:alertBody 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
        [alertView show];       
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:phoneNo forKey:@"twinChatUsername"];
    
    if (!_registerTask) {
        _registerTask = [[avRegisterTask alloc] init];
    }
    [[_registerTask payload] setObject:phoneNo forKey:@"username"];
    _registerTask.delegate = self;
    [[avClient shared] runTask:_registerTask];
    
}

- (IBAction)activateSelf:(id)sender 
{
    NSString *activationCode = self.activationCodeText.text;
    if (activationCode.length < 4) {
        NSString *alertBody = @"Please Enter The Activation Code \nThat Sent To You Via SMS";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ERROR"
                                                            message:alertBody 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
        [alertView show]; 
    }
    
    if (!_activationTask) {
        _activationTask = [[avActivateTask alloc] init];
        NSLog(@"Activation Task Olusturuluyor");
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:activationCode forKey:@"twinChatPassword"];
    NSString *twinChatUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"twinChatUsername"];
    NSLog(@"Username: %@ Password: %@",twinChatUser,activationCode);
    [_activationTask.payload setObject:twinChatUser forKey:@"username"];
    [_activationTask.payload setObject:activationCode forKey:@"uuid"];        
    _activationTask.delegate = self;
    [[avClient shared] runTask:_activationTask];
}



//////DELEGATES

-(void) taskDidSucceed:(avClientTask *)task
{
    NSLog(@"TASK DID SUCCEED");
    if ([task isEqual:_registerTask]) {
        NSLog(@"Register Task Did Succeed");
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"twinChatAccountState"]; 
    } else if ([task isEqual:_activationTask]) {
        NSLog(@"Activation Task Did Suceed");
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"twinChatAccountState"];
    }
    
    [self accountFlow];
}

-(void) taskDidFail:(avClientTask *)task
{
    NSLog(@"TASK DID FAIL");   
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}


@end
