/*
 * $Id: XMSoundChannel.cpp,v 1.7 2006/09/13 21:23:46 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#include "XMBridge.h"
#include "XMSoundChannel.h"
#include "XMCircularBuffer.h"
#include "XMCircularBuffer.cpp"
#include "XMCallbackBridge.h"

#define checkStatus( err, location ) \
if(err) {\
	cout << "error: " << location << endl;\
}

#define XM_MIN_INPUT_FILL 20

extern "C" {
	unsigned char linear2ulaw(int pcm_val);
	void _XMHandleLocalAudioFrames(void *localAudioFrames, unsigned numberOfFrames);
	void _XMHandleRemoteAudioFrames(void *remoteAudioFrames, unsigned numberOfFrames);
};

PCREATE_SOUND_PLUGIN(XMSoundChannel, XMSoundChannel);

// protects all static variable manipulation
static PMutex deviceEditMutex;

// static variables
static XMSoundChannel *activePlayDevice = NULL;
static AudioDeviceID activePlayDeviceID = kAudioDeviceUnknown;
static BOOL activePlayDeviceIsMuted = FALSE; 
static XMSoundChannel *recordDevice = NULL;
static AudioDeviceID recordDeviceID = kAudioDeviceUnknown;
static BOOL recordDeviceIsMuted = FALSE;
static BOOL measureSignalLevels = FALSE;
static int inputSignalLevelCounter = 0;

#pragma mark Static Methods

void XMSoundChannel::Init()
{
	deviceEditMutex.Wait();
	
	OSStatus err = noErr;
	
	UInt32 deviceIDSize = sizeof(AudioDeviceID);
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
								   &deviceIDSize,
								   &activePlayDeviceID);
	checkStatus(err, 50);
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
								   &deviceIDSize,
								   &recordDeviceID);
	checkStatus(err, 51);
	
	// Start the default record device that is always running.
	// to enable input level metering
	PString deviceName = XMSoundChannelDevice;
	recordDevice = new XMSoundChannel(deviceName, PSoundChannel::Recorder,
									  1, 8000, 16);
	recordDevice->SetBuffers(320, 2);
	recordDevice->StartRecording();
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::DoClose()
{
	deviceEditMutex.Wait();
	
	StopChannels();
	if(recordDevice != NULL) {
		recordDevice->StopAudioConversion();
		delete recordDevice;
		recordDevice = NULL;
	}
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::SetPlayDevice(unsigned int device)
{
	deviceEditMutex.Wait();
	
	AudioDeviceID deviceID = (AudioDeviceID)device;
	
	if(activePlayDeviceID != deviceID)
	{
		activePlayDeviceID = deviceID;
		
		if(activePlayDevice)
		{
			activePlayDevice->Restart(activePlayDeviceID);
		}
	}
	
	activePlayDeviceIsMuted = FALSE;
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::SetPlayDeviceMuted(BOOL muteFlag)
{
	deviceEditMutex.Wait();
	
	if(activePlayDevice != NULL)
	{
		activePlayDevice->SetDeviceMuted(muteFlag);
	}
	
	activePlayDeviceIsMuted = muteFlag;
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::SetRecordDevice(unsigned int device)
{
	deviceEditMutex.Wait();
	
	AudioDeviceID deviceID = (AudioDeviceID)device;
	
	if(recordDeviceID != deviceID)
	{
		recordDeviceID = deviceID;
		
		if(recordDevice)
		{
			recordDevice->Restart(recordDeviceID);
		}
	}
	
	recordDeviceIsMuted = FALSE;
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::SetRecordDeviceMuted(BOOL muteFlag)
{
	deviceEditMutex.Wait();
	
	if(recordDevice != NULL)
	{
		recordDevice->SetDeviceMuted(muteFlag);
	}
	
	recordDeviceIsMuted = muteFlag;
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::SetMeasureSignalLevels(BOOL flag)
{
	measureSignalLevels = flag;
}

void XMSoundChannel::StopChannels()
{
	deviceEditMutex.Wait();
	if(activePlayDevice != NULL)
	{
		activePlayDevice->StopAudioConversion();
	}
	deviceEditMutex.Signal();
}

#pragma mark Public Methods

XMSoundChannel::XMSoundChannel()
{
	CommonConstruct();
}

XMSoundChannel::XMSoundChannel(const PString & device,
							   PSoundChannel::Directions direction,
							   unsigned numChannels,
							   unsigned sampleRate,
							   unsigned bitsPerSample)
{
	CommonConstruct();	
	Open(device, direction, numChannels, sampleRate, bitsPerSample);
}

XMSoundChannel::~XMSoundChannel()
{
	deviceEditMutex.Wait();
	if(direction == Player)
	{
		activePlayDevice = NULL;
	}
	deviceEditMutex.Signal();
	
	// Closing the device, freeing all buffers
	CloseDevice();
}

PString XMSoundChannel::GetDefaultDevice(PSoundChannel::Directions direction)
{
	return XMSoundChannelDevice;
}

PStringList XMSoundChannel::GetDeviceNames(PSoundChannel::Directions direction)
{
	PStringList devices;
	
	devices.AppendString(XMSoundChannelDevice);
	devices.AppendString(XMInputSoundChannelDevice);
	
	return devices;
}

BOOL XMSoundChannel::Open(const PString & deviceName,
						  PSoundChannel::Directions direction,
						  unsigned numChannels,
						  unsigned sampleRate,
						  unsigned bitsPerSample)
{
	OSStatus err;
	
	if(deviceName == XMInputSoundChannelDevice)
	{
		isInputProxy = TRUE;
		os_handle = 8;
		state = format_set_;
		return TRUE;
	}
	
	deviceEditMutex.Wait();
	if(direction == Player)
	{
		activePlayDevice = this;
		isMuted = activePlayDeviceIsMuted;
	}
	else
	{
		isMuted = recordDeviceIsMuted;
	}
	deviceEditMutex.Signal();
	
	if(deviceName != XMSoundChannelDevice)
	{
		mDeviceID = kAudioDeviceUnknown;
		return FALSE;
	}
	else
	{
		this->direction = direction;
		
		AudioDeviceID deviceID;
		UInt32 theSize = sizeof(deviceID);
		
		deviceEditMutex.Wait();
		if(direction == Player)
		{
			if(activePlayDeviceID == kAudioDeviceUnknown)
			{
				err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
											   &theSize, &deviceID);
			}
			else
			{
				deviceID = activePlayDeviceID;
				err = kAudioHardwareNoError;
			}
		}
		else
		{
			if(recordDeviceID == kAudioDeviceUnknown)
			{
				err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
											   &theSize, &deviceID);
			}
			else
			{
				deviceID = recordDeviceID;
				err = kAudioHardwareNoError;
			}
		}
		
		deviceEditMutex.Signal();
		
		if(err != kAudioHardwareNoError)
		{
			mDeviceID = kAudioDeviceUnknown;
			return FALSE;
		}
		
		return OpenDevice(deviceID, numChannels, sampleRate, bitsPerSample);
	}
}

BOOL XMSoundChannel::IsOpen() const
{
	if(isInputProxy == TRUE)
	{
		return TRUE;
	}
	return os_handle >= 0;
}

unsigned XMSoundChannel::GetChannels() const
{
	if(isInputProxy == TRUE)
	{
		return recordDevice->GetChannels();
	}
	if(state >= format_set_)
	{
		return pwlibASBD.mChannelsPerFrame;
	}
	return 0;
}

unsigned XMSoundChannel::GetSampleRate() const
{
	if(isInputProxy == TRUE)
	{
		return recordDevice->GetSampleRate();
	}
	if(state >= format_set_)
	{
		return (unsigned)(pwlibASBD.mSampleRate);
	}
	return 0;
}

unsigned XMSoundChannel::GetSampleSize() const
{
	if(isInputProxy == TRUE)
	{
		return recordDevice->GetSampleSize();
	}
	if(state >= format_set_)
	{
		return (unsigned)(pwlibASBD.mBitsPerChannel);
	}
	return 0;
}

BOOL XMSoundChannel::SetFormat(unsigned numChannels,
							   unsigned sampleRate,
							   unsigned bitsPerSample)
{
	PAssert((sampleRate == 8000 && numChannels == 1 && bitsPerSample == 16), PUnsupportedFeature);
	
	if(isInputProxy)
	{
		return TRUE;
	}
	
	if(numChannels != 1 || sampleRate != 8000 || bitsPerSample != 16 || state != open_)
	{
		return FALSE;
	}
	
	if(mDeviceID == kAudioDeviceUnknown)
	{
		state = format_set_;
		return TRUE;
	}
	
	/*
	 * Setup the pwlibASBD
	 */
	memset((void *)&pwlibASBD, 0, sizeof(AudioStreamBasicDescription)); 
	
	/* pwlibASBD->mReserved */
	pwlibASBD.mFormatID          = kAudioFormatLinearPCM;
	pwlibASBD.mFormatFlags       = kLinearPCMFormatFlagIsSignedInteger;
	pwlibASBD.mFormatFlags      |= kLinearPCMFormatFlagIsNonInterleaved; 
