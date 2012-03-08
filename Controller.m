//
//  Controller.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import "Controller.h"

@implementation Controller

#pragma mark-
#pragma mark Starting up and shutting down

- (id) init
{
	self = [super init];
	if (self != nil) {
		if (![self checkMinimumVersion]) {
			// The user is not running the minimally required version of OS X.
			
			NSString *pathToInfoPList = [[NSBundle mainBundle] pathForResource: @"Info" ofType: @"plist"];
			NSDictionary *factoryDefaults = [NSDictionary dictionaryWithContentsOfFile: pathToInfoPList];
			NSString *minimumVersion = [factoryDefaults objectForKey: @"minimumVersionRequired"];
			
			NSLog (@"Minimum required version of OS X not found.\n");
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText: [NSString stringWithFormat: NSLocalizedString(@"Version %@ too low", nil), minimumVersion]];
			[alert addButtonWithTitle: NSLocalizedString(@"Quit", nil)];
			[alert setInformativeText: [NSString stringWithFormat: NSLocalizedString(@"Warning version %@ too low", nil), minimumVersion]];
			[alert setAlertStyle: NSCriticalAlertStyle];
			[alert runModal];
			[alert release];
			[NSApp terminate:self];																// Exit.
		}

		// Is Perl available?
		// Thanks to Brian Bergstrand for simplifying the detection of perl.
        NSString *string = [[NSString alloc] initWithString:@"/usr/bin/perl"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:string]) {
			// Can't find Perl at "/usr/bin/perl".
			NSLog (@"Error locating \"Perl\": %@.\n", string);
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText: NSLocalizedString(@"No Perl", nil)];
			[alert addButtonWithTitle: NSLocalizedString(@"Quit", nil)];
			[alert setInformativeText: NSLocalizedString(@"Warning no Perl", nil)];
			[alert setAlertStyle: NSCriticalAlertStyle];
			[alert runModal];
			[alert release];
			[NSApp terminate:self];																// Exit.
		}

		// If we get here, all is well.
		[string release];
		
		// Set default preferences.
		[self setFactoryDefaults];

		// Register with notificationcenter to hear when colours are changed.
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(handleColourChange:)
				   name: @"NSColorPanelColorDidChangeNotification"
			     object: nil];

		// Register with notificationcenter to hear when a new match should be started.
		[nc addObserver: self
			   selector: @selector(startMatch:)
				   name: @"RDJStartMatch"
			     object: nil];

		// Register with notificationcenter to hear when a new replace (without an accompanying match) should be started.
		[nc addObserver: self
			   selector: @selector(startReplace:)
				   name: @"RDJStartReplace"
			     object: nil];

		// Register with notificationcenter to hear when match is finished.
		[nc addObserver: self
			   selector: @selector(matchFinished:)
				   name: @"RDJRegExFinished"
			     object: nil];

		// Set some globals.
		regExResults = [[RegExRoot alloc] init];
		matchInProgress = FALSE;
		matchAborted = FALSE;
		interruptMatchInProgress = FALSE;
		forceMatchDrawing = FALSE;
	}

	return self;
}

- (BOOL) checkMinimumVersion
// Use the file /System/Library/CoreServices/SystemVersion.plist to check the user uses the minimum required version.
{
	NSString *pathToInfoPList = [[NSBundle mainBundle] pathForResource: @"Info" ofType: @"plist"];
	NSDictionary *factoryDefaults = [NSDictionary dictionaryWithContentsOfFile: pathToInfoPList];

	NSString *minimumVersion = [factoryDefaults objectForKey: @"minimumVersionRequired"];

//	NSString *minimumVersion = [NSString stringWithString: minimumVersionRequired];
 
	BOOL versionOK = FALSE;

    int major = 0;
    int minor = 0;
    int bugfix = 0;
    
    NSString *systemVersion = [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] objectForKey:@"ProductVersion"];    
    NSArray *systemVersionComponents = [systemVersion componentsSeparatedByString:@"."];

	switch ([systemVersionComponents count]) {
		case 3:
			bugfix = [[systemVersionComponents objectAtIndex:2] intValue];
		case 2:
			minor = [[systemVersionComponents objectAtIndex:1] intValue];
		case 1:
			major = [[systemVersionComponents objectAtIndex:0] intValue];
			break;
		default:
			return FALSE;
	}

	NSArray *minimumVersionComponents = [minimumVersion componentsSeparatedByString:@"."];
	int numberOfComponents = [minimumVersionComponents count];

	if (major > [[minimumVersionComponents objectAtIndex:0] intValue]) {
		versionOK = TRUE;
	} else if (major < [[minimumVersionComponents objectAtIndex:0] intValue]) {
		versionOK = FALSE;
	} else if (numberOfComponents < 2) {														// major is required minimum and no minor specified
		versionOK = TRUE;
	} else if (minor > [[minimumVersionComponents objectAtIndex:1] intValue]) {					// major is required minimum, so check minor
		versionOK = TRUE;
	} 	else if (minor < [[minimumVersionComponents objectAtIndex:1] intValue]) {
		versionOK = FALSE;
	} else if (numberOfComponents < 3) {														// minor is required minimum and no bugfix specified
		versionOK = TRUE;
	} else if (bugfix > [[minimumVersionComponents objectAtIndex:2] intValue]) {				// minor is required minimum, so check bugfix
		versionOK = TRUE;
	} else if (bugfix < [[minimumVersionComponents objectAtIndex:2] intValue]) {
		versionOK = FALSE;
	} else {																					// bugfix is required minimum
		versionOK = TRUE;
	}

	return versionOK;
}

