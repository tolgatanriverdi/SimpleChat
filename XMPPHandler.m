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

#import "FtpHandler.h"


//TODO Gercek resim database e kaydedildikten sonra klasorden silinecek

@interface XMPPHandler()<FtpHandlerDelegate>


@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property BOOL 	allowSelfSignedCertificates;
@property BOOL allowSSLHostNameMismatch;

@property (nonatomic,strong)NSManagedObjectContext *managedObjectContext_roster;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext_capabilities;
@property (nonatomic,strong) UIManagedDocument *messageDocument;

@property (nonatomic,strong) NSString *sendingFilePath;
@property (nonatomic,strong) FtpHandler *ftpHandler;

-(NSString*) getActualFileNameFromThumbnail:(NSString*)thumbnailFileName;

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

@synthesize sendingFilePath = _sendingFilePath;

@synthesize ftpHandler = _ftpHandler;

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
    
    self.allowSelfSignedCertificates = YES;
	self.allowSSLHostNameMismatch = YES;
    
    [self getmanagedObjectMessage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goOnline) name:@"saveStatus" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageIsSending:) name:@"messageSent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileIsSending:) name:@"fileSent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coordIsSending:) name:@"coordSent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaIsDownloading:) name:@"downloadMedia" object:nil];
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
    _ftpHandler = [[FtpHandler alloc] init];
    [_ftpHandler setDelegate:self];
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

-(XMPPJID *) getMyJid
{
    return [self.xmppStream myJID];
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
    XMPPMessage *newMessage = [[XMPPMessage alloc] initWithType:type to:toJid];
    [newMessage addBodyToMessage:messageBody];
    
    [self.xmppStream sendElement:newMessage];
}

-(void) messageIsSending:(NSNotification*)notification
{
    NSDictionary *messageContent = [notification userInfo];
    [self sendMessage:[messageContent valueForKey:@"body"] toAdress:[messageContent valueForKey:@"to"] withType:[messageContent valueForKey:@"type"]];
}

-(void) sendCoordinateMessage:(double)lattitude andLongitude:(double)longitude toUser:(NSString*)to
{
    XMPPJID *toJid = [XMPPJID jidWithString:to];
    XMPPMessage *newMessage = [[XMPPMessage alloc] initWithType:@"coordinate" to:toJid];
    [newMessage addLattitude:lattitude andLongitude:longitude];
    [self.xmppStream sendElement:newMessage];
}

-(void) coordIsSending:(NSNotification*)notification
{
    NSDictionary *coordContent = [notification userInfo];
    [self sendCoordinateMessage:[[coordContent valueForKey:@"lat"] doubleValue] andLongitude:[[coordContent valueForKey:@"lon"] doubleValue] toUser:[coordContent valueForKey:@"toUser"]];
    
}

-(void) sendFileMessage:(NSString*)thumbnailUrl withActualData:(NSString*)actualDataUrl toAdress:(XMPPJID*)toUser withType:(NSString*)type
{
    XMPPMessage *newMessage = [[XMPPMessage alloc] initWithType:type to:toUser];
    [newMessage addThumbNailPath:thumbnailUrl];
    [newMessage addDataPath:actualDataUrl];
    
    [self.xmppStream sendElement:newMessage];
}

-(void) transferFile:(NSString *)filePath fromUser:(XMPPJID *)userJid toUser:(NSString *)toUserJid withType:(NSString*)type
{
    //NSLog(@"Transfering File ");
    
    if (type == @"audio") {  //Audio da thumbnail transfer edilmedigi icin direk db ye yaziliyor
        
        XMPPJID *toJid = [XMPPJID jidWithString:toUserJid];
        XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:toJid
                                                                      xmppStream:self.xmppStream
                                                            managedObjectContext:[self getManagedObjectRoster]];
        
        NSDate* currentTime = [NSDate date];
        NSString *thumbnailPath = [[NSBundle mainBundle] pathForResource:@"mic" ofType:@"png"];
        NSData *thumbnailData = [NSData dataWithContentsOfFile:thumbnailPath];
        
        XMPPMessageCoreDataObject *messageObj = [XMPPMessageCoreDataObject insertMessageWithBody:filePath andSendDate:[currentTime description] andMessageReceipant:self.username withType:@"audio" withThumbnail:thumbnailData withActualData:nil includingUserJid:user.jidStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:1]];
            
        if (messageObj) {
            NSLog(@"Audio Mesaji DB Ye Yazilamadi");
        }
            
        
    }
    
    self.sendingFilePath = filePath;
    NSString *remotePath = [NSString stringWithFormat:@"%@-%@",[userJid bare],[userJid resource]];
    
    [self.ftpHandler uploadFile:self.sendingFilePath withFolder:remotePath withType:type toUser:toUserJid];
}

