/*
 * $Id: XMUtils.m,v 1.28 2008/08/14 19:57:05 hfriederich Exp $
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

- (void)_updateCheckipInformation;
- (void)_urlLoadingTimeout:(NSTimer *)timer;
- (void)_cleanupCheckipFetching;
- (void)_getLocalAddresses;
- (void)_gotInformation;

@end

@implementation XMUtils

#pragma mark Class Methods

+ (XMUtils *)sharedInstance
{
  return _XMUtilsSharedInstance;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)_init
{
  SCDynamicStoreContext dynamicStoreContext;
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
  
  doesUpdateSTUNInformation = YES; // at startup, STUN is automatically updated
  doesUpdateCheckipInformation = NO;
  
  networkInterfaces = nil;
  
  natType = XMNATType_NoNAT;
  stunPublicAddress = nil;
  checkipPublicAddress = nil;

  checkipURLConnection = nil;
  checkipURLData = nil;
  checkipTimer = nil;
  
  [self _updateCheckipInformation];
  [self _getLocalAddresses];
  
  return self;
}

- (void)_close
{
  if (dynamicStore != NULL) {
    CFRelease(dynamicStore);
  }
  dynamicStore = NULL;
  
  [networkInterfaces release];
  networkInterfaces = nil;
  
  [stunPublicAddress release];
  stunPublicAddress = nil;
  
  [checkipPublicAddress release];
  checkipPublicAddress = nil;
  
  [checkipURLConnection cancel];
  [checkipURLConnection release];
  checkipURLConnection = nil;
  
  [checkipURLData release];
  checkipURLData = nil;
  
  [checkipTimer invalidate];
  [checkipTimer release];
  checkipTimer = nil;
}

- (void)dealloc
{
  // Although _close should have been called,
  // we call it once again just to be sure
  [self _close];
  
  [super dealloc];
}

#pragma mark -
#pragma mark Handling local network interfaces

- (NSArray *)networkInterfaces
{
  return networkInterfaces;
}

- (BOOL)isLocalAddress:(NSString *)address {
  unsigned count = [networkInterfaces count];
  for (unsigned i = 0; i < count; i++) {
    XMNetworkInterface *interface = (XMNetworkInterface *)[networkInterfaces objectAtIndex:i];
    if ([[interface ipAddress] isEqualToString:address]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark -
#pragma mark NAT handling

- (XMNATType)natType
{	
  if ([networkInterfaces count] == 0)
  {
    // we have no network interface!
    return XMNATType_Error;
  }
  
  // If STUN couldn't resolve the NAT type, determine
  // if there is a NAT based on a comparison of public
  // address and the local addresses
  if (natType == XMNATType_Error) {
    if (checkipPublicAddress == nil) {
      return XMNATType_Error;
    } else if ([self isLocalAddress:checkipPublicAddress]) {
      return XMNATType_NoNAT;
    }
    return XMNATType_UnknownNAT;
  }
  
  return natType;
}

- (NSString *)publicAddress
{
  if (stunPublicAddress != nil) {
    return stunPublicAddress;
  }
  return checkipPublicAddress;
}

- (void)updateNetworkInformation
{
  if (dynamicStore == NULL) {
    return; // Framework is already closing
  }
  
  doesUpdateSTUNInformation = YES;
  [_XMCallManagerSharedInstance _networkConfigurationChanged];
  
  [self _updateCheckipInformation];
  [self _getLocalAddresses];
}

#pragma mark -
#pragma mark Private Methods

- (void)_updateCheckipInformation
{
  if (doesUpdateCheckipInformation == NO) {
    doesUpdateCheckipInformation = YES;
    
    NSURL *checkipURL = [[NSURL alloc] initWithString:XM_CHECKIP_URL];
    NSURLRequest *checkipURLRequest = [[NSURLRequest alloc] initWithURL:checkipURL 
                                                            cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                        timeoutInterval:10.0];
    checkipURLConnection = [[NSURLConnection alloc] initWithRequest:checkipURLRequest delegate:self];
    
    [checkipURLData release];
    checkipURLData = nil;
    
    // since the timeoutInterval in NSURLRequest for some reason doesn't work, we do our own timeout by
    // using a timer and sending a -cancel message to the NSURLConnection when the timer fires
    checkipTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                   selector:@selector(_urlLoadingTimeout:) 
                                                   userInfo:nil repeats:NO] retain];
    
    [checkipURL release];
    [checkipURLRequest release];
  }
}

- (void)_getLocalAddresses
{
  NSMutableArray *interfaces = [[NSMutableArray alloc] initWithCapacity:3];
  
  /**
   * The goal is to get both an array of IPv4 addresses AND a human readable string of the interface name this
   * IP address belongs to.
   * To obtain this, the dynamic store is searched for matches to
   * State:/Network/Service/[^/]+/IPv4
   * Once the IP addresses are obtained, the Setup: domain is searched for the given Service information to obtain
   * the human readable name
   **/
  NSArray *keys = (NSArray *)SCDynamicStoreCopyKeyList(dynamicStore, (CFStringRef)@"State:/Network/Service/[^/]+/IPv4");
  
  unsigned count = [keys count];
  unsigned i;
  for (i = 0; i < count; i++) {
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
    if (interfaceName == nil) {
      interfaceName = [serviceDict objectForKey:@"InterfaceName"];
    }
    if (interfaceName == nil) {
      interfaceName = @"";
    }
    
    unsigned addressCount = [interfaceAddresses count];
    unsigned j;
    for (j = 0; j < addressCount; j++) {
      NSString *address = [interfaceAddresses objectAtIndex:j];
      XMNetworkInterface *interface = [[XMNetworkInterface alloc] initWithIPAddress:address name:interfaceName];
      [interfaces addObject:interface];
    }
    
    [serviceDict release];
    [serviceInfo release];
  }
  
  [keys release];
  
  [networkInterfaces release];
  networkInterfaces = [interfaces copy];
  [interfaces release];
}

