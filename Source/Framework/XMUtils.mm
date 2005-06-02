/*
 * $Id: XMUtils.mm,v 1.3 2005/06/02 08:23:16 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMUtils.h"

NSString *XMNotification_DidStartFetchingExternalAddress = @"XMeeting_DidStartFetchingExternalAddressNotification";
NSString *XMNotification_DidEndFetchingExternalAddress = @"XMeeting_DidEndFetchingExternalAddressNotification";

@interface XMUtils (PrivateMethods)

- (id)_init;

@end

@implementation XMUtils

#pragma mark Class Methods

+ (XMUtils *)sharedInstance
{
	static XMUtils *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMUtils alloc] _init];
	}
	return sharedInstance;
}

+ (BOOL)isPhoneNumber:(NSString *)str
{
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789 ()+-"];
	NSScanner *scanner = [[NSScanner alloc] initWithString:str];
	BOOL result = NO;
	
	if([scanner scanCharactersFromSet:charSet intoString:nil] && [scanner isAtEnd])
	{
		result = YES;
	}
	
	[scanner release];
	
	return result;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_init
{
	isFetchingExternalAddress = NO;
	didSucceedFetchingExternalAddress = YES;
	externalAddress = nil;
	externalAddressFetchFailReason = nil;
}

- (void)dealloc
{
	[fetchingURL release];
	[externalAddress release];
	[externalAddressFetchFailReason release];
	
	[super dealloc];
}

#pragma mark Fetching External Address

- (void)startFetchingExternalAddress
{
	if(isFetchingExternalAddress == NO)
	{
		fetchingURL = [[NSURL alloc] initWithString:@"http://checkip.dyndns.org"];
		[fetchingURL loadResourceDataNotifyingClient:self usingCache:NO];
		isFetchingExternalAddress = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidStartFetchingExternalAddress object:self];
	}
}

- (BOOL)didSucceedFetchingExternalAddress
{
	return didSucceedFetchingExternalAddress;
}

- (NSString *)externalAddress
{
	return externalAddress;
}

- (NSString *)externalAddressFetchFailReason
{
	return externalAddressFetchFailReason;
}

#pragma mark NSURLClient Methods

- (void)URLResourceDidFinishLoading:(NSURL *)sender
{
	if(sender != fetchingURL)
	{
		return;
	}
	
	[externalAddress release];
	externalAddress = nil;
	[externalAddressFetchFailReason release];
	externalAddressFetchFailReason = nil;
	
	NSData *data = [fetchingURL resourceDataUsingCache:YES];
	if(data != nil)
	{
		// parsing the data for the address string
		NSCharacterSet *ipCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
		NSString *urlDataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		NSString *addressString;
		NSScanner *scanner = [[NSScanner alloc] initWithString:urlDataString];
		if([scanner scanUpToCharactersFromSet:ipCharacters intoString:nil] &&
		   [scanner scanCharactersFromSet:ipCharacters intoString:&addressString])
		{
			externalAddress = [addressString retain];
			didSucceedFetchingExternalAddress = YES;
		}
		else
		{
			NSString *failReason = @"Invalid address returned";
			externalAddressFetchFailReason = [failReason retain];
			didSucceedFetchingExternalAddress = NO;
		}
		
		[scanner release];
		[urlDataString release];
	}
	else
	{
		didSucceedFetchingExternalAddress = NO;
	}
	
	[fetchingURL release];
	fetchingURL = nil;
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidEndFetchingExternalAddress object:self];
}

- (void)URLResourceDidCancelLoading:(NSURL *)sender
{
	[fetchingURL release];
	fetchingURL = nil;
	isFetchingExternalAddress = NO;
	didSucceedFetchingExternalAddress = NO;
	[externalAddress release];
	externalAddress = nil;
	[externalAddressFetchFailReason release];
	NSString *failReason = @"Resource loading cancelled";
	externalAddressFetchFailReason = [failReason retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidEndFetchingExternalAddress object:self];
}

- (void)URL:(NSURL *)sender resourceDataDidBecomeAvailable:(NSData *)newBytes
{
	// just ignoring
}

- (void)URL:(NSURL *)sender resourceDidFailLoadingWithReason:(NSString *)reason
{
	[fetchingURL release];
	fetchingURL = nil;
	isFetchingExternalAddress = NO;
	didSucceedFetchingExternalAddress = NO;
	[externalAddress release];
	externalAddress = nil;
	[externalAddressFetchFailReason release];
	externalAddressFetchFailReason = [reason retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidEndFetchingExternalAddress object:self];
}

@end
