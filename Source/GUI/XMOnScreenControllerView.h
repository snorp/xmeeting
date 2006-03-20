/*
 * $Id: XMOnScreenControllerView.h,v 1.3 2006/03/20 23:25:24 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Ivan Guajana. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

extern NSString *XM_OSD_Separator;

typedef enum XMOSDSize
{
	XMOSDSize_Small = 0,
	XMOSDSize_Large = 1
	
} XMOSDSize;

@interface XMOnScreenControllerView : NSView {
	
	NSColor *backgroundColor;
	
	NSRect bkgrRect;
	
	XMOSDSize osdSize;
	float buttonWidth, buttonHeight, separatorWidth, separatorHeight;
	
	/*Array containing the buttons to be displayed
	*Each button is stored as a dictionary with the following keys:
	*
	*Icons - NSArray of NSImage
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

- (id)initWithFrame:(NSRect)frameRect andSize:(XMOSDSize)size;

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
- (void)setOSDSize:(XMOSDSize)s;

@end
