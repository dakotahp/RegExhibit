//
//  RegExLabel.h
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegExText.h"

enum labelText {matchText, replacementText};

@interface RegExLabel : NSObject {
	enum labelText textOfLabel;
	RegExText *containedText;
}

#pragma mark-
#pragma mark Initialisation

- (id) init;
- (id) initWithBeginPosition: (int) beginPosition endPosition: (int) endPosition;
- (id) initWithString: (NSString *) aString;


#pragma mark-
#pragma mark Accessors

- (void) setBeginPosition: (int) beginPosition;
- (int) beginPosition;

- (void) setEndPosition: (int) endPosition;
- (int) endPosition;

- (void) setBeginPosition: (int) beginPosition endPosition: (int) endPosition;

- (void) setTheText: (NSString *) newText;
- (NSString *) theText;

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
