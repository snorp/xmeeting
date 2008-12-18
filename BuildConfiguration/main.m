/*
 * $Id: main.m,v 1.4 2008/12/18 08:28:43 hfriederich Exp $
 *
 * Copyright (c) 2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2008 Hannes Friederich. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import <sys/param.h>
#import <sys/sysctl.h>
#import <string.h>
#import <stdlib.h>

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

typedef struct FileDefinition {
  NSString *templateFile;
  NSString *outputFile;
  ReplaceRecord *replaceRecords;
  unsigned numReplaceRecords;
} FileDefinition;

NSString *PTLIBTemplateFile = @"../ptlib/include/ptbuildopts.h.in";
NSString *PTLIBOutputFile = @"../ptlib/include/ptbuildopts.h";
NSString *PTLIBVersionFile = @"../ptlib/version.h";
// TODO: Add code to automatically detect the PTLIB version
ReplaceRecord PTLIBRecords[] = {
  { @"#undef    PTLIB_MAJOR",             @"#define PTLIB_MAJOR __XM_PTLIB_MAJOR__" },
  { @"#undef    PTLIB_MINOR",             @"#define PTLIB_MINOR __XM_PTLIB_MINOR__" },
  { @"#undef    PTLIB_BUILD",             @"#define PTLIB_BUILD __XM_PTLIB_BUILD__" },
  { @"#undef    PTLIB_VERSION",           @"#define PTLIB_VERSION \"__XM_PTLIB_MAJOR__.__XM_PTLIB_MINOR__.__XM_PTLIB_BUILD__\"" },
  { @"#undef    P_LINUX",                 @"/* #undef P_LINUX */" },
  { @"#undef    P_FREEBSD",               @"/* #undef P_FREEBSD */" },
  { @"#undef    P_OPENBSD",               @"/* #undef P_OPENBSD */" },
  { @"#undef    P_NETBSD",                @"/* #undef P_NETBSD */" },
  { @"#undef    P_SOLARIS",               @"/* #undef P_SOLARIS */" },
  { @"#undef    P_MACOSX",                @"#define P_MACOSX __XM_OS_MAJOR____XM_OS_MINOR__" },
  { @"#undef    P_CYGWIN",                @"/* #undef P_CYGWIN */" },
  { @"#undef    P_MINGW",                 @"/* #undef P_MINGW */" },
  { @"#undef    P_UNKNOWN_OS",            @"/* #undef P_UNKNOWN_OS */" },
  { @"#undef SIZEOF_INT",                 @"#define SIZEOF_INT 4" },
  { @"#undef PBYTE_ORDER\n",              @"/* #undef PBYTE_ORDER */\n" },
  { @"#undef P_HAS_IPV6",                 @"/* #undef P_HAS_IPV6 */" },
  { @"#undef P_QOS",                      @"/* #undef P_QOS */" },
  { @"#undef P_OSSL ",                    @"/* #undef P_OSSL */" },
  { @"#undef P_OSSL_AES",                 @"/* #undef P_OSSL_AES */" },
  { @"#undef P_SSL_USE_CONST",            @"/* #undef P_SSL_USE_CONST */" },
  { @"#undef P_OEXPAT",                   @"/* #undef P_OEXPAT */" },
  { @"#undef P_WINEXPAT",                 @"/* #undef P_WINEXPAT */" },
  { @"#undef P_LDAP",                     @"/* #undef P_LDAP */" },
  { @"#undef P_MEDIALIB",                 @"/* #undef P_MEDIALIB */" },
  { @"#undef P_DNS",                      @"#define P_DNS 1" },
  { @"#undef P_HAS_RES_NINIT",            @"#define P_HAS_RES_NINIT 1" },
  { @"#undef P_SAPI\n",                   @"/* #undef P_SAPI */\n" },
  { @"#undef P_SAPI_LIBRARY",             @"/* #undef P_SAPI_LIBRARY */\n" },
  { @"#undef P_SASL ",                    @"/* #undef P_SASL */" },
  { @"#undef P_SASL2",                    @"#define P_SASL2 1" },
  { @"#undef P_HAS_SASL_SASL_H",          @"/* #undef P_HAS_SASL_SASL_H */" },
  { @"#undef P_DYNALINK",                 @"#define P_DYNALINK 1" },
  { @"#undef P_PLUGINS",                  @"#define P_PLUGINS 1" },
  { @"#undef P_DEFAULT_PLUGIN_DIR",       @"#define P_DEFAULT_PLUGIN_DIR \"/dev/null\"" },
  { @"#undef P_REGEX",                    @"#define P_REGEX 1" },
  { @"#undef P_TTS",                      @"/* #undef P_TTS */" },
  { @"#undef P_ASN",                      @"#define P_ASN 1" },
  { @"#undef P_STUN",                     @"#define P_STUN 1" },
  { @"#undef P_PIPECHAN",                 @"/* #undef P_PIPECHAN */" },
  { @"#undef P_DTMF",                     @"/* #undef P_DTMF */" },
  { @"#undef P_WAVFILE",                  @"/* #undef P_WAVFILE */" },
  { @"#undef P_SOCKS",                    @"/* #undef P_SOCKS */" },
  { @"#undef P_FTP",                      @"/* #undef P_FTP */" },
  { @"#undef P_SNMP",                     @"/* #undef P_SNMP */" },
  { @"#undef P_TELNET",                   @"/* #undef P_TELNET */" },
  { @"#undef P_REMCONN",                  @"/* #undef P_REMCONN */" },
  { @"#undef P_SERIAL",                   @"/* #undef P_SERIAL */" },
  { @"#undef P_POP3SMTP",                 @"/* #undef P_POP3SMTP */" },
  { @"#undef P_AUDIO",                    @"#define P_AUDIO 1" },
  { @"#undef P_VIDEO",                    @"#define P_VIDEO 1" },
  { @"#undef NO_VIDEO_CAPTURE",           @"/* #undef NO_VIDEO_CAPTURE */" },
  { @"#undef P_VXML",                     @"/* #undef P_VXML */" },
  { @"#undef P_JABBER",                   @"/* #undef P_JABBER */" },
  { @"#undef P_XMLRPC",                   @"/* #undef P_XMLRPC */" },
  { @"#undef P_SOAP",                     @"/* #undef P_SOAP */" },
  { @"#undef P_URL",                      @"#define P_URL 1" },
  { @"#undef P_HTTP\n",                   @"#define P_HTTP 1\n" },
  { @"#undef P_HTTPFORMS",                @"/* #undef P_HTTPFORMS */" },
  { @"#undef P_HTTPSVC",                  @"/* #undef P_HTTPSVC */" },
  { @"#undef P_SOCKAGG",                  @"#define P_SOCKAGG 1" },
  { @"#undef P_VIDFILE",                  @"/* #undef P_VIDFILE */" },
  { @"#undef P_ODBC",                     @"/* #undef P_ODBC */" },
  { @"#undef P_SHM_VIDEO",                @"/* #undef P_SHM_VIDEO */" },
  { @"#undef P_PTHREADS\n",               @"#define P_PTHREADS 1\n" },
  { @"#undef P_HAS_SEMAPHORES\n",         @"/* #undef P_HAS_SEMAPHORES */\n" },
  { @"#undef P_HAS_NAMED_SEMAPHORES",     @"#define P_HAS_NAMED_SEMAPHORES 1" },
  { @"#undef P_PTHREADS_XPG6",            @"/* #undef P_THREADS_XPG6 */" },
  { @"#undef P_HAS_SEMAPHORES_XPG6",      @"/* #undef P_HAS_SEMAPHORES_XPG6 */" },
  { @"#undef P_EXCEPTIONS",               @"/* #undef P_EXCEPTIONS */" },
  { @"#undef USE_SYSTEM_SWAB",            @"#define USE_SYSTEM_SWAB" },
  { @"#undef    P_64BIT",                 @"/* #undef P_64BIT */" },
  { @"#undef P_LPIA",                     @"/* #undef P_LPIA */" },
  { @"#undef    PNO_LONG_DOUBLE",         @"/* #undef PNO_LONG_DOUBLE */" },
  { @"#undef P_HAS_POSIX_READDIR_R",      @"#define P_HAS_POSIX_READDIR_R 3" },
  { @"#undef P_HAS_STL_STREAMS",          @"#define P_HAS_STL_STREAMS 1" },
  { @"#undef P_HAS_ATOMIC_INT",           @"#define P_HAS_ATOMIC_INT 1" },
  { @"#undef P_HAS_RECURSIVE_MUTEX",      @"#define P_HAS_RECURSIVE_MUTEX 2" },
  { @"#undef P_NEEDS_GNU_CXX_NAMESPACE",  @"#define P_NEEDS_GNU_CXX_NAMESPACE 1" },
  { @"#undef PMEMORY_CHECK",              @"/* #undef PMEMORY_CHECK */" },
  { @"#undef P_HAS_RECVMSG",              @"/* #undef P_HAS_RECVMSG */" },
  { @"#undef P_HAS_UPAD128_T",            @"/* #undef P_HAS_UPAD128_T */" },
  { @"#undef P_HAS_INET_NTOP",            @"#define P_HAS_INET_NTOP 1" },
  { @"#undef  P_USE_STANDARD_CXX_BOOL",   @"#define P_USE_STANDARD_CXX_BOOL 1" },
};
unsigned PTLIBNumRecords = 83;

