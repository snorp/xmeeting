/*
 * $Id: XMSetupAssistantModules.h,v 1.1 2009/01/04 17:16:33 hfriederich Exp $
 *
 * Copyright (c) 2009 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2009 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_SETUP_ASSISTANT_MODULES_H__
#define __XM_SETUP_ASSISTANT_MODULES_H__

#import <Cocoa/Cocoa.h>
#import "XMeeting.h"

#import "XMSetupAssistantManager.h"

@interface XMSAEditIntroductionModule : NSObject <XMSetupAssistantModule> {
  
  @private
  
  IBOutlet NSView *contentView;
}

@end

@interface XMSAGeneralModule : NSObject <XMSetupAssistantModule> {
  
  @private
  
  IBOutlet NSView *contentView;
}

@end

@interface XMSALocationModule : NSObject <XMSetupAssistantModule> {

  @private
  
  IBOutlet NSView *contentView;
}

@end

#endif // __XM_SETUP_ASSISTANT_MODULES_H__
