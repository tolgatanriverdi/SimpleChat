//
//  XMPPMessageUserCoreDataObject.h
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPMessageCoreDataObject;

@interface XMPPMessageUserCoreDataObject : NSManagedObject

@property (nonatomic, retain) NSString * jidStr;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSSet *messages;
@end

@interface XMPPMessageUserCoreDataObject (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(XMPPMessageCoreDataObject *)value;
- (void)removeMessagesObject:(XMPPMessageCoreDataObject *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
