//
//  avContactModel.h
//  av
//
//  Created by Utku ALTINKAYA on 11/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface avContactModel : NSObject

@property (nonatomic, strong, readonly) NSString* fullName;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, retain) NSArray* emailAddresses;
@property (nonatomic, retain) NSArray* phoneNumbers;
@property (nonatomic, assign) BOOL isAvatarUser;
@property (nonatomic, assign) int abId;

+(NSArray*) all;

@end
