/*
 * $Id: XMAudioManager.m,v 1.12 2006/09/24 17:53:31 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
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

OSStatus XMAudioManagerDeviceListPropertyListenerProc(AudioHardwarePropertyID inPropertyID,
													  void *inClientData);

OSStatus XMAudioManagerVolumeChangePropertyListenerProc(AudioDeviceID device,
														UInt32 inChannel,
														Boolean isInput,
														AudioDevicePropertyID inPropertyID,
														void *userData);

@implementation XMAudioManager

#pragma mark Class Methods

+ (XMAudioManager *)sharedInstance
{	
	if(_XMAudioManagerSharedInstance == nil)
	{
		NSLog(@"Attempt to access XMAudioManager prior to initialization");
	}
	
	return _XMAudioManagerSharedInstance;
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
	
	noDeviceName = NSLocalizedString(@"XM_FRAMEWORK_NO_DEVICE", @"");
	unknownDeviceName = NSLocalizedString(@"XM_FRAMEWORK_UNKNOWN_DEVICE", @"");
	
	// obtaining the currently selected devices
	selectedInputDeviceID = [self _defaultDeviceForDirection:XM_INPUT_DIRECTION];
	selectedInputDevice = [[self _nameForDeviceID:selectedInputDeviceID] copy];
	selectedOutputDeviceID = [self _defaultDeviceForDirection:XM_OUTPUT_DIRECTION];
	selectedOutputDevice = [[self _nameForDeviceID:selectedOutputDeviceID] copy];
	
	doesMeasureSignalLevels = NO;
	inputLevel = 0.0;
	outputLevel = 0.0;
	
	doesRunAudioTest = NO;
	
	[self _addVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	[self _addVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	
	AudioHardwareAddPropertyListener(kAudioHardwarePropertyDevices,
									 XMAudioManagerDeviceListPropertyListenerProc,
									 NULL);
	
	return self;
}

- (void)_close
{
	if(inputDevices != nil)
	{
		[inputDevices release];
		inputDevices = nil;
	}
	if(outputDevices != nil)
	{
		[outputDevices release];
		outputDevices = nil;
	}
	if(selectedInputDevice != nil)
	{
		[selectedInputDevice release];
		selectedInputDevice = nil;
	}
	if(selectedOutputDevice != nil)
	{
		[selectedOutputDevice release];
		selectedOutputDevice = nil;
	}
	
	[self stopAudioTest];
	
	[self _removeVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	[self _removeVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	
	AudioHardwareRemovePropertyListener(kAudioHardwarePropertyDevices,
										XMAudioManagerDeviceListPropertyListenerProc);
}

- (void)dealloc
{
	[self _close];
	
	[super dealloc];
}

#pragma mark Managing Devices

- (void)updateDeviceLists
{
	[inputDevices release];
	inputDevices = nil;
	
	[outputDevices release];
	outputDevices = nil;
	
	// getting the new devices
	[self inputDevices];
	[self outputDevices];
	
	AudioDeviceID newDeviceID = [self _deviceIDForName:selectedInputDevice direction:XM_INPUT_DIRECTION];
	if(newDeviceID == kAudioDeviceUnknown)
	{
		newDeviceID = [self _defaultDeviceForDirection:XM_INPUT_DIRECTION];
	}
	
	if(newDeviceID != selectedInputDeviceID)
	{
		[self _removeVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
		
		_XMSetSelectedAudioInputDevice((unsigned int)newDeviceID);
		selectedInputDeviceID = newDeviceID;
		[selectedInputDevice release];
		selectedInputDevice = [[self _nameForDeviceID:selectedInputDeviceID] copy];
		
		[self _addVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	}
	
	newDeviceID = [self _deviceIDForName:selectedOutputDevice direction:XM_OUTPUT_DIRECTION];
	if(newDeviceID == kAudioDeviceUnknown)
	{
		newDeviceID = [self _defaultDeviceForDirection:XM_OUTPUT_DIRECTION];
	}
	
	if(newDeviceID != selectedOutputDeviceID)
	{
		[self _removeVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
		
		_XMSetSelectedAudioOutputDevice((unsigned int)newDeviceID);
		selectedOutputDeviceID = newDeviceID;
		[selectedOutputDevice release];
		selectedOutputDevice = [[self _nameForDeviceID:selectedOutputDeviceID] copy];
		
		[self _addVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidUpdateDeviceLists object:self];
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
	if(deviceID == kAudioDeviceUnknown && ![deviceName isEqualToString:noDeviceName])
	{
		return NO;
	}
	
	[self _removeVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	_XMSetSelectedAudioInputDevice((unsigned int)deviceID);
	
	selectedInputDeviceID = deviceID;
	selectedInputDevice = [deviceName copy];
	selectedInputDeviceIsMuted = NO;
	
	[self _addVolumePropertyListenerForDevice:selectedInputDeviceID direction:XM_INPUT_DIRECTION];
	
	return YES;
}

- (NSString *)selectedOutputDevice
{	
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
	
	AudioDeviceID deviceID = [self _deviceIDForName:deviceName direction:XM_OUTPUT_DIRECTION];
	if(deviceID == kAudioDeviceUnknown  && ![deviceName isEqualToString:noDeviceName])
	{
		return NO;
	}
	
	[self _removeVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	
	_XMSetSelectedAudioOutputDevice((unsigned int)deviceID);
	
	selectedOutputDeviceID = deviceID;
	selectedOutputDevice = [deviceName copy];
	selectedOutputDeviceIsMuted = NO;
	
	[self _addVolumePropertyListenerForDevice:selectedOutputDeviceID direction:XM_OUTPUT_DIRECTION];
	
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

- (BOOL)mutesInput
{
	return selectedInputDeviceIsMuted;
}

- (BOOL)setMutesInput:(BOOL)muteFlag
{	
	if((muteFlag == YES && selectedInputDeviceIsMuted == YES) ||
	   (muteFlag == NO && selectedInputDeviceIsMuted == NO))
	{
		return YES;
	}
	
	_XMSetMuteAudioInputDevice(muteFlag);
	selectedInputDeviceIsMuted = muteFlag;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerInputVolumeDidChange object:self];
	
	if(muteFlag == YES)
	{
		inputLevel = 0.0;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidUpdateInputLevel object:self];
	}
	
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

- (BOOL)mutesOutput
{
	return selectedOutputDeviceIsMuted;
}

- (BOOL)setMutesOutput:(BOOL)muteFlag
{
	if((muteFlag == YES && selectedOutputDeviceIsMuted == YES) ||
	   (muteFlag == NO && selectedOutputDeviceIsMuted == NO))
	{
		return YES;
	}
	
	_XMSetMuteAudioOutputDevice(muteFlag);
	selectedOutputDeviceIsMuted = muteFlag;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerOutputVolumeDidChange object:self];
	
	if(muteFlag == YES)
	{
		outputLevel = 0.0;
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidUpdateOutputLevel object:self];
	}
	
	return YES;
}

- (BOOL)doesMeasureSignalLevels
{
	return doesMeasureSignalLevels;
}

- (void)setDoesMeasureSignalLevels:(BOOL)flag
{
	doesMeasureSignalLevels = flag;
	_XMSetMeasureAudioSignalLevels(flag);
	if(doesMeasureSignalLevels == NO)
	{
		// Fall back zo zero
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerOutputVolumeDidChange object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerInputVolumeDidChange object:self];
	}
}

- (double)inputLevel
{
	if(doesMeasureSignalLevels == YES) {
		return inputLevel;
	}
	return 0.0;
}

- (double)outputLevel
{
	if(doesMeasureSignalLevels == YES) {
		return outputLevel;
	}
	return 0.0;
}

- (void)startAudioTestWithDelay:(unsigned)delay
{
	if(doesRunAudioTest == YES)
	{
		return;
	}
	
	if(delay > 5)
	{
		delay = 5;
	}
	if(delay < 1)
	{
		delay = 1;
	}
	_XMStartAudioTest(delay);
	
	doesRunAudioTest = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidStartAudioTest object:self];
}

- (void)stopAudioTest
{
	if(doesRunAudioTest == NO)
	{
		return;
	}
	// this method will block until the audio test thread finished.
	// The state is is updated in the callback called by the underlying
	// system
	_XMStopAudioTest();
}

- (BOOL)doesRunAudioTest
{
	return doesRunAudioTest;
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
		name = [[NSString alloc] initWithCString:deviceName encoding:NSUTF8StringEncoding];
		[name autorelease];
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
	
	AudioDeviceAddPropertyListener(deviceID, 1, direction,
								   kAudioDevicePropertyVolumeScalar,
								   XMAudioManagerVolumeChangePropertyListenerProc,
								   NULL);
	
	/*if(err != kAudioHardwareNoError)
	{
		NSLog(@"adding the prop listener failed");
	}*/
}

