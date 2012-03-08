//
//  RegExRoot.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//
//  This is the model-class that does the basic work matching regular expressions and arranging the storage of their results.
//	When requested to do a match, replacement or split, it will build a Perl-program and run it. The results will put into its
//	instance variables.
//	RegExRoot contains an array "matches" and an array "splits". The matches array contains for every match a RegExMatch object.
//	A RegExMatch object consist of other objects with the number of the match, its starting and ending position, containing captures and
//	the text used to replace the match, if appropriate.
//	The splits array holds a NSString for each split.
//	With the demo match this means:
//	RegExMatch object -->		Match 1 (from 306 to 330: the proper point of ...)
//	RegExLabel object -->			Matched text
//	RegExText object -->				the proper point of view
//	RegExCapture object -->		Capture 1 (from 310 to 316: proper)
//	RegExText object -->				proper
//	The RegExLabel object for replacement text is empty
//	The splits array is empty
//

#import "RegExRoot.h"

int const showLength = 20;

@implementation RegExRoot

- (id) init
{
	self = [super init];
	if (self != nil) {
		matchSucceeded = FALSE;
		encodingToUse = NSMacOSRomanStringEncoding;
		allowCode = FALSE;
		matchAll = FALSE;
		doSplit = FALSE;
		matches = [[NSMutableArray alloc]init];
		splits = [[NSMutableArray alloc]init];
		
		dummyText = FALSE;
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		// Register with notificationcenter to hear when match if finished,
		[nc addObserver: self
			   selector: @selector(regExFinished:)
				   name: NSFileHandleReadToEndOfFileCompletionNotification
			     object: nil];

		// or ended through an error or by being aborted.
		[nc addObserver: self
			   selector: @selector(regExError:)
				   name: NSFileHandleReadCompletionNotification
			     object: nil];

	}
	return self;
}


#pragma mark-
#pragma mark Accessors

- (void) setAllowCode: (BOOL) aBool
// Only use if you want to allow runtime evaluation. Not recommended!
{
	allowCode = aBool;
}

- (int) allowCode
{
	return allowCode;
}

- (void) setEncodingToUse: (int) anEncoding
{
	encodingToUse = anEncoding;
}

- (int) encodingToUse
{
	return encodingToUse;
}

- (void) setMatchAll: (BOOL) aBOOL
{
	matchAll = aBOOL;
}

- (BOOL) matchAll
{
	return matchAll;
}

- (void) setTextToMatch: (NSString *) aString
{
//	If there is no user provided text. set textToMatch to a dummy text to be able to check the validity of the regular expressions.
	if ((aString == nil) || [aString isEqualToString:@""]) {
		dummyText = TRUE;
		[textToMatch release];
		textToMatch = [[NSString alloc] initWithString: @" "];
	} else {
		dummyText = FALSE;
		[aString retain];
		[textToMatch release];
		textToMatch = aString;
	}
}

- (NSString *) textToMatch
{
	return textToMatch;
}

- (void) setRegExModifiers: (NSSet *) modifiers
{
	[modifiers retain];
	[regExModifiers release];
	regExModifiers = modifiers;
}

- (NSSet *) regExModifiers
{
	return regExModifiers;
}

- (void) setMatchRegEx: (NSString *) aString
{
	if (matchRegEx == aString) {
		return;
	}
	
	[matchRegEx release];
	
	// Process the regex, because for one reason or other, I cannot get Perl to recognize $ in embedded lines, (i.e. when using multiline mode).
	// Therefore: walk through the regex and replace all $ with (?:$|(?=\\n^)), which means the same and gets processed correctly.
	// This also could be used in future to do more pre-processing.

	BOOL escapeFound = FALSE;
	int i = 0;
	int stringLength = [aString length] - 1; // strings are 0-based.
	NSMutableString *currentChar = [[NSMutableString alloc] init];
	NSMutableString *charBuffer = [[NSMutableString alloc] init];
	NSMutableString *tempResult = [[NSMutableString alloc] init];
	
	for (i = 0; i <= stringLength; i++) {
		[charBuffer setString:@""];
		[currentChar setString: [aString substringWithRange: NSMakeRange(i,1)]];
		if (escapeFound) {
			if ([currentChar isEqualToString:@"Q"]) {											// Start quotemeta
				[charBuffer appendString:@"\\"];												// Add skipped escape, currentChar will be added in the for loop.
				for (; 
                     (i < stringLength) && ![[aString substringWithRange: NSMakeRange(i,2)] isEqualToString: @"\\E"]; i++) {
					[charBuffer appendString: [aString substringWithRange: NSMakeRange(i,1)]];
				}
				if (i < stringLength) {		// Loop has been exited before length condition was true, therefore it must have ended on \E.
					[charBuffer appendString: @"\\E"];
					i++;
				} else {							// Add last character. i has been upped in the if-condition!
					[charBuffer appendString: [aString substringWithRange: NSMakeRange(i,1)]];
				}
			} else {																			// Normal escape
				[charBuffer appendString:@"\\"];												// Add skipped escape
				[charBuffer appendString: [aString substringWithRange: NSMakeRange(i,1)]];
			}
			escapeFound = FALSE;
			[tempResult appendString: charBuffer];
		} else if ([currentChar isEqualToString:@"$"]) {									// Found an unescaped $
			[tempResult appendString: @"(?:$|(?=\\n^))"];
		} else if ([currentChar isEqualToString:@"\\"]) {									// Found unescaped escape character
			escapeFound = TRUE;										// Don't add escape. No reason not to now, but handy if we ever extend this routine in future.
		} else {
			[tempResult appendString: currentChar];
		}
	}
	matchRegEx = [[NSString alloc] initWithString: tempResult];
	[tempResult release];
	[charBuffer release];
	[currentChar release];
}

