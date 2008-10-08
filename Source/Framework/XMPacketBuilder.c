/*
 * $Id: XMPacketBuilder.c,v 1.11 2008/10/08 21:20:50 hfriederich Exp $
 *
 * Copyright (c) 2005-2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2006 Hannes Friederich. All rights reserved.
 */

#include <QuickTime/QuickTime.h>
#include "XMPacketBuilder.h"
#include "XMBridge.h"

#define kXMPacketBuilderVersion (0x00010001)

typedef struct {
  ComponentInstance	self;
  ComponentInstance	target;
  UInt32				packetGroupRef;
  UInt32				packetRef;
  UInt32				repRef;
} XMPacketBuilderGlobalsRecord, *XMPacketBuilderGlobals;

// Setup required for ComponentDispatchHelper.c
#define RTPPB_BASENAME()			XMPacketBuilder_
#define RTPPB_GLOBALS()				XMPacketBuilderGlobals storage

#define CALLCOMPONENT_BASENAME()	RTPPB_BASENAME()
#define CALLCOMPONENT_GLOBALS()		RTPPB_GLOBALS()

#define COMPONENT_DISPATCH_FILE		"XMPacketBuilderDispatch.h"
#define COMPONENT_UPP_SELECT_ROOT()	RTPPB

#include <CoreServices/Components.k.h>
#include <QuickTime/QTStreamingComponents.k.h>
#include <QuickTime/ComponentDispatchHelper.c>

ComponentResult XMPacketBuilder_Open(XMPacketBuilderGlobals globals,
                                     ComponentInstance self)
{
  ComponentResult	err = noErr;
	
  globals = calloc( sizeof (XMPacketBuilderGlobalsRecord), 1);
  if (!globals) {
    err = memFullErr;
    goto bail;
  }
	
  SetComponentInstanceStorage( self, (Handle)globals );
	
  globals->self  = self;
  globals->target = self;
  globals->packetGroupRef = 1;
  globals->packetRef = 1;
  globals->repRef = 0;
	
bail:
  return err;
}

ComponentResult XMPacketBuilder_Close(XMPacketBuilderGlobals globals,
                                      ComponentInstance	self)
{
  if (globals) {
    free (globals);
  }
	
  return noErr ;
}

ComponentResult XMPacketBuilder_Version(XMPacketBuilderGlobals globals)
{
	return kXMPacketBuilderVersion;
}

ComponentResult XMPacketBuilder_Target(XMPacketBuilderGlobals globals,
									   ComponentInstance target)
{	
  printf("XMPacketBuilder_Target called\n");
  globals->target = target;
  return noErr;
}

// PacketBuilder stuff

ComponentResult XMPacketBuilder_BeginPacketGroup(XMPacketBuilderGlobals globals,
                                                 SInt32 inFlags,
                                                 UInt32 inTimeStamp,
                                                 RTPPacketGroupRef *outPacketGroup)
{
  ComponentResult err = noErr;
	
  if (outPacketGroup != NULL) {
    *outPacketGroup = (RTPPacketGroupRef)globals->packetGroupRef;
    globals->packetGroupRef++;
  } else {
    err = paramErr;
    goto bail;
  }

  _XMSetTimeStamp(2, inTimeStamp);
	
bail:
  return err;
}

ComponentResult XMPacketBuilder_BeginPacket(XMPacketBuilderGlobals globals,
                                            SInt32 inFlags,
                                            RTPPacketGroupRef inPacketGroup,
                                            UInt32 inPacketMediaDataLength,
                                            RTPPacketRef *outPacket)
{
  ComponentResult err = noErr;
	
  if (outPacket != NULL) {
    *outPacket = (RTPPacketRef)globals->packetRef;
    globals->packetRef++;
  } else {
    err = paramErr;
    goto bail;
  }

bail:
  return err;
}

