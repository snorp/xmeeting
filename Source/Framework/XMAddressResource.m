/*
 * $Id: XMAddressResource.m,v 1.3 2007/05/08 15:17:46 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMAddressResource.h"

#import "XMGeneralPurposeAddressResource.h"
#import "XMH323URL.h"
#import "XMSIPURL.h"

@implementation XMAddressResource

#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)stringRepresentation
{
	if([XMGeneralPurposeAddressResource canHandleStringRepresentation:stringRepresentation] ||
       [XMH323URL canHandleStringRepresentation:stringRepresentation] ||
       [XMSIPURL canHandleStringRepresentation:stringRepresentation])
	{
		return YES;
	}
	return NO;
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dictionaryRepresentation
{
	if([XMGeneralPurposeAddressResource canHandleDictionaryRepresentation:dictionaryRepresentation] ||
       [XMH323URL canHandleDictionaryRepresentation:dictionaryRepresentation] ||
       [XMSIPURL canHandleDictionaryRepresentation:dictionaryRepresentation])
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
    else if ([XMH323URL canHandleStringRepresentation:stringRepresentation])
    {
        instance = [XMH323URL addressResourceWithStringRepresentation:stringRepresentation];
    }
    else if ([XMSIPURL canHandleStringRepresentation:stringRepresentation])
    {
        instance = [XMSIPURL addressResourceWithStringRepresentation:stringRepresentation];
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
    else if ([XMH323URL canHandleDictionaryRepresentation:dictionaryRepresentation])
    {
        instance = [XMH323URL addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
    }
    else if ([XMSIPURL canHandleDictionaryRepresentation:dictionaryRepresentation])
    {
        instance = [XMSIPURL addressResourceWithDictionaryRepresentation:dictionaryRepresentation];
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
    else if ([XMH323URL canHandleStringRepresentation:stringRepresentation])
    {
        return [[XMH323URL alloc] initWithStringRepresentation:stringRepresentation];
    }
    else if ([XMSIPURL canHandleStringRepresentation:stringRepresentation])
    {
        return [[XMSIPURL alloc] initWithStringRepresentation:stringRepresentation];
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
    else if ([XMH323URL canHandleDictionaryRepresentation:dictionaryRepresentation])
    {
        return [[XMH323URL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
    }
    else if ([XMSIPURL canHandleDictionaryRepresentation:dictionaryRepresentation])
    {
        return [[XMSIPURL alloc] initWithDictionaryRepresentation:dictionaryRepresentation];
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
