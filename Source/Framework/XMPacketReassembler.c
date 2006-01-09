/*
 * $Id: XMPacketReassembler.c,v 1.8 2006/01/09 22:22:57 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include "XMPacketReassembler.h"

#include "XMTypes.h"
#include "XMCallbackBridge.h"
#include "XMH264PacketReassembler.h"

#define kXMPacketReassemblerVersion (0x00010001)

#define kXMMaxBufferSize 352*288*4

typedef struct
{
	ComponentInstance self;
	ComponentInstance target;
	RTPReassembler reassembler;
	CodecType codecType;
	unsigned payloadType;
	unsigned sessionID;
	UInt8 *chunkBuffer;
} XMPacketReassemblerGlobalsRecord, *XMPacketReassemblerGlobals;

#define RTPRSSM_BASENAME()				XMPacketReassembler_
#define RTPRSSM_GLOBALS()				XMPacketReassemblerGlobals storage

#define CALLCOMPONENT_BASENAME()	RTPRSSM_BASENAME()
#define CALLCOMPONENT_GLOBALS()		RTPRSSM_GLOBALS()

#define COMPONENT_DISPATCH_FILE		"XMPacketReassemblerDispatch.h"
#define COMPONENT_UPP_SELECT_ROOT()	RTPRssm

#include <CoreServices/Components.k.h>
#include <QuickTime/QTStreamingComponents.k.h>
#include <QuickTime/ComponentDispatchHelper.c>

// This function is implemented in XMMediaReceiver.m
//extern void _XMProcessFrame(UInt8* data, unsigned length, unsigned sessionID);

#pragma mark RTPRssm functions

ComponentResult XMPacketReassembler_Open(XMPacketReassemblerGlobals globals,
										 ComponentInstance self)
{
	ComponentResult err = noErr;
	
	printf("Open XMPacketReassembler\n");
	
	globals = calloc( sizeof(XMPacketReassemblerGlobalsRecord), 1);
	if(!globals)
	{
		err = memFullErr;
		goto bail;
	}

	SetComponentInstanceStorage(self, (Handle)globals);
	
	globals->self = self;
	globals->target = self;
	globals->reassembler = NULL;
	globals->codecType = 0;
	globals->payloadType = 0;
	globals->sessionID = 0;
	globals->chunkBuffer = NULL;
	
bail:
	return err;
}

ComponentResult XMPacketReassembler_Close(XMPacketReassemblerGlobals globals,
										  ComponentInstance self)
{
	if(globals)
	{
		if(globals->reassembler != NULL)
		{
			CloseComponent(globals->reassembler);
			globals->reassembler = NULL;
		}
		if(globals->chunkBuffer != NULL)
		{
			free(globals->chunkBuffer);
		}
		free(globals);
	}
	
	return noErr;
}

ComponentResult XMPacketReassembler_Version(XMPacketReassemblerGlobals globals)
{
	return kXMPacketReassemblerVersion;
}

ComponentResult XMPacketReassembler_Target(XMPacketReassemblerGlobals globals,
										   ComponentInstance target)
{
	globals->target = target;
	
	return noErr;
}

ComponentResult XMPacketReassembler_Initialize(XMPacketReassemblerGlobals globals,
											   RTPRssmInitParams *inInitParams)
{	
	XMCodecIdentifier codecIdentifier = (XMCodecIdentifier)inInitParams->ssrc;
	
	switch(codecIdentifier)
	{
		case XMCodecIdentifier_H261:
			globals->codecType = kH261CodecType;
			break;
		case XMCodecIdentifier_H263:
			globals->codecType = kH263CodecType;
			break;
		case XMCodecIdentifier_H264:
			globals->codecType = kH264CodecType;
			break;
		default:
			return paramErr;
	}
	
	globals->payloadType = inInitParams->payloadType;
	globals->sessionID = inInitParams->timeScale;
	
	return noErr;
}

ComponentResult XMPacketReassembler_HandleNewPacket(XMPacketReassemblerGlobals globals,
													QTSStreamBuffer *inStreamBuffer,
													SInt32 inNumWraparounds)
{
	ComponentResult err = noErr;
	
	unsigned char *data = inStreamBuffer->rptr;
	
	if(globals->reassembler == NULL)
	{
		OSType subType;
		
		ComponentDescription componentDescription;
		componentDescription.componentType = kRTPReassemblerType;
		componentDescription.componentSubType = 0;
		componentDescription.componentManufacturer = 0;
		componentDescription.componentFlags = 0;
		componentDescription.componentFlagsMask = 0;
		
		if(globals->codecType == kH261CodecType)
		{
			subType = kRTP261ReassemblerType;
		}
		else if(globals->codecType == kH263CodecType)
		{
			if(globals->payloadType == kRTPPayload_H263)
			{
				subType = kRTP263ReassemblerType;
			}
			else
			{
				subType = kRTP263PlusReassemblerType;
			}
		}
		else if(globals->codecType == kH264CodecType)
		{
			subType = kXMH264PacketReassemblerComponentSubType;
			componentDescription.componentType = kXMH264PacketReassemblerComponentType;
			componentDescription.componentManufacturer = kXMH264PacketReassemblerComponentManufacturer;
		}
		else
		{
			printf("no valid video codec\n");
			return paramErr;
		}
		
		componentDescription.componentSubType = subType;
		
		Component reassemblerComponent = FindNextComponent(0, &componentDescription);
		if(reassemblerComponent == NULL)
		{
			printf("not found\n");
			err = qtsBadStateErr;
			goto bail;
		}
		
		RTPReassembler reassembler;
		err = OpenAComponent(reassemblerComponent, &reassembler);
		if(err != noErr)
		{
			printf("not opened\n");
			err = qtsBadStateErr;
			goto bail;
		}
		
		RTPRssmInitParams initParams;
		initParams.payloadType = globals->payloadType;
		initParams.timeBase = NewTimeBase();
		initParams.timeScale = 90000;
		err = RTPRssmInitialize(reassembler, &initParams);
		if(err != noErr)
		{
			printf("coulnd't initialize reassembler\n");
			//err = qtsBadStateErr;
			//goto bail;
		}
		
		err = CallComponentTarget(reassembler, globals->self);
		if(err != noErr)
		{
			err = qtsBadStateErr;
			goto bail;
		}
		
		/*err = RTPRssmSetPayloadHeaderLength(reassembler, 4);
		if(err != noErr)
		{
			err = qtsBadStateErr;
			goto bail;
		}*/
		
		globals->reassembler = reassembler;
	}
	
	err = RTPRssmHandleNewPacket(globals->reassembler, inStreamBuffer, inNumWraparounds);