#if PBYTE_ORDER == PBIG_ENDIAN
	pwlibASBD.mFormatFlags      |= kLinearPCMFormatFlagIsBigEndian;
#endif
	pwlibASBD.mSampleRate        = sampleRate;
	pwlibASBD.mChannelsPerFrame  = numChannels;
	pwlibASBD.mBitsPerChannel    = bitsPerSample;
	pwlibASBD.mBytesPerFrame     = bitsPerSample / 8;
	pwlibASBD.mFramesPerPacket   = 1;
	pwlibASBD.mBytesPerPacket    = pwlibASBD.mBytesPerFrame;
	
	OSStatus err;
	if(direction == Player)
	{
		err = MatchHALOutputFormat();
	}
	else
	{
		err = MatchHALInputFormat();
	}
	checkStatus(err, 1);
	
	/*
	 * Sample Rate Conversion (SRC)
	 * Create AudioConverters, input/output buffers, compute conversion rate 
	 */
	
	// how many samples has the output device compared to pwlib sample rate?
	rateTimes8kHz  = hwASBD.mSampleRate / pwlibASBD.mSampleRate;
	
	/*
	 * Create Converter for Sample Rate conversion
	 */
	if (direction == Player)
	{
		err = AudioConverterNew(&pwlibASBD, &hwASBD, &converter);
	}
	else
	{
		err = AudioConverterNew(&hwASBD, &pwlibASBD, &converter);
	}
	checkStatus(err, 2);
	
	UInt32 quality = kAudioConverterQuality_Max;
	err = AudioConverterSetProperty(converter,
									kAudioConverterSampleRateConverterQuality,
									sizeof(UInt32),
									&quality);
	checkStatus(err, 3);
	
	// trying compute number of requested data more predictably also 
	// for the first request
	UInt32 primeMethod = kConverterPrimeMethod_None;
	err = AudioConverterSetProperty(converter,
									kAudioConverterPrimeMethod,
									sizeof(UInt32),
									&primeMethod);
	checkStatus(err, 4);
	
	state = format_set_;
	return TRUE;
}

BOOL XMSoundChannel::GetBuffers(PINDEX & size,
								PINDEX & count)
{
	if(isInputProxy)
	{
		return recordDevice->GetBuffers(size, count);
	}
	size = bufferSizeBytes;
	count = bufferCount;
	return TRUE;
}

/**
 * SetBuffers is used to create the circular buffer as requested by the caller 
 * plus all the hidden buffers used for Sample-Rate-Conversion(SRC)
 *
 * A device can not be used after calling Open(), SetBuffers() must
 * also be called before it can start working.
 *
 * size:    Size of each buffer
 * count:   Number of buffers
 *
 **/
