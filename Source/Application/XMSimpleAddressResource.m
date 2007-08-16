/*
 * $Id: XMSimpleAddressResource.m,v 1.5 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMSimpleAddressResource.h"


@implementation XMSimpleAddressResource

#pragma mark Init & Deallocation Methods

- (id)initWithAddress:(NSString *)theAddress callProtocol:(XMCallProtocol)theCallProtocol
{
  address = [theAddress copy];
  callProtocol = theCallProtocol;
  displayString = nil;
  displayImage = nil;
  
  return self;
}

- (void)dealloc
{
  [address release];
  [displayString release];
  [displayImage release];
  
  [super dealloc];
}

#pragma mark Getting & Setting the attributes

- (NSString *)address
{
  return address;
}

- (id<XMCallAddressProvider>)provider
{
  return  nil;
}

- (NSImage *)displayImage
{
  return displayImage;
}

- (void)setDisplayImage:(NSImage *)image
{
  NSImage *old = displayImage;
  displayImage = [image retain];
  [old release];
}

- (XMAddressResource *)addressResource
{
  return self;
}

- (NSString *)displayString
{
  if (displayString != nil) {
    return displayString;
  }
  return [self address];
}

- (void)setDisplayString:(NSString *)_displayString
{
  NSString *old = displayString;
  displayString = [_displayString copy];
  [old release];
}

- (XMCallProtocol)callProtocol
{
  return callProtocol;
}

- (void)setCallProtocol:(XMCallProtocol)theCallProtocol
{
  callProtocol = theCallProtocol;
}

- (NSString *)humanReadableAddress
{
  return [self displayString];
}

@end

@implementation XMSimpleAddressResourceWrapper

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)initWithAddressResource:(XMAddressResource *)_addressResource
{
  self = [super init];
  
  addressResource = [_addressResource retain];
  
  return self;
}

- (void)dealloc
{
  [addressResource release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark XMCallAddress methods

- (id<XMCallAddressProvider>)provider
{
  return nil;
}

- (XMAddressResource *)addressResource
{
  return addressResource;
}

- (NSString *)displayString
{
  return [addressResource humanReadableAddress];
}

- (NSImage *)displayImage
{
  return nil;
}

@end
