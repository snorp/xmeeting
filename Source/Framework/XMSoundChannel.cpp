/*
 * $Id: XMSoundChannel.cpp,v 1.13 2007/03/13 01:15:49 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Andreas Fenkart, Hannes Friederich. All rights reserved.
 */

#include "XMBridge.h"
#include "XMSoundChannel.h"
#include "XMCircularBuffer.h"
#include "XMCircularBuffer.cpp"
#include "XMCallbackBridge.h"

#define checkStatus( err, location ) \
if(err) {\
	PTRACE(1, "XMSoundChannelError: " << err << " (" << location << ")"); \
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
static BOOL runInputDevice = FALSE;
static BOOL recordAudio = FALSE;
static AudioDeviceID recordDeviceID = kAudioDeviceUnknown;
static BOOL recordDeviceIsMuted = FALSE;
static BOOL measureSignalLevels = FALSE;
static int inputSignalLevelCounter = 0;

#pragma mark -
#pragma mark Static Methods

void XMSoundChannel::Init()
{
	deviceEditMutex.Wait(); // should not be needed, but one never knows...
	
	OSStatus err = noErr;
	
	UInt32 deviceIDSize = sizeof(AudioDeviceID);
	
	// define default audio devices to start with
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
								   &deviceIDSize,
								   &activePlayDeviceID);
	checkStatus(err, 50);
	
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice,
								   &deviceIDSize,
								   &recordDeviceID);
	checkStatus(err, 51);
	
	// Start the singleton record device that is always present (but not always running).
	// This is needed to enable input metering
	PString deviceName = XMSoundChannelDevice;
	recordDevice = new XMSoundChannel(deviceName, PSoundChannel::Recorder,
									  1, 8000, 16);
	recordDevice->SetBuffers(320, 2); // always needed before running
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::DoClose()
{
	deviceEditMutex.Wait();
	
	StopChannels();
	if(recordDevice != NULL) {
		recordDevice->Stop();
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
		
		recordDevice->Restart(recordDeviceID, FALSE);
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
	deviceEditMutex.Wait();
	
	measureSignalLevels = flag;
	if(measureSignalLevels == TRUE)
	{
		recordDevice->Start();
	}
	else if(runInputDevice == FALSE && recordAudio == FALSE)
	{
		recordDevice->Stop();
	}
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::SetRecordAudio(BOOL flag)
{
	deviceEditMutex.Wait();
	
	recordAudio = flag;
	if(recordAudio == TRUE)
	{
		recordDevice->Start();
	}
	else if(runInputDevice == FALSE && measureSignalLevels == FALSE)
	{
		recordDevice->Stop();
	}
	
	deviceEditMutex.Signal();
}

void XMSoundChannel::StopChannels()
{
	deviceEditMutex.Wait();
	if(activePlayDevice != NULL)
	{
		activePlayDevice->Stop();
	}
	deviceEditMutex.Signal();
}

#pragma mark -
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
	PWaitAndSignal m(deviceEditMutex);
	
	if(direction == Player)
	{	
		// detach the activePlayDevice pointer
		activePlayDevice = NULL;
	}
	else if(isInputProxy == TRUE)
	{
		runInputDevice = FALSE;
		if(measureSignalLevels == FALSE && recordAudio == FALSE)
		{
			recordDevice->Stop();
		}
	}
	
	PWaitAndSignal m2(editMutex);
	
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
	PWaitAndSignal m(editMutex);
	
	if(deviceName == XMInputSoundChannelDevice)
	{
		// This instance is just a thin 'proxy'
		// that forwards all requests to the singleton
		// record device already present
		isInputProxy = TRUE;
        this->direction = direction;
		os_handle = 8;
		state = format_set_;
		runInputDevice = TRUE;
		recordDevice->Start();
		return TRUE;
	}
	
	if(direction == Player)
	{
		activePlayDevice = this;
		isMuted = activePlayDeviceIsMuted;
	}
	else
	{
		isMuted = recordDeviceIsMuted;
	}
	
	if(deviceName != XMSoundChannelDevice)
	{
		// an error, should not happen!
		mDeviceID = kAudioDeviceUnknown;
		return FALSE;
	}
	else
	{
		// set direction of device
		this->direction = direction;
		
		AudioDeviceID deviceID;
		
		// determine which audio device to take
		deviceEditMutex.Wait();
		if(direction == Player)
		{
			deviceID = activePlayDeviceID;
		}
		else
		{
			deviceID = recordDeviceID;
		}
		deviceEditMutex.Signal();
		
		return OpenDevice(deviceID, numChannels, sampleRate, bitsPerSample);
	}
}

BOOL XMSoundChannel::IsOpen() const
{
	PWaitAndSignal m(editMutex);
	
	if(isInputProxy == TRUE)
	{
		return TRUE;
	}
	return os_handle >= 0;
}

unsigned XMSoundChannel::GetChannels() const
{
	PWaitAndSignal m(editMutex);
	
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
	PWaitAndSignal m(editMutex);
	
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
	PWaitAndSignal m(editMutex);
	
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
	PWaitAndSignal m(editMutex);
	
	// Currently, only 8kHz, 16-bit linear PCM (mono) is supported
	PAssert((sampleRate == 8000 && numChannels == 1 && bitsPerSample == 16), PUnsupportedFeature);
	
	// input proxies just forward to the singleton instance
	if(isInputProxy)
	{
		return TRUE;
	}
	
	if(state != open_)
	{
		return FALSE;
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
    
    // dummy device needs nothing to set up
	if(mDeviceID == kAudioDeviceUnknown)
	{
		state = format_set_;
		return TRUE;
	}
	
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
	
	// Bluetooth devices record at 8kHz. They don't need any
	// sample rate conversion. Don't set the Quality and
	// prime method quantities as they're not supported by this
	// converter anyway
	if(hwASBD.mSampleRate != pwlibASBD.mSampleRate)
	{
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
	}
	
	state = format_set_;
	return TRUE;
}

BOOL XMSoundChannel::GetBuffers(PINDEX & size,
								PINDEX & count)
{
	PWaitAndSignal m(editMutex);
	
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
	PWaitAndSignal m(editMutex);
	
	OSStatus err = noErr;
	
	if(isInputProxy)
	{
		return TRUE; // not needed for thin proxies
	}

	// validity checks
	PAssert((bufferSize > 0 && bufferCount > 0 && bufferCount < 65536), PInvalidParameter);
	if(state != format_set_)
	{
		return FALSE;
	}
	
	this->bufferSizeBytes = bufferSize;
	this->bufferCount = bufferCount;
	
	if(mDeviceID == kAudioDeviceUnknown)
	{
		state = buffer_set_;
		return TRUE;
	}
	
	mCircularBuffer = new XMCircularBuffer(bufferSize * bufferCount);
	
	/** Register callback function */
	err = CallbackSetup();
    checkStatus(err, 7);
	
	if (direction == Player) {
		UInt32 propertySize = sizeof(UInt32);
		err = AudioConverterGetProperty(converter,
										kAudioConverterPropertyCalculateInputBufferSize,
										&propertySize,
										&bufferSizeBytes);
		checkStatus(err, 6);
		converter_buffer_size = bufferSizeBytes;
	} else {        UInt32 bufferSizeFrames;
        UInt32 propertySize;
        
        // Try to obtain the variable frame size
        propertySize = sizeof(UInt32);
        err = AudioDeviceGetProperty( mDeviceID,
                                      0, // output channel
                                      true, // is input
                                      kAudioDevicePropertyUsesVariableBufferFrameSizes,
                                      &propertySize,
                                      &bufferSizeFrames);
        if (err != noErr)
        {
            // Variable size didn't work out. Take fixed size
            propertySize = sizeof(UInt32);
            err = AudioDeviceGetProperty( mDeviceID,
                                          0, // output channel
                                          true, // is input
                                          kAudioDevicePropertyBufferFrameSize,
                                          &propertySize,
                                          &bufferSizeFrames);
            checkStatus(err, 5);
        }
        
		// on each turn the device spits out bufferSizeBytes bytes
		// the input ringbuffer has at most MIN_INPUT_FILL frames in it 
		// if all other frames were converted during the last callback
		converter_buffer_size = (bufferSizeFrames + 2 * XM_MIN_INPUT_FILL) * hwASBD.mBytesPerFrame;
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
	
	return TRUE;
}

BOOL XMSoundChannel::Read(void *buffer,
						  PINDEX length)
{
    
	// input proxies just forward to the singleton instance
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
        // Siimply fill the buffer with zeros
        lastReadCount =  length; 
		bzero(buffer, length);
        
        // Determine how long to sleep. 
        // This is required to obtain the correct target data rate.
        struct timeval currentTime;
        gettimeofday(&currentTime, NULL);
        muteBytesRead += length;
        unsigned bytesPerSecond = pwlibASBD.mSampleRate * pwlibASBD.mBytesPerFrame;
        unsigned millisecondsSinceStart = (unsigned)(float(muteBytesRead) * 1000 /(float)bytesPerSecond);
        unsigned timeElapsed = ((currentTime.tv_sec - muteStartTime.tv_sec) * 1000) +
                               ((currentTime.tv_usec - muteStartTime.tv_usec) / 1000);
        int timeToWait = millisecondsSinceStart - timeElapsed;
        
        if (timeToWait > 0) {
            // Sleep the desired amount
            usleep(1000 * timeToWait);
        }

		return TRUE; 
	}
	
    // wait at most half a second
	lastReadCount = mCircularBuffer->Drain((char*)buffer, length, true, 500);
	
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
	PWaitAndSignal m(editMutex);
	
	if(isInputProxy)
	{
		return TRUE;
	}
	if(state != buffer_set_){
		
		return FALSE;
	}
	
	return TRUE;
}

BOOL XMSoundChannel::IsRecordBufferFull()
{
	PWaitAndSignal m(editMutex);
	
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
	PWaitAndSignal m(editMutex);
	
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

#pragma mark -
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

#pragma mark -
#pragma mark Private Methods

void XMSoundChannel::CommonConstruct()
{
    os_handle = -1; // member of PSoundChannel
    
    isInputProxy = FALSE;
    direction = Player;
    state = init_;
	isMuted = FALSE;
	mAudioUnit = NULL;
	mDeviceID = kAudioDeviceUnknown;
	converter = NULL;
	mCircularBuffer = NULL; 
	rateTimes8kHz = 0;
	bufferSizeBytes = 0;
	bufferCount = 0;
    muteBytesRead = 0;
    muteStartTime.tv_sec = 0;
    muteStartTime.tv_usec = 0;
	converter_buffer = NULL;
	converter_buffer_size = 0;
	mInputCircularBuffer = NULL;
	mInputBufferList = NULL;
	mOutputBufferList = NULL;
	mRecordOutputBufferSize = 0;
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
		// dummy device, always returning zero buffers
		os_handle = 8;
		state = format_set_;
        muteBytesRead = 0;
        gettimeofday(&muteStartTime, NULL);
		return TRUE;
	}
	
	// setup the underlying audio units
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
	
	// adjusting state
	state = open_;
	
	// Set the format
	BOOL result = SetFormat(numChannels, sampleRate, bitsPerSample);
	
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
	
	// reset the state
	state = init_;
	
	// tell IsOpen() that the channel is closed.
	os_handle = -1;
}

void XMSoundChannel::SetDeviceMuted(BOOL muteFlag)
{
	PWaitAndSignal m(editMutex);
	
    if (muteFlag != isMuted)
    {
        if(muteFlag == FALSE)
        {
            isMuted = FALSE;
            StartAudioConversion();
        }
        else
        {
            muteBytesRead = 0;
            gettimeofday(&muteStartTime, NULL);
            isMuted = TRUE;
            StopAudioConversion();
        }
    }
}

void XMSoundChannel::Start()
{
	PWaitAndSignal m(editMutex);
	StartAudioConversion();
}

void XMSoundChannel::Stop()
{
	PWaitAndSignal m(editMutex);
	StopAudioConversion();
}

void XMSoundChannel::Restart(AudioDeviceID deviceID, BOOL startIfNeeded)
{
	PWaitAndSignal m(editMutex);
	
	int currentState = state;
	
	PINDEX size;
	PINDEX count;
	unsigned numChannels = GetChannels();
	unsigned sampleRate = GetSampleRate();
	unsigned bitsPerSample = GetSampleSize();
	GetBuffers(size, count);
	
	// Close the existing device
	CloseDevice();
		
	// Resequencing the restart using the new device ID
	OpenDevice(deviceID, numChannels, sampleRate, bitsPerSample);
	SetBuffers(size, count);
	
	if(currentState == running_ || startIfNeeded == TRUE)
	{
		StartAudioConversion();
	}
}

OSStatus XMSoundChannel::StartAudioConversion()
{
	OSStatus err = noErr;
	
	if(state == buffer_set_)
	{
		state = running_;
	
		if(mCircularBuffer != NULL)
		{
            mCircularBuffer->SetDataRate(pwlibASBD.mBytesPerFrame * pwlibASBD.mSampleRate);
			mCircularBuffer->Restart();
		}
		if(mInputCircularBuffer != NULL)
		{
			mInputCircularBuffer->Restart();
		}
		
		// starting the AudioOutputUnit
		err = AudioOutputUnitStart(mAudioUnit);
		checkStatus(err, 98);
	}
	
	return err;
}

OSStatus XMSoundChannel::StopAudioConversion()
{
	OSStatus err = noErr;
	
	if(mDeviceID == kAudioDeviceUnknown)
	{
		return noErr;
	}

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
	checkStatus(err, 99);
	
	state = buffer_set_;
	
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
	
	if( This->state != running_) {
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
	
    // protection against buffer overflow
	if( This->converter_buffer_size < inNumberFrames * asbd.mFramesPerPacket)
	{
		inNumberFrames = This->converter_buffer_size / asbd.mFramesPerPacket;
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
    UInt32 propertySize;
	
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
		mInputBufferList->mBuffers[i].mDataByteSize = converter_buffer_size;
		mInputBufferList->mBuffers[i].mData = malloc(converter_buffer_size);
	}
	
	/** allocate ringbuffer to cache data before passing them to the converter */
	// take only one buffer -> mono, use double buffering
	mInputCircularBuffer = new XMCircularBuffer(converter_buffer_size * 2);
	
	/* 
	 * Build buffer list that is passed to the Converter to be filled with 
	 * the converted frames.
	 */
	// given the number of input bytes how many bytes to expect at the output?
	UInt32 bufferSizeBytes = converter_buffer_size;
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