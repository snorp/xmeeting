/*
 * $Id: XMPreferences.m,v 1.3 2005/04/30 20:14:59 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMPreferences.h"
#import "XMCodecManager.h"

NSString *XMKey_BandwidthLimit = @"XMeeting_BandwidthLimit";
NSString *XMKey_UseAddressTranslation = @"XMeeting_UseAddressTranslation";
NSString *XMKey_ExternalAddress = @"XMeeting_ExternalAddress";
NSString *XMKey_TCPPortMin = @"XMeeting_TCPPortMin";
NSString *XMKey_TCPPortMax = @"XMeeting_TCPPortMax";
NSString *XMKey_UDPPortMin = @"XMeeting_UDPPortMin";
NSString *XMKey_UDPPortMax = @"XMeeting_UDPPortMax";

NSString *XMKey_AudioCodecPreferenceList = @"XMeeting_AudioCodecPreferenceList";
NSString *XMKey_AudioBufferSize = @"XMeeting_AudioBufferSize";

NSString *XMKey_EnableVideoReceive = @"XMeeting_EnableVideoReceive";
NSString *XMKey_SendVideo = @"XMeeting_SendVideo";
NSString *XMKey_SendFPS = @"XMeeting_SendFPS";
NSString *XMKey_VideoSize = @"XMeeting_VideoSize";
NSString *XMKey_VideoCodecPreferenceList = @"XMeeting_VideoCodecPreferenceList";

NSString *XMKey_H323_IsEnabled = @"XMeeting_H323_IsEnabled";
NSString *XMKey_H323_EnableH245Tunnel = @"XMeeting_H323_EnableH245Tunnel";
NSString *XMKey_H323_EnableFastStart = @"XMeeting_H323_EnableFastStart";
NSString *XMKey_H323_LocalListenerPort = @"XMeeting_H323_LocalListenerPort";
NSString *XMKey_H323_RemoteListenerPort = @"XMeeting_H323_RemoteListenerPort";
NSString *XMKey_H323_UseGatekeeper = @"XMeeting_H323_UseGatekeeper";
NSString *XMKey_H323_GatekeeperAddress = @"XMeeting_H323_GatekeeperAddress";
NSString *XMKey_H323_GatekeeperID = @"XMeeting_H323_GatekeeperID";
NSString *XMKey_H323_GatekeeperUsername = @"XMeeting_H323_GatekeeperUsername";
NSString *XMKey_H323_GatekeeperE164Number = @"XMeeting_H323_GatekeeperE164Number";

// XMKey_CodecKey is defined in XMCodecManager.mm
NSString *XMKey_CodecIsEnabled = @"XMeeting_CodecIsEnabled";

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
	
	bandwidthLimit = 0;
	useAddressTranslation = NO;
	externalAddress = nil;
	tcpPortMin = 30000;
	tcpPortMax = 30010;
	udpPortMin = 5000;
	udpPortMax = 5099;
	
	// to reduce unnecessary copy overhead, we do not allocate any storage, indicating that
	// this has yet to be done. In case of a copy operation, the array allocated here is never
	// used.
	audioCodecPreferenceList = nil;
	audioBufferSize = 2;
	
	enableVideoReceive = NO;
	sendVideo = NO;
	sendFPS = 5;
	videoSize = XMVideoSize_NoVideo;
	videoCodecPreferenceList = nil;
	
	h323_IsEnabled = YES;
	h323_EnableH245Tunnel = NO;
	h323_EnableFastStart = NO;
	h323_LocalListenerPort = 1720;
	h323_RemoteListenerPort = 1720;
	h323_UseGatekeeper = NO;
	h323_GatekeeperAddress = nil;
	h323_GatekeeperID = nil;
	h323_GatekeeperUsername = nil;
	h323_GatekeeperE164Number = nil;

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [self init];
	
	obj = [dict objectForKey:XMKey_BandwidthLimit];
	if(obj)
	{
		[self setBandwidthLimit:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_UseAddressTranslation];
	if(obj)
	{
		[self setUseAddressTranslation:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_ExternalAddress];
	if(obj)
	{
		[self setExternalAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_TCPPortMin];
	if(obj)
	{
		[self setTCPPortMin:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_TCPPortMax];
	if(obj)
	{
		[self setTCPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_UDPPortMin];
	if(obj)
	{
		[self setUDPPortMin:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_UDPPortMax];
	if(obj)
	{
		[self setUDPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_AudioCodecPreferenceList];
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
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithDictionary:dict];
			
			if([codecManager codecDescriptorForKey:[record key]] != nil)
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
			NSString *key = [[codecManager audioCodecDescriptorAtIndex:i] key];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithKey:key isEnabled:YES];
			[audioCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	obj = [dict objectForKey:XMKey_AudioBufferSize];
	if(obj)
	{
		[self setAudioBufferSize:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_EnableVideoReceive];
	if(obj)
	{
		[self setEnableVideoReceive:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_SendVideo];
	if(obj)
	{
		[self setSendVideo:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_SendFPS];
	if(obj)
	{
		[self setSendFPS:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_VideoSize];
	if(obj)
	{
		[self setVideoSize:[(NSNumber *)obj intValue]];
	}
	
	obj = [dict objectForKey:XMKey_VideoCodecPreferenceList];
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
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithDictionary:dict];
			
			if([codecManager codecDescriptorForKey:[record key]] != nil)
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
			NSString *key = [[codecManager videoCodecDescriptorAtIndex:i] key];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithKey:key isEnabled:YES];
			[videoCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	obj = [dict objectForKey:XMKey_H323_IsEnabled];
	if(obj)
	{
		[self setH323IsEnabled:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_H323_EnableH245Tunnel];
	if(obj)
	{
		[self setH323EnableH245Tunnel:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_H323_EnableFastStart];
	if(obj)
	{
		[self setH323EnableFastStart:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_H323_LocalListenerPort];
	if(obj)
	{
		[self setH323LocalListenerPort:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_H323_RemoteListenerPort];
	if(obj)
	{
		[self setH323RemoteListenerPort:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_H323_UseGatekeeper];
	if(obj)
	{
		[self setH323UseGatekeeper:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_H323_GatekeeperAddress];
	if(obj)
	{
		[self setH323GatekeeperAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_H323_GatekeeperID];
	if(obj)
	{
		[self setH323GatekeeperID:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_H323_GatekeeperUsername];
	if(obj)
	{
		[self setH323GatekeeperUsername:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_H323_GatekeeperE164Number];
	if(obj)
	{
		[self setH323GatekeeperE164Number:(NSString *)obj];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMPreferences *preferences = [[[self class] allocWithZone:zone] init];
	
	[preferences setBandwidthLimit:[self bandwidthLimit]];
	[preferences setUseAddressTranslation:[self useAddressTranslation]];
	[preferences setExternalAddress:[self externalAddress]];
	[preferences setTCPPortMin:[self tcpPortMin]];
	[preferences setTCPPortMax:[self tcpPortMax]];
	[preferences setUDPPortMin:[self udpPortMin]];
	[preferences setUDPPortMax:[self udpPortMax]];
	
	[preferences _setAudioCodecPreferenceList:[self _audioCodecPreferenceList]];
	[preferences setAudioBufferSize:[self audioBufferSize]];
	
	[preferences setEnableVideoReceive:[self enableVideoReceive]];
	[preferences setSendVideo:[self sendVideo]];
	[preferences setSendFPS:[self sendFPS]];
	[preferences setVideoSize:[self videoSize]];
	[preferences _setVideoCodecPreferenceList:[self _videoCodecPreferenceList]];
	
	[preferences setH323IsEnabled:[self h323IsEnabled]];
	[preferences setH323EnableH245Tunnel:[self h323EnableH245Tunnel]];
	[preferences setH323EnableFastStart:[self h323EnableFastStart]];
	[preferences setH323LocalListenerPort:[self h323LocalListenerPort]];
	[preferences setH323RemoteListenerPort:[self h323RemoteListenerPort]];
	[preferences setH323UseGatekeeper:[self h323UseGatekeeper]];
	[preferences setH323GatekeeperAddress:[self h323GatekeeperAddress]];
	[preferences setH323GatekeeperID:[self h323GatekeeperID]];
	[preferences setH323GatekeeperUsername:[self h323GatekeeperUsername]];
	[preferences setH323GatekeeperE164Number:[self h323GatekeeperE164Number]];

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
		
		[self setBandwidthLimit:[coder decodeIntForKey:XMKey_BandwidthLimit]];
		[self setUseAddressTranslation:[coder decodeBoolForKey:XMKey_UseAddressTranslation]];
		[self setExternalAddress:[coder decodeObjectForKey:XMKey_ExternalAddress]];
		[self setTCPPortMin:[coder decodeIntForKey:XMKey_TCPPortMin]];
		[self setTCPPortMax:[coder decodeIntForKey:XMKey_TCPPortMax]];
		[self setUDPPortMin:[coder decodeIntForKey:XMKey_UDPPortMin]];
		[self setUDPPortMax:[coder decodeIntForKey:XMKey_UDPPortMax]];
		
		array = (NSArray *)[coder decodeObjectForKey:XMKey_AudioCodecPreferenceList];
		count = [array count];
		codecCount = [codecManager audioCodecCount];
		audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			XMCodecListRecord *record = (XMCodecListRecord *)[array objectAtIndex:i];
			if([codecManager codecDescriptorForKey:[record key]] != nil)
			{
				[audioCodecPreferenceList addObject:record];
			}
		}
		for(i = count; i < codecCount; i++)
		{
			NSString *key = [[codecManager audioCodecDescriptorAtIndex:i] key];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithKey:key isEnabled:YES];
			[audioCodecPreferenceList addObject:record];
			[record release];
		}
		
		[self setAudioBufferSize:[coder decodeIntForKey:XMKey_AudioBufferSize]];
		
		[self setEnableVideoReceive:[coder decodeBoolForKey:XMKey_EnableVideoReceive]];
		[self setSendVideo:[coder decodeBoolForKey:XMKey_SendVideo]];
		[self setSendFPS:[coder decodeIntForKey:XMKey_SendFPS]];
		[self setVideoSize:[coder decodeIntForKey:XMKey_VideoSize]];
		
		array = (NSArray *)[coder decodeObjectForKey:XMKey_VideoCodecPreferenceList];
		count = [array count];
		codecCount = [codecManager videoCodecCount];
		videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			XMCodecListRecord *record = (XMCodecListRecord *)[array objectAtIndex:i];
			if([codecManager codecDescriptorForKey:[record key]] != nil)
			{
				[videoCodecPreferenceList addObject:record];
			}
		}
		for(i = count; i < codecCount; i++)
		{
			NSString *key = [[codecManager videoCodecDescriptorAtIndex:i] key];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithKey:key isEnabled:YES];
			[videoCodecPreferenceList addObject:record];
			[record release];
		}
		
		[self setH323IsEnabled:[coder decodeBoolForKey:XMKey_H323_IsEnabled]];
		[self setH323EnableH245Tunnel:[coder decodeBoolForKey:XMKey_H323_EnableH245Tunnel]];
		[self setH323EnableFastStart:[coder decodeBoolForKey:XMKey_H323_EnableFastStart]];
		[self setH323LocalListenerPort:[coder decodeIntForKey:XMKey_H323_LocalListenerPort]];
		[self setH323RemoteListenerPort:[coder decodeIntForKey:XMKey_H323_RemoteListenerPort]];
		[self setH323UseGatekeeper:[coder decodeBoolForKey:XMKey_H323_UseGatekeeper]];
		[self setH323GatekeeperAddress:[coder decodeObjectForKey:XMKey_H323_GatekeeperAddress]];
		[self setH323GatekeeperID:[coder decodeObjectForKey:XMKey_H323_GatekeeperID]];
		[self setH323GatekeeperUsername:[coder decodeObjectForKey:XMKey_H323_GatekeeperUsername]];
		[self setH323GatekeeperE164Number:[coder decodeObjectForKey:XMKey_H323_GatekeeperE164Number]];
	}
	else // raise an exception
	{
		[NSException raise:@"XMeetingNonSupportedCoderException" format:@"Only NSCoder subclasses which allow keyed coding are supported."];
		[self release];
		return nil;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeInt:[self bandwidthLimit] forKey:XMKey_BandwidthLimit];
		[coder encodeBool:[self useAddressTranslation] forKey:XMKey_UseAddressTranslation];
		[coder encodeObject:[self externalAddress] forKey:XMKey_ExternalAddress];
		[coder encodeInt:[self tcpPortMin] forKey:XMKey_TCPPortMin];
		[coder encodeInt:[self tcpPortMax] forKey:XMKey_TCPPortMax];
		[coder encodeInt:[self udpPortMin] forKey:XMKey_UDPPortMin];
		[coder encodeInt:[self udpPortMax] forKey:XMKey_UDPPortMax];
		
		[coder encodeObject:[self _audioCodecPreferenceList] forKey:XMKey_AudioCodecPreferenceList];
		[coder encodeInt:[self audioBufferSize] forKey:XMKey_AudioBufferSize];
		
		[coder encodeBool:[self enableVideoReceive] forKey:XMKey_EnableVideoReceive];
		[coder encodeBool:[self sendVideo] forKey:XMKey_SendVideo];
		[coder encodeInt:[self sendFPS] forKey:XMKey_SendFPS];
		[coder encodeInt:[self videoSize] forKey:XMKey_VideoSize];
		[coder encodeObject:[self _videoCodecPreferenceList] forKey:XMKey_VideoCodecPreferenceList];
		
		[coder encodeBool:[self h323IsEnabled] forKey:XMKey_H323_IsEnabled];
		[coder encodeBool:[self h323EnableH245Tunnel] forKey:XMKey_H323_EnableH245Tunnel];
		[coder encodeBool:[self h323EnableFastStart] forKey:XMKey_H323_EnableFastStart];
		[coder encodeInt:[self h323LocalListenerPort] forKey:XMKey_H323_LocalListenerPort];
		[coder encodeInt:[self h323RemoteListenerPort] forKey:XMKey_H323_RemoteListenerPort];
		[coder encodeBool:[self h323UseGatekeeper] forKey:XMKey_H323_UseGatekeeper];
		[coder encodeObject:[self h323GatekeeperAddress] forKey:XMKey_H323_GatekeeperAddress];
		[coder encodeObject:[self h323GatekeeperID] forKey:XMKey_H323_GatekeeperID];
		[coder encodeObject:[self h323GatekeeperUsername] forKey:XMKey_H323_GatekeeperUsername];
		[coder encodeObject:[self h323GatekeeperE164Number] forKey:XMKey_H323_GatekeeperE164Number];
	}
	else // raise an exception
	{
		[NSException raise:@"XMeetingNonSupportedCoderException" format:@"Only NSCoder subclasses which allow keyed coding are supported."];
	}
}

- (void)dealloc
{
	[externalAddress release];
	
	[audioCodecPreferenceList release];
	[videoCodecPreferenceList release];
	
	[h323_GatekeeperAddress release];
	[h323_GatekeeperID release];
	[h323_GatekeeperUsername release];
	[h323_GatekeeperE164Number release];
	
	[super dealloc];
}

#pragma mark General NSObject Functionality

/**
 * this compare is correct but may break if someone decides to
 * override the audio/video codec preferences list handling
 **/
