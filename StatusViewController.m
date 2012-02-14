//
//  StatusViewController.m
//  SimpleChat
//
//  Created by ARGELA on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StatusViewController.h"

@implementation StatusViewController
@synthesize statusText;

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
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *currentStat = [prefs stringForKey:@"avatarChatStatus"];
    
    if (!currentStat) {
        currentStat = @"Available";
    }
    
    [self.statusText setText:currentStat];
    [self.statusText setDelegate:self];
}


- (void)viewDidUnload
{
    [self setStatusText:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)save:(id)sender 
{
    [self.statusText resignFirstResponder];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:self.statusText.text forKey:@"avatarChatStatus"];
    //NSLog(@"USERDEFAULT: %@",self.statusText.text);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"saveStatus" object:self];
    
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)cancel:(id)sender 
{
    [self.statusText resignFirstResponder];
    [self dismissModalViewControllerAnimated:YES];
}


-(BOOL) textViewShouldEndEditing:(UITextView *)textView
{
    [self.statusText resignFirstResponder];
    return YES;
}

@end
