//
//  avClient.m
//  av
//
//  Created by Utku Altinkaya on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "avClient.h"
#import "RXMLElement.h"
#import "avContactModel.h"

#import "ASIDownloadCache.h"

avClient* _avClient = nil;

@implementation avClient

@synthesize delegate, session;

+(avClient*) shared 
{
    if (!_avClient) {
        _avClient = [[avClient alloc] init];
    }
    return _avClient;
}

-(id)init
{
    if ((self = [super init])) {
        tasks  = [NSMutableArray array];
        session = nil;        
        loginTask = nil;
    }
    return self;
}

-(void) login 
{
    NSString* username = [[NSUserDefaults standardUserDefaults] objectForKey:@"twinChatUsername"];
    NSString* password = [[NSUserDefaults standardUserDefaults] objectForKey:@"twinChatPassword"];
    if (!(username && password)) {
        [self.delegate loginDidFail];
    } else {
        loginTask = [[avLoginTask alloc] init];
        [loginTask.payload setObject:username forKey:@"username"];
        [loginTask.payload setObject:password forKey:@"password"];
        loginTask.delegate = self;
        [self runTask: loginTask];
    }
}

-(void)runTask:(avClientTask *)task
{
//    return;
    [tasks addObject: task];
    if ([task requireLogin] && !session) {
        if (!loginTask) {
            [self login];
        }
        return;
    }
    ASIHTTPRequest* request = [task createRequest]; 
    [request startAsynchronous];
}

-(void) taskIsDone: (avClientTask*) task
{
    [tasks removeObject:task];
//    [task autorelease];
}

-(void)taskDidFail:(avClientTask *)task
{ 
    [self.delegate loginDidFail];
}

-(void) taskDidSucceed:(avClientTask *)task
{
    [self.delegate loginDidSucceed];
    self.session = ((avLoginTask*)task).session;
    for (avClientTask* task in tasks) {
        if ([task requireLogin]) {
            ASIHTTPRequest* request = [task createRequest];
            [request startAsynchronous];            
        }
    }
}

-(void) cancelTask:(avClientTask*)task
{
    if (task.request) {
        [task.request clearDelegatesAndCancel];        
    }
    [tasks removeObject: task];
}

@end

@implementation avClientTask

@synthesize delegate, payload, request;

-(BOOL) requireLogin 
{
    return YES;
}

- (NSString *)url
{
    return @"";
}

