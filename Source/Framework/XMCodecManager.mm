/*
 * $Id: XMCodecManager.mm,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCodecManager.h"

#define XM_CODEC_DESCRIPTIONS_FILENAME @"CodecDescriptions"
#define XM_CODEC_DESCRIPTIONS_FILETYPE @"plist"

#define AUDIO_CODECS_KEY @"AudioCodecs"
#define VIDEO_CODECS_KEY @"VideoCodecs"

NSString *XMAudioCodec_G711_ALaw = @"g.711-alaw";
NSString *XMAudioCodec_G711_uLaw = @"g.711-ulaw";
NSString *XMAudioCodec_Speex = @"speex";
NSString *XMAudioCodec_GSM = @"gsm";
NSString *XMAudioCodec_G726 = @"g.726";
NSString *XMAudioCodec_iLBC = @"ilbc";
NSString *XMAudioCodec_IMA_ADPCM = @"ima_adpcm";
NSString *XMAudioCodec_LPC = @"lpc";

NSString *XMVideoCodec_H261 = @"H.261";
NSString *XMVideoCodec_H263 = @"H.263";

NSString *XMKey_CodecKey = @"XMeeting_CodecKey";
NSString *XMKey_CodecName = @"XMeeting_CodecName";
NSString *XMKey_CodecBandwidth = @"XMeeting_CodecBandwidth";
NSString *XMKey_CodecQuality = @"XMeeting_CodecQuality";

/*
 * Private interface to XMCodecDescritpro
 */
@interface XMCodecDescriptor (InitMethod)

- (id)_initWithDictionary:(NSDictionary *)dict;
- (id)_initWithKey:(NSString *)key
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
		sharedInstance = [[XMCodecManager alloc] init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation methods


// This methods currently misses the check with the OPAL system to verify that
// codec described in the plist really exists. This has to be done to prevent
// unpredictable behaviour.
- (id)init
{
	self = [super init];
	
	audioCodecDescriptors = [[NSMutableArray alloc] initWithCapacity:5];
	videoCodecDescriptors = [[NSMutableArray alloc] initWithCapacity:2];
	
	// obtaining the plist-data
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *descFilePath = [bundle pathForResource:XM_CODEC_DESCRIPTIONS_FILENAME 
											  ofType:XM_CODEC_DESCRIPTIONS_FILETYPE];
	
	NSData *descFileData = [NSData dataWithContentsOfFile:descFilePath];
	
	NSString *errorString;
	NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization propertyListFromData:descFileData 
																		  mutabilityOption:NSPropertyListImmutable
																					format:NULL
																		  errorDescription:&errorString];
	
	if(dict == nil)
	{
		[NSException raise:@"XMeetingCodecInfoParseException" format:@"Parsing the infos for available codecs failed. (%@)", errorString];
		return nil;
	}
	
	// Importing the audio codecs from the plist
	NSArray *arr = [dict objectForKey:AUDIO_CODECS_KEY];
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
	arr = [dict objectForKey:VIDEO_CODECS_KEY];
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

- (XMCodecDescriptor *)codecDescriptorForKey:(NSString *)codecKey
{
	// check all audio codecs
	int count = [audioCodecDescriptors count];
	int i;
	for(i = 0; i < count; i++)
	{
		XMCodecDescriptor *codecDesc = (XMCodecDescriptor *)[audioCodecDescriptors objectAtIndex:i];
		
		if([[codecDesc key] isEqualToString:codecKey])
		{
			return codecDesc;
		}
	}
	
	// now check the video codecs
	count = [videoCodecDescriptors count];
	for(i = 0; i < count; i++)
	{
		XMCodecDescriptor *codecDesc = (XMCodecDescriptor *)[videoCodecDescriptors objectAtIndex:i];
		
		if([[codecDesc key] isEqualToString:codecKey])
		{
			return codecDesc;
		}
	}
	
	// noting found, hence returning nil
	return nil;
}

- (unsigned)audioCodecsCount
{
	return [audioCodecDescriptors count];
}

- (XMCodecDescriptor *)audioCodecDescriptorAtIndex:(unsigned)index
{
	return (XMCodecDescriptor *)[audioCodecDescriptors objectAtIndex:index];
}

- (unsigned)videoCodecsCount
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
	NSString *aKey = [dict objectForKey:XMKey_CodecKey];
	NSString *aName = [dict objectForKey:XMKey_CodecName];
	NSString *aBandwidth = [dict objectForKey:XMKey_CodecBandwidth];
	NSString *aQuality = [dict objectForKey:XMKey_CodecQuality];
	
	return [self _initWithKey:aKey name:aName bandwidth:aBandwidth quality:aQuality];
}

- (id)_initWithKey:(NSString *)aKey 
			 name:(NSString *)aName 
		bandwidth:(NSString *)aBandwidth 
		  quality:(NSString *)aQuality
{
	self = [super init];
	
	key = [aKey copy];
	name = [aName copy];
	bandwidth = [aBandwidth copy];
	quality = [aQuality copy];
	
	return self;
}

- (void)dealloc
{
	[key release];
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
		if([key isEqualToString:[desc key]] &&
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
	if([theKey isEqualToString:XMKey_CodecKey])
	{
		return key;
	}
	
	if([theKey isEqualToString:XMKey_CodecName])
	{
		return name;
	}
	
	if([theKey isEqualToString:XMKey_CodecBandwidth])
	{
		return bandwidth;
	}
	
	if([theKey isEqualToString:XMKey_CodecQuality])
	{
		return quality;
	}
	
	return nil;
}

- (NSString *)key
{
	return key;
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
