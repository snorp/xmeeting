/*
 * $Id: XMAddressBookManager.h,v 1.8 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_MANAGER_H__
#define __XM_ADDRESS_BOOK_MANAGER_H__

#import <Foundation/Foundation.h>
#import "XMeeting.h"

extern NSString *XMNotification_AddressBookManagerDidChangeDatabase;

/**
 * These properties are registered in the AddressBook database and
 * can be used to query the AddressBook database directly.
 * (type is kABStringProperty for the HumanReadableCallAddress
 * and kABDataProperty for the CallAddress property)
 **/
extern NSString *XMAddressBookProperty_CallAddress;
extern NSString *XMAddressBookProperty_HumanReadableCallAddress;

/**
 * Needed for backwards compatibility. Unfortunately, the AddressBook
 * API doesn't allow to change the type of a property once the property
 * has been added to the AddressBook. This means that it is not possible
 * to change the properties defined for v0.1 into multivalue properties.
 * Removing properties from the addres book isn't implemented yet, and
 * there is no way to run a script that does this.
 * That means that the AddressBook gets filled up with lots of unused
 * properties related to XMeeting
 **/
extern NSString *XMAddressBookProperty_CallAddress_0_1;
extern NSString *XMAddressBookProperty_HumanReadableCallAddress_0_1;

@class ABAddressBook, ABPerson, XMAddressBookRecord;

@protocol XMAddressBookRecord;

/**
 * XMAddressBookManager encapsulates functionality useful for dealing with
 * Apple's AddressBook database records in the context of the XMeeting framework.
 *
 * This header provides functions to extract useful information from ABPerson
 * records or creating new records and adding them to the AddressBook database.
 * In addition, the search function enables to do a comprehensive search for
 * valid records in the context of the XMeeting framework.
 * A record is considered valid in the context of the XMeeting framework if it
 * contains an XMAddressResource property. Only in this case is the XMeeting framework able
 * to call this person.
 *
 * When searching the AddressBook database, the firstName, lastName, organizationName
 * and addressResource properties are searched for matches. Other properties such as phoneNumbers
 * are not searched
 **/
@interface XMAddressBookManager : NSObject {
  
@private
  ABAddressBook *addressBook;
}

+ (XMAddressBookManager *)sharedInstance;

/**
 * Returns all records in the AddressBook database which have a
 * call address set and are therefore valid in the context of the
 * XMeeting framework. If a person has multiple address records stored,
 * each record is contained once in the array
 **/
- (NSArray *)records;

/**
 * Creates a new person record initialized with the parameters as specified and returns it
 * This does NOT add the record to the database, use -addRecord: to do so. All string
 * values may be nil, but at least one value should not be nil.
 **/
- (ABPerson *)createPersonWithFirstName:(NSString *)firstName lastName:(NSString *)lastName
                            companyName:(NSString *)companyName isCompany:(BOOL)isCompany;

/**
 * Adds the person record created by -createPersonWithFirstName... 
 * to the AddressBook database. Returns whether this action is succesful or not.
 * Does nothing if the person is already contained in the database
 **/
- (BOOL)addPerson:(ABPerson *)person;

/**
 * Adds the record to the AddressBook database. Returns whether this action is 
 * succesful or not.
 * Does nothing if the record is already contained in the database.
 **/
- (BOOL)addRecord:(XMAddressBookRecord *)record;

/**
 * Returns the address book record belonging to the person specified and having the
 * identifier specified. The identifier is of type like the ones used by ABMultiValue
 * instances to identify the data records. The identifier is checked with the identifiers
 * contained by the multi value stored with the XMAddressBookProperty_HumanReadableCallAddress
 * property, if isPhoneNumber is NO. If isPhoneNumber is YES, the identifier is checked
 * with the identifiers contained in the multi value stored with the kABPhoneProperty.
 * if identifier is nil, a new record is created which is marked as needing to be added
 * to the person as soon as a call adress was set. This only works when isPhoneNumber is NO.
 **/
- (XMAddressBookRecord *)recordForPerson:(ABPerson *)person identifier:(NSString *)identifier
                           isPhoneNumber:(BOOL)isPhoneNumber;

/**
 * Sets the primary identifier for the person specified
 **/
- (void)setPrimaryAddressForPerson:(ABPerson *)person withIdentifier:(NSString *)identifier;

/**
 * Searches the AddressBook database and returns all records matching
 * the searchString.
 **/
- (NSArray *)recordsMatchingString:(NSString *)searchString;

/**
 * Returns the record that matches callAddress, or nil if no record matches callAddress.
 * If multiple records have a match on callAddress, it isn't defined which record
 * is returned.
 **/
- (XMAddressBookRecord *)recordWithCallAddress:(NSString *)callAddress;

/**
 * Returns an array containing all records that belong to the same person as the
 * record given.
 * On return, indexOfRecord contains the index of the record specified
 **/
- (NSArray *)recordsForPersonWithRecord:(XMAddressBookRecord *)record indexOfRecord:(unsigned *)indexOfRecord;

@end

#endif // __XM_ADDRESS_BOOK_MANAGER_H_-
