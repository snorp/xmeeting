/*
 * $Id: XMSimpleAddressResource.m,v 1.3 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMSimpleAddressResource.h"


@implementation XMSimpleAddressResource

#pragma mark Init & Deallocation Methods

- (id)initWithAddress:(NSString *)theAddress callProtocol:(XMCallProtocol)theCallProtocol
{
	address = [theAddress copy];
	
	callProtocol = theCallProtocol;
	
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
	return callProtocol;
}

- (void)setCallProtocol:(XMCallProtocol)theCallProtocol
{
	callProtocol = theCallProtocol;
}

- (NSString *)humanReadableAddress
{
	return [self address];
}

@end
