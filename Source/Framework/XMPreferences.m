/*
 * $Id: XMPreferences.m,v 1.5 2005/06/23 12:35:56 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMPreferences.h"
#import "XMCodecManager.h"

@interface XMCodecListRecord (PrivateMethods)

- (id)_initWithIdentifier:(NSString *)identifier enabled:(BOOL)enabled;
- (id)_initWithDictionary:(NSDictionary *)dict;

@end

@interface XMPreferences(PrivateMethods)

- (NSMutableArray *)_audioCodecPreferenceList;
- (void)_setAudioCodecPreferenceList:(NSArray *)arr;

- (NSMutableArray *)_videoCodecPreferenceList;
- (void)_setVideoCodecPreferenceList:(NSArray *)arr;

- (void)_validateCodecs;

@end

@implementation XMPreferences

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	userName = nil;
	autoAnswerCalls = NO;
	
	bandwidthLimit = 0;
	useAddressTranslation = NO;
	externalAddress = nil;
	tcpPortBase = 30000;
	tcpPortMax = 30010;
	udpPortBase = 5000;
	udpPortMax = 5099;
	
	// to reduce unnecessary copy overhead, we do not allocate any storage, indicating that
	// this has yet to be done. In case of a copy operation, the array allocated here is never
	// used.
	audioBufferSize = 2;
	audioCodecPreferenceList = nil;
	
	enableVideoReceive = NO;
	enableVideoTransmit = NO;
	videoFramesPerSecond = 5;
	videoSize = XMVideoSize_NoVideo;
	videoCodecPreferenceList = nil;
	
	enableH323 = NO;
	enableH245Tunnel = NO;
	enableFastStart = NO;
	useGatekeeper = NO;
	gatekeeperAddress = nil;
	gatekeeperID = nil;
	gatekeeperUsername = nil;
	gatekeeperPhoneNumber = nil;

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [self init];
	
	obj = [dict objectForKey:XMKey_Preferences_UserName];
	if(obj)
	{
		[self setUserName:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_AutoAnswerCalls];
	if(obj)
	{
		[self setAutoAnswerCalls:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_BandwidthLimit];
	if(obj)
	{
		[self setBandwidthLimit:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_UseAddressTranslation];
	if(obj)
	{
		[self setUseAddressTranslation:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_ExternalAddress];
	if(obj)
	{
		[self setExternalAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_TCPPortBase];
	if(obj)
	{
		[self setTCPPortBase:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_TCPPortMax];
	if(obj)
	{
		[self setTCPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_UDPPortBase];
	if(obj)
	{
		[self setUDPPortBase:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_UDPPortMax];
	if(obj)
	{
		[self setUDPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_AudioCodecPreferenceList];
	if(obj)
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		NSArray *arr = (NSArray *)obj;
		unsigned count = [arr count];
		unsigned i;
		
		audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithDictionary:dict];
			
			if([codecManager codecDescriptorForIdentifier:[record identifier]] != nil)
			{
				[audioCodecPreferenceList addObject:record];
			}
			[record release];
		}
		
		// any newly added codecs are guaranteed to be found at the end of the array
		count = [audioCodecPreferenceList count];
		unsigned codecCount = [codecManager audioCodecCount];
		
		for(i = count; i < codecCount; i++)
		{
			NSString *identifier = [[codecManager audioCodecDescriptorAtIndex:i] identifier];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
			[audioCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	obj = [dict objectForKey:XMKey_Preferences_AudioBufferSize];
	if(obj)
	{
		[self setAudioBufferSize:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_EnableVideoReceive];
	if(obj)
	{
		[self setEnableVideoReceive:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_EnableVideoTransmit];
	if(obj)
	{
		[self setEnableVideoTransmit:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_VideoFramesPerSecond];
	if(obj)
	{
		[self setVideoFramesPerSecond:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_VideoSize];
	if(obj)
	{
		[self setVideoSize:[(NSNumber *)obj intValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_VideoCodecPreferenceList];
	if(obj)
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		NSArray *arr = (NSArray *)obj;
		unsigned count = [arr count];
		int i;
		
		videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithDictionary:dict];
			
			if([codecManager codecDescriptorForIdentifier:[record identifier]] != nil)
			{
				[videoCodecPreferenceList addObject:record];
			}
			[record release];
		}
		
		// we have to include additional codec records in case new codecs were added to the system
		count = [videoCodecPreferenceList count];
		unsigned codecCount = [codecManager videoCodecCount];
		
		for(i = count; i < codecCount; i++)
		{
			NSString *identifier = [[codecManager videoCodecDescriptorAtIndex:i] identifier];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
			[videoCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	obj = [dict objectForKey:XMKey_Preferences_EnableH323];
	if(obj)
	{
		[self setEnableH323:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_EnableH245Tunnel];
	if(obj)
	{
		[self setEnableH245Tunnel:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_EnableFastStart];
	if(obj)
	{
		[self setEnableFastStart:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_UseGatekeeper];
	if(obj)
	{
		[self setUseGatekeeper:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_GatekeeperAddress];
	if(obj)
	{
		[self setGatekeeperAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_GatekeeperID];
	if(obj)
	{
		[self setGatekeeperID:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_GatekeeperUsername];
	if(obj)
	{
		[self setGatekeeperUsername:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_Preferences_GatekeeperPhoneNumber];
	if(obj)
	{
		[self setGatekeeperPhoneNumber:(NSString *)obj];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMPreferences *preferences = [[[self class] allocWithZone:zone] init];
	
	[preferences setUserName:[self userName]];
	[preferences setAutoAnswerCalls:[self autoAnswerCalls]];
	
	[preferences setBandwidthLimit:[self bandwidthLimit]];
	[preferences setUseAddressTranslation:[self useAddressTranslation]];
	[preferences setExternalAddress:[self externalAddress]];
	[preferences setTCPPortBase:[self tcpPortBase]];
	[preferences setTCPPortMax:[self tcpPortMax]];
	[preferences setUDPPortBase:[self udpPortBase]];
	[preferences setUDPPortMax:[self udpPortMax]];
	
	[preferences _setAudioCodecPreferenceList:[self _audioCodecPreferenceList]];
	[preferences setAudioBufferSize:[self audioBufferSize]];
	
	[preferences setEnableVideoReceive:[self enableVideoReceive]];
	[preferences setEnableVideoTransmit:[self enableVideoTransmit]];
	[preferences setVideoFramesPerSecond:[self videoFramesPerSecond]];
	[preferences setVideoSize:[self videoSize]];
	[preferences _setVideoCodecPreferenceList:[self _videoCodecPreferenceList]];
	
	[preferences setEnableH323:[self enableH323]];
	[preferences setEnableH245Tunnel:[self enableH245Tunnel]];
	[preferences setEnableFastStart:[self enableFastStart]];
	[preferences setUseGatekeeper:[self useGatekeeper]];
	[preferences setGatekeeperAddress:[self gatekeeperAddress]];
	[preferences setGatekeeperID:[self gatekeeperID]];
	[preferences setGatekeeperUsername:[self gatekeeperUsername]];
	[preferences setGatekeeperPhoneNumber:[self gatekeeperPhoneNumber]];

	return preferences;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	if([coder allowsKeyedCoding]) // use keyed coding
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		NSArray *array;
		unsigned count, codecCount, i;
		
		[self setUserName:[coder decodeObjectForKey:XMKey_Preferences_UserName]];
		[self setAutoAnswerCalls:[coder decodeBoolForKey:XMKey_Preferences_AutoAnswerCalls]];
		[self setBandwidthLimit:[coder decodeIntForKey:XMKey_Preferences_BandwidthLimit]];
		[self setUseAddressTranslation:[coder decodeBoolForKey:XMKey_Preferences_UseAddressTranslation]];
		[self setExternalAddress:[coder decodeObjectForKey:XMKey_Preferences_ExternalAddress]];
		[self setTCPPortBase:[coder decodeIntForKey:XMKey_Preferences_TCPPortBase]];
		[self setTCPPortMax:[coder decodeIntForKey:XMKey_Preferences_TCPPortMax]];
		[self setUDPPortBase:[coder decodeIntForKey:XMKey_Preferences_UDPPortBase]];
		[self setUDPPortMax:[coder decodeIntForKey:XMKey_Preferences_UDPPortMax]];
		
		array = (NSArray *)[coder decodeObjectForKey:XMKey_Preferences_AudioCodecPreferenceList];
		count = [array count];
		codecCount = [codecManager audioCodecCount];
		audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			XMCodecListRecord *record = (XMCodecListRecord *)[array objectAtIndex:i];
			if([codecManager codecDescriptorForIdentifier:[record identifier]] != nil)
			{
				[audioCodecPreferenceList addObject:record];
			}
		}
		for(i = count; i < codecCount; i++)
		{
			NSString *identifier = [[codecManager audioCodecDescriptorAtIndex:i] identifier];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
			[audioCodecPreferenceList addObject:record];
			[record release];
		}
		
		[self setAudioBufferSize:[coder decodeIntForKey:XMKey_Preferences_AudioBufferSize]];
		
		[self setEnableVideoReceive:[coder decodeBoolForKey:XMKey_Preferences_EnableVideoReceive]];
		[self setEnableVideoTransmit:[coder decodeBoolForKey:XMKey_Preferences_EnableVideoTransmit]];
		[self setVideoFramesPerSecond:[coder decodeIntForKey:XMKey_Preferences_VideoFramesPerSecond]];
		[self setVideoSize:[coder decodeIntForKey:XMKey_Preferences_VideoSize]];
		
		array = (NSArray *)[coder decodeObjectForKey:XMKey_Preferences_VideoCodecPreferenceList];
		count = [array count];
		codecCount = [codecManager videoCodecCount];
		videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			XMCodecListRecord *record = (XMCodecListRecord *)[array objectAtIndex:i];
			if([codecManager codecDescriptorForIdentifier:[record identifier]] != nil)
			{
				[videoCodecPreferenceList addObject:record];
			}
		}
		for(i = count; i < codecCount; i++)
		{
			NSString *identifier = [[codecManager videoCodecDescriptorAtIndex:i] identifier];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
			[videoCodecPreferenceList addObject:record];
			[record release];
		}
		
		[self setEnableH323:[coder decodeBoolForKey:XMKey_Preferences_EnableH323]];
		[self setEnableH245Tunnel:[coder decodeBoolForKey:XMKey_Preferences_EnableH245Tunnel]];
		[self setEnableFastStart:[coder decodeBoolForKey:XMKey_Preferences_EnableFastStart]];
		[self setUseGatekeeper:[coder decodeBoolForKey:XMKey_Preferences_UseGatekeeper]];
		[self setGatekeeperAddress:[coder decodeObjectForKey:XMKey_Preferences_GatekeeperAddress]];
		[self setGatekeeperID:[coder decodeObjectForKey:XMKey_Preferences_GatekeeperID]];
		[self setGatekeeperUsername:[coder decodeObjectForKey:XMKey_Preferences_GatekeeperUsername]];
		[self setGatekeeperPhoneNumber:[coder decodeObjectForKey:XMKey_Preferences_GatekeeperPhoneNumber]];
	}
	else // raise an exception
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
		[self release];
		return nil;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:[self userName] forKey:XMKey_Preferences_UserName];
		[coder encodeBool:[self autoAnswerCalls] forKey:XMKey_Preferences_AutoAnswerCalls];
		
		[coder encodeInt:[self bandwidthLimit] forKey:XMKey_Preferences_BandwidthLimit];
		[coder encodeBool:[self useAddressTranslation] forKey:XMKey_Preferences_UseAddressTranslation];
		[coder encodeObject:[self externalAddress] forKey:XMKey_Preferences_ExternalAddress];
		[coder encodeInt:[self tcpPortBase] forKey:XMKey_Preferences_TCPPortBase];
		[coder encodeInt:[self tcpPortMax] forKey:XMKey_Preferences_TCPPortMax];
		[coder encodeInt:[self udpPortBase] forKey:XMKey_Preferences_UDPPortBase];
		[coder encodeInt:[self udpPortMax] forKey:XMKey_Preferences_UDPPortMax];
		
		[coder encodeObject:[self _audioCodecPreferenceList] forKey:XMKey_Preferences_AudioCodecPreferenceList];
		[coder encodeInt:[self audioBufferSize] forKey:XMKey_Preferences_AudioBufferSize];
		
		[coder encodeBool:[self enableVideoReceive] forKey:XMKey_Preferences_EnableVideoReceive];
		[coder encodeBool:[self enableVideoTransmit] forKey:XMKey_Preferences_EnableVideoTransmit];
		[coder encodeInt:[self videoFramesPerSecond] forKey:XMKey_Preferences_VideoFramesPerSecond];
		[coder encodeInt:[self videoSize] forKey:XMKey_Preferences_VideoSize];
		[coder encodeObject:[self _videoCodecPreferenceList] forKey:XMKey_Preferences_VideoCodecPreferenceList];
		
		[coder encodeBool:[self enableH323] forKey:XMKey_Preferences_EnableH323];
		[coder encodeBool:[self enableH245Tunnel] forKey:XMKey_Preferences_EnableH245Tunnel];
		[coder encodeBool:[self enableFastStart] forKey:XMKey_Preferences_EnableFastStart];
		[coder encodeBool:[self useGatekeeper] forKey:XMKey_Preferences_UseGatekeeper];
		[coder encodeObject:[self gatekeeperAddress] forKey:XMKey_Preferences_GatekeeperAddress];
		[coder encodeObject:[self gatekeeperID] forKey:XMKey_Preferences_GatekeeperID];
		[coder encodeObject:[self gatekeeperUsername] forKey:XMKey_Preferences_GatekeeperUsername];
		[coder encodeObject:[self gatekeeperPhoneNumber] forKey:XMKey_Preferences_GatekeeperPhoneNumber];
	}
	else // raise an exception
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
	}
}

- (void)dealloc
{
	[userName release];
	
	[externalAddress release];
	
	[audioCodecPreferenceList release];
	[videoCodecPreferenceList release];
	
	[gatekeeperAddress release];
	[gatekeeperID release];
	[gatekeeperUsername release];
	[gatekeeperPhoneNumber release];
	
	[super dealloc];
}

#pragma mark General NSObject Functionality

/**
 * this compare is correct but may break if someone decides to
 * override the audio/video codec preferences list handling
 **/
