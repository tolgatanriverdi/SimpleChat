//
//  XMPPMessageCoreDataObject.h
//  SimpleChat
//
//  Created by ARGELA on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPMessageUserCoreDataObject;

@interface XMPPMessageCoreDataObject : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSDate * sendDate;
@property (nonatomic, retain) NSNumber * selfReplied;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) XMPPMessageUserCoreDataObject *whoOwns;

@end
