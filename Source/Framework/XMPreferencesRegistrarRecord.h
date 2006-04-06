/*
 * $Id: XMPreferencesRegistrarRecord.h,v 1.1 2006/04/06 23:15:32 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_PREFERENCES_REGISTRAR_RECORD_H__
#define __XM_PREFERENCES_REGISTRAR_RECORD_H__

#import <Cocoa/Cocoa.h>

@interface XMPreferencesRegistrarRecord : NSObject <NSCopying, NSCoding> {

	NSString *host;
	NSString *username;
	NSString *authorizationUsername;
	NSString *password;

}

- (NSMutableDictionary *)dictionaryRepresentation;

- (NSString *)host;
- (void)setHost:(NSString *)host;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)authorizationUsername;
- (void)setAuthorizationUsername:(NSString *)authorizationUsername;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

@end

#endif // __XM_PREFERENCES_REGISTRAR_RECORD_H__
