/*
 * $Id: XMCallManager.mm,v 1.1 2005/02/11 12:58:44 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMCallManager.h"
#import "XMPrivate.h"

#import "XMCallInfo.h"
#import "XMPreferences.h"
#import "XMBridge.h"


@implementation XMCallManager

#pragma mark Class Methods

+ (XMCallManager *)sharedInstance
{
	static XMCallManager *sharedInstance = nil;
	
	if(!sharedInstance)
	{
		sharedInstance = [[XMCallManager alloc] init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	self = [super init];
	
	delegate = nil;
	activePreferences = nil;
	
	activeCall = nil;
	
	//initializing the underlying OPAL system
	initOPAL();
	
	return self;
}

- (void)dealloc
{
	[self setDelegate:nil];
	
	[activePreferences release];
	[activeCall release];
	
	[super dealloc];
}

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)theDelegate
{
	delegate = theDelegate;
}

- (BOOL)startH323Listening
{
	return startH323Listeners();
}

- (void)stopH323Listening
{
	stopH323Listeners();
}

- (BOOL)isH323Listening
{
	return isH323Listening();
}

- (XMPreferences *)activePreferences
{
	return activePreferences;
}

- (void)setActivePreferences:(XMPreferences *)prefs
{
}

#pragma mark Private Methods

- (void)_handleIncomingCall:(unsigned)callID 
				   protocol:(XMCallProtocol)protocol
				 remoteName:(NSString *)remoteName
			   remoteNumber:(NSString *)remoteNumber
			  remoteAddress:(NSString *)remoteAddress
		  remoteApplication:(NSString *)remoteApplication
{
	XMCallInfo *info = [[XMCallInfo alloc] _initWithCallID:callID
												  protocol:protocol
												remoteName:remoteName
											  remoteNumber:remoteNumber
											 remoteAddress:remoteAddress
										 remoteApplication:remoteApplication
												 callStatus:XMCallStatus_Incoming];
	
	[self performSelectorOnMainThread:@selector(_handleIncomingCall:)
						   withObject:info
						waitUntilDone:NO];
	
	[info release];
}

- (void)_handleIncomingCall:(XMCallInfo *)callInfo
{
	if(activeCall != nil)
	{
		[activeCall release];
		// do something here
	}
	
	activeCall = [callInfo retain];
	
	// replace this by a call to the delegate
	int result = NSRunAlertPanel(@"Incoming Call", 
								 @"%@, %@, %@, %@",
								 @"Accept", 
								 @"Reject", 
								 nil, 
								 [callInfo remoteName],
								 [callInfo remoteNumber],
								 [callInfo remoteAddress],
								 [callInfo remoteApplication]);
	
	if(result == NSOKButton)
	{
		setAcceptCall(true);
	}
	else
	{
		setAcceptCall(false);
	}
}

-(void)_handleCallEstablished:(unsigned)callID
{
	if([activeCall _callID] != callID)
	{
		// do something here!
		NSLog(@"callID mismatch");
	}
	NSLog(@"call with %@ established", [activeCall remoteName]);
	
	[activeCall _setCallStatus:XMCallStatus_Active];
}

- (void)_handleCallCleared:(unsigned)callID withCallEndReason:(XMCallEndReason)endReason
{
	if([activeCall _callID] != callID)
	{
		NSLog(@"callID mismatch");
	}
	NSLog(@"call with %@ ended", [activeCall remoteName]);
	[activeCall _setCallStatus:XMCallStatus_Ended];
	[activeCall _setCallEndReason:endReason];
}

@end
