/*
 * $Id: XMAudioManager.mm,v 1.2 2005/04/28 20:26:26 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMAudioManager.h"
#import "XMPrivate.h"

#import "XMBridge.h"

@interface XMAudioManager (PrivateMethods)

- (id)_init;

@end

@implementation XMAudioManager

+ (XMAudioManager *)sharedInstance
{
	static XMAudioManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMAudioManager alloc] _init];
	}
	
	return sharedInstance;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	[self release];
	
	return nil;
}

- (id)_init
{
	self = [super init];
	
	audioInputDevices = nil;
	audioOutputDevices = nil;
	
	// making sure that the underlying OPAL system is
	// configured properly
	initOPAL();
	
	return self;
}

- (void)dealloc
{
	[audioInputDevices release];
	[audioOutputDevices release];
	
	[super dealloc];
}

- (void)updateDeviceLists
{
	// We do a lazy approach by just releasing
	// the cached values.
	// The new values are not obtained before
	// the next call to -audio<DIRECTION>Devices
	[audioInputDevices release];
	audioInputDevices = nil;
	
	[audioOutputDevices release];
	audioOutputDevices = nil;
}

- (NSArray *)inputDevices
{
	if(audioInputDevices == nil)
	{
		const char **basePtr = getAudioInputDevices();
		NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:5];
	
		int i = 0;
		while(basePtr[i] != NULL)
		{
			const char *str = basePtr[i];
			NSString *string = [[NSString alloc] initWithCString:str];
			[arr addObject:string];
			[string release];
		
			delete[] str;
		
			i++;
		}
	
		delete[] basePtr;
	
		audioInputDevices = [arr copy];
		[arr release];
	}
	
	return audioInputDevices;
}

- (NSString *)defaultInputDevice
{
	char str[64];
	getDefaultAudioInputDevice(str);
	
	NSString *string = [NSString stringWithCString:str];
	
	return string;
}

- (NSArray *)outputDevices
{
	if(audioOutputDevices == nil)
	{
		const char **basePtr = getAudioOutputDevices();
		NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:5];
		
		int i = 0;
		while(basePtr[i] != NULL)
		{
			const char *str = basePtr[i];
			NSString *string = [[NSString alloc] initWithCString:str];
			[arr addObject:string];
			[string release];
			
			delete str;
			
			i++;
		}
		
		delete basePtr;
		
		audioOutputDevices = [arr copy];
		[arr release];
	}
	
	return audioOutputDevices;
}

- (NSString *)defaultOutputDevice
{
	char str[64];
	getDefaultAudioOutputDevice(str);
	
	NSString *string = [NSString stringWithCString:str];
	
	return string;
}

- (NSString *)selectedInputDevice
{
	return [NSString stringWithCString:getSelectedAudioInputDevice()];
}

- (void)setSelectedInputDevice:(NSString *)str
{
	setSelectedAudioInputDevice([str cString]);
}

- (unsigned)inputVolume
{
	return getAudioInputVolume();
}

- (void)setInputVolume:(unsigned)vol
{
	if(!setAudioInputVolume(vol))
	{
		NSLog(@"FAILED");
	}
}

- (NSString *)selectedOutputDevice
{
	return [NSString stringWithCString:getSelectedAudioOutputDevice()];
}

- (void)setSelectedOutputDevice:(NSString *)str
{
	setSelectedAudioOutputDevice([str cString]);
}

- (unsigned)outputVolume
{
	return getAudioOutputVolume();
}

- (void)setOutputVolume:(unsigned)vol
{
	if(!setAudioOutputVolume(vol))
	{
		NSLog(@"FAILED 2");
	}
}

#pragma mark Callback Methods from the Bridge

- (void)_inputVolumeDidChange:(unsigned)volume
{
	NSLog(@"Audio: input volume did change: %d", volume);
}

- (void)_outputVolumeDidChange:(unsigned)volume
{
	NSLog(@"Audio: output volume did change: %d", volume);
}

@end
