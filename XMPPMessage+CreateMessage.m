//
//  XMPPMessage+CreateMessage.m
//  SimpleChat
//
//  Created by ARGELA on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessage+CreateMessage.h"

@implementation XMPPMessage (CreateMessage)

-(void) addBodyToMessage:(NSString *)bodyMessage
{
    NSXMLElement *bodyElement = [NSXMLElement elementWithName:@"body" stringValue:bodyMessage];
    [self addChild:bodyElement];
}

-(void) addSendDateToMessage:(NSDate *)sendDate
{
    NSString *sendingDate = [sendDate description];
    NSLog(@"Sending Date For Message is: %@",sendingDate);
    
    NSXMLElement *sendDateElement = [NSXMLElement elementWithName:@"sendDate" stringValue:sendingDate];
    [self addChild:sendDateElement];
}

@end
