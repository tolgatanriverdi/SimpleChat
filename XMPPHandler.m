//
//  XMPPHandler.m
//  SimpleChat
//
//  Created by ARGELA on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPHandler.h"
#import "XMPPPresence+AddStatus.h"
#import "XMPPMessage+CreateMessage.h"

#import "XMPPMessageCoreDataObject+AddMessage.h"
#import "XMPPMessageUserCoreDataObject+Update.h"

@interface XMPPHandler()


@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property BOOL 	allowSelfSignedCertificates;
@property BOOL allowSSLHostNameMismatch;

@property (nonatomic,strong)NSManagedObjectContext *managedObjectContext_roster;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext_capabilities;
@property (nonatomic,strong) UIManagedDocument *messageDocument;

@end


@implementation XMPPHandler


@synthesize xmppStream = _xmppStream;
@synthesize xmppReconnect = _xmppReconnect;
@synthesize xmppRoster = _xmppRoster;
@synthesize xmppRosterStorage = _xmppRosterStorage;

@synthesize allowSelfSignedCertificates = _allowSelfSignedCertificates;
@synthesize allowSSLHostNameMismatch = _allowSSLHostNameMismatch;


@synthesize username = _username;
@synthesize password = _password;
@synthesize hostname = _hostname;

@synthesize delegate = _delegate;


@synthesize managedObjectContext_roster = _managedObjectContext_roster;
@synthesize managedObjectContext_capabilities = _managedObjectContext_capabilities;
@synthesize messageDocument = _messageDocument;

-(void) setupStream
{
    self.xmppStream = [[XMPPStream alloc] init];
    self.xmppStream.hostName = self.hostname;
    //self.xmppStream.hostName = @"192.168.3.103";
    //self.xmppStream.myJID = @"tolga";
    
    

    
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		// 
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		self.xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
    
    
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
    self.xmppRoster.autoFetchRoster = YES;
    self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    
    //Activate modules
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppRoster activate:self.xmppStream];
    
    
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.allowSelfSignedCertificates = NO;
	self.allowSSLHostNameMismatch = NO;
    
    [self getmanagedObjectMessage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goOnline) name:@"saveStatus" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageIsSending:) name:@"messageSent" object:nil];
}


- (NSManagedObjectContext *)getManagedObjectRoster
{
    NSAssert([NSThread isMainThread],
	         @"NSManagedObjectContext is not thread safe. It must always be used on the same thread/queue");
	
	if (self.managedObjectContext_roster == nil)
	{
		self.managedObjectContext_roster = [[NSManagedObjectContext alloc] init];
		
		NSPersistentStoreCoordinator *psc = [self.xmppRosterStorage persistentStoreCoordinator];
		[self.managedObjectContext_roster setPersistentStoreCoordinator:psc];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(contextDidSave:)
		                                             name:NSManagedObjectContextDidSaveNotification
		                                           object:nil];
	}
	
	return self.managedObjectContext_roster;
}

- (NSManagedObjectContext*)getmanagedObjectMessage
{
    NSAssert([NSThread isMainThread],
	         @"NSManagedObjectContext is not thread safe. It must always be used on the same thread/queue");

    if (!self.messageDocument) {
        NSLog(@"Managed Document Olusturuluyor");
        NSArray *documentsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [documentsDir objectAtIndex:0];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"messageDocument"];
        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:filePath];
        
        self.messageDocument = [[UIManagedDocument alloc] initWithFileURL:fileUrl];
        
        
        NSDictionary *optionsForStore = [NSDictionary dictionaryWithObjectsAndKeys: 
                                         
                                         [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                         
                                         [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        [self.messageDocument setPersistentStoreOptions:optionsForStore];
         
        
        
        //Dokuman daha onceden varsa siler
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        
        
        //Dokumani olusturur
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [self.messageDocument saveToURL:self.messageDocument.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
        }
    }
    
    return self.messageDocument.managedObjectContext;
}

- (void)contextDidSave:(NSNotification *)notification
{
	NSManagedObjectContext *sender = (NSManagedObjectContext *)[notification object];
	
	if (sender != self.managedObjectContext_roster &&
	    [sender persistentStoreCoordinator] == [self.managedObjectContext_roster persistentStoreCoordinator])
	{
		//DDLogVerbose(@"%@: %@ - Merging changes into managedObjectContext_roster", THIS_FILE, THIS_METHOD);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[self.managedObjectContext_roster mergeChangesFromContextDidSaveNotification:notification];
		});
    }
	
    /*
	if (sender != managedObjectContext_capabilities &&
	    [sender persistentStoreCoordinator] == [managedObjectContext_capabilities persistentStoreCoordinator])
	{
        NSLog(@"Merging Capabilitieeeeeeeess");
		DDLogVerbose(@"%@: %@ - Merging changes into managedObjectContext_capabilities", THIS_FILE, THIS_METHOD);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[managedObjectContext_capabilities mergeChangesFromContextDidSaveNotification:notification];
		});
	}
     */
}

/*
- (NSManagedObjectContext *)getManagedObjectCapabilities
{
    NSAssert([NSThread isMainThread],
	         @"NSManagedObjectContext is not thread safe. It must always be used on the same thread/queue");
	
	if (self.managedObjectContext_capabilities == nil)
	{
		self.managedObjectContext_capabilities = [[NSManagedObjectContext alloc] init];
		
		NSPersistentStoreCoordinator *psc = [self.xmppCapabilitiesStorage persistentStoreCoordinator];
		[self.managedObjectContext_roster setPersistentStoreCoordinator:psc];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(contextDidSave:)
		                                             name:NSManagedObjectContextDidSaveNotification
		                                           object:nil];
	}
	
	return self.managedObjectContext_capabilities;
}
 */

