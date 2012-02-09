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
-(void) addLattitude:(double)lattitude andLongitude:(double)longitude;
-(void) addContactFirstName:(NSString*)firstName andLastName:(NSString*)lastName;
-(void) addContactPhoneNumbers:(NSString*)mobileNo andIphoneNumber:(NSString*)iphoneNo;

-(BOOL) isImageMessage;
-(BOOL) isAudioMessage;
-(BOOL) isCoordMessage;
-(BOOL) isContactMessage;

@end
