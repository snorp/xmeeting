/*
 * $Id: XMURLParser.h,v 1.1 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_URL_PARSER_H__
#define __XM_URL_PARSER_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*XMURLParseCallback) (const char * displayName, 
                                    const char * username,
                                    const char * domainName,
                                    void * userData);

bool _XMParseH323URL(const char *url, XMURLParseCallback callback, void * userData);
bool _XMParseSIPURI(const char *uri, XMURLParseCallback callback, void * userData);

#ifdef __cplusplus
}
#endif

#endif // __XM_URL_PARSER_H__