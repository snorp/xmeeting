/*
 * $Id: XMCodecManager.mm,v 1.4 2005/06/23 12:35:56 hfriederich Exp $
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

@interface XMCodecDescriptor (PrivateMethods)

- (id)_initWithDictionary:(NSDictionary *)dict;

- (id)_initWithIdentifier:(NSString *)identifier
					 name:(NSString *)name
				bandwidth:(NSString *)bandwidth
				  quality:(NSString *)quality;
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
	
	audioCodecDescriptors = [[NSMutableArray alloc] initWithCapacity:5];
	videoCodecDescriptors = [[NSMutableArray alloc] initWithCapacity:2];
	
	// obtaining the plist-data
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *descFilePath = [bundle pathForResource:XMKey_CodecManager_CodecDescriptionsFilename 
											  ofType:XMKey_CodecManager_CodecDescriptionsFiletype];
	
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
	NSArray *arr = [dict objectForKey:XMKey_CodecManager_AudioCodecs];
	int count = [arr count];
	int i;
	
	for(i = 0; i < count; i++)
	{
		NSDictionary *descDict = (NSDictionary *)[arr objectAtIndex:i];
		
		XMCodecDescriptor *desc = [[XMCodecDescriptor alloc] _initWithDictionary:descDict];
		[audioCodecDescriptors addObject:desc];
		[desc release];
	}
	
	// Importing the video codecs from the plist
	arr = [dict objectForKey:XMKey_CodecManager_VideoCodecs];
	count = [arr count];
	
	for(i = 0; i < count; i++)
	{
		NSDictionary *descDict = (NSDictionary *)[arr objectAtIndex:i];

		XMCodecDescriptor *desc = [[XMCodecDescriptor alloc] _initWithDictionary:descDict];
		[videoCodecDescriptors addObject:desc];
		[desc release];
	}
	
	return self;
}

- (void)dealloc
{
	[audioCodecDescriptors release];
	[videoCodecDescriptors release];
	
	[super dealloc];
}

#pragma mark Methods for Accessing Codec Descriptors

- (XMCodecDescriptor *)codecDescriptorForIdentifier:(NSString *)identifier
{
	// check all audio codecs
	int count = [audioCodecDescriptors count];
	int i;
	for(i = 0; i < count; i++)
	{
		XMCodecDescriptor *codecDesc = (XMCodecDescriptor *)[audioCodecDescriptors objectAtIndex:i];
		
		if([[codecDesc identifier] isEqualToString:identifier])
		{
			return codecDesc;
		}
	}
	
	// now check the video codecs
	count = [videoCodecDescriptors count];
	for(i = 0; i < count; i++)
	{
		XMCodecDescriptor *codecDesc = (XMCodecDescriptor *)[videoCodecDescriptors objectAtIndex:i];
		
		if([[codecDesc identifier] isEqualToString:identifier])
		{
			return codecDesc;
		}
	}
	
	// noting found, returning nil
	return nil;
}

- (unsigned)audioCodecCount
{
	return [audioCodecDescriptors count];
}

- (XMCodecDescriptor *)audioCodecDescriptorAtIndex:(unsigned)index
{
	return (XMCodecDescriptor *)[audioCodecDescriptors objectAtIndex:index];
}

- (unsigned)videoCodecCount
{
	return [videoCodecDescriptors count];
}

- (XMCodecDescriptor *)videoCodecDescriptorAtIndex:(unsigned)index
{
	return (XMCodecDescriptor *)[videoCodecDescriptors objectAtIndex:index];
}

@end

@implementation XMCodecDescriptor

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithDictionary:(NSDictionary *)dict
{
	NSString *anIdentifier = [dict objectForKey:XMKey_CodecDescriptor_Identifier];
	NSString *aName = [dict objectForKey:XMKey_CodecDescriptor_Name];
	NSString *aBandwidth = [dict objectForKey:XMKey_CodecDescriptor_Bandwidth];
	NSString *aQuality = [dict objectForKey:XMKey_CodecDescriptor_Quality];
	
	if(anIdentifier == nil || aName == nil || aBandwidth == nil || aQuality == nil)
	{
		[NSException raise:XMException_InternalConsistencyFailure
					format:XMExceptionReason_CodecManagerInternalConsistencyFailure];
	}
	
	return [self _initWithIdentifier:anIdentifier name:aName bandwidth:aBandwidth quality:aQuality];
}

- (id)_initWithIdentifier:(NSString *)anIdentifier
					 name:(NSString *)aName 
				bandwidth:(NSString *)aBandwidth 
				  quality:(NSString *)aQuality
{
	self = [super init];
	
	identifier = [anIdentifier copy];
	name = [aName copy];
	bandwidth = [aBandwidth copy];
	quality = [aQuality copy];
	
	return self;
}

- (void)dealloc
{
	[identifier release];
	[name release];
	[bandwidth release];
	[quality release];
	
	[super dealloc];
}

#pragma mark General NSObject Functionality

- (BOOL)isEqual:(NSObject *)object
{
	if(self == object)
	{
		return YES;
	}
	
	if([object isKindOfClass:[self class]])
	{
		XMCodecDescriptor *desc = (XMCodecDescriptor *)object;
		if([identifier isEqualToString:[desc identifier]] &&
		   [name isEqualToString:[desc name]] &&
		   [bandwidth isEqualToString:[desc bandwidth]] &&
		   [quality isEqualToString:[desc quality]])
		   {
			   return YES;
		   }
	}
return NO;
}

#pragma mark Accessors

- (NSString *)propertyForKey:(NSString *)theKey
{
	if([theKey isEqualToString:XMKey_CodecDescriptor_Identifier])
	{
		return identifier;
	}
	
	if([theKey isEqualToString:XMKey_CodecDescriptor_Name])
	{
		return name;
	}
	
	if([theKey isEqualToString:XMKey_CodecDescriptor_Bandwidth])
	{
		return bandwidth;
	}
	
	if([theKey isEqualToString:XMKey_CodecDescriptor_Quality])
	{
		return quality;
	}
	
	return nil;
}

- (NSString *)identifier
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

@end
