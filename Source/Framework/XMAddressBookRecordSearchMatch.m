/*
 * $Id: XMAddressBookRecordSearchMatch.m,v 1.1 2005/06/28 20:43:46 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <AddressBook/AddressBook.h>

#import "XMAddressBookRecordSearchMatch.h"

@implementation XMAddressBookRecordSearchMatch

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithRecord:(ABPerson *)theRecord propertyMatch:(XMAddressBookRecordPropertyMatch)thePropertyMatch
{
	record = [theRecord retain];
	propertyMatch = thePropertyMatch;
	
	return self;
}

- (void)dealloc
{
	[record release];
	
	[super dealloc];
}

- (id)record
{
	return record;
}

- (XMAddressBookRecordPropertyMatch)propertyMatch
{
	return propertyMatch;
}

@end
