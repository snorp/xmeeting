/*
 * $Id: XMCallHistoryRecord.h,v 1.4 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_RECORD_H__
#define __XM_CALL_HISTORY_RECORD_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMSimpleAddressResource.h"

/**
 * GeneralRecord defines a record nowhere else present
 * AddressBookRecord defines a record stored in AddressBook.
 **/
typedef enum XMCallHistoryRecordType
{
	XMCallHistoryRecordType_GeneralRecord = 0, // this record has no match in the Address Book
	XMCallHistoryRecordType_AddressBookRecord, // this record has a match in the Address Book
	XMCallHistoryRecordTypeCount
} XMCallHistoryRecordType;

/**
 * This object encapsulates all information required
 * to store information about recent calls made.
 * The problem we have to deal with is the following:
 * A call made may have been done with a record from the
 * AddressBook. This information should be stored as well.
 * However, if the user deleted the AddressBook record
 * in the meantime, we should still be able to call the
 * address, without the AddressBook's name though. In
 * addition, if we are called from someone, we know the name
 * of the remote party, and we want to be able to
 * store this information as well.
 **/
@interface XMCallHistoryRecord : XMSimpleAddressResource {
	
	NSString *displayString;
	id addressBookRecord;
	XMCallHistoryRecordType type;

}

- (id)initWithAddress:(NSString *)address protocol:(XMCallProtocol)callProtocol displayString:(NSString *)displayString;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (XMCallHistoryRecordType)type;

@end

#endif // __XM_CALL_HISTORY_RECORD_H__