- (void) setFactoryDefaults
// This method registers the default values of the preferences. It the user changes them in the preference window, Cocoa bindings will take care of saving those.
{
		NSString *pathToInfoPList = [[NSBundle mainBundle] pathForResource: @"Info" ofType: @"plist"];
		NSDictionary *factoryDefaults = [NSDictionary dictionaryWithContentsOfFile: pathToInfoPList];
		
		NSMutableDictionary *regExhibitDefaults = [NSMutableDictionary dictionary];

		NSColor *aColour = [[NSColorList colorListNamed: @"Crayons"] colorWithKey: [factoryDefaults objectForKey: @"matchColour"]];
		if (!aColour) {
			aColour = [NSColor blueColor];
		}
		[regExhibitDefaults setObject: [NSArchiver archivedDataWithRootObject:aColour] forKey: @"matchColour"];

		aColour = [[NSColorList colorListNamed: @"Crayons"] colorWithKey: [factoryDefaults objectForKey: @"captureColour"]];
		if (!aColour) {
			aColour = [NSColor redColor];
		}
		[regExhibitDefaults setObject: [NSArchiver archivedDataWithRootObject:aColour] forKey: @"captureColour"];

		aColour = [[NSColorList colorListNamed: @"Crayons"] colorWithKey: [factoryDefaults objectForKey: @"replaceColour"]];
		if (!aColour) {
			aColour = [NSColor purpleColor];
		}
		[regExhibitDefaults setObject: [NSArchiver archivedDataWithRootObject:aColour] forKey: @"replaceColour"];

		[regExhibitDefaults setObject: [factoryDefaults objectForKey: @"underlineMatch"] forKey: @"underlineMatch"];
		[regExhibitDefaults setObject: [factoryDefaults objectForKey: @"underlineCapture"] forKey: @"underlineCapture"];
		[regExhibitDefaults setObject: [factoryDefaults objectForKey: @"shadeOverlappingCaptures"] forKey: @"shadeOverlappingCaptures"];
		[regExhibitDefaults setObject: [factoryDefaults objectForKey: @"underlineReplace"] forKey: @"underlineReplace"];
		[regExhibitDefaults setObject: [factoryDefaults objectForKey: @"allowCode"] forKey: @"AllowCode"];
		[regExhibitDefaults setObject: [factoryDefaults objectForKey: @"liveMatching"] forKey: @"liveMatching"];

		[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: regExhibitDefaults];
		[[NSUserDefaults standardUserDefaults] registerDefaults: regExhibitDefaults];
}

- (void) awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// Set up these textview to use a special layoutmanager that can display underlines under leading and trailing spaces.
	[[findMatchText textContainer] replaceLayoutManager: [[RegExhibitLayoutManager alloc] init]];
	[[replaceMatchText textContainer] replaceLayoutManager: [[RegExhibitLayoutManager alloc] init]];
	[[replaceResultText textContainer] replaceLayoutManager: [[RegExhibitLayoutManager alloc] init]];
	[[splitMatchText textContainer] replaceLayoutManager: [[RegExhibitLayoutManager alloc] init]];

	// Add subviews tot statusview
	[regExStatusView addSubview: regExProgressIndicatorView];
	[regExStatusView addSubview: regExInvalidView];
	[regExInvalidView setHidden:TRUE];
	[regExStatusView addSubview: regExAbortedView];
	[regExAbortedView setHidden:TRUE];

	// Get the correct colours to use from the nib.
	[captureColour release];
	captureColour = (NSColor *)[NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: @"captureColour"]];
	[captureColour retain];

	[matchColour release];
	matchColour = (NSColor *)[NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: @"matchColour"]];
	[matchColour retain];

	[replaceColour release];
	replaceColour = (NSColor *)[NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: @"replaceColour"]];
	[replaceColour retain];

	// Set default font to use in textviews.
	[NSFont setUserFont: MAIN_FONT];
	
	// Set the status of the matching-cancel button
	if ([defaults boolForKey: @"liveMatching"]) {
		[toggleMatchingButton setTitle: NSLocalizedString(@"Cancel", nil)];
		[toggleMatchingButton setEnabled:FALSE];
	} else {
		[toggleMatchingButton setTitle: NSLocalizedString(@"Match", nil)];
		[toggleMatchingButton setEnabled:TRUE];
	}
	
	// Calculate a save width under which a text will be just one line, unless it contains a newline
	[self setSafeWidth: [findMatchText bounds].size.width / [[NSFont systemFontOfSize: 13.0] maximumAdvancement].width];
	
	// Trick the current tabviewitem in believing it will be selected, so it will perform some initialisations
	[self tabView:tabView willSelectTabViewItem:[tabView selectedTabViewItem]];

	// Register for notifications that the bounds of a view are changed.
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(boundsDidChangeNotification:)
												 name: NSViewBoundsDidChangeNotification
											   object: nil];

	// Tell the relevant views, they need to send notifications if their bounds are changed.
	[findMatchText setPostsBoundsChangedNotifications: YES];
	[replaceMatchText setPostsBoundsChangedNotifications: YES];
	[splitMatchText setPostsBoundsChangedNotifications: YES];
}

- (void) dealloc
{
	[[[findMatchText textContainer] layoutManager] release];
	[[[replaceMatchText textContainer] layoutManager] release];
	[[[replaceResultText textContainer] layoutManager] release];
	[[[splitMatchText textContainer] layoutManager] release];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	
	[replaceColour release];
	[captureColour release];
	[matchColour release];
	[regExResults release];
	
	[super dealloc];
}

#pragma mark-
#pragma mark Accessors

- (void) setInterruptMatchInProgress: (BOOL) aBool
{
	interruptMatchInProgress = aBool;
}

- (BOOL) interruptMatchInProgress
{
	return interruptMatchInProgress;
}

- (void) setMatchAborted: (BOOL) aBool
{
	matchAborted = aBool;
	if ([self matchAborted]) {
		[self setMatchInProgress: FALSE];
	}
}

- (BOOL) matchAborted
{
	return matchAborted;
}

- (void) setMatchInProgress: (BOOL) aBool
{
	matchInProgress = aBool;
}

- (BOOL) matchInProgress
{
	return matchInProgress;
}

- (void) setSafeWidth: (int) aWidth
// safeWidth is the safe length of a string that will fit on one line, unless it contains a newline.
{
	safeWidth = aWidth;
}

- (int) safeWidth
{
	return safeWidth;
}

