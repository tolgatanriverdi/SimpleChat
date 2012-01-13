//
//  XMPPMessageUserCoreDataObject+Update.m
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessageUserCoreDataObject+Update.h"

@implementation XMPPMessageUserCoreDataObject (Update)

+(XMPPMessageUserCoreDataObject*) messageUserWithJid:(NSString *)jidStr andDisplayName:(NSString *)displayName inManagedObjectContext:(NSManagedObjectContext *)context
{
    XMPPMessageUserCoreDataObject *messageUser = nil;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageUserCoreDataObject"];
    request.predicate = [NSPredicate predicateWithFormat:@"jidStr = %@",jidStr];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    request.sortDescriptors = [NSArray arrayWithObject:sortDesc];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    
    if ([matches count]) {
        return [matches lastObject];
    }
    else {
        messageUser = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPMessageUserCoreDataObject" inManagedObjectContext:context];
        messageUser.jidStr = jidStr;
        messageUser.displayName = displayName;
    }
    
    return messageUser;
}

@end
