//
//  RegExRoot.h
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegExMatch.h"

typedef enum regEx_modifiers {
    regExFindAll = 0,
    regExCaseInsensitive = 1,
    regExWhiteSpace = 2,
    regExDotMatchNEwline = 3,
    regExMultiline = 4,
    regExUnicode = 5
} regExModifierLabel;

typedef enum regEx_uses {
    regExMatch = 0,
    regExReplace = 1,
    regExSplit = 2
} regExUseLabel;

@interface RegExRoot : NSObject
{
	BOOL matchSucceeded, matchFinished, doSplit;

	// instance variables that save information about the current match
	int encodingToUse;
	BOOL allowCode;
	BOOL matchAll;
	NSString *textToMatch;
	NSString *matchRegEx;
	NSSet *regExModifiers;
	NSString *replacementText;

	// Arrays to store results
	NSMutableArray *matches;					// array with RexExMatch-objects
	NSMutableArray *splits;						// array with NSString-objects

	// Task of seperate Perl thread.
	NSTask *regExTask;
	
	BOOL dummyText;								// mark if RegExhibit uses a dummytext to validate a regex without a user given text.
}

#pragma mark-
#pragma mark Initialisation

- (id) init;

#pragma mark-
#pragma mark Accessors

- (void) setEncodingToUse: (int) anEncoding;
- (int) encodingToUse;

- (void) setMatchAll: (BOOL) aBOOL;
- (BOOL) matchAll;

- (void) setTextToMatch: (NSString *) aString;
- (NSString *) textToMatch;

- (void) setMatchRegEx: (NSString *) aString;
- (NSString *) matchRegEx;

- (void) setRegExModifiers: (NSSet *) modifiers;
- (NSSet *) regExModifiers;

- (void) setReplacementText: (NSString *) aString;
- (NSString *) replacementText;

- (void) setRegExTask: (NSTask *) aTask;
- (NSTask *) regExTask;

- (void) addMatchWithBeginPosition: (int) beginPosition endPosition: (int) endPosition;

- (RegExMatch *) matchNumber: (int) matchNumber;

- (NSString *) splitNumber: (int) splitNumber;

- (void) setMatchSucceeded: (BOOL) anError;
- (BOOL) matchSucceeded;
- (BOOL) matchError;

- (void) setMatchFinished: (BOOL) aBOOL;
- (BOOL) matchFinished;

- (void) setDoSplit: (BOOL) aBOOL;
- (BOOL) doSplit;


#pragma mark-
#pragma mark Regular expression methods

- (void) matchText: (NSString *) matchText 
		   toRegEx: (NSString *) regEx
		 modifiers: (NSSet *) modifiers
	   replacement: (NSString *) replaceString
	     allowCode: (BOOL) codeAllowed;

- (void) replaceInText: (NSString *) textToReplace 
				 regEx: (NSString *) regEx
			 modifiers: (NSSet *) modifiers
		   replacement: (NSString *) replaceString
		     allowCode: (BOOL) codeAllowed;

- (void) splitText: (NSString *) textToSplit 
		   onRegEx: (NSString *) regEx 
		 modifiers: (NSSet *) modifiers
		 allowCode: (BOOL) codeAllowed;

- (void) modifiersToString: (NSMutableString *) modifiersString;

- (void) buildPerlProgram: (NSMutableString *) programString 
				  version: (int) goal 
				modifiers: (NSMutableString *) modifiersString;

- (void) runPerlProgram: (NSString *) programString withInput: (NSString *) programInput;
			
- (void) abortMatching;

- (void) regExError: (NSNotification *) note;

- (void) regExFinished: (NSNotification *) note;

- (void) buildResultsWith: (NSString *) matchResults;

#pragma mark-
#pragma mark Other methods

- (int) numberOfMatches;

- (int) numberOfSplits;

- (void) clearSelf;

- (NSString *) displayInOutlineWithSource: (NSString *) sourceText;

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements;

- (id) child: (int) index;


#pragma mark-
#pragma mark Cleaning up

- (void) dealloc;



@end
