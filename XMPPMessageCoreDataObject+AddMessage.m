//
//  XMPPMessageCoreDataObject+AddMessage.m
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessageCoreDataObject+AddMessage.h"
#import "XMPPMessageUserCoreDataObject+Update.h"

@implementation XMPPMessageCoreDataObject (AddMessage)

+(XMPPMessageCoreDataObject *) insertMessageWithBody:(NSString *)body andSendDate:(NSString *)sendDate andMessageReceipant:(NSString*)messageReceipant withType:(NSString *)type withThumbnail:(NSData*)thumbNail withActualData:(NSData*)actualData includingUserJid:(NSString *)jidStr andUserDisplay:(NSString *)displayName inManagedObjectContext:(NSManagedObjectContext *)context withSelfRepliedStatus:(NSNumber*)status
{
    
    XMPPMessageCoreDataObject *messageObj = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPMessageCoreDataObject" inManagedObjectContext:context];
    
    messageObj.body = body;
    messageObj.type = type;
    messageObj.sendDate = sendDate;
    messageObj.selfReplied = status;
    messageObj.messageReceipant = messageReceipant;
    messageObj.thumbnail = thumbNail;
    messageObj.actualData = actualData;
    messageObj.whoOwns = [XMPPMessageUserCoreDataObject messageUserWithJid:jidStr andDisplayName:displayName inManagedObjectContext:context]; 
    
    
    return messageObj;
}
 
@end