BOOL XMSoundChannel::SetBuffers(PINDEX bufferSize,
								PINDEX bufferCount)
{
	if(isInputProxy)
	{
		return TRUE;
	}
	OSStatus err = noErr;

	PAssert((bufferSize > 0 && bufferCount > 0 && bufferCount < 65536), PInvalidParameter);
	
	if(state != format_set_ || bufferSize <= 0 || bufferCount <= 0 || bufferCount >= 65536)
	{
		return FALSE;
	}
	
	if(mDeviceID == kAudioDeviceUnknown)
	{
		editMutex.Wait();
		state = buffer_set_;
		editMutex.Signal();
		return TRUE;
	}
	
	editMutex.Wait();
	this->bufferSizeBytes = bufferSize;
	this->bufferCount = bufferCount;
	
	if(mDeviceID == kAudioDeviceUnknown){
		return TRUE;
	}
	
	mCircularBuffer = new XMCircularBuffer(bufferSize * bufferCount);
	
	/** Register callback function */
	err = CallbackSetup();
	
	/* 
	 * Allocate byte array passed as input to the converter 
	 */
	UInt32 bufferSizeFrames, bufferSizeBytes;
	UInt32 propertySize = sizeof(UInt32);
	err = AudioDeviceGetProperty( mDeviceID,
								  0,  // output channel,  
								  true,  // isInput 
								  kAudioDevicePropertyBufferFrameSize,
								  &propertySize,
								  &bufferSizeFrames);
	checkStatus(err, 5);
	bufferSizeBytes = bufferSizeFrames * hwASBD.mBytesPerFrame;
	
	if (direction == Player) {
		UInt32 propertySize = sizeof(UInt32);
		err = AudioConverterGetProperty(converter,
										kAudioConverterPropertyCalculateInputBufferSize,
										&propertySize,
										&bufferSizeBytes);
		checkStatus(err, 6);
		converter_buffer_size = bufferSizeBytes;
	} else {
		// on each turn the device spits out bufferSizeBytes bytes
		// the input ringbuffer has at most MIN_INPUT_FILL frames in it 
		// all other frames were converted during the last callback
		converter_buffer_size = bufferSizeBytes + 
		2 * XM_MIN_INPUT_FILL * hwASBD.mBytesPerFrame;
	}
	converter_buffer = (char*)malloc(converter_buffer_size);
	
	/** In case of Recording we need a couple of buffers more */
	if(direction == Recorder){
		SetupAdditionalRecordBuffers();
	}
	
	/*
	 * AU Setup, allocates necessary buffers... 
	 */
	err = AudioUnitInitialize(mAudioUnit);
	
	state = buffer_set_;
	
	editMutex.Signal();
	
	return TRUE;
}

BOOL XMSoundChannel::Read(void *buffer,
						  PINDEX length)
{
	if(isInputProxy)
	{
		BOOL result = recordDevice->Read(buffer, length);
		return result;
	}
	if(state < buffer_set_)
	{
		return FALSE;
	}
	
	if(isMuted == TRUE || mDeviceID == kAudioDeviceUnknown)
	{
		lastReadCount =  length; 
		bzero(buffer, length);
		
		// we are working with non-interleaved or mono
		UInt32 nr_samples = length / pwlibASBD.mBytesPerFrame;
		usleep(UInt32(nr_samples/pwlibASBD.mSampleRate * 1000000)); // sleep the amount of time to elapse
		return TRUE; 
	}
	
	// Start the device before draining data or the thread might be locked 
	// on an empty buffer and never wake up, because no device is filling
	// with data
	if(state == buffer_set_)
	{
		OSStatus err = StartAudioConversion();
		checkStatus(err, 7);
	}
	
	lastReadCount = mCircularBuffer->Drain((char*)buffer, length, true);
	
	return TRUE;
}

PINDEX XMSoundChannel::GetLastReadCount() const
{
	if(isInputProxy)
	{
		return recordDevice->GetLastReadCount();
	}
	return lastReadCount;
}

BOOL XMSoundChannel::Write(const void *buffer,
						   PINDEX length)
{
	if(isInputProxy)
	{
		return FALSE;
	}
	if(state < buffer_set_)
	{
		return FALSE;
	}
	
	if(isMuted == TRUE || mDeviceID == kAudioDeviceUnknown)
	{
		lastWriteCount =  length; 
		
		// safe to assume non-interleaved or mono
		UInt32 nr_samples = length / pwlibASBD.mBytesPerFrame; 
		
		usleep(UInt32(nr_samples/pwlibASBD.mSampleRate * 1000000)); // 10E-6 [s]

		return TRUE;  
	}
	
	// Start the device before putting data into the buffer
	// Otherwise the thread could be locked in case the buffer is full
	// and the device is not running and draining the buffer
	if(state == buffer_set_)
	{
		OSStatus err = StartAudioConversion();
		checkStatus(err, 8);
	} 
	
	// Write to circular buffer with locking 
	lastWriteCount = mCircularBuffer->Fill((const char*)buffer, length, true);
	
	_XMHandleRemoteAudioFrames((void *)buffer, (length/2));
	
	return TRUE;
}

BOOL XMSoundChannel::StartRecording()
{
	if(isInputProxy)
	{
		return TRUE;
	}
	if(state != buffer_set_){
		return FALSE;
	}
	
	if(isMuted == FALSE && mDeviceID != kAudioDeviceUnknown)
	{
	
		OSStatus err = StartAudioConversion();
		checkStatus(err, 9);
	}
	
	return TRUE;
}

BOOL XMSoundChannel::IsRecordBufferFull()
{
	if(isInputProxy)
	{
		return recordDevice->IsRecordBufferFull();
	}
	PAssert(direction == Recorder, PInvalidParameter);
	
	if(state != buffer_set_)
	{
		return FALSE;
	}
	
	if(isMuted == TRUE || mDeviceID == kAudioDeviceUnknown)
	{
		return TRUE;
	}
	
	return (mCircularBuffer->Size() > bufferSizeBytes);
}

