/*
 * $Id: XMUtils.m,v 1.12 2006/04/18 21:58:46 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import <SystemConfiguration/SystemConfiguration.h>

#import "XMUtils.h"
#import "XMPrivate.h"
#import "XMStringConstants.h"

NSString *XMString_DynamicStoreName = @"XMeeting";
NSString *XMString_DynamicStoreNotificationKey = @"State:/Network/Interface/.+/IPv4";

void _XMDynamicStoreCallback(SCDynamicStoreRef dynamicStore, CFArrayRef changedKeys, void *info);

@interface XMUtils (PrivateMethods)

- (void)_urlLoadingTimeout:(NSTimer *)timer;
- (void)_getLocalAddresses;

@end

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
	dynamicStoreContext.version = 0;
	dynamicStoreContext.info = NULL;
	dynamicStoreContext.retain = NULL;
	dynamicStoreContext.release = NULL;
	dynamicStoreContext.copyDescription = NULL;
	dynamicStore = SCDynamicStoreCreate(NULL, (CFStringRef)XMString_DynamicStoreName, _XMDynamicStoreCallback, &dynamicStoreContext);
	CFRunLoopSourceRef runLoopSource = SCDynamicStoreCreateRunLoopSource(NULL, dynamicStore, 0);
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopCommonModes);
	CFRelease(runLoopSource);
	NSArray *notificationKeys = [[NSArray alloc] initWithObjects:XMString_DynamicStoreNotificationKey, nil];
	SCDynamicStoreSetNotificationKeys(dynamicStore, NULL, (CFArrayRef)notificationKeys);
	localAddresses = nil;
	
	isFetchingExternalAddress = NO;
	didSucceedFetchingExternalAddress = YES;
	externalAddressURLConnection = nil;
	externalAddressURLData = nil;
	externalAddress = nil;
	externalAddressFetchFailReason = nil;
	
	[self _getLocalAddresses];
	
	return self;
}

- (void)_close
{
	if(localAddresses != nil)
	{
		[localAddresses release];
		localAddresses = nil;
	}
	
	if(dynamicStore != NULL)
	{
		CFRelease(dynamicStore);
		dynamicStore = NULL;
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

#pragma mark Handling local addresses

- (NSArray *)localAddresses
{
	return localAddresses;
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
		fetchingExternalAddressTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
																	   selector:@selector(_urlLoadingTimeout:) 
																	   userInfo:nil repeats:NO] retain];
		
		[externalAddressURL release];
		[externalAddressURLRequest release];
		
		isFetchingExternalAddress = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidStartFetchingExternalAddress object:self];
	}
}

- (BOOL)isFetchingExternalAddress
{
	return isFetchingExternalAddress;
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
	if([localAddresses count] == 0)
	{
		// we have no network interface!
		return XMNATDetectionResult_Error;
	}
	else if(externalAddress == nil)
	{
		if([self didSucceedFetchingExternalAddress] == YES)
		{
			// external address fetched
			return XMNATDetectionResult_Error;
		}
		else
		{
			// we have no external address. Thus, we have a network
			// interface but we haven't access to the internet
			return XMNATDetectionResult_NoNAT;
		}
	}
	else if([localAddresses containsObject:externalAddress])
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
		NSString *urlDataString = [[NSString alloc] initWithData:externalAddressURLData encoding:NSASCIIStringEncoding];
		NSScanner *scanner = [[NSScanner alloc] initWithString:urlDataString];
		
		if([scanner scanString:@"<html><head><title>Current IP Check</title></head><body>Current IP Address: " intoString:nil])
		{
			int firstByte;
			int secondByte;
			int thirdByte;
			int fourthByte;
			if([scanner scanInt:&firstByte] && [scanner scanString:@"." intoString:nil] &&
			   [scanner scanInt:&secondByte] && [scanner scanString:@"." intoString:nil] &&
			   [scanner scanInt:&thirdByte] && [scanner scanString:@"." intoString:nil] &&
			   [scanner scanInt:&fourthByte])
			{
				externalAddress = [[NSString alloc] initWithFormat:@"%d.%d.%d.%d", firstByte, secondByte, thirdByte, fourthByte];
			}
		}
		
		if(externalAddress != nil)
		{
			didSucceedFetchingExternalAddress = YES;
		}
		else
		{
			didSucceedFetchingExternalAddress = NO;
			externalAddressFetchFailReason = @"Invalid Data";
		}
		
		[scanner release];
		[urlDataString release];
	}
	else
	{
		didSucceedFetchingExternalAddress = NO;
		externalAddressFetchFailReason = @"No Data";
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

#pragma mark Private Methods

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

- (void)_getLocalAddresses
{
	NSString *interfacesKey = (NSString *)SCDynamicStoreKeyCreateNetworkInterface(NULL, kSCDynamicStoreDomainState);
	NSDictionary *interfacesDict = (NSDictionary *)SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)interfacesKey);
	NSArray *interfaces = (NSArray *)[interfacesDict objectForKey:@"Interfaces"];
	NSMutableArray *addresses = [[NSMutableArray alloc] initWithCapacity:3];
	
	unsigned i;
	unsigned count = [interfaces count];
	
	for(i = 0; i < count; i++)
	{
		NSString *interface = (NSString *)[interfaces objectAtIndex:i];
		if([interface isEqualToString:@"lo0"])
		{
			continue;
		}
		NSString *interfaceKey = (NSString *)SCDynamicStoreKeyCreateNetworkInterfaceEntity(NULL, kSCDynamicStoreDomainState,
																						   (CFStringRef)interface, kSCEntNetIPv4);
		NSDictionary *interfaceDict = (NSDictionary *)SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)interfaceKey);
		
		if(interfaceDict != NULL)
		{
			NSArray *interfaceAddresses = [interfaceDict objectForKey:@"Addresses"];
			[addresses addObjectsFromArray:interfaceAddresses];
		}
		[interfaceKey release];
 	}
	
	[interfacesKey release];
	
	if(localAddresses != nil)
	{
		[localAddresses release];
	}
	localAddresses = [addresses copy];
	[addresses release];
	
	[self startFetchingExternalAddress];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidUpdateLocalAddresses object:self];
}

@end

#pragma mark -
#pragma mark Functions

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

BOOL XMIsIPAddress(NSString *address)
{
	NSScanner *scanner = [[NSScanner alloc] initWithString:address];
	
	int byte;
	
	BOOL isIPAddress = NO;
	
	if([scanner scanInt:&byte] && [scanner scanString:@"." intoString:nil] &&
	   [scanner scanInt:&byte] && [scanner scanString:@"." intoString:nil] &&
	   [scanner scanInt:&byte] && [scanner scanString:@"." intoString:nil] &&
	   [scanner scanInt:&byte])
	{
		isIPAddress = YES;
	}
	
	[scanner release];
	
	return isIPAddress;
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
		case XMVideoSize_320_240:
			return NSMakeSize(320, 240);
		default:
			return NSMakeSize(0, 0);
	}
}

float XMGetVideoHeightForWidth(float width, XMVideoSize videoSize)
{
	if(videoSize == XMVideoSize_NoVideo)
	{
		return 0;
	}
	if(videoSize == XMVideoSize_SQCIF ||
	   videoSize == XMVideoSize_320_240)
	{
		// 4:3 aspect ratio
		return width * (3.0 / 4.0);
	}
	else
	{
		// 9:11 aspect ratio
		return width * (9.0 / 11.0);
	}
}

float XMGetVideoWidthForHeight(float height, XMVideoSize videoSize)
{
	if(videoSize == XMVideoSize_NoVideo)
	{
		return 0;
	}
	if(videoSize == XMVideoSize_SQCIF ||
	   videoSize == XMVideoSize_320_240)
	{
		// 4:3 aspect ratio
		return height * (4.0 / 3.0);
	}
	else
	{
		// 11:9 aspect ratio
		return height * (11.0 / 9.0);
	}
}

void _XMDynamicStoreCallback(SCDynamicStoreRef dynamicStore, CFArrayRef changedKeys, void *info)
{
	[_XMUtilsSharedInstance _getLocalAddresses];
}