- (NSString *) matchRegEx
{
	return matchRegEx;
}

- (void) setReplacementText: (NSString *) aString
{
	[aString retain];
	[replacementText release];
	replacementText = aString;
}

- (NSString *) replacementText
{
	return replacementText;
}


- (void) setRegExTask: (NSTask *) aTask
{
	[aTask retain];
	[regExTask release];
	regExTask = aTask;
}

- (NSTask *) regExTask
{
	return regExTask;
}

- (void) addMatchWithBeginPosition: (int) beginPosition endPosition: (int) endPosition
{
	[matches addObject: [[RegExMatch alloc] initMatchNumber: [matches count] + 1 
											  beginPosition: beginPosition
											    endPosition: endPosition]];
}

- (RegExMatch *) matchNumber: (int) matchNumber
{
	return [matches objectAtIndex: matchNumber - 1];
}


- (NSString *) splitNumber: (int) splitNumber
{
	return [splits objectAtIndex: splitNumber - 1];
}

- (void) setMatchSucceeded: (BOOL) anError
{
	matchSucceeded = anError;
} 

- (BOOL) matchSucceeded
{
	return matchSucceeded;
} 

- (BOOL) matchError
{
	return ![self matchSucceeded];
}

- (void) setMatchFinished: (BOOL) aBOOL
{
	matchFinished = aBOOL;
}

- (BOOL) matchFinished
{
	return matchFinished;
}

- (void) setDoSplit: (BOOL) aBOOL
{
	doSplit = aBOOL;
}

- (BOOL) doSplit
{
	return doSplit;
}


#pragma mark-
#pragma mark Regular expression methods

- (void) matchText: (NSString *) matchText 
		   toRegEx: (NSString *) regEx
		 modifiers: (NSSet *) modifiers
	   replacement: (NSString *) replaceString
		 allowCode: (BOOL) codeAllowed
{
	[self setMatchFinished: FALSE];																// After this, we still might need to replace text.

	// Save the variables, so the can be used later when possibly replacing.
	[self setAllowCode: codeAllowed];
	[self setTextToMatch: matchText];
	[self setMatchRegEx: regEx];
	[self setRegExModifiers: modifiers];
	[self setReplacementText: replaceString];

	// Make some assumptions about modifiers.
	[self setEncodingToUse: NSMacOSRomanStringEncoding];
	[self setMatchAll: FALSE];

	// Change the modifiersset into a string and some instance variables.
	NSMutableString *modifiersString = [[NSMutableString alloc] init];
	[self modifiersToString: modifiersString];

	// Build Perl program.
	NSMutableString *matchProgram = [[NSMutableString alloc] init];
	[self buildPerlProgram: matchProgram version: regExMatch modifiers: modifiersString];

	// Assemble the input.
	NSMutableString *programInput = [[NSMutableString alloc] initWithString: [self matchRegEx]];	// First get the regex to use.
	[programInput appendString: @"\n\0\n"];															// The null-string is used as seperator;
																									// ignore the compiler warning.
	[programInput appendString: [self textToMatch]];												// Add the text against which to match the regex.

	// Match the text by running the program.
	[self runPerlProgram: matchProgram withInput: programInput];

	// Do some cleaning up.
	[matchProgram release];
	[programInput release];
	[modifiersString release];
}


- (void) replaceInText: (NSString *) textToReplace 
				 regEx: (NSString *) regEx
			 modifiers: (NSSet *) modifiers
		   replacement: (NSString *) replaceString
			 allowCode: (BOOL) codeAllowed
{

	if ((replaceString == nil) || ([replaceString length] == 0)) {								// If there is nothing to replace, set the replacement text
		[self setMatchFinished: TRUE];
		int matchNumber;																		// of all matches to an empty string.
		for (matchNumber = 1; matchNumber <= [self numberOfMatches]; matchNumber++) {
			[[self matchNumber: matchNumber] setReplacementText: @""];
			[[self matchNumber: matchNumber] setMatchDrawn: NO];
		}

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName: @"RDJRegExFinished" object:@"matching"];

	} else {

		if ([self matchFinished]) {																// matchFinished was set by previous match.
			[self setEncodingToUse: NSMacOSRomanStringEncoding];								// Ignore, we came here direct from Controller.
			[self setAllowCode: codeAllowed];													// This is the first time for this match (only replace has changed).
			[self setMatchAll: FALSE];
			[self setTextToMatch: textToReplace];
			[self setMatchRegEx: regEx];
			[self setRegExModifiers: modifiers];
			[self setReplacementText: replaceString];
			int matchNumber;
			for (matchNumber = 1; matchNumber <= [self numberOfMatches]; matchNumber++) {
				[[self matchNumber: matchNumber] setMatchDrawn: NO];
			}
		} else {																				// We came here from "replaceInText"
			[self setMatchFinished: TRUE];
		}

		// Change the modifiersset into a string and some instance variables.
		NSMutableString *modifiersString = [[NSMutableString alloc] init];
		[self modifiersToString: modifiersString];

		NSMutableString *programInput = [[NSMutableString alloc] initWithString: [self matchRegEx]];	// get the regex to use
		[programInput appendString: @"\n\0\n"];													// null-string on purpose, ignore compiler warning

		[programInput appendString: [self replacementText]];
		[programInput appendString: @"\n\0\n"];													// null-string on purpose, ignore compiler warning

		[programInput appendString: [self textToMatch]];										// add text to search

		NSMutableString *matchProgram = [[NSMutableString alloc] init];
		[self buildPerlProgram: matchProgram version: regExReplace modifiers: modifiersString];

		[self runPerlProgram: matchProgram withInput: programInput];

		[matchProgram release];
		[programInput release];
		[modifiersString release];
	}

}

