/*
 * $Id: XMDebugPreferencesModule.m,v 1.2 2008/12/27 08:04:38 hfriederich Exp $
 *
 * Copyright (c) 2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2008 Hannes Friederich. All rights reserved.
 */

#import "XMDebugPreferencesModule.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"

NSString *XMKey_DebugPreferencesModuleIdentifier = @"XMeeting_DebugPreferencesModule";

@interface XMDebugPreferencesModule (PrivateMethods)

- (void)_chooseDebugFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)_alertNoDebugFilePath;

@end

@implementation XMDebugPreferencesModule

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
  return 7;
}

- (NSString *)identifier
{
  return XMKey_DebugPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
  return NSLocalizedString(@"XM_DEBUG_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
  return [NSImage imageNamed:@"debugPreferences.tif"];
}

- (NSString *)toolTipText
{
  return NSLocalizedString(@"XM_DEBUG_PREFERENCES_TOOLTIP", @"");
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
  int state = ([XMPreferencesManager enablePTrace] == YES) ? NSOnState : NSOffState;
  [generateDebugLogSwitch setState:state];
  
  NSString *debugLogFilePath = [XMPreferencesManager pTraceFilePath];
  if (debugLogFilePath == nil) {
    debugLogFilePath = @"";
  }
  [debugLogFilePathField setStringValue:debugLogFilePath];
  
  // validating the user interface
  [self toggleGenerateDebugLogFile:self];
}

- (void)savePreferences
{
  BOOL flag = ([generateDebugLogSwitch state] == NSOnState) ? YES : NO;
  [XMPreferencesManager setEnablePTrace:flag];
  
  NSString *path = [debugLogFilePathField stringValue];
  [XMPreferencesManager setPTraceFilePath:path];
}

- (void)becomeActiveModule
{
}

- (BOOL)validateData
{
  if ([generateDebugLogSwitch state] == NSOnState) {
    NSString *path = [debugLogFilePathField stringValue];
    if (path == nil || [path length] == 0) {
      [self _alertNoDebugFilePath];
      return NO;
    }
  }
  return YES;
}

#pragma mark -
#pragma mark Action & Delegate Methods

- (IBAction)defaultAction:(id)sender
{
  [prefWindowController notePreferencesDidChange];
}

- (IBAction)toggleGenerateDebugLogFile:(id)sender
{
  int state = [generateDebugLogSwitch state];
  BOOL enableButton = (state == NSOnState) ? YES : NO;
  
  [chooseDebugLogFilePathButton setEnabled:enableButton];
  
  [self defaultAction:self];
}

- (IBAction)chooseDebugFilePath:(id)sender
{
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  NSString *path = [debugLogFilePathField stringValue];
  
  NSString *directory = nil;
  NSString *file = nil;
  
  [savePanel setPrompt:NSLocalizedString(@"XM_GENERAL_PREFERENCES_CHOOSE", @"")];
  
  if (![path isEqualToString:@""]) {
    directory = [path stringByDeletingLastPathComponent];
    file = [path lastPathComponent];
  }
  
  [savePanel beginSheetForDirectory:directory file:file modalForWindow:[contentView window] modalDelegate:self
                     didEndSelector:@selector(_chooseDebugFilePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

#pragma mark -
#pragma mark Private Methods

-(void)_chooseDebugFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSOKButton) {
    [debugLogFilePathField setStringValue:[sheet filename]];
    [self defaultAction:self];
  }
}


- (void)_alertNoDebugFilePath
{
  NSAlert *alert = [[NSAlert alloc] init];
  
  [alert setMessageText:NSLocalizedString(@"XM_DEBUG_PREFERENCES_NO_FILE_PATH", @"")];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
  
  [alert runModal];
  
  [alert release];
}

@end
