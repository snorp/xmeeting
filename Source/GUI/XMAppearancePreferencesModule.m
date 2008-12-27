/*
 * $Id: XMAppearancePreferencesModule.m,v 1.4 2008/12/27 08:01:37 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#import "XMAppearancePreferencesModule.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"

@implementation XMAppearancePreferencesModule

#pragma mark Init & Deallocation Methods

- (id)init
{
  prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
  
  return self;
}

- (void)awakeFromNib
{
  contentViewHeight = [contentView frame].size.height;
  [prefWindowController addPreferencesModule:self];
}

- (void)dealloc
{
  [prefWindowController release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark XMPreferencesModule methods

- (unsigned)position
{
  return 1;
}

- (NSString *)identifier
{
  return @"XMeeting_AppearancePreferencesModule";
}

- (NSString *)toolbarLabel
{
  return NSLocalizedString(@"XM_APPEARANCE_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
  return [NSImage imageNamed:@"appearancePreferences.tif"];
}

- (NSString *)toolTipText
{
  return NSLocalizedString(@"XM_APPEARANCE_PREFERENCES_TOOLTIP", @"");
}

- (NSView *)contentView
{
  return contentView;
}

- (float)contentViewHeight
{
  return contentViewHeight;
}

- (void)loadPreferences
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  
  int state = ([prefManager automaticallyEnterFullScreen] == YES) ? NSOnState : NSOffState;
  [automaticallyEnterFullScreenSwitch setState:state];
  
  state = ([prefManager showSelfViewMirrored] == YES) ? NSOnState : NSOffState;
  [showSelfViewMirroredSwitch setState:state];
  
  state = ([prefManager automaticallyHideInCallControls] == YES) ? NSOnState : NSOffState;
  [automaticallyHideInCallControlsSwitch setState:state];
  
  XMInCallControlHideAndShowEffect effect = [prefManager inCallControlHideAndShowEffect];
  [inCallControlsHideAndShowEffectPopUp selectItemAtIndex:(unsigned)effect];
  
  state = ([prefManager alertIncomingCalls] == YES) ? NSOnState : NSOffState;
  [playSoundOnIncomingCallSwitch setState:state];
  
  XMIncomingCallAlertType alertType = [prefManager incomingCallAlertType];
  [soundTypePopUp selectItemAtIndex:((unsigned)alertType - 1)];
  
  // validating the user interface
  [self toggleAutomaticallyHideInCallControls:self];
  [self togglePlaySoundOnIncomingCall:self];
}

- (void)savePreferences
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  
  BOOL flag = ([automaticallyEnterFullScreenSwitch state] == NSOnState) ? YES : NO;
  [prefManager setAutomaticallyEnterFullScreen:flag];
  
  flag = ([showSelfViewMirroredSwitch state] == NSOnState) ? YES : NO;
  [prefManager setShowSelfViewMirrored:flag];
  
  flag = ([automaticallyHideInCallControlsSwitch state] == NSOnState) ? YES : NO;
  [prefManager setAutomaticallyHideInCallControls:flag];
  
  XMInCallControlHideAndShowEffect effect = (XMInCallControlHideAndShowEffect)[inCallControlsHideAndShowEffectPopUp indexOfSelectedItem];
  [prefManager setInCallControlHideAndShowEffect:effect];
  
  flag = ([playSoundOnIncomingCallSwitch state] == NSOnState) ? YES : NO;
  [prefManager setAlertIncomingCalls:flag];
  
  XMIncomingCallAlertType alertType = (XMIncomingCallAlertType)([soundTypePopUp indexOfSelectedItem] + 1);
  [prefManager setIncomingCallAlertType:alertType];
}

- (void)becomeActiveModule
{
}

- (BOOL)validateData
{
  return YES;
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)defaultAction:(id)sender
{
  [prefWindowController notePreferencesDidChange];	
}

- (IBAction)toggleAutomaticallyHideInCallControls:(id)sender
{
  int state = [automaticallyHideInCallControlsSwitch state];
  BOOL enablePopUp = (state == NSOnState) ? YES : NO;
  
  [inCallControlsHideAndShowEffectPopUp setEnabled:enablePopUp];
  
  [self defaultAction:sender];
}

- (IBAction)togglePlaySoundOnIncomingCall:(id)sender
{
  int state = [playSoundOnIncomingCallSwitch state];
  BOOL enablePopUp = (state == NSOnState) ? YES : NO;
  
  [soundTypePopUp setEnabled:enablePopUp];
  
  [self defaultAction:sender];
}

@end
