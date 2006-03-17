/*
 * $Id: XMInspectorController.m,v 1.3 2006/03/17 13:20:52 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Ivan Guajana. All rights reserved.
 */

#import "XMInspectorController.h"
#import "XMInspectorModule.h"

@interface XMInspectorController (PrivateMethods)

- (id)_initWithName:(NSString *)name;
- (void)_showModule:(XMInspectorModule *)module;
- (void)_setupInterface;
- (void)_resizeView;
- (void)_setMaxAndMinSizes;

@end


@implementation XMInspectorController

#pragma mark Class Methods

static XMInspectorController *inspectorInstance = nil;
static XMInspectorController *toolsInstance = nil;
static XMInspectorController *contactsInstance;

+ (XMInspectorController *)inspectorWithTag:(XMInspectorControllerTag)tag
{
	if(tag == XMInspectorControllerTag_Inspector)
	{
		if(inspectorInstance == nil)
		{
			inspectorInstance = [[XMInspectorController alloc] _initWithName:@"Inspector"];
		}
		
		return inspectorInstance;
	}
	else if(tag == XMInspectorControllerTag_Tools)
	{
		if(toolsInstance == nil)
		{
			toolsInstance = [[XMInspectorController alloc] _initWithName:@"Tools"];
		}
		
		return toolsInstance;
	}
	else if(tag == XMInspectorControllerTag_Contacts)
	{
		if(contactsInstance == nil)
		{
			contactsInstance = [[XMInspectorController alloc] _initWithName:@"Contacts"];
		}
		
		return contactsInstance;
	}
	
	return nil;
}

+ (void)closeAllInspectors
{
	[inspectorInstance close];
	[toolsInstance close];
	[contactsInstance close];
}

#pragma mark -
#pragma mark Init & Dealloc Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	return nil;
}

- (id)_initWithName:(NSString *)theName
{
	self = [super init];
	
	modules = nil;
	name = [theName copy];
	
	return self;
}

- (void)awakeFromNib
{
	[self _setupInterface];
}

- (void)dealloc
{
	[modules release];
	[name release];
	
	[super dealloc];
}

- (void)setModules:(NSArray *)theModules
{
	modules = [theModules copy];
}

#pragma mark -
#pragma mark Action Methods

- (IBAction)changePage:(id)sender
{
	XMInspectorModule *newModule = (XMInspectorModule *)[modules objectAtIndex:[pageController selectedSegment]];
	[self _showModule:newModule];
}

#pragma mark -
#pragma mark XMInspectorModule methods

- (void)moduleSizeChanged:(XMInspectorModule *)module
{
	[self _resizeView];
	[self _setMaxAndMinSizes];
}

- (void)moduleStatusChanged:(XMInspectorModule *)module
{
	unsigned index = [modules indexOfObject:module];
	
	if(index == NSNotFound)
	{
		return;
	}
	
	[pageController setEnabled:[module isEnabled] forSegment:index];
	
	if(module == activeModule && [module isEnabled] == YES)
	{
		// selecting the first enabled module
		unsigned i;
		unsigned count = [modules count];
		
		for(i = 0; i < count; i++)
		{
			if(i == index)
			{
				continue;
			}
			XMInspectorModule *theModule = (XMInspectorModule *)[modules objectAtIndex:i];
			
			if([theModule isEnabled] == YES)
			{
				[self _showModule:theModule];
				return;
			}
		}
		
		[self _showModule:nil];
	}
}

#pragma mark -
#pragma mark Public Methods

- (void)show
{
	if(panel == nil)
	{
		// loading the Nib file. The panel is shown automatically
		// inside -_showModule:
		[NSBundle loadNibNamed:@"XMInspector" owner:self];
	}
	else
	{
		[panel orderFront:self];
	}
}

- (void)close
{
	[panel orderOut:self];
}

#pragma mark -
#pragma mark Private Methods

- (void)_showModule:(XMInspectorModule *)module
{
	if(module == activeModule)
	{
		return;
	}
	
	[activeModule becomeInactiveModule];
	[contentBox setContentView:nil];
	
	activeModule = module;
	
	[self _resizeView];
	
	[contentBox setContentView:[activeModule contentView]];
	
	[panel orderFront:self];
	
	[activeModule becomeActiveModule];
		
	[self _setMaxAndMinSizes];
}

- (void)_setupInterface
{
	[panel setTitle:name];
	
	int moduleCount = [modules count];
	[pageController setSegmentCount:moduleCount];
	
	int i;
	for (i = 0; i < moduleCount; i++)
	{
		XMInspectorModule *curModule = (XMInspectorModule *)[modules objectAtIndex:i];
		
		[pageController setLabel:[curModule name] forSegment:i];
		[pageController setImage:[curModule image] forSegment:i];
		[pageController setEnabled:[curModule isEnabled] forSegment:i];
		[pageController setWidth:0 forSegment:i]; //autosize
	}
	
	[pageController setSelectedSegment:0];
	
	[self _showModule:(XMInspectorModule *)[modules objectAtIndex:0]];
}

- (void)_resizeView
{
	NSRect panelFrame = [panel frame];
	NSSize boxSize = [contentBox frame].size;
	NSSize moduleSize = [activeModule contentViewSize];
	
	float deltaX = moduleSize.width - boxSize.width;
	float deltaY = moduleSize.height - boxSize.height;
	
	panelFrame.size.width += deltaX;
	panelFrame.size.height += deltaY;
	panelFrame.origin.y -= deltaY;
	
	[panel setFrame:panelFrame display:YES animate:YES];
}

- (void)_setMaxAndMinSizes
{
	NSRect frame = [panel frame];
	NSSize currentSize = [activeModule contentViewSize];
	NSSize newMinSize = [activeModule contentViewMinSize];
	NSSize newMaxSize = [activeModule contentViewMaxSize];
	
	NSSize minSize = frame.size;
	int heightDifference = (int)currentSize.height - (int)newMinSize.height;
	int widthDifference = (int)currentSize.width - (int)newMinSize.width;
	minSize.height -= heightDifference;
	minSize.width -= widthDifference;
	[panel setMinSize:minSize];
	
	NSSize maxSize = frame.size;
	heightDifference = (int)newMaxSize.height - (int)currentSize.height;
	widthDifference = (int)newMaxSize.width - (int)currentSize.width;
	maxSize.height += heightDifference;
	maxSize.width += widthDifference;
	[panel setMaxSize:maxSize];
	
	BOOL windowIsResizable = ((minSize.width != maxSize.width) ||
							  (minSize.height != maxSize.height));
	
	[panel setShowsResizeIndicator:windowIsResizable];
}

@end
