/*
 * $Id: XMUtils.mm,v 1.4 2005/06/02 12:47:33 hfriederich Exp $
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
	externalAddressURLConnection = nil;
	externalAddressURLData = nil;
	externalAddress = nil;
	externalAddressFetchFailReason = nil;
}

- (void)dealloc
{
	if(externalAddressURLConnection != nil)
	{
		[externalAddressURLConnection cancel];
		[externalAddressURLConnection release];
	}
	[externalAddressURLData release];
	[externalAddress release];
	[externalAddressFetchFailReason release];
	
	[super dealloc];
}

#pragma mark Fetching External Address

- (void)startFetchingExternalAddress
{
	if(isFetchingExternalAddress == NO)
	{
		NSURL *externalAddressURL = [[NSURL alloc] initWithString:@"http://checkip.dyndns.org"];
		NSURLRequest *externalAddressURLRequest = [[NSURLRequest alloc] initWithURL:externalAddressURL 
																		cachePolicy:NSURLRequestReloadIgnoringCacheData
																	timeoutInterval:5.0];
		externalAddressURLConnection = [[NSURLConnection alloc] initWithRequest:externalAddressURLRequest delegate:self];
		
		// since the timeoutInterval in NSURLRequest for some reason doesn't work, we do our own timeout by
		// using a timer and seinding a -cancel message to the NSURLConnection when the timer fires
		fetchingExternalAddressTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self
																	   selector:@selector(_urlLoadingTimeout:) 
																	   userInfo:nil repeats:NO] retain];
		
		[externalAddressURL release];
		[externalAddressURLRequest release];
		
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

#pragma mark NSURLConnection delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(externalAddressURLData == nil)
	{
		externalAddressURLData = [data mutableCopy];
	}
	else
	{
		[externalAddressURLData appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(connection != externalAddressURLConnection)
	{
		return;
	}
	
	[externalAddress release];
	externalAddress = nil;
	[externalAddressFetchFailReason release];
	externalAddressFetchFailReason = nil;
	
	if(externalAddressURLData != nil)
	{
		// parsing the data for the address string
		NSCharacterSet *ipCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
		NSString *urlDataString = [[NSString alloc] initWithData:externalAddressURLData encoding:NSASCIIStringEncoding];
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
	
	[externalAddressURLConnection release];
	externalAddressURLConnection = nil;
	[externalAddressURLData release];
	externalAddressURLData = nil;
	if(fetchingExternalAddressTimer != nil)
	{
		[fetchingExternalAddressTimer invalidate];
		[fetchingExternalAddressTimer release];
		fetchingExternalAddressTimer = nil;
	}
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidEndFetchingExternalAddress object:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[externalAddressURLConnection release];
	externalAddressURLConnection = nil;
	[externalAddressURLData release];
	externalAddressURLData = nil;
	if(fetchingExternalAddressTimer != nil)
	{
		[fetchingExternalAddressTimer invalidate];
		[fetchingExternalAddressTimer release];
		fetchingExternalAddressTimer = nil;
	}
	
	[externalAddress release];
	externalAddress = nil;
	[externalAddressFetchFailReason release];
	externalAddressFetchFailReason = [error localizedDescription];
	didSucceedFetchingExternalAddress = NO;
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidEndFetchingExternalAddress object:self];
}

- (void)_urlLoadingTimeout:(NSTimer *)timer
{
	[externalAddressURLConnection cancel];
	[externalAddressURLConnection release];
	externalAddressURLConnection = nil;
	[externalAddressURLData release];
	externalAddressURLData = nil;
	[fetchingExternalAddressTimer release];
	fetchingExternalAddressTimer = nil;
	
	[externalAddress release];
	externalAddress = nil;
	[externalAddressFetchFailReason release];
	externalAddressFetchFailReason = [NSLocalizedString(@"connection timeout", @"") retain];
	didSucceedFetchingExternalAddress = NO;
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidEndFetchingExternalAddress object:self];
}

@end
