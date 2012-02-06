//
//  MediaViewController.h
//  SimpleChat
//
//  Created by ARGELA on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPMessageCoreDataObject.h"

@interface MediaViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic,assign) NSString* fromUsername;
@property (nonatomic,assign) NSManagedObjectContext *context;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

-(void) setMessage:(XMPPMessageCoreDataObject*)message;

@end