// Pseudo accessors
- (IBAction) setAllowCode: (id) sender
{
	if ([sender intValue]) {															// User checked box Allow code.
		[allowCodeCheck setEnabled:FALSE];

		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: NSLocalizedString(@"Confirm allow code", nil)];
		[alert addButtonWithTitle: NSLocalizedString(@"Cancel", nil)];
		[alert addButtonWithTitle: NSLocalizedString(@"Allow code", nil)];
		[alert setInformativeText: NSLocalizedString(@"Warning allow code", nil)];
		[alert setAlertStyle: NSWarningAlertStyle];
		[alert beginSheetModalForWindow:[sender window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		[alert release];
	} else																				// User unchecked box Allow code.
		if ([self liveMatching]) {
			[self newMatch];
		}
}

- (BOOL) allowCode
// If the user has checked Allow code in the preferences, but hasn't confirmed the alert sheet, allowCodeCheck is disabled.
{
	return [allowCodeCheck isEnabled] && [[NSUserDefaults standardUserDefaults] boolForKey: @"allowCode"];	// Only allowed if checkbox is enabled and checked.
}

- (IBAction) setLiveMatching: (id) sender
{
	if ([sender intValue]) {															// Checkbox Live Matching is checked.
		[toggleMatchingButton setTitle: NSLocalizedString(@"Cancel", nil)];
		[toggleMatchingButton setEnabled:FALSE];
		[self newMatch];
	} else {
		[toggleMatchingButton setTitle: NSLocalizedString(@"Match", nil)];
		[toggleMatchingButton setEnabled:TRUE];
	}
}

- (BOOL) liveMatching
{
	return [[NSUserDefaults standardUserDefaults] boolForKey: @"liveMatching"];
}


#pragma mark-
#pragma mark User input

// TextView delegate
- (void) textDidChange: (NSNotification *) aNotification
// This is the delegate function for all textviews the user can edit. If text in any of these changes, it means we probably need to perform a match.
// The only time this isn't necessary, is when just the replacement string has been changed. In that case only an update op the replacementstrings is
// needed.
{	
	if (![self liveMatching]) {															// Only proceed when live matching.
		return;
	}
	
	if ([self matchAborted]) {
		[self newMatch];
	} else if ([[aNotification object] isEqualTo:replaceRegex] && [regExResults matchSucceeded]) {
		[self newReplace];																// If only the replacementstring is changed, only a replace is needed.
	} else {
		[self newMatch];
	}
}

- (void) boundsDidChangeNotification: (NSNotification *) aNotification
// This method is called when the bounds of a view are changed. In this case, the bounds of the textToMatch view.
// When this is the case, drawn the displayed part of the view.
{
	[self displayMatchResults];
}

- (void) handleColourChange: (NSNotification *) note
// This method is called when the user changes colours in the preferences window.
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSColor *aColour;
	BOOL colourChanged = FALSE;
		
	aColour = (NSColor *)[NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: @"captureColour"]];
	if (![captureColour isEqual: aColour]) {
		[captureColour release];
		captureColour = aColour;
		[captureColour retain];
		colourChanged = TRUE;
	}

	aColour = (NSColor *)[NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: @"matchColour"]];
	if (![matchColour isEqual: aColour]) {
		[matchColour release];
		matchColour = aColour;
		[matchColour retain];
		colourChanged = TRUE;
	}

	aColour = (NSColor *)[NSUnarchiver unarchiveObjectWithData: [defaults dataForKey: @"replaceColour"]];
	if (![replaceColour isEqual: aColour]) {
		[replaceColour release];
		replaceColour = aColour;
		[replaceColour retain];
		colourChanged = TRUE;
	}

	if (colourChanged) {																// Redisplay the text, but don't rematch.
		[self setMatchInProgress: TRUE];
		[self runProgressIndicator: TRUE];
		[self clearTextToMatch];
		forceMatchDrawing = TRUE;														// Will automatically be turned off after drawing.
		[self prepareDrawing];
		[self runProgressIndicator: FALSE];
		[self setMatchInProgress: FALSE];
	}
}

- (IBAction) preferredColoursChanged: (id) sender
// This method is called if the user changes a preference that influences the way matches etc. are displayed, e.g. underlining of captures.
{
	[self setMatchInProgress: TRUE];
	[self runProgressIndicator: TRUE];
	[self clearTextToMatch];
	forceMatchDrawing = TRUE;															// Will automatically be turned off after drawing.
	[self prepareDrawing];
	[self runProgressIndicator: FALSE];
	[self setMatchInProgress: FALSE];
}

- (IBAction) modifiersChanged: (id) sender
// This method is called if the user changes a regex modifier. The values are read out when matching, so no need to bother with them here.
{
	if ([self liveMatching]) {
		[self newMatch];
	}
}

- (IBAction) toggleMatching: (id) sender
// This method is called when the user clicks the cancel/match button in the InfoView.
{
	if ([self matchInProgress]) {														// The user clicked the cancel-button.
		[regExResults abortMatching];
		[self regExAborted: TRUE];
	} else {																			// The user clicked the match-button.
		[self regExAborted: FALSE];
		[self regExInvalid: FALSE];
		[self newMatch];
	}
}

- (void) alertDidEnd: (NSAlert *) alert 
		  returnCode: (int) returnCode 
		 contextInfo: (void *) contextInfo
// Called when the user selects to allow code execution in the preferences window.
{
	[allowCodeCheck setEnabled:TRUE];

	if (returnCode == NSAlertSecondButtonReturn) {
		// User confirmed code should be allowed
		[[NSUserDefaults standardUserDefaults] setBool: TRUE forKey: @"allowCode"];
		if ([self liveMatching]) {														// Conditions have changed, so re-match of allowed.
			[self newMatch];
		}
	} else {
		// User recanted, so clear.
		[[NSUserDefaults standardUserDefaults] setBool: FALSE forKey: @"allowCode"];
	}
}

#pragma mark-
#pragma mark Perform match and show results

- (void) interruptMatch
// This method is called when the user requests a new match, usually by typing a new character, while the current match hasn't finished.
// It sets a flag and aborts the match. (This is only effective, if there is a match running in the background.)
// At several points the flag can be noticed by RegExhibit, and it will then continue with the new match.
{
	[self setInterruptMatchInProgress: TRUE];
	[regExResults abortMatching];
}

- (void) handleInterrupt
// This will always do a full match for safety, even if only a partial one is necessary.
{
	[self setInterruptMatchInProgress: FALSE];
	[[NSNotificationQueue defaultQueue] enqueueNotification: [NSNotification notificationWithName: @"RDJStartMatch" object: nil]
											   postingStyle: NSPostASAP // NSPostWhenIdle // 
											   coalesceMask: NSNotificationCoalescingOnName
													   forModes: nil];
}


- (void) newMatch {
	if ([self matchInProgress]) {
		[self interruptMatch];
	} else {
		// Send a notification to start match. The notifications are coalesced.
		[[NSNotificationQueue defaultQueue] enqueueNotification: [NSNotification notificationWithName: @"RDJStartMatch" object: nil]
												   postingStyle: NSPostWhenIdle // NSPostASAP // 
												   coalesceMask: NSNotificationCoalescingOnName
													   forModes: nil];

	}
}

- (void) newReplace {
	if ([self matchInProgress]) {
		[self interruptMatch];
	} else {
		// Send a notification to start match. The notifications are coalesced.
		[[NSNotificationQueue defaultQueue] enqueueNotification: [NSNotification notificationWithName: @"RDJStartReplace" object: nil]
												   postingStyle: NSPostWhenIdle // NSPostASAP // 
												   coalesceMask: NSNotificationCoalescingOnName
													   forModes: nil];
	}
}

- (void) startMatch: (NSNotification *) aNotification
{
	if ([self interruptMatchInProgress]) {
		[self handleInterrupt];
		return;
	}
	[self performMatch];
}

- (void) startReplace: (NSNotification *) aNotification
{
	if ([self interruptMatchInProgress]) {
		[self handleInterrupt];
		return;
	}
	[self performReplace];
}

