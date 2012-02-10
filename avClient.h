//
//  avClient.h
//  av
//
//  Created by Utku Altinkaya on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"


#define CLIENT_SERVER_URL @"http://95.0.221.13" 
#define CLIENT_BASE_URL @"http://95.0.221.13/" 

#define NOTIFICATION_SERVER_URL @"http://95.0.221.11:8888/"
#define AVATAR_SERVER_URL @"http://95.0.221.11:8989/"



//demo_avatar3@argela.com.tr
//mail.argela.com.tr 995
//smtp 587


@class avClientTask;
@class avLoginTask;

@protocol avClientDelegate <NSObject>
-(void) loginDidFail;
-(void) loginDidSucceed;
@optional
-(void) taskDidFail:(NSString*)error;
@end

@protocol avClientTaskDelegate <NSObject>

- (void) taskDidSucceed :(avClientTask*)task;

@optional
- (void) taskDidFail :(avClientTask*)task;

@end


@interface avClient : NSObject <avClientTaskDelegate> {
    NSMutableArray* tasks;
    avLoginTask* loginTask;
    NSString *countryMobileCode;
}
@property (nonatomic, unsafe_unretained) id<avClientDelegate> delegate;
@property (nonatomic, copy) NSString* session;

//- (void) registerUser:(NSString*) username sucesss:(SEL)callback fail:(SEL)callback;
- (void) runTask: (avClientTask*) task;
- (void) taskIsDone: (avClientTask*) task;
- (void) login;
-(void) cancelTask:(avClientTask*)task;

+ (avClient*) shared;
@end


@interface avClientTask : NSObject <ASIHTTPRequestDelegate> {
}
@property (nonatomic, unsafe_unretained) id<avClientTaskDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableDictionary* payload;
@property (nonatomic, retain) ASIHTTPRequest* request;

- (ASIHTTPRequest*) createRequest;
- (NSString*) payloadXML;
- (NSString*) url;
- (BOOL) requireLogin;
- (BOOL) processResponse:(ASIHTTPRequest *)_request;
@end


@interface avRegisterTask : avClientTask <ASIHTTPRequestDelegate> {
@private
    
}
@end

@interface avLoginTask : avClientTask <ASIHTTPRequestDelegate>{
@private
    
}
@property (nonatomic, copy) NSString* session;
@end

@interface avActivateTask : avClientTask <ASIHTTPRequestDelegate>


@end


@interface avListCategoriesTask : avClientTask {
@private
    
}
@end

@interface avListAvatarsTask : avClientTask {
@private
    
}
@end

@interface avMailPropsTask : avClientTask {
@private
    
}
@end

@interface avSelectAvatar : avClientTask {
@private
    
}
@property (nonatomic, assign) int avatarId;

@end

@interface avListSubscribedAvatars : avClientTask {
@private
    
}
@end

@interface avSendContacts : avClientTask

@end

@interface avRegisterNotifications : avClientTask

@property (nonatomic, retain) NSData* deviceId;
@property (nonatomic, copy) NSString* mailbox;

@end

@interface avSendNotification : avClientTask

@property (nonatomic, copy) NSString* mailbox;

@end

@interface avDownloadAvatar: avClientTask

@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* path;

@end
