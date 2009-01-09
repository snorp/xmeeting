/*
 * $Id: XMSetupAssistantModules.h,v 1.3 2009/01/09 08:08:21 hfriederich Exp $
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

#pragma mark -
#pragma mark General

@interface XMSAGeneralModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSTextField *nameField;
}

@end

@interface XMSALocationModule : NSObject <XMSetupAssistantModule> {

  @private
  IBOutlet NSView *contentView;
  IBOutlet NSMatrix *locationRadioButtons;
  IBOutlet NSTableView *locationsTable;
}

- (IBAction)radioButtonAction:(id)sender;

@end

@interface XMSANewLocationModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSTextField *nameField;
}

@end

@interface XMSANetworkModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSPopUpButton *bandwidthLimitPopUp;
}

@end

@interface XMSAProtocolModule : NSObject <XMSetupAssistantModule> {
 
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSButton *enableH323Switch;
  IBOutlet NSButton *enableSIPSwitch;
}

- (IBAction)action:(id)sender;

@end

@interface XMSAH323Module : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSMatrix *useGkRadioButtons;
}

@end

@interface XMSAGatekeeperModule : NSObject <XMSetupAssistantModule> {
 
  @private
  IBOutlet NSView *contentView;
}

@end

@interface XMSASIPModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSMatrix *useRegistrarRadioButtons;
}

@end

@interface XMSARegistrationModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
}

@end

@interface XMSAVideoModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSMatrix *videoRadioButtons;
}

@end

#pragma mark -
#pragma mark Edit Mode

@interface XMSAEditIntroductionModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
}

@end

@interface XMSAEditDoneModule : NSObject<XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
}

- (IBAction)continueAssistant:(id)sender;

@end

#endif // __XM_SETUP_ASSISTANT_MODULES_H__
