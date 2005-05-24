/*
 * $Id: XMVideoManager.mm,v 1.3 2005/05/24 15:21:02 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <unistd.h>

#import "XMVideoManager.h"
#import "XMLocalVideoView.h"
#import "XMPrivate.h"
#import "XMBridge.h"

NSString *XMNotification_DidStartVideoGrabbing = @"XMeeting_DidStartVideoGrabbingNotification";
NSString *XMNotification_DidStopVideoGrabbing = @"XMeeting_DidEndVideoGrabbingNotification";
NSString *XMNotification_DidReadVideoFrame = @"XMeeting_DidReadVideoFrameNotification";
NSString *XMNotification_DidUpdateVideoDeviceList = @"XMeeeting_DidUpdateVideoDeviceList";

/* Declaration of the used DataProc (See below) */
OSErr XM_SGDataProc(SGChannel c, 
					Ptr p,
					long len,
					long *offset,
					long chRefCon,
					TimeValue time,
					short writeType, 
					long refCon);

/*
 * This is a simple object wrapper used for transporting
 * the needed messages/codes from the grabber thread to the main
 * thread
 */
@interface XMGrabError : NSObject
{
	NSString *message;
	int code;
}

- (id)initWithMessage:(NSString *)msg code:(int)errorCode;

- (NSString *)message;
- (int)code;

@end

@interface XMVideoManager (PrivateMethods)

- (id)_init;

- (void)_noteVideoFrameRead:(NSBitmapImageRep *)rep;

- (BOOL)_initializeComponentAndChannel;
- (void)_closeComponentAndChannel;

- (BOOL)_getDeviceList;
- (void)_disposeDeviceList;

- (BOOL)_setSelectedDevice:(NSString *)device;

	/* setup and cleanup methods for video grabbing */
- (BOOL)_startGrabbing;
- (void)_stopGrabbing;

	/* cleanup, done in the main thread */
- (void)_noteGrabEnd;

	/* posts the relevant notification */
- (void)_noteVideoFrameRead:(NSBitmapImageRep *)rep;

	/* informs the delegate when an error occurred (if any delegate is set */
- (void)_noteError:(NSString *)errorMessage code:(int)errorCode;
- (void)_noteError:(XMGrabError *)grabError;

	/* Runs the grabbing sequence */
- (void)_grabThread;

	/* moves the video frame from QuickTime to the offscreen GWorld */
- (OSErr)_decompressToGWorld:(Ptr)p length:(long)len;

	/* Tries to send the currently grabbed frame to shm */
- (void)_sendCurrentFrameIfPossible;

	/* Renders a scaled bitmap representation from still image and sends it to SharedMemory */
- (void)_sendStillImageIfNeeded;

	/* Restarts the Sequence grabbing process at periodic intervals */
- (void)_restartSequenceGrabbing:(NSTimer *)timer;

@end

@implementation XMVideoManager

#pragma mark Class Methods

