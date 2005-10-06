/*
 * $Id: XMAudioManager.m,v 1.1 2005/10/06 15:04:42 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import "XMAudioManager.h"
#import "XMPrivate.h"
#import "XMStringConstants.h"

#import "XMBridge.h"

#define XM_DIRECTION BOOL
#define XM_INPUT_DIRECTION YES
#define XM_OUTPUT_DIRECTION NO
#define XM_MAX_DEVICE_NAME_LENGTH 128

/**
 * Note: Although this functionality exists also in PWLib/OPAL,
 * we directly use the CoreAudio API's to determine device lists
 * and controlling the volume
 **/
@interface XMAudioManager (PrivateMethods)

- (id)_init;

- (NSArray *)_devicesForDirection:(XM_DIRECTION)direction;
- (AudioDeviceID)_defaultDeviceForDirection:(XM_DIRECTION)direction;
- (NSString *)_nameForDeviceID:(AudioDeviceID)deviceID;
- (AudioDeviceID)_deviceIDForName:(NSString *)deviceName direction:(XM_DIRECTION)direction;
- (BOOL)_deviceID:(AudioDeviceID)deviceID supportsDirection:(XM_DIRECTION)direction;

- (BOOL)_canAlterVolumeForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction;
- (unsigned)_volumeForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction;
- (BOOL)_setVolume:(unsigned)volume forDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction;

- (void)_addVolumePropertyListenerForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction;
- (void)_removeVolumePropertyListenerForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction;

- (void)_inputVolumeDidChange;
- (void)_outputVolumeDidChange;

@end

OSStatus XMAudioManagerVolumeChangePropertyListenerProc(AudioDeviceID device,
														UInt32 inChannel,
														Boolean isInput,
														AudioDevicePropertyID inPropertyID,
														void *userData);

@implementation XMAudioManager

#pragma mark Class Methods