- (BOOL)isEqual:(id)object
{
	XMPreferences *prefs;
	
	if(object == self)
	{
		return YES;
	}
	
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	prefs = (XMPreferences *)object;
	
	if([prefs bandwidthLimit] == [self bandwidthLimit] &&
	   [prefs useAddressTranslation] == [self useAddressTranslation] &&
	   [[prefs externalAddress] isEqualToString:[self externalAddress]] &&
	   [prefs tcpPortMin] == [self tcpPortMin] &&
	   [prefs tcpPortMax] == [self tcpPortMax] &&
	   [prefs udpPortMin] == [self udpPortMin] &&
	   [prefs udpPortMax] == [self udpPortMax] &&
	   
	   [[prefs _audioCodecPreferenceList] isEqual:[self _audioCodecPreferenceList]] &&
	   [prefs audioBufferSize] == [self audioBufferSize] &&
	   
	   [prefs enableVideoReceive] == [self enableVideoReceive] &&
	   [prefs sendVideo] == [self sendVideo] &&
	   [prefs sendFPS] == [self sendFPS] &&
	   [prefs videoSize] == [self videoSize] &&
	   [[prefs _videoCodecPreferenceList] isEqual:[self _videoCodecPreferenceList]] &&

	   [prefs h323IsEnabled] == [self h323IsEnabled] &&
	   [prefs h323EnableH245Tunnel] == [self h323EnableH245Tunnel] &&
	   [prefs h323EnableFastStart] == [self h323EnableFastStart] &&
	   [prefs h323LocalListenerPort] == [self h323LocalListenerPort] &&
	   [prefs h323RemoteListenerPort] == [self h323RemoteListenerPort] &&
	   [prefs h323UseGatekeeper] == [self h323UseGatekeeper] &&
	   [[prefs h323GatekeeperAddress] isEqualToString:[self h323GatekeeperAddress]] &&
	   [[prefs h323GatekeeperID] isEqualToString:[self h323GatekeeperID]] &&
	   [[prefs h323GatekeeperUsername] isEqualToString:[self h323GatekeeperUsername]] &&
	   [[prefs h323GatekeeperE164Number] isEqualToString:[self h323GatekeeperE164Number]])
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
	
	integer = [self bandwidthLimit];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_BandwidthLimit];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self useAddressTranslation]];
	[dict setObject:number forKey:XMKey_UseAddressTranslation];
	[number release];
	
	obj = [self externalAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_ExternalAddress];
	}
	
	integer = [self tcpPortMin];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_TCPPortMin];
		[number release];
	}
	integer = [self tcpPortMax];
	if(integer != UINT_MAX)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_TCPPortMax];
		[number release];
	}
	integer = [self udpPortMin];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_UDPPortMin];
		[number release];
	}
	integer = [self udpPortMax];
	if(integer != UINT_MAX)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_UDPPortMax];
		[number release];
	}
	
	integer = [audioCodecPreferenceList count];
	int i;
	NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMCodecListRecord *)[audioCodecPreferenceList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_AudioCodecPreferenceList];
	[arr release];
	
	integer = [self audioBufferSize];
	if(integer != 2)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_AudioBufferSize];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self enableVideoReceive]];
	[dict setObject:number forKey:XMKey_EnableVideoReceive];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self sendVideo]];
	[dict setObject:number forKey:XMKey_SendVideo];
	[number release];
	
	integer = [self sendFPS];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_SendFPS];
		[number release];
	}
	
	integer = [self videoSize];
	if(integer != XMVideoSize_NoVideo)
	{
		number = [[NSNumber alloc] initWithInt:integer];
		[dict setObject:number forKey:XMKey_VideoSize];
		[number release];
	}
		
	integer = [videoCodecPreferenceList count];
	arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMCodecListRecord *)[videoCodecPreferenceList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_VideoCodecPreferenceList];
	[arr release];
	
	number = [[NSNumber alloc] initWithBool:[self h323IsEnabled]];
	[dict setObject:number forKey:XMKey_H323_IsEnabled];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self h323EnableH245Tunnel]];
	[dict setObject:number forKey:XMKey_H323_EnableH245Tunnel];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self h323EnableFastStart]];
	[dict setObject:number forKey:XMKey_H323_EnableFastStart];
	[number release];
	
	integer = [self h323LocalListenerPort];
	if(integer != 1720)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_H323_LocalListenerPort];
		[number release];
	}
	
	integer = [self h323RemoteListenerPort];
	if(integer != 1720)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_H323_RemoteListenerPort];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self h323UseGatekeeper]];
	[dict setObject:number forKey:XMKey_H323_UseGatekeeper];
	[number release];
	
	obj = [self h323GatekeeperAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_H323_GatekeeperAddress];
	}
	
	obj = [self h323GatekeeperID];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_H323_GatekeeperID];
	}
	
	obj = [self h323GatekeeperUsername];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_H323_GatekeeperUsername];
	}
	
	obj = [self h323GatekeeperE164Number];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_H323_GatekeeperE164Number];
	}
	
	return dict;
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

