/*
 * $Id: XMVideoInputModule.h,v 1.16 2007/05/08 15:17:13 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_VIDEO_INPUT_MODULE_H__
#define __XM_VIDEO_INPUT_MODULE_H__

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

#import "XMTypes.h"

@protocol XMVideoInputModule;

/*!
	@typedef	XMVideoInputManager
	@abstract	This protocol declares the methods provided by the VideoInput system 
				for the modules
 
				To add an new VideoInputManager update
				XMMediaTransmitter.m _init() function to add new item to the list.
 **/
@protocol XMVideoInputManager <NSObject>

/*!
	@function   handleGrabbedFrame:(CVPixelBufferRef)frame time:(TimeValue)time;
	@discussion	In order to allow for efficient processing of the grabbed frames, the frame
				have to reside within a CVPixelBuffer structure, encoded using the
				k32ARGBPixelFormat. This output is automatically created as part of an 
				ICMDecompressionSession from the SequenceGrabber data for example
 
				This method should be called on the same thread as -grabFrame is called.
 
	@param		frame	A reference to the frame grabbed.
 **/
- (void)handleGrabbedFrame:(CVPixelBufferRef)frame;

/*!
	@function	noteSettingsDidChangeForModule:(id<XMVideoInputModule>)module
	@discussion	Tells the InputManager that the settings changed for the specific module.
				This method should be called when the settings in a settings dialog change.
				That way, the changes made can be applied immediately.
 
				This method should be called on the main thread.
 
	@param		module	A reference to the module whose settings did change.
 **/
- (void)noteSettingsDidChangeForModule:(id<XMVideoInputModule>)module;

/*!
	@function   handleErrorWithCode:(ComponentResult)errorCode hintCode:(unsigned)hintCode;
	@discussion	Allows the modules to report errors which occured during the
				frame grabbing process. the errorCode should report which
				error occured while the hint code may be used to indicate the place
				where the error occured.
				In case of an error, the module should be capable of continuing
				anyway, do not rely on the grabbing process being aborted.
 
				This method should be called on the same thread as -openInputDevice and
				-grabFrame are called.
	 @param		(ComponentResult)errorCode   
	 @param		(unsigned)hintCode   
 **/
- (void)handleErrorWithCode:(int)errorCode hintCode:(int)hintCode;

@end

/*!
	@typedef	XMVideoInputModule
	@abstract	This protocol declares the methods necessary for any video module to work
				within the XMeeting framework. Since the video handling is done using
				QuickTime, it is necessary that most of the data flow occurs withing the
				QuickTime "world". Therefore, instances working as VideoInputModules
				are required to return the data in the appropriate QuickTime data 
				structures.
 
				All module methods are called from a separate thread unless explicitely
				stated differently. Therefore, the module should not interfere with the
				main thread in order to avoid race conditions.
 **/
@protocol XMVideoInputModule <NSObject>

/*!
	@function	identifier;
	@discussion	Unique, immutable and non-localized identifier of the module.
				This identifier may be used to identify the module.
				This method may be called on every thread, use only immutable strings
				here.
	@result		The unique identifier for this module.
 **/
- (NSString *)identifier;

/*!
	@function   name;
	@discussion	name of the video module. This method may be called
				on every thread, use only immutable strings here.
				The name should be localized if possible.
	
	@result		Returns a name appropriate for this module.
 **/
- (NSString *)name;

/*!
	@function   setupWithInputManager:(id<XMVideoInputManager>)manager;
	@discussion	called to allow proper initialization of the module. The module should
				not claim any unnecessary resources before this method has been called.
	 
				Do not create QuickTime device lists within the initializer for example,
				since the actual modue-manager communication happens on a different
				thread than the main thread.
	 
				The manager argument is a reference to the VideoInputManager where
				the module can send the grabbed frames to and obtain additional information.
 **/
- (void)setupWithInputManager:(id<XMVideoInputManager>)manager;

/*!
	@function   close;
	@discussion	This method is called whenever the module is no longer used and use it
				to release any resources claimed by -setupWithInputManager:.
 **/
- (void)close;

/*!
	@function   inputDevices;
	@discussion	Returns all devices this module is able to support. The device list
				returned is cached externally so that there is no need to optimize
				in case of lengthy operations. This method is only called when really
				needed.
	@result		NSArray	all devices this module is able to support. 
 **/
- (NSArray *)inputDevices;

/*!
	@function   openInputDevice:(NSString *)inputDevice;
	@discussion	Open the device specified with inputDevice and prepare it
				for capturing. 
	 
	 @param     NSString	inputDevice	Name of the device.
	 @result	BOOL		the success of this operation.
	 **/
- (BOOL)openInputDevice:(NSString *)inputDevice;

/*!
	@function   closeInputDevice
	@discussion	Closes the device used and cleanup any resources no longer used
	@result		BOOL		the success of this operation.
	 **/
- (BOOL)closeInputDevice;