/////////////////////

-(void) configure
{
    [self setupStream];
}

-(void) connect
{
    if (!self.xmppStream.isDisconnected) {
        return;
    }

    
    [self.xmppStream setMyJID:[XMPPJID jidWithString:self.username]];
    
    NSLog(@"XMPPHandler Conenct Username: %@",self.username);
    
    NSError *error = nil;
    if (![self.xmppStream connect:&error]) {
        [self.delegate setXMPPHandlerConnectionStatus:NO];
    }
}


-(void) disconnect
{
    if (self.xmppStream.isConnected) {
        [self.xmppStream disconnect];
    }
}

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *presenceStat = [prefs stringForKey:@"avatarChatStatus"];
    if (!presenceStat) {
        presenceStat = @"Available";
    }
    [presence addStatus:presenceStat];
    
	
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}


-(void) sendMessage:(NSString*)messageBody toAdress:(NSString*)to withType:(NSString*)type
{
    XMPPJID *toJid = [XMPPJID jidWithString:to];
    NSDate *currentTime = [NSDate date];
    XMPPMessage *newMessage = [[XMPPMessage alloc] initWithType:type to:toJid];
    [newMessage addBodyToMessage:messageBody];
    [newMessage addSendDateToMessage:currentTime];
    
    [self.xmppStream sendElement:newMessage];
}


-(void) messageIsSending:(NSNotification*)notification
{
    NSDictionary *messageContent = [notification userInfo];
    [self sendMessage:[messageContent valueForKey:@"body"] toAdress:[messageContent valueForKey:@"to"] withType:[messageContent valueForKey:@"type"]];
}


/////XMPP STREAM DELEGATES/////////
-(void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
    NSLog(@"Socket Baglandi");
}

-(void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"XMPP Server Baglantisi Kuruldu");
    
    NSError *error;
    if ([self.xmppStream authenticateWithPassword:self.password error:&error]) {
        NSLog(@"Authentication Basladi Uname: %@ Pass: %@ ",self.username,self.password);
    }
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    NSLog(@"Kullanici Hatasi: %@",[error description]);
    [self.delegate setXMPPHandlerConnectionStatus:NO];
}


-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    NSLog(@"XMPP Server Baglantisi Kesildi");
}

-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    NSLog(@"Authentication Basarili");
    [self goOnline];
    [self.delegate setXMPPHandlerConnectionStatus:YES];
}

-(void) xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    NSLog(@"Presence Received From: %@ Type: %@",[presence fromStr],[presence type]);
    NSString *status=@"Unknown";
    if (!presence.status) {
        NSLog(@"Presence Status Nil");
    }
    else {
        NSLog(@"Presence Status: %@",presence.status);
        status = [presence status];
        
    }
    [self.delegate presenceStatusChanged:presence.from withStatus:status];
}

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
    NSLog(@"Buddy Request Received From: %@ Type: %@",[presence fromStr],[presence type]);
}

-(void) xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    NSLog(@"Presence Durumu Geldiiii");
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// A simple example of inbound message handling.
    
	if ([message isChatMessageWithBody])
	{
		XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message from]
                                                                      xmppStream:self.xmppStream
                                                            managedObjectContext:[self getManagedObjectRoster]];
        
		
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        NSString *sentTime = [[message elementForName:@"sendDate"] stringValue];
        
        
        //Alttaki iki satir direk jid stringi aldigimizda gelen sacma karakterleri elemine etmek icindir
        XMPPJID *receipantID = [message to];
        NSString *fullReceipantID = [[receipantID user] stringByAppendingString:@"@"];
        NSString *receipantStr = [fullReceipantID stringByAppendingString:[receipantID domain]];
        
        //Alttaki iki satir direk jid stringi aldigimizda gelen sacma karakterleri elemine etmek icindir
        XMPPJID *messageFrom = [message from];
        NSString *fullJid = [[messageFrom user] stringByAppendingString:@"@"];
        NSString *jidStr = [fullJid stringByAppendingString:[messageFrom domain]];
        
		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                                message:body 
                                                               delegate:nil 
                                                      cancelButtonTitle:@"Ok" 
                                                      otherButtonTitles:nil];
			[alertView show];
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@ At:%@\n\n",displayName,body,sentTime];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
        

        
        XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:body andSendDate:sentTime andMessageReceipant:receipantStr withType:@"chat" includingUserJid:jidStr andUserDisplay:displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:0]];
        
      
        
        if (!messageCoreData) {
            NSLog(@"Gelen Mesaj DB ye Eklenemedi");
        }
        
	}
    
    
}

-(void) xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    NSLog(@"Mesaj Basariyla Gonderildi");
    
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message to]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self getManagedObjectRoster]];
    
    
    //Alttaki iki satir direk jid stringi aldigimizda gelen sacma karakterleri elemine etmek icindir
    //Burada receive messajin tersi uygulanir fromdaki kisi biz to daki kisi ise alicidir
    XMPPJID *receivingID = [message to];
    NSString *receiverName =[[receivingID user] stringByAppendingString:@"@"];
    NSString *receiverStr = [receiverName stringByAppendingString:[receivingID domain]];
    
    
    NSString *body = [[message elementForName:@"body"] stringValue];
    NSString *sentTime = [[message elementForName:@"sendDate"] stringValue];
    
    XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:body andSendDate:sentTime andMessageReceipant:self.username withType:@"chat" includingUserJid:receiverStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:1]];
    
    
    if (!messageCoreData) {
        NSLog(@"Gonderilen Mesaj DB Ye Eklenemedi");
    }
    
}

@end