ComponentResult XMPacketBuilder_EndPacket(XMPacketBuilderGlobals globals,
                                          SInt32 inFlags,
                                          RTPPacketGroupRef inPacketGroup,
                                          RTPPacketRef inPacket,
                                          UInt32 inTransmissionTimeOffset,
                                          UInt32 inDuration)
{
  if ((int)inPacket != (globals->packetRef-1)) {
    printf("ERROR PacketRef\n");
  }
  bool hasMarkerBitSet = (inFlags & 1);
  _XMSendPacket(2, hasMarkerBitSet);
  return noErr;
}

ComponentResult XMPacketBuilder_EndPacketGroup(XMPacketBuilderGlobals globals,
                                               SInt32 inFlags,
                                               RTPPacketGroupRef inPacketGroup)
{
  return noErr;
}

ComponentResult XMPacketBuilder_AddPacketLiteralData(XMPacketBuilderGlobals globals,
                                                     SInt32 inFlags,
                                                     RTPPacketGroupRef inPacketGroup,
                                                     RTPPacketRef inPacket,
                                                     UInt8 *inData,
                                                     UInt32 inDataLength,
                                                     RTPPacketRepeatedDataRef *outDataRef)
{
  ComponentResult err = noErr;
	
  if (outDataRef != NULL) {
    printf("RTPPacketRepeatedDataRef *dataRef != NULL\n");
    err = paramErr;
    goto bail;
  }
	
  _XMAppendData(2, (void *)inData, (unsigned)inDataLength);
	
bail:
  return err;
}

ComponentResult XMPacketBuilder_AddPacketRepeatedData(XMPacketBuilderGlobals globals,
                                                      SInt32 inFlags,
                                                      RTPPacketGroupRef inPacketGroup,
                                                      RTPPacketRef inPacket,
                                                      RTPPacketRepeatedDataRef inDataRef)
{
  return paramErr;
}

ComponentResult XMPacketBuilder_AddPacketSampleData(XMPacketBuilderGlobals globals,
                                                    SInt32 inFlags,
                                                    RTPPacketGroupRef inPacketGroup,
                                                    RTPPacketRef inPacket,
                                                    RTPMPSampleDataParams *inSampleDataParams,
                                                    UInt32 inSampleOffset,
                                                    UInt32 inSampleDataLength,
                                                    RTPPacketRepeatedDataRef *outDataRef)
{
  ComponentResult err = noErr;
	
  if (outDataRef != NULL) {
    printf("RTPPacketRepeatedDataRef Not NULL (2)\n");
    err = paramErr;
    goto bail;
  }
	
  UInt8 *data = (UInt8 *)inSampleDataParams->data;
	
  data += inSampleOffset;
  
  _XMAppendData(2, (void *)data, inSampleDataLength);
	
bail:
  return err;
}

ComponentResult XMPacketBuilder_AddPacketSampleData64 (XMPacketBuilderGlobals globals,
                                                       SInt32 inFlags,
                                                       RTPPacketGroupRef inPacketGroup,
                                                       RTPPacketRef inPacket,
                                                       RTPMPSampleDataParams *inSampleDataParams,
                                                       const UInt64 *inSampleOffset,
                                                       UInt32 inSampleDataLength,
                                                       RTPPacketRepeatedDataRef *outDataRef )
{
  printf("AddPacketSampleData64\n");
	
  return paramErr;
}

ComponentResult XMPacketBuilder_AddRepeatPacket(XMPacketBuilderGlobals globals,
                                                SInt32 inFlags,
                                                RTPPacketGroupRef inPacketGroup,
                                                RTPPacketRef inPacket,
                                                TimeValue inTransmissionOffset,
                                                UInt32 inSequenceNumber )
{
  printf("AddRepeatPacket\n");
  return paramErr;
}

ComponentResult XMPacketBuilder_SetCallback(XMPacketBuilderGlobals globals,
                                            RTPPBCallbackUPP inCallback,
                                            void *inRefCon)
{
  printf("XMPacketBuilder_SetCallback\n");
	
  return paramErr;
}

ComponentResult XMPacketBuilder_GetCallback(XMPacketBuilderGlobals globals,
                                            RTPPBCallbackUPP *outCallback,
                                            void **outRefCon)
{
  printf("XMPacketBuilder_GetCallback\n");
	
  return paramErr;
}

