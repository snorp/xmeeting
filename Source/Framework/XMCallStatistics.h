/*
 * $Id: XMCallStatistics.h,v 1.1 2005/11/09 20:00:27 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_STATISTICS_H__
#define __XM_CALL_STATISTICS_H__

#import <Foundation/Foundation.h>

#import "XMTypes.h"

@interface XMCallStatistics : NSObject {

	XMCallStatisticsRecord callStatisticsRecord;
	
}

- (id)_init;
- (XMCallStatisticsRecord *)_callStatisticsRecord;

@end

#endif // __XM_CALL_STATISTICS_H__