- (BOOL)isEqual:(id)object
{
	XMPreferences *otherPreferences;
	
	if(object == self)
	{
		return YES;
	}
	
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	
	otherPreferences = (XMPreferences *)object;
	
	if([[otherPreferences userName] isEqualToString:[self userName]] &&
	   [otherPreferences autoAnswerCalls] == [self autoAnswerCalls] &&
	   [otherPreferences bandwidthLimit] == [self bandwidthLimit] &&
	   [otherPreferences useAddressTranslation] == [self useAddressTranslation] &&
	   [[otherPreferences externalAddress] isEqualToString:[self externalAddress]] &&
	   [otherPreferences tcpPortBase] == [self tcpPortBase] &&
	   [otherPreferences tcpPortMax] == [self tcpPortMax] &&
	   [otherPreferences udpPortBase] == [self udpPortBase] &&
	   [otherPreferences udpPortMax] == [self udpPortMax] &&
	   
	   [[otherPreferences _audioCodecPreferenceList] isEqual:[self _audioCodecPreferenceList]] &&
	   [otherPreferences audioBufferSize] == [self audioBufferSize] &&
	   
	   [otherPreferences enableVideoReceive] == [self enableVideoReceive] &&
	   [otherPreferences enableVideoTransmit] == [self enableVideoTransmit] &&
	   [otherPreferences videoFramesPerSecond] == [self videoFramesPerSecond] &&
	   [otherPreferences videoSize] == [self videoSize] &&
	   [[otherPreferences _videoCodecPreferenceList] isEqual:[self _videoCodecPreferenceList]] &&

	   [otherPreferences enableH323] == [self enableH323] &&
	   [otherPreferences enableH245Tunnel] == [self enableH245Tunnel] &&
	   [otherPreferences enableFastStart] == [self enableFastStart] &&
	   [otherPreferences useGatekeeper] == [self useGatekeeper] &&
	   [[otherPreferences gatekeeperAddress] isEqualToString:[self gatekeeperAddress]] &&
	   [[otherPreferences gatekeeperID] isEqualToString:[self gatekeeperID]] &&
	   [[otherPreferences gatekeeperUsername] isEqualToString:[self gatekeeperUsername]] &&
	   [[otherPreferences gatekeeperPhoneNumber] isEqualToString:[self gatekeeperPhoneNumber]])
	{
		return YES;
	}
	
	return NO;
}

