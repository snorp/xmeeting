/*
 * $Id: XMBooleanCell.h,v 1.4 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_BOOLEAN_CELL_H__
#define __XM_BOOLEAN_CELL_H__

#import <Cocoa/Cocoa.h>

/**
 * This cell displays a Boolean value in a textual representation and edits the value through
 * a simple PopUp Menu containing the two boolean values
 **/
@interface XMBooleanCell : NSComboBoxCell {

}

- (BOOL)doesPopUp;
- (void)setDoesPopUp:(BOOL)flag;

@end

#endif // __XM_BOOLEAN_CELL_H__
