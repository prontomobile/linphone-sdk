/*
 * Copyright (c) 2010-2022 Belledonne Communications SARL.
 *
 * This file is part of mediastreamer2 
 * (see https://gitlab.linphone.org/BC/public/mediastreamer2).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "apple_utils.h"

#import <TargetConditionals.h>

char *toSafeCStr(CFStringRef str, CFStringEncoding encoding);

#if TARGET_OS_IPHONE
/* iOS XCFramework builds embed codec plugins as siblings of mediastreamer2.framework
   (for example Frameworks/msamr.framework), not under Libraries/. */
static char *getIosFrameworksDir(void) {
	CFStringRef cfFramework = CFStringCreateWithCString(NULL, MS2_FRAMEWORK, kCFStringEncodingUTF8);
	CFBundleRef bundle = NULL;
	CFURLRef bundleUrl = NULL;
	CFURLRef parentUrl = NULL;
	CFStringRef cfPath = NULL;
	char *path = NULL;

	if (cfFramework == NULL) return NULL;
	bundle = CFBundleGetBundleWithIdentifier(cfFramework);
	CFRelease(cfFramework);
	if (bundle == NULL) return NULL;

	bundleUrl = CFBundleCopyBundleURL(bundle);
	if (bundleUrl == NULL) return NULL;
	parentUrl = CFURLCreateCopyDeletingLastPathComponent(NULL, bundleUrl);
	CFRelease(bundleUrl);
	if (parentUrl == NULL) return NULL;

	cfPath = CFURLCopyFileSystemPath(parentUrl, kCFURLPOSIXPathStyle);
	CFRelease(parentUrl);
	path = toSafeCStr(cfPath, kCFStringEncodingUTF8);
	if (cfPath != NULL) CFRelease(cfPath);
	return path;
}
#endif

// macOS plugins live in the Libraries directory of the mediastreamer2 framework.
// iOS plugins are separate frameworks next to it.
char *getPluginsDir(void) {
#if TARGET_OS_IPHONE
	return getIosFrameworksDir();
#else
	return getBundleResourceDirPath(MS2_FRAMEWORK, "Libraries/");
#endif
}

//Safely get an encoded string from the given CFStringRef
char *toSafeCStr(CFStringRef str, CFStringEncoding encoding) {
    char *ret  = NULL;

    if (str == NULL) {
        return ret;
    }
    CFIndex length = CFStringGetLength(str);
    CFIndex maxSize = CFStringGetMaximumSizeForEncoding(length, encoding) + 1;
    char *buffer = (char *) malloc((size_t) maxSize);
    if (buffer) {
        if (CFStringGetCString(str, buffer, maxSize, encoding)) {
            ret = buffer;
        }
    }
    return ret;
}


//Returns the absolute path of the given resource relative to the mediastreamer2 Framework location
char *getBundleResourceDirPath (const char *framework, const char *resource) {
	CFStringEncoding encodingMethod = CFStringGetSystemEncoding();
	CFStringRef cfFramework = CFStringCreateWithCString(NULL, framework, encodingMethod);
	CFStringRef cfResource = CFStringCreateWithCString(NULL, resource, encodingMethod);
	CFBundleRef bundle = CFBundleGetBundleWithIdentifier(cfFramework);
	char *path = NULL;

	if (bundle) {
	    CFRetain(bundle);
	    CFURLRef bundleUrl = CFBundleCopyBundleURL(bundle);

	    if (bundleUrl) {
	        CFURLRef resourceUrl = CFURLCreateCopyAppendingPathComponent(NULL, bundleUrl, cfResource, true);
			CFStringRef cfSystemPath = CFURLCopyFileSystemPath(resourceUrl, kCFURLPOSIXPathStyle);
	        path = toSafeCStr(cfSystemPath, encodingMethod);
			CFRelease(cfSystemPath);
			CFRelease(bundleUrl);
			CFRelease(resourceUrl);
	    }
	    CFRelease(bundle);
	}
	CFRelease(cfResource);
	CFRelease(cfFramework);
	return path;
}
