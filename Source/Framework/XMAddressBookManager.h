/*
 * $Id: XMAddressBookManager.h,v 1.4 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_MANAGER_H__
#define __XM_ADDRESS_BOOK_MANAGER_H__

#import <Cocoa/Cocoa.h>
#import "XMTypes.h"

@class ABAddressBook, ABSearchElement, XMURL;

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
 * contains an XMURL property. Only in this case is the XMeeting framework able
 * to call this person.
 *
 * When searching the AddressBook database, the firstName, lastName, organizationName
 * and callURL properties are searched for matches. Other properties such as phoneNumbers
 * are not searched
 **/
@interface XMAddressBookManager : NSObject {
	
	ABAddressBook *addressBook;
}

+ (XMAddressBookManager *)sharedInstance;

/**
 * Returns all records in the AddressBook database, even if they
 * are not valid, e.g do not have any call URL set.
 */
- (NSArray *)records;

/**
 * Returns all records in the AddressBook database which have a
 * call URL set and are therefore valid in the context of the
 * XMeeting framework
 **/
- (NSArray *)validRecords;

/**
 * Creates a new record initialized with the parameters as specified and returns it
 * This does NOT add the record to the database, use -addRecord: to do so. All string/url
 * values may be nil, but at least one value should not be nil.
 **/
- (id)createRecordWithFirstName:(NSString *)firstName lastName:(NSString *)lastName
					companyName:(NSString *)companyName isCompany:(BOOL)isCompany
						callURL:(XMURL *)callURL;

/**
 * Adds the record to the AddressBook database. Returns whether this action
 * is succesful or not
 **/
- (BOOL)addRecord:(id)record;

/**
 * Searches the AddressBook database and returns all records matching
 * the searchString. if mustBeValid is YES, this method does check whether
 * this record is "valid" and can be used in the context of the XMeeting framework.
 * If returnExtraInformation is YES, the objects contained in the array
 * are instances of XMAddressBookRecordSearchMatch.
 **/
- (NSArray *)recordsMatchingString:(NSString *)searchString mustBeValid:(BOOL)mustBeValid
			  returnExtraInformation:(BOOL)returnExtraInformation;

/**
 * Returns the record that matches callAddress, or nil if
 * no record matches callAddress. If multiple records have
 * a match on callAddress, it isn't defined which record
 * is returned.
 **/
- (id<XMAddressBookRecord>)recordWithCallAddress:(NSString *)callAddress;

@end

/**
 * This protocol declares which methods the address book record instances
 * do respond to.
 **/
@protocol XMAddressBookRecord <NSObject>

/**
 * Returns whether the record is valid in the context of the
 * XMeeting framework or not
 **/
- (BOOL)isValid;

/**
 * Returns some properties of the record
 **/
- (NSString *)firstName;
- (NSString *)lastName;
- (NSString *)companyName;
- (BOOL)isCompany;
- (XMURL *)callURL;

/**
 * This is the only property that can be changed
 * by the XMeeting framework.
 **/
- (void)setCallURL:(XMURL *)callURL;

/**
 * Returns a more human readable representation of the record's
 * call address
 **/
- (NSString *)humanReadableCallURLRepresentation;

/**
 * Returns a string useful for Display. This string takes
 * into account whether the record is a person or a company
 * and what the name ordering mask is.
 **/
- (NSString *)displayName;

@end

#endif // __XM_ADDRESS_BOOK_MANAGER_H_-
