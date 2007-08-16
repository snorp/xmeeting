/*
 * $Id: XMSimpleAddressResource.h,v 1.5 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIMPLE_ADDRESS_RESOURCE_H__
#define __XM_SIMPLE_ADDRESS_RESOURCE_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMCallAddressManager.h"

/**
* This class implements the simple most address resource, containing
 * only an address and a protocol information
 **/
@interface XMSimpleAddressResource : XMAddressResource <XMCallAddress> {
  
  NSString *address;
  XMCallProtocol callProtocol;
  NSString *displayString;
  NSImage *displayImage;
}

- (id)initWithAddress:(NSString *)address callProtocol:(XMCallProtocol)protocol;

- (NSString *)address;

- (XMCallProtocol)callProtocol;
- (void)setCallProtocol:(XMCallProtocol)callProtocol;

- (NSString *)displayString;
- (void)setDisplayString:(NSString *)displayString;

- (NSImage *)displayImage;
- (void)setDisplayImage:(NSImage *)image;

- (id<XMCallAddressProvider>)provider;

@end

/**
* Simple class that wraps another address resource and implements
 * the XMCallAddress interface
 **/
@interface XMSimpleAddressResourceWrapper : NSObject <XMCallAddress> {
  XMAddressResource *addressResource;
}

- (id)initWithAddressResource:(XMAddressResource *)addressResource;

@end

#endif // __XM_SIMPLE_ADDRESS_RESOURCE_H__