- (void) performMatch
{
	// First set up for matching.
	[detailsDrawer close];
	[self regExAborted: FALSE];
	[self regExInvalid: FALSE];
	[infoView displayRect:[regExStatusView frame]];
	[self runProgressIndicator: TRUE];
	
	// Depending on the fact if live matching is allowed, the match/cancel button should either be enabled or be renamed to cancel.
	if ([self liveMatching]) {
		[toggleMatchingButton setEnabled:TRUE];
	} else {
		[toggleMatchingButton setTitle: NSLocalizedString(@"Cancel", nil)];
	}

	[self setMatchInProgress: TRUE];

	// Perform the match.
	[regExResults matchText: [textToMatch string]
					toRegEx: [matchRegex string]
				  modifiers: [self regExModifiersSet]
				replacement: [replaceRegex string]
				  allowCode: [self allowCode]];
}

- (void) performReplace
{
	// First set up for replacing.
	[detailsDrawer close];
	[self regExAborted: FALSE];
	[self regExInvalid: FALSE];
	[infoView displayRect:[regExStatusView frame]];
	[self runProgressIndicator: TRUE];
	
	// Depending on the fact if live matching is allowed, the match/cancel button should either be enabled or be renamed to cancel.
	if ([self liveMatching]) {
		[toggleMatchingButton setEnabled:TRUE];
	} else {
		[toggleMatchingButton setTitle: NSLocalizedString(@"Cancel", nil)];
	}

	[self setMatchInProgress: TRUE];

	// Perform the replacing.
	[regExResults replaceInText: [textToMatch string] 
						  regEx: [matchRegex string]
					  modifiers: [self regExModifiersSet]
					replacement: [replaceRegex string]
					  allowCode: [self allowCode]];
}



- (NSSet *) regExModifiersSet
// Walk through the matrix and get the values of the modifiers.
{
	NSEnumerator *enumerator;
	NSCell *cell;
	NSMutableSet *tempSet = [[NSMutableSet alloc]init];
	NSSet *regExModifiersSet;
	
	enumerator = [[modifierMatrix cells] objectEnumerator];
	while (cell = [enumerator nextObject]) {
		switch ([cell tag]) {
			case regExFindAll:
				if ([cell intValue]) {
					[tempSet addObject:[NSString stringWithFormat:@"%d", regExFindAll]];
				}
				break;
			case regExCaseInsensitive:
				if ([cell intValue]) {
					[tempSet addObject:[NSString stringWithFormat:@"%d", regExCaseInsensitive]];
				}
				break;
			case regExWhiteSpace:
				if ([cell intValue]) {
					[tempSet addObject:[NSString stringWithFormat:@"%d", regExWhiteSpace]];
				}
				break;
			case regExDotMatchNEwline:
				if ([cell intValue]) {
					[tempSet addObject:[NSString stringWithFormat:@"%d", regExDotMatchNEwline]];
				}
				break;
			case regExMultiline:
				if ([cell intValue]) {
					[tempSet addObject:[NSString stringWithFormat:@"%d", regExMultiline]];
				}
				break;
			case regExUnicode:
				if ([cell intValue]) {
					[tempSet addObject:[NSString stringWithFormat:@"%d", regExUnicode]];
				}
				break;
			default:
				;
		}
	}
	regExModifiersSet = [NSSet setWithSet:tempSet];
	[tempSet release];
	return regExModifiersSet;
}

- (void) matchFinished: (NSNotification *) note
// This method is called when the matching is done. It might still be necessary to perform a replacement.
{
	if ([self interruptMatchInProgress]) {
		[self clearTextToMatch];
		[self handleInterrupt];
		return;
	}

	// Do a split if necessary and possible.
	if ((resultReplacing == splitResultTableView) && ([regExResults matchSucceeded]) && (![[note object] isEqualToString:@"splitting"])) {
		[regExResults splitText: [textToMatch string]
						onRegEx: [matchRegex string]
					  modifiers: [self regExModifiersSet]
					  allowCode: [self allowCode]];
		[self clearTextToMatch];									// Clear here for splits, because this means there was a new match and matchDrawn was reset.
	} else {
		// The match is really finished, so display the results.
		[toggleMatchingButton setEnabled:FALSE];
		[infoView displayRect:[toggleMatchingButton frame]];
		stillToDraw = [regExResults numberOfMatches];
		if (![[note object] isEqualToString:@"splitting"]) {		// Don't clear after a split, because matchDrawn is not updated when there was no new match, 
			[self clearTextToMatch];								// so clearing will result in undrawn matches.
		}
		[self prepareDrawing];
	}
}


- (void) prepareDrawing
// This method is called in preparation for the real drawing. It tests whether there is something to be drawn, and if not exits.
{
	[self regExInvalid: FALSE];
	
	if (replaceRegex != nil) {
		// If there is a replacementstring, clear the replaceresultstextview.
		[replaceResultText replaceCharactersInRange: NSMakeRange(0,[[replaceResultText textStorage] length]) withString: @""];
	}

	if ([regExResults matchError]) {
		[self regExInvalid: TRUE];
		[detailsButton setEnabled:FALSE];

		if (replaceRegex != nil) {
			[replaceResultText replaceCharactersInRange: NSMakeRange(0,[[replaceResultText textStorage]length]) withString: [textToMatch string]];
			[self clearReplaceResultText];
		}

		if (resultReplacing == splitResultTableView) {
			[resultReplacing reloadData];
		}
		[self finishDrawing];
		return;													// No valid resuls, so no need to stay.
	}

	if ([regExResults numberOfMatches] == 0) {
		[detailsButton setEnabled:FALSE];

		if (replaceRegex != nil) {
			[replaceResultText replaceCharactersInRange: NSMakeRange(0,[[replaceResultText textStorage]length]) withString: [textToMatch string]];
			[self clearReplaceResultText];
		}

		if (resultReplacing == splitResultTableView) {
			[resultReplacing reloadData];
		}
		[self finishDrawing];
		return;													// Valid, but nothing matched, so no need to stay.
	}
	
	// There are matches, show them.

	[detailsButton setEnabled:TRUE];
	[self displayMatchResults];
}

- (void) clearTextToMatch
// Clear the textToMatchView prior to a redisplaying with a new match.
{
	int lengthTextToMatch = [[textToMatch textStorage] length];

	[[textToMatch textStorage] beginEditing];
	[[textToMatch textStorage] addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:0] range:NSMakeRange(0,lengthTextToMatch)];
	[[textToMatch textStorage] addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0,lengthTextToMatch)];
	[[textToMatch textStorage] addAttribute: NSBackgroundColorAttributeName value: [NSColor whiteColor] range: NSMakeRange(0,lengthTextToMatch)];
	[[textToMatch textStorage] endEditing];
	
}

