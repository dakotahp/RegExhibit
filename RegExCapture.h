//
//  RegExCapture.h
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegExText.h"

// Constant sets the length of text shown in the "summary" of the capture in the details drawer.
extern int const showLengthCapture;

@interface RegExCapture : NSObject {
	int captureNumber;
	RegExText *capturedText;
}


#pragma mark-
#pragma mark Initialisation

- (id) init;
- (id) initCaptureNumber: (int) aNumber beginPosition: (int) beginPosition endPosition: (int) endPosition;


#pragma mark-
#pragma mark Accessors

- (void) setBeginPosition: (int) beginPosition;
- (int) beginPosition;

- (void) setEndPosition: (int) endPosition;
- (int) endPosition;

- (void) setBeginPosition: (int) beginPosition endPosition: (int) endPosition;

- (void) setCaptureNumber: (int) aNumber;
- (int) captureNumber;


- (NSString *) matchedTextWithSource: (NSString *) sourceText;


#pragma mark-
#pragma mark Other methods


- (NSString *) displayInOutlineWithSource: (NSString *) sourceText;

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements;

- (id) child: (int) index;

- (NSRange) range;


#pragma mark-
#pragma mark Cleaning up

- (void) dealloc;

@end
