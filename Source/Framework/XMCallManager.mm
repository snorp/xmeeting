/*
 * $Id: XMCallManager.mm,v 1.2 2005/04/28 20:26:26 hfriederich Exp $
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

NSString *XMNotification_IncomingCall = @"XMeeting_IncomingCallNotification";
NSString *XMNotification_CallEstablished = @"XMeeting_CallEstablishedNotification";
NSString *XMNotification_CallEnd = @"XMeeting_CallEndNotification";

@interface XMCallManager (PrivateMethods)

- (id)_init;

@end

@implementation XMCallManager

/*
 * This code uses the following policy to ensure
 * data integrity:
 * all changes in the callInfo instance activeCall
 * happens on the main thread.
 */

#pragma mark Class Methods

+ (XMCallManager *)sharedInstance
{
	static XMCallManager *sharedInstance = nil;
	
	if(!sharedInstance)
	{
		sharedInstance = [[XMCallManager alloc] _init];
	}
	
	return sharedInstance;
}

#pragma mark Init & Deallocation Methods

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	
	return nil;
}

- (id)_init
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
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if(delegate != nil) // we need to unregister the old delegate
	{
		[nc removeObserver:delegate name:XMNotification_IncomingCall object:nil];
		[nc removeObserver:delegate name:XMNotification_CallEstablished object:nil];
		[nc removeObserver:delegate name:XMNotification_CallEnd object:nil];
	}
	
	delegate = theDelegate;
	
	if(delegate != nil)
	{
		/* registering the delegate for the implemented delegate methods */
		if([delegate respondsToSelector:@selector(callManagerDidReceiveIncomingCall:)])
		{
			[nc addObserver:delegate selector:@selector(callManagerDidReceiveIncomingCall:)
					   name:XMNotification_IncomingCall object:nil];
		}
		if([delegate respondsToSelector:@selector(callManagerDidEstablishCall:)])
		{
			[nc addObserver:delegate selector:@selector(callManagerDidEstablishCall:)
					   name:XMNotification_CallEstablished object:nil];
		}
		if([delegate respondsToSelector:@selector(callManagerDidEndCall:)])
		{
			[nc addObserver:delegate selector:@selector(callManagerDidEndCall:)
					   name:XMNotification_CallEnd object:nil];
		}
	}
}

/*
- (BOOL)startH323Listening
{
	return startH323Listeners();
}

- (void)stopH323Listening
{
	stopH323Listeners();
}
*/

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
	XMPreferences *old = activePreferences;
	activePreferences = [prefs copy];
	[old release];
	
	//autoAnswerCalls = [activePreferences autoAnswerCalls];
	autoAnswerCalls = NO;
	
	// now setting up the OPAL system according to the preferences
	if([activePreferences useAddressTranslation])
	{
		//add autoget ext addr
		setTranslationAddress([[activePreferences externalAddress] cString]);
	}
	else
	{
		setTranslationAddress(NULL);
	}
	
	// adjusting the port ranges
	setPortRanges([activePreferences udpPortMin],
				  [activePreferences udpPortMax],
				  [activePreferences tcpPortMin],
				  [activePreferences tcpPortMax],
				  [activePreferences udpPortMin],
				  [activePreferences udpPortMax]);
	
	// setting the audio preferences
	
	// setting the video preferences
	
	if([activePreferences h323IsEnabled])
	{
		if(!isH323Listening() && !startH323Listeners([activePreferences h323LocalListenerPort]))
		{
			NSLog(@"ERROR: StartH323Listening failed!");
		}
		
		setH323Functionality([activePreferences h323EnableFastStart], [activePreferences h323EnableH245Tunnel]);
		
		if([activePreferences h323UseGatekeeper])
		{
			setGatekeeper([[activePreferences h323GatekeeperAddress] cString],
						  [[activePreferences h323GatekeeperID] cString],
						  [[activePreferences h323GatekeeperUsername] cString],
						  [[activePreferences h323GatekeeperE164Number] cString]);
		}
		else
		{
			setGatekeeper(NULL, NULL, NULL, NULL);
		}
	}
	else
	{
		if(isH323Listening())
		{
			stopH323Listeners();
		}
	}
				  
}

- (XMCallInfo *)activeCall
{
	return activeCall;
}

- (XMCallInfo *)callRemoteParty:(NSString *)remoteParty usingProtocol:(XMCallProtocol)protocol
{
	unsigned callID = startCall(protocol, [remoteParty cString]);
	
	if(callID != 0)
	{
		XMCallInfo *info = [[XMCallInfo alloc] _initWithCallID:callID
													  protocol:protocol
													remoteName:nil
												  remoteNumber:nil
												 remoteAddress:nil
											 remoteApplication:nil
													callStatus:XMCallStatus_Calling];
			
		if(activeCall)
		{
			[activeCall release];
		}
			
		activeCall = info;
	}
	
	return activeCall;
}

