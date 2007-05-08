/*
 * $Id: XMSimpleAddressResource.m,v 1.4 2007/05/08 15:18:40 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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

@implementation XMSimpleAddressResourceWrapper

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)initWithAddressResource:(XMAddressResource *)_addressResource
{
    self = [super init];
    
    addressResource = [_addressResource retain];
    
    return self;
}

- (void)dealloc
{
    [addressResource release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark XMCallAddress methods

- (id<XMCallAddressProvider>)provider
{
    return nil;
}

- (XMAddressResource *)addressResource
{
    return addressResource;
}

- (NSString *)displayString
{
    return [addressResource address];
}

- (NSImage *)displayImage
{
    return nil;
}

@end
