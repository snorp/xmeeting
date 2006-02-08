/*
 * $Id: XMVideoPreferencesModule.m,v 1.1 2006/02/08 23:25:54 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#import "XMVideoPreferencesModule.h"

#import "XMeeting.h"
#import "XMPreferencesWindowController.h"
#import "XMPreferencesManager.h"
#import "XMBooleanCell.h"

NSString *XMKey_VideoPreferencesModuleIdentifier = @"XMeeting_VideoPreferencesModule";

NSString *XMKey_NameIdentifier = @"Name";
NSString *XMKey_EnabledIdentifier = @"Enabled";
NSString *XMKey_SettingsIdentifier = @"Settings";

@interface XMVideoPreferencesModule (PrivateMethods)

- (void)_showSettingsDialog:(id)sender;

@end

@implementation XMVideoPreferencesModule

- (id)init
{
	prefWindowController = [[XMPreferencesWindowController sharedInstance] retain];
	
	return self;
}

- (void)awakeFromNib
{
	contentViewHeight = [contentView frame].size.height;
	
	XMBooleanCell *booleanCell = [[XMBooleanCell alloc] init];
	NSTableColumn *column = [videoModulesTableView tableColumnWithIdentifier:XMKey_EnabledIdentifier];
	[column setDataCell:booleanCell];
	[booleanCell release];
	
	NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
	[buttonCell setTitle:@"Show Settings..."];
	[buttonCell setControlSize:NSSmallControlSize];
	[buttonCell setBezelStyle:NSShadowlessSquareBezelStyle];
	[buttonCell setFont:[NSFont controlContentFontOfSize:[NSFont labelFontSize]]];
	[buttonCell setTarget:self];
	[buttonCell setAction:@selector(_showSettingsDialog:)];
	column = [videoModulesTableView tableColumnWithIdentifier:XMKey_SettingsIdentifier];
	[column setDataCell:buttonCell];
	[buttonCell release];
	
	[videoModulesTableView setRowHeight:16];
	
	[prefWindowController addPreferencesModule:self];
}

- (void)dealloc
{
	[prefWindowController release];
	
	[super dealloc];
}

- (unsigned)position
{
	return 2;
}

- (NSString *)identifier
{
	return XMKey_VideoPreferencesModuleIdentifier;
}

- (NSString *)toolbarLabel
{
	return NSLocalizedString(@"Video Input", @"VideoPreferencesModuleLabel");
}

- (NSImage *)toolbarImage
{
	return nil;
}

- (NSString *)toolTipText
{
	return NSLocalizedString(@"Video Input Preferences", @"VideoPreferencesModuleToolTip");
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
}

- (void)savePreferences
{
}

#pragma mark NSTableView methods

- (unsigned)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[XMVideoManager sharedInstance] videoModuleCount];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex
{
	NSString *columnIdentifier = [tableColumn identifier];
	id<XMVideoModule> videoModule = [[XMVideoManager sharedInstance] videoModuleAtIndex:rowIndex];
	
	if([columnIdentifier isEqualToString:XMKey_NameIdentifier])
	{
		return [videoModule name];
	}
	else if([columnIdentifier isEqualToString:XMKey_EnabledIdentifier])
	{
		return [NSNumber numberWithBool:[videoModule isEnabled]];
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *tableColumnIdentifier = [aTableColumn identifier];
	
	if([tableColumnIdentifier isEqualToString:XMKey_SettingsIdentifier])
	{
		id<XMVideoModule> module = [[XMVideoManager sharedInstance] videoModuleAtIndex:rowIndex];
		[(NSButtonCell *)aCell setEnabled:[module hasSettings]];
	}
}

#pragma mark User Interface Methods

- (void)_showSettingsDialog:(id)sender
{
	NSIndexSet *indexes = [videoModulesTableView selectedRowIndexes];
	unsigned index = [indexes firstIndex];
	
	id<XMVideoModule> module = [[XMVideoManager sharedInstance] videoModuleAtIndex:index];
	
	NSView *settingsView = [module settingsView];
	
	NSRect panelFrame = [videoModuleSettingsPanel frame];
	
	NSRect settingsViewFrame = [settingsView frame];
	NSRect currentSettingsViewFrame = [videoModuleSettingsBox frame];
	
	panelFrame.size.width += (settingsViewFrame.size.width - currentSettingsViewFrame.size.width);
	panelFrame.size.height += (settingsViewFrame.size.height - currentSettingsViewFrame.size.height);
	
	[videoModuleSettingsPanel setFrame:panelFrame display:NO];
	
	[videoModuleSettingsBox setContentView:settingsView];
	
	[NSApp beginSheet:videoModuleSettingsPanel modalForWindow:[contentView window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (IBAction)restoreDefaultVideoModuleSettings:(id)sender
{
	NSIndexSet *indexes = [videoModulesTableView selectedRowIndexes];
	unsigned index = [indexes firstIndex];
	
	id<XMVideoModule> module = [[XMVideoManager sharedInstance] videoModuleAtIndex:index];
	
	[module setDefaultSettings];
}

- (IBAction)closeVideoModuleSettingsPanel:(id)sender
{
	[NSApp endSheet:videoModuleSettingsPanel returnCode:NSOKButton];
	[videoModuleSettingsPanel orderOut:self];
	
	[videoModuleSettingsBox setContentView:nil];
}

@end
