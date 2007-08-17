/*
 * $Id: XMCallStatistics.h,v 1.3 2007/08/17 11:36:41 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_CALL_STATISTICS_H__
#define __XM_CALL_STATISTICS_H__

#import <Foundation/Foundation.h>

#import "XMTypes.h"

@interface XMCallStatistics : NSObject {

@private
  XMCallStatisticsRecord callStatisticsRecord;
	
}

- (id)_init;
- (XMCallStatisticsRecord *)_callStatisticsRecord;

@end

#endif // __XM_CALL_STATISTICS_H__
