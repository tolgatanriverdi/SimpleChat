//
//  XMPPRoster+AddUser.m
//  SimpleChat
//
//  Created by ARGELA on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPRoster+AddUser.h"

@implementation XMPPRoster (AddUser)


- (void)addUser:(XMPPJID *)jid withNickname:(NSString *)optionalName withSubscriptionType:(NSString*)subsType
{
    NSLog(@"SUBS TYPE: %@",subsType);
	// This is a public method, so it may be invoked on any thread/queue.
	
	if (jid == nil) return;
	
	XMPPJID *myJID = xmppStream.myJID;
	
	if ([myJID isEqualToJID:jid options:XMPPJIDCompareBare])
	{
		// You don't need to add yourself to the roster.
		// XMPP will automatically send you presence from all resources signed in under your username.
		// 
		// E.g. If you sign in with robbiehanson@deusty.com/home you'll automatically
		//    receive presence from robbiehanson@deusty.com/work
		
		//XMPPLogInfo(@"%@: %@ - Ignoring request to add myself to my own roster", [self class], THIS_METHOD);
		return;
	}
	
	// Add the user to our roster.
	// 
	// <iq type="set">
	//   <query xmlns="jabber:iq:roster">
	//     <item jid="bareJID" name="optionalName"/>
	//   </query>
	// </iq>
	
	NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
	[item addAttributeWithName:@"jid" stringValue:[jid bare]];
	
	if (optionalName)
	{
		[item addAttributeWithName:@"name" stringValue:optionalName];
	}
    
    if (subsType)
    {
        [item addAttributeWithName:@"subscription" stringValue:subsType];
    }
	
	NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
	[query addChild:item];
	
	XMPPIQ *iq = [XMPPIQ iqWithType:@"set"];
	[iq addChild:query];
	
	[xmppStream sendElement:iq];
	
	// Subscribe to the user's presence.
	// 
	// <presence to="bareJID" type="subscribe"/>
	
	[xmppStream sendElement:[XMPPPresence presenceWithType:@"subscribe" to:[jid bareJID]]];
}

@end
