/*
 * $Id: XMH323Account.h,v 1.5 2007/09/27 21:13:10 hfriederich Exp $
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
extern NSString *XMKey_H323AccountGatekeeperHost;
extern NSString *XMKey_H323AccountTerminalAlias1;
extern NSString *XMKey_H323AccountTerminalAlias2;
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
  NSString *gatekeeperHost;
  NSString *terminalAlias1;
  NSString *terminalAlias2;
  BOOL didSetPassword;
  NSString *password;
	
}

- (id)init;
- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (unsigned)tag;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSString *)gatekeeperHost;
- (void)setGatekeeperHost:(NSString *)host;

- (NSString *)terminalAlias1;
- (void)setTerminalAlias1:(NSString *)alias;

- (NSString *)terminalAlias2;
- (void)setTerminalAlias2:(NSString *)alias;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

@end

#endif // __XM_H323_ACCOUNT_H__