- (void) splitText: (NSString *) textToSplit 
		   onRegEx: (NSString *) regEx 
		 modifiers: (NSSet *) modifiers 
		 allowCode: (BOOL) codeAllowed
{
	if ([textToSplit length] == 0) {															// With no text, no results,
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName: @"RDJRegExFinished" object:@"splitting"];
		return;																					// and no further processing needed.
	}

	[self setEncodingToUse: NSMacOSRomanStringEncoding];
	[self setAllowCode: codeAllowed];
	[self setMatchAll: FALSE];
	[self setTextToMatch: textToSplit];
	[self setMatchRegEx: regEx];
	[self setRegExModifiers: modifiers];
	[self setMatchFinished: TRUE];
	[self setDoSplit: TRUE];
	[self setReplacementText: nil];

	// Change the modifiersset into a string and some instance variables.
	NSMutableString *modifiersString = [[NSMutableString alloc] init];
	[self modifiersToString: modifiersString];

	// Build Perl program
	NSMutableString *programInput = [[NSMutableString alloc] initWithString: [self matchRegEx]];			// get the regex to use
	[programInput appendString: @"\n\0\n"];																// null-string on purpose, ignore compiler warning

	[programInput appendString: [self textToMatch]];														// add text to search

	NSMutableString *matchProgram = [[NSMutableString alloc] init];
	[self buildPerlProgram: matchProgram version: regExSplit modifiers: modifiersString];

	// Split text
	[self runPerlProgram: matchProgram withInput: programInput];
	
	[matchProgram release];
	[programInput release];
	[modifiersString release];
}


- (void) modifiersToString: (NSMutableString *) modifiersString
{
	// Determine modifiers
	NSEnumerator *enumerator;
	NSString *modifierItem;
	
	enumerator = [[self regExModifiers] objectEnumerator];
	while (modifierItem = [enumerator nextObject]) {
		switch ([modifierItem intValue]) {
			case regExFindAll:
				[self setMatchAll: TRUE];
				break;
			case regExCaseInsensitive:
				[modifiersString appendString: @"i"];
				break;
			case regExWhiteSpace:
				[modifiersString appendString: @"x"];
				break;
			case regExDotMatchNEwline:
				[modifiersString appendString: @"s"];
				break;
			case regExMultiline:
				[modifiersString appendString: @"m"];
				break;
			case regExUnicode:
				[self setEncodingToUse: NSUTF8StringEncoding];
				break;
			default:
				NSLog(@"Found unknown modifier %d\n",[modifierItem intValue]);
		}
	}
}

