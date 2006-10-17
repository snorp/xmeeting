/*
 * $Id: XMPreferences.m,v 1.17 2006/10/17 21:07:30 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMPreferences.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMPreferencesRegistrarRecord.h"
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
	else if([key isEqualToString:XMKey_PreferencesUseSTUN])
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
	else if([key isEqualToString:XMKey_PreferencesSTUNServer])
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
	else if([key isEqualToString:XMKey_PreferencesEnableSilenceSuppression])
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
	else if([key isEqualToString:XMKey_PreferencesEnableEchoCancellation])
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
	else if([key isEqualToString:XMKey_PreferencesGatekeeperPassword])
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
	else if([key isEqualToString:XMKey_PreferencesRegistrarRecords])
	{
		if([value isKindOfClass:[NSArray class]])
		{
			result = XM_VALID_VALUE;
		}
		else
		{
			result = XM_INVALID_VALUE_TYPE;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyHost])
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
	else if([key isEqualToString:XMKey_PreferencesSIPProxyUsername])
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
	else if([key isEqualToString:XMKey_PreferencesSIPProxyPassword])
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
	useSTUN = NO;
	stunServer = nil;
	useAddressTranslation = NO;
	externalAddress = nil;
	tcpPortBase = 30000;
	tcpPortMax = 30010;
	udpPortBase = 5000;
	udpPortMax = 5099;
	
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
	
	enableSilenceSuppression = NO;
	enableEchoCancellation = NO;
	
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
	gatekeeperPassword = nil;
	
	enableSIP = NO;
	registrarRecords = [[NSArray alloc] init];
	sipProxyHost = nil;
	sipProxyUsername = nil;
	sipProxyPassword = nil;

	return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	NSObject *obj;
	
	self = [self init];
	
	obj = [dict objectForKey:XMKey_PreferencesUserName];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setUserName:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setAutomaticallyAcceptIncomingCalls:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesBandwidthLimit];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setBandwidthLimit:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUseSTUN];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setUseSTUN:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesSTUNServer];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setSTUNServer:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUseAddressTranslation];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setUseAddressTranslation:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesExternalAddress];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setExternalAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesTCPPortBase];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setTCPPortBase:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesTCPPortMax];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setTCPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUDPPortBase];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setUDPPortBase:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesUDPPortMax];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setUDPPortMax:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesAudioCodecList];
	if(obj && [obj isKindOfClass:[NSArray class]])
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
	
	obj = [dict objectForKey:XMKey_PreferencesEnableSilenceSuppression];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableSilenceSuppression:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableEchoCancellation];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableEchoCancellation:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableVideo];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableVideo:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesVideoFramesPerSecond];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setVideoFramesPerSecond:[(NSNumber *)obj unsignedIntValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesVideoCodecList];
	if(obj && [obj isKindOfClass:[NSArray class]])
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
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableH264LimitedMode:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableH323];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableH323:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableH245Tunnel];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableH245Tunnel:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableFastStart];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableFastStart:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperAddress];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setGatekeeperAddress:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperUsername];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setGatekeeperUsername:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperPhoneNumber];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setGatekeeperPhoneNumber:(NSString *)obj];
	}
	obj = [dict objectForKey:XMKey_PreferencesGatekeeperPassword];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setGatekeeperPassword:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesEnableSIP];
	if(obj && [obj isKindOfClass:[NSNumber class]])
	{
		[self setEnableSIP:[(NSNumber *)obj boolValue]];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesRegistrarRecords];
	if(obj && [obj isKindOfClass:[NSArray class]])
	{
		[self setRegistrarRecords:(NSArray *)obj];
	}
	else
	{
		[self setRegistrarRecords:[NSArray array]];
	}
		
	obj = [dict objectForKey:XMKey_PreferencesSIPProxyHost];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setSIPProxyHost:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesSIPProxyUsername];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setSIPProxyUsername:(NSString *)obj];
	}
	
	obj = [dict objectForKey:XMKey_PreferencesSIPProxyPassword];
	if(obj && [obj isKindOfClass:[NSString class]])
	{
		[self setSIPProxyPassword:(NSString *)obj];
	}
	
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	XMPreferences *preferences = [[[self class] allocWithZone:zone] init];
	
	[preferences setUserName:[self userName]];
	[preferences setAutomaticallyAcceptIncomingCalls:[self automaticallyAcceptIncomingCalls]];
	
	[preferences setBandwidthLimit:[self bandwidthLimit]];
	[preferences setUseSTUN:[self useSTUN]];
	[preferences setSTUNServer:[self stunServer]];
	[preferences setUseAddressTranslation:[self useAddressTranslation]];
	[preferences setExternalAddress:[self externalAddress]];
	[preferences setTCPPortBase:[self tcpPortBase]];
	[preferences setTCPPortMax:[self tcpPortMax]];
	[preferences setUDPPortBase:[self udpPortBase]];
	[preferences setUDPPortMax:[self udpPortMax]];
	
	[preferences _setAudioCodecList:[self _audioCodecList]];
	[preferences setEnableSilenceSuppression:[self enableSilenceSuppression]];
	[preferences setEnableEchoCancellation:[self enableEchoCancellation]];
	
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
	[preferences setGatekeeperPassword:[self gatekeeperPassword]];
	
	[preferences setEnableSIP:[self enableSIP]];
	[preferences setRegistrarRecords:[self registrarRecords]];
	[preferences setSIPProxyHost:[self sipProxyHost]];
	[preferences setSIPProxyUsername:[self sipProxyUsername]];
	[preferences setSIPProxyPassword:[self sipProxyPassword]];

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
		[self setUseSTUN:[coder decodeBoolForKey:XMKey_PreferencesUseSTUN]];
		[self setSTUNServer:[coder decodeObjectForKey:XMKey_PreferencesSTUNServer]];
		[self setUseAddressTranslation:[coder decodeBoolForKey:XMKey_PreferencesUseAddressTranslation]];
		[self setExternalAddress:[coder decodeObjectForKey:XMKey_PreferencesExternalAddress]];
		[self setTCPPortBase:[coder decodeIntForKey:XMKey_PreferencesTCPPortBase]];
		[self setTCPPortMax:[coder decodeIntForKey:XMKey_PreferencesTCPPortMax]];
		[self setUDPPortBase:[coder decodeIntForKey:XMKey_PreferencesUDPPortBase]];
		[self setUDPPortMax:[coder decodeIntForKey:XMKey_PreferencesUDPPortMax]];
		
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
		
		[self setEnableSilenceSuppression:[coder decodeBoolForKey:XMKey_PreferencesEnableSilenceSuppression]];
		[self setEnableEchoCancellation:[coder decodeBoolForKey:XMKey_PreferencesEnableEchoCancellation]];
		
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
		[self setGatekeeperPassword:[coder decodeObjectForKey:XMKey_PreferencesGatekeeperPassword]];
		
		[self setEnableSIP:[coder decodeBoolForKey:XMKey_PreferencesEnableSIP]];
		[self setRegistrarRecords:[coder decodeObjectForKey:XMKey_PreferencesRegistrarRecords]];
		[self setSIPProxyHost:[coder decodeObjectForKey:XMKey_PreferencesSIPProxyHost]];
		[self setSIPProxyUsername:[coder decodeObjectForKey:XMKey_PreferencesSIPProxyUsername]];
		[self setSIPProxyPassword:[coder decodeObjectForKey:XMKey_PreferencesSIPProxyPassword]];
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
		[coder encodeBool:[self useSTUN] forKey:XMKey_PreferencesUseSTUN];
		[coder encodeObject:[self stunServer] forKey:XMKey_PreferencesSTUNServer];
		[coder encodeBool:[self useAddressTranslation] forKey:XMKey_PreferencesUseAddressTranslation];
		[coder encodeObject:[self externalAddress] forKey:XMKey_PreferencesExternalAddress];
		[coder encodeInt:[self tcpPortBase] forKey:XMKey_PreferencesTCPPortBase];
		[coder encodeInt:[self tcpPortMax] forKey:XMKey_PreferencesTCPPortMax];
		[coder encodeInt:[self udpPortBase] forKey:XMKey_PreferencesUDPPortBase];
		[coder encodeInt:[self udpPortMax] forKey:XMKey_PreferencesUDPPortMax];
		
		[coder encodeObject:[self _audioCodecList] forKey:XMKey_PreferencesAudioCodecList];
		[coder encodeBool:[self enableSilenceSuppression] forKey:XMKey_PreferencesEnableSilenceSuppression];
		[coder encodeBool:[self enableEchoCancellation] forKey:XMKey_PreferencesEnableEchoCancellation];
		
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
		[coder encodeObject:[self gatekeeperPassword] forKey:XMKey_PreferencesGatekeeperPassword];
		
		[coder encodeBool:[self enableSIP] forKey:XMKey_PreferencesEnableSIP];
		[coder encodeObject:[self registrarRecords] forKey:XMKey_PreferencesRegistrarRecords];
		[coder encodeObject:[self sipProxyHost] forKey:XMKey_PreferencesSIPProxyHost];
		[coder encodeObject:[self sipProxyUsername] forKey:XMKey_PreferencesSIPProxyUsername];
		[coder encodeObject:[self sipProxyPassword] forKey:XMKey_PreferencesSIPProxyPassword];
	}
	else // raise an exception
	{
		[NSException raise:XMException_UnsupportedCoder format:XMExceptionReason_UnsupportedCoder];
	}
}

- (void)dealloc
{
	[userName release];
	
	[stunServer release];
	[externalAddress release];
	
	[audioCodecList release];
	[videoCodecList release];
	
	[gatekeeperAddress release];
	[gatekeeperUsername release];
	[gatekeeperPhoneNumber release];
	[gatekeeperPassword release];
	
	[registrarRecords release];
	[sipProxyHost release];
	[sipProxyUsername release];
	[sipProxyPassword release];
	
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
	   [otherPreferences useSTUN] == [self useSTUN] &&
	   [[otherPreferences stunServer] isEqualToString:[self stunServer]] &&
	   [otherPreferences useAddressTranslation] == [self useAddressTranslation] &&
	   [[otherPreferences externalAddress] isEqualToString:[self externalAddress]] &&
	   [otherPreferences tcpPortBase] == [self tcpPortBase] &&
	   [otherPreferences tcpPortMax] == [self tcpPortMax] &&
	   [otherPreferences udpPortBase] == [self udpPortBase] &&
	   [otherPreferences udpPortMax] == [self udpPortMax] &&
	   
	   [[otherPreferences _audioCodecList] isEqual:[self _audioCodecList]] &&
	   [otherPreferences enableSilenceSuppression] == [self enableSilenceSuppression] &&
	   [otherPreferences enableEchoCancellation] == [self enableEchoCancellation] &&
	   
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
	   [[otherPreferences gatekeeperPassword] isEqualToString:[self gatekeeperPassword]] &&
	   
	   [otherPreferences enableSIP] == [self enableSIP] &&
	   [[otherPreferences registrarRecords] isEqualToArray:[self registrarRecords]] &&
	   [[otherPreferences sipProxyHost] isEqualToString:[self sipProxyHost]] &&
	   [[otherPreferences sipProxyUsername] isEqualToString:[self sipProxyUsername]] &&
	   [[otherPreferences sipProxyPassword] isEqualToString:[self sipProxyPassword]])
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
	
	number = [[NSNumber alloc] initWithBool:[self useSTUN]];
	[dict setObject:number forKey:XMKey_PreferencesUseSTUN];
	[number release];
	
	obj = [self stunServer];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesSTUNServer];
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
	
	integer = [audioCodecList count];
	int i;
	NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:integer];
	for(i = 0; i < integer; i++)
	{
		[arr addObject:[(XMPreferencesCodecListRecord *)[audioCodecList objectAtIndex:i] dictionaryRepresentation]];
	}
	[dict setObject:arr forKey:XMKey_PreferencesAudioCodecList];
	[arr release];
	
	number = [[NSNumber alloc] initWithBool:[self enableSilenceSuppression]];
	[dict setObject:number forKey:XMKey_PreferencesEnableSilenceSuppression];
	[number release];
	
	number = [[NSNumber alloc] initWithBool:[self enableEchoCancellation]];
	[dict setObject:number forKey:XMKey_PreferencesEnableEchoCancellation];
	[number release];
	
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
	
	obj = [self gatekeeperPassword];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesGatekeeperPassword];
	}
	
	number = [[NSNumber alloc] initWithBool:[self enableSIP]];
	[dict setObject:number forKey:XMKey_PreferencesEnableSIP];
	[number release];
	
	obj = [self registrarRecords];
	if([(NSArray *)obj count] != 0)
	{
		[dict setObject:obj forKey:XMKey_PreferencesRegistrarRecords];
	}
	
	obj = [self sipProxyHost];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesSIPProxyHost];
	}
	
	obj = [self sipProxyUsername];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesSIPProxyUsername];
	}
	
	obj = [self sipProxyPassword];
	if(obj)
	{
		[dict setObject:obj forKey:XMKey_PreferencesSIPProxyPassword];
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
	else if([key isEqualToString:XMKey_PreferencesUseSTUN])
	{
		return [NSNumber numberWithBool:[self useSTUN]];
	}
	else if([key isEqualToString:XMKey_PreferencesSTUNServer])
	{
		return [self stunServer];
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
	else if([key isEqualToString:XMKey_PreferencesAudioCodecList])
	{
		return [self audioCodecList];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableSilenceSuppression])
	{
		return [NSNumber numberWithBool:[self enableSilenceSuppression]];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableEchoCancellation])
	{
		return [NSNumber numberWithBool:[self enableEchoCancellation]];
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
	else if([key isEqualToString:XMKey_PreferencesGatekeeperPassword])
	{
		return [self gatekeeperPassword];
	}
	else if([key isEqualToString:XMKey_PreferencesEnableSIP])
	{
		return [NSNumber numberWithBool:[self enableSIP]];
	}
	else if([key isEqualToString:XMKey_PreferencesRegistrarRecords])
	{
		return [self registrarRecords];
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyHost])
	{
		return [self sipProxyHost];
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyUsername])
	{
		return [self sipProxyUsername];
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyPassword])
	{
		return [self sipProxyPassword];
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
	else if([key isEqualToString:XMKey_PreferencesUseSTUN])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setUseSTUN:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesSTUNServer])
	{
		if([value isKindOfClass:[NSString class]])
		{
			[self setSTUNServer:(NSString *)value];
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
	else if([key isEqualToString:XMKey_PreferencesEnableSilenceSuppression])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableSilenceSuppression:[(NSNumber *)value boolValue]];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesEnableEchoCancellation])
	{
		if([value isKindOfClass:[NSNumber class]])
		{
			[self setEnableEchoCancellation:[(NSNumber *)value boolValue]];
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
	else if([key isEqualToString:XMKey_PreferencesGatekeeperPassword])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setGatekeeperPassword:(NSString *)value];
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
	else if([key isEqualToString:XMKey_PreferencesRegistrarRecords])
	{
		if([value isKindOfClass:[NSArray class]])
		{
			[self setRegistrarRecords:(NSArray *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyHost])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setSIPProxyHost:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyUsername])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setSIPProxyUsername:(NSString *)value];
		}
		else
		{
			correctType = NO;
		}
	}
	else if([key isEqualToString:XMKey_PreferencesSIPProxyPassword])
	{
		if(value == nil || [value isKindOfClass:[NSString class]])
		{
			[self setSIPProxyPassword:(NSString *)value];
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

- (BOOL)useSTUN
{
	return useSTUN;
}

- (void)setUseSTUN:(BOOL)flag
{
	useSTUN = flag;
}

- (NSString *)stunServer
{
	return stunServer;
}

- (void)setSTUNServer:(NSString *)server
{
	NSString *old = stunServer;
	stunServer = [server copy];
	[old release];
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

- (BOOL)enableSilenceSuppression
{
	return enableSilenceSuppression;
}

- (void)setEnableSilenceSuppression:(BOOL)flag
{
	enableSilenceSuppression = flag;
}

- (BOOL)enableEchoCancellation
{
	return enableEchoCancellation;
}

- (void)setEnableEchoCancellation:(BOOL)flag
{
	enableEchoCancellation = flag;
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

- (NSString *)gatekeeperPassword
{
	return gatekeeperPassword;
}

- (void)setGatekeeperPassword:(NSString *)string
{
	if(string != gatekeeperPassword)
	{
		NSString *old = gatekeeperPassword;
		gatekeeperPassword = [string copy];
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

- (NSArray *)registrarRecords
{
	return registrarRecords;
}

- (void)setRegistrarRecords:(NSArray *)records
{
	if(registrarRecords != records)
	{
		NSArray *old = registrarRecords;
		registrarRecords = [records copy];
		[old release];
	}
}

- (BOOL)usesRegistrars
{
	if([[self registrarRecords] count] != 0)
	{
		return YES;
	}
	return NO;
}

- (NSString *)sipProxyHost
{
	return sipProxyHost;
}

- (void)setSIPProxyHost:(NSString *)host
{
	NSString *old = sipProxyHost;
	sipProxyHost = [host copy];
	[old release];
}

- (NSString *)sipProxyUsername
{
	return sipProxyUsername;
}

- (void)setSIPProxyUsername:(NSString *)username
{
	NSString *old = sipProxyUsername;
	sipProxyUsername = [username copy];
	[old release];
}

- (NSString *)sipProxyPassword
{
	return sipProxyPassword;
}

- (void)setSIPProxyPassword:(NSString *)password
{
	NSString *old = sipProxyPassword;
	sipProxyPassword = [password copy];
	[old release];
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