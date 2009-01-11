/*
 * $Id: XMSetupAssistantModules.h,v 1.4 2009/01/11 17:20:41 hfriederich Exp $
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
  IBOutlet NSTextField *gkHostField;
  IBOutlet NSTextField *gkUserAlias1Field;
  IBOutlet NSTextField *gkUserAlias2Field;
  IBOutlet NSTextField *gkPasswordField;
}

@end

@interface XMSASIPModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSMatrix *useRegistrationRadioButtons;
}

@end

@interface XMSARegistrationModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
  IBOutlet NSTextField *sipRegDomainField;
  IBOutlet NSTextField *sipRegUsernameField;
  IBOutlet NSTextField *sipRegAuthorizationUsernameField;
  IBOutlet NSTextField *sipRegPasswordField;
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

#pragma mark -
#pragma mark First Launch Mode

@interface XMSAFirstLaunchIntroductionModule : NSObject <XMSetupAssistantModule> {
 
  @private
  IBOutlet NSView *contentView;
}

@end

@interface XMSAFirstLaunchDoneModule : NSObject <XMSetupAssistantModule> {
  
  @private
  IBOutlet NSView *contentView;
}

@end

#endif // __XM_SETUP_ASSISTANT_MODULES_H__
