//
//  RegExMatch.h
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegExLabel.h"
#import "RegExCapture.h"

// Constant sets the length of text shown in the "summary" of the match in the details drawer.
extern int const showLengthMatch;

@interface RegExMatch : NSObject {
	int matchNumber;
	BOOL matchDrawn;
	NSMutableArray *captures;
	RegExLabel *matchedText;
	RegExLabel *replacementText;
}

#pragma mark-
#pragma mark Initialisation

- (id) init;
- (id) initMatchNumber: (int) aNumber beginPosition: (int) beginPosition endPosition: (int) endPosition;


#pragma mark-
#pragma mark Accessors

- (void) setBeginPosition: (int) beginPosition;
- (int) beginPosition;

- (void) setEndPosition: (int) endPosition;
- (int) endPosition;

- (void) setBeginPosition: (int) beginPosition endPosition: (int) endPosition;

- (void) setMatchNumber: (int) aNumber;
- (int) matchNumber;

- (void) setMatchDrawn: (BOOL) aBool;
- (BOOL) matchDrawn;

- (NSString *) matchedTextWithSource: (NSString *) sourceText;

- (void) addCaptureWithBeginPosition: (int) beginPosition endPosition: (int) endPosition;

- (RegExCapture *) captureNumber: (int) captureNumber;

- (void) setReplacementText: (NSString *) aString;
- (NSString *) replacementText;


#pragma mark-
#pragma mark Other methods

- (NSString *) displayInOutlineWithSource: (NSString *) sourceText;

- (int) numberOfCaptures;

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements;

- (id) child: (int) index;

- (NSRange) range;


#pragma mark-
#pragma mark Cleaning up

- (void) dealloc;


@end
