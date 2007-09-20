/*
 * $Id: XMUtils.h,v 1.24 2007/09/20 19:14:03 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
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
  NSArray *localAddresses;
  NSArray *localAddressInterfaces;
  
  BOOL doesUpdateSTUNInformation;
  BOOL doesUpdateCheckipInformation;
  
  XMNATType natType;
  NSString *stunExternalAddress;
  NSString *checkipExternalAddress;
  
  NSURLConnection *checkipURLConnection;
  NSMutableData *checkipURLData;
  NSTimer *checkipTimer;
}

/**
 * Returns the shared singleton instance of XMUtils
 **/
+ (XMUtils *)sharedInstance;

/**
 * Returns the local addresses for this computer
 **/
- (NSArray *)localAddresses;

/**
 * Returns the (human readable) interfaces corresponding to the
 * addresses returned by -localAddresses
 **/
- (NSArray *)localAddressInterfaces;

/**
 * Returns the type of NAT detected.
 * The value returned may depend on the STUN settings of the currently
 * active preferences set in XMCallManager.
 * If a STUN-Server is used, returns the NAT-Type returned by the
 * STUN-Server. If no STUN-Server is used, checks whether the external
 * address is contained is found in the localAddresses array. If so,
 * returns XMNATType_NoNAT. Else, returns XMNATType_UnknownNAT
 **/
- (XMNATType)natType;

/**
 * Returns the external address as determined either by STUN
 * or by the checkip - address lookup
 **/
- (NSString *)externalAddress;

/**
 * Updates the network information
 **/
- (void)updateNetworkInformation;

/**
 * Returns the external address as reported by the STUN server
 **/
//- (NSString *)stunExternalAddress;

/**
 * Starts a search for the external address by a HTTP page
 * that displays the external address to be used
 * This is a nonblocking action, the end of a search is reported by
 * sending the appropriate notification.
 **/
//- (void)startFetchingCheckipExternalAddress;

/**
 * Returns whether the external address as reported by the HTTP
 * method is currently being updated or not
 **/
//- (BOOL)isFetchingCheckipExternalAddress;

/**
 * Returns whether the last attempt to fetch the external address
 * by using the HTTP method was succesful or not.
 * Returns YES if no external address has been fetched yet, even
 * if -externalAddress returns nil in this case.
 **/
//- (BOOL)didSucceedFetchingCheckipExternalAddress;

/**
 * Returns the external address as determined by the HTTP Method. 
 * If the external address hasn't been fetched yet, this method 
 * starts a search but returns nil. Thus, this method is nonblocking
 * even if there is no external address yet.
 **/
//- (NSString *)checkipExternalAddress;

/**
 * Returns the fail reason for the external address fetch using
 * the HTTP method.
 * This string is returned localized if present.
 **/
//- (NSString *)checkipExternalAddressFetchFailReason;

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

#endif // __XM_UTILS_H__
