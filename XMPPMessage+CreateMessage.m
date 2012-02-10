//
//  XMPPMessage+CreateMessage.m
//  SimpleChat
//
//  Created by ARGELA on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPMessage+CreateMessage.h"

@implementation XMPPMessage (CreateMessage)

-(void) addSubjectToMessage:(NSString*)subject
{
    NSXMLElement *subjectElement = [NSXMLElement elementWithName:@"subject" stringValue:subject];
    [self addChild:subjectElement];
}

-(void) addBodyToMessage:(NSString *)bodyMessage
{
    NSXMLElement *bodyElement = [NSXMLElement elementWithName:@"body" stringValue:bodyMessage];
    [self addChild:bodyElement];
}

-(void) addThumbNailPath:(NSString *)thumbnailPath withActualDataPath:(NSString *)dataPath
{
    NSString *bodyStr = [NSString stringWithFormat:@"%@,%@",thumbnailPath,dataPath];
    [self addBodyToMessage:bodyStr];
}

-(void) addLattitude:(double)lattitude andLongitude:(double)longitude
{
    NSString *latStr = [NSString stringWithFormat:@"%f",lattitude];
    NSString *lonStr = [NSString stringWithFormat:@"%f",longitude];
    NSString *bodyStr = [NSString stringWithFormat:@"%@,%@",latStr,lonStr];
    [self addBodyToMessage:bodyStr];
}

-(void) addContactFirstName:(NSString *)firstName andLastName:(NSString *)lastName andMobilePhone:(NSString *)mobilePhone andIphoneNo:(NSString *)iphoneNo
{
    NSString *bodyStr = [NSString stringWithFormat:@"%@,%@,%@,%@",firstName,lastName,mobilePhone,iphoneNo];
    [self addBodyToMessage:bodyStr];
}
/////////////////////////////////////

-(NSString*) getBodyString
{
    NSArray *elements = [self elementsForName:@"body"];
    if ([elements count] > 0) {
        NSXMLElement *element = [elements objectAtIndex:0];
        return [element stringValue];
    }    
    
    return nil;
}

-(NSArray*) getFileMessageContent
{
    NSString *fileStr = [self getBodyString];
    NSArray *fileContent = [fileStr componentsSeparatedByString:@","];
    
    return fileContent;
}

-(NSArray*) getContactMessageContent
{
    NSString *contactStr = [self getBodyString];
    NSArray *contactContent = [contactStr componentsSeparatedByString:@","];
    
    return contactContent;    
}

-(NSArray*) getCoordMessageContent
{
    NSString *coordStr = [self getBodyString];
    NSArray *coordContent = [coordStr componentsSeparatedByString:@","];
    
    return coordContent;
}


/////////////////////////////////////


-(BOOL) getSubject:(NSString*)stringVal
{
    NSArray *elements = [self elementsForName:@"subject"];
    if ([elements count] > 0) {
        NSXMLElement *element = [elements objectAtIndex:0];
        if ([[element stringValue] isEqualToString:stringVal]) {
            return YES;
        }
    }
    
    return NO;
}

-(BOOL) isImageMessage
{
    return [self getSubject:@"image"];
}

-(BOOL) isAudioMessage
{
    return [self getSubject:@"audio"];    
}

-(BOOL) isCoordMessage
{
    return [self getSubject:@"coordinate"];
}

-(BOOL) isContactMessage
{
    return [self getSubject:@"contact"];
}

-(BOOL) isActualChatMessage
{
    return [self getSubject:@"chat"];
}

@end