/*!
	@function   setInputFrameSize:(NSSize)frameSize;
	@discussion	tells the receiver to produce frames with dimensions for the given video size
	
	This method may be called during a ongoing grab sequence, so the receiver
	cannot rely on having the same frame size all the time.
	
	This method is guaranteed to be called at least once before any call to -openInputDevice is made.
	 
	@param      XMVideoSize	videoSize	tells the receiver which size is required
	 
	@result		BOOL		return whether the receiver can handle this size or not.
 **/
- (BOOL)setInputFrameSize:(XMVideoSize)videoSize;

/*!
	@function   setFrameGrabRate:(unsigned)frameGrabRate;
	@discussion	Tells the module which framerate currently is active.
	 
	 This method may be called at any time, also during
	 active grab sessions.
	 
	 This method is guarateed to be called before any call to
	 -openInputDevice: is made.
	 
	 frameGrabRate is guaranteed to be greater than zero and no larger
	 than 30.
	 
	 @param      unsigned		frameGrabRate	framerate.
	 
	 @result		BOOL		success status.
 **/
- (BOOL)setFrameGrabRate:(unsigned)frameGrabRate;

/*!
	@function   grabFrame;
	@discussion	Gives the module time to grab a frame.
	 
	Due to the different architecture which QuickTime uses,
	it is not possible and neither desirable to have the modules
	directly return a frame. Rather, the modules can send the data
	using the methods of XMVideoInputManager
	 
	Called by Timer from XMMediaTransmiiter.m
	 
	@result		BOOL		success status.
 **/
- (BOOL)grabFrame;

/*!
	@function   descriptionForErrorCode:(unsigned)errorCode device:(NSString *)device;
	@discussion	Return a error description (localized if possible) which
				describes errorCode and hintCode. 
	 
				This method is guaranteed to be called on the main thread.
	 
	@param      unsigned		errorCode
	 
	@result		NSString 		a error description (localized if possible) 
 **/
- (NSString *)descriptionForErrorCode:(int)errorCode hintCode:(int)hintCode device:(NSString *)device;

/*!
	@function	hasSettingsForDevice:(NSString *)device;
	@discussion	Returns whether this module has any adjustable settings for the given device
				or not. If the device parameter is nil, return whether this module has
				general settings that apply for all kind of devices.
 
				This method will be called on the main thread.
 
	@param		NSString	device	Device for which settings are requested or nil in case
									general settings are requested.
 
	@result		BOOL	YES, if this module has settings for the given device, NO otherwise.
  **/
- (BOOL)hasSettingsForDevice:(NSString *)device;

/*!
	@function	requiresSettingsDialogWhenDeviceOpens;
	@discussion	If the module requires a settings dialog to show up when one of its devices
				has been opened, return YES here. This might apply for a still image device
				for example, where the user might choose which picture to send every time this
				module is activated.
 
				It is not guaranteed that a settings dialog will be displayed if
				this method returns YES, though. The module should work properly even without
				a settings dialog being displayed and adjusted. (For example, returning a black
				frame)
 
				This method will be called on the main thread.
 
				The value returned here may change during the lifetime of this module.
	@param		NSString	device	The device in question.
	@result		BOOL	YES, if an settings dialog should be displayed, NO otherwise.
 **/
- (BOOL)requiresSettingsDialogWhenDeviceOpens:(NSString *)device;

/*!
	@function	getInternalSettings;
	@discussion	This method return the current settings of the module. Only the module
				itself needs to be able to interpret the settings returned here.
				If this module does not have any internal settings, return nil.
 
				This method will be called on the main thread.
 
	@result		NSData	The Settings of this module, or nil if this module does not have any
						settings.
 **/
- (NSData *)internalSettings;

/*!
	@function	applyInternalSettings:(NSData *)settings;
	@discussion	Asks the module to apply the settings returned by -getInternalSettings.
 
				This method will not be called on the main thread but on the same thread as
				-grabFrame is called.
 
	@param		The settings previously returned by -getInternalSettings
 **/
- (void)applyInternalSettings:(NSData *)settings;

/*!
	@function	getSettings;
	@discussion	Returns permament settings of this module in a data structure which
				can be saved on disk. (UserDefaults for example) Therefore, only standard
				data types should be contained in the dictionary returned.
				If this module does not have permament settings, return nil.
 
				This method will be called on the main thread.
 
	@result		NSDictionary	A dictionary containing the settings for this module.
 **/
- (NSDictionary *)permamentSettings;

/*!
	@function	setSettings:(NSDictionary *)settings;
	@discussion	Instructs the module to apply the settings contained in the dictionary.
				If the settings of this module change as a result of this operation,
				the module should call -noteSettingsDidChangeForModule:.
 
				This method will be called on the main thread.
 
	@param		settings	A dictionary containing the settings for this module
	@result		BOOL		The success of this operation.
 **/
- (BOOL)setPermamentSettings:(NSDictionary *)settings;

/*!
	@function	settingsViewForDevice:(NSString *)device;
	@discussion	Returns a view to adjust the settings provided by this module. If the user
				changes any settings in the view, -noteSettingsDidChangeForModule of the
				input manager should be called.
 
				This method will be called on the main thread.
 
	@param		device	A reference to the device for which the settings apply, or nil if
						the settings apply to no specific device.
 **/
- (NSView *)settingsViewForDevice:(NSString *)device;

