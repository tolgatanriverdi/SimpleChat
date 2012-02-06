//
//  FriendListController.h
//  SimpleChat
//
//  Created by ARGELA on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#include "XMPPFramework.h"

@interface FriendListController : UITableViewController<NSFetchedResultsControllerDelegate>
@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSManagedObjectContext *chatThreadContext;

@property (nonatomic,assign) NSString* selfID;
@property (nonatomic,assign) XMPPJID *selfJID;

-(void) presenceStatusChanged:(XMPPJID*)jid withStatus:(NSString*)status;
@end