+ (XMVideoManager *)sharedInstance
{
	static XMVideoManager *sharedInstance = nil;
	
	if(sharedInstance == nil)
	{
		sharedInstance = [[XMVideoManager alloc] _init];
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
	
	// These values are not initiated until actually used
	delegate = nil;
	
	view = nil;
	drawSequence = NULL;
	imageSize = 0;
	
	component = NULL;
	channel = NULL;
	decomSequence = NULL;
	gWorld = NULL;
	isGrabbing = NO;
	
	deviceList = NULL;
	deviceNames = nil;
	
	videoSize = XMVideoSize_NoVideo;
	
	//stillImage = nil;
	//imgRep = nil;
	
	fps = 10;
	
	remoteVideoFrame = nil;
	
	// making sure that the underlying OPAL system is properly initialised
	initOPAL();
	
	return self;
}

- (void)dealloc
{
	// stopping the grabbing sequence if needed
	[self stopGrabbing];
	
	// disposing all used QuickTime resources
	[self _disposeDeviceList];
	[self _closeComponentAndChannel];
	
	/* unregistering the delegate */
	[self setDelegate:nil];
	
	/* releasing all objects */
	[view release];
	//[stillImage release];
	//[imgRep release];
	
	/* completing deallocation */
	[super dealloc];
}

#pragma mark Public Interface Methods

- (NSBitmapImageRep *)remoteVideoFrame
{
	return remoteVideoFrame;
}

- (void)updateDeviceList
{
	/*
	 * We do a lazy approach here and simply remove the
	 * cached device list. The next time this list is
	 * queried, the list is updated
	 */
	[self _disposeDeviceList];
}

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)theDelegate
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if(delegate)
	{
		[nc removeObserver:delegate name:XMNotification_DidStartVideoGrabbing object:self];
		[nc removeObserver:delegate name:XMNotification_DidStopVideoGrabbing object:self];
		[nc removeObserver:delegate name:XMNotification_DidReadVideoFrame object:nil];
		[nc removeObserver:delegate name:XMNotification_DidUpdateVideoDeviceList object:self];
	}
	
	delegate = theDelegate;
	
	if(delegate)
	{
		
		if([delegate respondsToSelector:@selector(videoManagerDidStartGrabbing:)])
		{
			[nc addObserver:delegate selector:@selector(videoManagerDidStartGrabbing:)
					   name:XMNotification_DidStartVideoGrabbing object:self];
		}
		
		if([delegate respondsToSelector:@selector(videoManagerDidStopGrabbing:)])
		{
			[nc addObserver:delegate selector:@selector(videoManagerDidStopGrabbing:)
					   name:XMNotification_DidStopVideoGrabbing object:self];
		}
		
		if([delegate respondsToSelector:@selector(videoManagerDidReadVideoFrame:)])
		{
			[nc addObserver:delegate selector:@selector(videoManagerDidReadVideoFrame:)
					   name:XMNotification_DidReadVideoFrame object:nil];
		}
		if([delegate respondsToSelector:@selector(videoManagerDidUpdateVideoDeviceList:)])
		{
			[nc addObserver:delegate selector:@selector(videoManagerDidUpdateVideoDeviceList:)
					   name:XMNotification_DidUpdateVideoDeviceList object:self];
		}
	}
}

- (BOOL)startGrabbing
{	
	BOOL result;
	
	@synchronized(self)
	{
		if(isGrabbing)
		{
			return YES;
		}
		
		result = [self _startGrabbing];
		
		if(result)
		{
			// starting the grab thread
			isGrabbing = YES;
			[NSThread detachNewThreadSelector:@selector(_grabThread)
									 toTarget:self
								   withObject:nil];
		}
	}
	
	if(result)
	{
		// notifying the success
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidStartVideoGrabbing object:self];
	}
	
	return result;
}

- (void)stopGrabbing
{
	@synchronized(self)
	{
		isGrabbing = NO;
	}
}

- (BOOL)isGrabbing
{
	return isGrabbing;
}

- (NSArray *)availableDevices
{	
	//SGDeviceListRecord *record;	
	NSMutableArray *array;		// buffer for constructing the list
	int i;
	
	if(deviceList == NULL)		// we have to construct a new list
	{
		SGDeviceListRecord *record;
		
		if(![self _getDeviceList])	// getting the device list failed
		{
			// simply returning an empty array
			return [NSArray array];
		}
		
		record = (*deviceList);
		
		// using the devices count as a first assumption about the size of the array
		array = [[NSMutableArray alloc] initWithCapacity:record->count];
		
		for(i = 0; i < record->count; i++)
		{
			// structure containing informations about a device
			SGDeviceName deviceName = record->entry[i];
			
			if(deviceName.inputs != NULL) // this device has input possibilities
			{
				int j;
				SGDeviceInputListRecord *inputListRecord = *deviceName.inputs;
				
				for(j = 0; j < inputListRecord->count; j++)
				{
					// this structure contains the actual human understandable name
					SGDeviceInputName inputName = inputListRecord->entry[j];
					NSString *name = [[NSString alloc] initWithCString:(const char*)inputName.name];
					
					// adding the name to the object
					[array addObject:name];
					[name release];
				}
			}
		}
		
		deviceNames = [array copy];
		[array release];
		
		// finally, notifying interested parties
		[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidUpdateVideoDeviceList object:self];
	}
	
	// returing the stored names
	return deviceNames;
}

