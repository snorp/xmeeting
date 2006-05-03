/*
 * $Id: XMRTPH263Packetizer.c,v 1.7 2006/05/03 20:10:04 hfriederich Exp $
 *
 * Copyright (c) 2006 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2006 Hannes Friederich. All rights reserved.
 */

//////////////////////////////////////////////////////////////////////
//
// QuickTime H.263 produces the following bitstream:
//
// PTYPE, bit  3: always 0
// PTYPE, bit  4: always 0
// PTYPE, bit  5: always 0
// PTYPE, bits 6-8: depending on video size. Never '000' (Forbidden)
// or '111' (PLUSPTYPE)
// PTYPE, bit  9: First frame is 1 (INTRA), else 0 (INTER)
// PTYPE, bit 10: always 0 (Unrestricted Motion Vector)
// PTYPE, bit 11: always 0 (SAC)
// PTYPE, bit 12: always 0 (AP)
// PTYPE, bit 13: always 0 (PB-Frames)
//
// CPM: always zero
// PSBI: Not present since CPM is zero
// TRB: Not present since PB-Frames are off (PTYPE, bit 13)
// DBQUANT: Not present since PB-Frames are off
// PEI: zero
// EOS: Not present
//
// The GOB headers are all byte aligned, so it is easy to find them
// if needed (two subsequent zero bytes)
//
// The packetization algorithm is as follows:
//
// remainingLength = frameLength;
// currentIndex = 0;
// while(remainingLength > maxPacketSize) {
//	   if(currentGOBNumber == LastGOBNumber) {
//		   packetizeRemainingDataAsModeAModeBPackets();
//		   remainingLength = 0;
//	   } else {
//         startAt(currentIndex + maxPacketLength);
//	       searchBackwardsForGOBStartHeader();
//         if(GOB start header is found) {
//             packetizeDataFoundAsModeAPacket();
//         } else {
//		       startAt(currentIndex + maxPacketLength);
//			   searchForwardsForGOBStartHeader();
//			   packetizeDataFoundAsModeAModeBPackets();
//         }
//     }
//	   remainingLength -= lengthJustPacketized;
//	   currentIndex += lengthJustPacketized;
// }
// if(remainingLength != 0) {
//     packetizeRemainingDataAsModeAPacket();
// }
//
// The algorithm to packetize long GOBs goes as follows:
//
// remainingLength = gobLength;
// lengthToPacketize = 0;
// while(remainingLength > maxPacketSize) {
//     findNextMBBoundary();
//	   lengthToPacketize += mbLength;
//	   remainingLength -= mbLength;
//     if(lengthToPacketize > maxPacketSize) {
//         packetizeDataUpToPreviousMBBoundary();
//		   lengthToPacketize -= dataLengthJustPacketized;
//     }
// }
// packetizeDataUpdToMBBoundaryFound();
// packetizeRemainingData();
//
///////////////////////////////////////////////////////////////////////

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

#pragma mark H.263 Bitstream Analyzation Stuff

#define scanBit(theDataIndex, theMask) \
{ \
	theMask >>= 1; \
	if(theMask == 0) { \
		theDataIndex++; \
		theMask = 0x80; \
	} \
}

#define readBit(out, theData, theDataIndex, theMask) \
{ \
	out = theData[theDataIndex] & theMask; \
	scanBit(theDataIndex, theMask); \
}

#define scanBits(theDataIndex, theMask, theLength) \
{ \
	if(theLength == 1) {\
		scanBit(theDataIndex, theMask); \
	} else if(theLength == 2) {\
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
	} else if(theLength == 3) { \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
	} else if(theLength == 4) { \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
	} else if(theLength == 5) { \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
	} else if(theLength == 6) { \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
	} else { \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
		scanBit(theDataIndex, theMask); \
	} \
}

#define readBits(out, theData, theDataIndex, theMask, theLength) \
out = 0; \
{ \
	UInt32 counter = theLength; \
	UInt8 bit; \
	while(counter != 0) { \
		readBit(bit, theData, theDataIndex, theMask); \
		counter--; \
		if(bit != 0) { \
			out |= (0x01 << counter); \
		} \
	} \
}

#define scanBytes(theDataIndex, theLength) \
{ \
	theDataIndex += theLength; \
}

#define lookupBit(theData, theDataIndex, theMask, theTable, theTableIndex) \
{ \
	UInt8 bit; \
	readBit(bit, theData, theDataIndex, theMask); \
	if(bit != 0) { \
		theTableIndex++; \
	} \
	theTableIndex = theTable[theTableIndex]; \
}

#define scanSymbol(theData, theDataIndex, theMask, theTable, theTableSize) \
{ \
	UInt32 theTableIndex = 0; \
	do { \
		lookupBit(theData, theDataIndex, theMask, theTable, theTableIndex); \
	} while(theTableIndex < theTableSize); \
}

#define readSymbol(out, theData, theDataIndex, theMask, theTable, theTableSize) \
{ \
	UInt32 theTableIndex = 0; \
	do { \
		lookupBit(theData, theDataIndex, theMask, theTable, theTableIndex); \
	} while(theTableIndex < theTableSize); \
	out = theTableIndex; \
}

#define scanBlockData(theData, theDataIndex, theMask, theMBType, theReadCondition) \
{ \
	if(theMBType == MB_TYPE_3 || \
	  theMBType == MB_TYPE_4) { \
		scanBytes(theDataIndex, 1); \
	} \
	if(theReadCondition != false) { \
		do { \
			UInt8 tcoef; \
			readSymbol(tcoef, theData, theDataIndex, theMask, TCOEF, TCOEF_TABLE_SIZE); \
			if(tcoef == TCOEF_ESCAPE) { \
				UInt8 last; \
				readBit(last, theData, theDataIndex, theMask); \
				scanBytes(theDataIndex, 1); \
				scanBits(theDataIndex, theMask, 6); \
				if(last != 0) { \
					break; \
				} \
			} else if(tcoef == TCOEF_OK_LAST_1) { \
				break; \
			} \
		} while(true); \
	} \
}

