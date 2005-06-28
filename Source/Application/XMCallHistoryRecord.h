/*
 * $Id: XMCallHistoryRecord.h,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_HISTORY_RECORD_H__
#define __XM_CALL_HISTORY_RECORD_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMSimpleAddressURL.h"

/**
 * GeneralRecord defines a record nowhere else present
 * AddressBookRecord defines a record stored in AddressBook.
 **/
typedef enum XMCallHistoryRecordType
{
	XMCallHistoryRecordType_GeneralRecord = 0,
	XMCallHistoryRecordType_AddressBookRecord,
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
 * of the remote party as well, and we want to be able to
 * store this information as well.
 **/
@interface XMCallHistoryRecord : XMSimpleAddressURL {
	
	NSString *displayString;
	id addressBookRecord;
	XMCallHistoryRecordType type;

}

- (id)initWithAddress:(NSString *)address displayString:(NSString *)displayString;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (XMCallHistoryRecordType)type;

@end

#endif // __XM_CALL_HISTORY_RECORD_H__
