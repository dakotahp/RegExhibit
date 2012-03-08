//
//  RegExLabel.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//
//	A RegExLabel object is a class that sits between a match and the matched text or replacement text.
//	The object points towards a RegExText object which holds the beginning and ending positions of the match and the text of the replacement text.
//	The RegExLabel object is only used to have an object for the outlineview.
//

#import "RegExLabel.h"

@implementation RegExLabel

#pragma mark-
#pragma mark Initialisation

- (id) init {
	self = [super init];
	if (self != nil) {
		textOfLabel = replacementText;
		containedText = [[RegExText alloc]init];
	}
	return self;
}

- (id) initWithBeginPosition: (int) beginPosition endPosition: (int) endPosition {
	self = [super init];
	if (self != nil) {
		textOfLabel = matchText;
		containedText = [[RegExText alloc]init];
		[self setBeginPosition: beginPosition endPosition: endPosition];
	}
	return self;
}

- (id) initWithString: (NSString *) aString {
	self = [super init];
	if (self != nil) {
		textOfLabel = replacementText;
		containedText = [[RegExText alloc]init];
		[containedText setTheText: aString];
	}
	return self;
}

#pragma mark-
#pragma mark Accessors


- (void) setBeginPosition: (int) beginPosition {
	textOfLabel = matchText;
	[containedText setBeginPosition: beginPosition];
}

- (int) beginPosition {
	return [containedText beginPosition];
}

- (void) setEndPosition: (int) endPosition {
	textOfLabel = matchText;
	[containedText setEndPosition: endPosition];
}

- (int) endPosition {
	return [containedText endPosition];
}

- (void) setBeginPosition: (int) beginPosition endPosition: (int) endPosition {
	[self setBeginPosition: beginPosition];
	[self setEndPosition: endPosition];
}

- (void) setTheText: (NSString *) newText {
	[containedText setTheText: newText];
}

- (NSString *) theText {
	return [containedText theText];
}

- (NSString *) matchedTextWithSource: (NSString *) sourceText {

	NSString *returnString;
	
	if (textOfLabel == matchText) {
		returnString = [[NSString alloc]initWithString:	[sourceText substringWithRange: [self range]]];
		[returnString autorelease];
		return returnString;
	} else {
		return [self theText];
	}

}

#pragma mark-
#pragma mark Other methods


- (NSString *) displayInOutlineWithSource: (NSString *) sourceText {
// Use when object is to be called from a NSOutlineView-datasource.

	NSString *returnString;

	if (textOfLabel == matchText) {
		returnString = [[NSString alloc] initWithString: NSLocalizedString(@"Matched text", nil)];
	} else {
		returnString = [[NSString alloc] initWithString: NSLocalizedString(@"Replacement text", nil)];
	}
	[returnString autorelease];
	return returnString;
}

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements {
// Use when object is to be called from a NSOutlineView-datasource.
	return 1;
}

- (id) child: (int) index {
	return containedText;
}


- (NSRange) range {
	return [containedText range];
}

#pragma mark-
#pragma mark Cleaning up

- (void) dealloc {
	[containedText release];
	[super dealloc];
}



@end
