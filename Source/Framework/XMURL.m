/*
 * $Id: XMURL.m,v 1.1 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMURL.h"
#import "XMCalltoURL.h"

NSString *XMKey_URLType = @"XMeeting_URLType";
NSString *XMKey_URLString = @"XMeeting_URLString";
NSString *XMKey_URLAddress = @"XMeeting_URLAddress";
NSString *XMKey_URLPort = @"XMeeting_URLPort";

@implementation XMURL

+ (BOOL)canHandleString:(NSString *)url
{
	if([XMCalltoURL canHandleString:url])
	{
		return YES;
	}
	return NO;
}

+ (BOOL)canHandleDictionary:(NSDictionary *)dict
{
	if([XMCalltoURL canHandleDictionary:dict])
	{
		return YES;
	}
	return NO;
}

+ (XMURL *)urlWithString:(NSString *)url
{
	XMURL *instance = nil;
	
	if([XMCalltoURL canHandleString:url])
	{
		instance = [XMCalltoURL urlWithString:url];
	}
	return instance;
}

+ (XMURL *)urlWithDictionary:(NSDictionary *)dict
{
	XMURL *instance = nil;
	
	if([XMCalltoURL canHandleDictionary:dict])
	{
		instance = [XMCalltoURL urlWithDictionary:dict];
	}
	return instance;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)initWithString:(NSString *)url
{
	// cleanup
	[self release];
	
	if([XMCalltoURL canHandleString:url])
	{
		return [[XMCalltoURL alloc] initWithString:url];
	}

	return nil;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	// cleanup
	[self release];
	
	if([XMCalltoURL canHandleDictionary:dict])
	{
		return [[XMCalltoURL alloc] initWithDictionary:dict];
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

- (NSString *)address
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (unsigned)port
{
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSString *)humanReadableRepresentation
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