#define SOURCE_FORMAT_FORBIDDEN 0x00
#define SOURCE_FORMAT_SQCIF 0x01
#define SOURCE_FORMAT_QCIF 0x02
#define SOURCE_FORMAT_CIF 0x03
#define SOURCE_FORMAT_4CIF 0x04
#define SOURCE_FORMAT_16CIF 0x05
#define SOURCE_FORMAT_RESERVED 0x06
#define SOURCE_FORMAT_EXTENDED 0x07

#define PICTURE_CODING_TYPE_INTRA 0x00
#define PICTURE_CODING_TYPE_INTER 0x01

#define MB_TYPE_0_CBPC_0_0	0x80
#define MB_TYPE_0_CBPC_0_1	0x81
#define MB_TYPE_0_CBPC_1_0	0x82
#define MB_TYPE_0_CBPC_1_1	0x83
#define MB_TYPE_1_CBPC_0_0	0x84
#define MB_TYPE_1_CBPC_0_1	0x85
#define MB_TYPE_1_CBPC_1_0	0x86
#define MB_TYPE_1_CBPC_1_1	0x87
#define MB_TYPE_2_CBPC_0_0	0x88
#define MB_TYPE_2_CBPC_0_1	0x89
#define MB_TYPE_2_CBPC_1_0	0x8a
#define MB_TYPE_2_CBPC_1_1	0x8b
#define MB_TYPE_3_CBPC_0_0	0x8c
#define MB_TYPE_3_CBPC_0_1	0x8d
#define MB_TYPE_3_CBPC_1_0	0x8e
#define MB_TYPE_3_CBPC_1_1	0x8f
#define MB_TYPE_4_CBPC_0_0	0x90
#define MB_TYPE_4_CBPC_0_1	0x91
#define MB_TYPE_4_CBPC_1_0	0x92
#define MB_TYPE_4_CBPC_1_1	0x93
#define MCBPC_STUFFING		0xf0
#define MCBPC_ERROR			0xff

#define MB_TYPE_MASK		0x1c
#define MB_TYPE_0			0x00
#define MB_TYPE_1			0x04
#define MB_TYPE_2			0x08
#define MB_TYPE_3			0x0c
#define MB_TYPE_4			0x10

#define C_BLOCK_B_MASK		0x02
#define C_BLOCK_R_MASK		0x01

#define MCBPC_I_TABLE_SIZE 22

UInt8 MCBPC_I[MCBPC_I_TABLE_SIZE] = {
	2, MB_TYPE_3_CBPC_0_0, 4, 6, 8, MB_TYPE_3_CBPC_0_1, MB_TYPE_3_CBPC_1_0, MB_TYPE_3_CBPC_1_1,
	10, MB_TYPE_4_CBPC_0_0, 12, 14, 16, MB_TYPE_4_CBPC_0_1, MB_TYPE_4_CBPC_1_0, MB_TYPE_4_CBPC_1_1,
	18, MCBPC_ERROR, 20, MCBPC_ERROR, MCBPC_ERROR, MCBPC_STUFFING
};

#define MCBPC_P_TABLE_SIZE 42

UInt8 MCBPC_P[MCBPC_P_TABLE_SIZE] = {
	2, MB_TYPE_0_CBPC_0_0, 4, 6, 8, 10, MB_TYPE_2_CBPC_0_0, MB_TYPE_1_CBPC_0_0, 12, 14,
	MB_TYPE_0_CBPC_1_0, MB_TYPE_0_CBPC_0_1, 16, 18, 20, MB_TYPE_3_CBPC_0_0, 22, 24, 26, 28,
	MB_TYPE_4_CBPC_0_0, MB_TYPE_0_CBPC_1_1, 30, 32, 34, MB_TYPE_3_CBPC_1_1, MB_TYPE_2_CBPC_1_0,
	MB_TYPE_2_CBPC_0_1, MB_TYPE_1_CBPC_1_0, MB_TYPE_1_CBPC_0_1, 36, 38, 40, MB_TYPE_3_CBPC_1_0,
	MB_TYPE_3_CBPC_0_1, MB_TYPE_2_CBPC_1_1, MCBPC_ERROR, MCBPC_STUFFING, MB_TYPE_4_CBPC_1_1,
	MB_TYPE_4_CBPC_1_0, MB_TYPE_4_CBPC_0_1, MB_TYPE_1_CBPC_1_1
};

// coded as 1|000|aaaa where aaaa
// encodes which y blocks are
// coded and which aren't
#define CBPY_0_0_0_0		0x80
#define CBPY_0_0_0_1		0x81
#define CBPY_0_0_1_0		0x82
#define CBPY_0_0_1_1		0x83
#define CBPY_0_1_0_0		0x84
#define CBPY_0_1_0_1		0x85
#define CBPY_0_1_1_0		0x86
#define CBPY_0_1_1_1		0x87
#define CBPY_1_0_0_0		0x88
#define CBPY_1_0_0_1		0x89
#define CBPY_1_0_1_0		0x8a
#define CBPY_1_0_1_1		0x8b
#define CBPY_1_1_0_0		0x8c
#define CBPY_1_1_0_1		0x8d
#define CBPY_1_1_1_0		0x8e
#define CBPY_1_1_1_1		0x8f
#define CBPY_ERROR			0xff