- (void) clearReplaceResultText
// Clear the replaceResultTextView when a error has occurred. Otherwise when the match is successful,
// with certain "wrong" replacementstrings, the whole area may be coloured.
{
	if (replaceRegex == nil) {															// Only valid when replacing, not when splitting
		return;
	}

	int lengthResultReplacing = [[resultReplacing textStorage] length];
	[[resultReplacing textStorage] beginEditing];
	[[resultReplacing textStorage] addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:0] range:NSMakeRange(0,lengthResultReplacing)];
	[[resultReplacing textStorage] addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0,lengthResultReplacing)];
	[[resultReplacing textStorage] endEditing];
}


- (void) displayMatchResults
// This method does the real drawing. It first checks to see which characters are visible, and will only draw does matches, except when overridden.
{
	// Exit if interrupted
	if ([self interruptMatchInProgress]) {
		[self clearTextToMatch];
		[self finishDrawing];
		return;
	}

	// Which characters are visible?
	NSRect visibleRect = [textToMatch visibleRect];
	NSPoint textContainerOrigin = [textToMatch textContainerOrigin];
	visibleRect.origin.x -= textContainerOrigin.x;
	visibleRect.origin.y -= textContainerOrigin.y;

	NSLayoutManager *layoutManager = [textToMatch layoutManager];
	NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:[textToMatch textContainer]];
	NSRange charRange = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];

	int firstVisibleCharacter = charRange.location;
	int lastVisibleCharacter = firstVisibleCharacter + charRange.length;

	// Prepare the textToMatchView.
	NSTextStorage *textToMatchStorage = [textToMatch textStorage];
	[textToMatchStorage beginEditing];
	
	int captureNumber;
	int lowestInSet;
	int maxMatchNumber = [regExResults numberOfMatches];
	int maxCaptureNumber;
	BOOL underlineMatch = [[NSUserDefaults standardUserDefaults] boolForKey: @"underlineMatch"];
	BOOL underlineCapture = [[NSUserDefaults standardUserDefaults] boolForKey: @"underlineCapture"];
	BOOL shadeOverlappingCaptures = [[NSUserDefaults standardUserDefaults] boolForKey: @"shadeOverlappingCaptures"];

	// No need to draw matches before the current visible one.
	int matchNumber = [self firstMatchToDraw: firstVisibleCharacter lowerLimit: 1 upperLimit: maxMatchNumber];

	// Only draw the matches when visible.
	for (matchNumber; matchNumber <= maxMatchNumber && [[regExResults matchNumber: matchNumber] range].location < lastVisibleCharacter; matchNumber++) {
	
		// Walk through the matches.
		id currentMatch = [regExResults matchNumber: matchNumber];

		if (!forceMatchDrawing) {
			if (stillToDraw && [currentMatch matchDrawn]) {
				continue;
			} else {
				stillToDraw--;
				[currentMatch setMatchDrawn: YES];
			}
		}
		
		NSRange matchRange = [currentMatch range];

		NSCountedSet *overlappingCapturesSet = [[NSCountedSet alloc] init];				// Used to determine overlapping captures.
		lowestInSet =  [currentMatch beginPosition];									// Used to determine overlapping captures.

		[textToMatchStorage addAttribute: NSForegroundColorAttributeName 
								   value: matchColour 
								   range: matchRange];

		if (underlineMatch) {
			[textToMatchStorage addAttribute: NSUnderlineColorAttributeName 
									   value: matchColour 
									   range: matchRange];

			[textToMatchStorage addAttribute: NSUnderlineStyleAttributeName 
									   value: [NSNumber numberWithInt:1] 
									   range: matchRange];
		}

		maxCaptureNumber = [currentMatch numberOfCaptures];
		for (captureNumber = 1; captureNumber <= maxCaptureNumber; captureNumber++) {
			// For each match, walk through its captures.
			id currentCapture = [currentMatch captureNumber: captureNumber];
			NSRange captureRange = [currentCapture range];
			
			[textToMatchStorage addAttribute: NSForegroundColorAttributeName 
									   value: captureColour 
									   range: captureRange];
													
			if (underlineCapture) {
				[textToMatchStorage addAttribute: NSUnderlineColorAttributeName 
										   value: captureColour 
										   range: captureRange];

				[textToMatchStorage addAttribute: NSUnderlineStyleAttributeName 
										   value: [NSNumber numberWithInt:1] 
										   range: captureRange];
			}

			if (shadeOverlappingCaptures) {
				if ([overlappingCapturesSet occurencesCount]) {
					while (([overlappingCapturesSet occurencesCount]) && 
							([currentCapture beginPosition] > lowestInSet)) {
							// While there are overlapping captures and the beginposition of the current capture of the currend match is larger 
							// than the known lowest in the overlappingCapturesSet.
						[overlappingCapturesSet removeObject:[NSString stringWithFormat:@"%d",lowestInSet]];
						lowestInSet = [overlappingCapturesSet lowestInt];
					}

					if ([overlappingCapturesSet occurencesCount]) {
						float shade = 0.7;
						int i;
						for (i = 0; i < [overlappingCapturesSet occurencesCount] -1; i++) {					// Darken shade for each overlapping match.
							shade *= 0.7;
						}
					
						[textToMatchStorage addAttribute: NSBackgroundColorAttributeName 
												   value: [NSColor colorWithCalibratedWhite:shade alpha:1.0] 
												   range: captureRange];
					}
				}
				NSString *tempString = [[NSString alloc]initWithFormat:@"%d",
										[currentCapture endPosition]];
				[overlappingCapturesSet addObject:tempString];
				[tempString autorelease];
				lowestInSet = [overlappingCapturesSet lowestInt];
			}
		}
		[overlappingCapturesSet release];
	}
	[textToMatchStorage endEditing];
	
	// Prepare the replaceResultTextView.
	[[replaceResultText textStorage] beginEditing];
	if (replaceRegex != nil) {

		int length = [[replaceResultText textStorage] length];
		[replaceResultText replaceCharactersInRange: NSMakeRange(0,length) withString: @""];
		
		BOOL underlineReplace = [[NSUserDefaults standardUserDefaults] boolForKey: @"underlineReplace"];

		NSMutableAttributedString *tempString;
		int beginPosition = 0;
		for (matchNumber = 1; matchNumber <= maxMatchNumber; matchNumber++) {
			// Get the part after the previous match and before the current match.
			tempString = [[NSMutableAttributedString alloc] initWithString: 
					[[textToMatch string] substringWithRange: NSMakeRange(beginPosition,[[regExResults matchNumber: matchNumber] beginPosition] - beginPosition)]];
			[tempString addAttribute: NSFontAttributeName 
							   value: MAIN_FONT 
							   range: NSMakeRange(0,[tempString length])];
			[[replaceResultText textStorage] appendAttributedString:tempString];
			[tempString release];

			// Bump the beginPosition one place along
			beginPosition = [[regExResults matchNumber:matchNumber]endPosition];

			// Get the current replacementString.
			tempString = [[NSMutableAttributedString alloc]initWithString:[[regExResults matchNumber:matchNumber]replacementText]];
			[tempString addAttribute: NSFontAttributeName 
							   value: MAIN_FONT 
							   range: NSMakeRange(0,[tempString length])];
			[tempString addAttribute: NSForegroundColorAttributeName 
							   value: replaceColour 
							   range: NSMakeRange(0,[tempString length])];

			if (underlineReplace) {
				[tempString addAttribute: NSUnderlineColorAttributeName 
								   value: replaceColour 
								   range: NSMakeRange(0,[tempString length])];

				[tempString addAttribute: NSUnderlineStyleAttributeName 
								   value: [NSNumber numberWithInt:1] 
								   range: NSMakeRange(0,[tempString length])];
			}

			[[replaceResultText textStorage] appendAttributedString:tempString];
			[tempString release];
		}
		
		// Finish of with the string from the end of the last match to the end of the text.
		beginPosition = [[regExResults matchNumber:--matchNumber]endPosition];
		tempString = [[NSMutableAttributedString alloc]initWithString:[[textToMatch string]substringWithRange: NSMakeRange(beginPosition,[[textToMatch string]length] - beginPosition)]];
		[tempString addAttribute: NSFontAttributeName 
						   value: MAIN_FONT 
						   range: NSMakeRange(0,[tempString length])];
		[[replaceResultText textStorage] appendAttributedString:tempString];
		[tempString release];
	}
	[[replaceResultText textStorage] endEditing];

	// When done, force de detailsOutline to update.
	[detailsOutlineView reloadData];
	
	// If necessary, do the same for the splitresults table.
	if (resultReplacing == splitResultTableView) {
		[resultReplacing reloadData];
	}
	[self finishDrawing];
}

