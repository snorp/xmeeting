/*
 * $Id: XMAddressResource.m,v 1.2 2006/03/14 23:05:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMAddressResource.h"

#import "XMGeneralPurposeAddressResource.h"

@implementation XMAddressResource

#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation
{
	if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation])
	{
		return YES;
	}
	return NO;
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation])
	{
		return YES;
	}
	return NO;
}

+ (XMAddressResource *)addressResourceWithStringRepresentation:(NSString *)stringRepresentation
{
	XMAddressResource *instance = nil;
	
	if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation])
	{
		instance = [XMGeneralPurposeAddressResource addressResourceWithStringRepresentation:stringRepresentation];
	}
	
	return instance;
}

+ (XMAddressResource *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	XMAddressResource *instance = nil;
	
	if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation])
	{
		instance = [XMGeneralPurposeAddressResource addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
	}
	
	return instance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)initWithStringRepresentation:(NSString *)stringRepresentation
{
	// cleanup
	[self release];
	
	if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation])
	{
		return [[XMGeneralPurposeAddressResource alloc] initWithStringRepresentation:stringRepresentation];
	}

	return nil;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	// cleanup
	[self release];
	
	if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation])
	{
		return [[XMGeneralPurposeAddressResource alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
	}
	
	return nil;
}

#pragma mark Public Methods

- (NSString *)stringRepresentation
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSDictionary *)dictionaryRepresentation
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (XMCallProtocol)callProtocol
{
	[self doesNotRecognizeSelector:_cmd];
	return XMCallProtocol_UnknownProtocol;
}

- (NSString *)address
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString *)humanReadableAddress
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
