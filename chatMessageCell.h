//
//  avMessageCell.h
//  av
//
//  Created by Utku ALTINKAYA on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPMessageCoreDataObject.h"

@protocol ChatCellDelegate<NSObject>

-(void) chatCellViewButtonPressed:(NSInteger) indexOfMessage;
@end

@interface chatMessageCell : UITableViewCell 

@property (nonatomic, assign) XMPPMessageCoreDataObject* message;
@property (nonatomic, strong) UIImageView* play;
@property (nonatomic) int messageIndex;

@property (nonatomic,assign) id<ChatCellDelegate>buttonDelegate;


+ (CGFloat) sizeForMessage: (XMPPMessageCoreDataObject*) message;


@end
