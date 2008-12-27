/*
 * $Id: XMInfoModule.h,v 1.11 2008/12/27 08:06:47 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Ivan Guajana, Hannes Friederich. All rights reserved.
 */

#ifndef __XM_INFO_MODULE_H__
#define __XM_INFO_MODULE_H__

#import <Cocoa/Cocoa.h>

#import "XMInspectorModule.h"

@interface XMInfoModule : XMInspectorModule {
  
@private
  IBOutlet NSView *contentView;
  NSSize contentViewSize;
  
  IBOutlet NSBox *networkBox;
  IBOutlet NSTextField *ipAddressesField;
  IBOutlet NSImageView *ipAddressStatusImage;
  IBOutlet NSTextField *natTypeField;
  IBOutlet NSImageView *natTypeStatusImage;
  
  IBOutlet NSButton *h323Disclosure;
  IBOutlet NSBox *h323Box;
  IBOutlet NSTextField *h323Title;
  IBOutlet NSTextField *h323StatusField;
  IBOutlet NSImageView *h323StatusImage;
  IBOutlet NSTextField *gatekeeperField;
  IBOutlet NSImageView *gatekeeperStatusImage;
  IBOutlet NSTextField *terminalAliasField;
  NSMutableArray *terminalAliasViews;
  
  IBOutlet NSButton *sipDisclosure;
  IBOutlet NSBox *sipBox;
  IBOutlet NSTextField *sipTitle;
  IBOutlet NSTextField *sipStatusField;
  IBOutlet NSImageView *sipStatusImage;
  IBOutlet NSTextField *registrationField;
  IBOutlet NSImageView *registrationStatusImage;
  NSMutableArray *registrationViews;
  
  unsigned addressExtraHeight;
  unsigned h323BoxHeight;
  unsigned h323AliasesExtraHeight;
  unsigned sipBoxHeight;
  unsigned sipRegistrationsExtraHeight;
  
  BOOL showH323Details;
  BOOL showSIPDetails;
}

- (IBAction)toggleShowH323Details:(id)sender;
- (IBAction)toggleShowSIPDetails:(id)sender;

@end

#endif // __XM_INFO_MODULE_H__