- (void) buildPerlProgram: (NSMutableString *) programString
				  version: (int) goal 
				modifiers: (NSMutableString *) modifiersString
{
	// Create Perl program to match text. This program expects the regex to use in the match, followed by a null-string, followed by the text to match.
	[programString appendString:@"use strict;"];											// Use strict processing.
	[programString appendString:@"my $_m_;"];												// $_m_ for match.
	
	if ([self encodingToUse] == NSUTF8StringEncoding) {
		[programString appendString:@"binmode STDIN, \":utf8\";"];							// stdin will be in UTF-8
		[programString appendString:@"binmode STDOUT, \":utf8\";"];							// stdout will be in UTF-8
	}

	if ([self allowCode]) {
		[programString appendString:@"use re \'eval\';"];

		// To prevent errors caused by the user using "print" redirect STDOUT
		[programString appendString:@"open(SAVED_OUT,\">&STDOUT\");"];						// Save STDOUT
		[programString appendString:@"open(STDOUT,\"> /dev/null\") or die;"];				// Redirect to /dev/null
	}

	[programString appendString:@"while (<>)  {"];											// read each line of input
	[programString appendString:	@"if (/\\0/) {"];										// if you find a null-string
	[programString appendString:		@"last;"];											// exit the loop
	[programString appendString:	@"} else {"];											// otherwise
	[programString appendString:		@"$_m_ .= $_;"];									// add the line to the regex
	[programString appendString:	@"}"];	
	[programString appendString:@"}"];														// (end while)
	[programString appendString:@"chomp ($_m_);"];

	// trouble passing things like \u by pipe, therefore do it manually. (Escaped \'s are needed for compiler)
	// First process \u or \l if followed by \E. Perl allows this, even though it doesn't make sense/

	// Find all \u's possibly followed by \E and replace it with the appropriate text and remove the \E,
	// unless that belongs to a previous \l, \L ,\u, \U or \Q.
	[programString appendString:@"$_m_ =~ s/"];												// Match
	[programString appendString:				@"\\\\u"];									// \u (obj-c escaped)
	[programString appendString:				@"(.?)"];									// capture the following character ($1)
	[programString appendString:				@"("];										// capture ($2) the next
	[programString appendString:					@"(?:"];								// non matching group
	[programString appendString:						@"."];								// beginning with a character
	[programString appendString:						@"(?!\\\\"];						// if not followed by an escaped backslash
	[programString appendString:							@"(?:"];						// and one of a non matching group
	[programString appendString:								@"l|L|u|U|Q"];				// containing either l L u U or Q
	[programString appendString:							@")"];							// end non matching group
	[programString appendString:						@")"];								// end negative lookahead
	[programString appendString:					@")*?"];								// end non matching group
	[programString appendString:				@")"];										// end capture ($2)
	[programString appendString:				@"\\\\E"];									// until \E (obj-c escaped)
	[programString appendString:			@"/"];											// and replace it with
	[programString appendString:				@"\\u$1$2"];								// $1 in uppercase followed by $2
	[programString appendString:			@"/g;"];

	// Find all \l's possibly followed by \E and replace it with the appropriate text and remove the \E,
	// unless that belongs to a previous \l, \L ,\u, \U or \Q.
	[programString appendString:@"$_m_ =~ s/"];												// Match
	[programString appendString:				@"\\\\l"];									// \u (obj-c escaped)
	[programString appendString:				@"(.?)"];									// capture the following character ($1)
	[programString appendString:				@"("];										// capture ($2) the next
	[programString appendString:					@"(?:"];								// non matching group
	[programString appendString:						@"."];								// beginning with a character
	[programString appendString:						@"(?!\\\\"];						// if not followed by an escaped backslash
	[programString appendString:							@"(?:"];						// and one of a non matching group
	[programString appendString:								@"l|L|u|U|Q"];				// containing either l L u U or Q
	[programString appendString:							@")"];							// end non matching group
	[programString appendString:						@")"];								// end negative lookahead
	[programString appendString:					@")*?"];								// end non matching group
	[programString appendString:				@")"];										// end capture ($2)
	[programString appendString:				@"\\\\E"];									// until \E (obj-c escaped)
	[programString appendString:			@"/"];											// and replace it with
	[programString appendString:				@"\\l$1$2"];								// $1 in uppercase followed by $2
	[programString appendString:			@"/g;"];

	[programString appendString:@"$_m_ =~ s/\\\\u(.?)/\\u$1/g;"];							// Find all \u's without an associated \E and replace.
	[programString appendString:@"$_m_ =~ s/\\\\l(.?)/\\l$1/g;"];							// Find all \l's without an associated \E and replace.

	// Find all \Q's possibly followed by \E and replace it with the appropriate text,
	[programString appendString:@"$_m_ =~ s/"];											// Match
	[programString appendString:				@"\\\\Q"];									// \Q (obj-c escaped)
	[programString appendString:				@"("];										// capture ($1)
	[programString appendString:					@".*?"];								// the following characters
	[programString appendString:				@")"];										// end capture
	[programString appendString:				@"(?:"];									// non matching group
	[programString appendString:					@"\\\\E|$"];							// until you find either \E (obj-c escaped) or the end of the string
	[programString appendString:				@")"];										// end non matching group
	[programString appendString:			@"/"];											// and replace it with
	[programString appendString:				@"\\Q$1\\E"];								// the appropriate text
	[programString appendString:			@"/g;"];

	// Find all \U's possibly followed by \E and replace it with the appropriate text,
	[programString appendString:@"$_m_ =~ s/"];												// Match
	[programString appendString:				@"\\\\U"];									// \U (obj-c escaped)
	[programString appendString:				@"("];										// capture ($1)
	[programString appendString:					@".*?"];								// the following characters
	[programString appendString:				@")"];										// end capture
	[programString appendString:				@"(?:"];									// non matching group
	[programString appendString:					@"\\\\E|$"];							// until you find either \E (obj-c escaped) or the end of the string
	[programString appendString:				@")"];										// end non matching group
	[programString appendString:			@"/"];											// and replace it with
	[programString appendString:				@"\\U$1\\E"];								// the appropriate text
	[programString appendString:			@"/g;"];

	// Find all \L's possibly followed by \E and replace it with the appropriate text,
	[programString appendString:@"$_m_ =~ s/"];												// Match
	[programString appendString:				@"\\\\L"];									// \L (obj-c escaped)
	[programString appendString:				@"("];										// capture ($1)
	[programString appendString:					@".*?"];								// the following characters
	[programString appendString:				@")"];										// end capture
	[programString appendString:				@"(?:"];									// non matching group
	[programString appendString:					@"\\\\E|$"];							// until you find either \E (obj-c escaped) or the end of the string
	[programString appendString:				@")"];										// end non matching group
	[programString appendString:			@"/"];											// and replace it with
	[programString appendString:				@"\\L$1\\E"];								// the appropriate text
	[programString appendString:			@"/g;"];

	if (goal == regExReplace) {
		[programString appendString:@"my $_s_;"];											// $_s_ for substitute.

		[programString appendString:@"while (<>)  {"];										// read each line of input
		[programString appendString:	@"if (/\\0/) {"];									// if you find a null-string
		[programString appendString:		@"last;"];										// exit the loop
		[programString appendString:	@"} else {"];										// otherwise
		[programString appendString:		@"$_s_ .= $_;"];								// add the line to the regex
		[programString appendString:	@"}"];	
		[programString appendString:@"}"];													// (end while)
		[programString appendString:@"chomp ($_s_);"];


		// trouble passing things like \u by pipe, therefore do it manually. (Escaped \'s are needed for compiler)
		// For the substitution \u, \U, \l and \L shouldn't be changed, because we are feeding Perl a string it has to interpret. If we change them as we
		// did for the match, the won't stay around long enough te be correctly used. Only processing \Q is needed.

		// Find all \Q's possibly followed by \E and replace it with the appropriate text,
		[programString appendString:@"$_s_ =~ s/"];											// Match
		[programString appendString:				@"\\\\Q"];								// \Q (obj-c escaped)
		[programString appendString:				@"("];									// capture ($1)
		[programString appendString:					@".*?"];							// the following characters
		[programString appendString:				@")"];									// end capture
		[programString appendString:				@"(?:"];								// non matching group
		[programString appendString:					@"\\\\E|$"];						// until you find either \E (obj-c escaped) or the end of the string
		[programString appendString:				@")"];									// end non matching group
		[programString appendString:			@"/"];										// and replace it with
		[programString appendString:				@"\\Q$1\\E"];							// the appropriate text
		[programString appendString:			@"/g;"];
	}

	[programString appendString:@"eval {\"\" =~ /$_m_/};"];									// is this a valid regex?

	[programString appendString:@"if ($@) {"];												// if not, there will be an error-message ($@)
	[programString appendString:	@"warn \"no valid match\";"];							// mention there is an error
	[programString appendString:	@"while (<>) {};"];										// don't exit immediately, because there is still input in the pipe
	[programString appendString:	@"exit;"];												// ignore it and then exit
	[programString appendString:@"}"];	
	[programString appendString:@"undef $/;"];												// valid regex, so ignore record seperator
	[programString appendString:@"$_ = <>;"];												// so we can get the remaining input in one slurp 

	if ([self matchAll] && goal == regExMatch) {											// For some reason, Perl -e & cocoa give an "out of memory" error
		[programString appendString:@"my $_i_ = 1;"];										// when finding all and matching for example 18 ordinary letters, 										
																							// e.g. try "ordinary gentleman" as regex and text. 
		if ([modifiersString rangeOfString:@"x"].location == NSNotFound) {
			[programString appendString:@"while ($_m_ =~ /(?<!\\\\)"];						// Match if there are is no \ (this is an escaped Obj-c Perl escaped \),
			[programString appendString:				@"(?:\\\\\\\\)*"];					// followed by an even number of \'s (again double escaping)
			[programString appendString:				@"("];								// capture
			[programString appendString:					@"\\("];						// a (
			[programString appendString:				@")"];								// end capture
			[programString appendString:				@"(?!\\?)/g"];						// unless followed by a ? (Perl escaped ?)
		} else {																			// Freeflow mode, watch out for extra spaces.
			[programString appendString:@"while ($_m_ =~ /(?<!\\\\)"];						// Match if there are is no \ (this is an escaped Obj-c Perl escaped \),
			[programString appendString:				@"(?:\\\\\\\\)*"];					// followed by an even number of \'s (again double escaping)
			[programString appendString:				@"\\s*"];							// perhaps followed by spaces
			[programString appendString:				@"("];								// capture
			[programString appendString:				@"\\s*"];							// perhaps followed by spaces
			[programString appendString:					@"\\("];						// a (
			[programString appendString:				@")"];								// end capture
			[programString appendString:				@"\\s*"];							// perhaps followed by spaces
			[programString appendString:				@"(?!\\?)/g"];						// unless followed by a ? (Perl escaped ?)
		}

		[programString appendString: modifiersString];										// By first finding how many captures there are and setting $_i_ to it,
		[programString appendString:@") {"];												// this is prevented.  Of course, this causes overhead,
		[programString appendString:@"$_i_++;"];											// but that is better than an error.
		[programString appendString:@"}"];
	}																						


	[programString appendString:@"$_m_ =  qr/$_m_/"];										// quote regex
		[programString appendString: modifiersString];										// add modifiers
	[programString appendString: @";"];	

	switch (goal) {
		case regExMatch:
			if ([self matchAll]) {
				[programString appendString:@"while (m/$_m_/g"];							// loop if all matches need to be found
			} else {
				[programString appendString:@"if (m/$_m_/"];								// or just once if there is a match
			}
			[programString appendString: @") {"];											// close

			if ([self allowCode]) {
				// Re-allow printing to STDOUT. Looping through this is probably costly, but necessary for safety.
				[programString appendString:@"close(STDOUT) or die;"];						// Close redirected STDOUT
				[programString appendString:@"open(STDOUT,\">&SAVED_OUT\") or die;"];		// Restore normal STDOUT
				[programString appendString:@"close(SAVED_OUT) or die;"];					// Close to prevent memory leaks
			}

			[programString appendString:	@"my $_t_=\"\";"];								// Perl doesn't capture undefined captures after the last defined capture 
																							// this variable saves undefined captures until it is clear whether they
																							// are followed by a defined one.
			[programString appendString:	@"my $_j_;"];									// $_j_ counter.
			if ([self matchAll] && goal == regExMatch) {									// More prevention of per -e & cocoa problem from above
				[programString appendString:	@"for ($_j_= 0; $_j_ < $_i_; $_j_++) {"];
			} else {
				[programString appendString:	@"for ($_j_= 0; $_j_ < @-; $_j_++) {"];		// for each (captured) match
			}

			[programString appendString:		@"if (defined $-[$_j_]) {"];				// needed in case of undef
			[programString appendString:			@"print $_t_;"];						// print any undefined captures
			[programString appendString:			@"$_t_ = \"\";"];						// clear the temporary string for undefined captures
			[programString appendString:			@"print \"$-[$_j_]\\0$+[$_j_]\\0\";"];	// print them to STDOUT
			[programString appendString:		@"} elsif ($_j_ > 0) {"];
			[programString appendString:			@"$_t_ .= \"-1\\0-1\\0\";"];			// add placeholder to the temporary string for undefined captures
			[programString appendString:		@"}"];	
			[programString appendString:	@"}"];	
			[programString appendString:	@"print \"|\\0\";"];							// after each match, print a seperator

			if ([self allowCode]) {
				[programString appendString:@"open(SAVED_OUT,\">&STDOUT\");"];				// Save STDOUT again for match at the top of the loop
				[programString appendString:@"open(STDOUT,\"> /dev/null\") or die;"];		// Redirect to /dev/null
			}

			[programString appendString:@"};"];
			break;
		case regExReplace:

			// We need to check whether the replacement string is valid with a dummy text and match, because the eval on the set from the user
			// will not give an error on the replacement string if the regex does not match.
			
			// First set $_i_ to one more than the number of captures.
			[programString appendString:@"my $_i_ = 0;"];	

			if ([modifiersString rangeOfString:@"x"].location == NSNotFound) {
				[programString appendString:@"while ($_m_ =~ /(?<!\\\\)"];					// Match if there are is no \ (this is an escaped Obj-c Perl escaped \),
				[programString appendString:				@"(?:\\\\\\\\)*"];				// followed by an even number of \'s (again double escaping)
				[programString appendString:				@"("];							// capture
				[programString appendString:					@"\\("];					// a (
				[programString appendString:				@")"];							// end capture
				[programString appendString:				@"(?!\\?)/g"];					// unless followed by a ? (Perl escaped ?)
			} else {																		// Freeflow mode, watch out for extra spaces.
				[programString appendString:@"while ($_m_ =~ /(?<!\\\\)"];					// Match if there are is no \ (this is an escaped Obj-c Perl escaped \),
				[programString appendString:				@"(?:\\\\\\\\)*"];				// followed by an even number of \'s (again double escaping)
				[programString appendString:				@"\\s*"];						// perhaps followed by spaces
				[programString appendString:				@"("];							// capture
				[programString appendString:				@"\\s*"];						// perhaps followed by spaces
				[programString appendString:					@"\\("];					// a (
				[programString appendString:				@")"];							// end capture
				[programString appendString:				@"\\s*"];						// perhaps followed by spaces
				[programString appendString:				@"(?!\\?)/g"];					// unless followed by a ? (Perl escaped ?)
			}

			[programString appendString: modifiersString];
			[programString appendString:@") {"];
			[programString appendString:@"$_i_++;"];
			[programString appendString:@"}"];

			// Set $_i_ to a dummy match regex consisting of just empty captures. (Needed in case the replacementstring has backreferences.)
			[programString appendString:	@"$_i_ = \"()\" x $_i_;"];
			
			// Set $_j_ to a dummy text.
			[programString appendString:	@"my $_j_ = \"test\";"];

			[programString appendString:@"$_s_ = qq/\"\\0$_s_\\0\"/;"];						// Pad the replacementstring with null-strings for split

			[programString appendString:@"eval {"];											// See if the regex is valid, with the dummy.
			[programString appendString:	@"$_j_ =~ s/$_i_/$_s_/ee;"];
			[programString appendString:@"};"];

			[programString appendString:	@"if ($@) {"];									// if not, there will be an error-message ($@)
			[programString appendString:		@"die \"no valid match\";"];				// mention there is an error and exit.
			[programString appendString:	@"}"];	

			// If we get here, the replacement string is valid. No use it with the real text and regex. 
			[programString appendString:@"eval {"];											// See if the regex is valid, while doing the substitution.
			[programString appendString:	@"s/$_m_/$_s_/ee"];
			if ([self matchAll]) {	
				[programString appendString:		@"g"];
			} 
			[programString appendString:							@";"];						
			[programString appendString:@"};"];

			[programString appendString:	@"if ($@) {"];									// if not, there will be an error-message ($@)
			[programString appendString:		@"die \"no valid match\";"];				// mention there is an error and exit.
			[programString appendString:	@"}"];	


			[programString appendString:@"my @_sp_;"];
			[programString appendString:@"@_sp_ = split(/\\0/,$_);"];						// split $_ to get the parts

			if ([self allowCode]) {
				// Re-allow printing to STDOUT. Looping through this is probably costly, but necessary for safety.
				[programString appendString:@"close(STDOUT) or die;"];						// Close redirected STDOUT
				[programString appendString:@"open(STDOUT,\">&SAVED_OUT\") or die;"];		// Restore normal STDOUT
				[programString appendString:@"close(SAVED_OUT) or die;"];					// Close to prevent memory leaks
			}

			[programString appendString:@"for ($_i_ = 0; $_i_ <= $#_sp_; $_i_++) {"];
			[programString appendString:	@"if ($_i_%2 != 0) {"];	
			[programString appendString:		@"print \"$_sp_[$_i_]\\0\";"];				// print the items seperated by a null-string to STDOUT
			[programString appendString:	@"}"];	
			[programString appendString:@"}"];	

			break;
		case regExSplit:
			[programString appendString:@"my @_sp_;"];
			[programString appendString:@"@_sp_ = split(/$_m_/,$_);"];						// split $_

			if ([self allowCode]) {
				// Re-allow printing to STDOUT. Looping through this is probably costly, but necessary for safety.
				[programString appendString:@"close(STDOUT) or die;"];						// Close redirected STDOUT
				[programString appendString:@"open(STDOUT,\">&SAVED_OUT\") or die;"];		// Restore normal STDOUT
				[programString appendString:@"close(SAVED_OUT) or die;"];					// Close to prevent memory leaks
			}

			[programString appendString:@"foreach (@_sp_) {"];
			[programString appendString:	@"if (defined $_) {"];	
			[programString appendString:		@"s/\\\\1/\\\\1\\\\1/g;"];
			[programString appendString:		@"print \"$_\\0\";"];						// print the items seperated by a null-string to STDOUT
			[programString appendString:	@"} else {"];	
			[programString appendString:		@"print \"\\1\\0\";"];						// print a placeholder followed by a null-string to STDOUT
			[programString appendString:	@"}"];	
			[programString appendString:@"}"];	
			break;
	}
	
}

