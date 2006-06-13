/*
 * $Id: XMGeneralPreferencesModule.m,v 1.9 2006/06/13 20:27:18 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMGeneralPreferencesModule.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"

NSString *XMKey_GeneralPreferencesModuleIdentifier = @"XMeeting_GeneralPreferencesModule";

@interface XMGeneralPreferencesModule (PrivateMethods)

-(void)_chooseDebugFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end

@implementation XMGeneralPreferencesModule

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
	return 0;
}

- (NSString *)identifier
{
	return XMKey_GeneralPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"XM_GENERAL_PREFERENCES_NAME", @"");
}

- (NSImage *)toolbarImage
{
	return [NSImage imageNamed:@"generalPreferences.tif"];
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"XM_GENERAL_PREFERENCES_TOOLTIP", @"");
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
	
	[userNameField setStringValue:[prefManager userName]];
	
	int state = ([prefManager defaultAutomaticallyAcceptIncomingCalls] == YES) ? NSOnState : NSOffState;
	[automaticallyAcceptIncomingCallsSwitch setState:state];
	
	state = ([XMPreferencesManager enablePTrace] == YES) ? NSOnState : NSOffState;
	[generateDebugLogSwitch setState:state];
	
	NSString *debugLogFilePath = [XMPreferencesManager pTraceFilePath];
	if(debugLogFilePath == nil)
	{
		debugLogFilePath = @"";
	}
	[debugLogFilePathField setStringValue:debugLogFilePath];
	
	// validating the user interface
	[self toggleGenerateDebugLogFile:self];
}

- (void)savePreferences
{
	XMPreferencesManager *prefManager = [XMPreferencesManager sharedInstance];
	
	[prefManager setUserName:[userNameField stringValue]];
	
	BOOL flag = ([automaticallyAcceptIncomingCallsSwitch state] == NSOnState) ? YES : NO;
	[prefManager setDefaultAutomaticallyAcceptIncomingCalls:flag];
	
	flag = ([generateDebugLogSwitch state] == NSOnState) ? YES : NO;
	[XMPreferencesManager setEnablePTrace:flag];
	
	NSString *path = [debugLogFilePathField stringValue];
	[XMPreferencesManager setPTraceFilePath:path];
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
	
	if(![path isEqualToString:@""])
	{
		directory = [path stringByDeletingLastPathComponent];
		file = [path lastPathComponent];
	}
	
	[savePanel beginSheetForDirectory:directory file:file modalForWindow:[contentView window] modalDelegate:self
					   didEndSelector:@selector(_chooseDebugFilePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
	[self defaultAction:self];
}

#pragma mark -
#pragma mark Private Methods

-(void)_chooseDebugFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(returnCode == NSOKButton)
	{
		[debugLogFilePathField setStringValue:[sheet filename]];
		[self defaultAction:self];
	}
}

@end
