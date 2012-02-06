//
//  XMPPMessageCoreDataObject+AddMessage.h
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessageCoreDataObject.h"

@interface XMPPMessageCoreDataObject (AddMessage)
+(XMPPMessageCoreDataObject*) insertMessageWithBody:(NSString *)body andSendDate:(NSString *)sendDate andMessageReceipant:(NSString*)messageReceipant withType:(NSString*)type withThumbnail:(NSData*)thumbNail withActualData:(NSData*)actualData includingUserJid:(NSString*)jidStr andUserDisplay:(NSString*)displayName inManagedObjectContext:(NSManagedObjectContext*)context withSelfRepliedStatus:(NSNumber*)status;
@end
