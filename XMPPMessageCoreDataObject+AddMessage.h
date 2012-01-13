//
//  XMPPMessageCoreDataObject+AddMessage.h
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessageCoreDataObject.h"

@interface XMPPMessageCoreDataObject (AddMessage)
+(XMPPMessageCoreDataObject*) insertMessageWithBody:(NSString *)body andSendDate:(NSString *)sendDate withType:(NSString*)type includingUserJid:(NSString*)jidStr andUserDisplay:(NSString*)displayName inManagedObjectContext:(NSManagedObjectContext*)context;
@end