- (unsigned)tcpPortMin
{
	return tcpPortMin;
}

- (void)setTCPPortMin:(unsigned)port
{
	tcpPortMin = port;
}

- (unsigned)tcpPortMax
{
	return tcpPortMax;
}

- (void)setTCPPortMax:(unsigned)port
{
	tcpPortMax = port;
}

- (unsigned)udpPortMin
{
	return udpPortMin;
}

- (void)setUDPPortMin:(unsigned)port
{
	udpPortMin = port;
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

- (BOOL)sendVideo
{
	return sendVideo;
}

- (void)setSendVideo:(BOOL)flag
{
	sendVideo = flag;
}

- (unsigned)sendFPS
{
	return sendFPS;
}

- (void)setSendFPS:(unsigned)value
{
	sendFPS = value;
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

- (BOOL)h323IsEnabled
{
	return h323_IsEnabled;
}

- (void)setH323IsEnabled:(BOOL)flag
{
	h323_IsEnabled = flag;
}

- (BOOL)h323EnableH245Tunnel
{
	return h323_EnableH245Tunnel;
}

- (void)setH323EnableH245Tunnel:(BOOL)flag
{
	h323_EnableH245Tunnel = flag;
}

- (BOOL)h323EnableFastStart
{
	return h323_EnableFastStart;
}

- (void)setH323EnableFastStart:(BOOL)flag
{
	h323_EnableFastStart = flag;
}

- (unsigned)h323LocalListenerPort
{
	return h323_LocalListenerPort;
}

- (void)setH323LocalListenerPort:(unsigned)port
{
	h323_LocalListenerPort = port;
}

- (unsigned)h323RemoteListenerPort
{
	return h323_RemoteListenerPort;
}

- (void)setH323RemoteListenerPort:(unsigned)port
{
	h323_RemoteListenerPort = port;
}

- (BOOL)h323UseGatekeeper
{
	return h323_UseGatekeeper;
}

- (void)setH323UseGatekeeper:(BOOL)flag
{
	h323_UseGatekeeper = flag;
}

- (NSString *)h323GatekeeperAddress
{
	return h323_GatekeeperAddress;
}

- (void)setH323GatekeeperAddress:(NSString *)address
{
	if(address != h323_GatekeeperAddress)
	{
		NSString *old = h323_GatekeeperAddress;
		h323_GatekeeperAddress = [address copy];
		[old release];
	}
}

- (NSString *)h323GatekeeperID
{
	return h323_GatekeeperID;
}

- (void)setH323GatekeeperID:(NSString *)string
{
	if(string != h323_GatekeeperID)
	{
		NSString *old = h323_GatekeeperID;
		h323_GatekeeperID = [string copy];
		[old release];
	}
}

- (NSString *)h323GatekeeperUsername
{
	return h323_GatekeeperUsername;
}

- (void)setH323GatekeeperUsername:(NSString *)string
{
	if(string != h323_GatekeeperUsername)
	{
		NSString *old = h323_GatekeeperUsername;
		h323_GatekeeperUsername = [string copy];
		[old release];
	}
}

- (NSString *)h323GatekeeperE164Number
{
	return h323_GatekeeperE164Number;
}

- (void)setH323GatekeeperE164Number:(NSString *)string
{
	if(string != h323_GatekeeperE164Number)
	{
		NSString *old = h323_GatekeeperE164Number;
		h323_GatekeeperE164Number = [string copy];
		[old release];
	}
}

- (NSString *)h323GatekeeperPassword
{
	return nil;
	/*
	NSString *gatekeeper;
	NSString *user;
	
	if(h323_GatekeeperHost != nil && [h323_GatekeeperHost length] > 0)
	{
		gatekeeper = h323_GatekeeperHost;
	}
	else if (h323_GatekeeperID != nil && [h323_GatekeeperID length] > 0)
	{
		gatekeeper = h323_GatekeeperID;
	}
	else
	{
		return nil;
	}
	
	if(h323_GatekeeperUsername != nil && [h323_GatekeeperUsername length] > 0)
	{
		user = h323_GatekeeperUsername;
	}
	else
	{
		return nil;
	}
	
	return nil;
	//return [[XMKeyChainAccess sharedInstance] passwordForServiceName:gatekeeper account:user];
	 */
}

- (BOOL)setH323GatekeeperPassword:(NSString *)password
{
	/*
	NSString *gatekeeper;
	NSString *user;
	
	if(h323_GatekeeperHost != nil && [h323_GatekeeperHost length] > 0)
	{
		gatekeeper = h323_GatekeeperHost;
	}
	else if (h323_GatekeeperID != nil && [h323_GatekeeperID length] > 0)
	{
		gatekeeper = h323_GatekeeperID;
	}
	else
	{
		return NO;
	}
	
	if(h323_GatekeeperUsername != nil && [h323_GatekeeperUsername length] > 0)
	{
		user = h323_GatekeeperUsername;
	}
	else
	{
		return NO;
	}
	
	return NO;
	//return [[XMKeyChainAccess sharedInstance] setPassword:password forServiceName:gatekeeper account:user];
	 */
	return FALSE;
}

#pragma mark Private Methods

- (NSMutableArray *)_audioCodecPreferenceList
{
	if(!audioCodecPreferenceList)
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		unsigned count = [codecManager audioCodecCount];
		unsigned i;
		
		audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSString *key = [[codecManager audioCodecDescriptorAtIndex:i] key];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithKey:key isEnabled:YES];
			[audioCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	return audioCodecPreferenceList;
}

- (void)_setAudioCodecPreferenceList:(NSArray *)list
{
	NSArray *old = audioCodecPreferenceList;
	audioCodecPreferenceList = [list mutableCopy];
	[old release];
}

- (NSArray *)_videoCodecPreferenceList
{
	if(!videoCodecPreferenceList)
	{
		XMCodecManager *codecManager = [XMCodecManager sharedInstance];
		unsigned count = [codecManager videoCodecCount];
		unsigned i;
		
		videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:count];
		
		for(i = 0; i < count; i++)
		{
			NSString *key = [[codecManager videoCodecDescriptorAtIndex:i] key];
			XMCodecListRecord *record = [[XMCodecListRecord alloc] initWithKey:key isEnabled:YES];
			[videoCodecPreferenceList addObject:record];
			[record release];
		}
	}
	
	return videoCodecPreferenceList;
}

- (void)_setVideoCodecPreferenceList:(NSArray *)list
{
	if(list != videoCodecPreferenceList)
	{
		NSArray *old = videoCodecPreferenceList;
		videoCodecPreferenceList = [list mutableCopy];
		[old release];
	}
}

@end

@implementation XMCodecListRecord

#pragma mark Init & Deallocation Methods

- (id)initWithKey:(NSString *)theKey isEnabled:(BOOL)enabled
{
	self = [super init];
	
	key = [theKey copy];
	[self setIsEnabled:enabled];
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [super init];
	
	obj = [dict objectForKey:XMKey_CodecKey];
	if(obj)
	{
		key = (NSString *)[obj copy];
	}
	else
	{
		key = @"<Unknown Codec>";
	}
	
	obj = [dict objectForKey:XMKey_CodecIsEnabled];
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
	return [[XMCodecListRecord allocWithZone:zone] initWithKey:[self key] isEnabled:[self isEnabled]];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	if([coder allowsKeyedCoding]) // use keyed coding
	{
		key = (NSString *)[[coder decodeObjectForKey:XMKey_CodecKey] copy];
		[self setIsEnabled:[coder decodeBoolForKey:XMKey_CodecIsEnabled]];
	}
	else // raise an exception
	{
		[NSException raise:@"XMeetingNonSupportedCoderException" format:@"Only NSCoder subclasses which allow keyed coding are supported."];
		[self release];
		return nil;
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if([coder allowsKeyedCoding])
	{
		[coder encodeObject:[self key] forKey:XMKey_CodecKey];
		[coder encodeBool:[self isEnabled] forKey:XMKey_CodecIsEnabled];
	}
	else
	{
		[NSException raise:@"XMeetingNonSupportedCoderException" format:@"Only NSCoder subclasses which allow keyed coding are supported."];
	}
}

- (void)dealloc
{
	[key release];
	
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
	
	if([[entry key] isEqualToString:[self key]] &&
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
		
	[dict setObject:[self key] forKey:XMKey_CodecKey];
	
	number = [[NSNumber alloc] initWithBool:[self isEnabled]];
	[dict setObject:number forKey:XMKey_CodecIsEnabled];
	[number release];
	
	return dict;
}

#pragma mark Getter & Setter Methods

- (NSString *)key;
{
	return key;
}

- (BOOL)isEnabled
{
	return isEnabled;
}

- (void)setIsEnabled:(BOOL)flag
{
	isEnabled = flag;
}

@end
