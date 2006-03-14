/*
 * $Id: XMAddressBookRecordSearchMatch.m,v 1.3 2006/03/14 22:44:38 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMAddressBookRecordSearchMatch.h"

#import <AddressBook/AddressBook.h>
#import "XMAddressBookManager.h"
#import "XMAddressBookCallAddressProvider.h"

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

- (id<XMCallAddressProvider>)provider
{
	return [XMAddressBookCallAddressProvider sharedInstance];
}

- (XMAddressResource *)addressResource
{
	return (XMAddressResource *)[[self record] callAddress];
}

- (NSString *)displayString
{
	return [[self record] displayName];
}

- (NSImage *)displayImage
{
	return [NSImage imageNamed:@"AddressBook"];
}

@end