#pragma mark Getting Different Representations

- (NSMutableDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:30];
	NSNumber *number;
	NSObject *obj;
	unsigned integer;
	
	obj = [self userName];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_Preferences_UserName];
	}
	
	number = [[NSNumber alloc] initWithBool:[self autoAnswerCalls]];
	[dict setObject:number forKey:XMKey_Preferences_AutoAnswerCalls];
	[number release];
	
	integer = [self bandwidthLimit];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_BandwidthLimit];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self useAddressTranslation]];
	[dict setObject:number forKey:XMKey_Preferences_UseAddressTranslation];
	[number release];
	
	obj = [self externalAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_Preferences_ExternalAddress];
	}
	
	integer = [self tcpPortBase];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_TCPPortBase];
		[number release];
	}
	integer = [self tcpPortMax];
	if(integer != UINT_MAX)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_TCPPortMax];
		[number release];
	}
	integer = [self udpPortBase];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_UDPPortBase];
		[number release];
	}
	integer = [self udpPortMax];
	if(integer != UINT_MAX)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_UDPPortMax];
		[number release];
	}
	
	integer = [audioCodecPreferenceList count];
	int i;
	NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMCodecListRecord *)[audioCodecPreferenceList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_Preferences_AudioCodecPreferenceList];
	[arr release];
	
	integer = [self audioBufferSize];
	if(integer != 2)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_AudioBufferSize];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self enableVideoReceive]];
	[dict setObject:number forKey:XMKey_Preferences_EnableVideoReceive];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableVideoTransmit]];
	[dict setObject:number forKey:XMKey_Preferences_EnableVideoTransmit];
	[number release];
	
	integer = [self videoFramesPerSecond];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_VideoFramesPerSecond];
		[number release];
	}
	
	integer = [self videoSize];
	if(integer != XMVideoSize_NoVideo)
	{
		number = [[NSNumber alloc] initWithInt:integer];
		[dict setObject:number forKey:XMKey_Preferences_VideoSize];
		[number release];
	}
		
	integer = [videoCodecPreferenceList count];
	arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMCodecListRecord *)[videoCodecPreferenceList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_Preferences_VideoCodecPreferenceList];
	[arr release];
	
	number = [[NSNumber alloc] initWithBool:[self enableH323]];
	[dict setObject:number forKey:XMKey_Preferences_EnableH323];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableH245Tunnel]];
	[dict setObject:number forKey:XMKey_Preferences_EnableH245Tunnel];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableFastStart]];
	[dict setObject:number forKey:XMKey_Preferences_EnableFastStart];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self useGatekeeper]];
	[dict setObject:number forKey:XMKey_Preferences_UseGatekeeper];
	[number release];
	
	obj = [self gatekeeperAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_Preferences_GatekeeperAddress];
	}
	
	obj = [self gatekeeperID];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_Preferences_GatekeeperID];
	}
	
	obj = [self gatekeeperUsername];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_Preferences_GatekeeperUsername];
	}
	
	obj = [self gatekeeperPhoneNumber];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_Preferences_GatekeeperPhoneNumber];
	}
	
	return dict;
}