- (void) runPerlProgram: (NSString *) programString withInput: (NSString *) programInput
// The matching by Perl is done in a seperate thread to allow the user to break of the matching.
{
	[self setMatchSucceeded: TRUE];

	[self setRegExTask: [[NSTask alloc] init]];
	[[self regExTask] setLaunchPath: @"/usr/bin/perl"];

	NSPipe *readPipe = [NSPipe pipe];
	NSFileHandle *readHandle = [readPipe fileHandleForReading];
	
	NSPipe *writePipe = [NSPipe pipe];
	NSFileHandle *writeHandle = [writePipe fileHandleForWriting];

	NSPipe *errorPipe = [NSPipe pipe];
	NSFileHandle *errorHandle = [errorPipe fileHandleForReading];
	
	[[self regExTask] setStandardInput: writePipe];
	[[self regExTask] setStandardOutput: readPipe];
	[[self regExTask] setStandardError: errorPipe];
	
	[readHandle readToEndOfFileInBackgroundAndNotify];
	[errorHandle readInBackgroundAndNotify];
	
    NSArray *arguments = [NSArray arrayWithObjects: @"-w", @"-e", programString, nil];
    [[self regExTask] setArguments: arguments];
	
	[[self regExTask] launch];
	[writeHandle writeData: [programInput dataUsingEncoding: [self encodingToUse]]];
	[writeHandle closeFile];

}

