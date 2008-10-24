/*
 * $Id: XMCodec.m,v 1.5 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMCodec.h"

#import "XMTypes.h"
#import "XMStringConstants.h"
#import "XMPrivate.h"

@implementation XMCodec

#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)_initWithDictionary:(NSDictionary *)dict
{
  NSNumber *number = (NSNumber *)[dict objectForKey:XMKey_CodecIdentifier];
  NSString *theName = (NSString *)[dict objectForKey:XMKey_CodecName];
  NSString *theBandwidth = (NSString *)[dict objectForKey:XMKey_CodecBandwidth];
  NSString *theQuality = (NSString *)[dict objectForKey:XMKey_CodecQuality];
  NSNumber *theBoolean = (NSNumber *)[dict objectForKey:XMKey_CodecCanDisable];
	
  if (number == nil || theName == nil || theBandwidth == nil || theQuality == nil || theBoolean == nil) {
    [NSException raise:XMException_InternalConsistencyFailure format:XMExceptionReason_CodecManagerInternalConsistencyFailure];
  }
	
  XMCodecIdentifier theIdentifier = (XMCodecIdentifier)[number intValue];
	
  BOOL theCanDisableBoolean = [theBoolean boolValue];
	
  return [self _initWithIdentifier:theIdentifier name:theName bandwidth:theBandwidth quality:theQuality canDisable:theCanDisableBoolean];
}

- (id)_initWithIdentifier:(XMCodecIdentifier)theIdentifier
                     name:(NSString *)theName 
                bandwidth:(NSString *)theBandwidth 
                  quality:(NSString *)theQuality
               canDisable:(BOOL)theCanDisableBoolean
{
  self = [super init];
	
  identifier = theIdentifier;
  name = [theName copy];
  bandwidth = [theBandwidth copy];
  quality = [theQuality copy];
  canDisable = theCanDisableBoolean;
	
  return self;
}

- (void)dealloc
{
  [name release];
  [bandwidth release];
  [quality release];
	
  [super dealloc];
}

#pragma mark General NSObject Functionality

- (BOOL)isEqual:(NSObject *)object
{
  if (self == object) {
    return YES;
  }
	
  if ([object isKindOfClass:[self class]]) {
    XMCodec *codec = (XMCodec *)object;
    if (identifier == [codec identifier] &&
       [name isEqualToString:[codec name]] &&
       [bandwidth isEqualToString:[codec bandwidth]] &&
       [quality isEqualToString:[codec quality]] &&
       canDisable == [codec canDisable]) {
      return YES;
    }
  }
  return NO;
}

#pragma mark Accessors

- (NSObject *)propertyForKey:(NSString *)theKey
{
  if ([theKey isEqualToString:XMKey_CodecIdentifier]) {
    return [NSNumber numberWithInt:(int)identifier];
  } else if ([theKey isEqualToString:XMKey_CodecName]) {
    return name;
  } else if ([theKey isEqualToString:XMKey_CodecBandwidth]) {
    return bandwidth;
  } else if ([theKey isEqualToString:XMKey_CodecQuality]) {
    return quality;
  } else if ([theKey isEqualToString:XMKey_CodecCanDisable]) {
    return [NSNumber numberWithBool:canDisable];
  }
	
  return nil;
}

- (XMCodecIdentifier)identifier
{
  return identifier;
}

- (NSString *)name
{
  return name;
}

- (NSString *)bandwidth
{
  return bandwidth;
}

- (NSString *)quality
{
  return quality;
}

- (BOOL)canDisable
{
  return canDisable;
}

@end