#pragma mark General Settings Methods

- (NSString *)userName
{
	return userName;
}

- (void)setUserName:(NSString *)name
{
	NSString *old = userName;
	userName = [name copy];
	[old release];
}

- (BOOL)autoAnswerCalls;
{
	return autoAnswerCalls;
}

- (void)setAutoAnswerCalls:(BOOL)flag
{
	autoAnswerCalls = flag;
}

#pragma mark Network-Settings Methods

- (unsigned)bandwidthLimit
{
	return bandwidthLimit;
}

- (void)setBandwidthLimit:(unsigned)limit
{
	bandwidthLimit = limit;
}

- (BOOL)useAddressTranslation
{
	return useAddressTranslation;
}

- (void)setUseAddressTranslation:(BOOL)flag
{
	useAddressTranslation = flag;
}

- (NSString *)externalAddress
{
	return externalAddress;
}

- (void)setExternalAddress:(NSString *)string
{
	if(string != externalAddress)
	{
		NSString *old = externalAddress;
		externalAddress = [string copy];
		[old release];
	}
}

- (unsigned)tcpPortBase
{
	return tcpPortBase;
}

- (void)setTCPPortBase:(unsigned)port
{
	tcpPortBase = port;
}

- (unsigned)tcpPortMax
{
	return tcpPortMax;
}

