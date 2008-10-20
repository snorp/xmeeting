/*
 * $Id: XMMediaTransmitter.m,v 1.64 2008/10/20 22:06:42 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#import "XMMediaTransmitter.h"

#import <Accelerate/Accelerate.h>

#import <sys/time.h>

#import "XMPrivate.h"

#import "XMPacketBuilder.h"
#import "XMRTPH263Packetizer.h"
#import "XMRTPH263PlusPacketizer.h"
#import "XMRTPH264Packetizer.h"

#import "XMSequenceGrabberVideoInputModule.h"
#import "XMStillImageVideoInputModule.h"
#import "XMScreenVideoInputModule.h"
#import "XMDummyVideoInputModule.h"

#import "XMBridge.h"
#import "XMCallbackBridge.h"

typedef enum XMMediaTransmitterMessage
{
  // general messages
  _XMMediaTransmitterMessage_Shutdown= 0x0000,
	
  // configuration messages
  _XMMediaTransmitterMessage_GetDeviceList = 0x0100,
  _XMMediaTransmitterMessage_SetDevice,
  _XMMediaTransmitterMessage_SetFrameGrabRate,
	
  // "action" messages
  _XMMediaTransmitterMessage_StartVideoDisplay = 0x0200,
  _XMMediaTransmitterMessage_StopVideoDisplay,
  _XMMediaTransmitterMessage_StartTransmitting,
  _XMMediaTransmitterMessage_StopTransmitting,
  _XMMediaTransmitterMessage_UpdatePicture,
  _XMMediaTransmitterMessage_SetMaxBitrate,
  _XMMediaTransmitterMessage_SetVideoBytesSent,
  _XMMediaTransmitterMessage_StartRecording,
  _XMMediaTransmitterMessage_StopRecording,
	
  // settings handling
  _XMMediaTransmitterMessage_SendSettingsToModule = 0x300
	
} XMMediaTransmitterMessage;

@class XMVideoInputModuleWrapper;

@interface XMMediaTransmitter (PrivateMethods)

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components;

- (NSPort *)_receivePort;
- (XMVideoInputModuleWrapper *)_wrapperForDevice:(NSString *)device;
- (void)_sendDeviceList;
- (void)_handleErrorReport:(NSArray *)errorReport;
- (void)_handleMediaTransmitterThreadDidExit;

- (void)_runMediaTransmitThread;
- (BOOL)_isTransmitting;
- (BOOL)_isRecording;
- (void)handlePortMessage:(NSPortMessage *)portMessage;

- (void)_handleShutdownMessage;
- (void)_handleGetDeviceListMessage;
- (void)_handleSetDeviceMessage:(NSArray *)messageComponents;
- (void)_handleSetFrameGrabRateMessage:(NSArray *)messageComponents;
- (void)_handleStartVideoDisplayMessage;
- (void)_handleStopVideoDisplayMessage;
- (void)_handleStartTransmittingMessage:(NSArray *)messageComponents;
- (void)_handleStopTransmittingMessage:(NSArray *)messageComponents;
- (void)_handleUpdatePictureMessage;
- (void)_handleSetMaxBitrateMessage:(NSArray *)messageComponents;
- (void)_handleSetVideoBytesSentMessage:(NSArray *)messageComponents;
- (void)_handleStartRecordingMessage:(NSArray *)messageComponents;
- (void)_handleStopRecordingMessage;

- (void)_handleSendSettingsToModuleMessage:(NSArray *)messageComponents;

- (void)_updateGrabStatus;
- (void)_grabFrame:(NSTimer *)timer;

- (void)_updateDeviceListAndSelectDummy;

- (unsigned)_adjustVideoBitrateLimit:(unsigned)bitrateLimit forCodec:(CodecType)codecType;

- (void)_startCompressionSession;
- (void)_stopCompressionSession;
- (void)_compressionSessionCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp;

- (void)_startCompressSequence;
- (void)_stopCompressSequence;
- (void)_restartCompressSequence;
- (void)_compressSequenceCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp;

- (OSStatus)_packetizeCompressedFrame:(UInt8 *)data 
                               length:(UInt32)dataLength
                     imageDescription:(ImageDescriptionHandle)imageDesc 
                            timeStamp:(UInt32)timeStamp;
@end

@interface XMVideoInputModuleWrapper : NSObject <XMVideoModule> {

  id<XMVideoInputModule> videoInputModule;
  NSArray *devices;
  BOOL isEnabled;
}

- (id)_initWithVideoInputModule:(id<XMVideoInputModule>)videoInputModule;

- (id<XMVideoInputModule>)_videoInputModule;

- (NSArray *)_devices;
- (void)_setDevices:(NSArray *)devices;

- (BOOL)_hasSettingsForDevice:(NSString *)device;
- (NSView *)_settingsViewForDevice:(NSString *)device;
- (void)_setDefaultSettingsForDevice:(NSString *)device;

@end

OSStatus XMPacketizeCompressedFrameProc(void*                     encodedFrameOutputRefCon, 
                                        ICMCompressionSessionRef	session, 
                                        OSStatus                  err,
                                        ICMEncodedFrameRef        encodedFrame,
                                        void*                     reserved);

void XMPacketizerDataReleaseProc(UInt8 *inData, void *inRefCon);

void XMMediaTransmitterPixelBufferReleaseCallback(void *releaseRefCon, const void *baseAddress);
UInt32 *_XMCreateColorLookupTable(CGDirectPaletteRef palette);

void _XMAdjustH261Data(UInt8 *data, BOOL isINTRAFrame, UInt32 timestamp);
void _XMAdjustH263Data(UInt8 *data, BOOL isINTRAFrame, UInt32 timestamp);
BOOL _XMIsH263IFrame(UInt8* data);

#pragma mark -

@implementation XMMediaTransmitter

#pragma mark -
#pragma mark Class Methods

+ (void)_getDeviceList
{
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_GetDeviceList withComponents:nil];
}

+ (void)_selectModule:(unsigned)moduleIndex device:(NSString *)device
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:moduleIndex];
  NSData *moduleData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSData *deviceData = [NSKeyedArchiver archivedDataWithRootObject:device];
	
  NSArray *components = [[NSArray alloc] initWithObjects:moduleData, deviceData, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetDevice withComponents:components];
	
  [components release];
}

+ (void)_setFrameGrabRate:(unsigned)frameGrabRate
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:frameGrabRate];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
  NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetFrameGrabRate withComponents:components];

  [components release];
}

+ (void)_startVideoDisplay
{
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StartVideoDisplay withComponents:nil];
}

+ (void)_stopVideoDisplay
{
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StopVideoDisplay withComponents:nil];
}

+ (void)_startTransmittingForSession:(unsigned)sessionID
                           withCodec:(XMCodecIdentifier)codecIdentifier
                           videoSize:(XMVideoSize)videoSize 
                  maxFramesPerSecond:(unsigned)maxFramesPerSecond
                          maxBitrate:(unsigned)maxBitrate
                    keyframeInterval:(unsigned)theKeyframeInterval
                               flags:(unsigned)flags
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:sessionID];
  NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:codecIdentifier];
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:videoSize];
  NSData *sizeData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:maxFramesPerSecond];
  NSData *framesData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:maxBitrate];
  NSData *bitrateData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:theKeyframeInterval];
  NSData *keyframeData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:flags];
  NSData *flagsData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSArray *components = [[NSArray alloc] initWithObjects:sessionData, codecData, sizeData, framesData,
                            bitrateData, keyframeData, flagsData, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StartTransmitting withComponents:components];
	
  [components release];
}

+ (void)_stopTransmittingForSession:(unsigned)sessionID
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:sessionID];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSArray *components = [[NSArray alloc] initWithObjects:data, nil];

  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StopTransmitting withComponents:components];
	
  [components release];
}

+ (void)_updatePicture
{
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_UpdatePicture withComponents:nil];
}

+ (void)_setMaxBitrate:(unsigned)bitrate
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:bitrate];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetMaxBitrate withComponents:components];
	
  [components release];
}

+ (void)_setVideoBytesSent:(unsigned)videoBytesSent
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:videoBytesSent];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSArray *components = [[NSArray alloc] initWithObjects:data, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SetVideoBytesSent withComponents:components];
	
  [components release];
}

+ (void)_startRecordingWithCodec:(XMCodecIdentifier)codecIdentifier
                       videoSize:(XMVideoSize)videoSize
                    codecQuality:(XMCodecQuality)codecQuality
                      maxBitrate:(unsigned)maxBitrate
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:codecIdentifier];
  NSData *codecData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:videoSize];
  NSData *sizeData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:codecQuality];
  NSData *qualityData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  number = [[NSNumber alloc] initWithUnsignedInt:maxBitrate];
  NSData *bitrateData = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSArray *components = [[NSArray alloc] initWithObjects:codecData, sizeData, qualityData, bitrateData, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StartRecording withComponents:components];
	
  [components release];
}

+ (void)_stopRecording
{
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_StopRecording withComponents:nil];
}

+ (void)_sendSettings:(NSData *)settings toModule:(id<XMVideoInputModule>)module
{
  NSNumber *number = [[NSNumber alloc] initWithUnsignedInt:(unsigned)module];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:number];
  [number release];
	
  NSArray *components = [[NSArray alloc] initWithObjects:data, settings, nil];
	
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_SendSettingsToModule withComponents:components];
	
  [components release];
}

+ (void)_sendMessage:(XMMediaTransmitterMessage)message withComponents:(NSArray *)components
{
  if (_XMMediaTransmitterSharedInstance == nil) {
    NSLog(@"Attempt to access XMMediaTransmitter prior to initialization");
    return;
  }
  NSPort *thePort = [_XMMediaTransmitterSharedInstance _receivePort];
  NSPortMessage *portMessage = [[NSPortMessage alloc] initWithSendPort:thePort receivePort:nil components:components];
  [portMessage setMsgid:(unsigned)message];
  if ([portMessage sendBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]] == NO) {
    NSLog(@"Sending the message failed: %x", message);
  }
  [portMessage release];
}

#pragma mark -
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
	
  receivePort = [[NSPort port] retain];
	
  XMSequenceGrabberVideoInputModule *seqGrabModule = [[XMSequenceGrabberVideoInputModule alloc] _init];
  XMStillImageVideoInputModule *stillImageModule = [[XMStillImageVideoInputModule alloc] _init];
  XMScreenVideoInputModule *screenModule = [[XMScreenVideoInputModule alloc] _init];
  XMDummyVideoInputModule *dummyModule = [[XMDummyVideoInputModule alloc] _init];
	
  XMVideoInputModuleWrapper *seqGrabWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:seqGrabModule];
  XMVideoInputModuleWrapper *stillImageWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:stillImageModule];
  XMVideoInputModuleWrapper *screenWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:screenModule];
  XMVideoInputModuleWrapper *dummyWrapper = [[XMVideoInputModuleWrapper alloc] _initWithVideoInputModule:dummyModule];
		
  videoInputModules = [[NSArray alloc] initWithObjects:seqGrabWrapper, stillImageWrapper, screenWrapper, dummyWrapper, nil];
	
  [seqGrabModule release];
  [stillImageModule release];
  [screenModule release];
  [dummyModule release];
	
  [seqGrabWrapper release];
  [stillImageWrapper release];
  [screenWrapper release];
  [dummyWrapper release];
	
  activeModule = nil;
  selectedDevice = nil;
    
  isGrabbing = NO;
  frameGrabTimer = nil;
  previewFrameGrabRate = 30;
  frameGrabRate = 30;
    
  isDoingVideoDisplay = NO;
	
  isTransmitting = NO;
  transmitFrameGrabRate = UINT_MAX;
  videoSize = XMVideoSize_CIF;
  codecType = 0;
  codecSpecificCallFlags = 0;
  bitrateToUse = 0;
	
  isRecording = NO;
  recordingSize = XMVideoSize_CIF;
  recordingCodec = 0;
  recordingQuality = XMCodecQuality_Max;
  recordingBitrate = 0;
	
  needsPictureUpdate = NO;
	
  useCompressionSessionAPI = NO;
  compressor = NULL;
	
  previousTimeStamp = 0;
  firstTime.tv_sec = 0;
  firstTime.tv_usec = 0;
	
  compressionSession = NULL;
  compressionFrameOptions = NULL;
  compressionSessionPreviousTimeStamp = 0;
	
  compressSequenceIsActive = NO;
  compressSequence = 0;
  compressSequenceImageDescription = NULL;
  compressSequenceCompressedFrame = NULL;
  compressSequenceFrameCounter = 0;
  compressSequenceLastVideoBytesSent = 0;
  compressSequenceNonKeyFrameCounter = 0;
  dataRateUpdateTime.tv_sec = 0;
  dataRateUpdateTime.tv_usec = 0;
	
  mediaPacketizer = NULL;
	
  return self;
}

- (void)_close
{
  [XMMediaTransmitter _sendMessage:_XMMediaTransmitterMessage_Shutdown withComponents:nil];
}

- (void)dealloc
{
  [videoInputModules release];
	
  [receivePort release];
	
  [super dealloc];
}

#pragma mark -
#pragma mark MainThread methods

- (NSPort *)_receivePort
{
  return receivePort;
}

- (void)_setDevice:(NSString *)deviceToSelect
{
  unsigned count = [videoInputModules count];
  for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		
    NSArray *inputDevices = [moduleWrapper _devices];
		
    unsigned inputDeviceCount = [inputDevices count];
    for (unsigned j = 0; j < inputDeviceCount; j++) {
      NSString *device = (NSString *)[inputDevices objectAtIndex:j];
      if ([device isEqualToString:deviceToSelect]) {
        [XMMediaTransmitter _selectModule:i device:device];
        return;
      }
    }
  }
	
  // If the desired device isn't found, select the dummy device
  [XMMediaTransmitter _selectModule:(count-1) device:0];
}

- (BOOL)_deviceHasSettings:(NSString *)device
{
  XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
  if (moduleWrapper != nil) {
    return [moduleWrapper _hasSettingsForDevice:device];
  }
	
  return NO;
}

- (BOOL)_requiresSettingsDialogWhenDeviceIsSelected:(NSString *)device
{
  XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
  if (moduleWrapper != nil) {
    return [[moduleWrapper _videoInputModule] requiresSettingsDialogWhenDeviceOpens:device];
  }
	
  return NO;
}

- (NSView *)_settingsViewForDevice:(NSString *)device
{
  XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
  if (moduleWrapper != nil) {
    return [moduleWrapper _settingsViewForDevice:device];
  }
	
  return nil;
}

- (void)_setDefaultSettingsForDevice:(NSString *)device
{
  XMVideoInputModuleWrapper *moduleWrapper = [self _wrapperForDevice:device];
	
  if (moduleWrapper != nil) {
    [moduleWrapper _setDefaultSettingsForDevice:device];
  }
}

- (unsigned)_videoModuleCount
{
  // not returning the dummy device
  unsigned count = [videoInputModules count];
	return (count-1);
}

- (id<XMVideoModule>)_videoModuleAtIndex:(unsigned)index
{
  unsigned count = [videoInputModules count];
  if (index == (count-1)) {
    return nil;
  }
	
  return [videoInputModules objectAtIndex:index];
}

- (XMVideoInputModuleWrapper *)_wrapperForDevice:(NSString *)device
{
	unsigned count = [videoInputModules count];
	for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		
    if ([[moduleWrapper _devices] containsObject:device]) {
      return moduleWrapper;
    }
  }
	
  return nil;
}

- (void)_sendDeviceList
{	
  NSMutableArray *devices = [[NSMutableArray alloc] initWithCapacity:5];
  
  unsigned count = [videoInputModules count];
  for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
		
    if ([moduleWrapper isEnabled] == YES) {
      NSArray *inputDevices = [moduleWrapper _devices];
			
      if (inputDevices == nil) {
        return;
      }
      [devices addObjectsFromArray:inputDevices];
    }
  }
	
  NSString *device = [_XMVideoManagerSharedInstance selectedInputDevice];
	
  [_XMVideoManagerSharedInstance _handleDeviceList:devices];
	
  if (device != nil && ![devices containsObject:device]) {
    unsigned dummyIndex = [videoInputModules count] - 1;
    XMVideoInputModuleWrapper *dummyWrapper = [videoInputModules objectAtIndex:dummyIndex];
    [XMMediaTransmitter _selectModule:dummyIndex device:[[dummyWrapper _devices] objectAtIndex:0]];
  }
	
  [devices release];
}

- (void)_handleErrorReport:(NSArray *)report
{	
  NSNumber *indexNumber = [report objectAtIndex:0];
  NSNumber *errorNumber = [report objectAtIndex:1];
  NSNumber *hintNumber = [report objectAtIndex:2];
  NSString *device = [report objectAtIndex:3];
	
  unsigned index = [indexNumber unsignedIntValue];
  int errorCode = [errorNumber intValue];
  int hintCode = [hintNumber intValue];
	
  id<XMVideoInputModule> module = [(XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:index] _videoInputModule];
  NSString *description = [module descriptionForErrorCode:errorCode hintCode:hintCode device:device];
	
  [_XMVideoManagerSharedInstance _handleErrorDescription:description];
}

- (void)_handleMediaTransmitterThreadDidExit
{
  _XMThreadExit();
}

#pragma mark -
#pragma mark MediaTransmitterThread methods

- (void)_runMediaTransmitterThread
{	
  // Use a higher thread priority
  BOOL result = [NSThread setThreadPriority:0.8];
  if (result == NO) {
    _XMLogMessage("Could not adjust media transmitter thread priority");
  }
	
  EnterMoviesOnThread(kQTEnterMoviesFlagDontSetComponentsThreadMode);
  XMRegisterPacketBuilder();
  XMRegisterRTPH263Packetizer();
  XMRegisterRTPH263PlusPacketizer();
  XMRegisterRTPH264Packetizer();
	
  [receivePort setDelegate:self];
  [[NSRunLoop currentRunLoop] addPort:receivePort forMode:NSDefaultRunLoopMode];
	
  // initializing all modules
  unsigned count = [videoInputModules count];
	for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
    id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
		
    [module setupWithInputManager:self];
    NSArray *inputDevices = [module inputDevices];
		
    [moduleWrapper performSelectorOnMainThread:@selector(_setDevices:) withObject:inputDevices waitUntilDone:NO];
		
    // initially selecting the dummy device
    if (i == (count-1)) {
      activeModule = module;
      selectedDevice = (NSString *)[inputDevices objectAtIndex:0];
      [selectedDevice retain];
    }
  }

  [self performSelectorOnMainThread:@selector(_sendDeviceList) withObject:nil waitUntilDone:NO];
	
  // running the run loop
  [[NSRunLoop currentRunLoop] run];
	
  // Due to the problem that this run loop will never exit at the moment,
  // the associated thread is killed after having cleaned up
}

- (BOOL)_isTransmitting
{
  return isTransmitting;
}

- (BOOL)_isRecording
{
  return isRecording;
}

#pragma mark Message handling methods

- (void)handlePortMessage:(NSPortMessage *)portMessage
{
  XMMediaTransmitterMessage message = (XMMediaTransmitterMessage)[portMessage msgid];
	
  switch (message) {
    case _XMMediaTransmitterMessage_Shutdown:
      [self _handleShutdownMessage];
      break;
    case _XMMediaTransmitterMessage_GetDeviceList:
      [self _handleGetDeviceListMessage];
      break;
    case _XMMediaTransmitterMessage_SetDevice:
      [self _handleSetDeviceMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_SetFrameGrabRate:
      [self _handleSetFrameGrabRateMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_StartVideoDisplay:
      [self _handleStartVideoDisplayMessage];
      break;
    case _XMMediaTransmitterMessage_StopVideoDisplay:
      [self _handleStopVideoDisplayMessage];
      break;
    case _XMMediaTransmitterMessage_StartTransmitting:
      [self _handleStartTransmittingMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_StopTransmitting:
      [self _handleStopTransmittingMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_UpdatePicture:
      [self _handleUpdatePictureMessage];
      break;
    case _XMMediaTransmitterMessage_SetMaxBitrate:
      [self _handleSetMaxBitrateMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_SetVideoBytesSent:
      [self _handleSetVideoBytesSentMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_StartRecording:
      [self _handleStartRecordingMessage:[portMessage components]];
      break;
    case _XMMediaTransmitterMessage_StopRecording:
      [self _handleStopRecordingMessage];
      break;
    case _XMMediaTransmitterMessage_SendSettingsToModule:
      [self _handleSendSettingsToModuleMessage:[portMessage components]];
      break;
    default:
      // ignore it
      break;
  }
}

- (void)_handleShutdownMessage
{
  [self _handleStopTransmittingMessage:nil];
  [self _handleStopRecordingMessage];
  [self _handleStopVideoDisplayMessage];
	
  unsigned count = [videoInputModules count];
	for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
    id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
    [module close];
  }
	
  // exiting from the run loop
  [[NSRunLoop currentRunLoop] removePort:receivePort forMode:NSDefaultRunLoopMode];
	
  // Since the run loop wil not exit as long as QuickTime is enabled, we have
  // to kill the thread "by hand"
  ExitMoviesOnThread();
	
  [self performSelectorOnMainThread:@selector(_handleMediaTransmitterThreadDidExit) withObject:nil waitUntilDone:NO];
	
  [NSThread exit];
}

- (void)_handleGetDeviceListMessage
{
  unsigned count = [videoInputModules count];
  for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
    id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
		
    NSArray *devices = [module inputDevices];
    [moduleWrapper performSelectorOnMainThread:@selector(_setDevices:) withObject:devices waitUntilDone:NO];
  }
	
  [self performSelectorOnMainThread:@selector(_sendDeviceList) withObject:nil waitUntilDone:NO];
}

- (void)_handleSetDeviceMessage:(NSArray *)messageComponents
{
  NSData *data = [messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  unsigned moduleIndex = [number unsignedIntValue];
	
  data = [messageComponents objectAtIndex:1];
  NSString *device = (NSString *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	
  XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:moduleIndex];
  id<XMVideoInputModule> module = [moduleWrapper _videoInputModule];
	
  [selectedDevice release];
  selectedDevice = [device retain];
	
  BOOL didSucceed = YES;
	
  if (isGrabbing == YES) {
    [activeModule closeInputDevice];
		
    if (module != activeModule) {
      activeModule = module;
			
      if (![module setInputFrameSize:videoSize]) {
        NSLog(@"Error with setInputFrameSize (2)");
      }
      [module setFrameGrabRate:frameGrabRate];
    }
		
    didSucceed = [module openInputDevice:device];
  } else {
    activeModule = module;
  }
	
  if (didSucceed == YES) {
		
    if (isTransmitting == YES) {
      if (useCompressionSessionAPI == NO) {
        [self _restartCompressSequence];
      }
    }
		
    NSArray *info = [[NSArray alloc] initWithObjects:selectedDevice, moduleWrapper, nil];
    [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
                                                    withObject:info waitUntilDone:NO];
    [info release];
  } else {
    activeModule = nil;
    [selectedDevice release];
    selectedDevice = nil;
	
    //The device could not be opened.
    // We now 1) refresh the device list and 2) select the last module's only device
    // which happens to be the dummy module/device
    [self _updateDeviceListAndSelectDummy];
  }
}

- (void)_handleSetFrameGrabRateMessage:(NSArray *)messageComponents
{
  NSData *data = [messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  previewFrameGrabRate = [number unsignedIntValue];
	
  if (isTransmitting == NO) {
    frameGrabRate = previewFrameGrabRate;
  }
	
  [activeModule setFrameGrabRate:frameGrabRate];
}

- (void)_handleStartVideoDisplayMessage
{
  if (isDoingVideoDisplay == YES) {
    return;
  }
    
  isDoingVideoDisplay = YES;
    
  [self _updateGrabStatus];
    
  NSArray *info = [[NSArray alloc] initWithObjects:selectedDevice, [NSNull null], nil];
  [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
                                                  withObject:info waitUntilDone:NO];
  [info release];
}

- (void)_handleStopVideoDisplayMessage
{
  if (isDoingVideoDisplay == NO) {
    return;
  }
    
  isDoingVideoDisplay = NO;
    
  [self _updateGrabStatus];
}

- (void)_handleStartTransmittingMessage:(NSArray *)components
{
  if (isTransmitting == YES) {
    return;
  }
	
  if (isRecording == YES) {
    // stop the already running compression session to
    // create a fresh instance with different codec
    // parameters
    [self _stopCompressionSession];
  }
	
  XMCodecIdentifier codecIdentifier;
  XMVideoSize requiredVideoSize;
	
  NSData *data = (NSData *)[components objectAtIndex:1];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  codecIdentifier = [number unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:2];
  NSNumber *videoSizeNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  requiredVideoSize = (XMVideoSize)[videoSizeNumber unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:3];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  transmitFrameGrabRate = [number unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:4];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  bitrateToUse = [number unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:5];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  keyframeInterval = [number unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:6];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  codecSpecificCallFlags = [number unsignedIntValue];
	
  // ensuring correct keyframe interval
  if (keyframeInterval > 200) {
    keyframeInterval = 200;
  }
	
  switch(codecIdentifier) {
    case XMCodecIdentifier_H261:
      codecType = kH261CodecType;
      codecManufacturer = 'appl';
      useCompressionSessionAPI = NO;
      break;
    case XMCodecIdentifier_H263:
      codecType = kH263CodecType;
      codecManufacturer = 'surf';
      useCompressionSessionAPI = NO;
      break;
    case XMCodecIdentifier_H264:
      codecType = kH264CodecType;
      codecManufacturer = 'appl';
      useCompressionSessionAPI = YES;
      break;
    default:
      codecType = 0;
      // no valid codec means an error
      // should be reported here
      return;
  }
      
  bitrateToUse = [self _adjustVideoBitrateLimit:bitrateToUse forCodec:codecType];
	
  if (videoSize != requiredVideoSize) {
    videoSize = requiredVideoSize;
		
    if (isGrabbing == YES) {
      BOOL result = [activeModule setInputFrameSize:requiredVideoSize];
      if (result == NO) {
        NSLog(@"Error with setInputFrameSize (1)");
      }
    }
  }
	
  // check if the frameGrabRate needs to be adjusted
  if ((transmitFrameGrabRate < frameGrabRate) && (isGrabbing == YES)) {
    frameGrabRate = transmitFrameGrabRate;
    [activeModule setFrameGrabRate:transmitFrameGrabRate];
  }
	
  isTransmitting = YES;
	
  // Ensure that we're indeed grabbing frames
  [self _updateGrabStatus];
	
  if (useCompressionSessionAPI == YES) {
    [self _startCompressionSession];
  } else {
    [self _startCompressSequence];
  }
	
  previousTimeStamp = 0;
	
  transmitFrameCounter = 0;
	
  [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoTransmittingStart:)
                                                  withObject:videoSizeNumber waitUntilDone:NO];
}

- (void)_handleStopTransmittingMessage:(NSArray *)components
{
  if (isTransmitting == NO) {
    return;
  }
	
  if (useCompressionSessionAPI == YES) {
    [self _stopCompressionSession];
  } else {
    [self _stopCompressSequence];
  }
	
  if (mediaPacketizer != NULL) {
    CloseComponent(mediaPacketizer);
    mediaPacketizer = NULL;
  }
	
  RTPMPDataReleaseUPP dataReleaseProc = sampleData.releaseProc;
  if (dataReleaseProc != NULL) {
    DisposeRTPMPDataReleaseUPP(dataReleaseProc);
    sampleData.releaseProc = NULL;
  }
	
  if (transmitFrameGrabRate < frameGrabRate) {
    [activeModule setFrameGrabRate:frameGrabRate];
  }
	
  transmitFrameGrabRate = UINT_MAX;
	
  _XMDidStopTransmitting(2);
	
  isTransmitting = NO;
	
  frameGrabRate = previewFrameGrabRate;
	
  [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleVideoTransmittingEnd)
                                                  withObject:nil waitUntilDone:NO];
	
  if (isRecording == YES) {
    useCompressionSessionAPI = YES;
    [self _startCompressionSession];
  }
    
  [self _updateGrabStatus];
}

- (void)_handleUpdatePictureMessage
{
  needsPictureUpdate = YES;
}

- (void)_handleSetMaxBitrateMessage:(NSArray *)components
{
  NSData *data = (NSData *)[components objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  bitrateToUse = [number unsignedIntValue];

  bitrateToUse = [self _adjustVideoBitrateLimit:bitrateToUse forCodec:codecType];
}

- (void)_handleSetVideoBytesSentMessage:(NSArray *)components
{
  if (compressSequence != 0) {
    NSData *data = (NSData *)[components objectAtIndex:0];
    NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    unsigned videoBytesSent = [number unsignedIntValue];
		
    long currentDataRate = (videoBytesSent - compressSequenceLastVideoBytesSent);
    long dataRateWanted = (bitrateToUse / 8);
    long overrun = currentDataRate - dataRateWanted;
		
    // avoid division by zero
    if (compressSequenceFrameCounter == 0) {
      compressSequenceFrameCounter = 1;
    }
		
    struct timeval time;
    gettimeofday(&time, NULL);
    unsigned timeElapsed = 1000 * (time.tv_sec - dataRateUpdateTime.tv_sec);
    timeElapsed += (time.tv_usec - dataRateUpdateTime.tv_usec) / 1000;
    dataRateUpdateTime = time;
		
    unsigned avgFrameDuration = (unsigned)((double)timeElapsed/(double)compressSequenceFrameCounter);
		
    DataRateParams dataRateParams;
    dataRateParams.dataRate = dataRateWanted;
    dataRateParams.dataOverrun = overrun;
    dataRateParams.frameDuration = avgFrameDuration;
    dataRateParams.keyFrameRate = 0;
    dataRateParams.minSpatialQuality = codecNormalQuality;
    dataRateParams.minTemporalQuality = codecNormalQuality;
		
    OSStatus err = noErr;
    err = SetCSequenceDataRateParams(compressSequence, &dataRateParams);
    if (err != noErr) {
      NSLog(@"Setting data rate contraints failed %d", err);
    }
		
    compressSequenceFrameCounter = 0;
    compressSequenceLastVideoBytesSent = videoBytesSent;
  }
}

- (void)_handleStartRecordingMessage:(NSArray *)components
{
  if (isRecording == YES) {
    return;
  }
	
  XMCodecIdentifier recordingCodecIdentifier;
  NSData *data = (NSData *)[components objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  recordingCodecIdentifier = [number unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:1];
  NSNumber *videoSizeNumber = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  recordingSize = (XMVideoSize)[videoSizeNumber unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:2];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  recordingQuality = (XMCodecQuality)[number unsignedIntValue];
	
  data = (NSData *)[components objectAtIndex:3];
  number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
  recordingBitrate = [number unsignedIntValue];
	
  switch (recordingCodecIdentifier) {
    case XMCodecIdentifier_H261:
      recordingCodec = kH261CodecType;
      break;
    case XMCodecIdentifier_H263:
      recordingCodec = kH263CodecType;
      break;
    case XMCodecIdentifier_H264:
      recordingCodec = kH264CodecType;
      break;
    case XMCodecIdentifier_MPEG4:
      recordingCodec = kMPEG4VisualCodecType;
      break;
    case XMCodecIdentifier_Motion_JPEG_A:
      recordingCodec = kMotionJPEGACodecType;
      break;
    case XMCodecIdentifier_Motion_JPEG_B:
      recordingCodec = kMotionJPEGBCodecType;
      break;
			
    default:
      recordingCodec = 0;
      // no valid codec means an error
      // should be reported here
      return;
  }
	
  isRecording = YES;
    
  [self _updateGrabStatus];
	
  if (isTransmitting == NO) {
    useCompressionSessionAPI = YES;
    [self _startCompressionSession];
  }
	
  needsPictureUpdate = YES; // make complete picture at the beginning of the recording
}

- (void)_handleStopRecordingMessage
{
  if (isRecording == NO) {
    return;
  }
	
  isRecording = NO;
    
  [self _updateGrabStatus];
	
  if (isTransmitting == NO) {
    [self _stopCompressionSession];
  }
	
  [_XMCallRecorderSharedInstance performSelectorOnMainThread:@selector(_handleLocalVideoRecordingDidEnd) withObject:nil waitUntilDone:NO];
}

- (void)_handleSendSettingsToModuleMessage:(NSArray *)messageComponents
{
  NSData *data = (NSData *)[messageComponents objectAtIndex:0];
  NSNumber *number = (NSNumber *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	
  id<XMVideoInputModule> module = (id<XMVideoInputModule>)[number unsignedIntValue];
	
  NSData *settings = (NSData *)[messageComponents objectAtIndex:1];
	
  [module applyInternalSettings:settings];
}

#pragma mark -
#pragma mark XMVideoInputManager Methods

- (void)handleGrabbedFrame:(CVPixelBufferRef)frame
{	
  // checking whether frame has correct dimensions
  unsigned width = CVPixelBufferGetWidth(frame);
  unsigned height = CVPixelBufferGetHeight(frame);
  NSSize desiredSize = XMVideoSizeToDimensions(videoSize);
	
  if ((unsigned)desiredSize.width != width || (unsigned)desiredSize.height != height) {
    [self _updateDeviceListAndSelectDummy];
    return;
  }
	
  // compress and transmit the frame if needed
  if (isTransmitting == YES || isRecording == YES) {
    TimeValue timeStamp;
		
    if (previousTimeStamp == 0) {
      gettimeofday(&firstTime, NULL);
      timeStamp = 3003;
    } else {
      struct timeval time;
			
      gettimeofday(&time, NULL);
			
      // calculating the time units passed in the 90khz clock.
      long units = (time.tv_sec - firstTime.tv_sec) * 90000;
      units += ((time.tv_usec - firstTime.tv_usec) * (90000.0 / 1000000.0));
			
      // rounding down to integer multiples of 3003 (29.97hz clock), 
      // increasing by 3003 since the first timestamp has value 3003.
      TimeValue calculatedTimeStamp = units - (units % 3003) + 3003;
			
      // make sure that the time stamp is strictly monotonically increasing
      if (calculatedTimeStamp <= previousTimeStamp) {
        timeStamp = previousTimeStamp + 3003;
				
        if (timeStamp - calculatedTimeStamp >= 3003) {
          return;
        }
      } else {
        timeStamp = calculatedTimeStamp;
      }
    }
		
    previousTimeStamp = timeStamp;

    // Sending a couple of I-Frames at the beginning of a stream
    // to allow proper picture build-up.
    if (transmitFrameCounter < 3 ||	// first three frames are I-frames
        (transmitFrameCounter < 120 && (transmitFrameCounter % 30) == 0))	{ // every 30th is an I-frame
      needsPictureUpdate = YES;
    }
			
    transmitFrameCounter++;
	
    if (useCompressionSessionAPI == YES) {
      [self _compressionSessionCompressFrame:frame timeStamp:timeStamp];
    }	else {
      [self _compressSequenceCompressFrame:frame timeStamp:timeStamp];
    }
  }
	
  // handling the frame to the video manager to draw the preview image
  // on screen
  [_XMVideoManagerSharedInstance _handleLocalVideoFrame:frame];
}

- (void)noteSettingsDidChangeForModule:(id<XMVideoInputModule>)module
{
  NSString *theSelectedDevice = [_XMVideoManagerSharedInstance selectedInputDevice];
	
  unsigned count = [videoInputModules count];
  for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *moduleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
    if ([moduleWrapper _videoInputModule] == module) {
      if ([[moduleWrapper _devices] containsObject:theSelectedDevice]) {
        NSData *settings = [module internalSettings];
        [XMMediaTransmitter _sendSettings:settings toModule:module];
      }
      return;
    }
  }
}

- (void)handleErrorWithCode:(int)errorCode hintCode:(int)hintCode
{
  NSNumber *errorCodeNumber = [[NSNumber alloc] initWithInt:errorCode];
  NSNumber *hintCodeNumber = [[NSNumber alloc] initWithInt:hintCode];
	
  unsigned index = NSNotFound;
  unsigned count = [videoInputModules count];
  for (unsigned i = 0; i < count; i++) {
    XMVideoInputModuleWrapper *wrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:i];
    if ([wrapper _videoInputModule] == activeModule) {
      index = i;
      break;
    }
  }
	
  if (index == NSNotFound) {
    NSLog(@"ERROR: MODULE NOT FOUND");
  }
	
  NSNumber *indexNumber = [[NSNumber alloc] initWithUnsignedInt:index];
	
  NSArray *objects = [[NSArray alloc] initWithObjects:indexNumber, errorCodeNumber, hintCodeNumber, selectedDevice, nil];
	
  [self performSelectorOnMainThread:@selector(_handleErrorReport:) withObject:objects waitUntilDone:NO];
	
  [objects release];
  [indexNumber release];
  [errorCodeNumber release];
  [hintCodeNumber release];
}

#pragma mark -
#pragma mark Private Methods

- (void)_updateGrabStatus
{
  BOOL needsGrabbing = NO;
  if (isDoingVideoDisplay == YES || isTransmitting == YES || isRecording == YES) {
    needsGrabbing = YES;
  }
    
  if (needsGrabbing == isGrabbing) {
    return;
  }
      
  if (needsGrabbing == YES) {
    if (![activeModule setInputFrameSize:videoSize]) {
      activeModule = nil;
      [self _updateDeviceListAndSelectDummy];
    }
    [activeModule setFrameGrabRate:frameGrabRate];
        
    if (![activeModule openInputDevice:selectedDevice]) {
      activeModule = nil;
      [self _updateDeviceListAndSelectDummy];
    }
        
    isGrabbing = YES;
        
    // starting the timer and grabbing the first frame
        
    NSTimeInterval desiredTimeInterval = 1.0/frameGrabRate;
    frameGrabTimer = [[NSTimer scheduledTimerWithTimeInterval:desiredTimeInterval target:self 
                                                     selector:@selector(_grabFrame:) userInfo:nil
                                                      repeats:YES] retain];
    [self _grabFrame:nil];
  } else {
    isGrabbing = NO;
        
    if (![activeModule closeInputDevice]) {
      NSLog(@"Closing the device failed");
    }
        
    [frameGrabTimer invalidate];
    [frameGrabTimer release];
    frameGrabTimer = nil;
  }
}

- (void)_grabFrame:(NSTimer *)timer
{
  NSTimeInterval desiredTimeInterval = 1.0/frameGrabRate;
	
  // readjusting the timer interval if needed
  if ([frameGrabTimer timeInterval] != desiredTimeInterval) {
    [frameGrabTimer invalidate];
    [frameGrabTimer release];
		
    frameGrabTimer = [[NSTimer scheduledTimerWithTimeInterval:desiredTimeInterval target:self 
                                                     selector:@selector(_grabFrame:) userInfo:nil
                                                      repeats:YES] retain];
  }
	
  // calling the active module to grab a frame
  if (![activeModule grabFrame]) {
    // an error occured, we switch to the dummy device
    [self _updateDeviceListAndSelectDummy];
  }
}

- (void)_updateDeviceListAndSelectDummy
{
  if (activeModule != nil) {
    [activeModule closeInputDevice];
  }
	
  unsigned count = [videoInputModules count];
	
  XMVideoInputModuleWrapper *dummyModuleWrapper = (XMVideoInputModuleWrapper *)[videoInputModules objectAtIndex:(count-1)];
  activeModule = [dummyModuleWrapper _videoInputModule];
	
  selectedDevice = (NSString *)[[[activeModule inputDevices] objectAtIndex:0] retain];
	
  NSArray *info = [[NSArray alloc] initWithObjects:selectedDevice, dummyModuleWrapper, nil];
  [_XMVideoManagerSharedInstance performSelectorOnMainThread:@selector(_handleInputDeviceChangeComplete:)
                                                  withObject:info waitUntilDone:NO];
  [info release];
	
  // updating the device list
  [self _handleGetDeviceListMessage];
	
  [activeModule setInputFrameSize:videoSize];
  [activeModule setFrameGrabRate:frameGrabRate];  
  [activeModule openInputDevice:selectedDevice];
}

- (unsigned)_adjustVideoBitrateLimit:(unsigned)bitrate forCodec:(CodecType)codec
{	
  // protection against codec hangups
  if (bitrate < 80000 && codec == kH261CodecType) {
    bitrate = 80000;  
  } else if (bitrate < 64000 && codec == kH263CodecType) {
    bitrate = 64000;
  } else if (bitrate < 192000 && codec == kH264CodecType) {
    // H.264 seems not to use the whole bandwidth allowed, so we're increasing
    // the minimum bandwidth used
    bitrate = 192000;
  }
  return bitrate;
}

- (void)_startCompressionSession
{
  ComponentResult err = noErr;
  ICMEncodedFrameOutputRecord encodedFrameOutputRecord = {0};
  ICMCompressionSessionOptionsRef sessionOptions = NULL;
	
  err = ICMCompressionSessionOptionsCreate(NULL, &sessionOptions);
  if (err != noErr) {
    NSLog(@"ICMCompressionSessionOptionsCreate failed: %d", (int)err);
  }
	
  err = ICMCompressionSessionOptionsSetAllowTemporalCompression(sessionOptions, true);
  if (err != noErr) {
    NSLog(@"allowTemporalCompression failed: %d", (int)err);
  }
	
  err = ICMCompressionSessionOptionsSetAllowFrameReordering(sessionOptions, false);
  if (err != noErr) {
    NSLog(@"allow frame reordering failed: %d", (int)err);
  }	
	
  if (isTransmitting == YES) {
    err = ICMCompressionSessionOptionsSetMaxKeyFrameInterval(sessionOptions, keyframeInterval);
    if (err != noErr) {
      NSLog(@"set max keyFrameInterval failed: %d", (int)err);
    }
  }
	
  err = ICMCompressionSessionOptionsSetAllowFrameTimeChanges(sessionOptions, false);
  if (err != noErr) {
    NSLog(@"setAllowFrameTimeChanges failed: %d", (int)err);
  }
	
  err = ICMCompressionSessionOptionsSetDurationsNeeded(sessionOptions, true);
  if (err != noErr) {
    NSLog(@"SetDurationsNeeded failed: %d", (int)err);
  }
	
  // averageDataRate is in bytes/s
  SInt32 averageDataRate = bitrateToUse/8;
  if (isTransmitting == NO) {
    averageDataRate = recordingBitrate/8;
  }
  if (averageDataRate != 0) {
    err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
                                                  kQTPropertyClass_ICMCompressionSessionOptions,
                                                  kICMCompressionSessionOptionsPropertyID_AverageDataRate,
                                                  sizeof(averageDataRate),
                                                  &averageDataRate);
    if (err != noErr) {
      NSLog(@"SetAverageDataRate failed: %d", (int)err);
    }
  }
	
  SInt32 maxFrameDelayCount = 0;
  err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
                                                kQTPropertyClass_ICMCompressionSessionOptions,
                                                kICMCompressionSessionOptionsPropertyID_MaxFrameDelayCount,
                                                sizeof(maxFrameDelayCount),
                                                &maxFrameDelayCount);
  if (err != noErr) {
    NSLog(@"SetMaxFrameDelayCount failed: %d", (int)err);
  }
	
  CodecQ codecQuality = codecMaxQuality;
  if (isTransmitting == NO) {
    codecQuality = recordingQuality;
  }
  err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
                                                kQTPropertyClass_ICMCompressionSessionOptions,
                                                kICMCompressionSessionOptionsPropertyID_Quality,
                                                sizeof(codecQuality),
                                                &codecQuality);
  if (err != noErr) {
    NSLog(@"SetCodecQuality failed: %d", (int)err);
  }
	
  CodecType codecTypeToUse = codecType;
  OSType codecManufacturerToUse = codecManufacturer;
  if (isTransmitting == NO) {
    codecTypeToUse = recordingCodec;
    codecManufacturerToUse = 0;
  }
  ComponentDescription componentDescription;
  componentDescription.componentType = FOUR_CHAR_CODE('imco');
  componentDescription.componentSubType = codecTypeToUse;
  componentDescription.componentManufacturer = codecManufacturerToUse;
  componentDescription.componentFlags = 0;
  componentDescription.componentFlagsMask = 0;
	
  Component compressorComponent = FindNextComponent(0, &componentDescription);
  if (compressorComponent == NULL) {
    NSLog(@"No such compressor");
  }
	
  err = OpenAComponent(compressorComponent, &compressor);
  if (err != noErr) {
    NSLog(@"Opening the component failed");
  }
	
  if (codecType == FOUR_CHAR_CODE('avc1') && isTransmitting == YES) {
    // Profile is currently fixed to Baseline
    // The level is adjusted by the use of the bitrate, but the SPS returned reveals
    // level 1.1 in case of QCIF and level 1.3 in case of CIF
		
    Handle h264Settings = NewHandleClear(0);
		
    err = ImageCodecGetSettings(compressor, h264Settings);
    if (err != noErr) {
      NSLog(@"ImageCodecGetSettings failed");
    }
		
    // For some reason, the QTAtomContainer functions will crash if used on the atom
    // container returned by ImageCodecGetSettings.
    // Therefore, we have to parse the atoms self to set the correct settings.
    unsigned settingsSize = GetHandleSize(h264Settings) / 4;
    UInt32 *data = (UInt32 *)*h264Settings;
    for (unsigned i = 0; i < settingsSize; i++) {
      
			// Forcing Baseline profile
#if defined(__BIG_ENDIAN__)
      if (data[i] == FOUR_CHAR_CODE('sprf')) {
        i+=4;
        data[i] = 1;
      }
#else
      if (data[i] == FOUR_CHAR_CODE('frps')) {
        i+=4;
        data[i] = CFSwapInt32(1);
      }
#endif
			
      // if video sent is CIF size, we set this flag to one to have the picture
      // encoded in 5 slices instead of two.
      // If QCIF is sent, this flag remains zero to send two slices instead of
      // one.
#if defined(__BIG_ENDIAN__)
      else if (videoSize == XMVideoSize_CIF && data[i] == FOUR_CHAR_CODE('susg')) {
        i+=4;
        data[i] = 1;
      }
#else
      else if (videoSize == XMVideoSize_CIF && data[i] == FOUR_CHAR_CODE('gsus')) {
        i+=4;
        data[i] = CFSwapInt32(1);
      }
#endif
    }
		
    err = ImageCodecSetSettings(compressor, h264Settings);
    if (err != noErr) {
      NSLog(@"ImageCodecSetSettings failed");
    }
  }
	
  err = ICMCompressionSessionOptionsSetProperty(sessionOptions,
                                                kQTPropertyClass_ICMCompressionSessionOptions,
                                                kICMCompressionSessionOptionsPropertyID_CompressorComponent,
                                                sizeof(compressor),
                                                &compressor);
  if (err != noErr) {
    NSLog(@"No such codec found");
  }
	
  encodedFrameOutputRecord.encodedFrameOutputCallback = XMPacketizeCompressedFrameProc;
  encodedFrameOutputRecord.encodedFrameOutputRefCon = (void *)self;
  encodedFrameOutputRecord.frameDataAllocator = NULL;
	
  XMVideoSize theVideoSize = videoSize;
  if (isTransmitting == NO) {
    theVideoSize = recordingSize;
  }
  NSSize frameDimensions = XMVideoSizeToDimensions(theVideoSize);
  err = ICMCompressionSessionCreate(NULL, frameDimensions.width, frameDimensions.height, codecTypeToUse,
                                    (TimeScale)90000, sessionOptions, NULL, &encodedFrameOutputRecord,
                                    &compressionSession);
  if (err != noErr) {
    NSLog(@"ICMCompressionSessionCreate failed: %d", (int)err);
  }
	
  ICMCompressionSessionOptionsRelease(sessionOptions);
	
  err = ICMCompressionFrameOptionsCreate(NULL, compressionSession, &compressionFrameOptions);
  if (err != noErr) {
    NSLog(@"ICMCompressionFrameOptionsCreate failed %d", (int)err);
  }
	
  compressionSessionPreviousTimeStamp = 0;
}

- (void)_stopCompressionSession
{
  if (compressionFrameOptions != NULL) {
    ICMCompressionFrameOptionsRelease(compressionFrameOptions);
    compressionFrameOptions = NULL;
  }
	
  if (compressionSession != NULL) {
    ICMCompressionSessionRelease(compressionSession);
    compressionSession = NULL;
  }
	
  if (compressor != NULL) {
    CloseComponent(compressor);
    compressor = NULL;
  }
}

- (void)_compressionSessionCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp
{
  if (compressionSession != NULL) {
    OSErr err = noErr;
    
    err = ICMCompressionFrameOptionsSetForceKeyFrame(compressionFrameOptions, needsPictureUpdate);
    if (err != noErr) {
      NSLog(@"ICMCompressionFrameOptionsSetForceKeyFrame failed %d", (int)err);
    }
		
    TimeValue frameDuration = timeStamp - compressionSessionPreviousTimeStamp;
		
    err = ICMCompressionSessionEncodeFrame(compressionSession, 
                                           frame,
                                           timeStamp, 
                                           frameDuration, 
                                           kICMValidTime_DisplayTimeStampIsValid | kICMValidTime_DisplayDurationIsValid,
                                           compressionFrameOptions, 
                                           NULL, 
                                           NULL);
    if (err != noErr) {
      NSLog(@"ICMCompressionSessionEncodeFrame failed %d", (int)err);
    }
		
    compressionSessionPreviousTimeStamp = timeStamp;
		
    needsPictureUpdate = NO;
  }
}

- (void)_startCompressSequence
{
  // Since the CompressSequence API needs a PixMap to be
  // present when callling CompressSequenceBegin,
  // this task is deferred to _compressSequenceCompressFrame:timeStamp:
  compressSequenceFrameNumber = 0;
  compressSequenceIsActive = YES;
}

- (void)_stopCompressSequence
{
  if (compressSequence != 0) {
    CDSequenceEnd(compressSequence);
    compressSequence = 0;
  }
	
  if (compressSequenceImageDescription != NULL) {
    DisposeHandle((Handle)compressSequenceImageDescription);
    compressSequenceImageDescription = NULL;
  }
	
  if (compressSequenceCompressedFrame != NULL) {
    DisposePtr(compressSequenceCompressedFrame);
    compressSequenceCompressedFrame = NULL;
  }
	
  if (compressor != NULL) {
    CloseComponent(compressor);
    compressor = NULL;
  }
	
  compressSequenceIsActive = NO;
}

- (void)_restartCompressSequence
{
  [self _stopCompressSequence];
  compressSequenceIsActive = YES;
}

- (void)_compressSequenceCompressFrame:(CVPixelBufferRef)frame timeStamp:(TimeValue)timeStamp
{
  if (compressSequenceIsActive == YES) {
    ComponentResult err = noErr;
		
    CVPixelBufferLockBaseAddress(frame, 0);
    UInt32 width = CVPixelBufferGetWidth(frame);
    UInt32 height = CVPixelBufferGetHeight(frame);
		
    PixMap pixMap;
    PixMapPtr pixMapPtr;
    PixMapHandle pixMapHandle;
    Rect dstRect;
		
    pixMap.baseAddr = CVPixelBufferGetBaseAddress(frame);
    pixMap.rowBytes = 0x8000;
    pixMap.rowBytes |= (CVPixelBufferGetBytesPerRow(frame) & 0x3fff);
    pixMap.bounds.top = 0;
    pixMap.bounds.left = 0;
    pixMap.bounds.bottom = height;
    pixMap.bounds.right = width;
    pixMap.pmVersion = 0;
    pixMap.packType = 0;
    pixMap.packSize = 0;
    pixMap.hRes = Long2Fix(72);
    pixMap.vRes = Long2Fix(72);
    pixMap.pixelType = 16;
    pixMap.pixelSize = 32;
    pixMap.cmpCount = 4;
    pixMap.cmpSize = 8;
    pixMap.pixelFormat = CVPixelBufferGetPixelFormatType(frame);
    pixMap.pmTable = NULL;
    pixMap.pmExt = NULL;
		
    pixMapPtr = &pixMap;
    pixMapHandle = &pixMapPtr;
    dstRect.top = 0;
    dstRect.left = 0;
    dstRect.bottom = height;
    dstRect.right = width;
		
    // creating the compress sequence if needed
    if (compressSequence == 0) {
      ComponentDescription componentDescription;
      componentDescription.componentType = FOUR_CHAR_CODE('imco');
      componentDescription.componentSubType = codecType;
      componentDescription.componentManufacturer = codecManufacturer;
      componentDescription.componentFlags = 0;
      componentDescription.componentFlagsMask = 0;
			
      Component compressorComponent = FindNextComponent(0, &componentDescription);
      if (compressorComponent == NULL) {
        NSLog(@"No such compressor");
      }
			
      err = OpenAComponent(compressorComponent, &compressor);
      if (err != noErr) {
        NSLog(@"Opening the component failed");
      }
			
      compressSequenceImageDescription = (ImageDescriptionHandle)NewHandleClear(0);
			
      err = CompressSequenceBegin(&compressSequence,
                                  pixMapHandle,
                                  NULL,
                                  &dstRect,
                                  &dstRect,
                                  32,
                                  codecType,
                                  (CompressorComponent)compressor,
                                  codecHighQuality,
                                  codecHighQuality,
                                  0,
                                  NULL,
                                  0,
                                  compressSequenceImageDescription);
      if (err != noErr) {
        NSLog(@"CompressSequenceBegin failed: %d", err);
      }
			
      long maxCompressionSize;
      err = GetMaxCompressionSize(pixMapHandle,
                                  &dstRect,
                                  0,
                                  codecNormalQuality,
                                  codecType,
                                  (CompressorComponent)compressor,
                                  &maxCompressionSize);
			
      if (err != noErr) {
        NSLog(@"GetMaxCompressionSize failed: %d", err);
      }
			
      compressSequenceCompressedFrame = QTSNewPtr(maxCompressionSize, kQTSMemAllocHoldMemory, NULL);
			
      compressSequencePreviousTimeStamp = 0;
			
      DataRateParams dataRateParams;
      dataRateParams.dataRate = (bitrateToUse / 8);
      dataRateParams.dataOverrun = 0;
      dataRateParams.frameDuration = 30;
      dataRateParams.keyFrameRate = 0;
      dataRateParams.minSpatialQuality = codecNormalQuality;
      dataRateParams.minTemporalQuality = codecNormalQuality;
      err = SetCSequenceDataRateParams(compressSequence, &dataRateParams);
      if (err != noErr) {
        NSLog(@"Setting data rate contraints failed %d", err);
      }
			
      compressSequenceFrameCounter = 0;
      compressSequenceLastVideoBytesSent = 0;
      compressSequenceNonKeyFrameCounter = 0;
			
      gettimeofday(&dataRateUpdateTime, NULL);
    }
		
    CodecFlags compressionFlags = (codecFlagUpdatePreviousComp | codecFlagLiveGrab);
		
    // send and I-frame every keyframeInterval frames
    if (compressSequenceNonKeyFrameCounter == keyframeInterval || keyframeInterval == 0) {
      needsPictureUpdate = YES;
    }
		
    // picture update means to force a key frame
    // as well as setting the compressSequenceFrameNumber to zero
    // Only that way will an H.263 frame actually be encoded as an I-frame
    if (needsPictureUpdate == YES) {
      compressionFlags |= codecFlagForceKeyFrame;
      compressSequenceNonKeyFrameCounter = 0;
      compressSequenceFrameNumber = 0;
    } else {
      compressSequenceNonKeyFrameCounter++;
		
      // calculate the correct frame number
      UInt32 numberOfFramesInBetween = 1;
      if (compressSequencePreviousTimeStamp != 0) {
        numberOfFramesInBetween = (timeStamp - compressSequencePreviousTimeStamp) / 3003;
        compressSequenceFrameNumber += numberOfFramesInBetween;
      }
    }
		
    err = SetCSequenceFrameNumber(compressSequence, compressSequenceFrameNumber);
    if (err != noErr) {
      NSLog(@"SetFrameNumber failed %d", err);
    }
		
    compressSequencePreviousTimeStamp = timeStamp;
		
    long dataLength;
    err = CompressSequenceFrame(compressSequence,
                                pixMapHandle,
                                &dstRect,
                                compressionFlags,
                                compressSequenceCompressedFrame,
                                &dataLength,
                                NULL,
                                NULL);
    if (err != noErr) {
      NSLog(@"CompressSequenceFrame failed: %d", err);
      return;
    }
		
    UInt8 *compressedData = (UInt8 *)compressSequenceCompressedFrame;
		
    if (isTransmitting == YES) {
      [self _packetizeCompressedFrame:compressedData
                               length:dataLength
                     imageDescription:compressSequenceImageDescription
                            timeStamp:timeStamp];
    }
		
    if (isRecording == YES) {
      // record the frame if needed
      [_XMCallRecorderSharedInstance _handleCompressedLocalVideoFrame:compressedData
                                                               length:dataLength
                                                     imageDescription:compressSequenceImageDescription];
    }
		
    compressSequenceFrameCounter += 1;
		
    needsPictureUpdate = NO;
		
    CVPixelBufferUnlockBaseAddress(frame, 0);
  }
}

- (OSStatus)_packetizeCompressedFrame:(UInt8 *)data 
                               length:(UInt32)dataLength
                     imageDescription:(ImageDescriptionHandle)imageDesc 
                            timeStamp:(UInt32)timeStamp
{
  OSErr err = noErr;
	
  sampleData.flags = 0;
	
  if (mediaPacketizer == NULL) {
    OSType packetizerToUse;
		
    switch (codecType) {
      case kH261CodecType:
        packetizerToUse = kRTP261MediaPacketizerType;
        break;
      case kH263CodecType:
        if (codecSpecificCallFlags >= kRTPPayload_FirstDynamic) {
          packetizerToUse = kXMRTPH263PlusPacketizerType;
        } else {
          packetizerToUse = kXMRTPH263PacketizerType;
        }
        break;
      case kH264CodecType:
        packetizerToUse = kXMRTPH264PacketizerType;
        break;
      default:
        return qtsBadStateErr;
    }
		
    ComponentDescription componentDescription;
    componentDescription.componentType = kRTPMediaPacketizerType;
    componentDescription.componentSubType = packetizerToUse;
    componentDescription.componentManufacturer = 0;
    componentDescription.componentFlags = 0;
    componentDescription.componentFlagsMask = 0;
		
    Component component = FindNextComponent(0, &componentDescription);
    if (component == NULL) {
      NSLog(@"No Packetizer found");
    }
		
    err = OpenAComponent(component, &mediaPacketizer);
    if (err != noErr) {
      NSLog(@"Open packetizer failed: %d", (int)err);
    }
		
    err = RTPMPPreflightMedia(mediaPacketizer,
                              VideoMediaType,
                              (SampleDescriptionHandle)imageDesc);
    if (err != noErr) {
      NSLog(@"PreflightMedia failed: %d", (int)err);
    }
		
    SInt32 packetizerFlags = kRTPMPRealtimeModeFlag;
    if (codecType == kH264CodecType) {
      unsigned packetizationMode = (codecSpecificCallFlags >> 8) & 0xf;
      if (packetizationMode == 2) {
				packetizerFlags |= 2;
      }
    }
    err = RTPMPInitialize(mediaPacketizer, packetizerFlags);
    if (err != noErr) {
      NSLog(@"RTPMP initialize failed: %d", (int)err);
    }
		
    componentDescription.componentType = kXMPacketBuilderComponentType;
    componentDescription.componentSubType = kXMPacketBuilderComponentSubType;
    componentDescription.componentManufacturer = kXMPacketBuilderComponentManufacturer;
    componentDescription.componentFlags = 0;
    componentDescription.componentFlagsMask = 0;
		
    Component packetBuilderComponent = FindNextComponent(0, &componentDescription);
    ComponentInstance packetBuilder;
    err = OpenAComponent(packetBuilderComponent, &packetBuilder);
		
    err = RTPMPSetPacketBuilder(mediaPacketizer, packetBuilder);
    if (err != noErr) {
      NSLog(@"SetPacketBuilder failed: %d", (int)err);
    }
		
    err = RTPMPSetTimeBase(mediaPacketizer, NewTimeBase());
    if (err != noErr) {
      NSLog(@"SetTimeBase failed: %d", (int)err);
    }
		
    err = RTPMPSetTimeScale(mediaPacketizer, 90000);
    if (err != noErr) {
      NSLog(@"SetTimeScale failed: %d", (int)err);
    }
		
    // Preventing the packetizer from creating packets
    // greater than the ethernet packet size.
    err = RTPMPSetMaxPacketSize(mediaPacketizer, 1400);
    if (err != noErr) {
      NSLog(@"SetMaxPacketSize failed: %d", (int)err);
    }
		
    RTPMPDataReleaseUPP dataReleaseProc = NewRTPMPDataReleaseUPP(XMPacketizerDataReleaseProc);
    sampleData.version = 0;
    sampleData.timeStamp = 0;
    sampleData.duration = 0;
    sampleData.playOffset = 0;
    sampleData.playRate = fixed1;
    sampleData.flags = 0;
    sampleData.sampleDescSeed = 0;
    sampleData.sampleRef = 0;
    sampleData.releaseProc = dataReleaseProc;
    sampleData.refCon = (void *)self;
		
    if (codecType == kH264CodecType) {
      // The very first frame should include SPS / PPS atoms
      sampleData.flags = 1;
    }
  }
	
  if (needsPictureUpdate == YES && codecType == kH264CodecType) {
    sampleData.flags = 1;
  }
	
  sampleData.timeStamp = timeStamp;
  sampleData.sampleDescription = (Handle)imageDesc;
  sampleData.dataLength = dataLength;
	
  // Making H.261 stream standard compliant
  if (codecType == kH261CodecType) {
    _XMAdjustH261Data(data, needsPictureUpdate, timeStamp);
  } else if (codecType == kH263CodecType) {
    if (keyframeInterval == 0 && _XMIsH263IFrame(data) == NO) {
      // can't send non I-frame pictures at zero keyframe interval
      return noErr;
    }
    _XMAdjustH263Data(data, needsPictureUpdate, timeStamp);
  }
	
  sampleData.data = (const UInt8 *)data;
	
  SInt32 outFlags;
  err = RTPMPSetSampleData(mediaPacketizer, &sampleData, &outFlags);
  if (err != noErr) {
    NSLog(@"SetSampleData  failed %d", (int)err);
  }
  if (kRTPMPStillProcessingData & outFlags) {
    NSLog(@"Still processing data");
  }
	
  // should actually not happen at all!
  while(kRTPMPStillProcessingData & outFlags) {
    err = RTPMPIdle(mediaPacketizer, 0, &outFlags);
    if (err != noErr) {
      NSLog(@"RTPMPIdle failed %d", (int)err);
    }
  }
	
  return err;
}

@end

#pragma mark -

@implementation XMVideoInputModuleWrapper

#pragma mark -
#pragma mark Init & Deallocation Methods

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)_initWithVideoInputModule:(id<XMVideoInputModule>)theVideoInputModule
{
  videoInputModule = [theVideoInputModule retain];
  devices = nil;
  isEnabled = YES;
	
  return self;
}

- (void)dealloc
{
  [videoInputModule release];
  [devices release];
	
  [super dealloc];
}

#pragma mark -
#pragma mark Internal Methods

- (id<XMVideoInputModule>)_videoInputModule
{   
  return videoInputModule;
}

- (NSArray *)_devices
{
  return devices;
}

- (void)_setDevices:(NSArray *)theDevices
{
  NSArray *old = devices;
  devices = [theDevices retain];
  [old release];
}

- (BOOL)_hasSettingsForDevice:(NSString *)device
{
  return [videoInputModule hasSettingsForDevice:device];
}

- (NSView *)_settingsViewForDevice:(NSString *)device
{
  if ([videoInputModule hasSettingsForDevice:device] == NO) {
    return nil;
  }
	
  return [videoInputModule settingsViewForDevice:device];
}

- (void)_setDefaultSettingsForDevice:(NSString *)device
{
  if ([videoInputModule hasSettingsForDevice:device] == NO) {
    return;
  }
	
  [videoInputModule setDefaultSettingsForDevice:device];
}

#pragma mark -
#pragma mark XMVideoModule Methods

- (NSString *)identifier
{
  return [videoInputModule identifier];
}

- (NSString *)name
{
  return [videoInputModule name];
}

- (BOOL)isEnabled
{
  return isEnabled;
}

- (void)setEnabled:(BOOL)flag
{
  if (flag == isEnabled) {
    return;
  }
	
  isEnabled = flag;
	
  [_XMMediaTransmitterSharedInstance _sendDeviceList];
}

- (BOOL)hasSettings
{
  return [videoInputModule hasSettingsForDevice:nil];
}

- (NSDictionary *)permamentSettings
{
  if ([videoInputModule hasSettingsForDevice:nil] == NO) {
    return nil;
  }
	
  return [videoInputModule permamentSettings];
}

- (BOOL)setPermamentSettings:(NSDictionary *)settings
{
  if ([videoInputModule hasSettingsForDevice:nil] == NO) {
    return NO;
  }
	
  return [videoInputModule setPermamentSettings:settings];
}

- (NSView *)settingsView
{
  return [self _settingsViewForDevice:nil];
}

- (void)setDefaultSettings
{
  [self _setDefaultSettingsForDevice:nil];
}

@end

#pragma mark -
#pragma mark QT-Procs

OSStatus XMPacketizeCompressedFrameProc(void*                     encodedFrameOutputRefCon, 
                                        ICMCompressionSessionRef  session, 
                                        OSStatus                  err,
                                        ICMEncodedFrameRef        encodedFrame,
                                        void*                     reserved)
{
  if (err == noErr) {
    XMMediaTransmitter *mediaTransmitter = (XMMediaTransmitter *)encodedFrameOutputRefCon;
    UInt8 *data = ICMEncodedFrameGetDataPtr(encodedFrame);
    UInt32 dataLength = ICMEncodedFrameGetDataSize(encodedFrame);
    UInt32 timeStamp = ICMEncodedFrameGetDecodeTimeStamp(encodedFrame);
    ImageDescriptionHandle imageDesc;
		
    err = ICMEncodedFrameGetImageDescription(encodedFrame, &imageDesc);
    if (err != noErr) {
      NSLog(@"ICMEncodedFrameGetImageDescription failed: %d", err);
    }
    if ([mediaTransmitter _isTransmitting]) {
      err = [mediaTransmitter _packetizeCompressedFrame:data length:dataLength imageDescription:imageDesc timeStamp:timeStamp];
    }
    if ([mediaTransmitter _isRecording]) {
      [_XMCallRecorderSharedInstance _handleCompressedLocalVideoFrame:data
                                                               length:dataLength
                                                     imageDescription:imageDesc];
    }
  }
	
  return err;
}

void XMPacketizerDataReleaseProc(UInt8 *inData, void *inRefCon)
{
}

#pragma mark -
#pragma mark Pixel processing functions

typedef struct XMImageCopyContext
{
  size_t srcWidth;
  size_t srcHeight;
  size_t srcBytesPerRow;
  size_t srcBytesPerPixel;
  unsigned srcByteOffset;
  size_t dstWidth;
  size_t dstHeight;
  size_t dstBytesPerRow;
  size_t dstOffset;
  unsigned conversionMode; // 0: no conversion, 1:24to32, 2:16to32 3:8to32
  unsigned scaleMode;		// 0: no scaling, 1: direct copy, 2: vImage_Scale
  UInt32 *colorLookupTable;
  void *intermediateBuffer;
  void *scaleBuffer;
} XMImageCopyContext;

CVPixelBufferRef XMCreatePixelBuffer(XMVideoSize videoSize)
{
  NSSize size = XMVideoSizeToDimensions(videoSize);
	
  unsigned width = size.width;
  unsigned height = size.height;
	
  if (width == 0 && height == 0) {
    return NULL;
  }
	
  void *buffer = malloc(4*width*height);
	
  CVPixelBufferRef pixelBuffer;
  CVReturn result = CVPixelBufferCreateWithBytes(NULL, (size_t)width, (size_t)height,
                                                 k32ARGBPixelFormat, buffer, 4*width,
                                                 XMMediaTransmitterPixelBufferReleaseCallback,
                                                 NULL, NULL, &pixelBuffer);
	
  if (result != kCVReturnSuccess) {
    return NULL;
  }
	
  return pixelBuffer;
}

void XMClearPixelBuffer(CVPixelBufferRef pixelBuffer)
{
  CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
  void *buf = CVPixelBufferGetBaseAddress(pixelBuffer);
    
  unsigned bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);  
  unsigned height = CVPixelBufferGetHeight(pixelBuffer);
    
  bzero(buf, bytesPerRow*height);
    
  CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

void *XMCreateImageCopyContext(unsigned srcWidth, unsigned srcHeight,
                               unsigned srcXOffset, unsigned srcYOffset,
                               unsigned srcBytesPerRow, OSType srcPixelFormat,
                               CGDirectPaletteRef colorPalette,
                               CVPixelBufferRef dstPixelBuffer,
                               XMImageScaleOperation imageScaleOperation)
{
  XMImageCopyContext *context = malloc(sizeof(XMImageCopyContext));
	
  // initializing default values
  context->srcWidth = srcWidth;
  context->srcHeight = srcHeight;
  context->srcBytesPerRow = srcBytesPerRow;
  context->srcBytesPerPixel = 4;
  context->dstWidth = CVPixelBufferGetWidth(dstPixelBuffer);
  context->dstHeight = CVPixelBufferGetHeight(dstPixelBuffer);
  context->dstBytesPerRow = CVPixelBufferGetBytesPerRow(dstPixelBuffer);
  context->dstOffset = 0;
  context->conversionMode = 0;
  context->scaleMode = 0;
  context->colorLookupTable = NULL;
  context->intermediateBuffer = NULL;
  context->scaleBuffer = NULL;
	
  // determining whether conversion is needed
  switch (srcPixelFormat) {
    case k32ARGBPixelFormat:
      break;
    case k24RGBPixelFormat:
      context->conversionMode = 1;
      context->srcBytesPerPixel = 3;
      break;
    case k16BE555PixelFormat:
      context->conversionMode = 2;
      context->srcBytesPerPixel = 2;
      break;
    case k8IndexedPixelFormat:
      context->conversionMode = 3;
      context->srcBytesPerPixel = 1;
      context->colorLookupTable = _XMCreateColorLookupTable(colorPalette);
      break;
    default: // unknown pixel format
      context->conversionMode = UINT_MAX;
      break;
  }
    
  context->srcByteOffset = (srcYOffset * srcBytesPerRow) + (srcXOffset * context->srcBytesPerPixel);
	
  // determining whether scale or copy operation is needed
  if (context->srcWidth != context->dstWidth || context->srcHeight != context->srcHeight) {
    if (imageScaleOperation == XMImageScaleOperation_NoScaling) {
      context->scaleMode = 1;
			
      if (context->srcWidth < context->dstWidth) {
        size_t difference = (context->dstWidth - context->srcWidth) / 2;
        context->dstOffset += (difference * 4);
        context->dstWidth = context->srcWidth;
      } else {
        context->srcWidth = context->dstWidth;
      }
			
      if (context->srcHeight < context->dstHeight) {
        size_t difference = (context->dstHeight - context->srcHeight) / 2;
        context->dstOffset += (difference * context->dstBytesPerRow);
        context->dstHeight = context->srcHeight;
      } else {
        context->srcHeight = context->dstHeight;
      }
    } else if (imageScaleOperation == XMImageScaleOperation_ScaleProportionally) {
      context->scaleMode = 2;
			
      float aspectRatio = (float)context->srcWidth/(float)context->srcHeight;
			
      size_t calculatedDstWidth = (size_t)((float)context->dstHeight * aspectRatio);
      size_t calculatedDstHeight = (size_t)((float)context->dstWidth / aspectRatio);
			
      if (calculatedDstWidth < context->dstWidth) {
        size_t difference = (context->dstWidth - calculatedDstWidth) / 2;
        context->dstWidth = calculatedDstWidth;
        context->dstOffset += difference * 4;
      } else if (calculatedDstHeight < context->dstHeight) {
        size_t difference = (context->dstHeight - calculatedDstHeight) / 2;
        context->dstHeight = calculatedDstHeight;
        context->dstOffset += (difference*context->dstBytesPerRow);
      }
    } else if (imageScaleOperation == XMImageScaleOperation_ScaleToFit) {
      context->scaleMode = 2;
    }
  }
	
  if (context->conversionMode != 0 && context->scaleMode == 2) {
    unsigned bufferSize = 4*context->srcWidth*context->srcHeight;
    context->intermediateBuffer = malloc(bufferSize);
  }
  if (context->scaleMode == 1) {
    if (context->conversionMode != 0) {
      unsigned bufferSize = context->srcBytesPerPixel*context->srcWidth*context->srcHeight;
      context->intermediateBuffer = malloc(bufferSize);
    }
  }
  if (context->scaleMode == 2) {
    vImage_Buffer srcBuffer;
    vImage_Buffer dstBuffer;
		
    srcBuffer.data = NULL;
    srcBuffer.width = context->srcWidth;
    srcBuffer.height = context->srcHeight;
    if (context->conversionMode == 0) {
      srcBuffer.rowBytes = context->srcBytesPerRow;
    } else {
      srcBuffer.rowBytes = 4*context->srcWidth*context->srcHeight;
    }
		
    dstBuffer.data = NULL;
    dstBuffer.width = context->dstWidth;
    dstBuffer.height = context->dstHeight;
    dstBuffer.rowBytes = context->dstBytesPerRow;
		
    vImage_Error result;
		
    result = vImageScale_ARGB8888(&srcBuffer, &dstBuffer, NULL, (kvImageBackgroundColorFill | kvImageGetTempBufferSize));
		
    if (result < 0) {
      context->scaleMode = UINT_MAX;
    } else {
      context->scaleBuffer = malloc(result);
    }
  }
	
  if (context->scaleMode == 0 && context->conversionMode == 0) {
    context->scaleMode = 1;
  }
	
  return context;
}

void XMDisposeImageCopyContext(void *imageCopyContext)
{
  XMImageCopyContext *context = (XMImageCopyContext *)imageCopyContext;
	
  if (context->colorLookupTable != NULL) {
    free(context->colorLookupTable);
  }
  if (context->intermediateBuffer != NULL) {
    free(context->intermediateBuffer);
  }
  if (context->scaleBuffer != NULL) {
    free(context->scaleBuffer);
  }
	
  free(context);
}

BOOL XMCopyImageIntoPixelBuffer(void *srcImage, CVPixelBufferRef dstPixelBuffer, void *imageCopyContext)
{
  CVPixelBufferLockBaseAddress(dstPixelBuffer, 0);
	
  XMImageCopyContext *context = (XMImageCopyContext *)imageCopyContext;
  void *targetBuffer = CVPixelBufferGetBaseAddress(dstPixelBuffer);
	
  void *srcBuffer = (srcImage + context->srcByteOffset);
  void *dstBuffer = srcBuffer;
  unsigned srcBytesPerRow = context->srcBytesPerRow;
  unsigned dstBytesPerRow = srcBytesPerRow;

  if (context->scaleMode == 1) {
    unsigned numberOfLines = context->srcHeight;
    unsigned numberOfSrcBytes = context->srcWidth * context->srcBytesPerPixel;
    srcBytesPerRow = context->srcBytesPerRow;
		
    if (context->conversionMode == 0) {
      dstBuffer = targetBuffer;
      dstBuffer += context->dstOffset;
      dstBytesPerRow = context->dstBytesPerRow;
    } else {
      dstBuffer = context->intermediateBuffer;
      dstBytesPerRow = numberOfSrcBytes;
    }
		
    void *src = srcBuffer;
    void *dst = dstBuffer;
		
		for (unsigned i = 0; i < numberOfLines; i++) {
      memcpy(dst, src, numberOfSrcBytes);
      src += srcBytesPerRow;
      dst += dstBytesPerRow;
    }
  }
	
  srcBuffer = dstBuffer;
  srcBytesPerRow = dstBytesPerRow;
	
  if (context->conversionMode == 3) {
    UInt8 *src = srcBuffer;
    UInt8 *dst;
		
    if (context->scaleMode == 2) {
      dstBuffer = context->intermediateBuffer;
      dstBytesPerRow = context->srcWidth*4;
      dst = dstBuffer;
    } else {
      dstBuffer = targetBuffer;
      dstBytesPerRow = context->dstBytesPerRow;
      dst = (dstBuffer + context->dstOffset);
    }
  
    unsigned width = context->srcWidth;
    unsigned height = context->srcHeight;
  
    UInt32 *table = context->colorLookupTable;
		
    for (unsigned i = 0; i < height; i++) {
      UInt32 *temp = (UInt32 *)dst;
			
      for (unsigned j = 0; j < width; j++) {
        UInt8 index = src[j];
				
        temp[j] = table[index];
      }
			
      src += srcBytesPerRow;
      dst += dstBytesPerRow;
    }
  } else if (context->conversionMode >= 1) {
    vImage_Buffer srcImageBuffer;
    vImage_Buffer dstImageBuffer;
		
    srcImageBuffer.data = srcBuffer;
    srcImageBuffer.width = context->srcWidth;
    srcImageBuffer.height = context->srcHeight;
    srcImageBuffer.rowBytes = srcBytesPerRow;
		
    if (context->scaleMode == 2) {
      dstBuffer = context->intermediateBuffer;
      dstImageBuffer.data = dstBuffer;
      dstImageBuffer.width = context->srcWidth;
      dstImageBuffer.height = context->srcHeight;
      dstImageBuffer.rowBytes = dstImageBuffer.width*4;
      dstBytesPerRow = dstImageBuffer.rowBytes;
    } else {
      dstBuffer = targetBuffer;
      dstImageBuffer.data = (dstBuffer + context->dstOffset);
      dstImageBuffer.width = context->dstWidth;
      dstImageBuffer.height = context->dstHeight;
      dstImageBuffer.rowBytes = context->dstBytesPerRow;
      dstBytesPerRow = dstImageBuffer.rowBytes;
    }
		
    vImage_Error result = kvImageNoError;
		
    if (context->conversionMode == 1) {
      result = vImageConvert_RGB888toARGB8888(&srcImageBuffer,
                                              NULL, 0xff,
                                              &dstImageBuffer, false,
                                              kvImageNoFlags);
    } else {
      result = vImageConvert_ARGB1555toARGB8888(&srcImageBuffer,
                                                &dstImageBuffer,
                                                kvImageNoFlags);
    }
		
    if (result != kvImageNoError) {
      NSLog(@"vImageConvert failed %d", result);
      CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
      return NO;
    }
  }
	
  srcBuffer = dstBuffer;
  srcBytesPerRow = dstBytesPerRow;
	
  if (context->scaleMode == 2) {
    vImage_Buffer srcImageBuffer;
    vImage_Buffer dstImageBuffer;
		
    srcImageBuffer.data = srcBuffer;
    srcImageBuffer.width = context->srcWidth;
    srcImageBuffer.height = context->srcHeight;
    srcImageBuffer.rowBytes = srcBytesPerRow;
		
    dstImageBuffer.data = (targetBuffer + context->dstOffset);
    dstImageBuffer.width = context->dstWidth;
    dstImageBuffer.height = context->dstHeight;
    dstImageBuffer.rowBytes = context->dstBytesPerRow;
		
    vImage_Error result = kvImageNoError;
		
    result = vImageScale_ARGB8888(&srcImageBuffer, &dstImageBuffer, context->scaleBuffer, kvImageBackgroundColorFill);
		
    if (result != kvImageNoError) {
      CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
      return NO;
    }
  }

  CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
	
  return YES;
}

void XMRGBA2ARGB(void *buf, unsigned width, unsigned height, unsigned bytesPerRow)
{
  UInt8 *buffer = (UInt8 *)buf;

	for (unsigned i = 0; i < height; i++) {
    for (unsigned j = 0; j < width; j++) {
      UInt8 r = buffer[4*j];
      UInt8 g = buffer[4*j + 1];
      UInt8 b = buffer[4*j + 2];
      UInt8 a = buffer[4*j + 3];
      buffer[4*j] = a;
      buffer[4*j + 1] = r;
      buffer[4*j + 2] = g;
      buffer[4*j + 3] = b;
    }
    buffer += bytesPerRow;
  }
}

void XMMediaTransmitterPixelBufferReleaseCallback(void *releaseRefCon, const void *baseAddress)
{
  free((void *)baseAddress);
}

UInt32 *_XMCreateColorLookupTable(CGDirectPaletteRef palette)
{
  UInt32 *table = (UInt32 *)malloc(256*4);
	
  CGDirectPaletteRef thePalette = palette;
	
  if (thePalette == NULL) {
    thePalette = CGPaletteCreateDefaultColorPalette();
  }
	
  for (unsigned i = 0; i < 256; i++) {
    CGDeviceColor color = CGPaletteGetColorAtIndex(thePalette, i);
		
    UInt8 *ptr = (UInt8 *)(&table[i]);
    ptr[0] = 255;
    ptr[1] = (UInt8)(255.0f * color.red);
    ptr[2] = (UInt8)(255.0f * color.green);
    ptr[3] = (UInt8)(255.0f * color.blue);
  }
	
  if (palette == NULL) {
    CGPaletteRelease(thePalette);
  }
	
  return table;
}

#define scanBit(theDataIndex, theMask) \
{ \
  theMask >>= 1; \
  if (theMask == 0) { \
    theDataIndex++; \
    theMask = 0x80; \
  } \
}

#define readBit(out, theData, theDataIndex, theMask) \
{ \
  out = theData[theDataIndex] & theMask; \
  scanBit(theDataIndex, theMask); \
}

void _XMAdjustH261Data(UInt8 *h261Data, BOOL isINTRAFrame, UInt32 timestamp)
{	
  // In the H.261 standard, there are two bits in PTYPE which
  // were originally unused. The first bit of them is now the
  // flag defining the still image mode. If this mode isn't used,
  // the flag should be set to one. This applies to the second
  // unused bit as well. Unfortunately, QuickTime sets these two
  // bits to zero, which causes problems on Tandberg devices.
  // Therefore, these bits are here set to one
  // In addition, the Freeze picture release bit should be set
  // whenever an INTRA frame is sent to make some polycom devices
  // happy.
  // Also set a correct value in the TR field of the H.261 picture header
  UInt8 tr = (UInt8)(timestamp/3003) - 1;
  UInt32 dataIndex = 1;
  UInt8 mask = 0x01;
	
  UInt8 bit;
  
  // scan past PSC
  do  {
    readBit(bit, h261Data, dataIndex, mask);
  } while (bit == 0);
  scanBit(dataIndex, mask);
  scanBit(dataIndex, mask);
  scanBit(dataIndex, mask);
  scanBit(dataIndex, mask);
  
  // Write the TR value
  if ((tr >> 4) & 0x01) {
    h261Data[dataIndex] |= mask;
  }
  scanBit(dataIndex, mask);
  if ((tr >> 3) & 0x01) {
    h261Data[dataIndex] |= mask;
  }
  scanBit(dataIndex, mask);
  if ((tr >> 2) & 0x01) {
    h261Data[dataIndex] |= mask;
  }
  scanBit(dataIndex, mask);
  if ((tr >> 1) & 0x01) {
    h261Data[dataIndex] |= mask;
  }
  scanBit(dataIndex, mask);
  if (tr & 0x01) {
    h261Data[dataIndex] |= mask;
  }
  scanBit(dataIndex, mask);
  
  // scan past Split screen indicator, Document camera indicator
  scanBit(dataIndex, mask);
  scanBit(dataIndex, mask);
	
  // Set the Freeze picture release bit if needed
  if (isINTRAFrame) {
    h261Data[dataIndex] |= mask;
  }
  scanBit(dataIndex, mask);
  
  // scan past Source format
  scanBit(dataIndex, mask);
	
  // set Optional still image mode HI_RES and Spare bits to one (disabled)
  h261Data[dataIndex] |= mask;
  scanBit(dataIndex, mask);
  h261Data[dataIndex] |= mask;
}

void _XMAdjustH263Data(UInt8 *h263Data, BOOL isINTRAFrame, UInt32 timestamp)
{
  if ((h263Data[4] & 0x02) == 0) { //isINTRAFrame
    h263Data[4] |= 0x20;
  }
	
  // Set the correct TR value
  UInt8 tr = (UInt8)(timestamp/3003) - 1;
  h263Data[2] &= 0xfc;
  h263Data[3] &= 0x03;
  h263Data[2] |= ((tr >> 6) & 0x03);
  h263Data[3] |= ((tr << 2) & 0xfc);
}

BOOL _XMIsH263IFrame(UInt8* data)
{
  return ((data[4] & 0x02) == 0);
}