- (NSString *)selectedDevice
{	
	SGDeviceListRecord *record;
	SGDeviceName deviceName;
	NSString *name;
	
	if(deviceList == NULL)
	{
		if(![self _getDeviceList])
		{
			return nil;
		}
	}
	
	record = *deviceList;
	deviceName = record->entry[record->selectedIndex];
	if(deviceName.inputs == NULL)
	{
		[self _noteError:@"Selected device contains no inputs" code:-1];
		name = nil;
	}
	else
	{
		SGDeviceInputListRecord *inputListRecord = *(deviceName.inputs);
		SGDeviceInputName inputName = inputListRecord->entry[inputListRecord->selectedIndex];
		name = [NSString stringWithCString:(const char*)inputName.name];
	}
	
	return name;
}

- (BOOL)setSelectedDevice:(NSString *)nameOfDeviceToSelect
{
	BOOL result;
	
	if(isGrabbing)
	{
		@synchronized(self)
	{
			[self _stopGrabbing];
			result = [self _setSelectedDevice:nameOfDeviceToSelect];
			[self _startGrabbing];
	}
	}
	else
	{
		result = [self _setSelectedDevice:nameOfDeviceToSelect];
	}
	
	return result;
}

- (NSImage *)stillImage
{
	//return stillImage;
	return nil;
}

- (void)setStillImage:(NSImage *)image
{
	@synchronized(self)
	{
		/*
		if(imgRep)
		{
			[imgRep release];
			imgRep = nil;
		}
		
		NSImage *old = stillImage;
		
		stillImage = [image copy];
		
		[old release];
		
		if(stillImage)
		{
			[stillImage setScalesWhenResized:YES];
		}
		//[self _sendStillImageIfNeeded];
		 */
	}
}

- (int)fps
{
	return fps;
}

- (void)setFps:(int)framesPerSecond
{
	fps = framesPerSecond;
}

#pragma mark Private Methods

/* store the new image and post a notification */

- (void)_noteVideoFrameRead:(NSBitmapImageRep *)rep
{
	[remoteVideoFrame release];
	remoteVideoFrame = [rep retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidReadVideoFrame object:self];
}

- (BOOL)_initializeComponentAndChannel
{
	ComponentResult err;
	
	// Any errors occuring in this method are either a fatal error
	// (such as EnterMovies() failure and must be treated in a different
	// way as the other ones, or they represent a sort of errors such
	// as channel creation failure due to a device not plugged int.
	// Anyway, no errors will be recorded through _noteError:code:
	// in this method
	
	/* before using the MovieToolbox, call EnterMovies() to be sure */
	err = EnterMovies();
	if(err != noErr)
	{
		NSLog(@"EnterMovies() failed: %d", err);
		return NO;
	}
	
	/* Opens a connection to the SequenceGrabber component */
	component = OpenDefaultComponent(SeqGrabComponentType, 0);
	if(component == NULL)
	{
		NSLog(@"OpenDefaultComponent() failed");
		return NO;
	}
	
	/* initializes the component */
	err = SGInitialize(component);
	if(err != noErr)
	{
		NSLog(@"SGInitialize() failed: %d", err);
		[self _closeComponentAndChannel];
		return NO;
	}
	
	/* Telling the component that we are not storing any data
		* in a movie file, we are just making a preview operation
		* (from QuickTime's point of view of course)
		*/
	err = SGSetDataRef(component, 0, 0, seqGrabDontMakeMovie);
	if(err != noErr)
	{
		NSLog(@"SGSetDataRef() failed: %d", err);
		[self _closeComponentAndChannel];
		return NO;
	}
	
	/* Initializing a channel for getting video data */
	err = SGNewChannel(component, VideoMediaType, &channel);
	if(err != noErr)
	{
		NSLog(@"SGNewChannel failed(): %d", err);
		[self _closeComponentAndChannel];
		return NO;
	}
	
	// Telling QuickTime that we are performing a record operation
	// Although we are not actually recording anything, the code
	// won't work in Preview mode
	err = SGSetChannelUsage(channel, seqGrabRecord);
	if(err != noErr)
	{
		NSLog(@"SGSetChannelUsage() failed: %d", err);
		[self _closeComponentAndChannel];
		return NO;
	}
	
	/* Now we have successfully initialized the required component and channel */
	return YES;
}