- (void)_gotInformation
{
  if (doesUpdateSTUNInformation == NO && doesUpdateCheckipInformation == NO) { // only post the notification if no updates are pending
    [[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_UtilsDidUpdateNetworkInformation object:self];
  }
}

#pragma mark -
#pragma mark STUN Feedback

- (void)_handleSTUNInformation:(NSArray *)array
{
  if (dynamicStore == NULL) {
    return; // Framework is already closing
  }
  
  NSNumber *number = [array objectAtIndex:0];
  natType = (XMNATType)[number unsignedIntValue];
  
  NSString *address = (NSString *)[array objectAtIndex:1];
  if ([address isEqualToString:@""]) {
    address = nil;
  }
  
  [stunPublicAddress release];
  stunPublicAddress = [address copy];
  
  doesUpdateSTUNInformation = NO;
  
  [self _gotInformation];
}

#pragma mark -
#pragma mark Checkip Methods

- (NSString *)_checkipPublicAddress
{
  return checkipPublicAddress;
}

- (BOOL)_doesUpdateCheckipInformation
{
  return doesUpdateCheckipInformation;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  if (checkipURLData == nil) {
    checkipURLData = [data mutableCopy];
  } else {
    [checkipURLData appendData:data];
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  if (connection != checkipURLConnection) {
    return;
  }
  
  [checkipPublicAddress release];
  checkipPublicAddress = nil;
  
  if (checkipURLData != nil) {
    // parsing the data for the address string
    NSString *urlDataString = [[NSString alloc] initWithData:checkipURLData encoding:NSASCIIStringEncoding];
    NSScanner *scanner = [[NSScanner alloc] initWithString:urlDataString];
    
    // too bad Cocoa doesn't have built-in regexp support
    if ([scanner scanString:XM_CHECKIP_PREFIX intoString:nil]) {
      int firstByte;
      int secondByte;
      int thirdByte;
      int fourthByte;
      if ([scanner scanInt:&firstByte] && [scanner scanString:@"." intoString:nil] &&
         [scanner scanInt:&secondByte] && [scanner scanString:@"." intoString:nil] &&
         [scanner scanInt:&thirdByte] && [scanner scanString:@"." intoString:nil] &&
         [scanner scanInt:&fourthByte])
      {
        checkipPublicAddress = [[NSString alloc] initWithFormat:@"%d.%d.%d.%d", firstByte, secondByte, thirdByte, fourthByte];
      }
    }
    
    [scanner release];
    [urlDataString release];
  }
  
  [self _cleanupCheckipFetching];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [checkipPublicAddress release];
  checkipPublicAddress = nil;
  
  [self _cleanupCheckipFetching];
}

- (void)_urlLoadingTimeout:(NSTimer *)timer
{
  [checkipPublicAddress release];
  checkipPublicAddress = nil;
  
  [self _cleanupCheckipFetching];
}

- (void)_cleanupCheckipFetching
{
  if (dynamicStore == NULL) {
    return; // Framework is already closing. SHOULD NOT HAPPEN
  }
  
  doesUpdateCheckipInformation = NO;
  
  [checkipURLConnection release];
  checkipURLConnection = nil;
  
  [checkipURLData release];
  checkipURLData = nil;
  
  [checkipTimer invalidate];
  [checkipTimer release];
  checkipTimer = nil;
  
  [_XMCallManagerSharedInstance _checkipAddressUpdated];
  
  [self _gotInformation];
}

@end

@implementation XMNetworkInterface

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)initWithIPAddress:(NSString *)theIPAddress name:(NSString *)interfaceName
{
  ipAddress = [theIPAddress copy];
  name = [interfaceName copy];
  return self;
}

- (NSString *)ipAddress
{
  return ipAddress;
}

- (NSString *)name
{
  return name;
}

- (BOOL)isEqual:(NSObject *)obj
{
  if ([obj isKindOfClass:[XMNetworkInterface class]]) {
    XMNetworkInterface *networkInterface = (XMNetworkInterface *)obj;
    return ([ipAddress isEqualToString:[networkInterface ipAddress]] && [name isEqualToString:[networkInterface name]]);
  }
  return NO;
}

@end

#pragma mark -
#pragma mark Functions

BOOL XMIsPhoneNumber(NSString *string)
{
  NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789 ()+-"];
  NSScanner *scanner = [[NSScanner alloc] initWithString:string];
  BOOL result = NO;
  
  if ([scanner scanCharactersFromSet:charSet intoString:nil] && [scanner isAtEnd])
  {
	result = YES;
  }
  
  [scanner release];
  
  return result;
}

BOOL XMIsPlainPhoneNumber(NSString *string)
{
  NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
  NSScanner *scanner = [[NSScanner alloc] initWithString:string];
  BOOL result = NO;
  
  if ([scanner scanCharactersFromSet:charSet intoString:nil] && [scanner isAtEnd])
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
  
  if ([scanner scanInt:&byte] && (byte < 256) && [scanner scanString:@"." intoString:nil] &&
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
  if (videoSize == XMVideoSize_NoVideo ||
	 videoSize == XMVideoSize_Custom) // when video size is custom, the aspect ration cannot be determined without looking at the video frames
  {
	return 0;
  }
		
  if (videoSize == XMVideoSize_SQCIF)
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
  if (videoSize == XMVideoSize_NoVideo)
  {
	return 0;
  }
  if (videoSize == XMVideoSize_SQCIF)
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
  [_XMUtilsSharedInstance updateNetworkInformation];
}