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

-(void) addThumbNailPath:(NSString *)path
{
    NSXMLElement *thumbnailElement = [NSXMLElement elementWithName:@"thumbnail" stringValue:path];
    [self addChild:thumbnailElement];
}

-(void) addDataPath:(NSString *)path
{
    NSXMLElement *actualData = [NSXMLElement elementWithName:@"actualData" stringValue:path];
    [self addChild:actualData];
}

-(void) addLattitude:(double)lattitude andLongitude:(double)longitude
{
    NSString *latStr = [NSString stringWithFormat:@"%f",lattitude];
    NSString *lonStr = [NSString stringWithFormat:@"%f",longitude];
    NSXMLElement *latElement = [NSXMLElement elementWithName:@"lattitude" stringValue:latStr];
    [self addChild:latElement];
    NSXMLElement *lonElement = [NSXMLElement elementWithName:@"longitude" stringValue:lonStr];
    [self addChild:lonElement];
}

-(void) addContactFirstName:(NSString *)firstName andLastName:(NSString *)lastName
{
    NSXMLElement *firstNameElement = [NSXMLElement elementWithName:@"contactFirstName" stringValue:firstName];
    [self addChild:firstNameElement];
    NSXMLElement *lastNameElement = [NSXMLElement elementWithName:@"contactLastname" stringValue:lastName];
    [self addChild:lastNameElement];
}

-(void) addContactPhoneNumbers:(NSString*)mobileNo andIphoneNumber:(NSString*)iphoneNo
{
    NSXMLElement *mobilePhoneElement = [NSXMLElement elementWithName:@"mobilePhoneNo" stringValue:mobileNo];
    [self addChild:mobilePhoneElement];
    NSXMLElement *iphonePhoneElement = [NSXMLElement elementWithName:@"iphonePhoneNo" stringValue:iphoneNo];
    [self addChild:iphonePhoneElement];
}


/////////////////////////////////////


-(BOOL) isImageMessage
{
    BOOL result=NO;
    if ([[[self attributeForName:@"type"] stringValue] isEqualToString:@"image"]) {
        result = YES;
    }
    
    return result;
}

-(BOOL) isAudioMessage
{
    BOOL result=NO;
    if ([[[self attributeForName:@"type"] stringValue] isEqualToString:@"audio"]) {
        result = YES;
    }
    
    return result;    
}

-(BOOL) isCoordMessage
{
    BOOL result=NO;
    if ([[[self attributeForName:@"type"] stringValue] isEqualToString:@"coordinate"])
    {
        result = YES;
    }
    
    return result;
}

-(BOOL) isContactMessage
{
    BOOL result=NO;
    if ([[[self attributeForName:@"type"] stringValue] isEqualToString:@"contact"])
    {
        result = YES;
    }
    
    return result;    
}

@end
