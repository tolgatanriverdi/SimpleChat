//
//  ChatThreadController.m
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatThreadController.h"
#import "XMPPMessageUserCoreDataObject.h"


@interface ChatThreadController()<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSArray *messages;
@end

@implementation ChatThreadController
@synthesize chatTable;
@synthesize keyboardToolbar;
@synthesize chatTextField;
@synthesize chatWith = _chatWith;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize context = _context;
@synthesize messages = _messages;


-(void) configure
{
    if (!self.fetchedResultsController) {
        if (self.context) {
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageCoreDataObject" inManagedObjectContext:self.context];

            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whoOwns = %@",[self.chatWith description]];
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:descriptor];
            [request setEntity:entity];
            [request setPredicate:predicate];
            [request setSortDescriptors:sortDescriptors];
            
            self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.context sectionNameKeyPath:@"type" cacheName:nil];
            
            [self.fetchedResultsController setDelegate:self];
         
            NSError *fetchError;
            NSArray *matches = [self.context executeFetchRequest:request error:&fetchError];
            
            
            if ([matches count] > 0) {
                self.messages = matches;
            }
            
        }
    }
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


-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSError *fetchError;
    NSArray *matches = [self.context executeFetchRequest:controller.fetchRequest error:&fetchError];
    
    
    if ([matches count] > 0) {
        self.messages = matches;
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
    [self.chatTable setDelegate:self];
    [self.chatTable setDataSource:self];
    
    [self configure];
}


- (void)viewDidUnload
{
    [self setChatTable:nil];
    [self setKeyboardToolbar:nil];
    [self setChatTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CGRect frame = self.keyboardToolbar.frame;
	frame.origin.y = self.view.frame.size.height - 260.0;
	self.keyboardToolbar.frame = frame;
	
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CGRect frame = self.keyboardToolbar.frame;
	frame.origin.y = self.view.frame.size.height;
	self.keyboardToolbar.frame = frame;
	
	[UIView commitAnimations];
}

- (IBAction)messageDone:(id)sender 
{
    NSString *textMessage = [self.chatTextField text];
    
    
    //NSString *person = [self.chatWith description];
    //NSLog(@"Chat Message: TO: %@ BODY: %@",person,textMessage);
    
    NSArray *values = [NSArray arrayWithObjects:textMessage,self.chatWith,@"chat", nil];
    NSArray *keys  = [NSArray arrayWithObjects:@"body",@"to",@"type", nil];
    NSDictionary *messageContent = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"messageSent" object:nil userInfo:messageContent];
    
    [self.chatTextField setText:@""];
}


#pragma mark - Table View Delegate

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.messages) {
        return [self.messages count];
    }
    
    return 0;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"messageCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
    
    if ([self.messages count] > 0) {
        XMPPMessageCoreDataObject *messageObj = [self.messages objectAtIndex:indexPath.row];
        cell.textLabel.text = messageObj.body;
    }
    
    return cell;
}


@end