+ (XMAudioManager *)sharedInstance
{
	static XMAudioManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMAudioManager alloc] _init];
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
	
	inputDevices = nil;
	selectedInputDevice = nil;
	selectedInputDeviceID = kAudioDeviceUnknown;
	selectedInputDeviceIsMuted = NO;
	
	outputDevices = nil;
	selectedOutputDevice = nil;
	selectedOutputDeviceID = kAudioDeviceUnknown;
	selectedOutputDeviceIsMuted = NO;
	
	noDeviceName = NSLocalizedString(@"<No Device>", @"");
	unknownDeviceName = NSLocalizedString(@"Unknown Audio Device", @"");
	
	// obtaining the currently selected devices
	selectedInputDeviceID = [self _defaultDeviceForDirection:XM_INPUT_DIRECTION];
	selectedInputDevice = [[self _nameForDeviceID:selectedInputDeviceID] copy];
	selectedOutputDeviceID = [self _defaultDeviceForDirection:XM_OUTPUT_DIRECTION];
	selectedOutputDevice = [[self _nameForDeviceID:selectedOutputDeviceID] copy];
	
	[self _addVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	[self _addVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	
	return self;
}

- (void)dealloc
{
	[inputDevices release];
	[outputDevices release];
	[selectedInputDevice release];
	[selectedOutputDevice release];
	
	[self _removeVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	[self _removeVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	
	[super dealloc];
}

#pragma mark Managing Devices

- (void)updateDeviceLists
{
	// We do a lazy approach by just releasing
	// the cached values.
	// The new values are not obtained before
	// the next call to -audio<DIRECTION>Devices
	[inputDevices release];
	inputDevices = nil;
	
	[outputDevices release];
	outputDevices = nil;
}

- (NSArray *)inputDevices
{
	if(inputDevices == nil)
	{
		inputDevices = [[self _devicesForDirection:XM_INPUT_DIRECTION] copy];
	}
	
	return inputDevices;
}

- (NSString *)defaultInputDevice
{
	OSStatus err = noErr;
	UInt32 deviceIDSize;
	AudioDeviceID deviceID = [self _defaultDeviceForDirection:XM_INPUT_DIRECTION];
	
	return [self _nameForDeviceID:deviceID];
}

- (NSArray *)outputDevices
{
	if(outputDevices == nil)
	{
		outputDevices = [[self _devicesForDirection:XM_OUTPUT_DIRECTION] copy];
	}
	return outputDevices;
}

- (NSString *)defaultOutputDevice
{
	OSStatus err = noErr;
	UInt32 deviceIDSize;
	AudioDeviceID deviceID = [self _defaultDeviceForDirection:XM_OUTPUT_DIRECTION];
	
	return [self _nameForDeviceID:deviceID];
}

- (NSString *)selectedInputDevice
{	
	return selectedInputDevice;
}

- (BOOL)setSelectedInputDevice:(NSString *)deviceName
{
	if([deviceName isEqualToString:selectedInputDevice])
	{
		return YES;
	}
	
	NSArray *devices = [self inputDevices];
	
	if(![devices containsObject:deviceName])
	{
		return NO;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:XM_INPUT_DIRECTION];
	setSelectedAudioInputDevice((unsigned int)deviceID);
	
	selectedInputDeviceID = deviceID;
	selectedInputDevice = [deviceName copy];
	selectedInputDeviceIsMuted = NO;
	
	return YES;
}

- (NSString *)selectedOutputDevice
{	
	return selectedOutputDevice;
}

- (BOOL)setSelectedOutputDevice:(NSString *)deviceName
{
	NSLog(@"setSelectedOutputDevice");
	if([deviceName isEqualToString:selectedOutputDevice])
	{
		NSLog(@"1");
		return YES;
	}
	
	NSArray *devices = [self outputDevices];
	
	if(![devices containsObject:deviceName])
	{
		NSLog(@"2");
		return NO;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:XM_OUTPUT_DIRECTION];
	setSelectedAudioOutputDevice((unsigned int)deviceID);
	
	selectedOutputDeviceID = deviceID;
	selectedOutputDevice = [deviceName copy];
	selectedOutputDeviceIsMuted = NO;
	
	return YES;
}

#pragma mark Managing Volume

- (BOOL)canAlterInputVolume
{	
	return [self _canAlterVolumeForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
}

- (unsigned)inputVolume
{	
	return [self _volumeForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
}

- (BOOL)setInputVolume:(unsigned)volume
{	
	return [self _setVolume:volume forDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
}

- (BOOL)mutesInputVolume
{
	return selectedInputDeviceIsMuted;
}

- (BOOL)setMutesInputVolume:(BOOL)muteFlag
{	
	if((muteFlag == YES && selectedInputDeviceIsMuted == YES) ||
	   (muteFlag == NO && selectedInputDeviceIsMuted == NO))
	{
		return YES;
	}
	
	setMuteAudioInputDevice(muteFlag);
	selectedInputDeviceIsMuted = muteFlag;
	return YES;
}

- (BOOL)canAlterOutputVolume
{	
	return [self _canAlterVolumeForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
}

- (unsigned)outputVolume
{	
	return [self _volumeForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
}

- (BOOL)setOutputVolume:(unsigned)volume
{	
	return [self _setVolume:volume forDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
}

- (BOOL)mutesOutputVolume
{
	return selectedOutputDeviceIsMuted;
}

- (BOOL)setMutesOutputVolume:(BOOL)muteFlag
{
	if((muteFlag == YES && selectedOutputDeviceIsMuted == YES) ||
	   (muteFlag == NO && selectedOutputDeviceIsMuted == NO))
	{
		return YES;
	}
	
	setMuteAudioOutputDevice(muteFlag);
	selectedOutputDeviceIsMuted = muteFlag;
	
	return YES;
}

#pragma mark Private Methods

- (NSArray *)_devicesForDirection:(XM_DIRECTION)direction
{
	OSStatus status;
	AudioDeviceID *deviceList;
	UInt32 devicesSize;
	
	status = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,
										  &devicesSize, NULL);
	
	if(status != noErr)
	{
		return [NSArray arrayWithObject:noDeviceName];
	}
	
	UInt32 numDevices = devicesSize / sizeof(AudioDeviceID);
	
	deviceList = (AudioDeviceID *)malloc(devicesSize);
	
	if(deviceList == NULL)
	{
		return [NSArray arrayWithObject:noDeviceName];
	}
	
	status = AudioHardwareGetProperty(kAudioHardwarePropertyDevices,
									  &devicesSize, deviceList);
	
	NSMutableArray *validDevices = [NSMutableArray arrayWithCapacity:numDevices];
	if(status == noErr)
	{
		int i;
		for(i = 0; i < numDevices; i++)
		{
			AudioDeviceID device = deviceList[i];
			if([self _deviceID:device supportsDirection:direction])
			{
				NSString *deviceName = [self _nameForDeviceID:device];
				[validDevices addObject:deviceName];
			}
		}
	}
	
	[validDevices addObject:noDeviceName];
	
	free(deviceList);
	
	return validDevices;
}

- (AudioDeviceID)_defaultDeviceForDirection:(XM_DIRECTION)direction
{
	OSStatus err = noErr;
	UInt32 deviceIDSize;
	AudioDeviceID deviceID;
	AudioHardwarePropertyID propertyID;
	
	deviceIDSize = sizeof(AudioDeviceID);
	
	if(direction == XM_INPUT_DIRECTION)
	{
		propertyID = kAudioHardwarePropertyDefaultInputDevice;
	}
	else
	{
		propertyID = kAudioHardwarePropertyDefaultOutputDevice;
	}
	
	err = AudioHardwareGetProperty(propertyID, &deviceIDSize, &deviceID);
	
	if(err == noErr)
	{
		return deviceID;
	}
	else
	{
		return kAudioDeviceUnknown;
	}	
}

- (NSString *)_nameForDeviceID:(AudioDeviceID)deviceID
{
	OSStatus status;
	char deviceName[XM_MAX_DEVICE_NAME_LENGTH];
	UInt32 deviceNameSize = sizeof(deviceName);
	NSString *name;
	
	if(deviceID == kAudioDeviceUnknown)
	{
		return noDeviceName;
	}
	
	status = AudioDeviceGetProperty(deviceID, 0, false,
									kAudioDevicePropertyDeviceName,
									&deviceNameSize, deviceName);
	
	if(status != noErr || deviceName[0] == '\0')
	{
		name = unknownDeviceName;
	}
	else
	{
		name = [NSString stringWithCString:deviceName];
	}
	return name;
}

- (AudioDeviceID)_deviceIDForName:(NSString *)deviceName direction:(XM_DIRECTION)direction
{
	OSStatus status;
	AudioDeviceID *deviceList;
	UInt32 devicesSize;
	
	if([deviceName isEqualToString:noDeviceName])
	{
		return kAudioDeviceUnknown;
	}
	
	status = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices,
										  &devicesSize, NULL);
	
	if(status != noErr)
	{
		return 0;
	}
	
	UInt32 numDevices = devicesSize / sizeof(AudioDeviceID);
	
	deviceList = (AudioDeviceID *)malloc(devicesSize);
	
	if(deviceList == NULL)
	{
		return 0;
	}
	
	status = AudioHardwareGetProperty(kAudioHardwarePropertyDevices,
									  &devicesSize, deviceList);
	AudioDeviceID correspondingDeviceID = kAudioDeviceUnknown;
	if(status == noErr)
	{
		int i;
		for(i = 0; i < numDevices; i++)
		{
			AudioDeviceID device = deviceList[i];
			if([self _deviceID:device supportsDirection:direction])
			{
				NSString *name = [self _nameForDeviceID:device];
				if([name isEqualToString:deviceName])
				{
					correspondingDeviceID = device;
					break;
				}
			}
		}
	}
	
	free(deviceList);
	
	return correspondingDeviceID;
}

- (BOOL)_deviceID:(AudioDeviceID)deviceID supportsDirection:(XM_DIRECTION)direction
{
	OSStatus status;
	UInt32 size;
	BOOL supportsDirection;
	
	status = AudioDeviceGetPropertyInfo(deviceID, 0, direction,
									kAudioDevicePropertyStreams,
									&size, NULL);
	
	if(status == noErr)
	{
		UInt32 numStreams = size/sizeof(AudioStreamID);
		
		if(numStreams != 0)
		{
			supportsDirection = YES;
		}
		else
		{
			supportsDirection = NO;
		}
	}
	else
	{
		supportsDirection = NO;
	}
	return supportsDirection;
}

- (BOOL)_canAlterVolumeForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction
{
	if(deviceID == kAudioDeviceUnknown)
	{
		return NO;
	}
	
	OSStatus err = noErr;
	Boolean isWritable;
	
	err = AudioDeviceGetPropertyInfo(deviceID, 0, direction,
									 kAudioDevicePropertyVolumeScalar,
									 NULL, &isWritable);
	
	if(err != kAudioHardwareNoError)
	{
		// we try accessing the next channel since the master channel
		// obviously cannot be queried
		err = AudioDeviceGetPropertyInfo(deviceID, 1, direction,
										 kAudioDevicePropertyVolumeScalar,
										 NULL, &isWritable);
	}
	
	return isWritable;
}

- (unsigned)_volumeForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction
{
	if(deviceID == kAudioDeviceUnknown)
	{
		return 0;
	}
	
	OSStatus err = noErr;
	Float32 volume;
	UInt32 volumeSize = sizeof(volume);
	
	err = AudioDeviceGetProperty(deviceID, 0, direction,
								 kAudioDevicePropertyVolumeScalar,
								 &volumeSize, &volume);
	
	if(err != kAudioHardwareNoError)
	{
		// take the value of the first channel to be the volume
		volumeSize = sizeof(volume);
		err = AudioDeviceGetProperty(deviceID, 1, direction,
									 kAudioDevicePropertyVolumeScalar,
									 &volumeSize, &volume);
	}
	
	if(err == kAudioHardwareNoError)
	{
		return (unsigned) (volume * 100);
	}
	return 0;
	
}

- (BOOL)_setVolume:(unsigned)volume forDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction
{
	if(deviceID == kAudioDeviceUnknown)
	{
		return NO;
	}
	
	OSStatus err = noErr;
	Boolean isWritable;
	BOOL useMaster;
	
	err = AudioDeviceGetPropertyInfo(deviceID, 0, direction,
									 kAudioDevicePropertyVolumeScalar,
									 NULL, &isWritable);
	if(err != kAudioHardwareNoError)
	{
		// check if we can access the individual channels
		err = AudioDeviceGetPropertyInfo(deviceID, 1, direction,
										 kAudioDevicePropertyVolumeScalar,
										 NULL, &isWritable);
		useMaster = NO;
	}
	
	if((err == kAudioHardwareNoError) && isWritable)
	{
		float theValue = ((float)volume / 100.0);
		
		if(useMaster)
		{
			err = AudioDeviceSetProperty(deviceID, NULL, 0, direction,
										 kAudioDevicePropertyVolumeScalar,
										 sizeof(float), &theValue);
		}
		else
		{
			if(err == kAudioHardwareNoError)
			{
				BOOL didSucceed = NO;
				
				// we iterate over all possible channels. If we reached
				// a channel which isn't available, this
				int i = 1;
				while(err == kAudioHardwareNoError)
				{
					err = AudioDeviceSetProperty(deviceID, NULL, i, direction,
												 kAudioDevicePropertyVolumeScalar,
												 sizeof(float), &theValue);
					if(err == kAudioHardwareNoError)
					{
						didSucceed = YES;
					}
					i++;
				}
				
				if(didSucceed == YES)
				{
					err = kAudioHardwareNoError;
				}
				else
				{
					err = kAudioHardwareUnspecifiedError;
				}
			}
		}
	}
	else
	{
		err = kAudioHardwareUnspecifiedError;
	}
	
	if(err == kAudioHardwareNoError)
	{
		return YES;
	}
	
	return NO;
}

- (void)_addVolumePropertyListenerForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction
{
	if(deviceID == kAudioDeviceUnknown)
	{
		return;
	}
	
	OSStatus err;
	
	err = AudioDeviceAddPropertyListener(deviceID, 1, direction,
										 kAudioDevicePropertyVolumeScalar,
										 XMAudioManagerVolumeChangePropertyListenerProc,
										 NULL);
	
	if(err != kAudioHardwareNoError)
	{
		NSLog(@"adding the prop listener failed");
	}
}

- (void)_removeVolumePropertyListenerForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction
{
	if(deviceID == kAudioDeviceUnknown)
	{
		return;
	}
	
	OSStatus err;
	
	err = AudioDeviceRemovePropertyListener(deviceID, 1, direction,
										 kAudioDevicePropertyVolumeScalar,
										 XMAudioManagerVolumeChangePropertyListenerProc);
	
	if(err != kAudioHardwareNoError)
	{
		NSLog(@"removing the prop listener failed");
	}
}

- (void)_inputVolumeDidChange;
{	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerInputVolumeDidChange
														object:self];
}

- (void)_outputVolumeDidChange;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerOutputVolumeDidChange
														object:self];
}

@end

#pragma mark CoreAudio PropertyListener Proc

OSStatus XMAudioManagerVolumeChangePropertyListenerProc(AudioDeviceID device,
														UInt32 inChannel,
														Boolean isInput,
														AudioDevicePropertyID inPropertyID,
														void *userData)
{		
	if(isInput)
	{
		[[XMAudioManager sharedInstance] performSelectorOnMainThread:@selector(_inputVolumeDidChange)
														  withObject:nil waitUntilDone:NO];
	}
	else
	{
		[[XMAudioManager sharedInstance] performSelectorOnMainThread:@selector(_outputVolumeDidChange)
														  withObject:nil waitUntilDone:NO];
	}
	
	return noErr;
}