-(void) fileIsSending:(NSNotification*)notification
{
    NSDictionary *fileContent = [notification userInfo];
    [self transferFile:[fileContent valueForKey:@"filePath"] fromUser:[fileContent valueForKey:@"fromUserJid"] toUser:[fileContent valueForKey:@"toUserJid"] withType:[fileContent valueForKey:@"type"]];
}

-(void) mediaIsDownloading:(NSNotification*)notification
{
    NSDictionary *mediaContent = [notification userInfo];
    if ([[mediaContent objectForKey:@"type"] isEqualToString:@"image"]) {
        NSString *thumbnailFileName = [mediaContent objectForKey:@"thumbnailFileName"];
        NSString *fromUser = [mediaContent objectForKey:@"fromUser"];
        NSString *remoteThumbFile = [self.ftpHandler getRemoteFileName:thumbnailFileName];
        NSString *actualRemoteImage = [self getActualFileNameFromThumbnail:remoteThumbFile];
        NSString *localDir = [NSString stringWithFormat:@"%@-%@",fromUser,self.username];
        
        [self.ftpHandler downloadFile:actualRemoteImage inFolder:localDir withType:@"image" fromUser:fromUser];
    } else if ([[mediaContent objectForKey:@"type"] isEqualToString:@"audio"]) {
        NSLog(@"Downloading Audioo");
        NSString *fileName = [mediaContent objectForKey:@"fileName"];
        NSString *fromUser = [mediaContent objectForKey:@"fromUser"];
        NSString *remoteFileName = [self.ftpHandler getRemoteFileName:fileName];
        NSString *localDir = [NSString stringWithFormat:@"%@-%@",fromUser,self.username];
        
        [self.ftpHandler downloadFile:remoteFileName inFolder:localDir withType:@"audio" fromUser:fromUser];
    }
    
}


