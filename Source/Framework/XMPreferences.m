/*
 * $Id: XMPreferences.m,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMPreferences.h"
//#import "XMKeyChainAccess.h"

NSString *XMKey_AutoanswerCalls = @"XMeeting_AutoanswerCalls";
NSString *XMKey_BandwidthLimit = @"XMeeting_BandwidthLimit";
NSString *XMKey_UseIPAddressTranslation = @"XMeeting_UseIPAddressTranslation";
NSString *XMKey_ExternalIPAddress = @"XMeeting_ExternalIPAddress";

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

NSString *XMKey_H323_EnableH245Tunnel = @"XMeeting_H323_EnableH245Tunnel";
NSString *XMKey_H323_EnableFastStart = @"XMeeting_H323_EnableFastStart";
NSString *XMKey_H323_LocalListenerPort = @"XMeeting_H323_LocalListenerPort";
NSString *XMKey_H323_RemoteListenerPort = @"XMeeting_H323_RemoteListenerPort";
NSString *XMKey_H323_UseGatekeeper = @"XMeeting_H323_UseGatekeeper";
NSString *XMKey_H323_GatekeeperHost = @"XMeeting_H323_GatekeeperHost";
NSString *XMKey_H323_GatekeeperID = @"XMeeting_H323_GatekeeperID";
NSString *XMKey_H323_GatekeeperUsername = @"XMeeting_H323_GatekeeperUsername";
NSString *XMKey_H323_GatekeeperE164Number = @"XMeeting_H323_GatekeeperE164Number";

// XMKey_CodecKey is defined in XMCodecManager.mm
NSString *XMKey_CodecIsEnabled = @"XMeeeting_CodecIsEnabled";

@interface XMPreferences(PrivateMethods)

- (NSArray *)_audioCodecPreferenceList;
- (void)_setAudioCodecPreferenceList:(NSArray *)arr;

- (NSArray *)_videoCodecPreferenceList;
- (void)_setVideoCodecPreferenceList:(NSArray *)arr;

@end

@implementation XMPreferences

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	autoanswerCalls = NO;
	bandwidthLimit = 0;
	useIPAddressTranslation = NO;
	externalIPAddress = nil;
	
	tcpPortMin = 30000;
	tcpPortMax = 30010;
	udpPortMin = 5000;
	udpPortMax = 5099;
	
	audioCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:5];
	audioBufferSize = 2;
	
	enableVideoReceive = NO;
	sendVideo = NO;
	sendFPS = 5;
	videoSize = XMVideoSize_NoVideo;
	videoCodecPreferenceList = [[NSMutableArray alloc] initWithCapacity:2];
	
	h323_EnableH245Tunnel = NO;
	h323_EnableFastStart = NO;
	h323_LocalListenerPort = 1720;
	h323_RemoteListenerPort = 1720;
	h323_UseGatekeeper = NO;
	h323_GatekeeperHost = nil;
	h323_GatekeeperID = nil;
	h323_GatekeeperUsername = nil;
	h323_GatekeeperE164Number = nil;

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [self init];
	
	obj = [dict objectForKey:XMKey_AutoanswerCalls];
	if(obj)
	{
		[self setAutoanswerCalls:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_BandwidthLimit];
	if(obj)
	{
		[self setBandwidthLimit:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_UseIPAddressTranslation];
	if(obj)
	{
		[self setUseIPAddressTranslation:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_ExternalIPAddress];
	if(obj)
	{
		[self setExternalIPAddress:(NSString *)obj];
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
		NSArray *arr = (NSArray *)obj;
		unsigned count = [arr count];
		int i;
		
		[audioCodecPreferenceList removeAllObjects];
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
			XMCodecListEntry *entry = [[XMCodecListEntry alloc] initWithDictionary:dict];
			[audioCodecPreferenceList addObject:entry];
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
		NSArray *arr = (NSArray *)obj;
		unsigned count = [arr count];
		int i;
		
		[videoCodecPreferenceList removeAllObjects];
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
			XMCodecListEntry *entry = [[XMCodecListEntry alloc] initWithDictionary:dict];
			[videoCodecPreferenceList addObject:entry];
		}
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
	
	obj = [dict objectForKey:XMKey_H323_GatekeeperHost];
	if(obj)
	{
		[self setH323GatekeeperHost:(NSString *)obj];
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
	
	[preferences setAutoanswerCalls:[self autoanswerCalls]];
	[preferences setBandwidthLimit:[self bandwidthLimit]];
	[preferences setUseIPAddressTranslation:[self useIPAddressTranslation]];
	[preferences setExternalIPAddress:[self externalIPAddress]];
	
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
	
	[preferences setH323EnableH245Tunnel:[self h323EnableH245Tunnel]];
	[preferences setH323EnableFastStart:[self h323EnableFastStart]];
	[preferences setH323LocalListenerPort:[self h323LocalListenerPort]];
	[preferences setH323RemoteListenerPort:[self h323RemoteListenerPort]];
	[preferences setH323UseGatekeeper:[self h323UseGatekeeper]];
	[preferences setH323GatekeeperHost:[self h323GatekeeperHost]];
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
		[self setAutoanswerCalls:[coder decodeBoolForKey:XMKey_AutoanswerCalls]];
		[self setBandwidthLimit:[coder decodeIntForKey:XMKey_BandwidthLimit]];
		[self setUseIPAddressTranslation:[coder decodeBoolForKey:XMKey_UseIPAddressTranslation]];
		[self setExternalIPAddress:[coder decodeObjectForKey:XMKey_ExternalIPAddress]];
		
		[self setTCPPortMin:[coder decodeIntForKey:XMKey_TCPPortMin]];
		[self setTCPPortMax:[coder decodeIntForKey:XMKey_TCPPortMax]];
		[self setUDPPortMin:[coder decodeIntForKey:XMKey_UDPPortMin]];
		[self setUDPPortMax:[coder decodeIntForKey:XMKey_UDPPortMax]];
		
		[self _setAudioCodecPreferenceList:[coder decodeObjectForKey:XMKey_AudioCodecPreferenceList]];
		[self setAudioBufferSize:[coder decodeIntForKey:XMKey_AudioBufferSize]];
		
		[self setEnableVideoReceive:[coder decodeBoolForKey:XMKey_EnableVideoReceive]];
		[self setSendVideo:[coder decodeBoolForKey:XMKey_SendVideo]];
		[self setSendFPS:[coder decodeIntForKey:XMKey_SendFPS]];
		[self setVideoSize:[coder decodeIntForKey:XMKey_VideoSize]];
		[self _setVideoCodecPreferenceList:[coder decodeObjectForKey:XMKey_VideoCodecPreferenceList]];
		
		[self setH323EnableH245Tunnel:[coder decodeBoolForKey:XMKey_H323_EnableH245Tunnel]];
		[self setH323EnableFastStart:[coder decodeBoolForKey:XMKey_H323_EnableFastStart]];
		[self setH323LocalListenerPort:[coder decodeIntForKey:XMKey_H323_LocalListenerPort]];
		[self setH323RemoteListenerPort:[coder decodeIntForKey:XMKey_H323_RemoteListenerPort]];
		[self setH323UseGatekeeper:[coder decodeBoolForKey:XMKey_H323_UseGatekeeper]];
		[self setH323GatekeeperHost:[coder decodeObjectForKey:XMKey_H323_GatekeeperHost]];
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
		[coder encodeBool:[self autoanswerCalls] forKey:XMKey_AutoanswerCalls];
		[coder encodeInt:[self bandwidthLimit] forKey:XMKey_BandwidthLimit];
		[coder encodeBool:[self useIPAddressTranslation] forKey:XMKey_UseIPAddressTranslation];
		[coder encodeObject:[self externalIPAddress] forKey:XMKey_ExternalIPAddress];
		
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
		
		[coder encodeBool:[self h323EnableH245Tunnel] forKey:XMKey_H323_EnableH245Tunnel];
		[coder encodeBool:[self h323EnableFastStart] forKey:XMKey_H323_EnableFastStart];
		[coder encodeInt:[self h323LocalListenerPort] forKey:XMKey_H323_LocalListenerPort];
		[coder encodeInt:[self h323RemoteListenerPort] forKey:XMKey_H323_RemoteListenerPort];
		[coder encodeBool:[self h323UseGatekeeper] forKey:XMKey_H323_UseGatekeeper];
		[coder encodeObject:[self h323GatekeeperHost] forKey:XMKey_H323_GatekeeperHost];
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
	[externalIPAddress release];
	
	[audioCodecPreferenceList release];
	
	[videoCodecPreferenceList release];
	
	[h323_GatekeeperHost release];
	[h323_GatekeeperID release];
	[h323_GatekeeperUsername release];
	[h323_GatekeeperE164Number release];
	
	[super dealloc];
}

#pragma mark General NSObject Functionality

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
	
	if([prefs autoanswerCalls] == [self autoanswerCalls] &&
	   [prefs bandwidthLimit] == [self bandwidthLimit] &&
	   [prefs useIPAddressTranslation] == [self useIPAddressTranslation] &&
	   [[prefs externalIPAddress] isEqualToString:[self externalIPAddress]] &&
	   
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

	   [prefs h323EnableH245Tunnel] == [self h323EnableH245Tunnel] &&
	   [prefs h323EnableFastStart] == [self h323EnableFastStart] &&
	   [prefs h323LocalListenerPort] == [self h323LocalListenerPort] &&
	   [prefs h323RemoteListenerPort] == [self h323RemoteListenerPort] &&
	   [prefs h323UseGatekeeper] == [self h323UseGatekeeper] &&
	   [[prefs h323GatekeeperHost] isEqualToString:[self h323GatekeeperHost]] &&
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
	
	number = [[NSNumber alloc] initWithBool:[self autoanswerCalls]];
	[dict setObject:number forKey:XMKey_AutoanswerCalls];
	[number release];
	
	integer = [self bandwidthLimit];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_BandwidthLimit];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self useIPAddressTranslation]];
	[dict setObject:number forKey:XMKey_UseIPAddressTranslation];
	[number release];
	
	obj = [self externalIPAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_ExternalIPAddress];
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
		[arr addObject:[(XMCodecListEntry *)[audioCodecPreferenceList objectAtIndex:i] dictionaryRepresentation]];
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
		[arr addObject:[(XMCodecListEntry *)[videoCodecPreferenceList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_VideoCodecPreferenceList];
	[arr release];
	
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
	
	obj = [self h323GatekeeperHost];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_H323_GatekeeperHost];
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

#pragma mark Location & behaviour-specific Methods

- (BOOL)autoanswerCalls
{
	return autoanswerCalls;
}

- (void)setAutoanswerCalls:(BOOL)flag
{
	autoanswerCalls = flag;
}

- (unsigned)bandwidthLimit
{
	return bandwidthLimit;
}

- (void)setBandwidthLimit:(unsigned)limit
{
	bandwidthLimit = limit;
}

- (BOOL)useIPAddressTranslation
{
	return useIPAddressTranslation;
}

- (void)setUseIPAddressTranslation:(BOOL)flag
{
	useIPAddressTranslation = flag;
}

- (NSString *)externalIPAddress
{
	return externalIPAddress;
}

- (void)setExternalIPAddress:(NSString *)string
{
	if(string != externalIPAddress)
	{
		NSString *old = externalIPAddress;
		externalIPAddress = [string copy];
		[old release];
	}
}

#pragma mark Port-specific Methods

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

- (NSArray *)_audioCodecPreferenceList
{
	return audioCodecPreferenceList;
}

- (void)_setAudioCodecPreferenceList:(NSArray *)list
{
	if(list != audioCodecPreferenceList)
	{
		NSArray *old = audioCodecPreferenceList;
		audioCodecPreferenceList = [list mutableCopy];
		[old release];
	}
}

- (unsigned)audioCodecPreferenceListCount
{
	return [audioCodecPreferenceList count];
}

- (XMCodecListEntry *)audioCodecPreferenceListEntryAtIndex:(unsigned)index
{
	return (XMCodecListEntry *)[audioCodecPreferenceList objectAtIndex:index];
}

- (void)audioCodecPreferenceListExchangeEntryAtIndex:(unsigned)index1 withEntryAtIndex:(unsigned)index2
{
	[audioCodecPreferenceList exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)audioCodecPreferenceListAddEntry:(XMCodecListEntry *)entry
{
	[audioCodecPreferenceList addObject:entry];
}

- (void)audioCodecPreferenceListRemoveEntryAtIndex:(unsigned)index
{
	[audioCodecPreferenceList removeObjectAtIndex:index];
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

- (NSArray *)_videoCodecPreferenceList
{
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

- (unsigned)videoCodecPreferenceListCount
{
	return [videoCodecPreferenceList count];
}

- (XMCodecListEntry *)videoCodecPreferenceListEntryAtIndex:(unsigned)index
{
	return (XMCodecListEntry *)[videoCodecPreferenceList objectAtIndex:index];
}

- (void)videoCodecPreferenceListExchangeEntryAtIndex:(unsigned)index1 withEntryAtIndex:(unsigned)index2
{
	[videoCodecPreferenceList exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (void)videoCodecPreferenceListAddEntry:(XMCodecListEntry *)entry
{
	[videoCodecPreferenceList addObject:entry];
}

- (void)videoCodecPreferenceListRemoveEntryAtIndex:(unsigned)index
{
	[videoCodecPreferenceList removeObjectAtIndex:index];
}

#pragma mark H.323-specific Methods

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

- (NSString *)h323GatekeeperHost
{
	return h323_GatekeeperHost;
}

- (void)setH323GatekeeperHost:(NSString *)host
{
	if(host != h323_GatekeeperHost)
	{
		NSString *old = h323_GatekeeperHost;
		h323_GatekeeperHost = [host copy];
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
}

- (BOOL)setH323GatekeeperPassword:(NSString *)password
{
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
}

@end

@implementation XMCodecListEntry

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
	NSLog(@"copying XMCodecListEntry");
	return [[XMCodecListEntry allocWithZone:zone] initWithKey:[self key] isEnabled:[self isEnabled]];
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
	XMCodecListEntry *entry;
	
	if(object == self)
	{
		return YES;
	}
	
	if(![object isKindOfClass:[self class]])
	{
		return NO;
	}
	entry = (XMCodecListEntry *)object;
	
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
