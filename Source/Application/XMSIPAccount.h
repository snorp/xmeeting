/*
 * $Id: XMSIPAccount.h,v 1.6 2007/08/14 10:56:39 hfriederich Exp $
 *
 * Copyright (c) 2006-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_ACCOUNT_H__
#define __XM_SIP_ACCOUNT_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"
#import "XMPreferencesManager.h"

extern NSString *XMKey_SIPAccountName;
extern NSString *XMKey_SIPAccountDomain;
extern NSString *XMKey_SIPAccountUsername;
extern NSString *XMKey_SIPAccountAuthorizationUsername;
extern NSString *XMKey_SIPAccountPassword;

/**
 * An SIP account instance encapsulates all information required so that the client
 * can register at a SIP registrar.
 *
 * The locations then point to an account to define it's registration settings.
 **/
@interface XMSIPAccount : NSObject <NSCopying, XMPasswordObject> {

	unsigned tag;
	NSString *name;
	NSString *domain;
	NSString *username;
	NSString *authorizationUsername;
	BOOL didSetPassword;
	NSString *password;
}

- (id)init;
- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (unsigned)tag;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSString *)domain;
- (void)setDomain:(NSString *)domain;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)authorizationUsername;
- (void)setAuthorizationUsername:(NSString *)authorizationUsername;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

- (NSString *)registration;

@end

#endif // __XM_SIP_ACCOUNT_H__
