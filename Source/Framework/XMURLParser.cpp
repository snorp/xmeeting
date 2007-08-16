/*
 * $Id: XMURLParser.cpp,v 1.1 2007/08/16 15:41:08 hfriederich Exp $
 *
 * Copyright (c) 2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2007 Hannes Friederich. All rights reserved.
 */

#include "XMURLParser.h"

#include <ptlib.h>
#include <sip/sip.h>

class XMH323URL : public PURL {
  PCLASSINFO(XMH323URL, PURL);
  public:
  
    XMH323URL(const PString & url);
    PString GetDisplayName();
    
};

XMH323URL::XMH323URL(const PString & str)
{
  Parse(str, "h323");
}

PString XMH323URL::GetDisplayName()
{
  PINDEX paramIndex;
  PString s = AsString();
  s.Replace("h323:", "");
  paramIndex = s.Find(';');
  if (paramIndex != P_MAX_INDEX) {
    s = s.Left(paramIndex);
  }
  
  return s;
}

bool _XMParseH323URL(const char *url, XMURLParseCallback callback, void * userData)
{
  XMH323URL h323URL(url);
  if (h323URL.IsEmpty()) {
    return false;
  }
  (*callback) (h323URL.GetDisplayName(), h323URL.GetUserName(), h323URL.GetHostName(), userData);
  return true;
}

bool _XMParseSIPURI(const char *uri, XMURLParseCallback callback, void * userData)
{
  SIPURL sipURL(uri);
  if (sipURL.IsEmpty()) {
    return false;
  }
  (*callback) (sipURL.GetDisplayName(), sipURL.GetUserName(), sipURL.GetHostName(), userData);
  return true;
}