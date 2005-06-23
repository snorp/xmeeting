/*
 * $Id: XMUtils.mm,v 1.5 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMutils.h"

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
	localAddress = nil;
	
	isFetchingExternalAddress = NO;
	didSucceedFetchingExternalAddress = YES;
	externalAddressURLConnection = nil;
	externalAddressURLData = nil;
	externalAddress = nil;
	externalAddressFetchFailReason = nil;
}

- (void)dealloc
{
	[localAddress release];
	
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

#pragma mark Fetching local address

- (NSString *)localAddress
{
	if(localAddress == nil)
	{
		NSArray *hostAddresses = [[NSHost currentHost] addresses];
		unsigned count = [hostAddresses count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSString *address = [hostAddresses objectAtIndex:i];
			NSScanner *scanner = [[NSScanner alloc] initWithString:address];
			int firstByte, secondByte, thirdByte, fourthByte;
			
			if([scanner scanInt:&firstByte] &&
			   [scanner scanString:@"." intoString:nil] &&
			   [scanner scanInt:&secondByte] &&
			   [scanner scanString:@"." intoString:nil] &&
			   [scanner scanInt:&thirdByte] &&
			   [scanner scanString:@"." intoString:nil] &&
			   [scanner scanInt:&fourthByte])
			{
				// we have an ip address. check that we haven't got the 127.0.0.1 address.
				
				if(firstByte != 127 || secondByte != 0 || thirdByte != 0 || fourthByte != 1) // we have a different address
				{
					localAddress = [address retain];
				}
			}
			[scanner release];
			
			if(localAddress != nil)
			{
				break;
			}
		}
	}
	return localAddress;
}

#pragma mark Fetching External Address

- (void)startFetchingExternalAddress
{
	if(isFetchingExternalAddress == NO)
	{
		NSURL *externalAddressURL = [[NSURL alloc] initWithString:@"http://checkip.dyndns.org"];
		NSURLRequest *externalAddressURLRequest = [[NSURLRequest alloc] initWithURL:externalAddressURL 
																		cachePolicy:NSURLRequestReloadIgnoringCacheData
																	timeoutInterval:10.0];
		externalAddressURLConnection = [[NSURLConnection alloc] initWithRequest:externalAddressURLRequest delegate:self];
		
		// since the timeoutInterval in NSURLRequest for some reason doesn't work, we do our own timeout by
		// using a timer and seinding a -cancel message to the NSURLConnection when the timer fires
		fetchingExternalAddressTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self
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

#pragma mark NAT handling

- (XMNATDetectionResult)NATDetectionResult
{	
	NSString *theExternalAddress = [self externalAddress];
	NSString *theLocalAddress = [self localAddress];
	XMNATDetectionResult result;
	
	if(theLocalAddress == nil)
	{
		// we have no network interface!
		result = XMNATDetectionResult_Error;
	}
	else if(theExternalAddress == nil)
	{
		if([self didSucceedFetchingExternalAddress] == YES)
		{
			// no external address fetched yet
			result = XMNATDetectionResult_Error;
		}
		else
		{
			// we have no external address, thus we are not
			// behind a NAT
			result = XMNATDetectionResult_NoNAT;
		}
	}
	else if([theExternalAddress isEqualToString:theLocalAddress])
	{
		return XMNATDetectionResult_NoNAT;
	}
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
