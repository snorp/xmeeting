/*
 * $Id: XMRTPH263PlusPacketizer.c,v 1.4 2008/10/11 18:56:55 hfriederich Exp $
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
// while (remainingLength > maxPacketSize) {
//	   if (currentGOBNumber == LastGOBNumber) {
//		   packetizeRemainingDataAsModeAModeBPackets();
//		   remainingLength = 0;
//	   } else {
//         startAt(currentIndex + maxPacketLength);
//	       searchBackwardsForGOBStartHeader();
//         if (GOB start header is found) {
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
// if (remainingLength != 0) {
//     packetizeRemainingDataAsModeAPacket();
// }
//
// The algorithm to packetize long GOBs goes as follows:
//
// remainingLength = gobLength;
// lengthToPacketize = 0;
// while (remainingLength > maxPacketSize) {
//     findNextMBBoundary();
//	   lengthToPacketize += mbLength;
//	   remainingLength -= mbLength;
//     if (lengthToPacketize > maxPacketSize) {
//         packetizeDataUpToPreviousMBBoundary();
//		   lengthToPacketize -= dataLengthJustPacketized;
//     }
// }
// packetizeDataUpToMBBoundaryFound();
// packetizeRemainingData();
//
///////////////////////////////////////////////////////////////////////

#include "XMRTPH263PlusPacketizer.h"

#define kXMRTPH263PlusPacketizerVersion (0x00010001)

typedef struct
{
  ComponentInstance self;
  ComponentInstance target;
  ComponentInstance packetBuilder;
  TimeBase timeBase;
  TimeScale timeScale;
  UInt32 maxPacketSize;
} XMRTPH263PlusPacketizerGlobalsRecord, *XMRTPH263PlusPacketizerGlobals;

#define RTPMP_BASENAME()            XMRTPH263PlusPacketizer_
#define RTPMP_GLOBALS()             XMRTPH263PlusPacketizerGlobals storage

#define CALLCOMPONENT_BASENAME()    RTPMP_BASENAME()
#define CALLCOMPONENT_GLOBALS()     RTPMP_GLOBALS()

#define COMPONENT_DISPATCH_FILE     "XMRTPH263PlusPacketizerDispatch.h"
#define COMPONENT_UPP_SELECT_ROOT()	RTPMP

#include <CoreServices/Components.k.h>
#include <QuickTime/QTStreamingComponents.k.h>
#include <QuickTime/ComponentDispatchHelper.c>

#pragma mark -
#pragma mark H.263 Bitstream Analyzation Stuff

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

#define scanBits(theDataIndex, theMask, theLength) \
{ \
  for (unsigned dummy = 0; dummy < theLength; dummy++) { \
    scanBit(theDataIndex, theMask); \
  } \
}

#define readBits(out, theData, theDataIndex, theMask, theLength) \
out = 0; \
{ \
  UInt32 counter = theLength; \
  UInt8 bit; \
  while (counter != 0) { \
    readBit(bit, theData, theDataIndex, theMask); \
    counter--; \
    if (bit != 0) { \
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
  if (bit != 0) { \
    theTableIndex++; \
  } \
  theTableIndex = theTable[theTableIndex]; \
}

#define SOURCE_FORMAT_FORBIDDEN 0x00
#define SOURCE_FORMAT_SQCIF     0x01
#define SOURCE_FORMAT_QCIF      0x02
#define SOURCE_FORMAT_CIF       0x03
#define SOURCE_FORMAT_4CIF      0x04
#define SOURCE_FORMAT_16CIF     0x05
#define SOURCE_FORMAT_RESERVED  0x06
#define SOURCE_FORMAT_EXTENDED  0x07

#pragma mark -
#pragma mark Function Prototypes

void _XMRTPH263PlusPacketizer_PacketizeCompleteGOBs(ComponentInstance packetBuilder,
                                                    const RTPMPSampleDataParams *sampleData,
                                                    RTPPacketGroupRef packetGroup,
                                                    UInt32 dataStartIndex,
                                                    UInt32 dataLength,
                                                    Boolean isLastPacket);

void _XMRTPH263PlusPacketizer_PacketizeLongGOB(ComponentInstance packetBuilder,
                                               UInt32 maxPacketSize,
                                               const RTPMPSampleDataParams *sampleData,
                                               RTPPacketGroupRef packetGroup,
                                               UInt32 dataStartIndex,
                                               UInt32 dataLength,
                                               Boolean isLastPacket);

#pragma mark -
#pragma mark Standard Component Calls
	
ComponentResult XMRTPH263PlusPacketizer_Open(XMRTPH263PlusPacketizerGlobals globals, ComponentInstance self)
{
  ComponentResult err = noErr;
	
  globals = calloc(sizeof(XMRTPH263PlusPacketizerGlobalsRecord), 1);
  if (!globals) {
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

ComponentResult XMRTPH263PlusPacketizer_Close(XMRTPH263PlusPacketizerGlobals globals, ComponentInstance self)
{
  if (globals) {
    free(globals);
  }
	
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_Version(XMRTPH263PlusPacketizerGlobals globals)
{
  return kXMRTPH263PlusPacketizerVersion;
}

ComponentResult XMRTPH263PlusPacketizer_Target(XMRTPH263PlusPacketizerGlobals globals, ComponentInstance target)
{
  printf("XMRTPH263PlusPacketizer_Target called\n");
  globals->target = target;
  return noErr;
}

#pragma mark -
#pragma mark MediaPacketizer Component Calls

ComponentResult XMRTPH263PlusPacketizer_Initialize(XMRTPH263PlusPacketizerGlobals globals, SInt32 inFlags)
{
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_PreflightMedia(XMRTPH263PlusPacketizerGlobals globals,
                                                       OSType inMediaType,
                                                       SampleDescriptionHandle inSampleDescription)
{	
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_Idle(XMRTPH263PlusPacketizerGlobals globals, SInt32 inFlags, SInt32 *outFlags)
{
  *outFlags = 0;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetSampleData(XMRTPH263PlusPacketizerGlobals globals,
                                                      const RTPMPSampleDataParams *sampleData,
                                                      SInt32 *outFlags)
{	
  RTPPacketGroupRef packetGroupRef;
  const UInt8 *data = sampleData->data;
  UInt32 maxPacketLength = globals->maxPacketSize;
  UInt32 frameLength = sampleData->dataLength;
	
  // Adjusting data length by substracting any zero bytes at the end
  if (data[frameLength-2] == 0 && data[frameLength-1] == 0) {
    if (data[frameLength-3] == 0) {
      frameLength -= 2;
    } else {
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
	
  UInt32 remainingLength = frameLength;
  UInt32 dataStartIndex = 0;
	
  UInt8 lastGOBNumber;
	
  switch (sourceFormat) {
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
		
  while (remainingLength > maxPacketLength) {
    UInt8 gobNumber = (data[dataStartIndex+2] >> 2) & 0x1f;
		
    if (gobNumber == lastGOBNumber) {
      _XMRTPH263PlusPacketizer_PacketizeLongGOB(globals->packetBuilder,
                                                globals->maxPacketSize,
                                                sampleData,
                                                packetGroupRef,
                                                dataStartIndex,
                                                remainingLength,
                                                true);
												  
      remainingLength = 0;
    } else {
      UInt32 scanIndex = dataStartIndex + maxPacketLength;
      UInt32 firstPossibleGOBStartIndex = dataStartIndex + 2;
      UInt32 gobStartIndex = 0;
			
      // find gob header
      while (scanIndex > firstPossibleGOBStartIndex) {
        if (data[scanIndex] == 0) {
          if ((data[scanIndex-1] == 0) && (data[scanIndex+1] != 0)) {
            gobStartIndex = scanIndex-1;
            break;
          } else if ((data[scanIndex+1] == 0) && (data[scanIndex+2] != 0)) {
            gobStartIndex = scanIndex;
            break;
          }
        }
				
        scanIndex -= 2;
      }
				
      // if GOB header found, pack it.
      if (gobStartIndex != 0) {
        UInt32 dataLength = gobStartIndex - dataStartIndex;
				
        _XMRTPH263PlusPacketizer_PacketizeCompleteGOBs(globals->packetBuilder,
                                                       sampleData,
                                                       packetGroupRef,
                                                       dataStartIndex,
                                                       dataLength,
                                                       false);
        dataStartIndex = gobStartIndex;
        remainingLength -= dataLength;
        
      } else {
        UInt32 scanIndex = dataStartIndex + maxPacketLength;
        UInt32 gobStartIndex = 0;
				
        // scanning for the next GOB header
        while (scanIndex < frameLength) {
          if (data[scanIndex] == 0) {
            if ((data[scanIndex-1] == 0) && (data[scanIndex+1] != 0)) {
              gobStartIndex = scanIndex-1;
              break;
            } else if ((data[scanIndex+1] == 0) && (data[scanIndex+2] != 0)) {
              gobStartIndex = scanIndex;
              break;
            }
          }
					
          scanIndex += 2;
        }
				
        if (gobStartIndex == 0) {
          // it may be that QuickTime does omit some GOBS if they are completely zero
          // in this case, it is considered as having the last GOB
          _XMRTPH263PlusPacketizer_PacketizeLongGOB(globals->packetBuilder,
                                                    globals->maxPacketSize,
                                                    sampleData,
                                                    packetGroupRef,
                                                    dataStartIndex,
                                                    remainingLength,
                                                    true);
          *outFlags = 0;
          return noErr;
        } else {
          UInt32 dataLength = gobStartIndex - dataStartIndex;
					
          _XMRTPH263PlusPacketizer_PacketizeLongGOB(globals->packetBuilder,
                                                    globals->maxPacketSize,
                                                    sampleData,
                                                    packetGroupRef,
                                                    dataStartIndex,
                                                    dataLength,
                                                    false);
          dataStartIndex = gobStartIndex;
          remainingLength -= dataLength;
        }
      }
    }
  }
		
  if (remainingLength != 0) {
    _XMRTPH263PlusPacketizer_PacketizeCompleteGOBs(globals->packetBuilder,
                                                   sampleData,
                                                   packetGroupRef,
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

ComponentResult XMRTPH263PlusPacketizer_Flush(XMRTPH263PlusPacketizerGlobals globals, SInt32 inFlags, SInt32 *outFlags)
{
  *outFlags = 0;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_Reset(XMRTPH263PlusPacketizerGlobals globals, SInt32 inFlags)
{
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetInfo(XMRTPH263PlusPacketizerGlobals globals, OSType inSelector, const void *ioParams)
{
  printf("SetInfo called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetInfo(XMRTPH263PlusPacketizerGlobals globals, OSType inSelector, void *ioParams)
{
  printf("GetInfo called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetTimeScale(XMRTPH263PlusPacketizerGlobals globals, TimeScale inTimeScale)
{
  globals->timeScale = inTimeScale;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetTimeScale(XMRTPH263PlusPacketizerGlobals globals, TimeScale *outTimeScale)
{
  *outTimeScale = globals->timeScale;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetTimeBase(XMRTPH263PlusPacketizerGlobals globals, TimeBase inTimeBase)
{
  globals->timeBase = inTimeBase;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetTimeBase(XMRTPH263PlusPacketizerGlobals globals, TimeBase *outTimeBase)
{
  *outTimeBase = globals->timeBase;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_HasCharacteristic(XMRTPH263PlusPacketizerGlobals globals, OSType inSelector, Boolean *outHasIt)
{
  printf("HasCharacteristic called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetPacketBuilder(XMRTPH263PlusPacketizerGlobals globals, ComponentInstance inPacketBuilder)
{
  globals->packetBuilder = inPacketBuilder;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetPacketBuilder(XMRTPH263PlusPacketizerGlobals globals, ComponentInstance *outPacketBuilder)
{
  *outPacketBuilder = globals->packetBuilder;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetMediaType(XMRTPH263PlusPacketizerGlobals globals, OSType inMediaType)
{
  if (inMediaType != '+263') {
    return paramErr;
  }
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetMediaType(XMRTPH263PlusPacketizerGlobals globals, OSType *outMediaType)
{   
  *outMediaType = '+263';
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetMaxPacketSize(XMRTPH263PlusPacketizerGlobals globals, UInt32 inMaxPacketSize)
{
  globals->maxPacketSize = inMaxPacketSize;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetMaxPacketSize(XMRTPH263PlusPacketizerGlobals globals, UInt32 *outMaxPacketSize)
{
  *outMaxPacketSize = globals->maxPacketSize;
  return noErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetMaxPacketDuration(XMRTPH263PlusPacketizerGlobals globals, UInt32 inMaxPacketDuration)
{
  printf("SetMaxPacketDuration called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetMaxPacketDuration(XMRTPH263PlusPacketizerGlobals globals, UInt32 *outMaxPacketDuration)
{
  printf("GetMaxPacketDuration called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_DoUserDialog(XMRTPH263PlusPacketizerGlobals globals, ModalFilterUPP inFilterUPP, Boolean *canceled)
{
  printf("Do UserDialog called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_SetSettingsFromAtomContainerAtAtom(XMRTPH263PlusPacketizerGlobals globals,
                                                                           QTAtomContainer inContainer,
                                                                           QTAtom inParentAtom)
{
  printf("SetSettingsFromAtomContainer called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetSettingsIntoAtomContainerAtAtom(XMRTPH263PlusPacketizerGlobals globals,
                                                                           QTAtomContainer inOutContainer,
                                                                           QTAtom inParentAtom)
{
  printf("GetSettingsIntoAtomContainer called\n");
  return paramErr;
}

ComponentResult XMRTPH263PlusPacketizer_GetSettingsAsText(XMRTPH263PlusPacketizerGlobals globals, Handle *text)
{
  printf("GetSettingsAsText called\n");
  return paramErr;
}

#pragma mark -
#pragma mark Private Packetization Functions

void _XMRTPH263PlusPacketizer_PacketizeCompleteGOBs(ComponentInstance packetBuilder,
                                                    const RTPMPSampleDataParams *sampleData,
                                                    RTPPacketGroupRef packetGroup,
                                                    UInt32 dataStartIndex,
                                                    UInt32 dataLength,
                                                    Boolean isLastPacket)
{
  UInt8 header[2];
	
  header[0] = 0;
  header[1] = 0;
	
  // setting P bit
  header[0] |= 0x04;
	
  RTPPacketRef packet;
	
  RTPPBBeginPacket(packetBuilder,
                   0,
                   packetGroup,
                   dataLength,
                   &packet);
					 
  RTPPBAddPacketLiteralData(packetBuilder,
                            0,
                            packetGroup,
                            packet,
                            header,
                            2,
                            NULL);
	
  RTPPBAddPacketSampleData(packetBuilder,
                           0,
                           packetGroup,
                           packet,
                           (RTPMPSampleDataParams *)sampleData,
                           dataStartIndex+2,
                           dataLength-2,
                           NULL);
	
  SInt32 flags = 0;
  if (isLastPacket) {
    flags = 1;
  }
	
  RTPPBEndPacket(packetBuilder,
                 flags,
                 packetGroup,
                 packet,
                 0,
                 0);
}

void _XMRTPH263PlusPacketizer_PacketizeLongGOB(ComponentInstance packetBuilder,
                                               UInt32 maxPacketLength,
                                               const RTPMPSampleDataParams *sampleData,
                                               RTPPacketGroupRef packetGroup,
                                               UInt32 dataStartIndex,
                                               UInt32 dataLength,
                                               Boolean isLastPacket)
{
  UInt8 header[2];
	
  header[0] = 0;
  header[1] = 0;
	
  // setting P bit
  header[0] |= 0x04;
	
  RTPPacketRef packet;
	
  RTPPBBeginPacket(packetBuilder,
                   0,
                   packetGroup,
                   maxPacketLength,
                   &packet);
	
  RTPPBAddPacketLiteralData(packetBuilder,
                            0,
                            packetGroup,
                            packet,
                            header,
                            2,
                            NULL);
	
  RTPPBAddPacketSampleData(packetBuilder,
                           0,
                           packetGroup,
                           packet,
                           (RTPMPSampleDataParams *)sampleData,
                           dataStartIndex+2,
                           maxPacketLength-2,
                           NULL);
	
  RTPPBEndPacket(packetBuilder,
                 0,
                 packetGroup,
                 packet,
                 0,
                 0);
	
  dataStartIndex += maxPacketLength;
  dataLength -= maxPacketLength;
	
  // from now, the data contained in the packets is smaller by two bytes than
  // the given maximum, as the header cannot be compensated
  maxPacketLength -= 2;
	
  header[0] = 0;
	
  while (dataLength > maxPacketLength) {
    RTPPBBeginPacket(packetBuilder,
                     0,
                     packetGroup,
                     maxPacketLength,
                     &packet);
		
    RTPPBAddPacketLiteralData(packetBuilder,
                              0,
                              packetGroup,
                              packet,
                              header,
                              2,
                              NULL);
		
    RTPPBAddPacketSampleData(packetBuilder,
                             0,
                             packetGroup,
                             packet,
                             (RTPMPSampleDataParams *)sampleData,
                             dataStartIndex,
                             maxPacketLength,
                             NULL);
		
    RTPPBEndPacket(packetBuilder,
                   0,
                   packetGroup,
                   packet,
                   0,
                   0);
		
    dataStartIndex += maxPacketLength;
    dataLength -= maxPacketLength;
  }
	
  // sending the last packet
	
  RTPPBBeginPacket(packetBuilder,
                   0,
                   packetGroup,
                   dataLength+2,
                   &packet);
	
  RTPPBAddPacketLiteralData(packetBuilder,
                            0,
                            packetGroup,
                            packet,
                            header,
                            2,
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
  if (isLastPacket) {
    flags = 1;
  }
	
    RTPPBEndPacket(packetBuilder,
                   flags,
                   packetGroup,
                   packet,
                   0,
                   0);
}

#pragma mark -
#pragma mark Component Registration Functions

/**
 * Registering the Component
 * This function registers the XMRTPH263PlusPacketizer component so that
 * this component can be used as a media packetizer for RFC2429 compliant
 * H.263
 **/
Boolean XMRegisterRTPH263PlusPacketizer()
{	
  ComponentDescription description;
  Component registeredComponent = NULL;
	
  description.componentType = kXMRTPH263PlusPacketizerComponentType;
  description.componentSubType = kXMRTPH263PlusPacketizerComponentSubType;
  description.componentManufacturer = kXMRTPH263PlusPacketizerComponentManufacturer;
  description.componentFlags = 0;
  description.componentFlagsMask = 0;
	
  // Registering the Component
  ComponentRoutineUPP componentEntryPoint = NewComponentRoutineUPP((ComponentRoutineProcPtr)&XMRTPH263PlusPacketizer_ComponentDispatch);
  registeredComponent = RegisterComponent(&description, componentEntryPoint, 0, 0, 0, 0);
  DisposeComponentRoutineUPP(componentEntryPoint);
	
bail:
  if (registeredComponent == NULL) {
    return false;
  } else {
    return true;
  }
}
