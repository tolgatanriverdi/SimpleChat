//
//  XMPPHandler.h
//  SimpleChat
//
//  Created by ARGELA on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@protocol XMPPHandlerDelegate <NSObject>

-(void) setXMPPHandlerConnectionStatus:(BOOL)status;
-(void) presenceStatusChanged:(XMPPJID*)jid withStatus:(NSString*)status;

@end


@interface XMPPHandler : NSObject<XMPPRosterDelegate,XMPPStreamDelegate>

@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *password;
@property (nonatomic,strong) NSString *hostname;


@property (nonatomic,assign) id<XMPPHandlerDelegate> delegate;  


-(void) configure;
-(void) connect;
-(void) disconnect;
-(void) transferFile:(NSString *)filePath fromUser:(XMPPJID *)userJid toUser:(NSString *)to withType:(NSString*)type;
-(XMPPJID*) getMyJid;


- (NSManagedObjectContext *)getManagedObjectRoster;
- (NSManagedObjectContext *)getmanagedObjectMessage;
//- (NSManagedObjectContext *)getManagedObjectCapabilities;

@end