- (void)_closeComponentAndChannel
{
	ComponentResult err;
	
	// disposing the channel (if needed)
	if(channel != NULL)
	{
		err = SGDisposeChannel(component, channel);
		if(err != noErr)
		{
			[self _noteError:@"Disposing the channel failed" code:err];
		}
		channel = NULL;
	}
	
	// closing the component
	if(component != NULL)
	{
		err = CloseComponent(component);
		if(err != noErr)
		{
			[self _noteError:@"Closing the component failed" code:err];
		}
		component = NULL;
	}
}

- (BOOL)_getDeviceList
{
	ComponentResult err;
	
	if(component == NULL)
	{
		// We need to initialize the component and channel first
		if(![self _initializeComponentAndChannel])
		{
			return NO;
		}
	}
	
	// We still have an active device list and need to dispose it first
	if(deviceList != NULL)
	{
		[self _disposeDeviceList];
	}
	
	// Now getting the new device list
	err = SGGetChannelDeviceList(channel, sgDeviceListIncludeInputs, &deviceList);
	if(err != noErr)
	{
		return NO;
	}
	
	return YES;
}

- (void)_disposeDeviceList
{
	ComponentResult err;
	
	if(deviceList != NULL)
	{
		err = SGDisposeDeviceList(component, deviceList);
		deviceList = NULL;
		
		if(err != noErr)
		{
			[self _noteError:@"Disposing the device list failed" code:err];
		}
		
		// also releasing the cached name array
		[deviceNames release];
		deviceNames = nil;
	}
}

- (BOOL)_setSelectedDevice:(NSString *)nameOfDeviceToSelect
{
	SGDeviceListRecord *record;
	int i;
	
	// sanity check first
	if(nameOfDeviceToSelect == nil)
	{
		return NO;
	}
	
	if(deviceList == NULL)	// we have to get the actual device list before being able to do anything
	{
		if(![self _getDeviceList])
		{
			return NO;
		}
	}
	
	record = *deviceList;
	
	for(i = 0; i < record->count; i++)
	{
		SGDeviceName deviceName = record->entry[i];
		SGDeviceInputListRecord *inputListRecord;
		SGDeviceInputName inputName;
		NSString *theName;
		int j;
		
		if(deviceName.inputs == NULL)	// this device contains no input devices
		{
			continue;
		}
		inputListRecord = *(deviceName.inputs);
		
		// we have to check all input devices's names whether they correspond to the device name to select
		for(j = 0; j < inputListRecord->count; j++)
		{
			inputName = inputListRecord->entry[j];
			theName = [[NSString alloc] initWithCString:(const char *)inputName.name];
			
			if([theName isEqualToString:nameOfDeviceToSelect]) // now we have a match
			{
				ComponentResult err;
				
				// we have to use the name of the device, not the input device itself
				err = SGSetChannelDevice(channel, deviceName.name);
				if(err != noErr)
				{
					//[self _noteError:@"Changing the channel device failed" code:err];
					[theName release];
					return NO;
				}
				
				// now we can set the actual input device by its index
				err = SGSetChannelDeviceInput(channel, j);
				if(err != noErr)
				{
					//[self _noteError:@"Changing the inputs number failed" code:err];
					[theName release];
					return NO;
				}
				
				// changing the selected needs the device list to be updated when used the next time
				[self _disposeDeviceList];
				[theName release];
				return YES;
			}
			
			[theName release];
		}
	}
	
	// the desired device doesn't exist
	return NO;
}