- (void)_removeVolumePropertyListenerForDevice:(AudioDeviceID)deviceID direction:(XM_DIRECTION)direction
{
	if(deviceID == kAudioDeviceUnknown)
	{
		return;
	}
	
	AudioDeviceRemovePropertyListener(deviceID, 1, direction,
									  kAudioDevicePropertyVolumeScalar,
									  XMAudioManagerVolumeChangePropertyListenerProc);
	
	/*if(err != kAudioHardwareNoError)
	{
		NSLog(@"removing the prop listener failed");
	}*/
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

- (void)_handleAudioInputLevel:(NSNumber *)level
{
	if(selectedInputDeviceIsMuted == YES)
	{
		return;
	}
	inputLevel = [level doubleValue];
	if(doesMeasureSignalLevels)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidUpdateInputLevel
															object:self];
	}
}

- (void)_handleAudioOutputLevel:(NSNumber *)level
{
	outputLevel = [level doubleValue];
	if(doesMeasureSignalLevels)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidUpdateOutputLevel
															object:self];
	}
}

- (void)_handleAudioTestEnd
{
	doesRunAudioTest = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_AudioManagerDidStopAudioTest object:self];
}

@end

#pragma mark CoreAudio PropertyListener Proc

OSStatus XMAudioManagerDeviceListPropertyListenerProc(AudioHardwarePropertyID inPropertyID,
													  void *inClientData)
{
	[[XMAudioManager sharedInstance] performSelectorOnMainThread:@selector(updateDeviceLists)
													  withObject:nil waitUntilDone:NO];
	return noErr;
}

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