-(id)init
{
    if ((self = [super init])) {
        delegate = nil;
        payload = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)dealloc
{
    [self.request clearDelegatesAndCancel];    
    NSLog(@"dealloc task!");
}


-(NSString*) payloadXML 
{
    NSMutableString* string =[NSMutableString string] ;
    for (NSString* key in [payload allKeys]) {
        [string appendFormat:@"<%@>%@</%@>", key, [payload objectForKey:key], key];
    }
    return string;
}

-(ASIHTTPRequest *)createRequest
{
    [self.request clearDelegatesAndCancel];
    self.request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", CLIENT_BASE_URL, [self url]]]];
    [request setDelegate:self];
    [request addRequestHeader:@"Content-Type" value:@"application/xml"];
    [request addRequestHeader:@"Accept" value:@"application/xml, text/plain, text/xml, text/html"];
    return request;
}

- (void)requestFinished:(ASIHTTPRequest *)_request
{
    NSString *responseString = [request responseString];
    BOOL error = [responseString rangeOfString:@"Error"].location != NSNotFound;
    if (!error) {
        if ([responseString rangeOfString:@"Login Dialog"].location != NSNotFound) {
            [[avClient shared] login];
            return;
        }
    }
    NSLog(@"%@", responseString);
    if (!error && [self processResponse:_request]) {    
        [self.delegate taskDidSucceed: self];
        [[avClient shared] taskIsDone: self];        
    } else {
        [self requestFailed:_request];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)_request
{
    NSError *error = [request error];
    NSLog(@"%@", error);  
    if ([self.delegate respondsToSelector:@selector(taskDidFail:)]) {
        [self.delegate taskDidFail:self];
    }
    [[avClient shared] taskIsDone: self];    
}

-(BOOL) processResponse:(ASIHTTPRequest *)_request
{
    return YES;
}

@end


@implementation avRegisterTask 

-(BOOL) requireLogin 
{
    return NO;
}

- (NSString *)url
{
    return @"registerMobileUserWS";
}

- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    NSString* body = [NSString stringWithFormat: 
                      @"<?xml version=\"1.0\" encoding=\"ISO-8859-9\" standalone=\"yes\"?><user>%@</user>\n", 
                      [self payloadXML]];
    [request appendPostData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    request.requestMethod = @"POST";    
    request.timeOutSeconds = 30;    
    NSLog(@"%@", body); 
    return request;
}

@end


@implementation avLoginTask

@synthesize session;

-(BOOL) requireLogin 
{
    return NO;
}

- (NSString *)url
{
    return @"loginWS";
}

- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    NSString* body = [NSString stringWithFormat: 
        @"<?xml version=\"1.0\" encoding=\"ISO-8859-9\" standalone=\"yes\"?><user>%@</user>\n", 
                      [self payloadXML]];
    NSLog(@"body:%@\n", body);
    [request appendPostData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    request.requestMethod = @"POST";
    return request;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    //[super requestFinished: request];
    NSString *responseString = [request responseString];
    NSLog(@"%@", responseString);
    RXMLElement* xml = [RXMLElement elementFromXMLString:responseString];
    self.session = [[xml child:@"sessionId"] text];
    if (!session || [session isEqualToString:@"-1"]) {
        [self requestFailed:request];
    } else {
        self.session = session;
        [self.delegate taskDidSucceed:self];
        [[avClient shared] taskIsDone: self];  
    }
}

@end

@implementation avActivateTask

-(BOOL) requireLogin 
{
    return NO;
}

- (NSString *)url
{
    return @"activateMobileAccountWS";
}

- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    NSString* body = [NSString stringWithFormat: 
                      @"<?xml version=\"1.0\" encoding=\"ISO-8859-9\" standalone=\"yes\"?><user>%@</user>\n", 
                      [self payloadXML]];
    NSLog(@"body:%@\n", body);
    [request appendPostData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    request.requestMethod = @"POST";
    return request;
}

@end

@implementation avListCategoriesTask

- (NSString *)url
{
    return @"categories";
}

- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    request.requestMethod = @"GET";
    request.delegate = self;
    return request;
}

@end

@implementation avListAvatarsTask

- (NSString *)url
{
    return @"avatars";
}

- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    request.requestMethod = @"GET";
    request.delegate = self;
    return request;
}

@end

@implementation avSelectAvatar

@synthesize avatarId;

- (NSString *) url
{
    return [NSString stringWithFormat: @"selectavatarws/%d", avatarId];
}


- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    request.requestMethod = @"GET";
    request.delegate = self;
    return request;
}

@end

@implementation avListSubscribedAvatars

- (NSString *) url
{
    return @"avatars/subscriber";
}

- (ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    request.requestMethod = @"GET";
    return request;
}

@end

@implementation avSendContacts

- (NSString *) url
{
    return @"sendaddressbook";
}

