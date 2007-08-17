/*
 * $Id: XMAddressBookRecord.h,v 1.3 2007/08/17 11:36:40 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_ADDRESS_BOOK_RECORD_H__
#define __XM_ADDRESS_BOOK_RECORD_H__

#import <Cocoa/Cocoa.h>

#import "XMCallAddressManager.h"

typedef enum XMAddressBookRecordPropertyMatch
{
  XMAddressBookRecordPropertyMatch_NoMatch = 0,
  XMAddressBookRecordPropertyMatch_FirstNameMatch,
  XMAddressBookRecordPropertyMatch_LastNameMatch,
  XMAddressBookRecordPropertyMatch_CompanyMatch,
  XMAddressBookRecordPropertyMatch_CallAddressMatch,
  XMAddressBookRecordPropertyMatch_PhoneNumberMatch,
  XMAddressBookRecordPropertyMatchCount
} XMAddressBookRecordPropertyMatch;

@class ABPerson, XMAddressResource;

@interface XMAddressBookRecord : NSObject <XMCallAddress> {

@private
  ABPerson *addressBookPerson;
  unsigned index;
  XMAddressBookRecordPropertyMatch propertyMatch;	
}

- (NSString *)firstName;
- (NSString *)lastName;
- (NSString *)companyName;
- (BOOL)isCompany;
- (XMAddressResource *)callAddress;
- (NSString *)label;

- (void)setCallAddress:(XMAddressResource *)callAddress label:(NSString *)label;

/**
 * Returns a more human readable representation of the record's
 * call address
 **/
- (NSString *)humanReadableCallAddress;

/**
 * Returns a string useful for display. This string takes
 * into account whether the record is a person or a company
 * and what the name ordering mask is.
 **/
- (NSString *)displayName;

/**
 * If this record is returned as a result of a search, this flag
 * indicates which property matched the search
 **/
- (XMAddressBookRecordPropertyMatch)propertyMatch;

@end

#endif // __XM_ADDRESS_BOOK_RECORD_H__