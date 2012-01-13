//
//  XMPPMessageUserCoreDataObject+Update.h
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessageUserCoreDataObject.h"

@interface XMPPMessageUserCoreDataObject (Update)
+(XMPPMessageUserCoreDataObject *) messageUserWithJid:(NSString*)jidStr andDisplayName:(NSString*)displayName inManagedObjectContext:(NSManagedObjectContext*)context;
@end
