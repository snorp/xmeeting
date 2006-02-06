/*
 * $Id: XMRTPH264Packetizer.c,v 1.4 2006/02/06 19:38:07 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMRTPH264Packetizer.h"

#define kXMRTPH264PacketizerVersion (0x00010001)

typedef struct
{
	ComponentInstance self;
	ComponentInstance target;
	ComponentInstance packetBuilder;
	TimeBase timeBase;
	TimeScale timeScale;
	UInt32 maxPacketSize;
	Boolean useNonInterleavedMode;
	UInt8 *spsAtomData;
	UInt8 *ppsAtomData;
	UInt16 spsAtomLength;
	UInt16 ppsAtomLength;
} XMRTPH264PacketizerGlobalsRecord, *XMRTPH264PacketizerGlobals;

#define RTPMP_BASENAME()	XMRTPH264Packetizer_
#define RTPMP_GLOBALS()		XMRTPH264PacketizerGlobals storage

#define CALLCOMPONENT_BASENAME()	RTPMP_BASENAME()
#define CALLCOMPONENT_GLOBALS()		RTPMP_GLOBALS()

#define COMPONENT_DISPATCH_FILE		"XMRTPH264PacketizerDispatch.h"
#define COMPONENT_UPP_SELECT_ROOT()	RTPMP

#include <CoreServices/Components.k.h>
#include <QuickTime/QTStreamingComponents.k.h>
#include <QuickTime/ComponentDispatchHelper.c>

#pragma mark Standard Component Calls

ComponentResult XMRTPH264Packetizer_Open(XMRTPH264PacketizerGlobals globals,
										 ComponentInstance self)
{
	ComponentResult err = noErr;
	
	globals = calloc(sizeof(XMRTPH264PacketizerGlobalsRecord), 1);
	if(!globals)
	{
		err = memFullErr;
		goto bail;
	}
	
	SetComponentInstanceStorage(self, (Handle)globals);
	
	globals->self = self;
	globals->target = self;
	globals->timeBase = 0;
	globals->timeScale = 0;
	globals->maxPacketSize = 1438;
	globals->useNonInterleavedMode = false;
	globals->spsAtomData = NULL;
	globals->spsAtomLength = 0;
	globals->ppsAtomData = NULL;
	globals->ppsAtomLength = 0;
	
bail:
	return err;
}

ComponentResult XMRTPH264Packetizer_Close(XMRTPH264PacketizerGlobals globals,
										  ComponentInstance self)
{
	if(globals)
	{
		free(globals);
	}
	
	return noErr;
}

ComponentResult XMRTPH264Packetizer_Version(XMRTPH264PacketizerGlobals globals)
{
	return kXMRTPH264PacketizerVersion;
}

ComponentResult XMRTPH264Packetizer_Target(XMRTPH264PacketizerGlobals globals,
										   ComponentInstance target)
{
	printf("XMRTPH264Packetizer_Target called\n");
	globals->target = target;
	return noErr;
}

#pragma mark MediaPacketizer Component Calls

ComponentResult XMRTPH264Packetizer_Initialize(XMRTPH264PacketizerGlobals globals,
											   SInt32 inFlags)
{
	if((inFlags & 2) != 0)
	{
		globals->useNonInterleavedMode = true;
	}
	return noErr;
}

ComponentResult XMRTPH264Packetizer_PreflightMedia(XMRTPH264PacketizerGlobals globals,
												   OSType inMediaType,
												   SampleDescriptionHandle inSampleDescription)
{
	ComponentResult err = noErr;
	
	Handle avccExtension = NULL;
	err = GetImageDescriptionExtension((ImageDescriptionHandle)inSampleDescription,
									   &avccExtension,
									   FOUR_CHAR_CODE('avcC'),
									   1);
	if(err != noErr)
	{
		printf("GetImageDescriptionExtension failed");
	}
	
	UInt8 *data = (UInt8 *)*avccExtension;
	
	UInt16 *spsLengthData = (UInt16 *)&(data[6]);
	UInt16 spsAtomLength = ntohs(spsLengthData[0]);
	
	UInt32 ppsAtomLengthIndex = 9 + spsAtomLength;
	
	UInt16 *ppsLengthData = (UInt16 *)&(data[ppsAtomLengthIndex]);
	UInt16 ppsAtomLength = ntohs(ppsLengthData[0]);
	
	globals->spsAtomData = malloc(spsAtomLength * sizeof(UInt8));
	globals->ppsAtomData = malloc(ppsAtomLength * sizeof(UInt8));
	
	UInt8 *src = &(data[8]);
	memcpy(globals->spsAtomData, src, spsAtomLength);
	globals->spsAtomLength = spsAtomLength;
	
	src = &(data[ppsAtomLengthIndex + 2]);
	memcpy(globals->ppsAtomData, src, ppsAtomLength);
	globals->ppsAtomLength = ppsAtomLength;
	
	printf("SPS: \n");
	unsigned i;
	for(i = 0; i < spsAtomLength; i++)
	{
		printf("%x ", globals->spsAtomData[i]);
	}
	printf("\n");
	/*
	printf("PPS: \n");
	for(i = 0; i < ppsAtomLength; i++)
	{
		printf("%x ", globals->ppsAtomData[i]);
	}
	printf("\n");*/
	
	DisposeHandle(avccExtension);
	return err;
}

