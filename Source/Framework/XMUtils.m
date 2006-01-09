/*
 * $Id: XMUtils.m,v 1.6 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMUtils.h"
#import "XMPrivate.h"
#import "XMStringConstants.h"

@implementation XMUtils

#pragma mark Class Methods

+ (XMUtils *)sharedInstance
{	
	if(_XMUtilsSharedInstance == nil)
	{
		NSLog(@"Attempt to access XMUtils prior to initialization");
	}
	return _XMUtilsSharedInstance;
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
	
	return self;
}

- (void)_close
{
	if(localAddress != nil)
	{
		[localAddress release];
		localAddress = nil;
	}
	
	if(externalAddressURLConnection != nil)
	{
		[externalAddressURLConnection cancel];
		[externalAddressURLConnection release];
		externalAddressURLConnection = nil;
	}
	
	if(externalAddressURLData != nil)
	{
		[externalAddressURLData release];
		externalAddressURLData = nil;
	}
	
	if(externalAddress != nil)
	{
		[externalAddress release];
		externalAddress = nil;
	}
	
	if(externalAddressFetchFailReason != nil)
	{
		[externalAddressFetchFailReason release];
		externalAddressFetchFailReason = nil;
	}
	
	if(fetchingExternalAddressTimer != nil)
	{
		[fetchingExternalAddressTimer invalidate];
		[fetchingExternalAddressTimer release];
		fetchingExternalAddressTimer = nil;
	}
}
	
- (void)dealloc
{
	// Although _close should have been called,
	// we call it once again just to be sure
	[self _close];
	
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
				// we have an IPv4 address. check that we haven't got the loopback address.
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
		// using a timer and sending a -cancel message to the NSURLConnection when the timer fires
		fetchingExternalAddressTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self
																	   selector:@selector(_urlLoadingTimeout:) 
																	   userInfo:nil repeats:NO] retain];
		
		[externalAddressURL release];
		[externalAddressURLRequest release];
		
		isFetchingExternalAddress = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidStartFetchingExternalAddress object:self];
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

- (XMNATDetectionResult)natDetectionResult
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
	
	return XMNATDetectionResult_HasNAT;
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
	
	if(externalAddress != nil)
	{
		[externalAddress release];
		externalAddress = nil;
	}
	
	if(externalAddressFetchFailReason != nil)
	{
		[externalAddressFetchFailReason release];
		externalAddressFetchFailReason = nil;
	}
	
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
	
	if(externalAddressURLConnection != nil)
	{
		[externalAddressURLConnection release];
		externalAddressURLConnection = nil;
	}
	
	if(externalAddressURLData != nil)
	{
		[externalAddressURLData release];
		externalAddressURLData = nil;
	}
	
	if(fetchingExternalAddressTimer != nil)
	{
		[fetchingExternalAddressTimer invalidate];
		[fetchingExternalAddressTimer release];
		fetchingExternalAddressTimer = nil;
	}
	
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidEndFetchingExternalAddress object:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if(externalAddressURLConnection != nil)
	{
		[externalAddressURLConnection release];
		externalAddressURLConnection = nil;
	}
	if(externalAddressURLData != nil)
	{
		[externalAddressURLData release];
		externalAddressURLData = nil;
	}
	if(fetchingExternalAddressTimer != nil)
	{
		[fetchingExternalAddressTimer invalidate];
		[fetchingExternalAddressTimer release];
		fetchingExternalAddressTimer = nil;
	}
	
	if(externalAddress != nil)
	{
		[externalAddress release];
		externalAddress = nil;
	}
	
	if(externalAddressFetchFailReason != nil)
	{
		[externalAddressFetchFailReason release];
	}
	externalAddressFetchFailReason = [[error localizedDescription] retain];
	
	didSucceedFetchingExternalAddress = NO;
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidEndFetchingExternalAddress object:self];
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
	
	if(externalAddress != nil)
	{
		[externalAddress release];
		externalAddress = nil;
	}
	
	if(externalAddressFetchFailReason != nil)
	{
		[externalAddressFetchFailReason release];
	}
	externalAddressFetchFailReason = [NSLocalizedString(@"connection timeout", @"") retain];
	
	didSucceedFetchingExternalAddress = NO;
	isFetchingExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidEndFetchingExternalAddress object:self];
}

@end

BOOL XMIsPhoneNumber(NSString *string)
{
	NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789 ()+-"];
	NSScanner *scanner = [[NSScanner alloc] initWithString:string];
	BOOL result = NO;
	
	if([scanner scanCharactersFromSet:charSet intoString:nil] && [scanner isAtEnd])
	{
		result = YES;
	}
	
	[scanner release];
	
	return result;
}

NSSize XMGetVideoFrameDimensions(XMVideoSize videoSize)
{
	switch (videoSize)
	{
		case XMVideoSize_SQCIF:
			return NSMakeSize(128, 96);
		case XMVideoSize_QCIF:
			return NSMakeSize(176, 144);
		case XMVideoSize_CIF:
			return NSMakeSize(352, 288);
		case XMVideoSize_4CIF:
			return NSMakeSize(704, 576);
		case XMVideoSize_16CIF:
			return NSMakeSize(1408, 1152);
		default:
			return NSMakeSize(0, 0);
	}
}

float XMGetVideoHeightForWidth(float width)
{
	return width * (9.0/11.0);
}

float XMGetVideoWidthForHeight(float height)
{
	return height * (11.0/9.0);
}