-(NSString*) contactXML:(avContactModel*)contact
{
    NSMutableString* emails = [NSMutableString string];
    NSMutableString* phones = [NSMutableString string];
    
    for (NSString* phone in contact.phoneNumbers) {
        NSString *fphone = [[phone componentsSeparatedByCharactersInSet:
                              [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] 
                             componentsJoinedByString:@""];
        if (fphone.length > 10) {
            fphone = [fphone substringFromIndex:fphone.length-10];            
        }
        [phones appendFormat:@"<phonenumber>+90%@</phonenumber>", fphone];
    }
    
    return [NSString stringWithFormat:@" "
            "<contact>"
            "<emailaddresses>"
            "%@"
            "</emailaddresses>"
            "<id>%d</id>"
            "<name>%@</name>"
            "<phonenumbers>"
            "%@"
            "</phonenumbers>"
            "<surname>%@</surname>"
            "</contact>", emails, contact.abId, 
            (contact.fullName ? contact.fullName : @""), 
            phones, (contact.lastName ? contact.lastName: @"")];    
}

-(NSString*) addressBookXML 
{
    NSMutableString* content = [NSMutableString string];
    for (avContactModel* contact in [avContactModel all]) {
        [content appendString: [self contactXML: contact]];
    }
    NSString* xml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>"\
                     "<addressbook><contacts>%@</contacts></addressbook>", content];    
    return xml;
}

-(ASIHTTPRequest *)createRequest
{
    ASIHTTPRequest* request = [super createRequest];
    NSString* body = [self addressBookXML];
    [request appendPostData: [body dataUsingEncoding: NSUTF8StringEncoding]];
    request.requestMethod = @"POST";
    NSLog(@"%@", body); 
    return request;
}

-(BOOL)processResponse:(ASIHTTPRequest *)request
{  
    NSMutableArray* contacts = [[NSMutableArray alloc] initWithArray:[avContactModel all]];
    RXMLElement* element = [RXMLElement elementFromXMLString:request.responseString];
    [element iterate:@"addressBookResponseFormat" with:^(RXMLElement *e) {
        int abId = [e child:@"contactId"].textAsInt;
        for (avContactModel* contact in contacts) {
            if (contact.abId == abId) {
                contact.isAvatarUser = YES;
                break;
            }
        }
    }];
    
    NSDictionary *processedContacts = [NSDictionary dictionaryWithObject:contacts forKey:@"processedContacts"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateContacts" object:nil userInfo:processedContacts]; 
    
    return YES;
}

@end

@implementation avRegisterNotifications

@synthesize deviceId, mailbox;

-(BOOL) requireLogin 
{
    return NO;
}

-(ASIHTTPRequest *)createRequest
{
    [self.request clearDelegatesAndCancel];
    ASIFormDataRequest* formReq = [ASIFormDataRequest requestWithURL:
            [NSURL URLWithString: [NSString stringWithFormat:@"%@r", NOTIFICATION_SERVER_URL]]];
    self.request = formReq;
    [self.request setDelegate:self];
    
    [formReq addData:deviceId forKey:@"deviceId"];
    [formReq addData:[mailbox dataUsingEncoding:NSUTF8StringEncoding] forKey:@"mailbox"];    
    
    return self.request;
}

@end

@implementation avSendNotification

@synthesize mailbox;

-(BOOL) requireLogin 
{
    return NO;
}

-(ASIHTTPRequest *)createRequest
{
    [self.request clearDelegatesAndCancel];
    ASIFormDataRequest* formReq = [ASIFormDataRequest requestWithURL:
            [NSURL URLWithString: [NSString stringWithFormat:@"%@n", NOTIFICATION_SERVER_URL]]];
    self.request = formReq;
    [self.request setDelegate:self];
    
    [formReq addPostValue:mailbox forKey:@"to"];
    
    NSString* sender = [[NSUserDefaults standardUserDefaults] stringForKey:@"mailbox"];
    [formReq addPostValue:sender forKey:@"sender"];
    
    return self.request;
}

@end

@implementation avDownloadAvatar

@synthesize name, path;

-(BOOL) requireLogin 
{
    return NO;
}

-(ASIHTTPRequest *)createRequest
{
    [self.request clearDelegatesAndCancel];
    self.request= [ASIHTTPRequest requestWithURL:
        [NSURL URLWithString: [NSString stringWithFormat:@"%@getAvatar?id=%@", AVATAR_SERVER_URL, name]]];
    [self.request setSecondsToCache: 10];
    [self.request setDownloadCache:[ASIDownloadCache sharedCache]];    
    [self.request setDelegate:self];
    self.request.timeOutSeconds = 30;
    return self.request;
}

- (NSString *)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *cacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"cache"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath: cacheDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error];
    return [cacheDir stringByAppendingPathComponent:name];
}

-(void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"%@", [self filePath]);
    [[request responseData] writeToFile:[self filePath] atomically:NO];
    self.path = [self filePath];
    [super requestFinished:request];
}

@end