ComponentResult XMRTPH264Packetizer_Idle(XMRTPH264PacketizerGlobals globals,
										 SInt32 inFlags,
										 SInt32 *outFlags)
{
	*outFlags = 0;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_SetSampleData(XMRTPH264PacketizerGlobals globals,
												  const RTPMPSampleDataParams *sampleData,
												  SInt32 *outFlags)
{	
	//printf("*******\n");
	UInt32 maxPacketLength = globals->maxPacketSize;
	const UInt8 *data = sampleData->data;
	UInt32 dataLength = sampleData->dataLength;
	UInt32 index = 0;
	ComponentInstance packetBuilder = globals->packetBuilder;
	
	RTPPacketGroupRef packetGroupRef;
	
	RTPPBBeginPacketGroup(packetBuilder,
						  0,
						  sampleData->timeStamp,
						  &packetGroupRef);
	
	// Check whether SPS and PPS units should be sent
	if((sampleData->flags & 1) != 0)
	{
		RTPPacketRef packetRef;
		RTPPBBeginPacket(packetBuilder,
						 0,
						 packetGroupRef,
						 globals->spsAtomLength,
						 &packetRef);
		RTPPBAddPacketLiteralData(packetBuilder,
								  0,
								  packetGroupRef,
								  packetRef,
								  globals->spsAtomData,
								  globals->spsAtomLength,
								  NULL);
		RTPPBEndPacket(packetBuilder,
					   0,
					   packetGroupRef,
					   packetRef,
					   0,
					   0);
		RTPPBBeginPacket(packetBuilder,
						 0,
						 packetGroupRef,
						 globals->ppsAtomLength,
						 &packetRef);
		RTPPBAddPacketLiteralData(packetBuilder,
								  0,
								  packetGroupRef,
								  packetRef,
								  globals->ppsAtomData,
								  globals->ppsAtomLength,
								  NULL);
		RTPPBEndPacket(packetBuilder,
					   0,
					   packetGroupRef,
					   packetRef,
					   0,
					   0);
	}
	
	do {
		// Getting the size of this NAL unit
		UInt32 *lengthPtr = (UInt32 *)&(data[index]);
		index += 4;
		UInt32 nalLength = ntohl(lengthPtr[0]);
		
		//printf("NAL %d\n", nalLength);
		
		// If the NAL does not fit within one single packet,
		// we have to use FU-A packets, which are only available
		// in the non-interleaved mode
		if(nalLength > maxPacketLength && globals->useNonInterleavedMode == true)
		{
			printf("Sending FU-A\n");
			// Send some FU-A packets
			UInt8 nri = (data[index] >> 5) & 0x03;
			UInt8 type = data[index] & 0x1f;
			
			UInt32 remainingLength = nalLength;
			index += 1;
			remainingLength -= 1;
		
			while(remainingLength > 0)
			{
				UInt8 s = 0;
				UInt8 e = 0;
				
				UInt32 sendDataLength = maxPacketLength-2;
			
				if(remainingLength == nalLength-1)
				{
					s = 1;
				}
				else if(remainingLength <= (maxPacketLength - 2))
				{
					e = 1;
					sendDataLength = remainingLength;
				}
				
				UInt8 header[2];
				
				header[0] = 0;
				header[0] |= (nri << 5);
				header[0] |= 28;
				header[1] = 0;
				header[1] = (s << 7);
				header[1] |= (e << 6);
				header[1] |= type;
		
				RTPPacketRef packetRef;
				RTPPBBeginPacket(packetBuilder,
								 0,
								 packetGroupRef,
								 sendDataLength+2,
								 &packetRef);
					
				RTPPBAddPacketLiteralData(packetBuilder,
										  0,
										  packetGroupRef,
										  packetRef,
										  header,
										  2,
										  NULL);
					
				RTPPBAddPacketSampleData(packetBuilder,
										 0,
										 packetGroupRef,
										 packetRef,
										 (RTPMPSampleDataParams *)sampleData,
										 index,
										 sendDataLength,
										 NULL);
					
				index += sendDataLength;
				remainingLength -= sendDataLength;
					
				SInt32 flags = 0;
				if(index >= dataLength)
				{
					flags = 1;
				}
				RTPPBEndPacket(packetBuilder,
							   flags,
							   packetGroupRef,
							   packetRef,
							   0,
							   0);
			}
		}
		else if(nalLength > maxPacketLength)
		{
			// Generating a packet of zero length indicates to the subsystem
			// to drop this packet and increment the RTP Sequence Number by
			// one
			printf("Impossible to send too big NAL unit: %d\n", nalLength);
			RTPPacketRef packetRef;
			RTPPBBeginPacket(packetBuilder,
							 0,
							 packetGroupRef,
							 0,
							 &packetRef);
			
			UInt8 empty[2];
			empty[0] = 0;
			empty[1] = 0;
			RTPPBAddPacketLiteralData(packetBuilder,
									  0,
									  packetGroupRef,
									  packetRef,
									  empty,
									  2,
									  NULL);
			
			RTPPBEndPacket(packetBuilder,
						   0,
						   packetGroupRef,
						   packetRef,
						   0,
						   0);
			index += nalLength;
		}
		else
		{
			RTPPacketRef packetRef;
			RTPPBBeginPacket(packetBuilder,
							 0,
							 packetGroupRef,
							 nalLength,
							 &packetRef);
			RTPPBAddPacketSampleData(packetBuilder,
									 0,
									 packetGroupRef,
									 packetRef,
									 (RTPMPSampleDataParams *)sampleData,
									 index,
									 nalLength,
									 NULL);
			index += nalLength;
			
			SInt32 flags = 0;
			if(index >= dataLength)
			{
				flags = 1;
			}
			
			RTPPBEndPacket(packetBuilder,
						   flags,
						   packetGroupRef,
						   packetRef,
						   0,
						   0);
		}
		
	} while (index < dataLength);
	
	RTPPBEndPacketGroup(packetBuilder,
						0,
						packetGroupRef);
	
	*outFlags = 0;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_Flush(XMRTPH264PacketizerGlobals globals,
										  SInt32 inFlags,
										  SInt32 *outFlags)
{
	*outFlags = 0;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_Reset(XMRTPH264PacketizerGlobals globals,
										  SInt32 inFlags)
{
	return noErr;
}

ComponentResult XMRTPH264Packetizer_SetInfo(XMRTPH264PacketizerGlobals globals,
											OSType inSelector,
											const void *ioParams)
{
	printf("SetInfo called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_GetInfo(XMRTPH264PacketizerGlobals globals,
											OSType inSelector,
											void *ioParams)
{
	printf("GetInfo called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_SetTimeScale(XMRTPH264PacketizerGlobals globals,
												 TimeScale inTimeScale)
{
	globals->timeScale = inTimeScale;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_GetTimeScale(XMRTPH264PacketizerGlobals globals,
												 TimeScale *outTimeScale)
{
	*outTimeScale = globals->timeScale;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_SetTimeBase(XMRTPH264PacketizerGlobals globals,
												TimeBase inTimeBase)
{
	globals->timeBase = inTimeBase;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_GetTimeBase(XMRTPH264PacketizerGlobals globals,
												TimeBase *outTimeBase)
{
	*outTimeBase = globals->timeBase;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_HasCharacteristic(XMRTPH264PacketizerGlobals globals,
													  OSType inSelector,
													  Boolean *outHasIt)
{
	printf("HasCharacteristic called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_SetPacketBuilder(XMRTPH264PacketizerGlobals globals,
													 ComponentInstance inPacketBuilder)
{
	globals->packetBuilder = inPacketBuilder;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_GetPacketBuilder(XMRTPH264PacketizerGlobals globals,
													 ComponentInstance *outPacketBuilder)
{
	*outPacketBuilder = globals->packetBuilder;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_SetMediaType(XMRTPH264PacketizerGlobals globals,
												 OSType inMediaType)
{
	if(inMediaType != 'avc1')
	{
		return paramErr;
	}
	return noErr;
}

ComponentResult XMRTPH264Packetizer_GetMediaType(XMRTPH264PacketizerGlobals globals,
												 OSType *outMediaType)
{
	*outMediaType = 'avc1';
	return noErr;
}

ComponentResult XMRTPH264Packetizer_SetMaxPacketSize(XMRTPH264PacketizerGlobals globals,
													 UInt32 inMaxPacketSize)
{
	globals->maxPacketSize = inMaxPacketSize;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_GetMaxPacketSize(XMRTPH264PacketizerGlobals globals,
													 UInt32 *outMaxPacketSize)
{
	*outMaxPacketSize = globals->maxPacketSize;
	return noErr;
}

ComponentResult XMRTPH264Packetizer_SetMaxPacketDuration(XMRTPH264PacketizerGlobals globals,
														 UInt32 inMaxPacketDuration)
{
	printf("SetMaxPacketDuration called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_GetMaxPacketDuration(XMRTPH264PacketizerGlobals globals,
														 UInt32 *outMaxPacketDuration)
{
	printf("GetMaxPacketDuration called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_DoUserDialog(XMRTPH264PacketizerGlobals globals,
												 ModalFilterUPP inFilterUPP,
												 Boolean *canceled)
{
	printf("Do UserDialog called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_SetSettingsFromAtomContainerAtAtom(XMRTPH264PacketizerGlobals globals,
																	   QTAtomContainer inContainer,
																	   QTAtom inParentAtom)
{
	printf("SetSettingsFromAtomContainer called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_GetSettingsIntoAtomContainerAtAtom(XMRTPH264PacketizerGlobals globals,
																	   QTAtomContainer inOutContainer,
																	   QTAtom inParentAtom)
{
	printf("GetSettingsIntoAtomContainer called\n");
	return paramErr;
}

ComponentResult XMRTPH264Packetizer_GetSettingsAsText(XMRTPH264PacketizerGlobals globals,
													  Handle *text)
{
	printf("GetSettingsAsText called\n");
	return paramErr;
}

#pragma mark Component Registration Functions

/**
* Registering the Component
 * This function registers the XMH263MediaPacketizer component so that
 * this component can be used as a media packetizer for RFC2190 compliant
 * H.263
 **/
Boolean XMRegisterRTPH264Packetizer()
{	
	ComponentDescription description;
	Component registeredComponent = NULL;
	
	description.componentType = kXMRTPH264PacketizerComponentType;
	description.componentSubType = kXMRTPH264PacketizerComponentSubType;
	description.componentManufacturer = kXMRTPH264PacketizerComponentManufacturer;
	description.componentFlags = 0;
	description.componentFlagsMask = 0;
	
	// Registering the Component
	ComponentRoutineUPP componentEntryPoint =
		NewComponentRoutineUPP((ComponentRoutineProcPtr)&XMRTPH264Packetizer_ComponentDispatch);
	registeredComponent = RegisterComponent(&description, componentEntryPoint,
											0, 0, 0, 0);
	DisposeComponentRoutineUPP(componentEntryPoint);
	
bail:
		if(registeredComponent == NULL)
		{
			return false;
		}
	else
	{
		return true;
	}
}