- (BOOL)_startGrabbing
{
	OSErr err;
	ImageDescriptionHandle imageDesc;
	MatrixRecord scaleMatrix;
	Rect destRect = {0,0}, sourceRect = {0,0};
	NSRect viewBounds;
	
	if(view != NULL)
	{
		viewBounds = [view bounds];
	}
	
	// initializing the component and channel if needed
	if(component == NULL)
	{
		if(![self _initializeComponentAndChannel])
		{
			return NO;
		}
	}
	
	// setting the data proc accordingly
	// this proc is used to decompress the data from the video driver
	// to the offscreen GWorld
	// Due to the FireWire bug in QuickTime which causes grabbing from
	// iSight and other FireWire devices to unregister the data proc
	// after a while, we need to set this data proc everytime we
	// reset the connection
	err = SGSetDataProc(component,NewSGDataUPP(&XM_SGDataProc), (long)self);
    if(err != noErr)
	{
		NSLog(@"SGSetDataProc() failed: %d", err);
		[self _closeComponentAndChannel];
		return NO;
	}
	
	// determining which size to grab
	// if we are not in a call, we use the size of the associated view as the
	// grab size. If there is no view, we simply grab QCIF size since this
	// ist most memory efficient. We do have to start grabbing since later,
	// we might start a call and we need to detect this.
	if(videoSize == XMVideoSize_NoVideo)
	{
		if(view != NULL)
		{
			destRect.bottom = viewBounds.size.height;
			destRect.right = viewBounds.size.width;
		}
		else
		{
			// QCIF size
			destRect.bottom = 144;
			destRect.right = 176;
		}
	}
	else if(videoSize == XMVideoSize_QCIF) // we are in a QCIF call
	{
		destRect.bottom = 144;
		destRect.right = 176;
	}
	else if(videoSize == XMVideoSize_CIF) // we are in a CIF call
	{
		destRect.bottom = 288;
		destRect.right = 352;
	}
	else	// no known video format, simply aborting
	{
		return NO;
	}
	
	// cleaning up from previous calls if needed
	if(gWorld != NULL)
	{
		DisposeGWorld(gWorld);
		gWorld = NULL;
	}
	
	// creating a new gWorld for this grab sequence
	err = QTNewGWorld(&gWorld,
					  k32ARGBPixelFormat,
					  &destRect,
					  0,
					  NULL,
					  0);
	if(err != noErr)
	{
		NSLog(@"QTNewGWorld() failed: %d", err);
		return NO;
	}
	
	// lock the pixmap and make sure it's locked because
    // we can't decompress into an unlocked PixMap
    if(!LockPixels(GetPortPixMap(gWorld)))
    {
		NSLog(@"LockPixels() failed");
		return NO;
    }
	
	// Telling QuickTime that we use our own GWorld for decompressing
	err = SGSetGWorld(component, gWorld, GetMainDevice());
	if(err != noErr)
	{
		[self _noteError:@"Setting the SeqGrab GWorld failed" code:err];
		return NO;
	}
	
	// Telling QuickTime which size we want to grab
	// QuickTime then adjusts the data it gets from the device driver
	// to the nearest match. We still have to rescale it down to
	// destRect's size (done in the dataProc)
	err = SGSetChannelBounds(channel, &destRect);
	if(err != noErr)
	{
		[self _noteError:@"Setting component bounds failed" code:err];
		return NO;
	}
	
	// preparing the sequence grabbing
	err = SGPrepare(component, false, true);
	if(err != noErr)
	{
		[self _noteError:@"Preparing the record operation failed\nSuspecting video device no longer plugged in" code:err];
		return NO;
	}
	
	// Now, we have start the record operation
	err = SGStartRecord(component);
	if(err != noErr)
	{
		[self _noteError:@"Starting the record operation failed" code:err];
		return NO;
	}
	
	// setting up the decompression sequence which decompresses
	// into the gWorld
	// We first get the dimensions of the frame coming from the device
	// driver
	imageDesc = (ImageDescriptionHandle)NewHandle(0);
	
	err = SGGetChannelSampleDescription(channel, (Handle)imageDesc);
	if(err != noErr)
	{
		NSLog(@"SGGetChannelSampleDescription() failed: %d", err);
		SGStop(component);
		return NO;
	}
	
	// The frame from the device driver needs to be scaled down to the 
	// desired size defined in destRect. This is done by using a
	// scale matrix
	sourceRect.right = (**imageDesc).width;
	sourceRect.bottom = (**imageDesc).height;
	RectMatrix(&scaleMatrix, &sourceRect, &destRect);
	
	// Starting the decompression sequence.
	err = DecompressSequenceBegin(&decomSequence,
								  imageDesc,
								  gWorld,
								  NULL,
								  NULL,
								  &scaleMatrix,
								  srcCopy,
								  NULL,
								  0,
								  codecNormalQuality,
								  bestSpeedCodec);
	
	// we no longer need this handle
	DisposeHandle((Handle)imageDesc);
	imageDesc = nil;
	
	if(err != noErr)
	{
		[self _noteError:@"Setting up the decompression sequence failed" code:err];
		SGStop(component);
		return NO;
	}
	
	// if we have a view attached, we have to prepare the second
	// decompression sequence, this time from the gWorld to the
	// view's graf port itself. The operations are basically the
	// same as above
	if(view != nil)
	{
		PixMapHandle pixMap = GetGWorldPixMap(gWorld);
		
		GetPixBounds(pixMap, &sourceRect);
		drawSequence = 0;
		
		destRect.top = 0;
		destRect.left = 0;
		destRect.bottom = viewBounds.size.height;
		destRect.right = viewBounds.size.width;
		
		// again creating a scale matrix
		RectMatrix(&scaleMatrix, &sourceRect, &destRect);
		
		// getting the image description for the GWorlds PixMap
		err = MakeImageDescriptionForPixMap(pixMap, &imageDesc);
		if(err != noErr)
		{
			//[self _noteError:@"Getting the GWorld's image description failed" code:err];
			if(imageDesc)
			{
				DisposeHandle((Handle)imageDesc);
			}
			SGStop(component);
			return NO;
		}
		
		imageSize = (GetPixRowBytes(pixMap) * (*imageDesc)->height);
		
		// Now setting up the decompressing sequence from GWorld
		// to the XMVideoView's gdPort
		err = DecompressSequenceBegin(&drawSequence,
									  imageDesc,
									  (OpaqueGrafPtr *)[view qdPort],
									  NULL,
									  NULL,
									  &scaleMatrix,
									  ditherCopy,
									  NULL,
									  0,
									  codecNormalQuality,
									  bestSpeedCodec);
		
		DisposeHandle((Handle)imageDesc);
		imageDesc = NULL;
		
		if(err != noErr)
		{
			[self _noteError:@"Setting up the window decompression sequence failed" code:err];
			SGStop(component);
			return NO;
		}
	}
	
	// having come so far, everything is successfully innitialized and started
	return YES;
}