- (void) abortMatching
{
	if ([[self regExTask] isRunning]) {
		[[self regExTask] terminate];
	}
	[self setMatchSucceeded:-1];
}

- (void) regExError: (NSNotification *) note
{
	NSMutableData *data = [[note userInfo] objectForKey: NSFileHandleNotificationDataItem];
	NSString *programErrorOutput = [[NSMutableString alloc] initWithData: data encoding: [self encodingToUse]];

	if (![programErrorOutput isEqualToString:@""]) {
		[self setMatchSucceeded:-1];
		if ([[self regExTask] isRunning]) {
			[[self regExTask] terminate];
		}
	}
	
//	Unquote this to see if there is any ErrorOutput.
//	NSMutableString *tempString = [NSMutableString stringWithString:programErrorOutput];
//	[tempString replaceOccurrencesOfString:@"\0" withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[tempString length])];
//	NSLog(@"Error %@\n",tempString);

	[programErrorOutput release];
}


- (void) regExFinished: (NSNotification *) note
{
	NSMutableData *data = [[note userInfo] objectForKey: NSFileHandleNotificationDataItem];

	NSString *programOutput;

	if ([self matchSucceeded] == -1) {
		[self setMatchSucceeded: FALSE];
		programOutput = [[NSString alloc] initWithString:@""];
	} else {
		[self setMatchSucceeded:TRUE];
		if (dummyText) {
			programOutput = [[NSString alloc] initWithString: @""];
		} else {
			programOutput = [[NSString alloc] initWithData: data encoding: [self encodingToUse]];
		}
	}
		
//	Unquote this to see the output of the Perl program.
//	NSMutableString *tempString = [NSMutableString stringWithString:programOutput];
//	[tempString replaceOccurrencesOfString:@"\0" withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[tempString length])];
//	NSLog(@"output %@\n",tempString);

	if ([[self regExTask] isRunning]) {
		[[self regExTask] terminate];
	}
	[[self regExTask] release];

	if ([self matchFinished]) {

		if ([self matchSucceeded]) {
		
			if ([self doSplit]) {
				[splits removeAllObjects];
				[splits release];
				splits = [[NSMutableArray alloc]init];
				int i;
				NSArray *tempArray = [[NSArray alloc]initWithArray:[programOutput componentsSeparatedByString:@"\0"]];
				int numberOfItems = [tempArray count];
				for (i = 0; i < numberOfItems; i++) {
					NSMutableString *tempString = [[NSMutableString alloc]initWithString:[tempArray objectAtIndex:i]];
					if ([tempString isEqualToString:@"\1"]) {
						[splits addObject:@"\0"];
					} else {
						[tempString replaceOccurrencesOfString:@"\1\1" withString:@"\1" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[tempString length])];
						[splits addObject:[[NSString alloc]initWithString:tempString]];
					}
					[tempString release];
				}
				[tempArray release];
		
				[self setDoSplit: FALSE];

				NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
				[nc postNotificationName: @"RDJRegExFinished" object:@"splitting"];

			} else {																			// We're not splitting, so we are replacing.
				NSArray *replaceArray = [programOutput componentsSeparatedByString:@"\0"];
				if (([replaceArray count] - 1) != [self numberOfMatches]) {						// Every match should have a replacement text
					[self setMatchSucceeded: FALSE];
					programOutput = @"";
					[self buildResultsWith: programOutput];
				} else {
					int matchNumber;
					for (matchNumber = 1; matchNumber <= [self numberOfMatches]; matchNumber++) {
						[[self matchNumber: matchNumber] setReplacementText: [replaceArray objectAtIndex: (matchNumber - 1)]];
					}
				}

				NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
				[nc postNotificationName: @"RDJRegExFinished" object:@"replacing"];
			}
		} else {																				// Match didn't succeed.
			programOutput = @"";
			[self setMatchSucceeded: FALSE];
			[self buildResultsWith: programOutput];

			NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
			[nc postNotificationName: @"RDJRegExFinished" object:@"with replace error"];
		}

		[programOutput release];

	} else {																					// Still replacing to do.
		[self buildResultsWith: programOutput];
		[programOutput release];
		
		if ([self matchError]) {
			[self setReplacementText:nil];														// If there is an error, no need to go through replacing.
		}

		// Replace text if necessary, otherwise set the replacement text of the matches to nothing.
		[self replaceInText: [self textToMatch]													// Always go through replaceInText even if not replacing
					  regEx: [self matchRegEx]													// to set the replacement text of matches to nothing.
				  modifiers: [self regExModifiers]
			    replacement: [self replacementText]
				  allowCode: [self allowCode]];
	}
}

