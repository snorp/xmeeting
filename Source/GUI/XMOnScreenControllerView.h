/*
 * $Id: XMOnScreenControllerView.h,v 1.1 2006/02/22 16:12:33 zmit Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Ivan Guajana. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


#define SmallButtonWidth 30.0
#define SmallButtonHeight 24.0
#define LargeButtonWidth 60.0
#define LargeButtonHeight 48.0
#define SmallSeparatorWidth 10.0
#define LargeSeparatorWidth 20.0

#define XM_OSD_Separator @"separator"

enum { OSD_SMALL = 0, OSD_LARGE = 1};

@interface XMOnScreenControllerView : NSView {	
	NSColor *backgroundColor;
	
	NSRect bkgrRect;
	
	int OSDSize;
	float buttonWidth, buttonHeight, separatorWidth, separatorHeight;
	
	/*Array containing the buttons to be displayed
	*Each button is stored as a dictionary with the following keys:
	*
	*Icons - NSArray
	*PressedIcons - NSArray of NSImage
	*Selectors - NSArray of selector
	*Targets - NSArray of NSObject
	*Tooltips - NSArray of NSString
	*CurrentStateIndex - NSNumber
	*IsPressed - NSNumber wrapping BOOL
	*Rect - NSRect
	*Name - NSString
	*
	* OR
	*
	* A separator, which is a string defined by XM_OSD_Separator
	*/
	
	NSMutableArray *buttons;
	int currentPressedButtonIndex;

	int numberOfButtons, numberOfSeparators;

}

- (id)initWithFrame:(NSRect)frameRect andSize:(int)size;

//Managing buttons
- (void)addButton:(NSMutableDictionary*)newBtn;
- (void)addButtons:(NSArray*)newButtons;
- (void)insertButton:(NSMutableDictionary*)btn atIndex:(int)idx;
- (void)removeButton:(NSMutableDictionary*)btn;
- (void)removeButtonAtIndex:(int)idx;

//Creating buttons
- (NSMutableDictionary*)createButtonNamed:(NSString*)name tooltips:(NSArray*)tooltips icons:(NSArray*)icons pressedIcons:(NSArray*)pressedIcons selectors:(NSArray*)selectors targets:(NSArray*)targets currentStateIndex:(int)currentIdx;

//Get&Set
- (NSRect)osdRect;
- (void)setOSDSize:(int)s;
@end
