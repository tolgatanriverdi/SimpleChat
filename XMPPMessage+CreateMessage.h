//
//  XMPPMessage+CreateMessage.h
//  SimpleChat
//
//  Created by ARGELA on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessage.h"

@interface XMPPMessage (CreateMessage)

-(void) addBodyToMessage:(NSString *)bodyMessage;
-(void) addThumbNailPath:(NSString*)path;
-(void) addDataPath:(NSString*)path;


@end