////////////////////////////////////
/////XMPP STREAM DELEGATES/////////
//////////////////////////////////
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
    NSLog(@"ISConnection Secured %d",sender.isSecure);
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
    
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message from]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self getManagedObjectRoster]];
    
    NSDate *currentTime = [NSDate date];
    
    
	if ([message isChatMessageWithBody])
	{
        NSLog(@"Chat Message Geldi");
        
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        NSString *sentTime = [currentTime description];
        
        
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
            /*
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
                                                                message:body 
                                                               delegate:nil 
                                                      cancelButtonTitle:@"Ok" 
                                                      otherButtonTitles:nil];
			[alertView show];
             */
		}
		else
		{
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@ At:%@\n\n",displayName,body,sentTime];
            
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
        

        
        XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:body andSendDate:sentTime andMessageReceipant:receipantStr withType:@"chat" withThumbnail:nil withActualData:nil includingUserJid:jidStr andUserDisplay:displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:0]];
        
      
        
        if (!messageCoreData) {
            NSLog(@"Gelen Mesaj DB ye Eklenemedi");
        }
        
	}
    else if ([message isImageMessage]) 
    {
        
        NSString *thumbnailPath = [[message elementForName:@"thumbnail"] stringValue];
        NSString *actualDataPath = [[message elementForName:@"actualData"] stringValue];
        NSLog(@"Image Message Geldi Thumbnail: %@  ActualData: %@",thumbnailPath,actualDataPath);
        
        if (thumbnailPath && actualDataPath) 
        {
            NSString *localDir = [NSString stringWithFormat:@"%@-%@",user.jidStr,self.username];
            [self.ftpHandler downloadFile:thumbnailPath inFolder:localDir withType:@"thumbnail" fromUser:user.jidStr];
        }
        
    }
    else if ([message isAudioMessage])
    {
        NSString *actualDataPath = [[message elementForName:@"actualData"] stringValue];
        //NSLog(@"Audio Message Geldi ActualDataPath: %@",actualDataPath);
        
        if (actualDataPath) {
            
            //Gelen datayi local olarak nereye koyacagini ayarlar
            NSString *localDir = [NSString stringWithFormat:@"%@-%@",user.jidStr,self.username];
            NSString *fileName = [actualDataPath lastPathComponent];
            NSArray *documentsTmpPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [documentsTmpPath objectAtIndex:0];
            NSString *outputDirPath = [documentsPath stringByAppendingPathComponent:localDir];
            NSString *fullLocalPath = [outputDirPath stringByAppendingPathComponent:fileName];
            [self.ftpHandler addLocalFile:fullLocalPath forRemoteFile:actualDataPath];
            
            //Gelen dataya uygun thumbnaili ayarlar
            NSString *thumbnailPath = [[NSBundle mainBundle] pathForResource:@"mic" ofType:@"png"];
            NSData *thumbnailData = [NSData dataWithContentsOfFile:thumbnailPath];
            NSString *recipantStr = [[message to] bare];
            NSString *fromJidStr = [[message from] bare];
            
            //Gelen data ile ilgili bilgiyi database e yazar
            XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:fullLocalPath andSendDate:[currentTime description] andMessageReceipant:recipantStr withType:@"audio" withThumbnail:thumbnailData withActualData:nil includingUserJid:fromJidStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:0]];
            
            if (!messageCoreData) {
                NSLog(@"Gelen Audio Mesaj DB ye Eklenemedi");
            }
            
        }
    }
    else if ([message isCoordMessage])
    {
        NSLog(@"Coordinate Mesaj Geldi");
        NSString *latStr = [[message elementForName:@"lattitude"] stringValue];
        NSString *lonStr = [[message elementForName:@"longitude"] stringValue];
        NSString *messageStr = [latStr stringByAppendingFormat:@",%@",lonStr];
        NSString *recipantStr = [[message to] bare];
        NSString *fromJidStr = [[message from] bare];
        
        NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"googlemaps" ofType:@"png"];
        NSData *iconData = [NSData dataWithContentsOfFile:iconPath];
        
        XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:messageStr andSendDate:[currentTime description] andMessageReceipant:recipantStr withType:@"coordinate" withThumbnail:iconData withActualData:nil includingUserJid:fromJidStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:0]];
        
        if (!messageCoreData) {
            NSLog(@"Gelen Coordinate Mesaj DB ye Eklenemedi");
        }
        
    }
    
        NSLog(@"Message Received From: %@",[[message from] full]);
    
}