- (void) buildResultsWith: (NSString *) matchResults
{
	if (![self matchSucceeded]) {																// Match failed, just leave.
		return;
	}

	[self clearSelf];
	[self setMatchSucceeded:TRUE];

	matches = [[NSMutableArray alloc]init];
	splits = [[NSMutableArray alloc]init];
	
	if ([[self textToMatch] length] == 0) {														// With no text, no results,
		return;																					// and no further processing needed.
	}

	if ([matchResults isEqualToString:@"|\0"] || ([matchResults length] == 0)) {				// The result is an (effectively) empty string,
		return;																					// no further processing needed.
	}
	
	NSArray *matchArray = [matchResults componentsSeparatedByString:@"\0"];

	int i, beginPos, endPos;
	int numberOfItems = [matchArray count] - 2;

	for (i = -1 ; i < numberOfItems; i++){														// First item has no separator.
		if (i == -1 || [[matchArray objectAtIndex: i] isEqualToString:@"|"]) {
			// found a match, next item will be position at which the match starts, item after that position at which it ends

			// Thanks to Brian Bergstrand (http://www.bergstrand.org/brian/) for solving why the Intel version would crash when using
			// [self addMatchWithBeginPosition: [[matchArray objectAtIndex: ++i] intValue] endPosition: [[matchArray objectAtIndex: ++i] intValue]];
			//
            // WARNING: one of the problems with the use of pre/post operators: depending on the order of expression evaluation
            // on Intel, the args are passed on the stack, not in registers so expression evaluation is not in the order written. Example:
            // when i = -1, the endPostion index will be 0 and the beginPosition index will be 1 - the reverse of what the actual results are in the array.
            // to get around this set the indexes to temp vars to force to them to be evaulted in the correct order no matter how args are passed
            // in the current ABI
            
            beginPos = [[matchArray objectAtIndex: ++i] intValue];
            endPos = [[matchArray objectAtIndex: ++i] intValue];
            [self addMatchWithBeginPosition: beginPos endPosition: endPos];
		} else {
			// item must be the starting position a captured match, the next item will be its end position. Add these to current match.

			// Same problem, again thanks Brian for the solution.
			//  [[matches lastObject] addCaptureWithBeginPosition: [[matchArray objectAtIndex: i] intValue] endPosition: [[matchArray objectAtIndex: ++i] intValue]];
            beginPos = [[matchArray objectAtIndex: i] intValue];
            endPos = [[matchArray objectAtIndex: ++i] intValue];
            [[matches lastObject] addCaptureWithBeginPosition: beginPos endPosition: endPos];
		}
	}
}



