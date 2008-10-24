/*
 * $Id: XMSequenceGrabberVideoInputModule.m,v 1.27 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMSequenceGrabberVideoInputModule.h"

#import "XMUtils.h"
#import "XMDummyVideoInputModule.h"

// The Built-in iSight returns perfectly resized pixel buffers when
// grabbing 352x288 sized images. However, the clean rect as reported
// by CVImageBufferGetCleanRect is incorrect, causing horrible drawing
// results on screen (transmitted images are just fine)
#define XM_GRAB_WIDTH 640
#define XM_GRAB_HEIGHT 480

#define XM_CALLBACK_NEVER_CALLED 0
#define XM_CALLBACK_NOT_CALLED 1
#define XM_CALLBACK_CALLED 2
#define XM_CALLBACK_ERROR_REPORTED 4

#define XM_MAX_CALLBACK_NOT_CALLED 10
#define XM_MAX_CALLBACK_NEVER_CALLED 100

// Data Proc that is called whenever the SequenceGrabber
// did grab a frame
static pascal OSErr XMSGProcessGrabDataProc(SGChannel channel,
                                            Ptr data,
                                            long length,
                                            long *offset,
                                            long channelRefCon,
                                            TimeValue time,
                                            short writeType,
                                            long refCon);

// Proc that is called when the grabbed frame is succcesfully
// decompressed into a CVPixelBufferRef structure
static void XMSGProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
                                             OSStatus result,
                                             ICMDecompressionTrackingFlags decompressionTrackingFlags,
                                             CVPixelBufferRef pixelBuffer, 
                                             TimeValue64 displayTime,
                                             TimeValue64 displayDuration, 
                                             ICMValidTimeFlags validTimeFlags,
                                             void* reserved, 
                                             void* sourceFrameRefCon);

@interface XMSGDeviceNameIndex : NSObject {
	
  unsigned deviceIndex;
  unsigned inputNameIndex;
	
}

- (id)_initWithDeviceIndex:(unsigned)deviceIndex inputNameIndex:(unsigned)inputNameIndex;

- (unsigned)_deviceIndex;
- (unsigned)_inputNameIndex;

@end

@interface XMSequenceGrabberVideoInputModule (PrivateMethods)

- (void)_openAndConfigureSeqGrabComponent;
- (void)_disposeSeqGrabComponent;
- (void)_openAndConfigureChannel;
- (BOOL)_createDecompressionSession;
- (BOOL)_disposeDecompressionSession;
- (OSErr)_processGrabData:(Ptr)grabData length:(long)length time:(TimeValue)time;
- (void)_processDecompressedFrame:(CVPixelBufferRef)pixelBuffer;
- (void)_updateSliders;
- (void)_updateTextFields;

@end

@implementation XMSequenceGrabberVideoInputModule

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
	
  inputManager = nil;
	
  deviceList = NULL;
  deviceNames = nil;
  deviceNameIndexes = nil;
  selectedDevice = nil;
	
  sequenceGrabber = NULL;
  videoChannel = NULL;
  dataGrabUPP = NULL;
  grabDecompressionSession = NULL;
  lastTime = 0;
  desiredFrameDuration = 0;
	
  frameSize = NSMakeSize(0, 0);
  framesPerSecond = 0;
	
  isGrabbing = NO;
  callbackMissCounter = 0;
  callbackStatus = XM_CALLBACK_NEVER_CALLED;
	
  brightness = 0;
  hue = 0;
  saturation = 0;
  contrast = 0;
  sharpness = 0;
	
  settingsView = nil;
	
  return self;
}

- (void)dealloc
{
  [inputManager release];
  [deviceNames release];
  [deviceNameIndexes release];
  [selectedDevice release];
	
  [super dealloc];
}

#pragma mark Module Methods

- (NSString *)identifier
{
  return @"XMSequenceGrabberVideoInputModule";
}

- (NSString *)name
{
  return NSLocalizedString(@"XM_FRAMEWORK_SEQ_GRAB_MODULE_NAME", @"");
}

- (void)setupWithInputManager:(id<XMVideoInputManager>)theInputManager
{
  inputManager = [theInputManager retain];
	
  [self _openAndConfigureSeqGrabComponent];
}

- (void)close
{
  [self _disposeSeqGrabComponent];
	
  [inputManager release];
  inputManager = nil;
}

- (NSArray *)inputDevices
{
  [deviceNames release];
  [deviceNameIndexes release];
  
  deviceNames = nil;
  deviceNameIndexes = nil;
	
  if (deviceList != NULL) {
    ComponentResult err = noErr;
    unsigned hintCode;
		
    err = SGDisposeDeviceList(sequenceGrabber, deviceList);
    deviceList = NULL;
		
    if (err != noErr) {
      hintCode = 0x003001;
      [inputManager handleErrorWithCode:err hintCode:hintCode];
    }
  }
	
  // In case we've failed to create a SGChannel previously, due
  // to the lack of an attached video device, we'll try again here
  if (videoChannel == NULL) {
    openAndConfigureChannelErr = noErr;
    [self performSelectorOnMainThread:@selector(_openAndConfigureChannel) withObject:nil waitUntilDone:YES];
    if (openAndConfigureChannelErr != noErr) {
      videoChannel = NULL;
    }
  }
	
  ComponentResult err = noErr;
  unsigned hintCode = 0;
		
  if (videoChannel == NULL) {
    // it wasn't possible to create the SGChannel, indicating
    // that no video device is plugged in.
    deviceNames = [[NSArray alloc] init];
  } else {
    err = SGGetChannelDeviceList(videoChannel, sgDeviceListIncludeInputs, &deviceList);
    if (err != noErr) {
      hintCode = 0x002001;
      [inputManager handleErrorWithCode:err hintCode:hintCode];
				
      deviceNames = [[NSArray alloc] init];
    } else {
      SGDeviceListRecord *deviceListRecord = (*deviceList);
      NSMutableArray *namesArray = [[NSMutableArray alloc] initWithCapacity:deviceListRecord->count];
      NSMutableArray *indexArray = [[NSMutableArray alloc] initWithCapacity:deviceListRecord->count];
		
      for (unsigned i = 0; i < deviceListRecord->count; i++) {
        SGDeviceName deviceName = deviceListRecord->entry[i];
		
        if (deviceName.inputs != NULL) {
          SGDeviceInputListRecord *inputListRecord = *deviceName.inputs;
				
          for (unsigned j = 0; j < inputListRecord->count; j++) {
            // this structure contains the actual human understandable name
            SGDeviceInputName deviceInputName = inputListRecord->entry[j];
            NSString *name = [[NSString alloc] initWithCString:(const char *)deviceInputName.name encoding:NSASCIIStringEncoding];
					
            // adding the name to the object
            [namesArray addObject:name];
            [name release];
					
            // caching the index of this device
            XMSGDeviceNameIndex *deviceNameIndex = [[XMSGDeviceNameIndex alloc] _initWithDeviceIndex:i inputNameIndex:j];
            [indexArray addObject:deviceNameIndex];
          }
        }
      }
	
      deviceNames = [namesArray copy];
      deviceNameIndexes = [indexArray copy];
		
      [namesArray release];
      [indexArray release];
    }
  }
	
  return deviceNames;
}

- (BOOL)openInputDevice:(NSString *)device
{	
  ComponentResult err = noErr;
  unsigned hintCode = 0;
	
  unsigned index = [deviceNames indexOfObject:device];
	
  if (index == NSNotFound) {
    // reporting the error here
    err = -1;
    hintCode = 0x004001;
    goto bail;
  }
	
  selectedDevice = [device retain];
	
  XMSGDeviceNameIndex *deviceNameIndex = [deviceNameIndexes objectAtIndex:index];
  unsigned deviceIndex = [deviceNameIndex _deviceIndex];
  unsigned inputNameIndex = [deviceNameIndex _inputNameIndex];
	
  SGDeviceListRecord *deviceListRecord = *deviceList;
  SGDeviceName deviceName = deviceListRecord->entry[deviceIndex];
	
  if (videoChannel == NULL) {
    openAndConfigureChannelErr = noErr;
    [self performSelectorOnMainThread:@selector(_openAndConfigureChannel) withObject:nil waitUntilDone:YES];
    if (openAndConfigureChannelErr != noErr) {
      err = openAndConfigureChannelErr;
      hintCode = 0x004002;
      goto bail;
    }
  }
	
  dataGrabUPP = NewSGDataUPP(XMSGProcessGrabDataProc);
  err = SGSetDataProc(sequenceGrabber, dataGrabUPP, (long)self);
  if (err != noErr) {
    hintCode = 0x004003;
    goto bail;
  }
	
  // we have to use the name of the device, not the input device name itself
  err = SGSetChannelDevice(videoChannel, deviceName.name);
  if (err != noErr) {
    hintCode = 0x004004;
    if (err == qErr) {
      // The device is probably used by another application
      goto bail;
    }
    NSLog(@"XMeeting SequenceGrabber module: SGSetChannelDevice() failed (Error code %d). Still continuing", err);
  }
	
  // now we can set the actual input device by its index
  err = SGSetChannelDeviceInput(videoChannel, inputNameIndex);
  if (err != noErr) {
    hintCode = 0x004005;
    goto bail;  
  }
	
  Rect rect;
  rect.top = 0;
  rect.left = 0;
  rect.bottom = XM_GRAB_HEIGHT;
  rect.right = XM_GRAB_WIDTH;
  err = SGSetChannelBounds(videoChannel, &rect);
  if (err != noErr) {
    hintCode = 0x004006;
    goto bail;
  }
	
  err = SGPrepare(sequenceGrabber, false, true);
  if (err != noErr) {
    hintCode = 0x004006;
    goto bail;
  }
	
  err = SGStartRecord(sequenceGrabber);
  if (err != noErr) {
    hintCode = 0x004007;
    goto bail;
  }
	
  err = SGGetChannelTimeScale(videoChannel, &timeScale);
  if (err != noErr) {
    NSLog(@"SGGetChannelTimeScale failed(1): %d", (int)err);
  }
	
  lastTime = 0;
  timeScale = 0;
	
  if ([self _createDecompressionSession] == NO) {
    // the error has already been reported
    return NO;
  }
	
  isGrabbing = YES;
  callbackMissCounter = 0;
  callbackStatus = XM_CALLBACK_NEVER_CALLED;
	
  // Obtaining values for Brightness etc.
	
  unsigned short theBrightness = 0;
  unsigned short theHue = 0;
  unsigned short theSaturation = 0;
  unsigned short theContrast = 0;
  unsigned short theSharpness = 0;
	
  ComponentInstance videoDigitizer = SGGetVideoDigitizerComponent(videoChannel);
	
  err = VDGetBrightness(videoDigitizer, &theBrightness);
  if (err != noErr) {
    //NSLog(@"VDGetBrightness failed :%d", err);
    theBrightness = 0;
  } else {
    err = VDSetBrightness(videoDigitizer, &theBrightness);
    if (err != noErr) {
      theBrightness = 0;
    } else if (theBrightness == 0) {
      theBrightness = 1;
    }
  }
	
  err = VDGetHue(videoDigitizer, &theHue);
  if (err != noErr) {
    //NSLog(@"VDGetHue failed: %d", err);
    theHue = 0;
  }	else {
    err = VDSetHue(videoDigitizer, &theHue);
    if (err != noErr) {
      theHue = 0;
    } else if (theHue == 0) {
      theHue = 1;
    }
  }
	
  err = VDGetSaturation(videoDigitizer, &theSaturation);
  if (err != noErr) {
    //NSLog(@"VDGetSaturation failed: %d", err);
    theSaturation = 0;
  } else {
    err = VDSetSaturation(videoDigitizer, &theSaturation);
    if (err != noErr) {
      theSaturation = 0;
    } else if (theSaturation == 0) {
      theSaturation = 1;
    }
  }
	
  err = VDGetContrast(videoDigitizer, &theContrast);
  if (err != noErr) {
    //NSLog(@"VDGetContrast failed: %d", err);
    theContrast = 0;
  } else {
    err = VDSetContrast(videoDigitizer, &theContrast);
    if (err != noErr) {
      theContrast = 0;
    } else if (theContrast == 0) {
      theContrast = 1;
    }
  }
	
  err = VDGetSharpness(videoDigitizer, &theSharpness);
  if (err != noErr) {
    //NSLog(@"VDGetSharpness failed: %d", err);
    theSharpness = 0;
  } else {
    err = VDSetSharpness(videoDigitizer, &theSharpness);
    if (err != noErr) {
      theSharpness = 0;
    } else if (theSharpness == 0) {
      theSharpness = 1;
    }
  }
	
  NSNumber *theBrightnessNumber = [[NSNumber alloc] initWithUnsignedShort:theBrightness];
  NSNumber *theHueNumber = [[NSNumber alloc] initWithUnsignedShort:theHue];
  NSNumber *theSaturationNumber = [[NSNumber alloc] initWithUnsignedShort:theSaturation];
  NSNumber *theContrastNumber = [[NSNumber alloc] initWithUnsignedShort:theContrast];
  NSNumber *theSharpnessNumber = [[NSNumber alloc] initWithUnsignedShort:theSharpness];
	
  NSArray *values = [[NSArray alloc] initWithObjects:theBrightnessNumber, theHueNumber, theSaturationNumber, theContrastNumber, theSharpnessNumber, nil];
	
  [self performSelectorOnMainThread:@selector(_setVideoValues:) withObject:values waitUntilDone:NO];
	
  [values release];
	
  [theBrightnessNumber release];
  [theHueNumber release];
  [theSaturationNumber release];	
  [theContrastNumber release];
  [theSharpnessNumber release];
    
  callbackStatus = XM_CALLBACK_NEVER_CALLED;
  callbackMissCounter = 0;
	
  return YES;
	
bail:
  // stopping any sequence if needed
  SGStop(sequenceGrabber);

  if (dataGrabUPP != NULL) {
    DisposeSGDataUPP(dataGrabUPP);
    dataGrabUPP = NULL;
  }
	
  [selectedDevice release];
  selectedDevice = nil;
	
  [inputManager handleErrorWithCode:err hintCode:hintCode];
  return NO;
}

- (BOOL)closeInputDevice
{
  BOOL result = YES;
	
  isGrabbing = NO;
	
  if (SGStop(sequenceGrabber) != noErr) {
    result = NO;
  }
	
  if ([self _disposeDecompressionSession] == NO) {
    result = NO;
  }
	
  [selectedDevice release];
  selectedDevice = nil;
	
  if (SGDisposeChannel(sequenceGrabber, videoChannel) != noErr) {
    result = NO;
  }
  videoChannel = NULL;
	
  return result;
}

- (BOOL)setInputFrameSize:(XMVideoSize)videoSize
{
  frameSize = XMVideoSizeToDimensions(videoSize);
	
  if (isGrabbing == YES) {
    if ([self _disposeDecompressionSession] == NO) {
      return NO;
    }
    if ([self _createDecompressionSession] == NO) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)setFrameGrabRate:(unsigned)theFramesPerSecond
{
  framesPerSecond = theFramesPerSecond;

  desiredFrameDuration = timeScale / framesPerSecond;
	
  return YES;
}

- (BOOL)grabFrame
{
  ComponentResult err = noErr;
  unsigned hintCode = 0;
	
  // Workaround for the FW-Cam Freeze Bug:
  // After some time running, a FW-Cam may freeze
  // so that the SGDataUPP doesn't get called anymore
  // We detect this by counting the subsequent
  // callback misses and restart the sequence grabbing
  // process after some time running
  if (callbackStatus != XM_CALLBACK_NEVER_CALLED) {
    callbackStatus = XM_CALLBACK_NOT_CALLED; // Reset the test condition
  }
  err = SGIdle(sequenceGrabber);
  if (callbackStatus == XM_CALLBACK_NEVER_CALLED || callbackStatus == XM_CALLBACK_NOT_CALLED) {
    // incrementing the counter and check for XM_MAX_CALLBACK_MISSES subsequent misses
    callbackMissCounter++;
    if ((callbackStatus == XM_CALLBACK_NEVER_CALLED && callbackMissCounter == XM_MAX_CALLBACK_NEVER_CALLED) ||
        (callbackStatus == XM_CALLBACK_NOT_CALLED && callbackMissCounter == XM_MAX_CALLBACK_NOT_CALLED)) {
      NSString *device = [selectedDevice retain];
      [self closeInputDevice];
      [self _disposeSeqGrabComponent];
      [self _openAndConfigureSeqGrabComponent];
      [self openInputDevice:device];
      [device release];
            
      callbackStatus = XM_CALLBACK_NOT_CALLED;
      callbackMissCounter = 0;
            
      // Send a dummy picture to keep the data flowing
      CVPixelBufferRef dummyPicture = [XMDummyVideoInputModule getDummyImageForVideoSize:XMDimensionsToVideoSize(frameSize)];
      if (dummyPicture != NULL) {
        [inputManager handleGrabbedFrame:dummyPicture];
      } else {
        hintCode = 0x005002;
        [inputManager handleErrorWithCode:1 hintCode:hintCode];
        return NO;
      }
    }
  } else if (callbackStatus == XM_CALLBACK_CALLED) {
    // resetting the counter
    callbackMissCounter = 0;
  }
	
  if (err != noErr) {
    // only reporting an error if not already done so.
    if (callbackStatus != XM_CALLBACK_ERROR_REPORTED) {
      hintCode = 0x005001;
      [inputManager handleErrorWithCode:err hintCode:hintCode];
    }
    return NO;
  }
	
  return YES;
}

- (NSString *)descriptionForErrorCode:(int)errorCode hintCode:(int)hintCode device:(NSString *)device
{
  NSString *formatString;
	
  if (hintCode == 0x005001) {
    formatString = NSLocalizedString(@"XM_FRAMEWORK_SEQ_GRAB_NO_CAMERA", @"");
  } else if ((hintCode == 0x004002 && errorCode == couldntGetRequiredComponent) ||
             (hintCode == 0x004004 && errorCode == qErr)) {
    formatString = NSLocalizedString(@"XM_FRAMEWORK_SEQ_GRAB_CAMERA_BUSY", @"");
    return [NSString stringWithFormat:formatString, device];
  } else {
    formatString = NSLocalizedString(@"XM_FRAMEWORK_SEQ_GRAB_INTERNAL", @"");
  }
  NSString *errorString = [NSString stringWithFormat:formatString, errorCode, hintCode, device];
  return errorString;
}

- (BOOL)hasSettingsForDevice:(NSString *)device
{
  if (device == nil) {
    return NO;
  }
	
  return YES;
}

- (BOOL)requiresSettingsDialogWhenDeviceOpens:(NSString *)device
{
  return NO;
}

- (NSData *)internalSettings
{
  unsigned short theBrightness;
  unsigned short theHue;
  unsigned short theSaturation;
  unsigned short theContrast;
  unsigned short theSharpness;
	
  if (settingsView == nil) {
    theBrightness = brightness;
    theHue = hue;
    theSaturation = saturation;
    theContrast = contrast;
    theSharpness = sharpness;
  } else {
    if ([brightnessSlider isEnabled] == YES) {
      float brightnessValue = [brightnessSlider floatValue];
      theBrightness = (unsigned short)(brightnessValue * 655.35f);
      if (theBrightness == 0) {
        theBrightness = 1;
      }
    } else {
      theBrightness = 0;
    }
		
		if ([hueSlider isEnabled] == YES) {
      float hueValue = [hueSlider floatValue];
      theHue = (unsigned short)((hueValue + 180.0f) * 182.04166666666f);
      if (theHue == 0) {
        theHue = 1;
      }
    } else {
      theHue = 0;
    }
		
    if ([saturationSlider isEnabled] == YES) {
      float saturationValue = [saturationSlider floatValue];
      theSaturation = (unsigned short)(saturationValue * 655.35f);
      if (theSaturation == 0) {
        theSaturation = 1;
      }
    } else {
      theSaturation = 0;
    }
		
    if ([contrastSlider isEnabled] == YES) {
      float contrastValue = [contrastSlider floatValue];
      theContrast = (unsigned short)(contrastValue * 655.35f);
      if (theContrast == 0) {
        theContrast = 1;
      }
    } else {
      theContrast = 0;
    }
		
    if ([sharpnessSlider isEnabled] == YES) {
      float sharpnessValue = [sharpnessSlider floatValue];
      theSharpness = (unsigned short)(sharpnessValue * 655.35f);
      if (theSharpness == 0) {
        theSharpness = 1;
      }
    } else {
      theSharpness = 0;
    }
  }
	
  NSNumber *theBrightnessNumber = [[NSNumber alloc] initWithUnsignedShort:theBrightness];
  NSNumber *theHueNumber = [[NSNumber alloc] initWithUnsignedShort:theHue];
  NSNumber *theSaturationNumber = [[NSNumber alloc] initWithUnsignedShort:theSaturation];
  NSNumber *theContrastNumber = [[NSNumber alloc] initWithUnsignedShort:theContrast];
  NSNumber *theSharpnessNumber = [[NSNumber alloc] initWithUnsignedShort:theSharpness];

  NSArray *values = [[NSArray alloc] initWithObjects:theBrightnessNumber, theHueNumber, theSaturationNumber, theContrastNumber, theSharpnessNumber, nil];
	
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:values];
	
  [values release];
	
  [theBrightnessNumber release];
  [theHueNumber release];
  [theSaturationNumber release];
  [theContrastNumber release];
  [theSharpnessNumber release];
	
  return data;
}

- (void)applyInternalSettings:(NSData *)settings
{
  ComponentResult err = noErr;
	
  if (videoChannel == NULL) {
    return;
  }
	
  NSArray *array = (NSArray *)[NSKeyedUnarchiver unarchiveObjectWithData:settings];
	
  NSNumber *theBrightnessNumber = (NSNumber *)[array objectAtIndex:0];
  NSNumber *theHueNumber = (NSNumber *)[array objectAtIndex:1];
  NSNumber *theSaturationNumber = (NSNumber *)[array objectAtIndex:2];
  NSNumber *theContrastNumber = (NSNumber *)[array objectAtIndex:3];
  NSNumber *theSharpnessNumber = (NSNumber *)[array objectAtIndex:4];
	
  unsigned short theBrightness = [theBrightnessNumber unsignedShortValue];
  unsigned short theHue = [theHueNumber unsignedShortValue];
  unsigned short theSaturation = [theSaturationNumber unsignedShortValue];
  unsigned short theContrast = [theContrastNumber unsignedShortValue];
  unsigned short theSharpness = [theSharpnessNumber unsignedShortValue];
	
  ComponentInstance videoDigitizer = SGGetVideoDigitizerComponent(videoChannel);
	
  if (theBrightness != 0) {
    err = VDSetBrightness(videoDigitizer, &theBrightness);
    if (err != noErr) {
      //NSLog(@"VDSetBrightness failed: %d", err);
    }
  }
  if (theHue != 0) {
    err = VDSetHue(videoDigitizer, &theHue);
    if (err != noErr) {
      //NSLog(@"VDSetHue failed: %d", err);
    }
  }
  if (theSaturation != 0) {
    err = VDSetSaturation(videoDigitizer, &theSaturation);
    if (err != noErr) {
      //NSLog(@"VDSetSaturation failed: %d", err);
    }
  }
  if (theContrast != 0) {
    err = VDSetContrast(videoDigitizer, &theContrast);
    if (err != noErr) {
      //NSLog(@"VDSetContrast failed: %d", err);
    }
  }
  if (theSharpness != 0) {
    err = VDSetSharpness(videoDigitizer, &theSharpness);
    if (err != noErr) {
      //NSLog(@"VDSetSharpness failed: %d", err);
    }
  }
}

- (NSDictionary *)permamentSettings
{
  // there are no permament settings at this time
  return nil;
}

- (BOOL)setPermamentSettings:(NSDictionary *)settings
{
  return NO;
}

- (NSView *)settingsViewForDevice:(NSString *)device
{
  if (settingsView == nil) {
    [NSBundle loadNibNamed:@"SequenceGrabberSettings" owner:self];
  }
	
  [self _updateSliders];
	
  return settingsView;
}

- (void)setDefaultSettingsForDevice:(NSString *)device
{
  [self _updateSliders];
  [inputManager noteSettingsDidChangeForModule:self];
}

#pragma mark Private Methods

- (void)_openAndConfigureSeqGrabComponent
{
  ComponentResult err = noErr;
  unsigned hintCode = 0;
	
  sequenceGrabber = OpenDefaultComponent(SeqGrabComponentType, 0);
  if (sequenceGrabber == NULL) {
    hintCode = 0x001001;
    goto bail;
  }
	
  err = SGInitialize(sequenceGrabber);
  if (err != noErr) {
    hintCode = 0x001002;
    goto bail;
  }
	
  // we need to explicitely call this function or the code will break
  // although we aren't using any GWorld
  err = SGSetGWorld(sequenceGrabber, NULL, NULL);
  if (err != noErr) {
    hintCode = 0x001003;
    goto bail;
  }
	
  err = SGSetDataRef(sequenceGrabber, 0, 0, seqGrabDontMakeMovie);
  if (err != noErr) {
    hintCode = 0x001004;
    goto bail;
  }
	
  return;
	
bail:
		
  [inputManager handleErrorWithCode:err hintCode:hintCode];
	
  if (sequenceGrabber != NULL) {
    CloseComponent(sequenceGrabber);
    sequenceGrabber = NULL;
  }
}

- (void)_disposeSeqGrabComponent
{
  // we don't report any errors occuring in this method
  if (videoChannel != NULL) {
    SGDisposeChannel(sequenceGrabber, videoChannel);
    videoChannel = NULL;
  }
	
  if (sequenceGrabber != NULL) {
    CloseComponent(sequenceGrabber);
    sequenceGrabber = NULL;
  }
	
  if (dataGrabUPP != NULL) {
    DisposeSGDataUPP(dataGrabUPP);
    dataGrabUPP = NULL;
  }
}

- (void)_openAndConfigureChannel
{
  openAndConfigureChannelErr = SGNewChannel(sequenceGrabber, VideoMediaType, &videoChannel);
  if (openAndConfigureChannelErr != noErr) {
    // this indicates that probably no video input device is attached
    return;
  }
	
  openAndConfigureChannelErr = SGSetChannelUsage(videoChannel, seqGrabRecord);
}

- (BOOL)_createDecompressionSession
{
  ComponentResult err = noErr;
  unsigned hintCode;
	
  ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
  err = SGGetChannelSampleDescription(videoChannel, (Handle)imageDesc);
  if (err != noErr) {
    hintCode = 0x007001;
    goto bail;
  }
	
  NSNumber *number = nil;
  NSMutableDictionary *pixelBufferAttributes = nil;
	
  pixelBufferAttributes = [[NSMutableDictionary alloc] initWithCapacity:3];
	
  // Setting the Width / Height for the buffer
  number = [[NSNumber alloc] initWithInt:(int)frameSize.width];
  [pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferWidthKey];
  [number release];
	
  number = [[NSNumber alloc] initWithInt:(int)frameSize.height];
  [pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferHeightKey];
  [number release];
	
  number = [[NSNumber alloc] initWithInt:k32ARGBPixelFormat];
  [pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
  [number release];
    
  number = [[NSNumber alloc] initWithBool:YES];
  [pixelBufferAttributes setObject:number forKey:(NSString *)kCVPixelBufferOpenGLCompatibilityKey];
  [number release];
	
  ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
  trackingCallbackRecord.decompressionTrackingCallback = XMSGProcessDecompressedFrameProc;
  trackingCallbackRecord.decompressionTrackingRefCon = (void *)self;
	
  err = ICMDecompressionSessionCreate(NULL, imageDesc, NULL, (CFDictionaryRef)pixelBufferAttributes, &trackingCallbackRecord, &grabDecompressionSession);
  if (err != noErr) {
    hintCode = 0x007002;
  }
	
bail:
	
  [pixelBufferAttributes release];
  DisposeHandle((Handle)imageDesc);
	
  if (err != noErr) {
    [inputManager handleErrorWithCode:err hintCode:hintCode];
    return NO;
  }
	
  return YES;
}

- (BOOL)_disposeDecompressionSession
{
  ICMDecompressionSessionRelease(grabDecompressionSession);
  grabDecompressionSession = NULL;
  return YES;
}

- (OSErr)_processGrabData:(Ptr)data length:(long)length time:(TimeValue)time
{
  ComponentResult err = noErr;
  unsigned hintCode = 0;
	
  callbackStatus = XM_CALLBACK_CALLED;
	
  if (timeScale == 0) {
    err = SGGetChannelTimeScale(videoChannel, &timeScale);
    if (err != noErr) {
      hintCode = 0x008001;
      goto bail;
    }
		
    // we use this value to determine whether to drop a frame or not.
    // this is necessary since SGIdle() does produce frames quite
    // unregularly, sometimes even twice per call
    desiredFrameDuration = timeScale / framesPerSecond;
  }
	
  // determining whether to drop the frame or not.
  // we leave a tolerance of half the desiredFrameDuration in
  // order not to drop a frame which is arriving only sligthly
  // before the minimum frame duration
  if (((time - lastTime) < (desiredFrameDuration * 0.5)) && (lastTime > 0)) {
    // Dropping the frame
    return noErr;
  }
	
  err = ICMDecompressionSessionDecodeFrame(grabDecompressionSession, (UInt8 *)data, length, NULL, NULL, (void *)self);
  if (err != noErr) {
    hintCode = 0x008002;
    goto bail;
  }
	
  lastTime = time;
	
bail:
	
  if (err != noErr) {
    [inputManager handleErrorWithCode:err hintCode:hintCode];
    callbackStatus = XM_CALLBACK_ERROR_REPORTED;
  }
	
  return err;
}

- (void)_processDecompressedFrame:(CVPixelBufferRef)pixelBuffer
{
  [inputManager handleGrabbedFrame:pixelBuffer];
}

- (void)_setVideoValues:(NSArray *)values
{
  NSNumber *number = [values objectAtIndex:0];
  brightness = [number unsignedShortValue];
	
  number = [values objectAtIndex:1];
  hue = [number unsignedShortValue];
	
  number = [values objectAtIndex:2];
  saturation = [number unsignedShortValue];
	
  number = [values objectAtIndex:3];
  contrast = [number unsignedShortValue];
	
  number = [values objectAtIndex:4];
  sharpness = [number unsignedShortValue];
	
  if (settingsView != nil) {
    [self _updateSliders];
  }
}

- (IBAction)_sliderValueChanged:(id)sender
{
  [self _updateTextFields];
	
  [inputManager noteSettingsDidChangeForModule:self];
}

- (void)_updateSliders
{
  if (brightness == 0) {
    [brightnessSlider setFloatValue:0.0f];
    [brightnessSlider setEnabled:NO];
    [brightnessField setEnabled:NO];
  } else {
    float brightnessValue = (float)brightness / 655.35f;
    [brightnessSlider setFloatValue:brightnessValue];
    [brightnessSlider setEnabled:YES];
    [brightnessField setEnabled:YES];
  }
	
  if (hue == 0) {
    [hueSlider setFloatValue:0.0f];
    [hueSlider setEnabled:NO];
    [hueField setEnabled:NO];
  }	else {
    float hueValue = ((float)hue / 182.04166666666666f) - 180.0f;
    [hueSlider setFloatValue:hueValue];
    [hueSlider setEnabled:YES];
    [hueField setEnabled:YES];
  }
	
  if (saturation == 0) {
    [saturationSlider setFloatValue:0.0f];
    [saturationSlider setEnabled:NO];
    [saturationField setEnabled:NO];
  } else {
    float saturationValue = (float)saturation / 655.35f;
    [saturationSlider setFloatValue:saturationValue];
    [saturationSlider setEnabled:YES];
    [saturationField setEnabled:YES];
  }
	
  if (contrast == 0) {
    [contrastSlider setFloatValue:0.0f];
    [contrastSlider setEnabled:NO];
    [contrastField setEnabled:NO];
  } else {
    float contrastValue = (float)contrast / 655.35f;
    [contrastSlider setFloatValue:contrastValue];
    [contrastSlider setEnabled:YES];
    [contrastField setEnabled:YES];
  }
	
  if (sharpness == 0) {
    [sharpnessSlider setFloatValue:0.0f];
    [sharpnessSlider setEnabled:NO];
    [sharpnessField setEnabled:NO];
  } else {
    float sharpnessValue = (float)sharpness / 655.35f;
    [sharpnessSlider setFloatValue:sharpnessValue];
    [sharpnessSlider setEnabled:YES];
    [sharpnessField setEnabled:YES];
  }
	
  [self _updateTextFields];
}

- (void)_updateTextFields
{
  float brightnessValue = [brightnessSlider floatValue];
  float hueValue = [hueSlider floatValue];
  float saturationValue = [saturationSlider floatValue];
  float contrastValue = [contrastSlider floatValue];
  float sharpnessValue = [sharpnessSlider floatValue];
	
  [brightnessField setFloatValue:brightnessValue];
  [hueField setFloatValue:hueValue];
  [saturationField setFloatValue:saturationValue];
  [contrastField setFloatValue:contrastValue];
  [sharpnessField setFloatValue:sharpnessValue];
}

@end

@implementation XMSGDeviceNameIndex

- (id)init
{
  [self doesNotRecognizeSelector:_cmd];
  [self release];
  return nil;
}

- (id)_initWithDeviceIndex:(unsigned)theDeviceIndex inputNameIndex:(unsigned)theInputNameIndex
{
  self = [super init];
	
  deviceIndex = theDeviceIndex;
  inputNameIndex = theInputNameIndex;
	
  return self;
}

- (unsigned)_deviceIndex
{
  return deviceIndex;
}

- (unsigned)_inputNameIndex
{
  return inputNameIndex;
}

@end

static pascal OSErr XMSGProcessGrabDataProc(SGChannel channel,
                                            Ptr data,
                                            long length,
                                            long *offset,
                                            long channelRefCon,
                                            TimeValue time,
                                            short writeType,
                                            long refCon)
{
#pragma unused(channel, offset, channelRefCon, writeType)
	
  ComponentResult err = noErr;
	
  XMSequenceGrabberVideoInputModule *module = (XMSequenceGrabberVideoInputModule *)refCon;
  err = [module _processGrabData:data length:length time:time];
	
  return err;
}

static void XMSGProcessDecompressedFrameProc(void *decompressionTrackingRefCon,
                                             OSStatus result,
                                             ICMDecompressionTrackingFlags decompressionTrackingFlags,
                                             CVPixelBufferRef pixelBuffer, 
                                             TimeValue64 displayTime,
                                             TimeValue64 displayDuration, 
                                             ICMValidTimeFlags validTimeFlags,
                                             void* reserved, 
                                             void* sourceFrameRefCon)
{   
  if ((kICMDecompressionTracking_EmittingFrame & decompressionTrackingFlags) && pixelBuffer) {
    XMSequenceGrabberVideoInputModule *module = (XMSequenceGrabberVideoInputModule *)sourceFrameRefCon;
    [module _processDecompressedFrame:pixelBuffer];
  }
}
