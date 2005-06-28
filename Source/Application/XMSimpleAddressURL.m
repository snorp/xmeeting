/*
 * $Id: XMSimpleAddressURL.m,v 1.1 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMSimpleAddressURL.h"


@implementation XMSimpleAddressURL

#pragma mark Init & Deallocation Methods

- (id)initWithAddress:(NSString *)theAddress
{
	address = [theAddress copy];
	
	return self;
}

- (void)dealloc
{
	[address release];
	
	[super dealloc];
}

#pragma mark Getting & Setting the attributes

- (NSString *)address
{
	return address;
}

- (id<XMCallAddressProvider>)provider
{
	return  nil;
}

- (NSImage *)displayImage
{
	return nil;
}

- (XMURL *)url
{
	return self;
}

- (NSString *)displayString
{
	return [self address];
}

- (XMCallProtocol)callProtocol
{
	return XMCallProtocol_H323;
}

- (NSString *)humanReadableRepresentation
{
	return [self address];
}

@end