BOOL XMSoundChannel::AreAllRecordBuffersFull()
{
	if(isInputProxy)
	{
		return recordDevice->AreAllRecordBuffersFull();
	}
	PAssert(direction == Recorder, PInvalidParameter);
	
	if(state != buffer_set_|| 
	   isMuted == TRUE || 
	   mDeviceID == kAudioDeviceUnknown)
	{
		return FALSE;
	}
	
	return (mCircularBuffer->Full());
}

#pragma mark Unimplemented Methods

BOOL XMSoundChannel::Abort()
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::GetVolume(unsigned & volume)
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::SetVolume(unsigned volume)
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::PlaySound(const PSound & sound,
							   BOOL wait)
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::PlayFile(const PFilePath & file,
							  BOOL wait)
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::HasPlayCompleted()
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::WaitForPlayCompletion()
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::RecordSound(PSound & sound)
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::RecordFile(const PFilePath & file)
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::WaitForRecordBufferFull()
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

BOOL XMSoundChannel::WaitForAllRecordBuffersFull()
{
	PAssert(0, PUnimplementedFunction);
	return FALSE;
}

#pragma mark Private Methods

void XMSoundChannel::CommonConstruct()
{
	os_handle = -1;
	state = init_;
	isMuted = FALSE;
	mAudioUnit = NULL;
	mDeviceID = kAudioDeviceUnknown;
	converter = NULL;
	mCircularBuffer = NULL; 
	rateTimes8kHz = 0;
	bufferSizeBytes = 0;
	bufferCount = 0;
	converter_buffer = NULL;
	converter_buffer_size = 0;
	mInputCircularBuffer = NULL;
	mInputBufferList = NULL;
	mRecordInputBufferSize = 0;
	mOutputBufferList = NULL;
	mRecordOutputBufferSize = 0;
	isInputProxy = FALSE;
}

BOOL XMSoundChannel::OpenDevice(AudioDeviceID deviceID, 
								unsigned numChannels, 
								unsigned sampleRate,
								unsigned bitsPerSample)
{
	OSStatus err = noErr;
	
	mDeviceID = deviceID;
	
	if(mDeviceID == kAudioDeviceUnknown)
	{
		editMutex.Wait();
		os_handle = 8;
		state = format_set_;
		editMutex.Signal();
		return TRUE;
	}
	
	editMutex.Wait();
	if(direction == Player)
	{
		err = SetupOutputUnit();
	}
	else
	{
		err = SetupInputUnit();
	}
	
	checkStatus(err, 11);
	
	os_handle = 8;	// tell IsOpen() that the channel is open
	
	state = open_;
	
	BOOL result = SetFormat(numChannels, sampleRate, bitsPerSample);
	
	editMutex.Signal();
	
	return result;
}

void XMSoundChannel::CloseDevice()
{
	OSStatus err = noErr;
	
	if(mDeviceID != kAudioDeviceUnknown)
	{
		State curr(state);
	
		/* OutputUnit also for input device,
		 * Stop everything before deallocating buffers
		 */
		switch(curr) {
			case running_:
				err = StopAudioConversion();
				checkStatus(err, 27);
				/* fall through */
			case buffer_set_:
				/* check for all buffers unconditionally */
				err = AudioUnitUninitialize(mAudioUnit);
				checkStatus(err, 28);
				/* fall through */
			case format_set_:
				err = AudioConverterDispose(converter);
				checkStatus(err, 29);
				/* fall through */
			case open_:
				err = CloseComponent(mAudioUnit);
				checkStatus(err, 30);
				/* fall through */
			case init_:
				/* nop */;
		}
	}
	
	/* now free all buffers */
	if(this->converter_buffer != NULL)
	{
		free(this->converter_buffer);
		this->converter_buffer = NULL;
	}
	if(this->mCircularBuffer != NULL)
	{
		delete this->mCircularBuffer;
		this->mCircularBuffer = NULL;
	}
	if(mInputCircularBuffer !=NULL) 
	{
		delete mInputCircularBuffer;
		mInputCircularBuffer = NULL;
	}
	if(this->mInputBufferList != NULL)
	{
		free(this->mInputBufferList);
		this->mInputBufferList = NULL;
	}
	if(this->mOutputBufferList != NULL)
	{
		free(this->mOutputBufferList);
		this->mOutputBufferList = NULL;
	}
	
	// tell IsOpen() that the channel is closed.
	os_handle = -1;
}

void XMSoundChannel::SetDeviceMuted(BOOL muteFlag)
{
	if(muteFlag == FALSE)
	{
		StartAudioConversion();
	}
	else
	{
		StopAudioConversion();
	}
}

void XMSoundChannel::Restart(AudioDeviceID deviceID)
{
	PINDEX size;
	PINDEX count;
	unsigned numChannels = GetChannels();
	unsigned sampleRate = GetSampleRate();
	unsigned bitsPerSample = GetSampleSize();
	GetBuffers(size, count);
	
	CloseDevice();
		
	OpenDevice(deviceID, numChannels, sampleRate, bitsPerSample);
	SetBuffers(size, count);
	StartAudioConversion();
}

OSStatus XMSoundChannel::StartAudioConversion()
{
	OSStatus err = noErr;
	
	editMutex.Wait();
	
	if(state == buffer_set_ || isMuted == TRUE)
	{
		state = running_;
		isMuted = FALSE;
	
		if(mCircularBuffer != NULL)
		{
			mCircularBuffer->Restart();
		}
		if(mInputCircularBuffer != NULL)
		{
			mInputCircularBuffer->Restart();
		}
		
		// starting the AudioOutputUnit
		err = AudioOutputUnitStart(mAudioUnit);
	}
	
	editMutex.Signal();
	
	return err;
}

OSStatus XMSoundChannel::StopAudioConversion()
{
	OSStatus err = noErr;
	
	if(mDeviceID == kAudioDeviceUnknown)
	{
		return noErr;
	}
	
	// entering the critical section
	editMutex.Wait();
	
	if(isMuted == FALSE)
	{
		
		// signaling the stop
		isMuted = TRUE;
	
		if(mCircularBuffer != NULL)
		{
			mCircularBuffer->Stop();
		}
		if(mInputCircularBuffer != NULL)
		{
			mInputCircularBuffer->Stop();
		}
	
		// stopping the audioOutputUnit
		err = AudioOutputUnitStop(mAudioUnit);
	}
	
	editMutex.Signal();
	
	usleep(1000*20);	// about the time of one callback, ensures that the
						// audio processing thread did end
	
	return err;
}

