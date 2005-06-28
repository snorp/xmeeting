/*
 * $Id: XMCodecManager.mm,v 1.5 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMCodecManager.h"

@interface XMCodecManager (PrivateMethods)

- (id)_init;

@end

@implementation XMCodecManager

#pragma mark Class Methods

+ (XMCodecManager *)sharedInstance
{
	static XMCodecManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMCodecManager alloc] _init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	
	return nil;
}


// This methods currently misses the check with the OPAL system to verify that
// codec described in the plist really exists. This has to be done to prevent
// unpredictable behaviour.
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
	
	if(dict == nil)
	{
		[NSException raise:XMException_InternalConsistencyFailure format:XMExceptionReason_CodecManagerInternalConsistencyFailure, errorString];
		return nil;
	}
	
	// Importing the audio codecs from the plist
	NSArray *arr = [dict objectForKey:XMKey_CodecManagerAudioCodecs];
	int count = [arr count];
	int i;
	
	audioCodecs = [[NSMutableArray alloc] initWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		NSDictionary *descDict = (NSDictionary *)[arr objectAtIndex:i];
		
		XMCodec *codec = [[XMCodec alloc] _initWithDictionary:descDict];
		[audioCodecs addObject:codec];
		[codec release];
	}
	
	// Importing the video codecs from the plist
	arr = [dict objectForKey:XMKey_CodecManagerVideoCodecs];
	count = [arr count];
	
	videoCodecs = [[NSMutableArray alloc] initWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		NSDictionary *descDict = (NSDictionary *)[arr objectAtIndex:i];

		XMCodec *codec = [[XMCodec alloc] _initWithDictionary:descDict];
		[videoCodecs addObject:codec];
		[codec release];
	}
	
	return self;
}

- (void)dealloc
{
	[audioCodecs release];
	[videoCodecs release];
	
	[super dealloc];
}

#pragma mark Methods for Accessing Codec Descriptors

- (XMCodec *)codecForIdentifier:(NSString *)identifier
{
	// check all audio codecs
	int count = [audioCodecs count];
	int i;
	for(i = 0; i < count; i++)
	{
		XMCodec *codec = (XMCodec *)[audioCodecs objectAtIndex:i];
		
		if([[codec identifier] isEqualToString:identifier])
		{
			return codec;
		}
	}
	
	// now check the video codecs
	count = [videoCodecs count];
	for(i = 0; i < count; i++)
	{
		XMCodec *codec = (XMCodec *)[videoCodecs objectAtIndex:i];
		
		if([[codec identifier] isEqualToString:identifier])
		{
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
