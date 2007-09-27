/*
 * $Id: XMPreferences.m,v 1.22 2007/09/27 21:13:11 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMPreferences.h"

#import "XMStringConstants.h"
#import "XMPrivate.h"
#import "XMPreferencesCodecListRecord.h"
#import "XMPreferencesRegistrationRecord.h"
#import "XMCodecManager.h"

@interface XMValueTypeRecord : NSObject {
  @public
  NSString *key;
  Class     class;
  BOOL      allowNil;
}

+ (XMValueTypeRecord *)createWithKey:(NSString *)key class:(Class)class allowNil:(BOOL)allowNil;
- (id)initWithKey:(NSString *)key class:(Class)class allowNil:(BOOL)allowNil;

@end

@implementation XMValueTypeRecord

+ (XMValueTypeRecord *)createWithKey:(NSString *)key class:(Class)class allowNil:(BOOL)allowNil
{
  return [[[XMValueTypeRecord alloc] initWithKey:key class:class allowNil:allowNil] autorelease];
}

- (id)initWithKey:(NSString *)_key class:(Class)_class allowNil:(BOOL)_allowNil
{
  key = _key;
  class = _class;
  allowNil = _allowNil;
  return self;
}

@end

@interface XMPreferences (PrivateMethods)

+ (NSArray *)_valueTypes;

- (NSMutableArray *)_audioCodecList;
- (void)_setAudioCodecList:(NSArray *)arr;

- (NSMutableArray *)_videoCodecList;
- (void)_setVideoCodecList:(NSArray *)arr;

@end

@implementation XMPreferences

#pragma mark -
#pragma mark Framework Methods

+ (NSArray *)_valueTypes {
  static NSArray *valueTypes = nil;
  if (valueTypes == nil) {
    Class number = [NSNumber class];
    Class string = [NSString class];
    Class array = [NSArray class];
    valueTypes = [[NSArray alloc] initWithObjects:
      [XMValueTypeRecord createWithKey:XMKey_PreferencesUserName class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesAutomaticallyAcceptIncomingCalls class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesBandwidthLimit class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesExternalAddress class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesTCPPortBase class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesTCPPortMax class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesUDPPortBase class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesUDPPortMax class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesSTUNServers class:array allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableSilenceSuppression class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableEchoCancellation class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesAudioPacketTime class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableVideo class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesVideoFramesPerSecond class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableH264LimitedMode class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableH323 class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableH245Tunnel class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableFastStart class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesGatekeeperAddress class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesGatekeeperTerminalAlias1 class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesGatekeeperTerminalAlias2 class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesGatekeeperPassword class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesEnableSIP class:number allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesSIPRegistrationRecords class:array allowNil:NO],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesSIPProxyHost class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesSIPProxyUsername class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesSIPProxyPassword class:string allowNil:YES],
      [XMValueTypeRecord createWithKey:XMKey_PreferencesInternationalDialingPrefix class:string allowNil:YES],
      
      nil];      
  }
  return valueTypes;
}

+ (XM_VALUE_TEST_RESULT)_checkValue:(id)value forKey:(NSString *)key
{
  NSArray *valueTypes = [XMPreferences _valueTypes];
  unsigned count = [valueTypes count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMValueTypeRecord *record = (XMValueTypeRecord *)[valueTypes objectAtIndex:i];
    if ([key isEqualToString:record->key]) {
      return ((value == nil && record->allowNil == YES) || [value isKindOfClass:record->class]) ? XM_VALID_VALUE : XM_INVALID_VALUE_TYPE;
    }
  }
  
  return XM_INVALID_KEY;
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
  externalAddress = nil;
  tcpPortBase = 30000;
  tcpPortMax = 30010;
  udpPortBase = 5000;
  udpPortMax = 5099;
  stunServers = [[NSArray alloc] init];
  
  unsigned audioCodecCount = [_XMCodecManagerSharedInstance audioCodecCount];
  audioCodecList = [[NSMutableArray alloc] initWithCapacity:audioCodecCount];
  
  [self resetAudioCodecs];
  
  enableSilenceSuppression = NO;
  enableEchoCancellation = NO;
  audioPacketTime = 0;
  
  enableVideo = NO;
  videoFramesPerSecond = 30;
  
  unsigned videoCodecCount = [_XMCodecManagerSharedInstance videoCodecCount];
  videoCodecList = [[NSMutableArray alloc] initWithCapacity:videoCodecCount];
  [self resetVideoCodecs];
  
  enableH264LimitedMode = NO;
  
  enableH323 = NO;
  enableH245Tunnel = NO;
  enableFastStart = NO;
  gatekeeperAddress = nil;
  gatekeeperTerminalAlias1 = nil;
  gatekeeperTerminalAlias2 = nil;
  gatekeeperPassword = nil;
  
  enableSIP = NO;
  sipRegistrationRecords = [[NSArray alloc] init];
  sipProxyHost = nil;
  sipProxyUsername = nil;
  sipProxyPassword = nil;
  
  internationalDialingPrefix = @"00";
  
  return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
  NSObject *obj;
  
  self = [self init];
  
  NSArray *valueTypes = [XMPreferences _valueTypes];
  unsigned count = [valueTypes count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMValueTypeRecord *record = (XMValueTypeRecord *)[valueTypes objectAtIndex:i];
    obj = [dict objectForKey:record->key];
    if (obj) {
      [self setValue:obj forKey:record->key];
    }
  }
  
  // Special code for the codec lists
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
  
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  XMPreferences *preferences = [[[self class] allocWithZone:zone] init];
  
  NSArray *valueTypes = [XMPreferences _valueTypes];
  unsigned count = [valueTypes count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMValueTypeRecord *record = (XMValueTypeRecord *)[valueTypes objectAtIndex:i];
    [preferences setValue:[self valueForKey:record->key] forKey:record->key];
  }
  
  // Special code for the audio codec lists
  [preferences _setAudioCodecList:[self _audioCodecList]];
  [preferences _setVideoCodecList:[self _videoCodecList]];
  
  return preferences;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [self init];
  
  if([coder allowsKeyedCoding]) // use keyed coding
  {
    NSArray *valueTypes = [XMPreferences _valueTypes];
    unsigned count = [valueTypes count];
    unsigned i;
    
    for (i = 0; i < count; i++) {
      XMValueTypeRecord *record = (XMValueTypeRecord *)[valueTypes objectAtIndex:i];
      [self setValue:[coder decodeObjectForKey:record->key] forKey:record->key];
    }
    
    // Special code for the codec lists
    NSArray *array;
    unsigned codecCount;
    
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
    NSArray *valueTypes = [XMPreferences _valueTypes];
    unsigned count = [valueTypes count];
    unsigned i;
    
    for (i = 0; i < count; i++) {
      XMValueTypeRecord *record = (XMValueTypeRecord *)[valueTypes objectAtIndex:i];
      [coder encodeObject:[self valueForKey:record->key] forKey:record->key];
    }
    
    // Special handling for the codec lists
    [coder encodeObject:[self _audioCodecList] forKey:XMKey_PreferencesAudioCodecList];
    [coder encodeObject:[self _videoCodecList] forKey:XMKey_PreferencesVideoCodecList];
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
  [stunServers release];
  
  [audioCodecList release];
  [videoCodecList release];
  
  [gatekeeperAddress release];
  [gatekeeperTerminalAlias1 release];
  [gatekeeperTerminalAlias2 release];
  [gatekeeperPassword release];
  
  [sipRegistrationRecords release];
  [sipProxyHost release];
  [sipProxyUsername release];
  [sipProxyPassword release];
  
  [internationalDialingPrefix release];
  
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
  
  return [[otherPreferences dictionaryRepresentation] isEqual:[self dictionaryRepresentation]];
}

#pragma mark -
#pragma mark Getting Different Representations

- (NSMutableDictionary *)dictionaryRepresentation
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:30];
  NSObject *obj;
  
  NSArray *valueTypes = [XMPreferences _valueTypes];
  unsigned count = [valueTypes count];
  unsigned i;
  
  for (i = 0; i < count; i++) {
    XMValueTypeRecord *record = (XMValueTypeRecord *)[valueTypes objectAtIndex:i];
    obj = [self valueForKey:record->key];
    if (obj) {
      [dict setObject:obj forKey:record->key];
    }
  }
  
  // special handling for the codec lists
  count = [audioCodecList count];
  NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:count];
  for (i = 0; i < count; i++)
  {
    [arr addObject:[(XMPreferencesCodecListRecord *)[audioCodecList objectAtIndex:i] dictionaryRepresentation]];
  }
  [dict setObject:arr forKey:XMKey_PreferencesAudioCodecList];
  [arr release];
  
  count = [videoCodecList count];
  arr = [[NSMutableArray alloc] initWithCapacity:count];
  for(i = 0; i < count; i++)
  {
    [arr addObject:[(XMPreferencesCodecListRecord *)[videoCodecList objectAtIndex:i] dictionaryRepresentation]];
  }
  [dict setObject:arr forKey:XMKey_PreferencesVideoCodecList];
  [arr release];
  
  return dict;
}

#pragma mark -
#pragma mark Accesssing values through keys

- (id)valueForKey:(NSString *)key
{
  if([key isEqualToString:XMKey_PreferencesUserName]) {
    return [self userName];
  } else if([key isEqualToString:XMKey_PreferencesAutomaticallyAcceptIncomingCalls]) {
    return [NSNumber numberWithBool:[self automaticallyAcceptIncomingCalls]];
  } else if([key isEqualToString:XMKey_PreferencesBandwidthLimit]) {
    return [NSNumber numberWithUnsignedInt:[self bandwidthLimit]];
  } else if([key isEqualToString:XMKey_PreferencesExternalAddress]) {
    return [self externalAddress];
  } else if([key isEqualToString:XMKey_PreferencesTCPPortBase]) {
    return [NSNumber numberWithUnsignedInt:[self tcpPortBase]];
  } else if([key isEqualToString:XMKey_PreferencesTCPPortMax]) {
    return [NSNumber numberWithUnsignedInt:[self tcpPortMax]];
  } else if([key isEqualToString:XMKey_PreferencesUDPPortBase]) {
    return [NSNumber numberWithUnsignedInt:[self udpPortBase]];
  } else if([key isEqualToString:XMKey_PreferencesUDPPortMax]) {
    return [NSNumber numberWithUnsignedInt:[self udpPortMax]];
  } else if ([key isEqualToString:XMKey_PreferencesSTUNServers]) {
    return [self stunServers];
  } else if([key isEqualToString:XMKey_PreferencesAudioCodecList]) {
    return [self audioCodecList];
  } else if([key isEqualToString:XMKey_PreferencesEnableSilenceSuppression]) {
    return [NSNumber numberWithBool:[self enableSilenceSuppression]];
  } else if([key isEqualToString:XMKey_PreferencesEnableEchoCancellation]) {
    return [NSNumber numberWithBool:[self enableEchoCancellation]];
  } else if([key isEqualToString:XMKey_PreferencesAudioPacketTime]) {
    return [NSNumber numberWithUnsignedInt:[self audioPacketTime]];
  } else if([key isEqualToString:XMKey_PreferencesEnableVideo]) {
    return [NSNumber numberWithBool:[self enableVideo]];
  } else if([key isEqualToString:XMKey_PreferencesVideoFramesPerSecond]) {
    return [NSNumber numberWithUnsignedInt:[self videoFramesPerSecond]];
  } else if([key isEqualToString:XMKey_PreferencesVideoCodecList]) {
    return [self videoCodecList];
  } else if([key isEqualToString:XMKey_PreferencesEnableH264LimitedMode]) {
    return [NSNumber numberWithBool:[self enableH264LimitedMode]];
  } else if([key isEqualToString:XMKey_PreferencesEnableH323]) {
    return [NSNumber numberWithBool:[self enableH323]];
  } else if([key isEqualToString:XMKey_PreferencesEnableH245Tunnel]) {
    return [NSNumber numberWithBool:[self enableH245Tunnel]];
  } else if([key isEqualToString:XMKey_PreferencesEnableFastStart]) {
    return [NSNumber numberWithBool:[self enableFastStart]];
  } else if([key isEqualToString:XMKey_PreferencesGatekeeperAddress]) {
    return [self gatekeeperAddress];
  } else if([key isEqualToString:XMKey_PreferencesGatekeeperTerminalAlias1]) {
    return [self gatekeeperTerminalAlias1];
  } else if([key isEqualToString:XMKey_PreferencesGatekeeperTerminalAlias2]) {
    return [self gatekeeperTerminalAlias2];
  } else if([key isEqualToString:XMKey_PreferencesGatekeeperPassword]) {
    return [self gatekeeperPassword];
  } else if([key isEqualToString:XMKey_PreferencesEnableSIP]) {
    return [NSNumber numberWithBool:[self enableSIP]];
  } else if([key isEqualToString:XMKey_PreferencesSIPRegistrationRecords]) {
    return [self sipRegistrationRecords];
  } else if([key isEqualToString:XMKey_PreferencesSIPProxyHost]) {
    return [self sipProxyHost];
  } else if([key isEqualToString:XMKey_PreferencesSIPProxyUsername]) {
    return [self sipProxyUsername];
  } else if([key isEqualToString:XMKey_PreferencesSIPProxyPassword]) {
    return [self sipProxyPassword];
  } else if ([key isEqualToString:XMKey_PreferencesInternationalDialingPrefix]) {
    return [self internationalDialingPrefix];
  }
  
  return nil;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
  XM_VALUE_TEST_RESULT result = [XMPreferences _checkValue:value forKey:key];
  if (result == XM_VALID_VALUE) {
    
    if([key isEqualToString:XMKey_PreferencesUserName]) {
      [self setUserName:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesAutomaticallyAcceptIncomingCalls]) {
      [self setAutomaticallyAcceptIncomingCalls:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesBandwidthLimit]) {
      [self setBandwidthLimit:[(NSNumber *)value unsignedIntValue]];
    } else if([key isEqualToString:XMKey_PreferencesExternalAddress]) {
      [self setExternalAddress:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesTCPPortBase]) {
      [self setTCPPortBase:[(NSNumber *)value unsignedIntValue]];
    } else if([key isEqualToString:XMKey_PreferencesTCPPortMax]) {
      [self setTCPPortMax:[(NSNumber *)value unsignedIntValue]];
    } else if([key isEqualToString:XMKey_PreferencesUDPPortBase]) {
      [self setUDPPortBase:[(NSNumber *)value unsignedIntValue]];
    } else if([key isEqualToString:XMKey_PreferencesUDPPortMax]) {
      [self setUDPPortMax:[(NSNumber *)value unsignedIntValue]];
    } else if ([key isEqualToString:XMKey_PreferencesSTUNServers]) {
      [self setSTUNServers:(NSArray *)value];
    } else if([key isEqualToString:XMKey_PreferencesEnableSilenceSuppression]) {
      [self setEnableSilenceSuppression:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesEnableEchoCancellation]) {
      [self setEnableEchoCancellation:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesAudioPacketTime]) {
      [self setAudioPacketTime:[(NSNumber *)value unsignedIntValue]];
    } else if([key isEqualToString:XMKey_PreferencesEnableVideo]) {
      [self setEnableVideo:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesVideoFramesPerSecond]) {
      [self setVideoFramesPerSecond:[(NSNumber *)value unsignedIntValue]];
    } else if([key isEqualToString:XMKey_PreferencesEnableH264LimitedMode]) {
      [self setEnableH264LimitedMode:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesEnableH323]) {
      [self setEnableH323:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesEnableH245Tunnel]) {
      [self setEnableH245Tunnel:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesEnableFastStart]) {
      [self setEnableFastStart:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesGatekeeperAddress]) {
      [self setGatekeeperAddress:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesGatekeeperTerminalAlias1]) {
      [self setGatekeeperTerminalAlias1:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesGatekeeperTerminalAlias2]) {
      [self setGatekeeperTerminalAlias2:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesGatekeeperPassword]) {
      [self setGatekeeperPassword:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesEnableSIP]) {
      [self setEnableSIP:[(NSNumber *)value boolValue]];
    } else if([key isEqualToString:XMKey_PreferencesSIPRegistrationRecords]) {
      [self setSIPRegistrationRecords:(NSArray *)value];
    } else if([key isEqualToString:XMKey_PreferencesSIPProxyHost]) {
      [self setSIPProxyHost:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesSIPProxyUsername]) {
      [self setSIPProxyUsername:(NSString *)value];
    } else if([key isEqualToString:XMKey_PreferencesSIPProxyPassword]) {
      [self setSIPProxyPassword:(NSString *)value];
    } else if ([key isEqualToString:XMKey_PreferencesInternationalDialingPrefix]) {
      [self setInternationalDialingPrefix:(NSString *)value];
    } else {
      [NSException raise:XMException_InvalidParameter format:XMExceptionReason_InvalidParameterMustBeValidKey];
    }
  } else {
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

- (NSArray *)stunServers
{
  return stunServers;
}

- (void)setSTUNServers:(NSArray *)servers
{
  if(stunServers != servers)
  {
    NSArray *old = stunServers;
    stunServers = [servers copy];
    [old release];
  }
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

- (void)resetAudioCodecs
{
  [audioCodecList removeAllObjects];
  
  unsigned count = [_XMCodecManagerSharedInstance audioCodecCount];
  unsigned i;
  for(i = 0; i < count; i++)
  {
    XMCodec *audioCodec = [_XMCodecManagerSharedInstance audioCodecAtIndex:i];
    XMCodecIdentifier identifier = [audioCodec identifier];
    XMPreferencesCodecListRecord *record = [[XMPreferencesCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
    [audioCodecList addObject:record];
    [record release];
  }
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

- (unsigned)audioPacketTime
{
  return audioPacketTime;
}

- (void)setAudioPacketTime:(unsigned)value
{
  audioPacketTime = value;
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

- (void)resetVideoCodecs
{
  [videoCodecList removeAllObjects];
  unsigned count = [_XMCodecManagerSharedInstance videoCodecCount];
  unsigned i;
  for(i = 0; i < count; i++)
  {
    XMCodec *videoCodec = [_XMCodecManagerSharedInstance videoCodecAtIndex:i];
    XMCodecIdentifier identifier = [videoCodec identifier];
    XMPreferencesCodecListRecord *record = [[XMPreferencesCodecListRecord alloc] _initWithIdentifier:identifier enabled:YES];
    [videoCodecList addObject:record];
    [record release];
  }
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

- (NSString *)gatekeeperTerminalAlias1
{
  return gatekeeperTerminalAlias1;
}

- (void)setGatekeeperTerminalAlias1:(NSString *)string
{
  if(string != gatekeeperTerminalAlias1)
  {
    NSString *old = gatekeeperTerminalAlias1;
    gatekeeperTerminalAlias1 = [string copy];
    [old release];
  }
}

- (NSString *)gatekeeperTerminalAlias2
{
  return gatekeeperTerminalAlias2;
}

- (void)setGatekeeperTerminalAlias2:(NSString *)string
{
  if(string != gatekeeperTerminalAlias2)
  {
    NSString *old = gatekeeperTerminalAlias2;
    gatekeeperTerminalAlias2 = [string copy];
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
  if ([self gatekeeperTerminalAlias1] != nil) {
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

- (NSArray *)sipRegistrationRecords
{
  return sipRegistrationRecords;
}

- (void)setSIPRegistrationRecords:(NSArray *)records
{
  if(sipRegistrationRecords != records)
  {
    NSArray *old = sipRegistrationRecords;
    sipRegistrationRecords = [records copy];
    [old release];
  }
}

- (BOOL)usesRegistrations
{
  if([[self sipRegistrationRecords] count] != 0)
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
#pragma mark Misc Methods

- (NSString *)internationalDialingPrefix
{
  return internationalDialingPrefix;
}

- (void)setInternationalDialingPrefix:(NSString *)prefix
{
  NSString *old = internationalDialingPrefix;
  internationalDialingPrefix = [prefix copy];
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