- (void)setTCPPortMax:(unsigned)port
{
	tcpPortMax = port;
}

- (unsigned)udpPortBase
{
	return udpPortBase;
}

- (void)setUDPPortBase:(unsigned)port
{
	udpPortBase = port;
}

- (unsigned)udpPortMax
{
	return udpPortMax;
}

- (void)setUDPPortMax:(unsigned)port
{
	udpPortMax = port;
}

#pragma mark Audio-specific Methods

- (unsigned)audioCodecListCount
{
	return [[self _audioCodecPreferenceList] count];
}

- (XMCodecListRecord *)audioCodecListRecordAtIndex:(unsigned)index
{
	return (XMCodecListRecord *)[[self _audioCodecPreferenceList] objectAtIndex:index];
}

- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2
{
	[[self _audioCodecPreferenceList] exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (unsigned)audioBufferSize
{
	return audioBufferSize;
}

- (void)setAudioBufferSize:(unsigned)size
{
	audioBufferSize = size;
}

#pragma mark Video Accessor & Setter Methods

- (BOOL)enableVideoReceive
{
	return enableVideoReceive;
}

- (void)setEnableVideoReceive:(BOOL)flag
{
	enableVideoReceive = flag;
}

- (BOOL)enableVideoTransmit
{
	return enableVideoTransmit;
}

- (void)setEnableVideoTransmit:(BOOL)flag
{
	enableVideoTransmit = flag;
}

- (unsigned)videoFramesPerSecond
{
	return videoFramesPerSecond;
}

- (void)setVideoFramesPerSecond:(unsigned)value
{
	videoFramesPerSecond = value;
}

- (XMVideoSize)videoSize
{
	return videoSize;
}

- (void)setVideoSize:(XMVideoSize)size
{
	videoSize = size;
}

- (unsigned)videoCodecListCount
{
	return [[self _videoCodecPreferenceList] count];
}

- (XMCodecListRecord *)videoCodecListRecordAtIndex:(unsigned)index
{
	return (XMCodecListRecord *)[[self _videoCodecPreferenceList] objectAtIndex:index];
}

- (void)videoCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2
{
	[[self _videoCodecPreferenceList] exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

#pragma mark H.323-specific Methods

- (BOOL)enableH323
{
	return enableH323;
}

- (void)setEnableH323:(BOOL)flag
{
	enableH323 = flag;
}

- (BOOL)enableH245Tunnel
{
	return enableH245Tunnel;
}

- (void)setEnableH245Tunnel:(BOOL)flag
{
	enableH245Tunnel = flag;
}

- (BOOL)enableFastStart
{
	return enableFastStart;
}

- (void)setEnableFastStart:(BOOL)flag
{
	enableFastStart = flag;
}

- (BOOL)useGatekeeper
{
	return useGatekeeper;
}

- (void)setUseGatekeeper:(BOOL)flag
{
	useGatekeeper = flag;
}

- (NSString *)gatekeeperAddress
{
	return gatekeeperAddress;
}

- (void)setGatekeeperAddress:(NSString *)address
{
	if(address != gatekeeperAddress)
	{
		NSString *old = gatekeeperAddress;
		gatekeeperAddress = [address copy];
		[old release];
	}
}

- (NSString *)gatekeeperID
{
	return gatekeeperID;
}

- (void)setGatekeeperID:(NSString *)string
{
	if(string != gatekeeperID)
	{
		NSString *old = gatekeeperID;
		gatekeeperID = [string copy];
		[old release];
	}
}

- (NSString *)gatekeeperUsername
{
	return gatekeeperUsername;
}

- (void)setGatekeeperUsername:(NSString *)string
{
	if(string != gatekeeperUsername)
	{
		NSString *old = gatekeeperUsername;
		gatekeeperUsername = [string copy];
		[old release];
	}
}

- (NSString *)gatekeeperPhoneNumber
{
	return gatekeeperPhoneNumber;
}

- (void)setGatekeeperPhoneNumber:(NSString *)string
{
	if(string != gatekeeperPhoneNumber)
	{
		NSString *old = gatekeeperPhoneNumber;
		gatekeeperPhoneNumber = [string copy];
		[old release];
	}
}

#pragma mark Private Methods

- (NSMutableArray *)_audioCodecPreferenceList
{
	if(audioCodecPreferenceList == nil)
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		unsigned count = [codecManager audioCodecCount];
		unsigned i;
		
		audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSString *identifier = [[codecManager audioCodecDescriptorAtIndex:i] identifier];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
			[audioCodecPreferenceList addObject:record];
			[record release];
		}
	}
	return audioCodecPreferenceList;
}

- (void)_setAudioCodecPreferenceList:(NSArray *)list
{
	NSArray *old = audioCodecPreferenceList;
	
	unsigned count = [list count];
	unsigned i;
	audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		XMCodecListRecord *record = (XMCodecListRecord *)[list objectAtIndex:i];
		XMCodecListRecord *copyOfRecord = [record copy];
		[audioCodecPreferenceList addObject:copyOfRecord];
		[copyOfRecord release];
	}
	
	[old release];
}

- (NSMutableArray *)_videoCodecPreferenceList
{
	if(videoCodecPreferenceList == nil)
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		unsigned count = [codecManager videoCodecCount];
		unsigned i;
		
		videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSString *identifier = [[codecManager videoCodecDescriptorAtIndex:i] identifier];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
			[videoCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	return videoCodecPreferenceList;
}

- (void)_setVideoCodecPreferenceList:(NSArray *)list
{
	NSArray *old = videoCodecPreferenceList;
	
	unsigned count = [list count];
	unsigned i;
	videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
	for(i = 0; i < count; i++)
	{
		XMCodecListRecord *record = (XMCodecListRecord *)[list objectAtIndex:i];
		XMCodecListRecord *copyOfRecord = [record copy];
		[videoCodecPreferenceList addObject:copyOfRecord];
		[copyOfRecord release];
	}
	
	[old release];
}

@end

@implementation XMCodecListRecord

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithIdentifier:(NSString *)theIdentifier enabled:(BOOL)enabled
{
	self = [super init];
	
	identifier = [theIdentifier copy];
	[self setEnabled:enabled];
	
	return self;
}

- (id)_initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [super init];
	
	obj = [dict objectForKey:XMKey_CodecListRecord_Identifier];
	if(obj)
	{
		identifier = (NSString *)[obj copy];
	}
	else
	{
		identifier = nil;
	}
	
	obj = [dict objectForKey:XMKey_CodecListRecord_IsEnabled];
	if(obj)
	{
		isEnabled = [(NSNumber *)obj boolValue];
	}
	else
	{
		isEnabled = NO;
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[XMCodecListRecord allocWithZone:zone] _initWithIdentifier:[self identifier] enabled:[self isEnabled]];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	if([coder allowsKeyedCoding]) // use keyed coding
	{
		identifier = (NSString *)[[coder decodeObjectForKey:XMKey_CodecListRecord_Identifier] retain];
		[self setEnabled:[coder decodeBoolForKey:XMKey_CodecListRecord_IsEnabled]];
	}
	else // raise an exception
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
		[self release];
		return nil;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:[self identifier] forKey:XMKey_CodecListRecord_Identifier];
		[coder encodeBool:[self isEnabled] forKey:XMKey_CodecListRecord_IsEnabled];
	}
	else
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
	}
}

- (void)dealloc
{
	[identifier release];
	
	[super dealloc];
}

#pragma mark General NSObject Functionality

- (BOOL)isEqual:(id)object
{
	XMCodecListRecord *entry;
	
	if(object == self)
	{
		return YES;
	}
	
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	entry = (XMCodecListRecord *)object;
	
	if([[entry identifier] isEqualToString:[self identifier]] &&
	   [entry isEnabled] == [self isEnabled])
	{
		return YES;
	}
	return NO;
}

#pragma mark Getting Different Representations

- (NSMutableDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSNumber *number;
		
	[dict setObject:[self identifier] forKey:XMKey_CodecListRecord_Identifier];
	
	number = [[NSNumber alloc] initWithBool:[self isEnabled]];
	[dict setObject:number forKey:XMKey_CodecListRecord_IsEnabled];
	[number release];
	
	return dict;
}

#pragma mark Getter & Setter Methods

- (NSString *)identifier;
{
	return identifier;
}

- (BOOL)isEnabled
{
	return isEnabled;
}

- (void)setEnabled:(BOOL)flag
{
	isEnabled = flag;
}

@end
