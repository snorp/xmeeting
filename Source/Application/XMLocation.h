/*
 * $Id: XMLocation.h,v 1.13 2007/08/17 11:36:40 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_LOCATION_H__
#define __XM_LOCATION_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMPreferencesManager.h"

enum {
  XMCustomSIPProxyTag = UINT_MAX-1
};

extern NSString *XMKey_LocationName;
extern NSString *XMKey_LocationH323AccountID;
extern NSString *XMKey_LocationSIPAccountIDs;
extern NSString *XMKey_LocationDefaultSIPAccountID;
extern NSString *XMKey_LocationSIPProxyID;

/**
 * Overrides the default XMPreferences instance to provide the following
 * functions:
 * - Name for the location
 * - Uses Accounts to store Gatekeeper / Registrar settings
 * - Provides storage for password data from Gatekeeper / Registrar
 * - Keeps a tag to identify instances which were copied. Required for safe
 *   editing of preferences
 **/
@interface XMLocation : XMPreferences <XMPasswordObject> {
	
@private
  unsigned tag;
  NSString *name;
  unsigned h323AccountTag;
  NSArray * sipAccountTags;
  unsigned defaultSIPAccountTag;
  unsigned sipProxyTag;
  BOOL didSetSIPProxyPassword;
  NSString *_sipProxyPassword;
}

/**
 * initializes the instance with theName as its name.
 **/
- (id)initWithName:(NSString *)theName;

/**
 * initializes the instance with the contents from dictionary,
 * pointing to the H.323 and SIP accounts provided if needed.
 **/
- (id)initWithDictionary:(NSDictionary *)dictionary
			h323Accounts:(NSArray *)h323Accounts
			 sipAccounts:(NSArray *)sipAccounts;

/**
 * Returns a duplicate of the location with the
 * new name set. Using this method is preferred instead
 * of -copy and then -setName: since it makes sure that
 * several internal optimizations work
 **/
- (XMLocation *)duplicateWithName:(NSString *)name;

/**
 * Returns the contents of the location stored in a dictionary.
 * The account pointers are stored relative to the index in the arrays
 * passed as arguments
 **/
- (NSMutableDictionary *)dictionaryRepresentationWithH323Accounts:(NSArray *)h323Accounts
													  sipAccounts:(NSArray *)sipAccounts;

- (unsigned)tag;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (unsigned)h323AccountTag;
- (void)setH323AccountTag:(unsigned)tag;

- (NSArray *)sipAccountTags;
- (void)setSIPAccountTags:(NSArray *)tags;

- (unsigned)defaultSIPAccountTag;
- (void)setDefaultSIPAccountTag:(unsigned)tag;

- (unsigned)sipProxyTag;
- (void)setSIPProxyTag:(unsigned)tag;

- (NSString *)_sipProxyPassword;
- (void)_setSIPProxyPassword:(NSString *)password;

/**
 * Stores the information from the accounts in the data storage
 * provided by the XMPreferences superclass so that the subsystem
 * can be setup consistently.
 * Also stores other global information from the XMPreferences class
 **/
- (void)storeGlobalInformationsInSubsystem;

#pragma mark Methods for Preferences Editing

- (NSNumber *)enableSilenceSuppressionNumber;
- (void)setEnableSilenceSuppressionNumber:(NSNumber *)number;

- (NSNumber *)enableEchoCancellationNumber;
- (void)setEnableEchoCancellationNumber:(NSNumber *)number;

- (NSNumber *)enableVideoNumber;
- (void)setEnableVideoNumber:(NSNumber *)number;

- (NSNumber *)enableH264LimitedModeNumber;
- (void)setEnableH264LimitedModeNumber:(NSNumber *)number;

- (NSNumber *)enableH323Number;
- (void)setEnableH323Number:(NSNumber *)number;

- (NSNumber *)enableH245TunnelNumber;
- (void)setEnableH245TunnelNumber:(NSNumber *)number;

- (NSNumber *)enableFastStartNumber;
- (void)setEnableFastStartNumber:(NSNumber *)number;

- (NSNumber *)enableSIPNumber;
- (void)setEnableSIPNumber:(NSNumber *)number;

@end

#endif // __XM_LOCATION_H__
