/*
 * $Id: XMUtils.m,v 1.14 2006/06/05 22:24:08 hfriederich Exp $
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

#define XM_CHECKIP_URL @"http://checkip.dyndns.org"
#define XM_CHECKIP_PREFIX @"<html><head><title>Current IP Check</title></head><body>Current IP Address: "

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
	
	natType = XMNATType_NoNAT;
	stunExternalAddress = nil;
	
	isFetchingCheckipExternalAddress = NO;
	didSucceedFetchingCheckipExternalAddress = YES;
	checkipURLConnection = nil;
	checkipURLData = nil;
	checkipExternalAddress = nil;
	checkipExternalAddressFetchFailReason = nil;
	checkipTimer = nil;
	
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
	
	if(checkipURLConnection != nil)
	{
		[checkipURLConnection cancel];
		[checkipURLConnection release];
		checkipURLConnection = nil;
	}
	
	if(checkipURLData != nil)
	{
		[checkipURLData release];
		checkipURLData = nil;
	}
	
	if(checkipExternalAddress != nil)
	{
		[checkipExternalAddress release];
		checkipExternalAddress = nil;
	}
	
	if(checkipExternalAddressFetchFailReason != nil)
	{
		[checkipExternalAddressFetchFailReason release];
		checkipExternalAddressFetchFailReason = nil;
	}
	
	if(checkipTimer != nil)
	{
		[checkipTimer invalidate];
		[checkipTimer release];
		checkipTimer = nil;
	}
}
	
- (void)dealloc
{
	// Although _close should have been called,
	// we call it once again just to be sure
	[self _close];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Handling local addresses

- (NSArray *)localAddresses
{
	return localAddresses;
}

#pragma mark -
#pragma mark NAT handling

- (XMNATType)natType
{	
	if([localAddresses count] == 0)
	{
		// we have no network interface!
		return XMNATType_Error;
	}
	
	if([_XMCallManagerSharedInstance _usesSTUN])
	{
		return natType;
	}
	else if(checkipExternalAddress == nil)
	{
		return XMNATType_Error;
	}
	else if([localAddresses containsObject:checkipExternalAddress])
	{
		return XMNATType_NoNAT;
	}
	
	return XMNATType_UnknownNAT;
}

#pragma mark -
#pragma mark STUN methods

- (NSString *)stunExternalAddress
{
	return stunExternalAddress;
}

- (NSString *)stunServer
{
	if([_XMCallManagerSharedInstance _usesSTUN])
	{
		return [_XMCallManagerSharedInstance _stunServer];
	}
	
	return nil;
}

- (void)updateSTUNInformation
{	
	if([_XMCallManagerSharedInstance _usesSTUN])
	{
		[XMOpalDispatcher _updateSTUNInformation];
	}
}

#pragma mark -
#pragma mark Fetching External Address using HTTP

- (void)startFetchingCheckipExternalAddress
{	
	if(isFetchingCheckipExternalAddress == NO)
	{
		NSURL *checkipURL = [[NSURL alloc] initWithString:XM_CHECKIP_URL];
		NSURLRequest *checkipURLRequest = [[NSURLRequest alloc] initWithURL:checkipURL 
																cachePolicy:NSURLRequestReloadIgnoringCacheData
															timeoutInterval:10.0];
		checkipURLConnection = [[NSURLConnection alloc] initWithRequest:checkipURLRequest delegate:self];
		
		// since the timeoutInterval in NSURLRequest for some reason doesn't work, we do our own timeout by
		// using a timer and sending a -cancel message to the NSURLConnection when the timer fires
		checkipTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
													   selector:@selector(_urlLoadingTimeout:) 
													   userInfo:nil repeats:NO] retain];
		
		[checkipURL release];
		[checkipURLRequest release];
		
		isFetchingCheckipExternalAddress = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidStartFetchingCheckipExternalAddress object:self];
	}
}

- (BOOL)isFetchingCheckipExternalAddress
{
	return isFetchingCheckipExternalAddress;
}

- (BOOL)didSucceedFetchingCheckipExternalAddress
{
	return didSucceedFetchingCheckipExternalAddress;
}

- (NSString *)checkipExternalAddress
{	
	return checkipExternalAddress;
}

- (NSString *)checkipExternalAddressFetchFailReason
{
	return checkipExternalAddressFetchFailReason;
}

#pragma mark -
#pragma mark NSURLConnection delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(checkipURLData == nil)
	{
		checkipURLData = [data mutableCopy];
	}
	else
	{
		[checkipURLData appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(connection != checkipURLConnection)
	{
		return;
	}
	
	if(checkipExternalAddress != nil)
	{
		[checkipExternalAddress release];
		checkipExternalAddress = nil;
	}
	
	if(checkipExternalAddressFetchFailReason != nil)
	{
		[checkipExternalAddressFetchFailReason release];
		checkipExternalAddressFetchFailReason = nil;
	}
	
	if(checkipURLData != nil)
	{
		// parsing the data for the address string
		NSString *urlDataString = [[NSString alloc] initWithData:checkipURLData encoding:NSASCIIStringEncoding];
		NSScanner *scanner = [[NSScanner alloc] initWithString:urlDataString];
		
		if([scanner scanString:XM_CHECKIP_PREFIX intoString:nil])
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
				checkipExternalAddress = [[NSString alloc] initWithFormat:@"%d.%d.%d.%d", firstByte, secondByte, thirdByte, fourthByte];
			}
		}
		
		if(checkipExternalAddress != nil)
		{
			didSucceedFetchingCheckipExternalAddress = YES;
		}
		else
		{
			didSucceedFetchingCheckipExternalAddress = NO;
			checkipExternalAddressFetchFailReason = NSLocalizedString(@"XM_FRAMEWORK_INVALID_DATA", @"");
		}
		
		[scanner release];
		[urlDataString release];
	}
	else
	{
		didSucceedFetchingCheckipExternalAddress = NO;
		checkipExternalAddressFetchFailReason = NSLocalizedString(@"XM_FRAMEWORK_NO_DATA", @"");
	}
	
	if(checkipURLConnection != nil)
	{
		[checkipURLConnection release];
		checkipURLConnection = nil;
	}
	
	if(checkipURLData != nil)
	{
		[checkipURLData release];
		checkipURLData = nil;
	}
	
	if(checkipTimer != nil)
	{
		[checkipTimer invalidate];
		[checkipTimer release];
		checkipTimer = nil;
	}
	
	isFetchingCheckipExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if(checkipURLConnection != nil)
	{
		[checkipURLConnection release];
		checkipURLConnection = nil;
	}
	if(checkipURLData != nil)
	{
		[checkipURLData release];
		checkipURLData = nil;
	}
	if(checkipTimer != nil)
	{
		[checkipTimer invalidate];
		[checkipTimer release];
		checkipTimer = nil;
	}
	
	if(checkipExternalAddress != nil)
	{
		[checkipExternalAddress release];
		checkipExternalAddress = nil;
	}
	
	if(checkipExternalAddressFetchFailReason != nil)
	{
		[checkipExternalAddressFetchFailReason release];
	}
	checkipExternalAddressFetchFailReason = [[error localizedDescription] retain];
	
	didSucceedFetchingCheckipExternalAddress = NO;
	isFetchingCheckipExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:self];
}

#pragma mark -
#pragma mark STUN Feedback

- (void)_handleSTUNInformation:(NSArray *)array
{
	NSNumber *number = [array objectAtIndex:0];
	natType = (XMNATType)[number unsignedIntValue];
	
	NSString *address = (NSString *)[array objectAtIndex:1];
	if([address isEqualToString:@""])
	{
		address = nil;
	}
	
	[stunExternalAddress release];
	stunExternalAddress = [address copy];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidUpdateSTUNInformation object:self];
}

#pragma mark -
#pragma mark Private Methods

- (void)_urlLoadingTimeout:(NSTimer *)timer
{
	[checkipURLConnection cancel];
	[checkipURLConnection release];
	checkipURLConnection = nil;
	
	[checkipURLData release];
	checkipURLData = nil;
	
	[checkipTimer release];
	checkipTimer = nil;
	
	if(checkipExternalAddress != nil)
	{
		[checkipExternalAddress release];
		checkipExternalAddress = nil;
	}
	
	if(checkipExternalAddressFetchFailReason != nil)
	{
		[checkipExternalAddressFetchFailReason release];
	}
	checkipExternalAddressFetchFailReason = [NSLocalizedString(@"XM_FRAMEWORK_CONNECTION_TIMEOUT", @"") retain];
	
	didSucceedFetchingCheckipExternalAddress = NO;
	isFetchingCheckipExternalAddress = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidEndFetchingCheckipExternalAddress object:self];
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
	
	[self startFetchingCheckipExternalAddress];
	
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