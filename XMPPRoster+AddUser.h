//
//  XMPPRoster+AddUser.h
//  SimpleChat
//
//  Created by ARGELA on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPRoster.h"

@interface XMPPRoster (AddUser)
- (void) addUser:(XMPPJID *)jid withNickname:(NSString *)optionalName withSubscriptionType:(NSString*)subsType;
@end
