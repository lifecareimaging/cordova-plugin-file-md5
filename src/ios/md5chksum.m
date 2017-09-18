#import "md5chksum.h"
#import "CDVFile.h"
#import <Cordova/CDV.h>
#include <CommonCrypto/CommonDigest.h>

@implementation md5chksum

- (NSString *)getUrl:(NSString *)urlString
{
	NSString *path = nil;
	id filePlugin = [self.commandDelegate getCommandInstance:@"File"];
	if (filePlugin != nil) {
		CDVFilesystemURL* url = [CDVFilesystemURL fileSystemURLWithString:urlString];
		path = [filePlugin filesystemPathForURL:url];
	}
	if (path == nil) {
		if ([urlString hasPrefix:@"file:"]) {
			path = [[NSURL URLWithString:urlString] path];
		}
	}
	return path;
}

- (void)file:(CDVInvokedUrlCommand*)command
{
	[self.commandDelegate runInBackground:^{
		NSString *url  = [command.arguments objectAtIndex:0];
		NSString *path = [self getUrl:url];

		// Get the file URL
		CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)path, kCFURLPOSIXPathStyle, (Boolean)false);
		if (!fileURL)
			goto done;

		// Create and open the read stream
		CFReadStreamRef readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)fileURL);
		if (!readStream)
			goto done;

		bool didSucceed = (bool)CFReadStreamOpen(readStream);
		if (!didSucceed)
			goto done;

		// Initialize the hash object
		CC_MD5_CTX hashObject;
		CC_MD5_Init(&hashObject);

		// Feed the data to the hash object
		bool hasMoreData = true;
		while (hasMoreData) {
			uint8_t buffer[4096];
			CFIndex readBytesCount = CFReadStreamRead(readStream, (UInt8 *)buffer, (CFIndex)sizeof(buffer));
			if (readBytesCount == -1)
				break;

			if (readBytesCount == 0) {
				hasMoreData = false;
				continue;
			}
			CC_MD5_Update(&hashObject, (const void *)buffer, (CC_LONG)readBytesCount);
		}

		// Check if the read operation succeeded
		didSucceed = !hasMoreData;

		// Compute the hash digest
		unsigned char digest[CC_MD5_DIGEST_LENGTH];
		CC_MD5_Final(digest, &hashObject);

		// Abort if the read operation failed
		if (!didSucceed)
			goto done;

		// Compute the string result
		CFStringRef result = NULL;
		char hash[2 * sizeof(digest) + 1];
		for (size_t i = 0; i < sizeof(digest); ++i) {
			snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
		}
		result = CFStringCreateWithCString(kCFAllocatorDefault, (const char *)hash, kCFStringEncodingUTF8);

	done:
		if (readStream) {
			CFReadStreamClose(readStream);
			CFRelease(readStream);
		}

		if (fileURL) {
			CFRelease(fileURL);
		}

		CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:(__bridge NSString*)result];
		CFRelease(result);
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}];
}
@end
