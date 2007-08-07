/*
 * $Id: XMUtils.m,v 1.23 2007/08/07 14:55:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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
  localAddressInterfaces = nil;
  
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

- (NSArray *)localAddressInterfaces
{
  return localAddressInterfaces;
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
  
  if (natType == XMNATType_Error) {
	if (checkipExternalAddress == nil) {
	  return XMNATType_Error;
	}
	else if ([localAddresses containsObject:checkipExternalAddress])
	{
	  return XMNATType_NoNAT;
	}
	
	return XMNATType_UnknownNAT;
  }
  
  return natType;
}

#pragma mark -
#pragma mark STUN methods

- (NSString *)stunExternalAddress
{
  return stunExternalAddress;
}

- (void)updateSTUNInformation
{	
  [_XMCallManagerSharedInstance _updateSTUNInformation];
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
  NSMutableArray *addresses = [[NSMutableArray alloc] initWithCapacity:3];
  NSMutableArray *interfaces = [[NSMutableArray alloc] initWithCapacity:3];
  
  /**
	* The goal is to get both an array of IPv4 addresses AND a human readable string of the interface name this
   * ip address belongs to.
   * To obtain this, the dynamic store is searched for matches to
   * State:/Network/Service/[^/]+/IPv4
   * Once the IP addresses are obtained, the Setup: domain is searched for the given Service information to obtain
   * the human readable name
   **/
  NSArray *keys = (NSArray *)SCDynamicStoreCopyKeyList(dynamicStore, (CFStringRef)@"State:/Network/Service/[^/]+/IPv4");
  
  unsigned count = [keys count];
  unsigned i;
  for(i = 0; i < count; i++)
  {
	NSString *key = (NSString *)[keys objectAtIndex:i];
	
	// obtaining the address
	NSDictionary *serviceDict = (NSDictionary *)SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)key);
	
	NSArray *interfaceAddresses = (NSArray *)[serviceDict objectForKey:@"Addresses"];
	
	// getting the service-ID
	NSString *serviceID = [[key stringByDeletingLastPathComponent] lastPathComponent];
	
	// searching the Setup: domain for the info about this service
	NSString *servicePath = @"Setup:/Network/Service/";
	NSString *serviceKey = [servicePath stringByAppendingPathComponent:serviceID];
	NSDictionary *serviceInfo = (NSDictionary *)SCDynamicStoreCopyValue(dynamicStore, (CFStringRef)serviceKey);
	
	NSString *interfaceName = [serviceInfo objectForKey:@"UserDefinedName"];
	if(interfaceName == nil)
	{
	  interfaceName = [serviceDict objectForKey:@"InterfaceName"];
	}
	if(interfaceName == nil)
	{
	  interfaceName = @"";
	}
	
	unsigned addressCount = [interfaceAddresses count];
	unsigned j;
	for(j = 0; j < addressCount; j++)
	{
	  [addresses addObject:[interfaceAddresses objectAtIndex:j]];
	  [interfaces addObject:interfaceName];
	}
	
	[serviceDict release];
	[serviceInfo release];
  }
  
  [keys release];
  
  if(localAddresses != nil)
  {
	[localAddresses release];
  }
  localAddresses = [addresses copy];
  [addresses release];
  
  if(localAddressInterfaces != nil)
  {
	[localAddressInterfaces release];
  }
  localAddressInterfaces = [interfaces copy];
  [interfaces release];
  
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
  
  if([scanner scanInt:&byte] && (byte < 256) && [scanner scanString:@"." intoString:nil] &&
	 [scanner scanInt:&byte] && (byte < 256) && [scanner scanString:@"." intoString:nil] &&
	 [scanner scanInt:&byte] && (byte < 256) && [scanner scanString:@"." intoString:nil] &&
	 [scanner scanInt:&byte] && (byte < 256) && [scanner isAtEnd])
  {
	isIPAddress = YES;
  }
  
  [scanner release];
  
  return isIPAddress;
}

NSSize XMVideoSizeToDimensions(XMVideoSize videoSize)
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

XMVideoSize XMDimensionsToVideoSize(NSSize size)
{
  if (size.width == 128 && size.height == 96)
	return XMVideoSize_SQCIF;
  if (size.width == 176 && size.height == 144)
	return XMVideoSize_QCIF;
  if (size.width == 352 && size.height == 288)
	return XMVideoSize_CIF;
  if (size.width == 704 && size.height == 576)
	return XMVideoSize_4CIF;
  if (size.width == 1408 && size.height == 1152)
	return XMVideoSize_16CIF;
  
  return XMVideoSize_NoVideo;
}

float XMGetVideoHeightForWidth(float width, XMVideoSize videoSize)
{
  if(videoSize == XMVideoSize_NoVideo ||
	 videoSize == XMVideoSize_Custom) // when video size is custom, the aspect ration cannot be determined without looking at the video frames
  {
	return 0;
  }
		
  if(videoSize == XMVideoSize_SQCIF)
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
  if(videoSize == XMVideoSize_SQCIF)
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

void XMLogMessage(NSString *message)
{
  const char *msg = [message cStringUsingEncoding:NSASCIIStringEncoding];
  
  _XMLogMessage(msg);
}

void _XMDynamicStoreCallback(SCDynamicStoreRef dynamicStore, CFArrayRef changedKeys, void *info)
{
  [_XMUtilsSharedInstance _getLocalAddresses];
  [_XMUtilsSharedInstance updateSTUNInformation];
  [XMOpalDispatcher _handleNetworkStatusChange];
}