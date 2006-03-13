/*
 * $Id: XMPreferences.m,v 1.14 2006/03/13 23:46:23 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMPreferences.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMCodecManager.h"

@interface XMPreferences (PrivateMethods)

- (NSMutableArray *)_audioCodecList;
- (void)_setAudioCodecList:(NSArray *)arr;

- (NSMutableArray *)_videoCodecList;
- (void)_setVideoCodecList:(NSArray *)arr;

@end

@implementation XMPreferences

#pragma mark -
#pragma mark Framework Methods

+ (XM_VALUE_TEST_RESULT)_checkValue:(id)value forKey:(NSString *)key
{
	XM_VALUE_TEST_RESULT result;
	
	if([key isEqualToString:XMKey_PreferencesUserName])
	{
		if([value isKindOfClass:[NSString class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesAutomaticallyAcceptIncomingCalls])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesBandwidthLimit])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesUseAddressTranslation])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesExternalAddress])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesTCPPortBase])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesTCPPortMax])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesUDPPortBase])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesUDPPortMax])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesAudioBufferSize])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableVideo])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesVideoFramesPerSecond])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH323])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH245Tunnel])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableFastStart])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperAddress])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperUsername])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperPhoneNumber])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableSIP])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarHosts])
	{
		if(value == nil || [value isKindOfClass:[NSArray class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarUsernames])
	{
		if(value == nil || [value isKindOfClass:[NSArray class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else
	{
		result = XM_INVALID_KEY;
	}
	
	return result;
}

- (BOOL)_value:(id)value differsFromPropertyWithKey:(NSString *)key
{
	id storedValue = [self valueForKey:key];
	
	if([value isEqual:storedValue])
	{
		return NO;
	}
	return YES;
}

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	userName = nil;
	automaticallyAcceptIncomingCalls = NO;
	
	bandwidthLimit = 0;
	useAddressTranslation = NO;
	externalAddress = nil;
	tcpPortBase = 30000;
	tcpPortMax = 30010;
	udpPortBase = 5000;
	udpPortMax = 5099;
	
	audioBufferSize = 2;
	
	unsigned audioCodecCount = [_XMCodecManagerSharedInstance audioCodecCount];
	audioCodecList = [[NSMutableArray alloc] initWithCapacity:audioCodecCount];
	unsigned i;
	for(i = 0; i < audioCodecCount; i++)
	{
		XMCodec *audioCodec = [_XMCodecManagerSharedInstance audioCodecAtIndex:i];
		XMCodecIdentifier identifier = [audioCodec identifier];
		XMPreferencesCodecListRecord *record = [[XMPreferencesCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
		[audioCodecList addObject:record];
		[record release];
	}
	
	enableVideo = NO;
	videoFramesPerSecond = 30;
	
	unsigned videoCodecCount = [_XMCodecManagerSharedInstance videoCodecCount];
	videoCodecList = [[NSMutableArray alloc] initWithCapacity:videoCodecCount];
	for(i = 0; i < videoCodecCount; i++)
	{
		XMCodec *videoCodec = [_XMCodecManagerSharedInstance videoCodecAtIndex:i];
		XMCodecIdentifier identifier = [videoCodec identifier];
		XMPreferencesCodecListRecord *record = [[XMPreferencesCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
		[videoCodecList addObject:record];
		[record release];
	}
	
	enableH264LimitedMode = NO;
	
	enableH323 = NO;
	enableH245Tunnel = NO;
	enableFastStart = NO;
	gatekeeperAddress = nil;
	gatekeeperUsername = nil;
	gatekeeperPhoneNumber = nil;
	
	enableSIP = NO;
	registrarHosts = [[NSArray alloc] init];
	registrarUsernames = [[NSArray alloc] init];

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [self init];
	
	obj = [dict objectForKey:XMKey_PreferencesUserName];
	if(obj)
	{
		[self setUserName:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls];
	if(obj)
	{
		[self setAutomaticallyAcceptIncomingCalls:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesBandwidthLimit];
	if(obj)
	{
		[self setBandwidthLimit:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUseAddressTranslation];
	if(obj)
	{
		[self setUseAddressTranslation:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesExternalAddress];
	if(obj)
	{
		[self setExternalAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesTCPPortBase];
	if(obj)
	{
		[self setTCPPortBase:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesTCPPortMax];
	if(obj)
	{
		[self setTCPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUDPPortBase];
	if(obj)
	{
		[self setUDPPortBase:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUDPPortMax];
	if(obj)
	{
		[self setUDPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesAudioBufferSize];
	if(obj)
	{
		[self setAudioBufferSize:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesAudioCodecList];
	if(obj)
	{
		NSArray *arr = (NSArray *)obj;
		unsigned count = [arr count];
		unsigned audioCodecCount = [audioCodecList count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
			XMPreferencesCodecListRecord *record = [[XMPreferencesCodecListRecord alloc] _initWithDictionary:dict];
			
			unsigned j;
			for(j = 0; j < audioCodecCount; j++)
			{
				XMPreferencesCodecListRecord *audioCodecRecord = (XMPreferencesCodecListRecord *)[audioCodecList objectAtIndex:j];
				
				if([record identifier] == [audioCodecRecord identifier])
				{
					[audioCodecList exchangeObjectAtIndex:i withObjectAtIndex:j];
					[audioCodecRecord setEnabled:[record isEnabled]];
					break;
				}
			}
			
			[record release];
		}
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableVideo];
	if(obj)
	{
		[self setEnableVideo:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesVideoFramesPerSecond];
	if(obj)
	{
		[self setVideoFramesPerSecond:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesVideoCodecList];
	if(obj)
	{
		NSArray *arr = (NSArray *)obj;
		unsigned count = [arr count];
		unsigned videoCodecCount = [videoCodecList count];
		unsigned i;
		
		for(i = 0; i < count; i++)
		{
			NSDictionary *dict = (NSDictionary *)[arr objectAtIndex:i];
			XMPreferencesCodecListRecord *record = [[XMPreferencesCodecListRecord alloc] _initWithDictionary:dict];
			
			unsigned j;
			for(j = 0; j < videoCodecCount; j++)
			{
				XMPreferencesCodecListRecord *videoCodecRecord = (XMPreferencesCodecListRecord *)[videoCodecList objectAtIndex:j];
				
				if([record identifier] == [videoCodecRecord identifier])
				{
					[videoCodecList exchangeObjectAtIndex:i withObjectAtIndex:j];
					[videoCodecRecord setEnabled:[record isEnabled]];
					break;
				}
			}
			
			[record release];
		}
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableH264LimitedMode];
	if(obj)
	{
		[self setEnableH264LimitedMode:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableH323];
	if(obj)
	{
		[self setEnableH323:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableH245Tunnel];
	if(obj)
	{
		[self setEnableH245Tunnel:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableFastStart];
	if(obj)
	{
		[self setEnableFastStart:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperAddress];
	if(obj)
	{
		[self setGatekeeperAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperUsername];
	if(obj)
	{
		[self setGatekeeperUsername:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperPhoneNumber];
	if(obj)
	{
		[self setGatekeeperPhoneNumber:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableSIP];
	if(obj)
	{
		[self setEnableSIP:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesRegistrarHosts];
	if(obj)
	{
		[self setRegistrarHosts:(NSArray *)obj];
	}
	else
	{
		[self setRegistrarHosts:[NSArray array]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesRegistrarUsernames];
	if(obj)
	{
		[self setRegistrarUsernames:(NSArray *)obj];
	}
	else
	{
		[self setRegistrarUsernames:[NSArray array]];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMPreferences *preferences = [[[self class] allocWithZone:zone] init];
	
	[preferences setUserName:[self userName]];
	[preferences setAutomaticallyAcceptIncomingCalls:[self automaticallyAcceptIncomingCalls]];
	
	[preferences setBandwidthLimit:[self bandwidthLimit]];
	[preferences setUseAddressTranslation:[self useAddressTranslation]];
	[preferences setExternalAddress:[self externalAddress]];
	[preferences setTCPPortBase:[self tcpPortBase]];
	[preferences setTCPPortMax:[self tcpPortMax]];
	[preferences setUDPPortBase:[self udpPortBase]];
	[preferences setUDPPortMax:[self udpPortMax]];
	
	[preferences setAudioBufferSize:[self audioBufferSize]];
	[preferences _setAudioCodecList:[self _audioCodecList]];
	
	[preferences setEnableVideo:[self enableVideo]];
	[preferences setVideoFramesPerSecond:[self videoFramesPerSecond]];
	[preferences _setVideoCodecList:[self _videoCodecList]];
	[preferences setEnableH264LimitedMode:[self enableH264LimitedMode]];
	
	[preferences setEnableH323:[self enableH323]];
	[preferences setEnableH245Tunnel:[self enableH245Tunnel]];
	[preferences setEnableFastStart:[self enableFastStart]];
	[preferences setGatekeeperAddress:[self gatekeeperAddress]];
	[preferences setGatekeeperUsername:[self gatekeeperUsername]];
	[preferences setGatekeeperPhoneNumber:[self gatekeeperPhoneNumber]];
	
	[preferences setEnableSIP:[self enableSIP]];
	[preferences setRegistrarHosts:[self registrarHosts]];
	[preferences setRegistrarUsernames:[self registrarUsernames]];

	return preferences;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
	
	if([coder allowsKeyedCoding]) // use keyed coding
	{
		NSArray *array;
		unsigned count, codecCount, i;
		
		[self setUserName:[coder decodeObjectForKey:XMKey_PreferencesUserName]];
		[self setAutomaticallyAcceptIncomingCalls:[coder decodeBoolForKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls]];
		[self setBandwidthLimit:[coder decodeIntForKey:XMKey_PreferencesBandwidthLimit]];
		[self setUseAddressTranslation:[coder decodeBoolForKey:XMKey_PreferencesUseAddressTranslation]];
		[self setExternalAddress:[coder decodeObjectForKey:XMKey_PreferencesExternalAddress]];
		[self setTCPPortBase:[coder decodeIntForKey:XMKey_PreferencesTCPPortBase]];
		[self setTCPPortMax:[coder decodeIntForKey:XMKey_PreferencesTCPPortMax]];
		[self setUDPPortBase:[coder decodeIntForKey:XMKey_PreferencesUDPPortBase]];
		[self setUDPPortMax:[coder decodeIntForKey:XMKey_PreferencesUDPPortMax]];
		
		[self setAudioBufferSize:[coder decodeIntForKey:XMKey_PreferencesAudioBufferSize]];
		
		array = (NSArray *)[coder decodeObjectForKey:XMKey_PreferencesAudioCodecList];
		count = [array count];
		codecCount = [audioCodecList count];
		
		for(i = 0; i < count; i++)
		{
			XMPreferencesCodecListRecord *record = (XMPreferencesCodecListRecord *)[array objectAtIndex:i];
			
			unsigned j;
			for(j = 0; j < codecCount; j++)
			{
				XMPreferencesCodecListRecord *audioCodecRecord = (XMPreferencesCodecListRecord *)[audioCodecList objectAtIndex:j];
				
				if([audioCodecRecord identifier] == [record identifier])
				{
					[audioCodecRecord setEnabled:[record isEnabled]];
					[audioCodecList exchangeObjectAtIndex:i withObjectAtIndex:j];
					break;
				}
			}
		}
		
		[self setEnableVideo:[coder decodeBoolForKey:XMKey_PreferencesEnableVideo]];
		[self setVideoFramesPerSecond:[coder decodeIntForKey:XMKey_PreferencesVideoFramesPerSecond]];
		
		array = (NSArray *)[coder decodeObjectForKey:XMKey_PreferencesVideoCodecList];
		count = [array count];
		codecCount = [videoCodecList count];
		
		for(i = 0; i < count; i++)
		{
			XMPreferencesCodecListRecord *record = (XMPreferencesCodecListRecord *)[array objectAtIndex:i];
			
			unsigned j;
			for(j = 0; j < codecCount; j++)
			{
				XMPreferencesCodecListRecord *videoCodecRecord = (XMPreferencesCodecListRecord *)[videoCodecList objectAtIndex:j];
				
				if([videoCodecRecord identifier] == [record identifier])
				{
					[videoCodecRecord setEnabled:[record isEnabled]];
					[videoCodecList exchangeObjectAtIndex:i withObjectAtIndex:j];
					break;
				}
			}
		}
		
		[self setEnableH264LimitedMode:[coder decodeBoolForKey:XMKey_PreferencesEnableH264LimitedMode]];
		
		[self setEnableH323:[coder decodeBoolForKey:XMKey_PreferencesEnableH323]];
		[self setEnableH245Tunnel:[coder decodeBoolForKey:XMKey_PreferencesEnableH245Tunnel]];
		[self setEnableFastStart:[coder decodeBoolForKey:XMKey_PreferencesEnableFastStart]];
		[self setGatekeeperAddress:[coder decodeObjectForKey:XMKey_PreferencesGatekeeperAddress]];
		[self setGatekeeperUsername:[coder decodeObjectForKey:XMKey_PreferencesGatekeeperUsername]];
		[self setGatekeeperPhoneNumber:[coder decodeObjectForKey:XMKey_PreferencesGatekeeperPhoneNumber]];
		
		[self setEnableSIP:[coder decodeBoolForKey:XMKey_PreferencesEnableSIP]];
		[self setRegistrarHosts:[coder decodeObjectForKey:XMKey_PreferencesRegistrarHosts]];
		[self setRegistrarUsernames:[coder decodeObjectForKey:XMKey_PreferencesRegistrarUsernames]];
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
		[coder encodeObject:[self userName] forKey:XMKey_PreferencesUserName];
		[coder encodeBool:[self automaticallyAcceptIncomingCalls] forKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls];
		
		[coder encodeInt:[self bandwidthLimit] forKey:XMKey_PreferencesBandwidthLimit];
		[coder encodeBool:[self useAddressTranslation] forKey:XMKey_PreferencesUseAddressTranslation];
		[coder encodeObject:[self externalAddress] forKey:XMKey_PreferencesExternalAddress];
		[coder encodeInt:[self tcpPortBase] forKey:XMKey_PreferencesTCPPortBase];
		[coder encodeInt:[self tcpPortMax] forKey:XMKey_PreferencesTCPPortMax];
		[coder encodeInt:[self udpPortBase] forKey:XMKey_PreferencesUDPPortBase];
		[coder encodeInt:[self udpPortMax] forKey:XMKey_PreferencesUDPPortMax];
		
		[coder encodeInt:[self audioBufferSize] forKey:XMKey_PreferencesAudioBufferSize];
		[coder encodeObject:[self _audioCodecList] forKey:XMKey_PreferencesAudioCodecList];
		
		[coder encodeBool:[self enableVideo] forKey:XMKey_PreferencesEnableVideo];
		[coder encodeInt:[self videoFramesPerSecond] forKey:XMKey_PreferencesVideoFramesPerSecond];
		[coder encodeObject:[self _videoCodecList] forKey:XMKey_PreferencesVideoCodecList];
		[coder encodeBool:[self enableH264LimitedMode] forKey:XMKey_PreferencesEnableH264LimitedMode];
		
		[coder encodeBool:[self enableH323] forKey:XMKey_PreferencesEnableH323];
		[coder encodeBool:[self enableH245Tunnel] forKey:XMKey_PreferencesEnableH245Tunnel];
		[coder encodeBool:[self enableFastStart] forKey:XMKey_PreferencesEnableFastStart];
		[coder encodeObject:[self gatekeeperAddress] forKey:XMKey_PreferencesGatekeeperAddress];
		[coder encodeObject:[self gatekeeperUsername] forKey:XMKey_PreferencesGatekeeperUsername];
		[coder encodeObject:[self gatekeeperPhoneNumber] forKey:XMKey_PreferencesGatekeeperPhoneNumber];
		
		[coder encodeBool:[self enableSIP] forKey:XMKey_PreferencesEnableSIP];
		[coder encodeObject:[self registrarHosts] forKey:XMKey_PreferencesRegistrarHosts];
		[coder encodeObject:[self registrarUsernames] forKey:XMKey_PreferencesRegistrarUsernames];
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
	
	[audioCodecList release];
	[videoCodecList release];
	
	[gatekeeperAddress release];
	[gatekeeperUsername release];
	[gatekeeperPhoneNumber release];
	
	[registrarHosts release];
	[registrarUsernames release];
	
	[super dealloc];
}

#pragma mark -
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
	   [otherPreferences automaticallyAcceptIncomingCalls] == [self automaticallyAcceptIncomingCalls] &&
	   [otherPreferences bandwidthLimit] == [self bandwidthLimit] &&
	   [otherPreferences useAddressTranslation] == [self useAddressTranslation] &&
	   [[otherPreferences externalAddress] isEqualToString:[self externalAddress]] &&
	   [otherPreferences tcpPortBase] == [self tcpPortBase] &&
	   [otherPreferences tcpPortMax] == [self tcpPortMax] &&
	   [otherPreferences udpPortBase] == [self udpPortBase] &&
	   [otherPreferences udpPortMax] == [self udpPortMax] &&
	   
	   [otherPreferences audioBufferSize] == [self audioBufferSize] &&
	   [[otherPreferences _audioCodecList] isEqual:[self _audioCodecList]] &&
	   
	   [otherPreferences enableVideo] == [self enableVideo] &&
	   [otherPreferences videoFramesPerSecond] == [self videoFramesPerSecond] &&
	   [[otherPreferences _videoCodecList] isEqual:[self _videoCodecList]] &&
	   [otherPreferences enableH264LimitedMode] == [self enableH264LimitedMode] &&

	   [otherPreferences enableH323] == [self enableH323] &&
	   [otherPreferences enableH245Tunnel] == [self enableH245Tunnel] &&
	   [otherPreferences enableFastStart] == [self enableFastStart] &&
	   [[otherPreferences gatekeeperAddress] isEqualToString:[self gatekeeperAddress]] &&
	   [[otherPreferences gatekeeperUsername] isEqualToString:[self gatekeeperUsername]] &&
	   [[otherPreferences gatekeeperPhoneNumber] isEqualToString:[self gatekeeperPhoneNumber]] &&
	   
	   [otherPreferences enableSIP] == [self enableSIP] &&
	   [[otherPreferences registrarHosts] isEqualToArray:[self registrarHosts]] &&
	   [[otherPreferences registrarUsernames] isEqualToArray:[self registrarUsernames]])
	{
		return YES;
	}
	
	return NO;
}

#pragma mark -
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
		[dict setObject:obj forKey:XMKey_PreferencesUserName];
	}
	
	number = [[NSNumber alloc] initWithBool:[self automaticallyAcceptIncomingCalls]];
	[dict setObject:number forKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls];
	[number release];
	
	integer = [self bandwidthLimit];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesBandwidthLimit];
		[number release];
	}
	
	number = [[NSNumber alloc] initWithBool:[self useAddressTranslation]];
	[dict setObject:number forKey:XMKey_PreferencesUseAddressTranslation];
	[number release];
	
	obj = [self externalAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesExternalAddress];
	}
	
	integer = [self tcpPortBase];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesTCPPortBase];
		[number release];
	}
	integer = [self tcpPortMax];
	if(integer != UINT_MAX)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesTCPPortMax];
		[number release];
	}
	integer = [self udpPortBase];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesUDPPortBase];
		[number release];
	}
	integer = [self udpPortMax];
	if(integer != UINT_MAX)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesUDPPortMax];
		[number release];
	}
	
	integer = [self audioBufferSize];
	if(integer != 2)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesAudioBufferSize];
		[number release];
	}
	
	integer = [audioCodecList count];
	int i;
	NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMPreferencesCodecListRecord *)[audioCodecList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_PreferencesAudioCodecList];
	[arr release];
	
	number = [[NSNumber alloc] initWithBool:[self enableVideo]];
	[dict setObject:number forKey:XMKey_PreferencesEnableVideo];
	[number release];
	
	integer = [self videoFramesPerSecond];
	if(integer != 0)
	{
		number = [[NSNumber alloc] initWithUnsignedInt:integer];
		[dict setObject:number forKey:XMKey_PreferencesVideoFramesPerSecond];
		[number release];
	}
		
	integer = [videoCodecList count];
	arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMPreferencesCodecListRecord *)[videoCodecList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_PreferencesVideoCodecList];
	[arr release];
	
	number = [[NSNumber alloc] initWithBool:[self enableH264LimitedMode]];
	[dict setObject:number forKey:XMKey_PreferencesEnableH264LimitedMode];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableH323]];
	[dict setObject:number forKey:XMKey_PreferencesEnableH323];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableH245Tunnel]];
	[dict setObject:number forKey:XMKey_PreferencesEnableH245Tunnel];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableFastStart]];
	[dict setObject:number forKey:XMKey_PreferencesEnableFastStart];
	[number release];
	
	obj = [self gatekeeperAddress];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesGatekeeperAddress];
	}
	
	obj = [self gatekeeperUsername];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesGatekeeperUsername];
	}
	
	obj = [self gatekeeperPhoneNumber];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesGatekeeperPhoneNumber];
	}
	
	number = [[NSNumber alloc] initWithBool:[self enableSIP]];
	[dict setObject:number forKey:XMKey_PreferencesEnableSIP];
	[number release];
	
	obj = [self registrarHosts];
	if([(NSArray *)obj count] != 0)
	{
		[dict setObject:obj forKey:XMKey_PreferencesRegistrarHosts];
	}
	
	obj = [self registrarUsernames];
	if([(NSArray *)obj count] != 0)
	{
		[dict setObject:obj forKey:XMKey_PreferencesRegistrarUsernames];
	}
	
	return dict;
}

#pragma mark -
#pragma mark Accesssing values through keys

- (id)valueForKey:(NSString *)key
{
	if([key isEqualToString:XMKey_PreferencesUserName])
	{
		return [self userName];
	}
	else if([key isEqualToString:XMKey_PreferencesAutomaticallyAcceptIncomingCalls])
	{
		return [NSNumber numberWithBool:[self automaticallyAcceptIncomingCalls]];
	}
	else if([key isEqualToString:XMKey_PreferencesBandwidthLimit])
	{
		return [NSNumber numberWithUnsignedInt:[self bandwidthLimit]];
	}
	else if([key isEqualToString:XMKey_PreferencesUseAddressTranslation])
	{
		return [NSNumber numberWithBool:[self useAddressTranslation]];
	}
	else if([key isEqualToString:XMKey_PreferencesExternalAddress])
	{
		return [self externalAddress];
	}
	else if([key isEqualToString:XMKey_PreferencesTCPPortBase])
	{
		return [NSNumber numberWithUnsignedInt:[self tcpPortBase]];
	}
	else if([key isEqualToString:XMKey_PreferencesTCPPortMax])
	{
		return [NSNumber numberWithUnsignedInt:[self tcpPortMax]];
	}
	else if([key isEqualToString:XMKey_PreferencesUDPPortBase])
	{
		return [NSNumber numberWithUnsignedInt:[self udpPortBase]];
	}
	else if([key isEqualToString:XMKey_PreferencesUDPPortMax])
	{
		return [NSNumber numberWithUnsignedInt:[self udpPortMax]];
	}
	else if([key isEqualToString:XMKey_PreferencesAudioBufferSize])
	{
		return [NSNumber numberWithUnsignedInt:[self audioBufferSize]];
	}
	else if([key isEqualToString:XMKey_PreferencesAudioCodecList])
	{
		return [self audioCodecList];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableVideo])
	{
		return [NSNumber numberWithBool:[self enableVideo]];
	}
	else if([key isEqualToString:XMKey_PreferencesVideoFramesPerSecond])
	{
		return [NSNumber numberWithUnsignedInt:[self videoFramesPerSecond]];
	}
	else if([key isEqualToString:XMKey_PreferencesVideoCodecList])
	{
		return [self videoCodecList];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH264LimitedMode])
	{
		return [NSNumber numberWithBool:[self enableH264LimitedMode]];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH323])
	{
		return [NSNumber numberWithBool:[self enableH323]];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH245Tunnel])
	{
		return [NSNumber numberWithBool:[self enableH245Tunnel]];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableFastStart])
	{
		return [NSNumber numberWithBool:[self enableFastStart]];
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperAddress])
	{
		return [self gatekeeperAddress];
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperUsername])
	{
		return [self gatekeeperUsername];
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperPhoneNumber])
	{
		return [self gatekeeperPhoneNumber];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableSIP])
	{
		return [NSNumber numberWithBool:[self enableSIP]];
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarHosts])
	{
		return [self registrarHosts];
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarUsernames])
	{
		return [self registrarUsernames];
	}
	
	return nil;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL correctType = YES;
	
	if([key isEqualToString:XMKey_PreferencesUserName])
	{
		if([value isKindOfClass:[NSString class]])
		{
			[self setUserName:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesAutomaticallyAcceptIncomingCalls])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setAutomaticallyAcceptIncomingCalls:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesBandwidthLimit])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setBandwidthLimit:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesUseAddressTranslation])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setUseAddressTranslation:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesExternalAddress])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setExternalAddress:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesTCPPortBase])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setTCPPortBase:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesTCPPortMax])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setTCPPortMax:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesUDPPortBase])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setUDPPortBase:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesUDPPortMax])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setUDPPortMax:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesAudioBufferSize])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setAudioBufferSize:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableVideo])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableVideo:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesVideoFramesPerSecond])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setVideoFramesPerSecond:[(NSNumber *)value unsignedIntValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH264LimitedMode])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableH264LimitedMode:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH323])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableH323:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableH245Tunnel])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableH245Tunnel:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableFastStart])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableFastStart:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperAddress])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setGatekeeperAddress:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperUsername])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setGatekeeperUsername:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesGatekeeperPhoneNumber])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setGatekeeperPhoneNumber:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableSIP])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableSIP:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarHosts])
	{
		if([value isKindOfClass:[NSArray class]])
		{
			[self setRegistrarHosts:(NSArray *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarUsernames])
	{
		if([value isKindOfClass:[NSArray class]])
		{
			[self setRegistrarUsernames:(NSArray *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else
	{
		[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeValidKey];
	}
	
	if(correctType == NO)
	{
		[NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeOfCorrectType];
	}
}

#pragma mark -
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

- (BOOL)automaticallyAcceptIncomingCalls;
{
	return automaticallyAcceptIncomingCalls;
}

- (void)setAutomaticallyAcceptIncomingCalls:(BOOL)flag
{
	automaticallyAcceptIncomingCalls = flag;
}

#pragma mark -
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

#pragma mark -
#pragma mark Audio-specific Methods

- (unsigned)audioBufferSize
{
	return audioBufferSize;
}

- (void)setAudioBufferSize:(unsigned)size
{
	audioBufferSize = size;
}

- (NSArray *)audioCodecList
{
	return audioCodecList;
}

- (unsigned)audioCodecListCount
{
	return [[self _audioCodecList] count];
}

- (XMPreferencesCodecListRecord *)audioCodecListRecordAtIndex:(unsigned)index
{
	return (XMPreferencesCodecListRecord *)[[self _audioCodecList] objectAtIndex:index];
}

- (void)audioCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2
{
	[[self _audioCodecList] exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

#pragma mark -
#pragma mark Video-specific Methods

- (BOOL)enableVideo
{
	return enableVideo;
}

- (void)setEnableVideo:(BOOL)flag
{
	enableVideo = flag;
}

- (unsigned)videoFramesPerSecond
{
	return videoFramesPerSecond;
}

- (void)setVideoFramesPerSecond:(unsigned)value
{
	videoFramesPerSecond = value;
}

- (NSArray *)videoCodecList
{
	return videoCodecList;
}

- (unsigned)videoCodecListCount
{
	return [[self _videoCodecList] count];
}

- (XMPreferencesCodecListRecord *)videoCodecListRecordAtIndex:(unsigned)index
{
	return (XMPreferencesCodecListRecord *)[[self _videoCodecList] objectAtIndex:index];
}

- (void)videoCodecListExchangeRecordAtIndex:(unsigned)index1 withRecordAtIndex:(unsigned)index2
{
	[[self _videoCodecList] exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}

- (BOOL)enableH264LimitedMode
{
	return enableH264LimitedMode;
}

- (void)setEnableH264LimitedMode:(BOOL)flag
{
	enableH264LimitedMode = flag;
}

#pragma mark -
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

- (BOOL)usesGatekeeper
{
	if([self gatekeeperAddress] != nil &&
	   ([self gatekeeperUsername] != nil || [self gatekeeperPhoneNumber] != nil))
	{
		return YES;
	}
	return NO;
}

- (NSString *)gatekeeperPassword
{
	return nil;
}

#pragma mark -
#pragma mark SIP Methods

- (BOOL)enableSIP
{
	return enableSIP;
}

- (void)setEnableSIP:(BOOL)flag
{
	enableSIP = flag;
}

- (NSArray *)registrarHosts
{
	return registrarHosts;
}

- (void)setRegistrarHosts:(NSArray *)hosts
{
	if(registrarHosts != hosts)
	{
		NSArray *old = registrarHosts;
		registrarHosts = [hosts copy];
		[old release];
	}
}

- (NSArray *)registrarUsernames
{
	return registrarUsernames;
}

- (void)setRegistrarUsernames:(NSArray *)usernames
{
	if(registrarUsernames != usernames)
	{
		NSArray *old = registrarUsernames;
		registrarUsernames = [usernames  copy];
		[old release];
	}
}

- (BOOL)usesRegistrars
{
	if([[self registrarHosts] count] != 0 &&
	   [[self registrarUsernames] count] != 0)
	{
		return YES;
	}
	return NO;
}

- (NSArray *)registrarPasswords
{
	unsigned count = [[self registrarHosts] count];
	unsigned i;
	
	NSMutableArray *pwds = [NSMutableArray arrayWithCapacity:count];
	
	for(i = 0; i < count; i++)
	{
		[pwds addObject:[NSNull null]];
	}
	
	return pwds;
}

#pragma mark -
#pragma mark Private Methods

- (NSMutableArray *)_audioCodecList
{
	return audioCodecList;
}

- (void)_setAudioCodecList:(NSArray *)list
{	
	unsigned count = [list count];
	unsigned i;
	unsigned audioCodecListCount = [audioCodecList count];
	for(i = 0; i < count; i++)
	{
		XMPreferencesCodecListRecord *record = (XMPreferencesCodecListRecord *)[list objectAtIndex:i];
		
		unsigned j;
		for(j = 0; j < audioCodecListCount; j++)
		{
			XMPreferencesCodecListRecord *audioCodecRecord = (XMPreferencesCodecListRecord *)[audioCodecList objectAtIndex:j];
			if([record identifier] == [audioCodecRecord identifier])
			{
				[audioCodecRecord setEnabled:[record isEnabled]];
				[audioCodecList exchangeObjectAtIndex:i withObjectAtIndex:j];
				break;
			}
		}
	}
}

- (NSMutableArray *)_videoCodecList
{
	return videoCodecList;
}

- (void)_setVideoCodecList:(NSArray *)list
{
	unsigned count = [list count];
	unsigned i;
	unsigned videoCodecListCount = [videoCodecList count];
	for(i = 0; i < count; i++)
	{
		XMPreferencesCodecListRecord *record = (XMPreferencesCodecListRecord *)[list objectAtIndex:i];
		
		unsigned j;
		for(j = 0; j < videoCodecListCount; j++)
		{
			XMPreferencesCodecListRecord *videoCodecRecord = (XMPreferencesCodecListRecord *)[videoCodecList objectAtIndex:j];
			if([record identifier] == [videoCodecRecord identifier])
			{
				[videoCodecRecord setEnabled:[record isEnabled]];
				[videoCodecList exchangeObjectAtIndex:i withObjectAtIndex:j];
				break;
			}
		}
	}
}

@end