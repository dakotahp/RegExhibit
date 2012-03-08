//
//  RegExCapture.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//
//	A RegExCapture object holds all the information needed to describe a capture inside a match made by a regular expression. 
//	The object is really a container that points towards a RegExText object which holds the beginning and ending positions of the capture.
//

#import "RegExCapture.h"

int const showLengthCapture = 20;

@implementation RegExCapture

#pragma mark-
#pragma mark Initialisation

- (id) init {
	self = [super init];
	if (self != nil) {
		capturedText = [[RegExText alloc]init];
		[self setCaptureNumber: -1];
	}
	return self;
}

- (id) initCaptureNumber: (int) aNumber beginPosition: (int) beginPosition endPosition: (int) endPosition {
	self = [super init];
	if (self != nil) {
		capturedText = [[RegExText alloc]init];
		[self setCaptureNumber: aNumber];
		[self setBeginPosition: beginPosition endPosition: endPosition];
	}
	return self;
}

#pragma mark-
#pragma mark Accessors


- (void) setBeginPosition: (int) beginPosition {
	[capturedText setBeginPosition: beginPosition];
}

- (int) beginPosition {
	return [capturedText beginPosition];
}

- (void) setEndPosition: (int) endPosition {
	[capturedText setEndPosition: endPosition];
}

- (int) endPosition {
	return [capturedText endPosition];
}

- (void) setBeginPosition: (int) beginPosition endPosition: (int) endPosition {
	[self setBeginPosition: beginPosition];
	[self setEndPosition: endPosition];
}

- (void) setCaptureNumber: (int) aNumber {
	captureNumber = aNumber;
}

- (int) captureNumber {
	return captureNumber;
}


- (NSString *) matchedTextWithSource: (NSString *) sourceText {
	NSString *returnString;

	if ([self beginPosition] != -1) {
		returnString = [[NSString alloc]initWithString:	[sourceText substringWithRange: [self range]]];
	} else {																			// Capture is undefined in Perl
		returnString = [[NSString alloc]initWithString: @"\0"];
	}
	[returnString autorelease];
	return returnString;

}

#pragma mark-
#pragma mark Other methods


- (NSString *) displayInOutlineWithSource: (NSString *) sourceText {
// Use when object is to be called from a NSOutlineView-datasource.

	NSString *returnString;
	NSMutableString *tempString = [NSMutableString string];

	if ([self beginPosition] != -1) {
		[tempString appendFormat: NSLocalizedString(@"Capturenumber&positions", nil), [self captureNumber], [self beginPosition], [self endPosition]];
		if (([self endPosition] - [self beginPosition]) <= showLengthCapture) {
			[tempString appendFormat: @"%@)", [sourceText substringWithRange: [self range]]];
		} else {
			[tempString appendFormat: @"%@ ...)", [sourceText substringWithRange:NSMakeRange([self beginPosition],showLengthCapture)]];
		}
	} else {																			// Capture is undefined in Perl
		[tempString appendFormat: NSLocalizedString(@"Capture undefined", nil), [self captureNumber]];
	}

	returnString = [[NSString alloc] initWithString: tempString];
	[returnString autorelease];
	return returnString;
}

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements {
// Use when object is to be called from a NSOutlineView-datasource.
	if ([self beginPosition] != -1) {
		return 1;
	} else {
		return 0;
	}
}

- (id) child: (int) index {
	return capturedText;
}


- (NSRange) range {
	return [capturedText range];
}

#pragma mark-
#pragma mark Cleaning up

- (void) dealloc {
	[capturedText release];
	[super dealloc];
}


@end