- (void)acceptIncomingCall:(BOOL)acceptFlag
{
	unsigned callID = [activeCall _callID];
		
	setAcceptIncomingCall(callID, acceptFlag);
}

- (void)clearActiveCall
{
	if(!activeCall)
	{
		return;
	}
	
	clearCall([activeCall _callID]);
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
		// do something here
		[activeCall release];
	}
	
	activeCall = [callInfo retain];
	
	if(autoAnswerCalls)
	{
		// we do not post any notification here since this will be posted on call established
		setAcceptIncomingCall([callInfo _callID], true);
	}
	else
	{
		// post the appropriate notification
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_IncomingCall
														object:self];
	}
}

-(void)_handleCallEstablished:(unsigned)callID
{
	@synchronized(self)
	{
		if([activeCall _callID] != callID)
		{
			// do something here!
			NSLog(@"callID mismatch on call established");
			return;
		}
	}
	
	[self performSelectorOnMainThread:@selector(_handleCallEstablished) withObject:nil
						waitUntilDone:NO];
}

- (void)_handleCallEstablished
{
	XMCallStatus status = [activeCall callStatus];
	
	if(status != XMCallStatus_Calling && status != XMCallStatus_Incoming)
	{
		// this should actually not happen
		NSLog(@"illegal call status on call established");
		return;
	}

	[activeCall _setCallStatus:XMCallStatus_Active];
	
	if([activeCall remoteName] == nil)
	{
		NSLog(@"fetching additional infos");
		// we need to get additional information.
		const char *remoteName;
		const char *remoteNumber;
		const char *remoteAddress;
		const char *remoteApplication;
		
		getCallInformation([activeCall _callID], &remoteName, &remoteNumber, &remoteAddress, &remoteApplication);
		
		NSString *str = [[NSString alloc] initWithCString:remoteName];
		[activeCall _setRemoteName:str];
		[str release];
		
		str = [[NSString alloc] initWithCString:remoteNumber];
		[activeCall _setRemoteNumber:str];
		[str release];
		
		str = [[NSString alloc] initWithCString:remoteAddress];
		[activeCall _setRemoteAddress:str];
		[str release];
		
		str = [[NSString alloc] initWithCString:remoteApplication];
		[activeCall _setRemoteApplication:str];
		[str release];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallEstablished
														object:self];
}

- (void)_handleCallCleared:(unsigned)callID withCallEndReason:(XMCallEndReason)endReason
{
	if([activeCall _callID] != callID)
	{
		NSLog(@"callID mismatch on call cleared");
		return;
	}
	
	NSNumber *reason = [[NSNumber alloc] initWithUnsignedInt:endReason];
	
	[self performSelectorOnMainThread:@selector(_handleCallCleared:) withObject:reason
						waitUntilDone:NO];
	[reason release];
}

- (void)_handleCallCleared:(NSNumber *)endReason
{
	[activeCall _setCallStatus:XMCallStatus_Ended];
	[activeCall _setCallEndReason:(XMCallEndReason)[endReason unsignedIntValue]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_CallEnd
														object:self];
}

- (void)_handleMediaStreamOpened:(unsigned)callID 
				   isInputStream:(BOOL)isInputStream 
					 mediaFormat:(NSString *)mediaFormat
{
	
	if([activeCall _callID] != callID)
	{
		NSLog(@"callID mismatch on media stream opened");
		return;
	}
	
	NSNumber *number = [[NSNumber alloc] initWithBool:isInputStream];
	NSArray *arr = [[NSArray alloc] initWithObjects:number, mediaFormat, nil];
	
	[self performSelectorOnMainThread:@selector(_handleMediaStreamOpened:) withObject:arr
						waitUntilDone:NO];
	
	[arr release];
	[number release];
}

- (void)_handleMediaStreamOpened:(NSArray *)values
{
	BOOL isInput = [(NSNumber *)[values objectAtIndex:0] boolValue];
	NSString *codec = (NSString *)[values objectAtIndex:1];
	
	if(isInput)
	{
		NSLog(@"incoming:");
	}
	else
	{
		NSLog(@"outgoing:");
	}
	NSLog(codec);
	
	if([codec rangeOfString:@"261"].location != NSNotFound ||
	   [codec rangeOfString:@"263"].location != NSNotFound)
	{
		// we have a video codec.
		if(isInput)
		{
			[activeCall _setOutgoingVideoCodec:codec];
		}
		else
		{
			[activeCall _setIncomingAudioCodec:codec];
		}
	}
	else
	{
		// we have an audio codec.
		if(isInput)
		{
			[activeCall _setOutgoingAudioCodec:codec];
		}
		else
		{
			[activeCall _setIncomingAudioCodec:codec];
		}
	}
}
	

@end