-(void) xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    NSLog(@"Mesaj Basariyla Gonderildi");
    
    XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:[message to]
                                                                  xmppStream:self.xmppStream
                                                        managedObjectContext:[self getManagedObjectRoster]];
    
    NSDate *currentTime = [NSDate date];
    NSString *sentTime = [currentTime description];
    
    
    if ([message isChatMessage]) {
        
        
        //Alttaki iki satir direk jid stringi aldigimizda gelen sacma karakterleri elemine etmek icindir
        //Burada receive messajin tersi uygulanir fromdaki kisi biz to daki kisi ise alicidir
        XMPPJID *receivingID = [message to];
        NSString *receiverName =[[receivingID user] stringByAppendingString:@"@"];
        NSString *receiverStr = [receiverName stringByAppendingString:[receivingID domain]];
        
        
        NSString *body = [[message elementForName:@"body"] stringValue];
        
        XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:body andSendDate:sentTime andMessageReceipant:self.username withType:@"chat" withThumbnail:nil withActualData:nil includingUserJid:receiverStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:1]];
        
        
        if (!messageCoreData) {
            NSLog(@"Gonderilen Mesaj DB Ye Eklenemedi");
        }
        
    }
    else if ([message isCoordMessage]) {
        
        NSString *latStr = [[message elementForName:@"lattitude"] stringValue];
        NSString *lonStr = [[message elementForName:@"longitude"] stringValue];
        NSString *messageStr = [latStr stringByAppendingFormat:@",%@",lonStr];
        
        NSString *iconPath = [[NSBundle mainBundle] pathForResource:@"googlemaps" ofType:@"png"];
        NSData *iconData = [NSData dataWithContentsOfFile:iconPath];
        
        XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:messageStr andSendDate:sentTime andMessageReceipant:self.username withType:@"coordinate" withThumbnail:iconData withActualData:nil includingUserJid:user.jidStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:1]];
        
        if (!messageCoreData) {
            NSLog(@"Gonderilen Coord Mesaj DB Ye Eklenemedi");
        }
        
    }

}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	//DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
    NSLog(@"Secure Baglanti Kuruluyor");
    
	if (self.allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (self.allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = self.xmppStream.hostName;
		NSString *virtualDomain = [self.xmppStream.myJID domain];
        
		
		if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}


////FILE OPERATIONS////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

-(NSString*) getActualFileNameFromThumbnail:(NSString *)thumbnailFileName
{
    NSString *result;
    
    NSString *withoutExt = [thumbnailFileName substringToIndex:[thumbnailFileName length]-14];
    result = [withoutExt stringByAppendingString:@".png"];
    
    return result;
}

-(NSString*) getThumbnailFileNameFromFileName:(NSString*)fileName {
    NSString *result;
    

    NSString *withoutExt = [fileName substringToIndex:[fileName length]-4];
    result = [withoutExt stringByAppendingString:@"_thumbnail.png"];
    
    return result;
}

-(void) insertActualDataToDownloadedMessage:(NSString*)bodyMessage actualFileName:(NSString*)fileName andUsername:(NSString*)username
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageCoreDataObject"];
    request.predicate = [NSPredicate predicateWithFormat:@"body = %@ AND whoOwns.jidStr = %@",bodyMessage,username];
    
    NSError *error;
    NSArray *matches = [self.getmanagedObjectMessage executeFetchRequest:request error:&error];
    
    if ([matches count] > 0) {
        XMPPMessageCoreDataObject *messageCoreData = [matches lastObject];
        messageCoreData.actualData = [NSData dataWithContentsOfFile:fileName];
        
        NSLog(@"Gercek Data Kayida Eklendi");
    }
    
}

-(void) insertActualDataToUploadedMessage:(NSString*)bodyMessage withActualLocalFile:(NSString*)localFileName andActualRemoteFile:(NSString*)remoteFileName includingRemoteThumb:(NSString*)remoteThumb toUserName:(NSString*)toUser andType:(NSString*)type
{
    XMPPJID *toUserJid = [XMPPJID jidWithString:toUser];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageCoreDataObject"];
    request.predicate = [NSPredicate predicateWithFormat:@"body = %@ AND whoOwns.jidStr = %@",bodyMessage,toUser];
    //NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    //request.sortDescriptors = [NSArray arrayWithObject:sortDesc];
    
    NSError *error;
    NSArray *matches = [self.getmanagedObjectMessage executeFetchRequest:request error:&error];
    
    if ([matches count] > 0) {
        XMPPMessageCoreDataObject *messageCoreData = [matches lastObject];
        messageCoreData.actualData = [NSData dataWithContentsOfFile:localFileName];
        
        //NSLog(@"Sending Remote Thumbnail: %@",remoteThumb);
        NSLog(@"Sending Remote File: %@",remoteFileName);
        [self sendFileMessage:remoteThumb withActualData:remoteFileName toAdress:toUserJid withType:type];
    }  
}