#define Y_BLOCK_1_MASK		0x08
#define Y_BLOCK_2_MASK		0x04
#define Y_BLOCK_3_MASK		0x02
#define Y_BLOCK_4_MASK		0x01

#define CBPY_I_TABLE_SIZE 32

UInt8 CBPY_I[CBPY_I_TABLE_SIZE] = {
	2, 4, 6, 8, 10, CBPY_1_1_1_1, 12, 14, 16, 18, 20, 22, 24, 26, 28, CBPY_0_0_0_0, CBPY_1_1_0_0, 
	CBPY_1_0_1_0, CBPY_1_1_1_0, CBPY_0_1_0_1, CBPY_1_1_0_1, CBPY_0_0_1_1, CBPY_1_0_1_1,
	CBPY_0_1_1_1, CBPY_ERROR, 30, CBPY_1_0_0_0, CBPY_0_1_0_0, CBPY_0_0_1_0, CBPY_0_0_0_1,
	CBPY_0_1_1_0, CBPY_1_0_0_1
};

#define CBPY_P_TABLE_SIZE 32

UInt8 CBPY_P[CBPY_P_TABLE_SIZE] = {
	2, 4, 6, 8, 10, CBPY_0_0_0_0, 12, 14, 16, 18, 20, 22, 24, 26, 28, CBPY_1_1_1_1, CBPY_0_0_1_1, 
	CBPY_0_1_0_1, CBPY_0_0_0_1, CBPY_1_0_1_0, CBPY_0_0_1_0, CBPY_1_1_0_0, CBPY_0_1_0_0,
	CBPY_1_0_0_0, CBPY_ERROR, 30, CBPY_0_1_1_1, CBPY_1_0_1_1, CBPY_1_1_0_1, CBPY_1_1_1_0,
	CBPY_1_0_0_1, CBPY_0_1_1_0
};

#define MVD_PLUS_32  0xa0
#define MVD_PLUS_33  0xa1
#define MVD_PLUS_34  0xa2
#define MVD_PLUS_35  0xa3
#define MVD_PLUS_36  0xa4
#define MVD_PLUS_37  0xa5
#define MVD_PLUS_38  0xa6
#define MVD_PLUS_39  0xa7
#define MVD_PLUS_40  0xa8
#define MVD_PLUS_41  0xa9
#define MVD_PLUS_42  0xaa
#define MVD_PLUS_43  0xab
#define MVD_PLUS_44  0xac
#define MVD_PLUS_45  0xad
#define MVD_PLUS_46  0xae
#define MVD_PLUS_47  0xaf
#define MVD_PLUS_48  0xb0
#define MVD_PLUS_49  0xb1
#define MVD_PLUS_50  0xb2
#define MVD_PLUS_51  0xb3
#define MVD_PLUS_52  0xb4
#define MVD_PLUS_53  0xb5
#define MVD_PLUS_54  0xb6
#define MVD_PLUS_55  0xb7
#define MVD_PLUS_56  0xb8
#define MVD_PLUS_57  0xb9
#define MVD_PLUS_58  0xba
#define MVD_PLUS_59  0xbb
#define MVD_PLUS_60  0xbc
#define MVD_PLUS_61  0xbd
#define MVD_PLUS_62  0xbe
#define MVD_PLUS_63  0xbf
#define MVD_ZERO	 0xc0
#define MVD_MINUS_63 0xc1
#define MVD_MINUS_62 0xc2
#define MVD_MINUS_61 0xc3
#define MVD_MINUS_60 0xc4
#define MVD_MINUS_59 0xc5
#define MVD_MINUS_58 0xc6
#define MVD_MINUS_57 0xc7
#define MVD_MINUS_56 0xc8
#define MVD_MINUS_55 0xc9
#define MVD_MINUS_54 0xca
#define MVD_MINUS_53 0xcb
#define MVD_MINUS_52 0xcc
#define MVD_MINUS_51 0xcd
#define MVD_MINUS_50 0xce
#define MVD_MINUS_49 0xcf
#define MVD_MINUS_48 0xd0
#define MVD_MINUS_47 0xd1
#define MVD_MINUS_46 0xd2
#define MVD_MINUS_45 0xd3
#define MVD_MINUS_44 0xd4
#define MVD_MINUS_43 0xd5
#define MVD_MINUS_42 0xd6
#define MVD_MINUS_41 0xd7
#define MVD_MINUS_40 0xd8
#define MVD_MINUS_39 0xd9
#define MVD_MINUS_38 0xda
#define MVD_MINUS_37 0xdb
#define MVD_MINUS_36 0xdc
#define MVD_MINUS_35 0xdd
#define MVD_MINUS_34 0xde
#define MVD_MINUS_33 0xdf
#define MVD_ERROR	 0xff

#define MVD_TABLE_SIZE 130

