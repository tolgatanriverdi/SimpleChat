//
//  ChatThreadController.h
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"

@interface ChatThreadController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *chatTable;
@property (weak, nonatomic) IBOutlet UIToolbar *keyboardToolbar;
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;

@property (nonatomic,assign) XMPPJID *chatWith;
@property (nonatomic,strong) NSManagedObjectContext *context;

@end
