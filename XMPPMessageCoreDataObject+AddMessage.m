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

+(XMPPMessageCoreDataObject *) insertMessageWithBody:(NSString *)body andSendDate:(NSString *)sendDate withType:(NSString *)type includingUserJid:(NSString *)jidStr andUserDisplay:(NSString *)displayName inManagedObjectContext:(NSManagedObjectContext *)context
{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *dateSent = [dateFormatter dateFromString:sendDate];
    
    XMPPMessageCoreDataObject *messageObj = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPMessageCoreDataObject" inManagedObjectContext:context];
    
    messageObj.body = body;
    messageObj.type = @"chat";
    messageObj.sendDate = dateSent;
    messageObj.whoOwns = [XMPPMessageUserCoreDataObject messageUserWithJid:jidStr andDisplayName:displayName inManagedObjectContext:context]; 
    
    
    return messageObj;
}
 
@end
