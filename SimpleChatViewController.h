//
//  SimpleChatViewController.h
//  SimpleChat
//
//  Created by ARGELA on 1/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FriendListController.h"
#import "XMPPHandler.h"

@interface SimpleChatViewController : UIViewController<XMPPHandlerDelegate,UITextFieldDelegate>



@property int isInitializingFirstTime;


@property (weak, nonatomic) IBOutlet UITextField *username;

@property (weak, nonatomic) IBOutlet UITextField *password;

@property (nonatomic,strong) NSString *uName;
@property (nonatomic,strong) NSString *pass;

@property (nonatomic,strong) XMPPHandler *xmppHandler;

@property (nonatomic,weak) FriendListController *friendListTable;

@end
