/*
 * $Id: main.m,v 1.1 2008/11/13 00:14:28 hfriederich Exp $
 *
 * Copyright (c) 2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2008 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

/**
 * The purpose of this little application is to replace the OPAL configuration chain (autoconf).
 * This is needed since this project does not build PTLib / OPAL separately, but instead includes everything
 * into one binary. Unfortunately, as of November 2008, the autofonf chain requires a ptlib binary in order
 * to build opal. Hence, this little app was created to allow seamless integration of PTLib / OPAL into the
 * XMeeting build system.
 *
 * Perhaps a shell script would be more appropriate for this task, but the author is much more familiar with
 * programming C/C++ than programming shell scripts...
 **/

typedef struct ReplaceRecord {
  NSString *search;
  NSString *replacement;
} ReplaceRecord;

NSString *OPALTemplateFile = @"../opal/include/opal/buildopts.h.in";
NSString *OPALOutputFile = @"../opal/include/opal/buildopts.h";


int main(int argc, char *argv[])
{
  // TODO: Eventually replace the PTLIB autoconf chain too
  
  ReplaceRecord opalRecords[] = {
    // TODO: Add code to automatically detect the OPAL version
    { @"#undef OPAL_MAJOR",               @"#define OPAL_MAJOR 3" },
    { @"#undef OPAL_MINOR",               @"#define OPAL_MINOR 5" },
    { @"#undef OPAL_BUILD",               @"#define OPAL_BUILD 1" },
    { @"#undef OPAL_VERSION",             @"#define OPAL_VERSION \"3.5.1\"" },
    { @"#undef  OPAL_PTLIB_SSL\n",        @"/* #undef OPAL_PTLIB_SSL */\n" },
    { @"#undef  OPAL_PTLIB_SSL_AES",      @"/* #undef OPAL_PTLIB_SSL_AES */" },
    { @"#undef  OPAL_PTLIB_ASN",          @"/* #undef OPAL_PTLIB_ASN */" },
    { @"#undef  OPAL_PTLIB_EXPAT",        @"/* #undef OPAL_PTLIB_EXPAT */" },
    { @"#undef  OPAL_PTLIB_AUDIO",        @"/* #undef OPAL_PTLIB_AUDIO */" },
    { @"#undef  OPAL_PTLIB_VIDEO",        @"/* #undef OPAL_PTLIB_VIDEO */" },
    { @"#undef  OPAL_PTLIB_WAVFILE",      @"/* #undef OPAL_PTLIB_WAVFILE */" },
    { @"#undef  OPAL_PTLIB_DTMF",         @"/* #undef OPAL_PTLIB_DTMF */" },
    { @"#undef  OPAL_PTLIB_IPV6",         @"/* #undef OPAL_PTLIB_IPV6 */" },
    { @"#undef  OPAL_PTLIB_DNS",          @"/* #undef OPAL_PTLIB_DNS */" },
    { @"#undef  OPAL_PTLIB_LDAP",         @"/* #undef OPAL_PTLIB_LDAP */" },
    { @"#undef  OPAL_PTLIB_VXML",         @"/* #undef OPAL_PTLIB_VXML */" },
    { @"#undef  OPAL_PTLIB_CONFIG_FILE",  @"/* #undef OPAL_PTLIB_CONFIG_FILE */" },
    { @"#undef  OPAL_IAX2",               @"/* #undef OPAL_IAX2 */" },
    { @"#undef\tOPAL_SIP",                @"#define OPAL_SIP 1" },
    { @"#undef\tOPAL_H323",               @"#define OPAL_H323 1" },
    { @"#undef  OPAL_LID",                @"/* #undef OPAL_LID */" },
    { @"#undef  OPAL_T120DATA",           @"/* #undef OPAL_T120DATA */" },
    { @"#undef  OPAL_H224FECC",           @"#define OPAL_H224FECC 1" },
    { @"#undef  OPAL_H501",               @"#define OPAL_H501 1" },
    { @"#undef  OPAL_H450",               @"#define OPAL_H450 1" },
    { @"#undef  OPAL_H460",               @"#define OPAL_H460 1" },
    { @"#undef  OPAL_STATISTICS",         @"#define OPAL_STATISTICS 1" },
    { @"#undef GCC_HAS_CLZ",              @"#define GCC_HAS_CLZ 1" },
    { @"#undef  OPAL_G711PLC",            @"#define OPAL_G711PLC 1" },
    { @"#undef  OPAL_VIDEO",              @"#define OPAL_VIDEO 1" },
    { @"#undef   OPAL_RFC4175",           @"/* #undef OPAL_RFC4175 */" },
    { @"#undef  OPAL_FAX",                @"/* #undef OPAL_FAX */" },
    { @"#undef\tOPAL_SYSTEM_SPEEX",       @"/* #undef OPAL_SYSTEM_SPEEX */" },
    { @"#undef  OPAL_HAVE_SPEEX_SPEEX_H", @"/* #undef OPAL_HAVE_SPEEX_SPEEX_H */" },
    { @"#undef  OPAL_SPEEX_FLOAT_NOISE",  @"/* #undef OPAL_SPEEX_FLOAT_NOISE */" },
    { @"#undef OPAL_JAVA",                @"/* #undef OPAL_JAVA */" },
  };
  unsigned numOPALRecords = 36;
  
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  NSString *template = [NSString stringWithContentsOfFile:OPALTemplateFile encoding:NSASCIIStringEncoding error:NULL];
  if (template == nil) {
    return 1;
  }
  NSMutableString *outputString = [template mutableCopy];
  
  unsigned i;
  for (i = 0; i < numOPALRecords; i++) {
    [outputString replaceOccurrencesOfString:opalRecords[i].search withString:opalRecords[i].replacement options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  }
  
  if (![outputString writeToFile:OPALOutputFile atomically:YES encoding:NSASCIIStringEncoding error:NULL]) {
    return 2;
  }
  
  [autoreleasePool release];
  
  return 0;
}