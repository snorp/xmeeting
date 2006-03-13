/*
 * $Id: XMSIPAccount.h,v 1.1 2006/03/13 23:46:21 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SIP_ACCOUNT_H__
#define __XM_SIP_ACCOUNT_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

extern NSString *XMKey_SIPAccountName;
extern NSString *XMKey_SIPAccountRegistrar;
extern NSString *XMKey_SIPAccountUsername;

@interface XMSIPAccount : NSObject <NSCopying> {

	unsigned tag;
	NSString *name;
	NSString *registrar;
	NSString *username;
	BOOL didLoadPassword;
	NSString *password;
}

- (id)init;
- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

- (unsigned)tag;

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSString *)registrar;
- (void)setRegistrar:(NSString *)registrar;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

- (void)clearPassword;
- (void)savePassword;

@end

#endif // __XM_SIP_ACCOUNT_H__
