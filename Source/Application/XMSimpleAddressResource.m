/*
 * $Id: XMSimpleAddressResource.m,v 1.1 2005/11/23 19:28:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMSimpleAddressResource.h"


@implementation XMSimpleAddressResource

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

- (XMAddressResource *)addressResource
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

- (NSString *)humanReadableAddress
{
	return [self address];
}

@end