/*!
	@function	setDefaultSettingsForDevice:(NSString *)device
	@discussion	Resets the settings applicable for device to the default values.
				If device is nil, the general settings applicable to all devices
				should be reset to default values.
				If the settings of this module change as a result of this operation,
				the module should call -noteSettingsDidChangeForModule:.
 
				This method will be called on the main thread.
	@param		NSString	device	The device in question
 **/
- (void)setDefaultSettingsForDevice:(NSString *)device;

@end

/*!
	@function	XMCreatePixelBuffer(XMVideoSize videoSize);
	@discussion	Creates a CVPixelBuffer for a given video size that
				is configured for best performance within the XMeeting
				video system.
 
	@param		XMVideoSize	videoSize	The desired video size for the buffer.
	@result		CVPixelBufferRef	The created pixel buffer
 **/
CVPixelBufferRef XMCreatePixelBuffer(XMVideoSize videoSize);

/*!
    @function   XMClearPixelBuffer(CVPixelBufferRef pixelBuffer);
    @discussion Clears the pixel buffer (zeros out the data)
 
    @param      CVPixelBuffer pixelBuffer   The pixel buffer to clear
 **/
void XMClearPixelBuffer(CVPixelBufferRef pixelBuffer);

/*!
	@function	XMCreateImageCopyContext(void *src, unsigned srcWidth, unsigned srcHeight,
										 unsigned bytesPerRow, OSType srcPixelFormat,
										 CVPixelBufferRef dstPixelBuffer,
										 XMImageScaleOperation imageScaleOperation);
	@discussion	Creates a context for copying/scaling a given source into the
				destination pixel buffer. This context guarantees best speed performance
				for the desired operation. This context has to be used when calling
				XMCopyImageIntoPixelBuffer().
 
	@param	unsigned	srcWidth	The width (in pixels) of the source image
	@param	unsigned	srcHeight	The height (in pixels) of the source image
    @param  unsigned    xOffset     Offset (in pixels) in x-direction into the original image
    @param  unsigned    yOffset     Offset (in pixels) in y-direction into the original image
	@param	unsigned	bytesPerRow	The number of bytes per row.
	@param	OSType		srcPixelFormat	The pixel format of the source. Currently supported
										pixel formats are:
										k32ARGBPixelFormat,
										k24RGBPixelFormat,
										k16BE555PixelFormat
										k8IndexedPixelFormat;
										Other pixel formats may be added in future
	@param	CGDirectPaletteRef	colorPalette	The color palette to be used when
												pixel format is k8IndexedPixelFormat.
												If you pass NULL, the default palette
												will be used.
												If you pass a palette here, you must
												release the palette, as the context
												does make a copy from the palette.
	@param	CVPixelBufferRef	dstPixelBuffer	The destionation pixel buffer. Use a buffer
												obtained from XMCreatePixelBuffer()
	@param	XMImageScaleOperation	imageScaleOperation	Defines how the image shall be scaled
									(if needed). 
 
									XMImageScaleOperation_NoScaling does not scale
									the source image. If it is too small, it is placed in the center
									of the image. If it is too large, only the upper left portion
									of the image will be copied.
 
									XMImageScaleOperation_ScaleProportionally will scale the image
									while keeping the proportions. The image is copied over the
									destination pixel buffer, thus the previous image is not altered
									where the source image does not cover. A pixel buffer created
									with XMCreatePixelBuffer will usually be zeroed (black background).
 
									XMImageScaleOperation_ScaleToFit will scale the image so that
									the whole destination buffer is covered by the source image.
 
	@result	void*	The freshly created image copy context
 **/
void *XMCreateImageCopyContext(unsigned srcWidth, unsigned srcHeight,
                               unsigned xOffset, unsigned yOffset,
							   unsigned bytesPerRow, OSType srcPixelFormat,
							   CGDirectPaletteRef colorPalette,
							   CVPixelBufferRef dstPixelBuffer,
							   XMImageScaleOperation imageScaleOperation);

/*!
	@function XMDisposeImageCopyContext(void *imageCopyContext);
	@discussion	Disposes the context created by XMCreateImageCopyContext().
 
	@param	void*	imageCopyContext	The context to dispose
 **/
void XMDisposeImageCopyContext(void *imageCopyContext);

/*!
	@function	XMCopyImageIntoPixelBuffer(void *src, CVPixelBufferRef dstPixelBuffer,
										   void *imageCopyContext);
	@discussion	Copies the source image contained in src to the destionation buffer
				according to the settings defined in the context. The context
				is created by calling XMCreateImageCopyContext().
 
	@param	void*				src					The source image buffer
	@param	CVPixelBufferRef	dstPixelBuffer		The destination pixel buffer.
	@aram	void*				imageCopyContext	The context to be used for this operation
 
	@result		Returns the success of this operation
 **/
BOOL XMCopyImageIntoPixelBuffer(void *src, CVPixelBufferRef dstPixelBuffer,
								void *imageCopyContext);

void XMRGBA2ARGB(void *buffer, unsigned width, unsigned height, unsigned bytesPerRow);

#endif // __XM_VIDEO_INPUT_MODULE_H__

