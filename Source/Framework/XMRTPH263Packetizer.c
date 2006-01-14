/*
 * $Id: XMRTPH263Packetizer.c,v 1.1 2006/01/14 13:25:59 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

#include "XMRTPH263Packetizer.h"

#define kXMRTPH263PacketizerVersion (0x00010001)

typedef struct
{
	ComponentInstance self;
	ComponentInstance target;
	ComponentInstance packetBuilder;
	TimeBase timeBase;
	TimeScale timeScale;
	UInt32 maxPacketSize;
} XMRTPH263PacketizerGlobalsRecord, *XMRTPH263PacketizerGlobals;

#define RTPMP_BASENAME()	XMRTPH263Packetizer_
#define RTPMP_GLOBALS()		XMRTPH263PacketizerGlobals storage

#define CALLCOMPONENT_BASENAME()	RTPMP_BASENAME()
#define CALLCOMPONENT_GLOBALS()		RTPMP_GLOBALS()

#define COMPONENT_DISPATCH_FILE		"XMRTPH263PacketizerDispatch.h"
#define COMPONENT_UPP_SELECT_ROOT()	RTPMP

#include <CoreServices/Components.k.h>
#include <QuickTime/QTStreamingComponents.k.h>
#include <QuickTime/ComponentDispatchHelper.c>

#pragma mark Definitions

#pragma mark Function Prototypes

// Called when the whole code between two GOB headers fits within one
// packet (Mode A only)
void _XMRTPH263Packetizer_PacketizeCompleteGOB(XMRTPH263PacketizerGlobals globals,
											   const RTPMPSampleDataParams *sampleData,
											   RTPPacketGroupRef packetGroup,
											   UInt8 sourceFormat,
											   UInt8 pictureCodingType,
											   UInt8 unrestrictedMotionVectorFlag,
											   UInt32 startIndex, 
											   UInt32 length,
											   Boolean isLastPacket);

// Called when it is required to split the data stream at MB boundaries.
// Thus, the first packet generated will be Mode A, the subsequent ones mode B
// Not implemented yet as probably not needed at all
void _XMRTP263Packetizer_PacketizeSplittedGOB(XMRTPH263PacketizerGlobals globals,
											  const RTPMPSampleDataParams *sampleData,
											  UInt8 sourceFormat,
											  UInt8 pictureCodingType,
											  UInt32 startIndex,
											  UInt32 length);

#pragma mark Standard Component Calls
	
ComponentResult XMRTPH263Packetizer_Open(XMRTPH263PacketizerGlobals globals,
										 ComponentInstance self)
{
	ComponentResult err = noErr;
	
	globals = calloc(sizeof(XMRTPH263PacketizerGlobalsRecord), 1);
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
	
bail:
	return err;
}

ComponentResult XMRTPH263Packetizer_Close(XMRTPH263PacketizerGlobals globals,
										  ComponentInstance self)
{
	if(globals)
	{
		free(globals);
	}
	
	return noErr;
}

ComponentResult XMRTPH263Packetizer_Version(XMRTPH263PacketizerGlobals globals)
{
	return kXMRTPH263PacketizerVersion;
}

ComponentResult XMRTPH263Packetizer_Target(XMRTPH263PacketizerGlobals globals,
										   ComponentInstance target)
{
	printf("XMRTPH263Packetizer_Target called\n");
	globals->target = target;
	return noErr;
}

#pragma mark MediaPacketizer Component Calls

ComponentResult XMRTPH263Packetizer_Initialize(XMRTPH263PacketizerGlobals globals,
											   SInt32 inFlags)
{
	return noErr;
}

ComponentResult XMRTPH263Packetizer_PreflightMedia(XMRTPH263PacketizerGlobals globals,
												   OSType inMediaType,
												   SampleDescriptionHandle inSampleDescription)
{	
	return noErr;
}

ComponentResult XMRTPH263Packetizer_Idle(XMRTPH263PacketizerGlobals globals,
										 SInt32 inFlags,
										 SInt32 *outFlags)
{
	*outFlags = 0;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_SetSampleData(XMRTPH263PacketizerGlobals globals,
												  const RTPMPSampleDataParams *sampleData,
												  SInt32 *outFlags)
{	
	//////////////////////////////////////////////////////////////////////
	//
	// QuickTime H.263 produces the following bitstream:
	//
	// PTYPE, bit  3: always 0
	// PTYPE, bit  4: always 0
	// PTYPE, bit  5: always 0
	// PTYPE, bits 6-8: depending on video size. Never '111' (PLUSPTYPE)
	// PTYPE, bit  9: First frame is 1, else 0 (INTER-Coding)
	// PTYPE, bit 10: always 0 (Unrestricted Motion Vectors)
	// PTYPE, bit 11: always 0 (SAC)
	// PTYPE, bit 12: always 0 (AP)
	// PTYPE, bit 13: always 0 (PB-Frames)
	//
	// Applies to 'appl' H.263:
	// CPM: always 0
	// PSBI: Not present since CPM is 0
	// TRB: Not present since PB-Frames are off (PTYPE, bit 13)
	// DBQUANT: Not present since PB-Frames are off
	// PEI: Normally 0
	// EOS: Not present
	//
	///////////////////////////////////////////////////////////////////////
	
	///////////////////////////////////////////////////////////////////////
	//
	// The GOB headers are all byte aligned, so it is easy to find them
	// if needed (two subsequent zero bytes)
	//
	///////////////////////////////////////////////////////////////////////
	
	RTPPacketGroupRef packetGroupRef;
	const UInt8 *data = sampleData->data;
	UInt32 maxPacketLength = globals->maxPacketSize - 4;	// substracting 4 bytes for Mode A
	UInt32 dataLength = sampleData->dataLength;

	// Begin the packet group
	RTPPBBeginPacketGroup(globals->packetBuilder,
						  0,
						  sampleData->timeStamp,
						  &packetGroupRef);

	// determining the source format for this picture
	// (SQCIF, QCIF, CIF)
	UInt8 sourceFormat = (data[4] >> 2) &0x07;
	
	// determining the picture coding type (INTRA / INTER) for this frame
	UInt8 pictureCodingType = (data[4] >> 1) & 0x01;
	
	// determining the unrestricted motion vector flag
	UInt8 unrestrictedMotionVectorFlag = data[4] & 0x01;
	
	// If the picture fits within one packet, we're already done
	if(dataLength <= maxPacketLength)
	{
		_XMRTPH263Packetizer_PacketizeCompleteGOB(globals,
												  sampleData,
												  packetGroupRef,
												  sourceFormat,
												  pictureCodingType,
												  unrestrictedMotionVectorFlag,
												  0,
												  dataLength,
												  true);
	}
	else
	{
		UInt32 remainingLength = dataLength;
		UInt32 dataStartIndex = 0;
		
		while(remainingLength > maxPacketLength)
		{
			SInt32 scanIndex = dataStartIndex + maxPacketLength;
			
			UInt32 packetLength = 0;
			
			while(scanIndex > dataStartIndex)
			{
				
				if(data[scanIndex] == 0)
				{
					UInt32 gobStartIndex = 0;
					
					if((data[scanIndex-1] == 0) &&
					   (data[scanIndex+1] != 0))
					{
						gobStartIndex = scanIndex-1;
					}
					else if((data[scanIndex+1] == 0) &&
							(data[scanIndex+2] != 0))
					{
						gobStartIndex = scanIndex;
					}
					
					if(gobStartIndex != 0)
					{
						packetLength = gobStartIndex - dataStartIndex;
						
						_XMRTPH263Packetizer_PacketizeCompleteGOB(globals,
																  sampleData,
																  packetGroupRef,
																  sourceFormat,
																  pictureCodingType,
																  unrestrictedMotionVectorFlag,
																  dataStartIndex,
																  packetLength,
																  false);
						dataStartIndex = gobStartIndex;
						remainingLength -= packetLength;
						break;
					}
				}
				
				scanIndex -= 2;
			}
			
			if(packetLength == 0)
			{
				printf("no fitting GOB found!\n");
				break;
			}
		}
		
		if(remainingLength <= maxPacketLength)
		{
			_XMRTPH263Packetizer_PacketizeCompleteGOB(globals,
													  sampleData,
													  packetGroupRef,
													  sourceFormat,
													  pictureCodingType,
													  unrestrictedMotionVectorFlag,
													  dataStartIndex,
													  remainingLength,
													  true);
		}
		else
		{
			printf("cannot pack last frame since too big!\n");
		}
	}
									
	RTPPBEndPacketGroup(globals->packetBuilder,
						0,
						packetGroupRef);
	
	*outFlags = 0;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_Flush(XMRTPH263PacketizerGlobals globals,
										  SInt32 inFlags,
										  SInt32 *outFlags)
{
	*outFlags = 0;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_Reset(XMRTPH263PacketizerGlobals globals,
										  SInt32 inFlags)
{
	return noErr;
}

ComponentResult XMRTPH263Packetizer_SetInfo(XMRTPH263PacketizerGlobals globals,
											OSType inSelector,
											const void *ioParams)
{
	printf("SetInfo called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_GetInfo(XMRTPH263PacketizerGlobals globals,
											OSType inSelector,
											void *ioParams)
{
	printf("GetInfo called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_SetTimeScale(XMRTPH263PacketizerGlobals globals,
												 TimeScale inTimeScale)
{
	globals->timeScale = inTimeScale;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_GetTimeScale(XMRTPH263PacketizerGlobals globals,
												 TimeScale *outTimeScale)
{
	*outTimeScale = globals->timeScale;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_SetTimeBase(XMRTPH263PacketizerGlobals globals,
												TimeBase inTimeBase)
{
	globals->timeBase = inTimeBase;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_GetTimeBase(XMRTPH263PacketizerGlobals globals,
												TimeBase *outTimeBase)
{
	*outTimeBase = globals->timeBase;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_HasCharacteristic(XMRTPH263PacketizerGlobals globals,
													  OSType inSelector,
													  Boolean *outHasIt)
{
	printf("HasCharacteristic called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_SetPacketBuilder(XMRTPH263PacketizerGlobals globals,
													 ComponentInstance inPacketBuilder)
{
	globals->packetBuilder = inPacketBuilder;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_GetPacketBuilder(XMRTPH263PacketizerGlobals globals,
													 ComponentInstance *outPacketBuilder)
{
	*outPacketBuilder = globals->packetBuilder;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_SetMediaType(XMRTPH263PacketizerGlobals globals,
												 OSType inMediaType)
{
	if(inMediaType != 'h263')
	{
		return paramErr;
	}
	return noErr;
}

ComponentResult XMRTPH263Packetizer_GetMediaType(XMRTPH263PacketizerGlobals globals,
												 OSType *outMediaType)
{
	*outMediaType = 'h263';
	return noErr;
}

ComponentResult XMRTPH263Packetizer_SetMaxPacketSize(XMRTPH263PacketizerGlobals globals,
													 UInt32 inMaxPacketSize)
{
	globals->maxPacketSize = inMaxPacketSize;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_GetMaxPacketSize(XMRTPH263PacketizerGlobals globals,
													 UInt32 *outMaxPacketSize)
{
	*outMaxPacketSize = globals->maxPacketSize;
	return noErr;
}

ComponentResult XMRTPH263Packetizer_SetMaxPacketDuration(XMRTPH263PacketizerGlobals globals,
														 UInt32 inMaxPacketDuration)
{
	printf("SetMaxPacketDuration called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_GetMaxPacketDuration(XMRTPH263PacketizerGlobals globals,
														 UInt32 *outMaxPacketDuration)
{
	printf("GetMaxPacketDuration called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_DoUserDialog(XMRTPH263PacketizerGlobals globals,
												 ModalFilterUPP inFilterUPP,
												 Boolean *canceled)
{
	printf("Do UserDialog called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_SetSettingsFromAtomContainerAtAtom(XMRTPH263PacketizerGlobals globals,
																	   QTAtomContainer inContainer,
																	   QTAtom inParentAtom)
{
	printf("SetSettingsFromAtomContainer called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_GetSettingsIntoAtomContainerAtAtom(XMRTPH263PacketizerGlobals globals,
																	   QTAtomContainer inOutContainer,
																	   QTAtom inParentAtom)
{
	printf("GetSettingsIntoAtomContainer called\n");
	return paramErr;
}

ComponentResult XMRTPH263Packetizer_GetSettingsAsText(XMRTPH263PacketizerGlobals globals,
													  Handle *text)
{
	printf("GetSettingsAsText called\n");
	return paramErr;
}

#pragma mark Private Packetization Functions

void _XMRTPH263Packetizer_PacketizeCompleteGOB(XMRTPH263PacketizerGlobals globals,
											   const RTPMPSampleDataParams *sampleData,
											   RTPPacketGroupRef packetGroup,
											   UInt8 sourceFormat,
											   UInt8 pictureCodingType,
											   UInt8 unrestrictedMotionVectorFlag,
											   UInt32 startIndex, 
											   UInt32 length,
											   Boolean isLastPacket)
{
	UInt8 header[4];
	
	// F, P, SBIT and EBIT are zero
	header[0] = 0;
	
	// U is set to one, 
	// S, A are always zero
	header[1] = 0;
	
	header[1] |= (sourceFormat << 5);
	header[1] |= (pictureCodingType << 4);
	header[1] |= (unrestrictedMotionVectorFlag << 3);
	
	// DBQ, TRB and TR are always zero
	header[2] = 0;
	header[3] = 0;
	
	RTPPacketRef packet;
	
	RTPPBBeginPacket(globals->packetBuilder,
					 0,
					 packetGroup,
					 length+4,
					 &packet);
	
	RTPPBAddPacketLiteralData(globals->packetBuilder,
							  0,
							  packetGroup,
							  packet,
							  header,
							  4,
							  NULL);
	
	RTPPBAddPacketSampleData(globals->packetBuilder,
							 0,
							 packetGroup,
							 packet,
							 (RTPMPSampleDataParams *)sampleData,
							 startIndex,
							 length,
							 NULL);
	
	SInt32 flags = 0;
	if(isLastPacket)
	{
		flags = 1;
	}
	RTPPBEndPacket(globals->packetBuilder,
				   flags,
				   packetGroup,
				   packet,
				   0,
				   0);
}

void _XMRTP263Packetizer_PacketizeSplittedGOB(XMRTPH263PacketizerGlobals globals,
											  const RTPMPSampleDataParams *sampleData,
											  UInt8 sourceFormat,
											  UInt8 pictureCodingType,
											  UInt32 startIndex,
											  UInt32 length)
{
	printf("Not implemented yet\n");
}

#pragma mark Component Registration Functions

/**
 * Registering the Component
 * This function registers the XMH263MediaPacketizer component so that
 * this component can be used as a media packetizer for RFC2190 compliant
 * H.263
 **/
Boolean XMRegisterRTPH263Packetizer()
{	
	ComponentDescription description;
	Component registeredComponent = NULL;
	
	description.componentType = kXMRTPH263PacketizerComponentType;
	description.componentSubType = kXMRTPH263PacketizerComponentSubType;
	description.componentManufacturer = kXMRTPH263PacketizerComponentManufacturer;
	description.componentFlags = 0;
	description.componentFlagsMask = 0;
	
	// Registering the Component
	ComponentRoutineUPP componentEntryPoint =
		NewComponentRoutineUPP((ComponentRoutineProcPtr)&XMRTPH263Packetizer_ComponentDispatch);
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