-(void) ftpUploadStatusChanged:(BOOL)suceed withLocalFileName:(NSString*)fileName andRemoteFileName:(NSString*)remoteFileName andType:(NSString *)type toUser:(NSString *)userId
{
    if (suceed) {
        XMPPJID *toUserName = [XMPPJID jidWithString:userId];
        XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:toUserName
                                                                      xmppStream:self.xmppStream
                                                            managedObjectContext:[self getManagedObjectRoster]];
        NSDate *currentTime = [NSDate date];
        
        if (type == @"thumbnail") 
        {
            if (user) {
                NSData *thumbnailData = [NSData dataWithContentsOfFile:fileName];
                XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:fileName andSendDate:[currentTime description] andMessageReceipant:self.username withType:@"image" withThumbnail:thumbnailData withActualData:nil includingUserJid:user.jidStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:1]];
                
                if (!messageCoreData) {
                    NSLog(@"Gonderilen Thumbnail DB ye Eklenemedi");
                }
                
                //NSLog(@"Length Of Thumbnail: %d",[messageCoreData.thumbnail length]); 
            }
            

        }
        else if (type == @"image") 
        {
            
            NSString *thumb = [self getThumbnailFileNameFromFileName:fileName];
            NSString *remoteThumb = [self getThumbnailFileNameFromFileName:remoteFileName];
           
            /*
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"XMPPMessageCoreDataObject"];
            request.predicate = [NSPredicate predicateWithFormat:@"body = %@ AND whoOwns.jidStr = %@",thumb,user.jidStr];
            //NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
            //request.sortDescriptors = [NSArray arrayWithObject:sortDesc];
            
            NSError *error;
            NSArray *matches = [self.getmanagedObjectMessage executeFetchRequest:request error:&error];
            
            if ([matches count] > 0) {
                XMPPMessageCoreDataObject *messageCoreData = [matches lastObject];
                messageCoreData.actualData = [NSData dataWithContentsOfFile:fileName];
                
                //NSLog(@"Sending Remote Thumbnail: %@",remoteThumb);
                NSLog(@"Sending Remote File: %@",remoteFileName);
                [self sendFileMessage:remoteThumb withActualData:remoteFileName toAdress:toUserName withType:@"image"];
                NSLog(@"Gercek Resim Thumbnailin Oldugu Kayida Eklendi");
            }
             */
            
            [self insertActualDataToUploadedMessage:thumb withActualLocalFile:fileName andActualRemoteFile:remoteFileName includingRemoteThumb:remoteThumb toUserName:user.jidStr andType:@"image"];
            
        }
        else if (type == @"audio") 
        {
            //NSLog(@"Audio File Uploaded");
            [self insertActualDataToUploadedMessage:fileName withActualLocalFile:fileName andActualRemoteFile:remoteFileName includingRemoteThumb:nil toUserName:user.jidStr andType:@"audio"];
        }
        
        
        
        //Buraya upload islemi biten dosyanin silinmesi eklenecek
        
    }
}


-(void) ftpDownloadStatusChanged:(BOOL)suceed withFileName:(NSString *)fileName withType:(NSString *)type fromUser:(NSString *)userId
{
    if (suceed) 
    {
        NSDate *currentTime = [NSDate date];
        XMPPJID *fromUserName = [XMPPJID jidWithString:userId];
        XMPPUserCoreDataStorageObject *user = [self.xmppRosterStorage userForJID:fromUserName
                                                                      xmppStream:self.xmppStream
                                                            managedObjectContext:[self getManagedObjectRoster]];
        
        
        if (user) 
        {
            
            if (type == @"thumbnail") 
            {
                NSLog(@"Thumbnail Received: %@",fileName);
                NSData *thumbnailData = [NSData dataWithContentsOfFile:fileName];
                XMPPMessageCoreDataObject *messageCoreData = [XMPPMessageCoreDataObject insertMessageWithBody:fileName andSendDate:[currentTime description] andMessageReceipant:self.username withType:@"image" withThumbnail:thumbnailData withActualData:nil includingUserJid:user.jidStr andUserDisplay:user.displayName inManagedObjectContext:[self getmanagedObjectMessage] withSelfRepliedStatus:[NSNumber numberWithInt:0]];
                
                if (!messageCoreData) {
                    NSLog(@"Gonderilen Mesaj DB ye Eklenemedi");
                }
                
                
            } 
            else if(type == @"image") 
            {
                
                NSString *thumb = [self getThumbnailFileNameFromFileName:fileName];
                //NSLog(@"Thumbnail For The Image Is: %@",thumb);
                NSLog(@"Actual ImageReceived: %@",fileName);
                [self insertActualDataToDownloadedMessage:thumb actualFileName:fileName andUsername:user.jidStr];
            }
            else if (type == @"audio")
            {
                NSLog(@"Actual AudioReceived:%@",fileName);
                [self insertActualDataToDownloadedMessage:fileName actualFileName:fileName andUsername:user.jidStr];
               
            }
                
        }
        
    }
}


/////////////////////////////////////////////
////////////////////////////////////////////

@end
