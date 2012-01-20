//
//  avMessageCell.h
//  av
//
//  Created by Utku ALTINKAYA on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPMessageCoreDataObject.h"

@interface chatMessageCell : UITableViewCell 

@property (nonatomic, assign) XMPPMessageCoreDataObject* message;
@property (nonatomic, strong) UIImageView* play;


+ (CGFloat) sizeForMessage: (XMPPMessageCoreDataObject*) message;


@end