/*
 * Functions to open an AUHAL component and assign it the device indicated 
 * by deviceID. Conigures the unit for match user desired format  as close as
 * possible while not assuming special hardware. (able to change sampling rate)
 */
OSStatus XMSoundChannel::SetupInputUnit()
{
	OSStatus err = noErr;
	
	Component comp;            
	ComponentDescription desc;
	
	//There are several different types of Audio Units.
	//Some audio units serve as Outputs, Mixers, or DSP
	//units. See AUComponent.h for listing
	desc.componentType = kAudioUnitType_Output;
	
	//Every Component has a subType, which will give a clearer picture
	//of what this components function will be.
	desc.componentSubType = kAudioUnitSubType_HALOutput;
	
	//all Audio Units in AUComponent.h must use 
	//"kAudioUnitManufacturer_Apple" as the Manufacturer
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	//Finds a component that meets the desc spec's
	comp = FindNextComponent(NULL, &desc);
	if (comp == NULL)
	{
		return kAudioCodecUnspecifiedError;
	}
	
	//gains access to the services provided by the component
	err = OpenAComponent(comp, &mAudioUnit);
	checkStatus(err, 12);
	
	err = EnableIO();
	checkStatus(err, 13);
	
	err= SetDeviceAsCurrent();
	checkStatus(err, 14);
	
	return err;
}

/*
 * By default all units are configured for output. If we want to use a 
 * unit for input we must configure it, before assigning the corresponding
 * device to it. This to make sure that it asks the device driver for the ASBD
 * of the input direction.
 */
OSStatus XMSoundChannel::EnableIO()
{
	OSStatus err = noErr;
	UInt32 enableIO;
	
	///////////////
	//ENABLE IO (INPUT)
	//You must enable the Audio Unit (AUHAL) for input and disable output 
	//BEFORE setting the AUHAL's current device.
	
	//Enable input on the AUHAL
	enableIO = 1;
	err =  AudioUnitSetProperty(mAudioUnit,
								kAudioOutputUnitProperty_EnableIO,
								kAudioUnitScope_Input,
								1, // input element
								&enableIO,
								sizeof(enableIO));
	checkStatus(err, 15);
	
	//disable Output on the AUHAL
	enableIO = 0;
	err = AudioUnitSetProperty(mAudioUnit,
							   kAudioOutputUnitProperty_EnableIO,
							   kAudioUnitScope_Output,
							   0,   //output element
							   &enableIO,
							   sizeof(enableIO));
	return err;
}

/*
 * Functions to open an AUHAL component and assign it the device indicated 
 * by deviceID. The builtin converter is configured to accept non-interleaved
 * data.
 */
OSStatus XMSoundChannel::SetupOutputUnit(){
	OSStatus err;
	
	//An Audio Unit is a OS component
	//The component description must be setup, then used to 
	//initialize an AudioUnit
	ComponentDescription desc;  
	
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_HALOutput;
	//desc.componentSubType = kAudioUnitSubType_DefaultOutput;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	//Finds an component that meets the desc spec's 
	Component comp = FindNextComponent(NULL, &desc);  
	if (comp == NULL) return kAudioCodecUnspecifiedError;
    
	//gains access to the services provided by the component
	err = OpenAComponent(comp, &mAudioUnit);  
	checkStatus(err, 16);
	
	//enableIO not needed, because output is default
	
	err = SetDeviceAsCurrent();
	return err;
}

OSStatus XMSoundChannel::SetDeviceAsCurrent()
{                       
	OSStatus err = noErr;
	
	// Set the Current Device to the AUHAL.
	// this should be done only after IO has been enabled on the AUHAL.
	// This means the direction selected, to make sure the ASBD for the proper
	// direction is requested
	err = AudioUnitSetProperty(mAudioUnit,
							   kAudioOutputUnitProperty_CurrentDevice,
							   kAudioUnitScope_Global,
							   0,  
							   &mDeviceID,
							   sizeof(mDeviceID));
	checkStatus(err, 18);
	
	return err;
}

/* 
 * Audio Unit for the Hardware Abstraction Layer(AUHAL) have builtin 
 * converters. It would be nice if we could configure it to spit out/consume 
 * the data in the format the data are passed by Read/Write function calls.
 *
 * Unfortunately this is not possible for the microphone, because this 
 * converter does not have a buffer inside, so it cannot do any Sample
 * Rate Conversion(SRC). We would have to set the device nominal sample
 * rate itself to 8kHz. Unfortunately not all microphones can do that,
 * so this is not an option. Maybe there will be some change in the future
 * by Apple, so we leave it here. 
 *
 * For the output we have the problem that we do not know currently how
 * to configure the channel map so that a mono input channel gets copied 
 * to all output channels, so we still have to do the conversion ourselves
 * to copy the result onto all output channels.
 *
 * Still the builtin converters can be used for something useful, such as 
 * converting from interleaved -> non-interleaved and to reduce the number of 
 * bits per sample to save space and time while copying 
 */

/* 
 * Configure the builtin AudioConverter to accept non-interleaved data.
 * Turn off SRC by setting the same sample rate at both ends.
 * See also general notes above
 */ 
