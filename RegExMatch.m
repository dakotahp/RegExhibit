//
//  RegExMatch.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//
//	A RegExMatch object holds all the information needed to describe a match made by a regular expression. It had instance variables that deal with 
//	the text matched, the text that is used to replace the match, (if any), the captures inside the match and the number of the match. Most of these
//	variables are other objects that hold more specfic information. Both the text of the match and the replacement text are RegExLabel-objects. The
//	captures are held inside an array consisting of RegExCapture objects.
//

#import "RegExMatch.h"

int const showLengthMatch = 20;

@implementation RegExMatch

#pragma mark-
#pragma mark Initialisation

- (id) init {
	self = [super init];
	if (self != nil) {
		replacementText = [[RegExLabel alloc]init];
		matchedText = [[RegExLabel alloc]init];
		captures = [[NSMutableArray alloc]init];
		[self setMatchDrawn: NO];
		[self setMatchNumber: -1];
	}
	return self;
}

- (id) initMatchNumber: (int) aNumber beginPosition: (int) beginPosition endPosition: (int) endPosition {
	self = [super init];
	if (self != nil) {
		replacementText = [[RegExLabel alloc]init];
		matchedText = [[RegExLabel alloc]init];
		captures = [[NSMutableArray alloc]init];
		[self setMatchNumber: aNumber];
		[self setMatchDrawn: NO];
		[self setBeginPosition: beginPosition endPosition: endPosition];
	}
	return self;
}

#pragma mark-
#pragma mark Accessors


- (void) setBeginPosition: (int) beginPosition {
	[matchedText setBeginPosition: beginPosition];
}

- (int) beginPosition {
	return [matchedText beginPosition];
}

- (void) setEndPosition: (int) endPosition {
	[matchedText setEndPosition: endPosition];
}

- (int) endPosition {
	return [matchedText endPosition];
}

- (void) setBeginPosition: (int) beginPosition endPosition: (int) endPosition {
	[self setBeginPosition: beginPosition];
	[self setEndPosition: endPosition];
}

- (void) setMatchNumber: (int) aNumber {
	matchNumber = aNumber;
}

- (int) matchNumber {
	return matchNumber;
}

- (void) setMatchDrawn: (BOOL) aBool {
	matchDrawn = aBool;
}

- (BOOL) matchDrawn {
	return matchDrawn;
}

- (NSString *) matchedTextWithSource: (NSString *) sourceText {

	NSString *returnString;

	returnString = [[NSString alloc]initWithString:	[sourceText substringWithRange: [self range]]];
	[returnString autorelease];
	return returnString;
}

- (void) addCaptureWithBeginPosition: (int) beginPosition endPosition: (int) endPosition {
	[captures addObject: [[RegExCapture alloc]initCaptureNumber: [captures count] + 1 
											  beginPosition: beginPosition
											     endPosition: endPosition]];

}

- (RegExCapture *) captureNumber: (int) captureNumber {
	return [captures objectAtIndex: captureNumber - 1];
}

- (void) setReplacementText: (NSString *) aString {
	[replacementText setTheText: aString];
}

- (NSString *) replacementText {
	return [replacementText theText];
}


#pragma mark-
#pragma mark Other methods


- (NSString *) displayInOutlineWithSource: (NSString *) sourceText {
// Use when object is to be called from a NSOutlineView-datasource.

	NSString *returnString;
	NSMutableString *tempString = [NSMutableString string];

	[tempString appendFormat: NSLocalizedString(@"Matchnumber&positions", nil), [self matchNumber], [self beginPosition], [self endPosition]];
	
	if (([self endPosition] - [self beginPosition]) <= showLengthMatch) {
		[tempString appendFormat: @"%@)", [sourceText substringWithRange: [self range]]];
	} else {
		[tempString appendFormat: @"%@ ...)", [sourceText substringWithRange:NSMakeRange([self beginPosition], showLengthMatch)]];
	}

	// If there is a newline in the string, get rid of it and the text following.
	NSRange tempRange = [tempString rangeOfString:@"\n"];
	if (tempRange.location != NSNotFound) {
		[tempString replaceCharactersInRange:NSMakeRange(tempRange.location,[tempString length] - tempRange.location) withString:@" ...)"];
	}

	returnString = [[NSString alloc] initWithString: tempString];
	[returnString autorelease];
	return returnString;
}

- (int) numberOfCaptures {
	return [captures count];
}

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements {
// Use when object is to be called from a NSOutlineView-datasource.
	if (showReplacements) {
		return [captures count] + 2;
	} else {
		return [captures count] + 1;
	}
}

- (id) child: (int) index {
	if (index == 0) {																// item 0 is always matchedText
			return matchedText;
	} else if (index == [captures count] + 1) {										// if there is an item beyond the number of captures, it is the replacementText
			return replacementText;
	} else {
		return [self captureNumber: index];
	}
}


- (NSRange) range {
	return [matchedText range];
}

#pragma mark-
#pragma mark Cleaning up

- (void) dealloc {
	NSEnumerator *enumerator;
	id capturedItem;
	
	enumerator = [captures objectEnumerator];
	while (capturedItem = [enumerator nextObject]) {
		[capturedItem release];
	}
	[captures release];
	[matchedText release];
	[replacementText release];

	[super dealloc];
}




@end
