/*
 * $Id: XMAudioPreferencesModule.m,v 1.5 2008/11/18 07:56:06 hfriederich Exp $
 *
 * Copyright (c) 2006-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006-2008 Hannes Friederich. All rights reserved.
 */

#import "XMAudioPreferencesModule.h"
#import "XMPreferencesManager.h"
#import "XMeeting.h"

NSString *XMKey_AudioPreferencesModuleIdentifier = @"XMeeting_AudioPreferencesModule";

NSString *XMString_UseDefaultDevice = @"";

@interface XMAudioPreferencesModule (PrivateMethods)

- (void)_buildInputDeviceList;
- (void)_buildOutputDeviceList;
- (void)_updateDeviceLists:(NSNotification *)notif;

@end

@implementation XMAudioPreferencesModule

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
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateDeviceLists:)
                                               name:XMNotification_AudioManagerDidUpdateDeviceLists
                                             object:nil];
  
  XMString_UseDefaultDevice = [NSLocalizedString(@"XM_AUDIO_PREFERENCES_DEFAULT_DEVICE", @"") retain];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [prefWindowController release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark XMPreferencesModule methods

- (unsigned)position
{
  return 4;
}

- (NSString *)identifier
{
  return XMKey_AudioPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
  return NSLocalizedString(@"XM_AUDIO_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
  return [NSImage imageNamed:@"Audio"];
}

- (NSString *)toolTipText
{
  return NSLocalizedString(@"XM_AUDIO_PREFERENCES_TOOLTIP", @"");
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
  [preferredOutputDevicePopUp removeAllItems];
  [preferredInputDevicePopUp removeAllItems];
  
  [self _buildOutputDeviceList];
  [self _buildInputDeviceList];
}

- (void)savePreferences
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  
  NSString *preferredOutputDevice = [preferredOutputDevicePopUp titleOfSelectedItem];
  if ([preferredOutputDevice isEqualToString:XMString_UseDefaultDevice]) {
    preferredOutputDevice = nil;
  }
  
  NSString *preferredInputDevice = [preferredInputDevicePopUp titleOfSelectedItem];
  if ([preferredInputDevice isEqualToString:XMString_UseDefaultDevice]) {
    preferredInputDevice = nil;
  }
  
  [prefManager setPreferredAudioOutputDevice:preferredOutputDevice];
  [prefManager setPreferredAudioInputDevice:preferredInputDevice];
  
}

- (void)becomeActiveModule
{
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)preferredOutputDeviceSelectionDidChange:(id)sender
{
  [self defaultAction:sender];
}

- (IBAction)preferredInputDeviceSelectionDidChange:(id)sender
{
  [self defaultAction:sender];
}

- (IBAction)defaultAction:(id)sender
{
  [prefWindowController notePreferencesDidChange];
}

#pragma mark -
#pragma mark Private Methods

- (void)_buildOutputDeviceList
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  XMAudioManager *audioManager = [XMAudioManager sharedInstance];
  
  NSString *preferredDevice;
  
  if ([preferredOutputDevicePopUp numberOfItems] == 0) {
    preferredDevice = [prefManager preferredAudioOutputDevice];
  } else {
    preferredDevice = [preferredOutputDevicePopUp titleOfSelectedItem];
    if ([preferredDevice isEqualToString:XMString_UseDefaultDevice]) {
      preferredDevice = nil;
    }
  }
  
  NSArray *devices = [audioManager outputDevices];
  
  [preferredOutputDevicePopUp removeAllItems];
  
  [preferredOutputDevicePopUp addItemWithTitle:XMString_UseDefaultDevice];
  
  if (preferredDevice != nil && ![devices containsObject:preferredDevice]) {
    [preferredOutputDevicePopUp addItemWithTitle:preferredDevice];
  }
  
  [[preferredOutputDevicePopUp menu] addItem:[NSMenuItem separatorItem]];
  
  [preferredOutputDevicePopUp addItemsWithTitles:devices];
  
  if (preferredDevice == nil) {
    [preferredOutputDevicePopUp selectItemAtIndex:0];
  } else {
    [preferredOutputDevicePopUp selectItemWithTitle:preferredDevice];
  }
}

- (void)_buildInputDeviceList
{
  XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
  XMAudioManager *audioManager = [XMAudioManager sharedInstance];
  
  NSString *preferredDevice;
  
  if ([preferredInputDevicePopUp numberOfItems] == 0) {
    preferredDevice = [prefManager preferredAudioInputDevice];
  } else {
    preferredDevice = [preferredInputDevicePopUp titleOfSelectedItem];
    if ([preferredDevice isEqualToString:XMString_UseDefaultDevice]) {
      preferredDevice = nil;
    }
  }
  
  NSArray *devices = [audioManager inputDevices];
  
  [preferredInputDevicePopUp removeAllItems];
  
  [preferredInputDevicePopUp addItemWithTitle:XMString_UseDefaultDevice];
  
  if (preferredDevice != nil && ![devices containsObject:preferredDevice]) {
    [preferredInputDevicePopUp addItemWithTitle:preferredDevice];
  }
  
  [[preferredInputDevicePopUp menu] addItem:[NSMenuItem separatorItem]];
  
  [preferredInputDevicePopUp addItemsWithTitles:devices];
  
  if (preferredDevice == nil) {
    [preferredInputDevicePopUp selectItemAtIndex:0];
  } else {
    [preferredInputDevicePopUp selectItemWithTitle:preferredDevice];
  }
}

- (void)_updateDeviceLists:(NSNotification *)notif
{
  [self _buildOutputDeviceList];
  [self _buildInputDeviceList];
}

@end
