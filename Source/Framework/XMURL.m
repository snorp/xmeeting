/*
 * $Id: XMURL.m,v 1.4 2005/06/30 09:33:13 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMURL.h"
#import "XMGeneralPurposeURL.h"
#import "XMCalltoURL.h"

@implementation XMURL

+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation
{
	return NO;
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	if([XMGeneralPurposeURL canHandleDictionaryRepresentation:dictionaryRepresentation])
	{
		return YES;
	}
	return NO;
}

+ (XMURL *)urlWithStringRepresentation:(NSString *)stringRepresentation
{
	XMURL *instance = nil;
	
	return instance;
}

+ (XMURL *)urlWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	XMURL *instance = nil;
	
	if([XMGeneralPurposeURL canHandleDictionaryRepresentation:dictionaryRepresentation])
	{
		instance = [XMGeneralPurposeURL urlWithDictionaryRepresentation:dictionaryRepresentation];
	}
	return instance;
}

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
	
	if([XMGeneralPurposeURL canHandleStringRepresentation:stringRepresentation])
	{
		return [[XMGeneralPurposeURL alloc] initWithStringRepresentation:stringRepresentation];
	}

	return nil;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	// cleanup
	[self release];
	
	if([XMGeneralPurposeURL canHandleDictionaryRepresentation:dictionaryRepresentation])
	{
		return [[XMGeneralPurposeURL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
	}
	
	return nil;
}

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

- (NSString *)humanReadableRepresentation
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