- (void) finishDrawing
// Finish up after drawing.
{
	if (forceMatchDrawing) {
		forceMatchDrawing = FALSE;																	// Turn off forceMatchDrawing if it has been turned on.
	}

	[self setMatchInProgress: FALSE];
	[self runProgressIndicator: FALSE];
	if (![self liveMatching]) {
		[toggleMatchingButton setEnabled:TRUE];
		[toggleMatchingButton setTitle: NSLocalizedString(@"Match", nil)];
	}
}


#pragma mark-
#pragma mark Other methods

- (int) firstMatchToDraw: (int) firstVisibleCharacter lowerLimit: (int) lowerLimit upperLimit: (int) upperLimit
// To speed up RegExhibit, this method determines the first match that should be drawwn, based on the first visible character in the window.
// It does a binary search, until it distance between the possible starting matches is less than 10 and than does a linear search.
{
	if (upperLimit <= lowerLimit) { 
		return 1; 
	} else if (upperLimit - lowerLimit < 10) {
		while ((lowerLimit <= upperLimit) && ([[regExResults matchNumber: lowerLimit] range].location < firstVisibleCharacter)) {
			lowerLimit++;
		}
		return lowerLimit;	
	} else {
		int midWay = lowerLimit + (upperLimit - lowerLimit) / 2;
		if  ([[regExResults matchNumber: midWay] range].location < firstVisibleCharacter) {
			return [self firstMatchToDraw: firstVisibleCharacter lowerLimit: midWay upperLimit: upperLimit];
		} else {
			return [self firstMatchToDraw: firstVisibleCharacter lowerLimit: lowerLimit upperLimit: midWay];
		}
	}
}

- (void) runProgressIndicator: (BOOL) animateProgressIndicator
{
	if (animateProgressIndicator) {
		[regExProgressIndicator startAnimation: self];
	} else {
		[regExProgressIndicator stopAnimation: self];
	}
}

- (void) regExInvalid: (BOOL) regExInvalid
{
	if ([self matchAborted]) {
		[regExProgressIndicator setHidden: TRUE];
		[regExInvalidView setHidden: TRUE];
	} else if (regExInvalid) {
		[regExProgressIndicator setHidden: TRUE];
		[regExAbortedView setHidden: TRUE];
		[regExInvalidView setHidden: FALSE];
	} else {
		[regExInvalidView setHidden: TRUE];
		[regExProgressIndicator setHidden: FALSE];
	}
}

- (void) regExAborted: (BOOL) regExAborted
{
	if (regExAborted) {
		[self setMatchAborted: TRUE];
		[regExProgressIndicator setHidden: TRUE];
		[regExInvalidView setHidden: TRUE];
		[regExAbortedView setHidden: FALSE];
	} else {
		[self setMatchAborted: FALSE];
		[regExAbortedView setHidden: TRUE];
		[regExProgressIndicator setHidden: FALSE];
	}
}

- (IBAction) showDetails: (id) sender
{
	if ([detailsButton isEnabled]) {
		[detailsButton performClick: sender];
	}
}

- (IBAction) switchTab: (id) sender
{
	if (![self matchInProgress]) {
		switch ([[sender keyEquivalent] intValue] - 1) {
			case regExMatch:
				[tabView selectTabViewItemAtIndex: regExMatch];
				break;
			case regExReplace:
				[tabView selectTabViewItemAtIndex: regExReplace];
				break;
			case regExSplit:
				[tabView selectTabViewItemAtIndex: regExSplit];
				break;
			default:
				NSLog(@"Unknown tabview at switchTab: %@\n", sender);
		}
	}
}


- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
	// If the main window is miniturised, disable the view menu items.
	if ([[tabView window] isMiniaturized]) {
		return NO;
	}

	// Match the state of the details menu item to that of the details button.
	NSString *selectorString;
	selectorString = NSStringFromSelector([menuItem action]);
	if ([menuItem action] == @selector(showDetails:)) {
		return [detailsButton isEnabled];
	} else {
		return YES;
	}
}


#pragma mark-
#pragma mark Application delegate

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication
{
 	return TRUE;
}
 
#pragma mark-
#pragma mark Window delegate

- (void) windowDidResize: (NSNotification *) aNotification
{
	// The size of the window has changed, so re-calculate safeWidth
	[self setSafeWidth: [findMatchText bounds].size.width / [[NSFont systemFontOfSize: 13.0] maximumAdvancement].width];
}
 
#pragma mark-
#pragma mark TabView delegate
 