- (void)_stopGrabbing
{
	ComponentResult err;
	
	// stop the record operation
	SGStop(component);
	
	// ending the two decompression sequences
	err = CDSequenceEnd(decomSequence);
	if(err != noErr)
	{
		[self _noteError:@"Ending the decompression Sequence failed" code:err];
	}
	
	if(view)
	{
		err = CDSequenceEnd(drawSequence);
		if(err != noErr)
		{
			[self _noteError:@"Ending the drawing sequence failed" code:err];
		}
	}
	
	// cleaning up no longer used memory
	DisposeGWorld(gWorld);
	gWorld = NULL;
}

- (void)_noteGrabEnd
{	
	// notifying interested parties. The may now call -startGrabbing again
	[[NSNotificationCenter defaultCenter] postNotificationName:XMNotification_DidStopVideoGrabbing object:self];
	
	// telling the view to update it's display
	if(view)
	{
		[view setNeedsDisplay:YES];
	}
}

- (void)_noteError:(NSString *)errorMessage code:(int)code
{
	// creates an instance of XMGrabError and sends this instance to the main thread
	// for further processing
	XMGrabError *error = [[XMGrabError alloc] initWithMessage:errorMessage code:code];
	
	[self performSelectorOnMainThread:@selector(_noteError:) withObject:error waitUntilDone:NO];
	
	[error release];
}

