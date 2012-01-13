//
//  StatusViewController.h
//  SimpleChat
//
//  Created by ARGELA on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface StatusViewController : UIViewController<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *statusText;

@end
