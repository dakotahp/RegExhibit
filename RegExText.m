//
//  RegExText.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//
//  This class is used to store either the positions on which a string (match, capture) begins and ends or the text of a replacementstring.
//

#import "RegExText.h"

@implementation RegExText

#pragma mark-
#pragma mark Initialisation

- (id) init
{
	self = [super init];
	if (self != nil) {
		containsPositions = FALSE;
	}
	return self;
}


#pragma mark-
#pragma mark Accessors

- (void) setBeginPosition: (int) position
{
	beginPosition = position;
	[self setContainsPositions: TRUE];
}

- (int) beginPosition
{
	return beginPosition;
}

- (void) setEndPosition: (int) position
{
	endPosition = position;
	[self setContainsPositions: TRUE];
}

- (int) endPosition
{
	return endPosition;
}

- (void) setBeginPosition: (int) startPosition endPosition: (int) stopPosition
{
	[self setBeginPosition: startPosition];
	[self setEndPosition: stopPosition];
	[self setContainsPositions: TRUE];
}

- (void) setContainsPositions: (BOOL) positionsSet
{
	containsPositions = positionsSet;
}

- (BOOL) containsPositions
{
	return containsPositions;
}

- (void) setTheText: (NSString *) newText
{
	[newText retain];
	[theText release];
	theText = newText;
	[self setContainsPositions: FALSE];
}

- (NSString *) theText
{
	return theText;
}

#pragma mark-
#pragma mark Other methods

- (NSString *) displayWithSource: (NSString *) sourceText
{
	return [self displayInOutlineWithSource: sourceText];
}


- (NSString *) displayInOutlineWithSource: (NSString *) sourceText
// Use when object is to be called from a NSOutlineView-datasource.
{
	NSString *returnString;
	if ((containsPositions) && ([self beginPosition] != -1)) {
		returnString = [[NSString alloc]initWithString:	[sourceText substringWithRange: [self range]]];
		[returnString autorelease];
		return returnString;
	} else if (containsPositions) {							// beginPosition = -1, meaning the text is undef in Perl.
		return @"\0";
	} else {
		return [self theText];
	}
}

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements
// Use when object is to be called from a NSOutlineView-datasource.
{
	return 0;
}


- (NSRange) range
// Thanks to Brian Bergstrand (http://www.bergstrand.org/brian/) for fixing this up.
{
    int begin = [self beginPosition];
    int end = [self endPosition];
	if (end >= begin) {
		return NSMakeRange(begin, end - begin);
	} else {
		NSLog (@"Error: Begin of range bigger than end of range!");
		return NSMakeRange(begin,  0);
	}
}

#pragma mark-
#pragma mark Cleaning up

- (void) dealloc
{
	[theText release];
	[super dealloc];
}



@end
