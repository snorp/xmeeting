/*
 * $Id: XMEndpoint.cpp,v 1.1 2005/01/20 17:28:13 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project (http://xmeeting.sf.net).
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>

#include "XMEndpoint.h"

using namespace std;

void XMEndpointTest()
{
	PString str = "Teststring to check whether PWLib and thereby PString works";
	
	cout << str << endl;
	
	cout << "*****functionality test:" << endl;
	
	cout << str.ToUpper() << endl;
}