OSStatus XMSoundChannel::MatchHALOutputFormat()
{
	OSStatus err = noErr;
	//AudioStreamBasicDescription& asbd = hwASBD;
	UInt32 size = sizeof (AudioStreamBasicDescription);
	
	memset(&hwASBD, 0, size);
	
	//Get the current stream format of the output
	err = AudioUnitGetProperty (mAudioUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Output,
								0,  // output bus 
								&hwASBD,
								&size);
	checkStatus(err, 19);  
	
	// make sure it is non-interleaved
	BOOL isInterleaved = !(hwASBD.mFormatFlags & kAudioFormatFlagIsNonInterleaved);
	
	hwASBD.mFormatFlags |= kAudioFormatFlagIsNonInterleaved; 
	if(isInterleaved){
		// so its only one buffer containing all data, according to 
		// list.apple.com: You only multiply out by mChannelsPerFrame 
		// if you are doing interleaved.
		hwASBD.mBytesPerPacket /= hwASBD.mChannelsPerFrame;
		hwASBD.mBytesPerFrame  /= hwASBD.mChannelsPerFrame;
	}
	
	//Set the stream format of the output to match the input
	err = AudioUnitSetProperty(mAudioUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   0,
							   &hwASBD,
							   size);
	
	
	// make sure we really know the current format
	size = sizeof (AudioStreamBasicDescription);
	err = AudioUnitGetProperty(mAudioUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   0,  // input bus
							   &hwASBD,
							   &size);
	
	return err;
}


/* 
 * Configure the builtin AudioConverter to provide data in non-interleaved 
 * format. Turn off SRC by setting the same sample rate at both ends.
 * See also general notes above
 */ 
OSStatus XMSoundChannel::MatchHALInputFormat()
{
	OSStatus err = noErr;
	AudioStreamBasicDescription& asbd = hwASBD;
	UInt32 size = sizeof (AudioStreamBasicDescription);
	
	memset(&asbd, 0, size);
	
	//Get the current stream format of the output
	err = AudioUnitGetProperty(mAudioUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   1,  // input bus/
							   &asbd,
							   &size);
	
	/*
	 * make it one-channel, non-interleaved, keeping same sample rate 
	 */
	BOOL isInterleaved = !(asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved); 
	
	// mFormatID -> assume lpcm !!!
	asbd.mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
	
	if(isInterleaved)
	{
		// so it's only one buffer containing all channels, according to 
		//list.apple.com: You only multiple out by mChannelsPerFrame 
		//if you are doing interleaved.
		asbd.mBytesPerPacket /= asbd.mChannelsPerFrame;
		asbd.mBytesPerFrame  /= asbd.mChannelsPerFrame;
	}
	
	asbd.mChannelsPerFrame = 1;
	
	// Set it to output side of input bus
	size = sizeof (AudioStreamBasicDescription);
	err = AudioUnitSetProperty(mAudioUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Output,
							   1,  // input bus
							   &asbd,
							   size);
	checkStatus(err, 20);
	
	// make sure we really know the current format
	size = sizeof(AudioStreamBasicDescription);
	err = AudioUnitGetProperty(mAudioUnit,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Output,
							   1,  // input bus
							   &hwASBD,
							   &size);
	
	return err;
}

OSStatus XMSoundChannel::CallbackSetup()
{
	OSStatus err = noErr;
	AURenderCallbackStruct callback;
	
	callback.inputProcRefCon = this;
	if (direction == Recorder) 
	{
		callback.inputProc = RecordProc;
		/* kAudioOutputUnit stands for both Microphone/Speaker */
		err = AudioUnitSetProperty(mAudioUnit,
								   kAudioOutputUnitProperty_SetInputCallback,
								   kAudioUnitScope_Global,
								   0,
								   &callback,
								   sizeof(callback));
		
	}
	else 
	{
		callback.inputProc = PlayRenderProc;
		err = AudioUnitSetProperty(mAudioUnit, 
								   kAudioUnitProperty_SetRenderCallback,
								   kAudioUnitScope_Input,
								   0,
								   &callback,
								   sizeof(callback));
	}
	
	checkStatus(err, 21);
	return err;
}

/*
 * Functions responsible for converting 8kHz to 44k1Hz. It works like this. 
 * The AudioHardware is abstracted by an AudioUnit(AUHAL). Each time the device
 * has more data available or needs new data a callback function is called.
 * These are PlayRenderProc and RecordProc. 
 *
 * The user data is stored in a format a set by ::SetFormat. Usually 8kHz, mono,
 * 16bit unsigned. The AudioUnit usually provides 44,1kHz, stereo, 32bit float.
 * So conversion is needed. The conversion is done by the AUConverter from 
 * the AudioToolbox framework.
 *
 * Currently inside the callback functions from the AUHAL, we pass the request
 * to the Converter, that in turn uses another callback function to grab some
 * of data in the input format. All this is done on-the-fly, which means inside
 * the thread managing the AudioHardware. The callback functions of the 
 * converter are ComplexBufferFillPlayback, ComplexbufferFillRecord.
 *
 * The problem we have that 44,1kHz is not a multiple of 8kHz, so we can never 
 * be sure about how many data the converter is going to ask exactly, 
 * sometimes it might be 102, 106.. This is especially true in case of the 
 * first request, where it might ask some additional data depending on 
 * PrimeMethod that garantuees smoth resampling at the border.
 *
 * To summarize, when the AudioUnit device is ready to handle more data, it 
 * calls its callback function, within these functions the data is processed or 
 * prepared by pulling through AUConverter. The converter in turn calls its 
 * callback function to request more input data. Depending on whether we talk 
 * about Read or Write, this includes more or less complex buffering. 
 */

/*
 *  Callback function called by the converter to request more data for 
 *  playback.
 *  
 *  outDataPacketDesc is unused, because all our packets have the same
 *  format and do not need individual description
 */
