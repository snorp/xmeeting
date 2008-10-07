/*
 * $Id: XMCodecManager.m,v 1.7 2008/10/07 23:19:17 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMCodecManager.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMBridge.h"

@implementation XMCodecManager

#pragma mark -
#pragma mark Class Methods

+ (XMCodecManager *)sharedInstance
{	
  return _XMCodecManagerSharedInstance;
}

#pragma mark -
#pragma mark Init & Deallocation methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
	
  return nil;
}

- (id)_init
{
  self = [super init];
	
  // obtaining the plist-data
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSString *descFilePath = [bundle pathForResource:XMKey_CodecManagerCodecDescriptionsFilename 
                                            ofType:XMKey_CodecManagerCodecDescriptionsFiletype];
	
  NSData *descFileData = [NSData dataWithContentsOfFile:descFilePath];
	
  NSString *errorString;
  NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:descFileData 
                                                                        mutabilityOption:NSPropertyListImmutable
                                                                                  format:NULL
                                                                        errorDescription:&errorString];
	
  if (dict == nil) {
    [NSException raise:XMException_InternalConsistencyFailure format:XMExceptionReason_CodecManagerInternalConsistencyFailure, errorString];
    return nil;
  }
	
  // Importing the audio codecs from the plist
  NSArray *arr = [dict objectForKey:XMKey_CodecManagerAudioCodecs];
  unsigned count = [arr count];
  audioCodecs = [[NSMutableArray alloc] initWithCapacity:count];
	for (unsigned i = 0; i < count; i++)	{
    NSDictionary *descDict = (NSDictionary *)[arr objectAtIndex:i];
		
    XMCodec *codec = [[XMCodec alloc] _initWithDictionary:descDict];
        
    if (_XMHasCodecInstalled([codec identifier])) {
      [audioCodecs addObject:codec];
    }
        
    [codec release];
  }
	
  // Importing the video codecs from the plist
  arr = [dict objectForKey:XMKey_CodecManagerVideoCodecs];
  count = [arr count];
	
  videoCodecs = [[NSMutableArray alloc] initWithCapacity:count];
	
  for (unsigned i = 0; i < count; i++) {
    NSDictionary *descDict = (NSDictionary *)[arr objectAtIndex:i];

    XMCodec *codec = [[XMCodec alloc] _initWithDictionary:descDict];
        
    if (_XMHasCodecInstalled([codec identifier])) {
      [videoCodecs addObject:codec];
    }
        
    [codec release];
	}
	
  return self;
}

- (void)_close
{
  [audioCodecs release];
  [videoCodecs release];
  
  audioCodecs = nil;
  videoCodecs = nil;
}

- (void)dealloc
{
  [self _close];
	
  [super dealloc];
}

#pragma mark -
#pragma mark Methods for Accessing Codec Descriptors

- (XMCodec *)codecForIdentifier:(XMCodecIdentifier)identifier
{
  // check all audio codecs
  unsigned count = [audioCodecs count];
	for (unsigned i = 0; i < count; i++) {
    XMCodec *codec = (XMCodec *)[audioCodecs objectAtIndex:i];
    if ([codec identifier] == identifier) {
      return codec;
    }
  }
	
  // now check the video codecs
  count = [videoCodecs count];
	for (unsigned i = 0; i < count; i++) {
    XMCodec *codec = (XMCodec *)[videoCodecs objectAtIndex:i];
    if ([codec identifier] == identifier) {
      return codec;
    } 
  }
	
  // noting found, returning nil
  return nil;
}

- (unsigned)audioCodecCount
{
  return [audioCodecs count];
}

- (XMCodec *)audioCodecAtIndex:(unsigned)index
{
  return (XMCodec *)[audioCodecs objectAtIndex:index];
}

- (unsigned)videoCodecCount
{
  return [videoCodecs count];
}

- (XMCodec *)videoCodecAtIndex:(unsigned)index
{
  return (XMCodec *)[videoCodecs objectAtIndex:index];
}

@end
