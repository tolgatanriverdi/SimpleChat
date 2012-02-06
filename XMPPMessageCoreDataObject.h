//
//  XMPPMessageCoreDataObject.h
//  SimpleChat
//
//  Created by ARGELA on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPMessageUserCoreDataObject;

@interface XMPPMessageCoreDataObject : NSManagedObject

@property (nonatomic, retain) NSData * actualData;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * messageReceipant;
@property (nonatomic, retain) NSNumber * selfReplied;
@property (nonatomic, retain) NSString * sendDate;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) XMPPMessageUserCoreDataObject *whoOwns;

@end