OSStatus XMSoundChannel::ComplexBufferFillPlayback(AudioConverterRef inAudioConverter,
												   UInt32 *ioNumberDataPackets,
												   AudioBufferList *ioData,
												   AudioStreamPacketDescription **outDataPacketDesc,
												   void *inUserData)
{
	OSStatus err = noErr;
	XMSoundChannel *This = static_cast<XMSoundChannel*>(inUserData);
	
	AudioStreamBasicDescription pwlibASBD = This->pwlibASBD;
	XMCircularBuffer* circBuf = This->mCircularBuffer;
	
	// output might stop in case there is a complete buffer underrun!!!
	UInt32 minPackets = MIN(*ioNumberDataPackets, circBuf->Size() / pwlibASBD.mBytesPerPacket);
	UInt32 outBytes = minPackets* pwlibASBD.mBytesPerPacket;
	
	
	if(outBytes > This->converter_buffer_size)
	{
		// doesn't matter converter will ask right again for remaining data
		// converter buffer multiple of packet size
		outBytes = This->converter_buffer_size;
	}
	
	// dequeue data from circular buffer, without locking(false)
	outBytes = circBuf->Drain(This->converter_buffer, outBytes, false);
	
	UInt32 reqBytes = *ioNumberDataPackets * pwlibASBD.mBytesPerPacket;
	if(outBytes < reqBytes && outBytes < This->converter_buffer_size) 
	{
		reqBytes = MIN(reqBytes, This->converter_buffer_size);
		
		bzero(This->converter_buffer + outBytes, reqBytes - outBytes );
		outBytes = reqBytes;
	}
	
	// fill structure that gets returned to converter
	ioData->mBuffers[0].mData = (char*)This->converter_buffer;
	ioData->mBuffers[0].mDataByteSize = outBytes;
	
	*ioNumberDataPackets = outBytes / pwlibASBD.mBytesPerPacket;
	
	return err;
}

/* 
 * Callback function called by the converter to fetch more date 
 */
OSStatus XMSoundChannel::ComplexBufferFillRecord(AudioConverterRef inAudioConverter,
												 UInt32 *ioNumberDataPackets,
												 AudioBufferList *ioData,
												 AudioStreamPacketDescription **outDataPacketDesc,
												 void *inUserData)
{
	OSStatus err = noErr;
	XMSoundChannel *This = static_cast<XMSoundChannel *>(inUserData);
	XMCircularBuffer* inCircBuf = This->mInputCircularBuffer;
	AudioStreamBasicDescription& hwASBD = This->hwASBD;
	
	// make sure it's always a multiple of packets
	UInt32 minPackets = MIN(*ioNumberDataPackets, inCircBuf->Size() / hwASBD.mBytesPerPacket );
	UInt32 ioBytes = minPackets * hwASBD.mBytesPerPacket;
	
	if(ioBytes > This->converter_buffer_size)
	{
		ioBytes = This->converter_buffer_size;
	}
	
	ioBytes = inCircBuf->Drain((char*)This->converter_buffer, ioBytes, false);
	
	if(ioBytes  != minPackets * hwASBD.mBytesPerPacket) {
		// no more a multiple of packet problably !!!
		//PTRACE(1, "Failed to fetch the computed number of packets");
	}
	
	ioData->mBuffers[0].mData = This->converter_buffer;
	ioData->mBuffers[0].mDataByteSize = ioBytes;
	
	// assuming non-interleaved or mono 
	*ioNumberDataPackets = ioBytes / hwASBD.mBytesPerPacket;
	
	return err;
}

/*
 * CoreAudio Player callback function
 */
OSStatus XMSoundChannel::PlayRenderProc(void *inRefCon,
										AudioUnitRenderActionFlags* ioActionFlags,
										const struct AudioTimeStamp* TimeStamp,
										UInt32 inBusNumber,
										UInt32 inNumberFrames,
										struct AudioBufferList* ioData)
{  
	OSStatus err = noErr;
	XMSoundChannel*This = static_cast<XMSoundChannel *>(inRefCon);
	
	if( This->state != running_  || This->mCircularBuffer->Empty() ) {
		return noErr;
	}
	
	err = AudioConverterFillComplexBuffer(This->converter,
										  XMSoundChannel::ComplexBufferFillPlayback, 
										  This, 
										  &inNumberFrames, // should be packets
										  ioData,
										  NULL /*outPacketDescription*/);
	checkStatus(err, 22);
	
	
	/* now that cpu intensive work is done, make stereo from mono
		* assume non-interleaved ==> 1 buffer per channel */
	UInt32 len = ioData->mBuffers[0].mDataByteSize;
	if(len > 0 && This->state == running_)
	{
		unsigned i = 1;
		while(i < ioData->mNumberBuffers) 
		{
			memcpy(ioData->mBuffers[i].mData, ioData->mBuffers[0].mData, len);  
			ioData->mBuffers[i].mDataByteSize = len;
			i++;
		}
	}
	
	return err;
}

