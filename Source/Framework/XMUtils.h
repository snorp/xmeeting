/*
 * $Id: XMUtils.h,v 1.30 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_UTILS_H__
#define __XM_UTILS_H__

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "XMTypes.h"

/**
 * XMUtils provides useful service functionality which
 * does not belong at another place
 **/
@interface XMUtils : NSObject {
	
@private
  SCDynamicStoreRef dynamicStore;
  NSArray *networkInterfaces;
  
  BOOL doesUpdateSTUNInformation;
  BOOL doesUpdateCheckipInformation;
  
  XMNATType natType;
  NSString *stunPublicAddress;
  NSString *checkipPublicAddress;
  
  NSURLConnection *checkipURLConnection;
  NSMutableData *checkipURLData;
  NSTimer *checkipTimer;
}

/**
 * Returns the shared singleton instance of XMUtils
 **/
+ (XMUtils *)sharedInstance;

/**
 * Returns the local network interfaces for this computer
 **/
- (NSArray *)networkInterfaces;

/**
 * Returns whether the given IP address is a local address.
 **/
- (BOOL)isLocalAddress:(NSString *)address;

/**
 * Returns the type of NAT detected.
 * The value returned may depend on the STUN settings of the currently
 * active preferences set in XMCallManager.
 * If a STUN-Server is used, returns the NAT-Type returned by the
 * STUN-Server. If no STUN-Server is used, checks whether the public
 * address is contained is found in the localAddresses array. If so,
 * returns XMNATType_NoNAT. Else, returns XMNATType_UnknownNAT
 **/
- (XMNATType)natType;

/**
 * Returns the public address as determined either by STUN
 * or by the checkip - address lookup
 **/
- (NSString *)publicAddress;

/**
 * Updates the network information
 **/
- (void)updateNetworkInformation;

@end

@interface XMNetworkInterface : NSObject {
  
@private
  NSString *ipAddress;
  NSString *name;
}

- (id)initWithIPAddress:(NSString *)ipAddress name:(NSString *)name;
- (NSString *)ipAddress;
- (NSString *)name;

@end

/**
 * checks whether phoneNumber is a phone number and consists of only
 * digits, white space and '(' ')' '+' or '-'
 **/
BOOL XMIsPhoneNumber(NSString *phoneNumber);

/**
 * checks whether phoneNumber is a phone number, similar
 * to XMIsPhoneNumber, but must only contain digits
 **/
BOOL XMIsPlainPhoneNumber(NSString *phoneNumber);

/**
 * checks whether address is an ip address in the form
 * xxx.xxx.xxx.xxx (IPv4)
 **/
BOOL XMIsIPAddress(NSString *address);

/**
 * Returns an NSSize containing the width and height
 * of the specified video size
 **/
NSSize XMVideoSizeToDimensions(XMVideoSize videoSize);

/**
 * Returns the video size corresponding to the size argument.
 * Returns XMVideoSize_NoVideo in case size does not correspond
 * to a "valid" video size
 **/
XMVideoSize XMDimensionsToVideoSize(NSSize dimensions);

/**
 * calculates the other dimension from the given dimension.
 * Since different video sizes may have different aspect ratios,
 * the videoSize argument defines which aspect ration is used.
 **/
float XMGetVideoHeightForWidth(float width, XMVideoSize videoSize);
float XMGetVideoWidthForHeight(float height, XMVideoSize videoSize);

/**
 * Logs the message given by string to the debug log
 **/
void XMLogMessage(NSString *message);

/**
 * Constructs an address-of-record string based on host and username.
 **/
NSString *XMGetAddressOfRecord(NSString *domain, NSString *username);

#endif // __XM_UTILS_H__