#pragma mark-
#pragma mark Other methods

- (int) numberOfMatches
{
	return [matches count];
}

- (int) numberOfSplits
{
	return [splits count];
}

- (void) clearSelf
{
	[self setMatchSucceeded: FALSE];

	[splits removeAllObjects];
	[splits release];

	[matches removeAllObjects];
	[matches release];
}


- (NSString *) displayInOutlineWithSource: (NSString *) sourceText
// Use when object is to be called from a NSOutlineView-datasource.
// Shouldn't show up, because this is the root.
{
	NSString *returnString = [[NSString alloc] initWithString: @"Match details"];
	[returnString autorelease];
	return returnString;
}

- (int) numberOfChildrenShowingReplacements: (BOOL) showReplacements
// Use when object is to be called from a NSOutlineView-datasource.
{
	return [matches count];
}

- (id) child: (int) index
{
	return [matches objectAtIndex: index];
}


#pragma mark-
#pragma mark Cleaning up


- (void) dealloc
{
	NSEnumerator *enumerator;
	id containedItem;
	
	enumerator = [splits objectEnumerator];
	while (containedItem = [enumerator nextObject]) {
		[containedItem release];
	}
	[splits release];

	enumerator = [matches objectEnumerator];
	while (containedItem = [enumerator nextObject]) {
		[containedItem release];
	}
	[matches release];
	
	[super dealloc];
}


@end