UInt8 MVD[MVD_TABLE_SIZE] = {
	2, MVD_ZERO, 4, 6, 8, 10, MVD_MINUS_63, MVD_PLUS_63, 12, 14, MVD_MINUS_62, MVD_PLUS_62, 16, 18, MVD_MINUS_61, MVD_PLUS_61,
	20, 22, 24, 26, 28, 30, 32, 34, 36, 38, MVD_MINUS_60, MVD_PLUS_60, 40, 42, 44, 46, 48, 50, MVD_MINUS_57, MVD_PLUS_57,
	MVD_MINUS_58, MVD_PLUS_58, MVD_MINUS_59, MVD_PLUS_59, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76, 78, 80, 82, 84,
	86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108, 110, MVD_MINUS_54, MVD_PLUS_54, MVD_MINUS_55, MVD_PLUS_55,
	MVD_MINUS_56, MVD_PLUS_56, MVD_ERROR, 112, 114, 116, 118, 120, 122, 124, MVD_MINUS_40, MVD_PLUS_40, MVD_MINUS_41,
	MVD_PLUS_41, MVD_MINUS_42, MVD_PLUS_42, MVD_MINUS_43, MVD_PLUS_43, MVD_MINUS_44, MVD_PLUS_44, MVD_MINUS_45, MVD_PLUS_45,
	MVD_MINUS_46, MVD_PLUS_46, MVD_MINUS_47, MVD_PLUS_47, MVD_MINUS_48, MVD_PLUS_48, MVD_MINUS_49, MVD_PLUS_49, MVD_MINUS_50,
	MVD_PLUS_50, MVD_MINUS_51, MVD_PLUS_51, MVD_MINUS_52, MVD_PLUS_52, MVD_MINUS_53, MVD_PLUS_53, 126, 128, MVD_MINUS_34,
	MVD_PLUS_34, MVD_MINUS_35, MVD_PLUS_35, MVD_MINUS_36, MVD_PLUS_36, MVD_MINUS_37, MVD_PLUS_37, MVD_MINUS_38, MVD_PLUS_38,
	MVD_MINUS_39, MVD_PLUS_39, MVD_ERROR, MVD_PLUS_32, MVD_MINUS_33, MVD_PLUS_33
};

#define TCOEF_OK_LAST_0		0xf0
#define TCOEF_OK_LAST_1		0xf1
#define TCOEF_ESCAPE		0xf2
#define TCOEF_ERROR			0xff

#define TCOEF_TABLE_SIZE 86

UInt8 TCOEF[TCOEF_TABLE_SIZE] = {
	2, 4, 6, 8, 76, 10, 12, 14, 16, 18, 76, 74, 20, 22, 24, 80, 72, 26, 74, 84, 28, 30, 32,
	34, 80, 72, 74, 76, 36, 38, 40, 42, 44, 80, 46, 72, 48, 70, 50, TCOEF_ESCAPE, 52, 80, 54,
	72, 72, 56, 82, 58, 60, 80, 62, 64, 66, 82, 82, 74, 74, 84, 84, 76, TCOEF_ERROR, 68, 72,
	80, 70, 78, 74, 84, 82, 74, 72, 72, 74, 74, 76, 76, TCOEF_OK_LAST_0, TCOEF_OK_LAST_0,
	80, 80, 82, 82, 84, 84, TCOEF_OK_LAST_1, TCOEF_OK_LAST_1
};

#pragma mark Function Prototypes

// Called when the whole data between two GOB headers fits within one
// packet (Mode A)
void _XMRTPH263Packetizer_PacketizeCompleteGOBs(ComponentInstance packetBuilder,
												const RTPMPSampleDataParams *sampleData,
												RTPPacketGroupRef packetGroup,
												UInt8 sourceFormat,
												UInt8 pictureCodingType,
												UInt32 dataStartIndex, 
												UInt32 dataLength,
												Boolean isLastPacket);

// Called when it is required to split the data stream at MB boundaries.
// Thus, the first packet generated will be Mode A, the subsequent ones mode B
void _XMRTPH263Packetizer_PacketizeLongGOB(ComponentInstance packetBuilder,
										   UInt32 maxPacketSize,
										   const RTPMPSampleDataParams *sampleData,
										   RTPPacketGroupRef packetGroup,
										   UInt8 sourceFormat,
										   UInt8 pictureCodingType,
										   UInt32 gobStartIndex,
										   UInt32 gobLength,
										   Boolean isLastGOB);

// Callend from _XMRTPH263Packetizer_PacketizeLongGOB when the first packet
// of a Long GOB is determined. This will send a Mode A packet.
void _XMRTPH263Packetizer_PacketizeGOBStart(ComponentInstance packetBuilder,
											const RTPMPSampleDataParams *sampleData,
											RTPPacketGroupRef packetGroup,
											UInt8 sourceFormat,
											UInt8 pictureCodingType,
											UInt32 gobStartIndex,
											UInt32 indexOfMBAfterPacket,
											UInt8 bitOfMBAfterPacket);

