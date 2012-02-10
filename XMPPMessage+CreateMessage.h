//
//  XMPPMessage+CreateMessage.h
//  SimpleChat
//
//  Created by ARGELA on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessage.h"

@interface XMPPMessage (CreateMessage)

-(void) addSubjectToMessage:(NSString*)subject;
-(void) addBodyToMessage:(NSString *)bodyMessage;
-(void) addThumbNailPath:(NSString*)thumbnailPath withActualDataPath:(NSString*)dataPath;
-(void) addLattitude:(double)lattitude andLongitude:(double)longitude;
-(void) addContactFirstName:(NSString*)firstName andLastName:(NSString*)lastName andMobilePhone:(NSString*)mobilePhone andIphoneNo:(NSString*)iphoneNo;


-(NSArray*) getFileMessageContent;
-(NSArray*) getCoordMessageContent;
-(NSArray*) getContactMessageContent;

-(BOOL) isImageMessage;
-(BOOL) isAudioMessage;
-(BOOL) isCoordMessage;
-(BOOL) isContactMessage;
-(BOOL) isActualChatMessage;

@end