ComponentResult XMPacketBuilder_GetInfo(XMPacketBuilderGlobals globals,
                                        OSType inSelector,
                                        void *ioParams)
{	
  printf("XMPacketBuilder_GetInfo\n");
  return paramErr;
}

ComponentResult XMPacketBuilder_GetPacketSequenceNumber(XMPacketBuilderGlobals globals,
                                                        SInt32 inFlags,
                                                        RTPPacketGroupRef inPacketGroup,
                                                        RTPPacketRef inPacket,
                                                        UInt32 *outSequenceNumber)
{
  printf("XMPacketBuilder_GetPacketSequenceNumber\n");
  *outSequenceNumber = (UInt32)inPacket;
	
  return paramErr;
}

ComponentResult XMPacketBuilder_GetPacketTimeStampOffset(XMPacketBuilderGlobals globals,
                                                         SInt32 inFlags,
                                                         RTPPacketGroupRef inPacketGroup,
                                                         RTPPacketRef inPacket,
                                                         SInt32 *outTimeStampOffset)
{
  printf("XMPacketBuilder_GetPacketTimeStampOffset\n");
  *outTimeStampOffset = 0;
	
  return paramErr;
}

ComponentResult XMPacketBuilder_GetSampleData(XMPacketBuilderGlobals globals,
                                              RTPMPSampleDataParams *inParams,
                                              const UInt64 *inStartOffset,
                                              UInt8 *outDataBuffer,
                                              UInt32 inBytesToRead,
                                              UInt32 *outBytesRead,
                                              SInt32 *outFlags)
{
  printf("XMPacketBuilder_GetSampleData\n");
  *outBytesRead = 0;
	
  return paramErr;
}

ComponentResult XMPacketBuilder_ReleaseRepeatedData(XMPacketBuilderGlobals globals,
                                                    RTPPacketRepeatedDataRef inDataRef)
{
  printf("XMPacketBuuilder_RerleaseRepeatedData\n");
  return paramErr;
}

ComponentResult XMPacketBuilder_SetInfo(XMPacketBuilderGlobals globals,
                                        OSType inSelector,
                                        void *ioParams)
{
  printf("XMPacketBuilder_SetInfo\n");
  return paramErr;
}

ComponentResult XMPacketBuilder_SetPacketSequenceNumber(XMPacketBuilderGlobals globals,
                                                        SInt32 inFlags,
                                                        RTPPacketGroupRef inPacketGroup,
                                                        RTPPacketRef inPacket,
                                                        UInt32 inSequenceNumber)
{
  printf("XMPacketBUilder_SetPacketSequenceNumber\n");
  return paramErr;
}

ComponentResult XMPacketBuilder_SetPacketTimeStampOffset(XMPacketBuilderGlobals globals,
                                                         SInt32 inFlags,
                                                         RTPPacketGroupRef inPacketGroup,
                                                         RTPPacketRef inPacket,
                                                         SInt32 inTimeStampOffset)
{
  printf("XMPacketBuilder_SetPacketTimeStampOffset\n");
  return paramErr;
}

/**
 * Registering the Component
 * This function registers the XMPacketBuilder so that
 * this component can be used as the packet builder for the
 * QuickTime media packetizers
 **/
Boolean XMRegisterPacketBuilder()
{	
  ComponentDescription description;
  Component registeredComponent = NULL;
	
  description.componentType = kXMPacketBuilderComponentType;
  description.componentSubType = kXMPacketBuilderComponentSubType;
  description.componentManufacturer = kXMPacketBuilderComponentManufacturer;
  description.componentFlags = 0;
  description.componentFlagsMask = 0;
	
  // Registering the Component
  ComponentRoutineUPP componentEntryPoint = NewComponentRoutineUPP((ComponentRoutineProcPtr)&XMPacketBuilder_ComponentDispatch);
  registeredComponent = RegisterComponent(&description, componentEntryPoint, 0, 0, 0, 0);
  DisposeComponentRoutineUPP(componentEntryPoint);
	
bail:
  if (registeredComponent == NULL) {
    return false;
  } else {
    return true;
  }
}