// Called from _XMRTPH263Packetizer_PacketizeLongGOB to with the
// packet boundaries given.
void _XMRTPH263Packetizer_PacketizeGOBPart(ComponentInstance packetBuilder,
										   const RTPMPSampleDataParams *sampleData,
										   RTPPacketGroupRef packetGroup,
										   UInt8 sourceFormat,
										   UInt8 pictureCodingType,
										   UInt8 quant,
										   UInt8 gobn,
										   UInt8 mba,
										   UInt8 hmv,
										   UInt8 vmv,
										   UInt32 mbStartIndex,
										   UInt8 mbStartBit,
										   UInt32 indexOfMBAfterPacket,
										   UInt8 bitOfMBAfterPacket,
										   Boolean isLastPacket);										   

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
	RTPPacketGroupRef packetGroupRef;
	const UInt8 *data = sampleData->data;
	UInt32 maxPacketLength = globals->maxPacketSize - 4;	// substracting 4 bytes for Mode A
	UInt32 frameLength = sampleData->dataLength;
	
	// Adjusting data length by substracting any zero bytes at the end
	if(data[frameLength-2] == 0 && data[frameLength-1] == 0)
	{
		if(data[frameLength-3] == 0)
		{
			frameLength -= 2;
		}
		else
		{
			frameLength -= 1;
		}
	}

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
	
	UInt32 remainingLength = frameLength;
	UInt32 dataStartIndex = 0;
	
	UInt8 lastGOBNumber;
	
	switch(sourceFormat)
	{
		case SOURCE_FORMAT_SQCIF:
			lastGOBNumber = 5;
			break;
		case SOURCE_FORMAT_QCIF:
			lastGOBNumber = 8;
			break;
		case SOURCE_FORMAT_CIF:
		case SOURCE_FORMAT_4CIF:
		case SOURCE_FORMAT_16CIF:
			lastGOBNumber = 17;
			break;
	}
		
	while(remainingLength > maxPacketLength)
	{
		UInt8 gobNumber = (data[dataStartIndex+2] >> 2) & 0x1f;
		
		if(gobNumber == lastGOBNumber)
		{
			_XMRTPH263Packetizer_PacketizeLongGOB(globals->packetBuilder,
												  globals->maxPacketSize,
												  sampleData,
												  packetGroupRef,
												  sourceFormat,
												  pictureCodingType,
												  dataStartIndex,
												  remainingLength,
												  true);
												  
			remainingLength = 0;
		}
		else
		{
			UInt32 scanIndex = dataStartIndex + maxPacketLength;
			UInt32 firstPossibleGOBStartIndex = dataStartIndex + 2;
			UInt32 gobStartIndex = 0;
			
			// find gob header
			while(scanIndex > firstPossibleGOBStartIndex)
			{
				if(data[scanIndex] == 0)
				{
					if((data[scanIndex-1] == 0) &&
					   (data[scanIndex+1] != 0))
					{
						gobStartIndex = scanIndex-1;
						break;
					}
					else if((data[scanIndex+1] == 0) &&
							(data[scanIndex+2] != 0))
					{
						gobStartIndex = scanIndex;
						break;
					}
				}
				
				scanIndex -= 2;
			}
				
			// if GOB header found, pack it.
			if(gobStartIndex != 0)
			{
				UInt32 dataLength = gobStartIndex - dataStartIndex;
				
				//printf("Packetizing Mode A from %d to %d (%d)\n", dataStartIndex, dataStartIndex+dataLength, dataLength);
					
				_XMRTPH263Packetizer_PacketizeCompleteGOBs(globals->packetBuilder,
														   sampleData,
														   packetGroupRef,
														   sourceFormat,
														   pictureCodingType,
														   dataStartIndex,
														   dataLength,
														   false);
				dataStartIndex = gobStartIndex;
				remainingLength -= dataLength;
			}
			else
			{
				UInt32 scanIndex = dataStartIndex + maxPacketLength;
				UInt32 gobStartIndex = 0;
				
				// scanning for the next GOB header
				while(scanIndex < frameLength)
				{
					if(data[scanIndex] == 0)
					{
						if((data[scanIndex-1] == 0) &&
						   (data[scanIndex+1] != 0))
						{
							gobStartIndex = scanIndex-1;
							break;
						}
						else if((data[scanIndex+1] == 0) &&
								(data[scanIndex+2] != 0))
						{
							gobStartIndex = scanIndex;
							break;
						}
					}
					
					scanIndex += 2;
				}
				
				if(gobStartIndex == 0)
				{
					// it may be that QuickTime does omit some GOBS if they are completely zero
					// thus, it we consider this case here as having the last GOB
					_XMRTPH263Packetizer_PacketizeLongGOB(globals->packetBuilder,
														  globals->maxPacketSize,
														  sampleData,
														  packetGroupRef,
														  sourceFormat,
														  pictureCodingType,
														  dataStartIndex,
														  remainingLength,
														  true);
					*outFlags = 0;
					return noErr;
				}
				else
				{
					UInt32 dataLength = gobStartIndex - dataStartIndex;
					//printf("Packetizing Mode A/B packets from %d to %d (%d)\n", dataStartIndex, gobStartIndex, dataLength);
					_XMRTPH263Packetizer_PacketizeLongGOB(globals->packetBuilder,
														  globals->maxPacketSize,
														  sampleData,
														  packetGroupRef,
														  sourceFormat,
														  pictureCodingType,
														  dataStartIndex,
														  dataLength,
														  false);
					dataStartIndex = gobStartIndex;
					remainingLength -= dataLength;
				}
			}
		}
	}
		
	if(remainingLength != 0)
	{
		//printf("Packing Rest as Mode A packet from %d to %d (%d)\n", dataStartIndex, dataStartIndex+remainingLength, remainingLength);
		_XMRTPH263Packetizer_PacketizeCompleteGOBs(globals->packetBuilder,
												   sampleData,
												   packetGroupRef,
												   sourceFormat,
												   pictureCodingType,
												   dataStartIndex,
												   remainingLength,
												   true);
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

void _XMRTPH263Packetizer_PacketizeCompleteGOBs(ComponentInstance packetBuilder,
											    const RTPMPSampleDataParams *sampleData,
											    RTPPacketGroupRef packetGroup,
											    UInt8 sourceFormat,
											    UInt8 pictureCodingType,
											    UInt32 dataStartIndex, 
											    UInt32 dataLength,
											    Boolean isLastPacket)
{
	UInt8 header[4];
	
	// F, P, SBIT and EBIT are zero
	header[0] = 0;
	 
	// U, S, A are always zero
	header[1] = 0;	
	header[1] |= (sourceFormat << 5);
	header[1] |= (pictureCodingType << 4);
	
	// DBQ, TRB and TR are always zero
	header[2] = 0;
	header[3] = 0;
	
	RTPPacketRef packet;
	
	RTPPBBeginPacket(packetBuilder,
					 0,
					 packetGroup,
					 dataLength+4,
					 &packet);
	
	RTPPBAddPacketLiteralData(packetBuilder,
							  0,
							  packetGroup,
							  packet,
							  header,
							  4,
							  NULL);
	
	RTPPBAddPacketSampleData(packetBuilder,
							 0,
							 packetGroup,
							 packet,
							 (RTPMPSampleDataParams *)sampleData,
							 dataStartIndex,
							 dataLength,
							 NULL);
	
	SInt32 flags = 0;
	if(isLastPacket)
	{
		flags = 1;
	}
	RTPPBEndPacket(packetBuilder,
				   flags,
				   packetGroup,
				   packet,
				   0,
				   0);
}

void _XMRTPH263Packetizer_PacketizeLongGOB(ComponentInstance packetBuilder,
										   UInt32 maxPacketSize,
										   const RTPMPSampleDataParams *sampleData,
										   RTPPacketGroupRef packetGroup,
										   UInt8 sourceFormat,
										   UInt8 pictureCodingType,
										   UInt32 gobStartIndex,
										   UInt32 gobLength,
										   Boolean isLastGOB)
{
	// subtracting 8 bytes for Mode B header
	maxPacketSize -= 8;
	
	const UInt8 *data = sampleData->data;
	UInt32 dataIndex = gobStartIndex;
	UInt8 mask = 0x80;
	
	UInt8 gobn = (data[dataIndex+2] >> 2) & 0x1f;
	UInt8 quant;
	
	UInt32 numberOfMBs = 0;
	switch(sourceFormat)
	{
		case SOURCE_FORMAT_SQCIF:
			numberOfMBs = 8;
			break;
		case SOURCE_FORMAT_QCIF:
			numberOfMBs = 11;
			break;
		case SOURCE_FORMAT_CIF:
			numberOfMBs = 22;
			break;
		case SOURCE_FORMAT_4CIF:
			numberOfMBs = 88;
			break;
		case SOURCE_FORMAT_16CIF:
			numberOfMBs = 352;
			break;
	}
	
	if(gobn == 0)
	{
		quant = (data[dataIndex+5] & 0x1f);
		
		scanBytes(dataIndex, 6);
		scanBit(dataIndex, mask);
		
		UInt8 pei;
		readBit(pei, data, dataIndex, mask);
		while(pei != 0)
		{
			scanBytes(dataIndex, 1);
			readBit(pei, data, dataIndex, mask);
		}
	}
	else
	{
		quant = (data[dataIndex+3] >> 3) & 0x1f;
		
		scanBytes(dataIndex, 3);
		scanBits(dataIndex, mask, 5); 
	}
	
	UInt8 *mcbpcTable;
	UInt32 mcbpcTableSize;
	
	if(pictureCodingType == PICTURE_CODING_TYPE_INTRA)
	{
		mcbpcTable = MCBPC_I;
		mcbpcTableSize = MCBPC_I_TABLE_SIZE;
	}
	else
	{
		mcbpcTable = MCBPC_P;
		mcbpcTableSize = MCBPC_P_TABLE_SIZE;
	}
	
	UInt32 remainingLength = gobLength;

	UInt32 packetStartIndex = gobStartIndex;
	UInt8 packetStartBit = 0x80;
	UInt8 packetStartQUANT = quant;
	UInt8 packetStartMBA = 0;
	UInt8 packetStartHMV = 0;
	UInt8 packetStartVMV = 0;
	UInt32 lengthToPacketize = 0;
	
	UInt8 mba = 0;
	UInt32 mbStartIndex = 0;
	UInt8 mbStartBit = 0;
	UInt8 hmv = 0;
	UInt8 vmv = 0;
	
	while(remainingLength > maxPacketSize)
	{
		Boolean mbIsEncoded = false;
		if(pictureCodingType == PICTURE_CODING_TYPE_INTRA)
		{
			mbIsEncoded = true;
		}
		else
		{
			UInt8 cod;
			readBit(cod, data, dataIndex, mask);
			if(cod == 0)
			{
				mbIsEncoded = true;
			}
		}
		
		if(mbIsEncoded == true)
		{
			UInt8 mcbpc;
			UInt8 cbpy;
			
			// reading the MCBPC field
			readSymbol(mcbpc, data, dataIndex, mask, mcbpcTable, mcbpcTableSize);
			
			/*if(mcbpc == MCBPC_STUFFING)
			{
				printf("STUFFING\n");
				return;
			}
			
			if(mcbpc == MCBPC_ERROR)
			{
				printf("MCBPC_ERROR\n");
				return;
			}*/
			
			// if mbType is zero or one, use the P table for CBPY
			// if mbType is three or four, use the I table for CBPY
			UInt8 mbType = (mcbpc & MB_TYPE_MASK);
			UInt8 *cbpyTable;
			UInt32 cbpyTableSize;
			switch(mbType)
			{
				case MB_TYPE_0:
				case MB_TYPE_1:
					cbpyTable = CBPY_P;
					cbpyTableSize = CBPY_P_TABLE_SIZE;
					break;
				case MB_TYPE_3:
				case MB_TYPE_4:
					cbpyTable = CBPY_I;
					cbpyTableSize = CBPY_I_TABLE_SIZE;
					break;
				case MB_TYPE_2:
					printf("MB_TYPE_2\n");
					return;
				default:
					printf("EXITING UNKNOWN MB_TYPE\n");
					return;
			}
			
			// reading the CBPY field
			readSymbol(cbpy, data, dataIndex, mask, cbpyTable, cbpyTableSize);
			
			// if mbType is one or four, read the DQUANT field and adjust the
			// QUANT value accordingly
			if(mbType == MB_TYPE_1 ||
			   mbType == MB_TYPE_4)
			{
				UInt8 dquant;
				readBits(dquant, data, dataIndex, mask, 2);
				
				switch(dquant)
				{
					case 0:
						quant -= 1;
						break;
					case 1:
						quant -= 2;
						break;
					case 2:
						quant += 1;
						break;
					case 3:
						quant += 2;
						break;
					default:
						break;
				}
			}
			
			// if mbType is zero or one, read the motion vectors and adjust the
			// motion vector predictors
			if(mbType == MB_TYPE_0 ||
			   mbType == MB_TYPE_1)
			{
				UInt8 hmvd;
			
				readSymbol(hmvd, data, dataIndex, mask, MVD, MVD_TABLE_SIZE);
				
				if(hmvd == MVD_ZERO)
				{
					hmvd = 0;
				}
				
				hmvd &= 0x7f;
				hmv += hmvd;
				
				if((hmv & 0x40) == 0 &&
				   (hmv >= 0x20))
				{
					hmv |= 0xc0;
				}
				else if((hmv & 0x40) != 0 &&
						(hmv < 0x60))
				{
					hmv &= 0x3f;
				}
				
				UInt8 vmvd;
				
				readSymbol(vmvd, data, dataIndex, mask, MVD, MVD_TABLE_SIZE);
				
				if(vmvd == MVD_ZERO)
				{
					vmvd = 0;
				}
				
				vmvd &= 0x7f;
				vmv += vmvd;
				
				if((vmv & 0x40) == 0 &&
				   (vmv >= 0x20))
				{
					vmv |= 0xc0;
				}
				else if((vmv & 0x40) != 0 &&
						(vmv < 0x60))
				{
					vmv &= 0x3f;
				}
			}
			else
			{
				hmv = 0;
				vmv = 0;
			}
			
			scanBlockData(data, dataIndex, mask, mbType, (cbpy & Y_BLOCK_1_MASK));
			scanBlockData(data, dataIndex, mask, mbType, (cbpy & Y_BLOCK_2_MASK));
			scanBlockData(data, dataIndex, mask, mbType, (cbpy & Y_BLOCK_3_MASK));
			scanBlockData(data, dataIndex, mask, mbType, (cbpy & Y_BLOCK_4_MASK));
			scanBlockData(data, dataIndex, mask, mbType, (mcbpc & C_BLOCK_B_MASK));
			scanBlockData(data, dataIndex, mask, mbType, (mcbpc & C_BLOCK_R_MASK));
		}
		
		UInt32 newLengthToPacketize = dataIndex - packetStartIndex;
		if(mask != 0x80)
		{
			newLengthToPacketize += 1;
		}
		
		if(newLengthToPacketize > maxPacketSize)
		{
			if(packetStartIndex == gobStartIndex)
			{
				_XMRTPH263Packetizer_PacketizeGOBStart(packetBuilder,
													   sampleData,
													   packetGroup,
													   sourceFormat,
													   pictureCodingType,
													   packetStartIndex,
													   mbStartIndex,
													   mbStartBit);
			}
			else
			{
				_XMRTPH263Packetizer_PacketizeGOBPart(packetBuilder,
													  sampleData,
													  packetGroup,
													  sourceFormat,
													  pictureCodingType, 
													  packetStartQUANT,
													  gobn,
													  packetStartMBA,
													  packetStartHMV,
													  packetStartVMV,
													  packetStartIndex, 
													  packetStartBit,
													  mbStartIndex,
													  mbStartBit,
													  false);
			}
			packetStartQUANT = quant;
			packetStartMBA = mba;
			packetStartHMV = hmv;
			packetStartVMV = vmv;
			
			packetStartIndex = mbStartIndex;
			packetStartBit = mbStartBit;
			newLengthToPacketize = dataIndex - packetStartIndex;
			if(mask != 0x80)
			{
				newLengthToPacketize += 1;
			}
		}
		
		mbStartIndex = dataIndex;
		mbStartBit = mask;
		lengthToPacketize = newLengthToPacketize;
		remainingLength = (gobStartIndex + gobLength) - mbStartIndex;
		
		mba += 1;
	}
	
	if(packetStartIndex == gobStartIndex)
	{
		if(packetStartIndex == gobStartIndex)
		{
			_XMRTPH263Packetizer_PacketizeGOBStart(packetBuilder,
												   sampleData,
												   packetGroup,
												   sourceFormat,
												   pictureCodingType,
												   packetStartIndex,
												   mbStartIndex,
												   mbStartBit);
		}
		else
		{
			_XMRTPH263Packetizer_PacketizeGOBPart(packetBuilder,
												  sampleData,
												  packetGroup,
												  sourceFormat,
												  pictureCodingType, 
												  packetStartQUANT,
												  gobn,
												  packetStartMBA,
												  packetStartHMV,
												  packetStartVMV,
												  packetStartIndex, 
												  packetStartBit,
												  mbStartIndex,
												  mbStartBit,
												  false);
		}
	}
	
	_XMRTPH263Packetizer_PacketizeGOBPart(packetBuilder,
										  sampleData,
										  packetGroup,
										  sourceFormat,
										  pictureCodingType,
										  quant,
										  gobn,
										  mba,
										  hmv,
										  vmv,
										  mbStartIndex,
										  mbStartBit,
										  (gobStartIndex+gobLength),
										  0x80,
										  isLastGOB);
}

// Callend from _XMRTPH263Packetizer_PacketizeLongGOB when the first packet
// of a Long GOB is determined. This will send a Mode A packet.
void _XMRTPH263Packetizer_PacketizeGOBStart(ComponentInstance packetBuilder,
											const RTPMPSampleDataParams *sampleData,
											RTPPacketGroupRef packetGroup,
											UInt8 sourceFormat,
											UInt8 pictureCodingType,
											UInt32 gobStartIndex,
											UInt32 indexOfMBAfterPacket,
											UInt8 bitOfMBAfterPacket)
{
	UInt8 header[4];
	
	UInt32 dataLength = indexOfMBAfterPacket - gobStartIndex + 1;
	
	// F, P, SBIT are zero
	header[0] = 0;
	
	// determining EBIT
	UInt8 ebit;
	switch(bitOfMBAfterPacket)
	{
		case 0x80:
			ebit = 0x00;
			dataLength -= 1;	// adjusting the length in case of a byte boundary
			break;
		case 0x40:
			ebit = 0x07;
			break;
		case 0x20:
			ebit = 0x06;
			break;
		case 0x10:
			ebit = 0x05;
			break;
		case 0x08:
			ebit = 0x04;
			break;
		case 0x04:
			ebit = 0x03;
			break;
		case 0x02:
			ebit = 0x02;
			break;
		case 0x01:
			ebit = 0x01;
			break;
	}
	
	header[0] |= (ebit & 0x07);
	
	// U, S, A are always zero
	header[1] = 0;
	header[1] |= (sourceFormat << 5) & 0xe0;
	header[1] |= (pictureCodingType << 4) & 0x10;
	
	// DBQ, TRB and TR are always zero
	header[2] = 0;
	header[3] = 0;
	
	RTPPacketRef packet;
	
	RTPPBBeginPacket(packetBuilder,
					 0,
					 packetGroup,
					 dataLength+4,
					 &packet);
	
	RTPPBAddPacketLiteralData(packetBuilder,
							  0,
							  packetGroup,
							  packet,
							  header,
							  4,
							  NULL);
	
	RTPPBAddPacketSampleData(packetBuilder,
							 0,
							 packetGroup,
							 packet,
							 (RTPMPSampleDataParams *)sampleData,
							 gobStartIndex,
							 dataLength,
							 NULL);
	
	RTPPBEndPacket(packetBuilder,
				   0,
				   packetGroup,
				   packet,
				   0,
				   0);
}

// Called from _XMRTPH263Packetizer_PacketizeLongGOB to with the
// packet boundaries given.
void _XMRTPH263Packetizer_PacketizeGOBPart(ComponentInstance packetBuilder,
										   const RTPMPSampleDataParams *sampleData,
										   RTPPacketGroupRef packetGroup,
										   UInt8 sourceFormat,
										   UInt8 pictureCodingType,
										   UInt8 quant,
										   UInt8 gobn,
										   UInt8 mba,
										   UInt8 hmv,
										   UInt8 vmv,
										   UInt32 mbStartIndex,
										   UInt8 mbStartBit,
										   UInt32 indexOfMBAfterPacket,
										   UInt8 bitOfMBAfterPacket,
										   Boolean isLastPacket)
{
	UInt8 header[8];
	
	UInt32 dataLength = indexOfMBAfterPacket - mbStartIndex;
	
	// F is one, P is zero
	header[0] = 0x80;
	
	// determining SBIT
	UInt8 sbit;
	switch(mbStartBit)
	{
		case 0x80:
			sbit = 0;
			break;
		case 0x40:
			sbit = 1;
			break;
		case 0x20:
			sbit = 2;
			break;
		case 0x10:
			sbit = 3;
			break;
		case 0x08:
			sbit = 4;
			break;
		case 0x04:
			sbit = 5;
			break;
		case 0x02:
			sbit = 6;
			break;
		case 0x01:
			sbit = 7;
			break;
	}
	header[0] |= (sbit << 3) & 0x38;
	
	// determining EBIT
	UInt8 ebit;
	switch(bitOfMBAfterPacket)
	{
		case 0x80:
			ebit = 0x00;
			break;
		case 0x40:
			dataLength += 1;
			ebit = 0x07;
			break;
		case 0x20:
			dataLength += 1;
			ebit = 0x06;
			break;
		case 0x10:
			dataLength += 1;
			ebit = 0x05;
			break;
		case 0x08:
			dataLength += 1;
			ebit = 0x04;
			break;
		case 0x04:
			dataLength += 1;
			ebit = 0x03;
			break;
		case 0x02:
			dataLength += 1;
			ebit = 0x02;
			break;
		case 0x01:
			dataLength += 1;
			ebit = 0x01;
			break;
	}
	header[0] |= (ebit & 0x07);
	
	// seting SRC and QUANT
	header[1] = 0;
	header[1] |= (sourceFormat << 5) & 0xe0;
	header[1] |= (quant & 0x1f);
	
	// setting GOBN
	header[2] = 0;
	header[2] |= (gobn << 3) & 0xf8;
	
	// setting MBA. Since only CIF format is supported, MBA never exceeds the value of 21.
	// Thus only five bits are actually used and GOBN fits within the third byte
	header[3] = 0;
	header[3] |= (mba << 2) & 0xfc;
	
	// U, S, A are always zero
	header[4] = 0;
	header[5] = 0;
	header[6] = 0;
	header[4] |= (pictureCodingType << 7) & 0x80;
	
	// Setting HVM1
	header[4] |= (hmv >> 3) & 0x0f;
	header[5] |= (hmv << 5) & 0xe0;
	
	// Setting VMV1
	header[5] |= (vmv >> 2) & 0x1f;
	header[6] |= (vmv << 6) & 0xc0;
	
	// HMV2 and VMV2 are always zero
	header[7] = 0;
	
	RTPPacketRef packet;
	
	RTPPBBeginPacket(packetBuilder,
					 0,
					 packetGroup,
					 dataLength+8,
					 &packet);
	
	RTPPBAddPacketLiteralData(packetBuilder,
							  0,
							  packetGroup,
							  packet,
							  header,
							  8,
							  NULL);
	
	RTPPBAddPacketSampleData(packetBuilder,
							 0,
							 packetGroup,
							 packet,
							 (RTPMPSampleDataParams *)sampleData,
							 mbStartIndex,
							 dataLength,
							 NULL);
	
	SInt32 flags = 0;
	if(isLastPacket)
	{
		flags = 1;
	}
	RTPPBEndPacket(packetBuilder,
				   flags,
				   packetGroup,
				   packet,
				   0,
				   0);
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
