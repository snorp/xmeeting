/*
 * $Id: XMSIPURL.m,v 1.1 2007/05/08 15:17:46 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#import "XMSIPURL.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"

@implementation XMSIPURL

#pragma mark -
#pragma mark Class Methods

+ (BOOL)canHandleStringRepresentation:(NSString *)url
{
	return [url hasPrefix:@"sip:"];
}

+ (BOOL)canHandleDictionaryRepresentation:(NSDictionary *)dict
{
	return NO;
}

+ (XMSIPURL *)addressResourceWithStringRepresentation:(NSString *)url
{
	XMSIPURL *sipURL = [[XMSIPURL alloc] initWithStringRepresentation:url];
    if (sipURL != nil)
    {
        return [sipURL autorelease];
    }
    return nil;
}

+ (XMSIPURL *)addressResourceWithDictionaryRepresentation:(NSDictionary *)dict
{
	return nil;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)initWithStringRepresentation:(NSString *)stringRepresentation
{
    BOOL valid = YES;
    url = [stringRepresentation copy];
    
    if (![stringRepresentation hasPrefix:@"sip:"]) {
        valid = NO;
        goto bail;
    }
    
    address = [stringRepresentation substringFromIndex:4];
    [address retain];
    
    // Do some more validicy checking here!

bail:
    if (valid == NO)
    {
        [self release];
        return nil;
    }

    return self;
}

- (void)dealloc
{
    [url release];
    [address release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSString *)stringRepresentation
{
    return url;
}

- (NSDictionary *)dictionaryRepresentation
{
    return nil;
}

#pragma mark -
#pragma mark XMAddressResource interface

- (XMCallProtocol)callProtocol
{
    return XMCallProtocol_SIP;
}

- (NSString *)address
{
    return address;
}

- (NSString *)humanReadableAddress
{
    return [self address];
}

@end