- (void) tabView: (NSTabView *) tabView willSelectTabViewItem: (NSTabViewItem *) tabViewItem
// This method uses the instance variable findAllState to keep track of the state of the find all modifier. This is necessary to restore it when a user
// switches to split, because split always finds all matches. The find tabview or replace tabview set findAllState to -1, so if it isn't -1, the previous
// tab was split. The split tabview sets the variable to the value of the find all modifier, i.e. 0 or 1. If it is 0, and the user switches to another
// tabview, it means the match is no longer the correct one, because it shouldn't match all.
{
	BOOL performMatch = FALSE;															// If we're just switching from another tab, 
																						// a match might not be necessary.
	if ([self liveMatching]) {
		[self runProgressIndicator: TRUE];
	}

	switch ([[tabViewItem identifier] intValue]) {										// Which tabview is showing?
		case regExMatch:
			[findRegExModifiersView addSubview: regExModifiersView];					// Show the common view with modifiers.
			[findInfoView addSubview: infoView];										// Show the common information view.

			if ([[matchRegex string] length] > 0) {										// If there is a current matchregex, show it on this tab.
				[[findMatchRegEx textStorage] setAttributedString: [matchRegex attributedSubstringFromRange:NSMakeRange(0,[[matchRegex string] length])]];
			} else if (matchRegex) {
				[findMatchRegEx setString: @""];
			}

			if ([[textToMatch string] length] > 0) {									// If there is a current text to match, show it on this tab.
				[[findMatchText textStorage] setAttributedString: [textToMatch attributedSubstringFromRange:NSMakeRange(0,[[textToMatch string] length])]];
			} else if (textToMatch) {
				[findMatchText setString: @""];
			}

			if ((replaceRegex != nil)													// If replaceRegex is not nil, the previous tab was replace.
				&& [regExResults matchError]											// If there was an error, it might have been caused by the replacement.
				&& ![self matchAborted]) {												// If the match wasn't aborted, 
				performMatch = TRUE;													// a new match is needed or a valid match may not show.
			}

			// Set the common outlets to the correct ones for this tab.
			matchRegex = findMatchRegEx;
			textToMatch = findMatchText;
			replaceRegex = nil;
			resultReplacing = nil;

			if (findAllState != -1) {													// Switching back from split-tabview
				[[modifierMatrix cellWithTag:0] setEnabled:TRUE];
				[[modifierMatrix cellWithTag:0] setIntValue:findAllState];
				if ([self liveMatching]
					&& (findAllState == 0)												// The saved state was not find all
					&& ![self matchAborted]) {											// and the match was not aborted,
					[self newMatch];													// so a match is needed.
				} else {																// No match needed, so stop the progressindicator.
					[self prepareDrawing];
					[self runProgressIndicator: FALSE];
				}
				findAllState = -1;
			} else {																	// The previous tabview was replace.
				if ([self liveMatching] && performMatch) {								// A match was deemed necessary.
					[self newMatch];													
				}
					[self prepareDrawing];
					[self runProgressIndicator: FALSE];
			}
	
			break;
		case regExReplace:
			[replaceRegExModifiersView addSubview: regExModifiersView];					// Show the common view with modifiers.
			[replaceInfoView addSubview: infoView];										// Show the common information view.

			if ([[matchRegex string] length] > 0) {										// If there is a current matchregex, show it on this tab.
				[[replaceMatchRegEx textStorage] setAttributedString: [matchRegex attributedSubstringFromRange:NSMakeRange(0,[[matchRegex string] length])]];
			} else if (matchRegex) {
				[replaceMatchRegEx setString: @""];
			}

			if ([[textToMatch string] length] > 0) {									// If there is a current text to match, show it on this tab.
				[[replaceMatchText textStorage] setAttributedString: [textToMatch attributedSubstringFromRange:NSMakeRange(0,[[textToMatch string] length])]];
			} else if (textToMatch) {
				[replaceMatchText setString: @""];
			}

			// Set the common outlets to the correct ones for this tab.
			matchRegex = replaceMatchRegEx;
			textToMatch = replaceMatchText;
			replaceRegex = replaceReplaceRegEx;
			resultReplacing = replaceResultText;
			
			if ([[replaceRegex string] isEqualToString:@""]) {
				[replaceResultText replaceCharactersInRange: NSMakeRange(0,[[replaceResultText textStorage]length]) withString: [textToMatch string]];
			}

			if (findAllState != -1) {													// Switching back from split-tabview
				[[modifierMatrix cellWithTag:0] setEnabled:TRUE];
				[[modifierMatrix cellWithTag:0] setIntValue:findAllState];


				if ([self liveMatching]
					&& ![self matchAborted]) {											// The match was not aborted,
						if (findAllState == 0) {										// and the saved state was not find all.
							[self newMatch];											// Perform a match
						} else {														// No changes in the match;
							[self newReplace];											// only the replacementtexts need updating.
						}
				} else {
					[self runProgressIndicator: FALSE];									// No match needed, so stop the progressindicator.
				}

				findAllState = -1;
			} else if (![self matchAborted] && [self liveMatching]) {					// The match was not aborted:
				[self newReplace];														// only the replacementtexts need updating.
			}

			break;
		case regExSplit:
			[splitRegExModifiersView addSubview: regExModifiersView];					// Show the common view with modifiers.
			[splitInfoView addSubview: infoView];										// Show the common information view.

			if ([[matchRegex string] length] > 0) {										// If there is a current matchregex, show it on this tab.
				[[splitMatchRegEx textStorage] setAttributedString: [matchRegex attributedSubstringFromRange:NSMakeRange(0,[[matchRegex string] length])]];
			} else if (matchRegex) {
				[splitMatchRegEx setString: @""];
			}

			if ([[textToMatch string] length] > 0) {									// If there is a current text to match, show it on this tab.
				[[splitMatchText textStorage] setAttributedString: [textToMatch attributedSubstringFromRange:NSMakeRange(0,[[textToMatch string] length])]];
			} else if (textToMatch) {
				[splitMatchText setString: @""];
			}

			if ((replaceRegex != nil) && [regExResults matchError]) {					// If replaceRegex is not nil, the previous tab was replace.
				performMatch = TRUE;													// If there was an error, it might have been caused by the replacement.
			}																			// Therefore a new match is needed or a valid match may not show.

			// Set the common outlets to the correct ones for this tab.
			matchRegex = splitMatchRegEx;
			textToMatch = splitMatchText;
			replaceRegex = nil;
			resultReplacing = splitResultTableView;

			findAllState = [[modifierMatrix cellWithTag:0] intValue];					// Save the state of the findAll modifier.
			[[modifierMatrix cellWithTag:0] setEnabled:FALSE];							// Disable it.
			[[modifierMatrix cellWithTag:0] setIntValue:1];								// Set it to "find all"
			
			if ([self liveMatching]
				&& ![self matchAborted]													// The match wasn't aborted
				&& (!findAllState || performMatch)) {									// and find all wasn't set for the previous match,
				[self newMatch];														// or a match is need for other reasons.
			} else {
				if ([regExResults matchSucceeded] && [self liveMatching]) {				// If the regex is valid,
					[detailsDrawer close];
					[self regExAborted: FALSE];
					[self regExInvalid: FALSE];
					[infoView displayRect:[regExStatusView frame]];
					[self runProgressIndicator: TRUE];

					// Depending on the fact if live matching is allowed, the match/cancel button should either be enabled or be renamed to cancel.
					if ([self liveMatching]) {
						[toggleMatchingButton setEnabled:TRUE];
					} else {
						[toggleMatchingButton setTitle: NSLocalizedString(@"Cancel", nil)];
					}

					[self setMatchInProgress: TRUE];

					[regExResults splitText: [textToMatch string]						// Use the regex to split the text.
									onRegEx: [matchRegex string]
								  modifiers: [self regExModifiersSet]
								  allowCode: [self allowCode]];
				}
			}
	}	// end case
}

