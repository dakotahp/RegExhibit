//
//  RegExText.h
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RegExText : NSObject
{
	BOOL containsPositions;
	int beginPosition, endPosition;
	NSString *theText;
}

#pragma mark-
#pragma mark Initialisation
- (id) init;

#pragma mark-
#pragma mark Accessors
- (void) setBeginPosition: (int) position;
- (int) beginPosition;

- (void) setEndPosition: (int) position;
- (int) endPosition;

- (void) setBeginPosition: (int) startPosition endPosition: (int) stopPosition;

- (void) setContainsPositions: (BOOL) positionsSet;
- (BOOL) containsPositions;

- (void) setTheText: (NSString *) newText;
- (NSString *) theText;

#pragma mark-
#pragma mark Other methods
- (NSString *) displayWithSource: (NSString *) sourceText;

- (NSString *) displayInOutlineWithSource: (NSString *) sourceText;

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements;

- (NSRange) range;

#pragma mark-
#pragma mark Cleaning up
- (void) dealloc;

@end
