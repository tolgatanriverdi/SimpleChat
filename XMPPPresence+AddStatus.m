//
//  XMPPPresence+AddStatus.m
//  SimpleChat
//
//  Created by ARGELA on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPPresence+AddStatus.h"

@implementation XMPPPresence (AddStatus)

-(void) addStatus:(NSString *)status
{
    //NSXMLElement *showElement = [NSXMLElement elementWithName:@"show" stringValue:@"online"];
    NSXMLElement *statusElement = [NSXMLElement elementWithName:@"status" stringValue:status];
    //[self addChild:showElement];
    [self addChild:statusElement];
}

@end