- (BOOL) tabView: (NSTabView *) tabView shouldSelectTabViewItem: (NSTabViewItem *) tabViewItem
// If there is a match is progress, prevent switching.
{
		if ([self matchInProgress]) { NSBeep(); }
	 	return (![self matchInProgress]);
}



#pragma mark-
#pragma mark Outline datasource

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (item == nil) {
		return [regExResults child: index];
	} else {
		return [item child:index];
	}
}
 
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	BOOL showReplacements;

	if (replaceRegex == nil) { 
		showReplacements = FALSE;
	} else {
		showReplacements = TRUE;
	}
	
	if (item == nil) {
		return [regExResults numberOfChildrenShowingReplacements: showReplacements];
	} else {
		return [item numberOfChildrenShowingReplacements: showReplacements];
	}
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	BOOL showReplacements;

	if (replaceRegex == nil) { 
		showReplacements = FALSE;
	} else {
		showReplacements = TRUE;
	}
	if (item == nil) {
		return [regExResults numberOfChildrenShowingReplacements: showReplacements];
	} else {
		return [item numberOfChildrenShowingReplacements: showReplacements];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == nil) {
		return [regExResults displayInOutlineWithSource: [textToMatch string]];
	} else {
		if ([[item displayInOutlineWithSource: [textToMatch string]] isEqualToString:@"\0"]) {	// undefined entry
			return NSLocalizedString(@"undefined", nil);
		} else {
			return [item displayInOutlineWithSource: [textToMatch string]];
		}
	}
}


#pragma mark-
#pragma mark Outline delegate

- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
	if ([item class] == [RegExText class]) {											// Only textType's should be more than 1 line.
		NSTableColumn *tableColumn = [outlineView outlineTableColumn];
		float width = [tableColumn width];
		NSRect rect = NSMakeRect(0,0,width,1000.0);										// Silly big rect, so content will fit.
		NSCell *cell = [tableColumn dataCellForRow:[outlineView rowForItem:item]];
		if ([[item displayInOutlineWithSource: [textToMatch string]] isEqualToString:@"\0"]) {	// undefined entry
			[cell setObjectValue: NSLocalizedString(@"undefined", nil)];
		} else {
			[cell setWraps:TRUE];
			[cell setObjectValue: [item displayInOutlineWithSource: [textToMatch string]]];
		}
		
		if (([[cell stringValue] length] > [self safeWidth]) || ([[cell stringValue]rangeOfString:@"\n"].location != NSNotFound)) {
			float height = [cell cellSizeForBounds:rect].height;
			return height;
		}
	}
	return 17;
}


#pragma mark-
#pragma mark Table datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if ([regExResults matchSucceeded]) {
		return [regExResults numberOfSplits] - 1;
	} else {
		return 0;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([regExResults matchSucceeded] && [regExResults numberOfSplits]) {
		if ([[regExResults splitNumber:rowIndex + 1] isEqualToString:@"\0"]) {
			return NSLocalizedString(@"undefined", nil);
		} else {
			return [regExResults splitNumber:rowIndex + 1];
		}
	} else {
		return 0;
	}
}


#pragma mark-
#pragma mark Table delegate

- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row
{
	NSTableColumn *tableColumn = [tableView tableColumnWithIdentifier:@"splitResultsColumn"];
	float width = [tableColumn width];
	NSRect rect = NSMakeRect(0,0,width,1000.0);
	NSCell *cell = [tableColumn dataCellForRow:row];
	
	[cell setObjectValue: [regExResults splitNumber:row + 1]];
	if ([[regExResults splitNumber:row + 1] isEqualToString:@"\0"]) {
		[cell setFont:UNDEF_FONT];
	} else {
		[cell setWraps:TRUE];
		[cell setFont:TABLE_FONT];

	}
	if (([[regExResults splitNumber:row + 1] length] < [self safeWidth])
		&& ([[regExResults splitNumber:row + 1] rangeOfString:@"\n"].location == NSNotFound)		// String doesn't contain a newline.
		) {				// should be less than one line, adapt to deal with growing window
			return 17;
	} else {
		float height = [cell cellSizeForBounds:rect].height;
		return height;
	}
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell 
		rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
	return [NSString stringWithFormat: NSLocalizedString(@"Part %d", nil),row+1];
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
	[resultReplacing reloadData];
}


@end

#pragma mark-
@implementation NSCountedSet (RegExhibit)

- (int)lowestInt
{
	if ([self count] == 0) { return nil;}
	
	NSEnumerator *enumerator;
	int lowest = nil;
	id itemPointer;
	
	enumerator = [self objectEnumerator];
	while (itemPointer = [enumerator nextObject]) {
		if (lowest == nil) {
			lowest = [itemPointer intValue];
		} else if ([itemPointer intValue] < lowest) {
			lowest = [itemPointer intValue];
		}
	}
	return lowest;
}

- (int) occurencesCount
{
	int count = 0;
	
	NSEnumerator *enumerator;
	id itemPointer;

	enumerator = [self objectEnumerator];
	while (itemPointer = [enumerator nextObject]) {
		count += [self countForObject: itemPointer]; 
	}
	return count;
}
@end

#pragma mark-
@implementation	NSTextView (RegExhibit)

- (void) appendString: (NSString *) aString
{
	int length = [[self textStorage] length];
	[self replaceCharactersInRange: NSMakeRange(length,0) withString: aString];
}
@end




