/*
 * $Id: XMAudioManager.mm,v 1.4 2005/06/28 20:41:06 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#import <CoreAudio/CoreAudio.h>
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
- (NSString *)_defaultDeviceForDirection:(XM_DIRECTION)direction;
- (NSString *)_nameForDeviceID:(AudioDeviceID)deviceID;
- (AudioDeviceID)_deviceIDForName:(NSString *)deviceName direction:(XM_DIRECTION)direction;
- (BOOL)_deviceID:(AudioDeviceID)deviceID supportsDirection:(XM_DIRECTION)direction;

- (BOOL)_canAlterVolumeForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction;
- (unsigned)_volumeForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction;
- (BOOL)_setVolume:(unsigned)volume forDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction;

- (void)_addVolumePropertyListenerForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction;
- (void)_removeVolumePropertyListenerForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction;

- (void)_inputVolumeDidChange:(NSNumber *)volume;
- (void)_outputVolumeDidChange:(NSNumber *)volume;

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
	outputDevices = nil;
	selectedInputDevice = nil;
	selectedOutputDevice = nil;
	
	noDeviceName = NSLocalizedString(@"<No Device>", @"");
	unknownDeviceName = NSLocalizedString(@"Unknown Audio Device", @"");
	
	unmutedInputVolume = 101;
	unmutedOutputVolume = 101;
	
	[self _addVolumePropertyListenerForDevice:[self selectedInputDevice] direction:XM_INPUT_DIRECTION];
	[self _addVolumePropertyListenerForDevice:[self selectedOutputDevice] direction:XM_OUTPUT_DIRECTION];
	
	return self;
}

- (void)dealloc
{
	[inputDevices release];
	[outputDevices release];
	[selectedInputDevice release];
	[selectedOutputDevice release];
	
	[self _removeVolumePropertyListenerForDevice:selectedInputDevice direction:XM_INPUT_DIRECTION];
	[self _removeVolumePropertyListenerForDevice:selectedOutputDevice direction:XM_OUTPUT_DIRECTION];
	
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
	AudioDeviceID deviceID;
	
	deviceIDSize = sizeof(AudioDeviceID);
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice, &deviceIDSize, &deviceID);
	
	if(err == noErr)
	{
		return [self _nameForDeviceID:deviceID];
	}
	else
	{
		return noDeviceName;
	}
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
	AudioDeviceID deviceID;
	
	deviceIDSize = sizeof(AudioDeviceID);
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice, &deviceIDSize, &deviceID);
	
	if(err == noErr)
	{
		return [self _nameForDeviceID:deviceID];
	}
	else
	{
		return noDeviceName;
	}
}

- (NSString *)selectedInputDevice
{
	if(selectedInputDevice == nil)
	{
		selectedInputDevice = [[self defaultInputDevice] copy];
	}
	
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
	
	const char *deviceString;
	
	if([deviceName isEqualToString:noDeviceName])
	{
		deviceString = "Null";
	}
	else
	{
		deviceString = [deviceName cString];
	}
	if(setSelectedAudioInputDevice(deviceString))
	{
		[self _removeVolumePropertyListenerForDevice:selectedInputDevice direction:XM_INPUT_DIRECTION];
		
		NSString *old = selectedInputDevice;
		selectedInputDevice = [deviceName copy];
		[old release];
		
		[self _addVolumePropertyListenerForDevice:selectedInputDevice direction:XM_INPUT_DIRECTION];
	
		unmutedInputVolume = 101;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerInputDeviceDidChange
															object:self];
		return YES;
	}
	return NO;
}

- (NSString *)selectedOutputDevice
{
	if(selectedOutputDevice == nil)
	{
		selectedOutputDevice = [[self defaultOutputDevice] copy];
	}
	
	return selectedOutputDevice;
}

- (BOOL)setSelectedOutputDevice:(NSString *)deviceName
{
	if([deviceName isEqualToString:selectedOutputDevice])
	{
		return YES;
	}
	
	NSArray *devices = [self outputDevices];
	
	if(![devices containsObject:deviceName])
	{
		return NO;
	}
	
	const char *deviceString;
	
	if([deviceName isEqualToString:noDeviceName])
	{
		// the dummy device name used by PWLib's CoreAudio implementation is "Null"
		deviceString = "Null";
	}
	else
	{
		deviceString = [deviceName cString];
	}
	
	if(setSelectedAudioOutputDevice(deviceString))
	{
		[self _removeVolumePropertyListenerForDevice:selectedOutputDevice direction:XM_OUTPUT_DIRECTION];
		
		NSString *old = selectedOutputDevice;
		selectedOutputDevice = [deviceName copy];
		[old release];
		
		[self _addVolumePropertyListenerForDevice:selectedOutputDevice direction:XM_OUTPUT_DIRECTION];
		
		unmutedOutputVolume = 101;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerOutputDeviceDidChange
															object:self];
		return YES;
	}
	return NO;
}

#pragma mark Managing Volume

- (BOOL)canAlterInputVolume
{	
	return [self _canAlterVolumeForDevice:[self selectedInputDevice] direction:XM_INPUT_DIRECTION];
}

- (unsigned)inputVolume
{	
	return [self _volumeForDevice:[self selectedInputDevice] direction:XM_INPUT_DIRECTION];
}

- (BOOL)setInputVolume:(unsigned)volume
{	
	return [self _setVolume:volume forDevice:[self selectedInputDevice] direction:XM_INPUT_DIRECTION];
}

- (BOOL)mutesInputVolume
{
	return unmutedInputVolume <= 100;
}

- (BOOL)setMutesInputVolume:(BOOL)muteVolume
{
	if((muteVolume == YES && unmutedInputVolume <= 100) || (muteVolume == NO && unmutedInputVolume > 100))
	{
		return YES;
	}
	
	if(muteVolume)
	{
		unsigned volume = [self inputVolume];
		
		if([self setInputVolume:0])
		{
			unmutedInputVolume = volume;
			return YES;
		}
		return NO;
	}
	else
	{
		if([self setInputVolume:unmutedInputVolume])
		{
			unmutedInputVolume = 101;
			return YES;
		}
		return NO;
	}
}

- (BOOL)canAlterOutputVolume
{	
	return [self _canAlterVolumeForDevice:[self selectedOutputDevice] direction:XM_OUTPUT_DIRECTION];
}

- (unsigned)outputVolume
{	
	return [self _volumeForDevice:[self selectedOutputDevice] direction:XM_OUTPUT_DIRECTION];
}

- (BOOL)setOutputVolume:(unsigned)volume
{	
	return [self _setVolume:volume forDevice:[self selectedOutputDevice] direction:XM_OUTPUT_DIRECTION];
}

- (BOOL)mutesOutputVolume
{
	return unmutedOutputVolume <= 100;
}

- (BOOL)setMutesOutputVolume:(BOOL)muteVolume
{
	if((muteVolume == YES && unmutedOutputVolume <= 100) || (muteVolume == NO && unmutedOutputVolume > 100))
	{
		return YES;
	}
	
	if(muteVolume)
	{
		unsigned volume = [self outputVolume];
		
		if([self setOutputVolume:0])
		{
			unmutedOutputVolume = volume;
			return YES;
		}
		return NO;
	}
	else
	{
		if([self setOutputVolume:unmutedOutputVolume])
		{
			unmutedOutputVolume = 101;
			return YES;
		}
		return NO;
	}
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
			NSString *deviceName = [self _nameForDeviceID:device];
			if([self _deviceID:device supportsDirection:direction])
			{
				[validDevices addObject:deviceName];
			}
		}
	}
	
	[validDevices addObject:noDeviceName];
	
	free(deviceList);
	
	return validDevices;
}

- (NSString *)_defaultDeviceForDirection:(XM_DIRECTION)direction
{
	OSStatus err = noErr;
	UInt32 deviceIDSize;
	AudioDeviceID deviceID;
	
	deviceIDSize = sizeof(AudioDeviceID);
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice, &deviceIDSize, &deviceID);
	
	if(err == noErr)
	{
		return [self _nameForDeviceID:deviceID];
	}
	else
	{
		return noDeviceName;
	}	
}

- (NSString *)_nameForDeviceID:(AudioDeviceID)deviceID
{
	OSStatus status;
	char deviceName[XM_MAX_DEVICE_NAME_LENGTH];
	UInt32 deviceNameSize = sizeof(deviceName);
	NSString *name;
	
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
	AudioDeviceID correspondingDeviceID = 0;
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

- (BOOL)_canAlterVolumeForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction
{
	if([deviceName isEqualToString:noDeviceName])
	{
		return NO;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:direction];
	
	if(deviceID == 0)
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

- (unsigned)_volumeForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction
{
	if([deviceName isEqualToString:noDeviceName])
	{
		return 0;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:direction];
	
	if(deviceID == 0)
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

- (BOOL)_setVolume:(unsigned)volume forDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction
{
	if([deviceName isEqualToString:noDeviceName])
	{
		return NO;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:direction];

	if(deviceID == 0)
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

- (void)_addVolumePropertyListenerForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction
{
	if([deviceName isEqualToString:noDeviceName])
	{
		return;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:direction];
	
	if(deviceID == 0)
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

- (void)_removeVolumePropertyListenerForDevice:(NSString *)deviceName direction:(XM_DIRECTION)direction
{
	if([deviceName isEqualToString:noDeviceName])
	{
		return;
	}
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:direction];
	
	if(deviceID == 0)
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

- (void)_inputVolumeDidChange:(NSNumber *)volumeNumber;
{
	unsigned volume = [volumeNumber unsignedIntValue];
	
	if(unmutedInputVolume <= 100)
	{
		// we have muted the input
		
		if(volume != 0)
		{
			// input is no longer muted
			unmutedInputVolume = 101;
		}
		else
		{
			return;
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerInputVolumeDidChange
														object:self];
}

- (void)_outputVolumeDidChange:(NSNumber *)volumeNumber;
{
	unsigned volume = [volumeNumber unsignedIntValue];
	
	if(unmutedOutputVolume <= 100)
	{
		// we have muted the input
		
		if(volume != 0)
		{
			// input is no longer muted
			unmutedOutputVolume = 101;
		}
		else
		{
			return;
		}
	}
	
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
	OSStatus err;
	Float32 volume;
	UInt32 volumeSize = sizeof(volume);
	
	err = AudioDeviceGetProperty(device, inChannel, isInput,
								 kAudioDevicePropertyVolumeScalar,
								 &volumeSize, &volume);
	
	
	if(err == kAudioHardwareNoError)
	{
		unsigned volumeValue = (unsigned) (volume * 100);
		NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:volumeValue];
		
		if(isInput)
		{
			[[XMAudioManager sharedInstance] performSelectorOnMainThread:@selector(_inputVolumeDidChange:)
															  withObject:number waitUntilDone:NO];
		}
		else
		{
			[[XMAudioManager sharedInstance] performSelectorOnMainThread:@selector(_outputVolumeDidChange:)
															  withObject:number waitUntilDone:NO];
		}
		[number release];
	}
	
	return noErr;
}
