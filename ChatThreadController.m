//
//  ChatThreadController.m
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatThreadController.h"
#import "XMPPMessageCoreDataObject.h"
#import "chatMessageCell.h"
#import "MediaHandler.h"



@interface ChatThreadController()<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate,UIActionSheetDelegate,MediaHandlerDelegate>
@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) MediaHandler *mediaHandler;
@end

@implementation ChatThreadController
@synthesize chatTable;
@synthesize keyboardToolbar;
@synthesize chatTextField;
@synthesize chatWith = _chatWith;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize context = _context;
@synthesize selfID = _selfID;
@synthesize mediaHandler = _mediaHandler;


-(void) configure
{
    if (!self.fetchedResultsController) {
        if (self.context) {
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageCoreDataObject" inManagedObjectContext:self.context];

            if (entity) {
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"whoOwns.jidStr = %@ AND messageReceipant=%@",self.chatWith,self.selfID];
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObject:descriptor];
                [request setEntity:entity];
                [request setPredicate:predicate];
                [request setSortDescriptors:sortDescriptors];
                
                self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.context sectionNameKeyPath:@"whoOwns.jidStr" cacheName:nil];
                
                [self.fetchedResultsController setDelegate:self];
                
                NSError *fetchError;
                if ([self.fetchedResultsController performFetch:&fetchError])
                {
                    NSLog(@"Sorgu Hatasi: %@",[fetchError description]);
                }
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
    //NSLog(@"Tabloo Degisti");
    [self.chatTable reloadData];
    
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:[self.chatTable numberOfRowsInSection:0]-1 inSection:0];
    [self.chatTable scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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

    //[self.chatTable setDelegate:self];
    //[self.chatTable setDataSource:self];
    _mediaHandler = [[MediaHandler alloc] init];
    [_mediaHandler setDelegate:self];
    
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
	
    /*
	CGRect frame = self.keyboardToolbar.frame;
	frame.origin.y = self.view.frame.size.height - 260.0;
	self.keyboardToolbar.frame = frame;
    
    CGRect chatFrame = self.chatTable.frame;
    chatFrame.size.height = self.chatTable.frame.size.height - 260.0;
    self.chatTable.frame = chatFrame;
     */
    
    self.keyboardToolbar.frame = CGRectMake(0, 156, 320, 44);
	self.chatTable.frame = CGRectMake(0, 0, 320, 156);	
    
    //[self.chatTable setContentSize:CGSizeMake(self.chatTable.contentSize.width, self.chatTable.contentSize.height-260.0)];
    
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
    /*
	CGRect frame = self.keyboardToolbar.frame;
	frame.origin.y = self.view.frame.size.height;
	self.keyboardToolbar.frame = frame;
    
    CGRect chatFrame = self.chatTable.frame;
    chatFrame.size.height = self.view.frame.size.height;
    self.chatTable.frame = chatFrame;
     */
    
    self.keyboardToolbar.frame = CGRectMake(0, 372, 320, 44);
	self.chatTable.frame = CGRectMake(0, 0, 320, 372);
	
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
    NSLog(@"Sections Count: %d",[[self.fetchedResultsController sections] count]);
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *sections = [[self fetchedResultsController] sections];
	
    if ([sections count]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
        return sectionInfo.numberOfObjects;    
    }

    return 0;
}


-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"messageCell";
    
    /*
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
        
	}
    
    
    XMPPMessageCoreDataObject *messageObj = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (messageObj) {
        cell.textLabel.text = messageObj.body;
        if (messageObj.selfReplied == [NSNumber numberWithInt:1]) {
            cell.textLabel.textAlignment = UITextAlignmentRight;
        } else {
            cell.textLabel.textAlignment = UITextAlignmentLeft;
        }
        
    }
     
     */
    
    
     
    chatMessageCell *cell = (chatMessageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
        NSArray* topLevelObj = [[NSBundle mainBundle] loadNibNamed:@"messageCell" owner:nil options:nil];
        
        for (id currentObject in topLevelObj) {
            if ([currentObject isKindOfClass:[UITableViewCell class]]) {
                cell = (chatMessageCell *) currentObject;
                break;
            }
        }
        
	}
    
    
    XMPPMessageCoreDataObject *messageObj = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell setMessage:messageObj];
    
    return cell;
}


-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [chatMessageCell sizeForMessage:[self.fetchedResultsController objectAtIndexPath:indexPath]];
}


///ACTIONS
////////////////////////////////////////
- (IBAction)selectAction:(id)sender 
{
    UIActionSheet *popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo or Video",@"Choose Existing",@"Audio Note",@"Share Contact", @"Share Location", nil];
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [popupQuery showInView:self.view];
    
}


-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Action SheetButton Index %d",buttonIndex);
    if (buttonIndex == 0) {
        [_mediaHandler takePhoto];
    }
}



-(void) presentImagePickerController:(UINavigationController *)imagePicker
{
    [self presentModalViewController:imagePicker animated:YES];
}


-(void) dismissImagePicker
{
    [self dismissModalViewControllerAnimated:YES];
}




@end