NSString *OPALTemplateFile = @"../opal/include/opal/buildopts.h.in";
NSString *OPALOutputFile = @"../opal/include/opal/buildopts.h";
NSString *OPALVersionFile = @"../opal/version.h";
// TODO: Add code to automatically detect the OPAL version
ReplaceRecord OPALRecords[] = {
  { @"#undef OPAL_MAJOR",               @"#define OPAL_MAJOR __XM_OPAL_MAJOR__" },
  { @"#undef OPAL_MINOR",               @"#define OPAL_MINOR __XM_OPAL_MINOR__" },
  { @"#undef OPAL_BUILD",               @"#define OPAL_BUILD __XM_OPAL_BUILD__" },
  { @"#undef OPAL_VERSION",             @"#define OPAL_VERSION \"__XM_OPAL_MAJOR__.__XM_OPAL_MINOR__.__XM_OPAL_BUILD__\"" },
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
unsigned OPALNumRecords = 36;

NSString *OSVersionMajor;
NSString *OSVersionMinor;

NSString *PTLibVersionMajor;
NSString *PTLibVersionMinor;
NSString *PTLibVersionBuild;

NSString *OPALVersionMajor;
NSString *OPALVersionMinor;
NSString *OPALVersionBuild;

void getDarwinVersion(unsigned *major, unsigned *minor);
void getPTLIBVersion(unsigned *major, unsigned *minor, unsigned *build);
void getOPALVersion(unsigned *major, unsigned *minor, unsigned *build);
int processFile(NSString *templateFile, NSString *outputFile, ReplaceRecord *replaceRecords, unsigned numReplaceRecords);

int main(int argc, char *argv[])
{
  // TODO: Eventually replace the PTLIB autoconf chain too
  
  NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
  
  unsigned versionMajor, versionMinor, versionBuild;
  getDarwinVersion(&versionMajor, &versionMinor);
  
  OSVersionMajor = [[NSString alloc] initWithFormat:@"%d", versionMajor];
  OSVersionMinor = [[NSString alloc] initWithFormat:@"%02d", versionMinor];
  
  getPTLIBVersion(&versionMajor, &versionMinor, &versionBuild);
  PTLibVersionMajor = [[NSString alloc] initWithFormat:@"%d", versionMajor];
  PTLibVersionMinor = [[NSString alloc] initWithFormat:@"%d", versionMinor];
  PTLibVersionBuild = [[NSString alloc] initWithFormat:@"%d", versionBuild];
  
  getOPALVersion(&versionMajor, &versionMinor, &versionBuild);
  OPALVersionMajor = [[NSString alloc] initWithFormat:@"%d", versionMajor];
  OPALVersionMinor = [[NSString alloc] initWithFormat:@"%d", versionMinor];
  OPALVersionBuild = [[NSString alloc] initWithFormat:@"%d", versionBuild];
  
  int result;
  
  // process the PTLIB file
  NSLog(@"Processing the PTLIB file");
  result = processFile(PTLIBTemplateFile, PTLIBOutputFile, PTLIBRecords, PTLIBNumRecords);
  if (result != 0) {
    NSLog(@"Could not process the PTLIB file %d", result);
    return result;
  }
  
  // process the OPAL file
  NSLog(@"Processing the OPAL file");
  result = processFile(OPALTemplateFile, OPALOutputFile, OPALRecords, OPALNumRecords);
  if (result != 0) {
    NSLog(@"Could not process the OPAL file");
    return result;
  }
  
  NSLog(@"All files processed");
  
  [autoreleasePool release];
  
  return 0;
}

int processFile(NSString *templateFile, NSString *outputFile, ReplaceRecord *replaceRecords, unsigned numReplaceRecords)
{
  NSString *template = [NSString stringWithContentsOfFile:templateFile encoding:NSASCIIStringEncoding error:NULL];
  if (template == nil) {
    return 1;
  }
  NSMutableString *outputString = [template mutableCopy];
  
  unsigned i;
  for (i = 0; i < numReplaceRecords; i++) {
    [outputString replaceOccurrencesOfString:replaceRecords[i].search withString:replaceRecords[i].replacement options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  }
  
  [outputString replaceOccurrencesOfString:@"__XM_OS_MAJOR__" withString:OSVersionMajor options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_OS_MINOR__" withString:OSVersionMinor options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_PTLIB_MAJOR__" withString:PTLibVersionMajor options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_PTLIB_MINOR__" withString:PTLibVersionMinor options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_PTLIB_BUILD__" withString:PTLibVersionBuild options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_OPAL_MAJOR__" withString:OPALVersionMajor options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_OPAL_MINOR__" withString:OPALVersionMinor options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  [outputString replaceOccurrencesOfString:@"__XM_OPAL_BUILD__" withString:OPALVersionBuild options:NSLiteralSearch range:NSMakeRange(0, [outputString length])];
  
  if (![outputString writeToFile:outputFile atomically:YES encoding:NSASCIIStringEncoding error:NULL]) {
    return 2;
  }
  
  return 0;
}

void getDarwinVersion(unsigned *systemVersionMajor, unsigned *systemVersionMinor)
{
  int mib[2];
  size_t len;
  char *kernelVersion;
  
  mib[0] = CTL_KERN;
  mib[1] = KERN_OSRELEASE;
  
  sysctl(mib, 2, NULL, &len, NULL, 0);
  kernelVersion = malloc(len * sizeof(char));
  sysctl(mib, 2, kernelVersion, &len, NULL, 0);
  
  NSString *content = [NSString stringWithCString:kernelVersion encoding:NSASCIIStringEncoding];
  NSScanner *scanner = [NSScanner scannerWithString:content];
  [scanner scanInt:(int *)systemVersionMajor];
  [scanner scanString:@"." intoString:NULL];
  [scanner scanInt:(int *)systemVersionMinor];
  
  free(kernelVersion);
}

void getPTLIBVersion(unsigned *major, unsigned *minor, unsigned *build)
{
  NSString *text = [NSString stringWithContentsOfFile:PTLIBVersionFile encoding:NSASCIIStringEncoding error:NULL];
  if (text == nil) {
    return;
  }
  NSScanner *scanner = [NSScanner scannerWithString:text];
  [scanner scanUpToString:@"MAJOR_VERSION " intoString:NULL];
  [scanner scanString:@"MAJOR_VERSION " intoString:NULL];
  if (![scanner scanInt:(int*)major]) {
    return;
  }
  [scanner scanUpToString:@"MINOR_VERSION " intoString:NULL];
  [scanner scanString:@"MINOR_VERSION " intoString:NULL];
  if (![scanner scanInt:(int*)minor]) {
    return;
  }
  [scanner scanUpToString:@"BUILD_NUMBER " intoString:NULL];
  [scanner scanString:@"BUILD_NUMBER " intoString:NULL];
  if (![scanner scanInt:(int*)build]) {
    return;
  }
}

void getOPALVersion(unsigned *major, unsigned *minor, unsigned *build)
{
  NSString *text = [NSString stringWithContentsOfFile:OPALVersionFile encoding:NSASCIIStringEncoding error:NULL];
  if (text == nil) {
    return;
  }
  NSScanner *scanner = [NSScanner scannerWithString:text];
  [scanner scanUpToString:@"MAJOR_VERSION " intoString:NULL];
  [scanner scanString:@"MAJOR_VERSION " intoString:NULL];
  if (![scanner scanInt:(int*)major]) {
    return;
  }
  [scanner scanUpToString:@"MINOR_VERSION " intoString:NULL];
  [scanner scanString:@"MINOR_VERSION " intoString:NULL];
  if (![scanner scanInt:(int*)minor]) {
    return;
  }
  [scanner scanUpToString:@"BUILD_NUMBER " intoString:NULL];
  [scanner scanString:@"BUILD_NUMBER " intoString:NULL];
  if (![scanner scanInt:(int*)build]) {
    return;
  }
}
