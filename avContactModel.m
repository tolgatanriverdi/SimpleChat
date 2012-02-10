//
//  avContactModel.m
//  av
//
//  Created by Utku ALTINKAYA on 11/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "avContactModel.h"
#import "addressbook/ABAddressBook.h"
#import "addressbook/ABPerson.h"
#import "addressbook/ABMultiValue.h"

@implementation avContactModel

@synthesize lastName = _lastName;
@synthesize firstName = _firstName;
@synthesize emailAddresses = _emailAddresses;
@synthesize phoneNumbers = _phoneNumbers;
@synthesize isAvatarUser = _isAvatarUser;
@synthesize abId = _abId;
@synthesize fullName = _fullName;


-(NSString *)fullName
{
    return [NSString stringWithFormat:@"%@ %@", _firstName, _lastName];
}

-(BOOL)isAvatarUser
{
    return YES;
}

+(avContactModel*) contactFromRecord: (ABRecordRef) rec
{
    avContactModel* person = [[avContactModel alloc] init];
    NSString* name = (__bridge_transfer NSString*)ABRecordCopyValue(rec, kABPersonFirstNameProperty);
    NSString* lastName = (__bridge_transfer NSString*)ABRecordCopyValue(rec, kABPersonLastNameProperty);
    ABMultiValueRef emails = ABRecordCopyValue(rec, kABPersonEmailProperty);
    ABMultiValueRef phones = ABRecordCopyValue(rec, kABPersonPhoneProperty);
    
    person.abId = ABRecordGetRecordID(rec);
    
    NSMutableArray* emailList = [NSMutableArray array];        
    NSMutableArray* phoneList = [NSMutableArray array];
    
    for (int i=0; i<ABMultiValueGetCount(emails); i++) {
        NSString* email = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(emails, i);
        [emailList addObject:email];
    }
    
    for (int i=0; i<ABMultiValueGetCount(phones); i++) {
        NSString *phoneNo = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phones, i);
        [phoneList addObject:phoneNo];
    }
    
    person.emailAddresses = emailList;
    person.phoneNumbers = phoneList;
    
    if (!name && lastName) {
        name = lastName;
        lastName = nil;
    }
    
    person.firstName = name;
    person.lastName = lastName;   
    return person;
}

+(NSArray*) all
{
    NSMutableArray* contactList = [NSMutableArray array];

    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                               kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people
                                                               );    
    
    CFArraySortValues(
                      peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void*) ABPersonGetSortOrdering()
                      );
    
    for (int i=0; i<CFArrayGetCount(people); i++) {
        ABRecordRef rec = CFArrayGetValueAtIndex(people, i);        
        avContactModel* person = [self contactFromRecord:rec];
        [contactList addObject: person];
    }    
    CFRelease(addressBook);
    CFRelease(people);
    CFRelease(peopleMutable);
    
    return contactList;    
}
@end
