//
//  FriendListController.m
//  SimpleChat
//
//  Created by ARGELA on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendListController.h"
#import "ChatThreadController.h"



@interface FriendListController()
@property (nonatomic,strong) NSMutableDictionary *friendsPresenceStatus;
@end


@implementation FriendListController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize context = _context;
@synthesize friendsPresenceStatus = _friendsPresenceStatus;
@synthesize chatThreadContext = _chatThreadContext;
@synthesize selfID = _selfID;

////////Fetch ResultsController///////////////
-(void) configure
{
    if (!self.fetchedResultsController) {
        if (self.context) {
            NSLog(@"Context Already Initialized");
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:self.context];
            
            NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
            NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
            
            NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:entity];
            [fetchRequest setSortDescriptors:sortDescriptors];
            [fetchRequest setFetchBatchSize:10];
            
            self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.context sectionNameKeyPath:@"sectionNum" cacheName:nil];
            
            [self.fetchedResultsController setDelegate:self];
            
            
            NSError *error = nil;
            if (![self.fetchedResultsController performFetch:&error])
            {
                NSLog(@"Error Performing Fetch:%@",error);
                //DDLogError(@"Error performing fetch: %@", error);
            }
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[[self tableView] reloadData];
}


///////////////////////////////////////////

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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


-(void) presenceStatusChanged:(XMPPJID*)jid withStatus:(NSString *)status
{
    //Alttaki iki satir direk jid stringi aldigimizda gelen sacma karakterleri elemine etmek icindir
    //NSString *fullJid = [[jid user] stringByAppendingString:@"@"];
    //NSString *jidStr = [fullJid stringByAppendingString:[jid domain]];
    
    
    //NSLog(@"PresentStatusChangedInTable: JID: %@ Status: %@",jidStr,status);
    [self.friendsPresenceStatus setValue:status forKey:[jid bare]];
    //[self.tableView reloadData];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configure];
    self.friendsPresenceStatus = [[NSMutableDictionary alloc] init];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}


- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
		int section = [sectionInfo.name intValue];
		switch (section)
		{
			case 0  : return @"Available";
			case 1  : return @"Away";
			default : return @"Offline";
		}
	}
	
	return @"";
}




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	}
	
	return 0;
}

 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"friendCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
	
	XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //NSLog(@"Status For %@ is %@",user.displayName,user.primaryResource.show);
	
    if (user) {
        cell.textLabel.text = user.displayName;
        cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];

    
        if (self.friendsPresenceStatus) {
            NSString *presenceStatus = [self.friendsPresenceStatus objectForKey:user.jidStr];
        
            if (presenceStatus) {
                cell.detailTextLabel.text = presenceStatus;
            }   
        }
        else {
            cell.detailTextLabel.text = @"Bilinmiyor";
        }
    }

    
	//[self configurePhotoForCell:cell user:user];
	
	return cell;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController respondsToSelector:@selector(setChatWith:)]) {
        if (self.fetchedResultsController) {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            XMPPUserCoreDataStorageObject *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [segue.destinationViewController setChatWith:[user.jid description]];
            [segue.destinationViewController setContext:self.chatThreadContext];
            [segue.destinationViewController setSelfID:self.selfID];
        }
    }

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.

}

*/

@end