OSStatus XMSoundChannel::RecordProc(void *inRefCon,
									AudioUnitRenderActionFlags *ioActionFlags,
									const AudioTimeStamp *inTimeStamp,
									UInt32 inBusNumber,
									UInt32 inNumberFrames,
									AudioBufferList *ioData)
{	
	OSStatus err = noErr;
	XMSoundChannel *This = static_cast<XMSoundChannel *>(inRefCon);
	XMCircularBuffer* inCircBuf   = This->mInputCircularBuffer;
	AudioStreamBasicDescription asbd = This->hwASBD;
	
	if(This->state != running_)
	{
		return noErr;
	}
	
	if( This->mRecordInputBufferSize < inNumberFrames * asbd.mFramesPerPacket)
	{
		inNumberFrames = This->mRecordInputBufferSize / asbd.mFramesPerPacket;
	}
	
	/* fetch the data from the microphone or other input device */
	AudioBufferList*  inputData =  This->mInputBufferList;
	err= AudioUnitRender(This->mAudioUnit,
						 ioActionFlags,
						 inTimeStamp, 
						 inBusNumber,
						 inNumberFrames, //# of frames  requested
						 inputData);// Audio Buffer List to hold data    
	checkStatus(err, 23);
		
	/* in any case reduce to mono by taking only the first buffer */
	AudioBuffer *audio_buf = &inputData->mBuffers[0];
	inCircBuf->Fill((char *)audio_buf->mData, audio_buf->mDataByteSize, 
						false, true); // do not wait, overwrite oldest frames 
		
	/*
	 * Sample Rate Conversion(SRC)
	 */
	unsigned int frames = inCircBuf->Size() / This->hwASBD.mBytesPerFrame;
		
		
	/* given the number of Microphone frames how many 8kHz frames are
	 * to expect, keeping a minimum buffer fill of XM_MIN_INPUT_FILL frames to 
	 * have some data handy in case the converter requests more Data */
	if(frames > XM_MIN_INPUT_FILL)
	{
		UInt32 pullFrames = int(float(frames-XM_MIN_INPUT_FILL)/This->rateTimes8kHz);
		UInt32 pullBytes = MIN( This->converter_buffer_size, pullFrames * This->pwlibASBD.mBytesPerFrame);
			
		UInt32 pullPackets = pullBytes / This->pwlibASBD.mBytesPerPacket;
			
		/* now pull the frames through the converter */
		AudioBufferList* outputData = This->mOutputBufferList;
		err = AudioConverterFillComplexBuffer(This->converter,
											  XMSoundChannel::ComplexBufferFillRecord, 
											  This, 
											  &pullPackets, 
											  outputData, 
											  NULL /*outPacketDescription*/);
		checkStatus(err, 24);
			
		/* put the converted data into the main CircularBuffer for later 
		 * fetching by the public Read function */
		audio_buf = &outputData->mBuffers[0];
		This->mCircularBuffer->Fill((char*)audio_buf->mData, 
									audio_buf->mDataByteSize, 
									false, true); // do not wait, overwrite oldest frames
		
		_XMHandleLocalAudioFrames(audio_buf->mData, (audio_buf->mDataByteSize/2));
		
		/* Doing a (primitive) form of level metering: if the measureInputLevel flag is
		 * set, calculate the average of the absolute values of the samples just processed. 
		 * This uses the same  algorithm as OpalPCM16SilenceDetector::GetAverageSignalLevel() */
		if(measureSignalLevels == TRUE) 
		{
			if(inputSignalLevelCounter % 4 == 0)
			{
				int sum = 0;
				PINDEX samples = audio_buf->mDataByteSize/2;
				const short *pcm = (const short *)audio_buf->mData;
				const short *end = pcm + samples;
				while (pcm != end) {
					if(*pcm < 0) {
						sum -= *pcm++;
					} else {
						sum += *pcm++;
					}
				}
			
				int intLevel = sum/samples;
			
				// convert it to logarithmic scale
				intLevel = linear2ulaw(intLevel) ^ 0xff;
			
				// filter out some noise
				if(intLevel < 15) {
					intLevel = 0;
				}
			
				// transform it into double and normalizing it
				// signed 8-bit integer: maximum is 128
				double doubleLevel = (intLevel / 128.0);
			
				_XMHandleAudioInputLevel(doubleLevel);
			}
		}
		inputSignalLevelCounter++;
	}

	return err;
}

OSStatus XMSoundChannel::SetupAdditionalRecordBuffers()
{
	OSStatus err = noErr;
	UInt32 bufferSizeFrames, bufferSizeBytes;
	
	/*
	 * build buffer list to take over the data from the microphone 
	 */
	UInt32 propertySize = sizeof(UInt32);
	err = AudioDeviceGetProperty(mDeviceID,
								 0,  // channel, probably all  
								 true,  // isInput 
										 //false,  // isInput ()
								 kAudioDevicePropertyBufferFrameSize,
								 &propertySize,
								 &bufferSizeFrames);
	checkStatus(err, 25);
	bufferSizeBytes = bufferSizeFrames * hwASBD.mBytesPerFrame;
	bufferSizeBytes += bufferSizeBytes / 10; // +10%
	
	//calculate size of ABL given the last field, assum non-interleaved 
	UInt32 mChannelsPerFrame = hwASBD.mChannelsPerFrame;
	UInt32 propsize = (UInt32) &(((AudioBufferList *)0)->mBuffers[mChannelsPerFrame]);
	
	//malloc buffer lists
	mInputBufferList = (AudioBufferList *)malloc(propsize);
	mInputBufferList->mNumberBuffers = hwASBD.mChannelsPerFrame;
	
	//pre-malloc buffers for AudioBufferLists
	for(UInt32 i =0; i< mInputBufferList->mNumberBuffers ; i++) 
	{
		mInputBufferList->mBuffers[i].mNumberChannels = 1;
		mInputBufferList->mBuffers[i].mDataByteSize = bufferSizeBytes;
		mInputBufferList->mBuffers[i].mData = malloc(bufferSizeBytes);
	}
	mRecordInputBufferSize = bufferSizeBytes;
	
	/** allocate ringbuffer to cache data before passing them to the converter */
	// take only one buffer -> mono, use double buffering
	mInputCircularBuffer = new XMCircularBuffer(bufferSizeBytes * 2);
	
	
	/* 
	 * Build buffer list that is passed to the Converter to be filled with 
	 * the converted frames.
	 */
	// given the number of input bytes how many bytes to expect at the output?
	bufferSizeBytes += XM_MIN_INPUT_FILL * hwASBD.mBytesPerFrame;
	propertySize = sizeof(UInt32);
	err = AudioConverterGetProperty(converter,
									kAudioConverterPropertyCalculateOutputBufferSize,
									&propertySize,
									&bufferSizeBytes);
	checkStatus(err, 26);
	
	//calculate number of buffers from channels
	mChannelsPerFrame = pwlibASBD.mChannelsPerFrame;
	propsize = (UInt32) &(((AudioBufferList *)0)->mBuffers[mChannelsPerFrame]);
	
	//malloc buffer lists
	mOutputBufferList = (AudioBufferList *)malloc(propsize);
	mOutputBufferList->mNumberBuffers = pwlibASBD.mChannelsPerFrame;
	
	//pre-malloc buffers for AudioBufferLists
	for(UInt32 i =0; i< mOutputBufferList->mNumberBuffers ; i++)
	{
		mOutputBufferList->mBuffers[i].mNumberChannels = 1;
		mOutputBufferList->mBuffers[i].mDataByteSize = bufferSizeBytes;
		mOutputBufferList->mBuffers[i].mData = malloc(bufferSizeBytes);
	}
	mRecordOutputBufferSize = bufferSizeBytes;
	
	return err;
}