- (void)_noteError:(XMGrabError *)error
{
	// informing the delegate if needed
	if(delegate && [delegate respondsToSelector:@selector(noteVideoManagerError:code:)])
	{
		[delegate noteVideoManagerError:[error message] code:[error code]];
	}
	
	// also logging to the system log (debugging)
	NSLog(@"%@ (%d)", [error message], [error code]);
}

- (void)_grabThread
{
	ComponentResult err;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int autoreleaseCounter = 0;
	int counter = 0;		// workaround for FW-Cam freeze bug
	
	while(isGrabbing == YES)
	{
		if(autoreleaseCounter == 10)
		{
			[pool release];
			pool = [[NSAutoreleasePool alloc] init];
			autoreleaseCounter = 0;
		}
		else
		{
			autoreleaseCounter++;
		}
		
		int sleepDuration;
		
		// sleeping the needed time for grabbing fps frames per second
		sleepDuration = 1000000 / fps;
		usleep(sleepDuration);
		
		// since this is multithreaded, protecting the whole grabbing process
		@synchronized(self)
		{
			// workaround for the FW-Cam freeze bug.
			// We set this flag to NO. If the callback gets called, he
			// sets the flag to YES.
			// If we have 5 NO's in a row, it's time to reset the whole
			// Sequence Grabbing process incl. closing the components etc.
			didCallCallback = NO;
			
			// this function allows QuickTime to Grab the next frame and process it
			// in the data proc below.
			err = SGIdle(component);
			if(err != noErr)
			{
				[self _noteError:@"Frame grabbing failed\nSuspecting the device is no longer plugged in" code:err];
				
				isGrabbing = NO;
				
			}
			else
			{
				if(didCallCallback == NO)	// the callback wasn't called
				{
					counter++;
					
					if((fps > 5 && counter >= fps) || (fps <= 5 && counter == 5))		// it's time to reset the connection
					{
						// it's time to reset the grabbing sequence
						[self _stopGrabbing];
						[self _closeComponentAndChannel];
						[self _startGrabbing];
						
						NSLog(@"SequenceGrabbing sequence reset");
						counter = 0;
					}
				}
				else
				{
					// since the behaviour of SGIdle() is somewhat undefined
					// it may happen that calling SGIdle() will not result in a call
					// to the callback. Therefore we need to reset the counter
					// every time the callback was called.
					counter = 0;
				}
			}
		}
	}
	
	@synchronized(self)
	{
		// ending the grabbing sequence
		[self _stopGrabbing];
		//[self _closeComponentAndChannel];
		
		// if we are in a call, it's time to send a still image
		// (if there is one set)
		/*
		if(imgRep)
		{
			[imgRep release];
			imgRep = nil;
		}
		 */
		//[self _sendStillImageIfNeeded];
	}
	
	// make the cleanup in the main thread for thread safety
	[self performSelectorOnMainThread:@selector(_noteGrabEnd)
						   withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (OSErr)_decompressToGWorld:(Ptr)p length:(long)len
{
	ComponentResult err = noErr;
	
	// signaling the thread that the callback was successfully called
	didCallCallback = YES;
	
	// when we have a GWorld, this means that we also have a decompression
	// sequence into this GWorld. Otherwise, we simply can do nothing
	if(gWorld)
	{
		// we have a GWorld to move the data to, so let's do it
		err = DecompressSequenceFrameWhen(decomSequence,
										  p,
										  len,
										  0,
										  NULL,
										  NULL,
										  NULL);
		if(err != noErr)
		{
			//[self _noteError:@"Decompressing a sequence frame failed" code:err];
			return err;
		}
		
		// The image is now in the gworld and can be processed further.
		
		// When we are in a call, we have to send this data to the SharedMemory frame
		//[self _sendCurrentFrameIfPossible];
		
		// We now mark the XMVideoView to redisplay it's contents
		if(view)
		{
			[view setNeedsDisplay:YES];
		}
	}
	
	return noErr;
}

#pragma mark Methods from XMPrivate.h

- (void)_addLocalVideoView:(XMLocalVideoView *)theView
{
	XMLocalVideoView *old = view;
	
	if(isGrabbing) // this action is not allowed while we are grabbing
	{
		[NSException raise:@"XMeetingInvalidActionException" format:@"Not allowed while video grabbing runs"];
	}
	
	if(view == theView)
	{
		return;
	}
	
	view = [theView retain];
	
	[old release];
}

- (void)_removeLocalVideoView:(XMLocalVideoView *)theView
{
	if(view == theView)
	{
		XMLocalVideoView *old = view;
		
		view = nil;
		
		[old release];
	}
}

- (void)_drawToView:(XMLocalVideoView *)theView
{
	if(view != theView)
	{
		return;
	}
	
	@synchronized(self)
	{
		if(gWorld)
		{
			if(drawSequence)
			{
				ComponentResult err = noErr;
				CodecFlags ignore;
				
				err = DecompressSequenceFrameWhen(drawSequence,
												  GetPixBaseAddr(GetGWorldPixMap(gWorld)),
												  imageSize,
												  0,
												  &ignore,
												  NULL,
												  NULL);
				if(err != noErr)
				{
					//[self _noteError:@"Decompressing to window failed" code:err];
					return;
				}
			}
		}
	}
}

- (BOOL)_handleVideoFrame:(void *)buffer width:(unsigned)width
				   height:(unsigned)height bytesPerPixel:(unsigned)bytesPerPixel
{
	unsigned char *data = (unsigned char *)buffer;
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:&data
					  pixelsWide:width
					  pixelsHigh:height
				   bitsPerSample:8
				 samplesPerPixel:bytesPerPixel
						hasAlpha:NO
						isPlanar:NO
				  colorSpaceName:NSDeviceRGBColorSpace
					 bytesPerRow:width * bytesPerPixel
					bitsPerPixel:8 * bytesPerPixel];
	
	/* performing the rest on the main thread */
	[self performSelectorOnMainThread:@selector(_noteVideoFrameRead:) withObject:rep
						waitUntilDone:NO];
	[rep release];
	
	return YES;
}

/**
 * Copies the current frame from the offscreen GWorld
 * to the buffer specified in the argument.
 * The offscreen GWorld is in argb-format while
 * the buffer to fill will be simple rgb.
 * Therefore, we can simply drop the alpha-part of the
 * pixel.
 **/
- (void)_getFrameData:(void *)buffer
{
}

@end

@implementation XMGrabError

#pragma mark Init & Deallocation Methods

- (id)initWithMessage:(NSString *)msg code:(int)theCode
{
	message = [msg copy];
	code = theCode;
	
	return self;
}

- (void)dealloc
{
	[message release];
	
	[super dealloc];
}

#pragma mark Accessor Methods

- (NSString *)message
{
	return message;
}

- (int)code
{
	return code;
}

@end

#pragma mark QuickTime Callbacks

/*
 * QuickTime data proc for decompressing into the GWorld
 * The actual work is done inside a method from this class.
 *
 * We use a separate data proc since we have better control
 * about the inner workings and can process the compressed
 * data further within the actual grabbing operation.
 */
OSErr XM_SGDataProc(SGChannel c, 
					Ptr p,
					long len,
					long *offset,
					long chRefCon,
					TimeValue time,
					short writeType, 
					long refCon)
{
	// A reference to the class using this proc is sent
	// in refCon
	XMVideoManager *videoManager = (XMVideoManager *)refCon;
	
	return [videoManager _decompressToGWorld:p length:len];
}