bail:
	return err;
}

ComponentResult XMPacketReassembler_ComputeChunkSize(XMPacketReassemblerGlobals globals,
													 RTPRssmPacket *inPacketListHead,
													 SInt32 inFlags,
													 UInt32 *outChunkDataSize)
{
	printf("ComputeChunkSize called\n");
	return paramErr;
}

ComponentResult XMPacketReassembler_AdjustPacketParams(XMPacketReassemblerGlobals globals,
													   RTPRssmPacket *inPacket,
													   SInt32 inFlags)
{
	RTPRssmAdjustPacketParams(globals->reassembler, inPacket, inFlags);
	return noErr;
}

ComponentResult XMPacketReassembler_CopyDataToChunk(XMPacketReassemblerGlobals globals,
													RTPRssmPacket *inPacketListHead,
													UInt32 inMaxChunkDataSize,
													SHChunkRecord *inChunk,
													SInt32 inFlags)
{
	printf("CopyDataToChunk\n");
	return paramErr;
}

ComponentResult XMPacketReassembler_SendPacketList(XMPacketReassemblerGlobals globals,
												   RTPRssmPacket *inPacketListHead,
												   const TimeValue64 *inLastChunkPresentationTime,
												   SInt32 inFlags)
{
	//printf("SendPacketList called with flags: %d\n", inFlags);
	ComponentResult err = noErr;
	
	// The chunkBuffer is used repeatedly, therefore we allocate it to the maximum buffer size available
	if(globals->chunkBuffer == NULL)
	{
		UInt8 *buffer = malloc(kXMMaxBufferSize);
		if(buffer == NULL)
		{
			err = memFullErr;
			goto bail;
		}
		
		globals->chunkBuffer = buffer;
	}
	
	SHChunkRecord chunkRecord;
	chunkRecord.dataSize = 0;
	chunkRecord.dataPtr = globals->chunkBuffer;
	
	err = RTPRssmCopyDataToChunk(globals->reassembler,
								 inPacketListHead,
								 kXMMaxBufferSize,
								 &chunkRecord,
								 0);
	if(err != noErr)
	{
		goto bail;
	}
	
	/*err = RTPRssmReleasePacketList(globals->reassembler,
								   inPacketListHead);*/
	
//	_XMProcessFrame(chunkRecord.dataPtr, chunkRecord.dataSize, globals->sessionID);
	
bail:
	return err;
}

ComponentResult XMPacketReassembler_GetTimeScaleFromPacket(XMPacketReassemblerGlobals globals,
														   QTSStreamBuffer *inStreamBuffer,
														   TimeScale *outTimeScale)
{
	printf("GetTimeScaleFromPacket called\n");
	return paramErr;
}

ComponentResult XMPacketReassembler_GetInfo(XMPacketReassemblerGlobals globals,
											OSType inSelector,
											void *ioParams)
{
	printf("GetInfo called\n");
	return paramErr;
}

ComponentResult XMPacketReassembler_SetInfo(XMPacketReassemblerGlobals globals,
											OSType inSelector,
											void *ioParams)
{
	printf("SetInfo called\n");
	return paramErr;
}

ComponentResult XMPacketReassembler_HasCharacteristic(XMPacketReassemblerGlobals globals,
													  OSType inCharacteristic,
													  Boolean *outHasIt)
{
	printf("HasCharacteristic called\n");
	return paramErr;
}

ComponentResult XMPacketReassembler_Reset(XMPacketReassemblerGlobals globals,
										  SInt32 inFlags)
{
	ComponentResult err = noErr;
	
	if(globals->reassembler != NULL)
	{
		CloseComponent(globals->reassembler);
		globals->reassembler = NULL;
	}
	
	return err;
}

#pragma mark Setup Functions

Boolean XMRegisterPacketReassembler()
{	
	ComponentDescription description;
	Component registeredComponent = NULL;
	
	description.componentType = kXMPacketReassemblerComponentType;
	description.componentSubType = kXMPacketReassemblerComponentSubType;
	description.componentManufacturer = kXMPacketReassemblerComponentManufacturer;
	description.componentFlags = 0;
	description.componentFlagsMask = 0;
		
	// Registering the Component
	ComponentRoutineUPP componentEntryPoint =
	NewComponentRoutineUPP((ComponentRoutineProcPtr)&XMPacketReassembler_ComponentDispatch);
	registeredComponent = RegisterComponent(&description, componentEntryPoint,
												0, 0, 0, 0);
	DisposeComponentRoutineUPP(componentEntryPoint);
	
bail:
	return (registeredComponent == NULL ? false : true);
}