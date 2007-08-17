/*
 * $Id: XMH323Account.h,v 1.4 2007/08/17 11:36:40 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_H323_ACCOUNT_H__
#define __XM_H323_ACCOUNT_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMPreferencesManager.h"

extern NSString *XMKey_H323AccountName;
extern NSString *XMKey_H323AccountGatekeeper;
extern NSString *XMKey_H323AccountUsername;
extern NSString *XMKey_H323AccountPhoneNumber;
extern NSString *XMKey_H323AccountPassword;

/**
 * An H323 account instance encapsulates all information required so that the client
 * can register at a gatekeeper.
 *
 * The locations then point to an account to define it's gatekeeper settings.
 **/
@interface XMH323Account : NSObject <NSCopying, XMPasswordObject> {

@private
  unsigned tag;
  NSString *name;
  NSString *gatekeeper;
  NSString *username;
  NSString *phoneNumber;
  BOOL didSetPassword;
  NSString *password;
	
}

- (id)init;
- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (unsigned)tag;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSString *)gatekeeper;
- (void)setGatekeeper:(NSString *)gatekeeper;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)phoneNumber;
- (void)setPhoneNumber:(NSString *)phoneNumber;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

@end

#endif // __XM_H323_ACCOUNT_H__
