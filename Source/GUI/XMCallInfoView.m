/*
 * $Id: XMCallInfoView.m,v 1.3 2006/03/16 14:13:57 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#import "XMeeting.h"
#import "XMCallInfoView.h"
#import "XMRecentCallsView.h"
#import "XMApplicationFunctions.h"

#define CORNER_RADIUS 15
#define LINE_HEIGHT 15
#define SMALL_LINE_HEIGHT 13
#define TEXT_OFFSET 8
#define VERTICAL_SPACING 4
#define HORIZONTAL_SPACING 10
#define DISCLOSURE_SIZE 11

#define DISCLOSURE_CLOSED 0
#define DISCLOSURE_OPEN 1
#define DISCLOSURE_CHANGING 2

@interface XMCallInfoView (PrivateMethods)

+ (NSColor *)_titleBackgroundColor;
+ (NSColor *)_titleTextColor;
+ (NSColor *)_contentBackgroundColor;
+ (NSColor *)_contentTextColor;
+ (NSFont *)_normalTextFont;
+ (NSFont *)_smallTextFont;

- (void)_calculateDisclosureRect:(NSRect)frameRect;
- (BOOL)_disclosureRectContainsPoint:(NSPoint)point;	// assumes point in window coordinates

- (void)_drawTitleWithSize:(NSSize)size;	// size of the whole frame must be given
- (void)_drawContentWithSize:(NSSize)size;	// size of the whole frame must be given
- (void)_drawDisclosure;
- (float)_calculateHeightForWidth:(float)width;

- (void)_createStrings;
- (void)_releaseStrings;

@end

@implementation XMCallInfoView

#pragma mark Init & Deallocation Methods

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	
	callInfo = nil;
	
	textDrawCell =  [[NSTextFieldCell alloc] init];
	[textDrawCell setDrawsBackground:NO];
	[textDrawCell setBezeled:NO];
	[textDrawCell setBordered:NO];
	
	[self _calculateDisclosureRect:frameRect];
	
	disclosureState = DISCLOSURE_CLOSED;
	
	return self;
}

- (void)dealloc
{
	[callInfo release];
	[textDrawCell release];
	
	[self _releaseStrings];
	
	[super dealloc];
}

#pragma mark Public Methods

- (XMCallInfo *)callInfo
{
	return callInfo;
}

- (void)setCallInfo:(XMCallInfo *)info
{
	XMCallInfo *old = callInfo;
	callInfo = [info retain];
	[old release];
}

- (float)requiredHeightForWidth:(float)width
{
	if(callInfo == nil)
	{
		return 0.0f;
	}
		
	return [self _calculateHeightForWidth:width];
}

#pragma mark NSView Methods

- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	
	[self _calculateDisclosureRect:frameRect];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint mousePoint = [theEvent locationInWindow];
	if([self _disclosureRectContainsPoint:mousePoint])
	{
		disclosureState += DISCLOSURE_CHANGING;
		[self setNeedsDisplayInRect:disclosureRect];
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint mousePoint = [theEvent locationInWindow];
	if([self _disclosureRectContainsPoint:mousePoint])
	{
		disclosureState -= DISCLOSURE_CHANGING;
		disclosureState = !disclosureState;
		[(XMRecentCallsView *)[self superview] noteSubviewHeightDidChange:self];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint mousePoint = [theEvent locationInWindow];
	if([self _disclosureRectContainsPoint:mousePoint])
	{
		if(disclosureState < DISCLOSURE_CHANGING)
		{
			disclosureState += DISCLOSURE_CHANGING;
			[self setNeedsDisplayInRect:disclosureRect];
		}
	}
	else
	{
		if(disclosureState >= DISCLOSURE_CHANGING)
		{
			disclosureState -= DISCLOSURE_CHANGING;
			[self setNeedsDisplayInRect:disclosureRect];
		}
	}
}

- (void)drawRect:(NSRect)rect
{
	// optimization for the case we only need to redraw the disclosure
	if(NSEqualRects(rect, disclosureRect))
	{
		NSColor *contentColor = [NSColor selectedControlColor];
		[contentColor setFill];
		[NSBezierPath fillRect:rect];
		
		[self _drawDisclosure];
		return;
	}
	
	// creating the strings
	[self _createStrings];
	
	// fetching the sizes we have to draw
	NSSize size = [self bounds].size;
	
	// drawing the title
	[self _drawTitleWithSize:size];

	// drawing the content
	[self _drawContentWithSize:size];
	
	// last, but not least, draw the disclosure
	[self _drawDisclosure]; 
	
	// releasing the strings again
	if(![self inLiveResize])
	{
		[self _releaseStrings];
	}
}

- (void)viewDidEndLiveResize
{
	[self _releaseStrings];
}

#pragma mark Private Methods

+ (NSColor *)_titleBackgroundColor
{
	return [NSColor selectedMenuItemColor];
}

+ (NSColor *)_titleTextColor
{
	return [NSColor selectedMenuItemTextColor];
}

+ (NSColor *)_contentBackgroundColor
{
	return [NSColor selectedControlColor];
}

+ (NSColor *)_contentTextColor
{
	return [NSColor controlTextColor];
}

+ (NSFont *)_normalTextFont
{
	return [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
}

+ (NSFont *)_smallTextFont
{
	return [NSFont systemFontOfSize:[NSFont labelFontSize]];
}

- (void)_calculateDisclosureRect:(NSRect)frameRect
{
	disclosureRect = NSMakeRect(TEXT_OFFSET, 
								frameRect.size.height - 2*LINE_HEIGHT + (LINE_HEIGHT - DISCLOSURE_SIZE) / 2,
								DISCLOSURE_SIZE,
								DISCLOSURE_SIZE);
}

- (BOOL)_disclosureRectContainsPoint:(NSPoint)point
{
	NSPoint convertedPoint = [self convertPoint:point fromView:nil];
	return NSPointInRect(convertedPoint, disclosureRect);
}

- (void)_drawTitleWithSize:(NSSize)size;
{
	[[XMCallInfoView _titleBackgroundColor] setFill];
	
	float width = size.width;
	float height = size.height;
	
	NSBezierPath *titlePath = [NSBezierPath bezierPath];
	[titlePath moveToPoint:NSMakePoint(0, height - CORNER_RADIUS)];
	[titlePath curveToPoint:NSMakePoint(CORNER_RADIUS, height)
			  controlPoint1:NSMakePoint(0, height)
			  controlPoint2:NSMakePoint(0, height)];
	[titlePath lineToPoint:NSMakePoint(width - CORNER_RADIUS, height)];
	[titlePath curveToPoint:NSMakePoint(width, height - CORNER_RADIUS)
			  controlPoint1:NSMakePoint(width, height)
			  controlPoint2:NSMakePoint(width, height)];
	[titlePath closePath];
	[titlePath fill];
	
	// setting the color to be used for the title
	[textDrawCell setTextColor:[XMCallInfoView _titleTextColor]];
	[textDrawCell setFont:[XMCallInfoView _normalTextFont]];
	
	// drawing the title
	NSString *title = [callInfo remoteName];
	if(title == nil)
	{
		title = [callInfo callAddress];
	}
	[textDrawCell setStringValue:title];
	NSRect drawRect = NSMakeRect(TEXT_OFFSET,
								 height - CORNER_RADIUS - 1,
								 width - 2*TEXT_OFFSET,
								 CORNER_RADIUS);
	[textDrawCell drawWithFrame:drawRect inView:self];
}

- (void)_drawContentWithSize:(NSSize)size
{
	[[XMCallInfoView _contentBackgroundColor] setFill];
	
	float width = size.width;
	float height = size.height;
	
	NSRect drawRect;
	NSSize cellSize;
	
	// drawing the background
	NSBezierPath *contentPath = [NSBezierPath bezierPath];
	[contentPath moveToPoint:NSMakePoint(0, height - CORNER_RADIUS)];
	[contentPath lineToPoint:NSMakePoint(width, height - CORNER_RADIUS)];
	[contentPath lineToPoint:NSMakePoint(width, CORNER_RADIUS)];
	[contentPath curveToPoint:NSMakePoint(width - CORNER_RADIUS, 0)
				controlPoint1:NSMakePoint(width, 0)
				controlPoint2:NSMakePoint(width, 0)];
	[contentPath lineToPoint:NSMakePoint(CORNER_RADIUS, 0)];
	[contentPath curveToPoint:NSMakePoint(0, CORNER_RADIUS)
				controlPoint1:NSMakePoint(0, 0)
				controlPoint2:NSMakePoint(0, 0)];
	[contentPath closePath];
	[contentPath fill];
	
	// obtaining the text color
	[textDrawCell setTextColor:[XMCallInfoView _contentTextColor]];
	
	if(disclosureState == DISCLOSURE_CLOSED || callStartString == nil)
	{
		[textDrawCell setFont:[XMCallInfoView _normalTextFont]];
		
		// drawing the end date
		[textDrawCell setStringValue:endDateString];
		cellSize = [textDrawCell cellSize];
		drawRect = NSMakeRect(width - cellSize.width - TEXT_OFFSET,
							  height - 2*LINE_HEIGHT - 1,
							  cellSize.width, 
							  LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
	}
	else
	{
		cellSize.width = -HORIZONTAL_SPACING;
	}
	
	// drawing the ShowDetails / HideDetais text
	[textDrawCell setFont:[XMCallInfoView _smallTextFont]];
	float remainingWidth = width - cellSize.width - 2*TEXT_OFFSET - HORIZONTAL_SPACING - DISCLOSURE_SIZE;
	
	NSString *detailsString;
	if(disclosureState == DISCLOSURE_CLOSED)
	{
		detailsString = @"Show Details";
	}
	else
	{
		detailsString = @"Hide Details";
	}
	[textDrawCell setStringValue:detailsString];

	drawRect = NSMakeRect(TEXT_OFFSET + DISCLOSURE_SIZE,
						  height - 2*LINE_HEIGHT - 1,
						  remainingWidth, 
						  LINE_HEIGHT);
	[textDrawCell drawWithFrame:drawRect inView:self];
		
	if(disclosureState == DISCLOSURE_CLOSED)
	{
		return;
	}
	
	float x = 2*TEXT_OFFSET;
	float y = height - 2*LINE_HEIGHT - VERTICAL_SPACING - SMALL_LINE_HEIGHT;
	float availableWidth = width - 3*TEXT_OFFSET;
	
	// drawing the callStart date
	if(callStartString != nil)
	{
		[textDrawCell setStringValue:callStartString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			cellSize.width = availableWidth;
		}
		drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
	
		x += cellSize.width + HORIZONTAL_SPACING;
		availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
	
		// drawing the callEnd date
		[textDrawCell setStringValue:callEndString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			x = 2*TEXT_OFFSET;
			y -= SMALL_LINE_HEIGHT;
			cellSize.width = width - 3*TEXT_OFFSET - HORIZONTAL_SPACING - availableWidth;
			[textDrawCell setAlignment:NSRightTextAlignment];
			availableWidth = width - 3*TEXT_OFFSET;
		}
		drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
	
		x += cellSize.width + HORIZONTAL_SPACING;
		availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
		[textDrawCell setAlignment:NSLeftTextAlignment];
	
		// drawing the callDuration
		[textDrawCell setStringValue:callDurationString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			x = 2*TEXT_OFFSET;
			y -= SMALL_LINE_HEIGHT;
			availableWidth = width - 3*TEXT_OFFSET;
		
			if(cellSize.width > availableWidth)
			{
				cellSize.width = availableWidth;
			}
		}
		drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
		
		// adjusting the x/y location
		x = 2*TEXT_OFFSET;
		y -= (SMALL_LINE_HEIGHT + VERTICAL_SPACING);
		availableWidth = width - 3*TEXT_OFFSET;
	}
	
	// drawing the direction of the call
	[textDrawCell setStringValue:callDirectionString];
	cellSize = [textDrawCell cellSize];
	if(cellSize.width > availableWidth)
	{
		cellSize.width = availableWidth;
	}
	drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
	[textDrawCell drawWithFrame:drawRect inView:self];
	
	// adjusting the x/availableWidth values
	x += (cellSize.width + HORIZONTAL_SPACING);
	availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
	
	// drawing the callEndReason
	[textDrawCell setStringValue:endReasonString];
	cellSize = [textDrawCell cellSize];
	if(cellSize.width > availableWidth)
	{
		x = 2*TEXT_OFFSET;
		y -= SMALL_LINE_HEIGHT;
		availableWidth = width - 3*TEXT_OFFSET;
		
		if(cellSize.width > availableWidth)
		{
			cellSize.width = availableWidth;
		}
	}
	drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
	[textDrawCell drawWithFrame:drawRect inView:self];
	
	// only draw additional infos if the call really was established
	if(callStartString == nil)
	{
		return;
	}
	
	x = 2*TEXT_OFFSET;
	y -= (SMALL_LINE_HEIGHT + VERTICAL_SPACING);
	availableWidth = width - 3*TEXT_OFFSET;
	BOOL didDrawSection = NO;
	
	// drawing the remote number
	if(remoteNumberString != nil)
	{
		[textDrawCell setStringValue:remoteNumberString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			cellSize.width = availableWidth;
		}
		drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
		
		x += (cellSize.width + HORIZONTAL_SPACING);
		availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
		
		didDrawSection = YES;
	}
	
	if(remoteAddressString != nil)
	{
		[textDrawCell setStringValue:remoteAddressString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			x = 2*TEXT_OFFSET;
			y -= SMALL_LINE_HEIGHT;
			availableWidth = width - 3*TEXT_OFFSET;
			
			if(cellSize.width > availableWidth)
			{
				cellSize.width = availableWidth;
			}
		}
		drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
		
		x += (cellSize.width + HORIZONTAL_SPACING);
		availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
		
		didDrawSection = YES;
	}
	
	if(remoteApplicationString != nil)
	{
		[textDrawCell setStringValue:remoteApplicationString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			x = 2*TEXT_OFFSET;
			y -= SMALL_LINE_HEIGHT;
			availableWidth = width - 3*TEXT_OFFSET;
			
			if(cellSize.width > availableWidth)
			{
				cellSize.width = availableWidth;
			}
		}
		drawRect = NSMakeRect(x, y, cellSize.width, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
		
		didDrawSection = YES;
	}
	
	// starting a new subsection
	if(didDrawSection == YES)
	{
		x = 2*TEXT_OFFSET;
		y -= (SMALL_LINE_HEIGHT + VERTICAL_SPACING);
		availableWidth = width - 3*TEXT_OFFSET;
	}
	
	if(audioOutString != nil || audioInString != nil)
	{
		[textDrawCell setStringValue:@"Audio:"];
		drawRect = NSMakeRect(x, y, availableWidth, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
		
		y -= SMALL_LINE_HEIGHT;
		
		if(audioOutString != nil)
		{
			[textDrawCell setStringValue:audioOutString];
			drawRect = NSMakeRect(x, y, availableWidth, SMALL_LINE_HEIGHT);
			[textDrawCell drawWithFrame:drawRect inView:self];
			
			y -= SMALL_LINE_HEIGHT;
		}
		if(audioInString != nil)
		{
			[textDrawCell setStringValue:audioInString];
			drawRect = NSMakeRect(x, y, availableWidth, SMALL_LINE_HEIGHT);
			[textDrawCell drawWithFrame:drawRect inView:self];
			
			y -= SMALL_LINE_HEIGHT;
		}
		
		y -= VERTICAL_SPACING;
	}
	
	if(videoOutString != nil || videoInString != nil)
	{
		[textDrawCell setStringValue:@"Video:"];
		drawRect = NSMakeRect(x, y, availableWidth, SMALL_LINE_HEIGHT);
		[textDrawCell drawWithFrame:drawRect inView:self];
		
		y -= SMALL_LINE_HEIGHT;
		
		if(videoOutString != nil)
		{
			[textDrawCell setStringValue:videoOutString];
			drawRect = NSMakeRect(x, y, availableWidth, SMALL_LINE_HEIGHT);
			[textDrawCell drawWithFrame:drawRect inView:self];
			
			y -= SMALL_LINE_HEIGHT;
		}
		if(videoInString != nil)
		{
			[textDrawCell setStringValue:videoInString];
			drawRect = NSMakeRect(x, y, availableWidth, SMALL_LINE_HEIGHT);
			[textDrawCell drawWithFrame:drawRect inView:self];
			
			y -= SMALL_LINE_HEIGHT;
		}
		
		y -= VERTICAL_SPACING;
	}
}

- (void)_drawDisclosure
{
	NSColor *color;
	
	if(disclosureState >= DISCLOSURE_CHANGING)
	{
		color = [NSColor darkGrayColor];
	}
	else
	{
		color = [NSColor grayColor];
	}
	[color setFill];
	
	NSBezierPath *trianglePath = [NSBezierPath bezierPath];
	
	float x = disclosureRect.origin.x;
	float y = disclosureRect.origin.y;
	
	if(disclosureState == DISCLOSURE_CLOSED)
	{
		[trianglePath moveToPoint:NSMakePoint(x+2, y+2)];
		[trianglePath lineToPoint:NSMakePoint(x+9, y+6)];
		[trianglePath lineToPoint:NSMakePoint(x+2, y+10)];
	}
	else if(disclosureState == DISCLOSURE_OPEN)
	{
		[trianglePath moveToPoint:NSMakePoint(x+2, y+9)];
		[trianglePath lineToPoint:NSMakePoint(x+10, y+9)];
		[trianglePath lineToPoint:NSMakePoint(x+6, y+2)];
	}
	else
	{
		[trianglePath moveToPoint:NSMakePoint(x+1, y+4)];
		[trianglePath lineToPoint:NSMakePoint(x+9, y+2)];
		[trianglePath lineToPoint:NSMakePoint(x+7, y+10.5)];
	}
	[trianglePath closePath];
	
	[trianglePath fill];
}

- (float)_calculateHeightForWidth:(float)width
{
	float height = 2*LINE_HEIGHT;
	
	unsigned state = disclosureState;
	if(state > DISCLOSURE_CHANGING)
	{
		state -= DISCLOSURE_CHANGING;
	}
	if(state == DISCLOSURE_CLOSED)
	{
		return height;
	}
	
	height += VERTICAL_SPACING;
	
	[self _createStrings];
	[textDrawCell setFont:[XMCallInfoView _smallTextFont]];
	
	height += (VERTICAL_SPACING + SMALL_LINE_HEIGHT);
	float availableWidth = width - 3*TEXT_OFFSET;
	NSSize cellSize;
	
	if(callStartString != nil)
	{
		[textDrawCell setStringValue:callStartString];
		cellSize = [textDrawCell cellSize];
		availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
		
		[textDrawCell setStringValue:callEndString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			height += SMALL_LINE_HEIGHT;
		}
		else
		{
			availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
		}
		
		[textDrawCell setStringValue:callDurationString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			height += SMALL_LINE_HEIGHT;
		}
		
		height += (VERTICAL_SPACING + SMALL_LINE_HEIGHT);
		availableWidth = width - 3*TEXT_OFFSET;
	}
	
	[textDrawCell setStringValue:callDirectionString];
	cellSize = [textDrawCell cellSize];
	availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
	
	[textDrawCell setStringValue:endReasonString];
	cellSize = [textDrawCell cellSize];
	if(cellSize.width > availableWidth)
	{
		height += SMALL_LINE_HEIGHT;
	}
	
	if(callStartString == nil)
	{
		NSLog(@"2");
		return height;
	}

	if(remoteNumberString != nil ||
	   remoteAddressString != nil ||
	   remoteApplicationString != nil)
	{
		height += (SMALL_LINE_HEIGHT + VERTICAL_SPACING);
	}
	availableWidth = width - 3*TEXT_OFFSET;
	
	if(remoteNumberString != nil)
	{
		[textDrawCell setStringValue:remoteNumberString];
		cellSize = [textDrawCell cellSize];
		availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
	}
	
	if(remoteAddressString != nil)
	{
		[textDrawCell setStringValue:remoteAddressString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			height += SMALL_LINE_HEIGHT;
			availableWidth = width - 3*TEXT_OFFSET;
		}
		else
		{
			availableWidth -= (cellSize.width + HORIZONTAL_SPACING);
		}
	}
	
	if(remoteApplicationString != nil)
	{
		[textDrawCell setStringValue:remoteApplicationString];
		cellSize = [textDrawCell cellSize];
		if(cellSize.width > availableWidth)
		{
			height += SMALL_LINE_HEIGHT;
		}
	}
	
	if(audioOutString != nil ||
	   audioInString != nil ||
	   videoOutString != nil ||
	   videoInString != nil)
	{
		height += VERTICAL_SPACING;
	}
	availableWidth = width - 3*TEXT_OFFSET;
	
	if(audioOutString != nil && audioInString != nil)
	{
		height += 3*SMALL_LINE_HEIGHT + VERTICAL_SPACING;
	}
	else if(audioOutString != nil || audioInString != nil)
	{
		height += 2*SMALL_LINE_HEIGHT + VERTICAL_SPACING;
	}
	
	if(videoOutString != nil && videoInString != nil)
	{
		height += 3*SMALL_LINE_HEIGHT + VERTICAL_SPACING;
	}
	else if(videoOutString != nil || videoInString != nil)
	{
		height += 2*SMALL_LINE_HEIGHT + VERTICAL_SPACING;
	}
	
	NSLog(@"3");
	return height;
}

- (void)_createStrings
{
	if(endDateString != nil) // strings already created
	{
		return;
	}
	
	NSDate *endDate = [callInfo callEndDate];
	endDateString = [[endDate descriptionWithCalendarFormat:XMDateFormatString()
												   timeZone:nil
													 locale:nil] retain];
	
	if([callInfo isOutgoingCall] == YES)
	{
		callDirectionString = @"Direction: Out";
	}
	else
	{
		callDirectionString = @"Direction: In";
	}
	
	NSString *endReason = XMCallEndReasonString([callInfo callEndReason]);
	endReasonString = [[NSString alloc] initWithFormat:@"Call End Reason: %@", endReason];
	
	NSDate *startDate = [callInfo callInitiationDate];
	if(startDate != nil)
	{
		NSString *startDateString = [startDate descriptionWithCalendarFormat:XMDateFormatString()
																	timeZone:nil
																	  locale:nil];
		callStartString = [[NSString alloc] initWithFormat:@"Start: %@", startDateString];
		callEndString = [[NSString alloc] initWithFormat:@"End: %@", endDateString];
		
		NSString *callDuration = XMTimeString((unsigned)[callInfo callDuration]);
		callDurationString = [[NSString alloc] initWithFormat:@"Duration: %@", callDuration];
		
		NSString *remoteNumber = [callInfo remoteNumber];
		if(remoteNumber != nil)
		{
			remoteNumberString = [[NSString alloc] initWithFormat:@"Remote Number: %@", remoteNumber];
		}
		
		NSString *remoteAddress = [callInfo remoteAddress];
		if(remoteAddress != nil)
		{
			remoteAddressString = [[NSString alloc] initWithFormat:@"Remote Address: %@", remoteAddress];
		}
		
		NSString *remoteApplication = [callInfo remoteApplication];
		if(remoteApplication != nil)
		{
			remoteApplicationString = [[NSString alloc] initWithFormat:@"Remote Application: %@", remoteApplication];
		}
		
		NSString *audioCodecOut = [callInfo outgoingAudioCodec];
		if(audioCodecOut != nil)
		{
			NSString *bytesSentString = XMByteString([callInfo audioBytesSent]);
			audioOutString = [[NSString alloc] initWithFormat:@"%@ sent using <%@>", bytesSentString, audioCodecOut];
		}
		
		NSString *audioCodecIn = [callInfo incomingAudioCodec];
		if(audioCodecIn != nil)
		{
			NSString *bytesReceivedString = XMByteString([callInfo audioBytesReceived]);
			audioInString = [[NSString alloc] initWithFormat:@"%@ received using <%@>", bytesReceivedString, audioCodecIn];
		}
		
		NSString *videoCodecOut = [callInfo outgoingVideoCodec];
		if(videoCodecOut != nil)
		{
			NSString *bytesSentString = XMByteString([callInfo videoBytesSent]);
			videoOutString = [[NSString alloc] initWithFormat:@"%@ sent using <%@>", bytesSentString, videoCodecOut];
		}
		
		NSString *videoCodecIn = [callInfo incomingVideoCodec];
		if(videoCodecIn != nil)
		{
			NSString *bytesReceivedString = XMByteString([callInfo videoBytesReceived]);
			videoInString = [[NSString alloc] initWithFormat:@"%@ received using <%@>", bytesReceivedString, videoCodecIn];
		}
	}
}

- (void)_releaseStrings
{
	[endDateString release];
	endDateString = nil;
	
	callDirectionString = nil;
	
	[endReasonString release];
	endReasonString = nil;
	
	if(callStartString != nil)
	{
		[callStartString release];
		callStartString = nil;
		
		[callEndString release];
		callEndString = nil;
		
		[callDurationString release];
		callDurationString = nil;
		
		[remoteNumberString release];
		remoteNumberString = nil;
		
		[remoteAddressString release];
		remoteAddressString = nil;
		
		[remoteApplicationString release];
		remoteApplicationString = nil;
		
		[audioOutString release];
		audioOutString = nil;
		
		[audioInString release];
		audioInString = nil;
		
		[videoOutString release];
		videoInString = nil;
		
		[videoInString release];
		videoInString = nil;
	}
}

@end
