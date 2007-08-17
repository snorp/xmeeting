/*
 * $Id: XMSimpleAddressResource.h,v 1.6 2007/08/17 11:36:41 hfriederich Exp $
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
 
@private
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

@private
  XMAddressResource *addressResource;
}

- (id)initWithAddressResource:(XMAddressResource *)addressResource;

@end

#endif // __XM_SIMPLE_ADDRESS_RESOURCE_H__
