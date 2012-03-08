//
//  Controller.h
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RegExRoot.h"
#import "RegExText.h"
#import "RegExhibitLayoutManager.h"

#define MAIN_FONT [NSFont fontWithName:@"Helvetica" size:18.00]
#define TABLE_FONT [NSFont fontWithName:@"Helvetica" size:13.00]
#define UNDEF_FONT [NSFont fontWithName:@"Helvetica-Oblique" size:12.00]

// typedef enum regEx_modifiers in RegExRoot
// typedef enum regEx_uses in RegExRoot

@interface Controller : NSObject
{
	// Tabview of main window.
	IBOutlet NSTabView *tabView;

	// Textviews that contains the match regex in the tabviewitems of the main window.
    IBOutlet NSTextView *findMatchRegEx;
    IBOutlet NSTextView *replaceMatchRegEx;
    IBOutlet NSTextView *splitMatchRegEx;

	// Generalised pointer to the current match regex in the active tabviewitem of the main window. (Also used during switching between tabviewitems.)
	IBOutlet NSTextView *matchRegex;

	// Textview that contains the replacementstring in the tabviewitems of the main window (if any).
    IBOutlet NSTextView *replaceReplaceRegEx;

	// Generalised pointer to the current replacementstring in the active tabviewitem of the main window (if any).
	IBOutlet NSTextView *replaceRegex;

	// Subclassed textviews that show the text the user wants to search with the regex in the tabviewitems of the main window.
    IBOutlet NSTextView *findMatchText;
    IBOutlet NSTextView *replaceMatchText;
    IBOutlet NSTextView *splitMatchText;

	// Generalised pointer to the current text the user wants to search with the regex in the active tabviewitem of the main window.
	IBOutlet id textToMatch;

	// Views that show the result of a replacement or a split.
    IBOutlet NSTextView *replaceResultText;
    IBOutlet NSTableView *splitResultTableView;

	// Generalised pointer to the results of a replacement or a split.
	IBOutlet id resultReplacing;

	// Subviews that show the regex modifiers in regExModifiersView.
	IBOutlet NSView *findRegExModifiersView;
	IBOutlet NSView *replaceRegExModifiersView;
	IBOutlet NSView *splitRegExModifiersView;

	// Subview with the regex modifiers.
	IBOutlet NSView *regExModifiersView;
	IBOutlet NSMatrix *modifierMatrix;
	
	// Subviews that show the information bar at the bottom of the main window (infoView).
	IBOutlet NSView *findInfoView;
	IBOutlet NSView *replaceInfoView;
	IBOutlet NSView *splitInfoView;

	// Subview containing the information bar for the bottom of the main window.
	IBOutlet NSView *infoView;

	// Box displaying the status of the current match, located on the information bar at the bottom of the main window.
	IBOutlet NSView *regExStatusView;
	
	// Boxes shown in the statusview.
	IBOutlet NSView *regExInvalidView;
	IBOutlet NSView *regExAbortedView;
	IBOutlet NSView *regExProgressIndicatorView;

	// Progressindicator in the progressindicatorview.
	IBOutlet NSProgressIndicator *regExProgressIndicator;

	// Button shown in information bar at the bottom of the main window (infoView) to toggle detailsdrawer.
    IBOutlet NSButton *detailsButton;

	// Detailsdrawer and outlineview it contains.
	IBOutlet NSDrawer *detailsDrawer;
	IBOutlet NSOutlineView *detailsOutlineView;

	// Items in the preference window dealing with the way matches etc. are displayed.
	IBOutlet NSColorWell *matchColorWell;
	IBOutlet NSColorWell *captureColorWell;
	IBOutlet NSColorWell *replaceColorWell;
	
	// Pointers to the current colours.
	NSColor *matchColour;
	NSColor *captureColour;
	NSColor *replaceColour;
	
	// Items dealing with how and when matches will happen.
	IBOutlet NSButton *allowCodeCheck;

	// Button to start and stop matching.
	IBOutlet NSButton *toggleMatchingButton;

	// Various variables
	BOOL matchInProgress;								// Set when a match is in progress.
	BOOL matchAborted;									// Set when a match is aborted.
	BOOL interruptMatchInProgress;						// Should the match in progress be interrupted?
	
	BOOL forceMatchDrawing;								// Used to force a complete update of the drawn match.

	int findAllState;									// Used to keep track of the value of the find all modifier when switching to and from split.
	int safeWidth;										// Strings with safeWidth characters will fit on one line if the don't contain a newline.
	int stillToDraw;									// If this variable is 0, no attempts to (re)draw matches is made, as all have been drawn already.
	
	RegExRoot *regExResults;							// Contains the results of the last match.
	
}

#pragma mark-
#pragma mark Starting up and shutting down
- (id) init;
- (BOOL) checkMinimumVersion;
- (void) setFactoryDefaults;
- (void) awakeFromNib;
- (void) dealloc;

#pragma mark-
#pragma mark Accessors
- (void) setInterruptMatchInProgress: (BOOL) aBool;
- (BOOL) interruptMatchInProgress;

- (void) setMatchAborted: (BOOL) aBool;
- (BOOL) matchAborted;

- (void) setMatchInProgress: (BOOL) aBool;
- (BOOL) matchInProgress;

- (void) setSafeWidth: (int) aWidth;
- (int) safeWidth;

// Pseudo accessors
- (IBAction) setAllowCode: (id) sender;
- (BOOL) allowCode;

- (IBAction) setLiveMatching: (id) sender;
- (BOOL) liveMatching;

#pragma mark-
#pragma mark User input
- (void) textDidChange: (NSNotification *) aNotification;						// TextView delegate
- (void) boundsDidChangeNotification: (NSNotification *) aNotification;
- (void) handleColourChange: (NSNotification *) note;
- (IBAction) preferredColoursChanged: (id) sender;
- (IBAction) modifiersChanged: (id) sender;
- (IBAction) toggleMatching: (id) sender;
- (void) alertDidEnd: (NSAlert *) alert											// Called after alert when checking allow code in preferences
		  returnCode: (int) returnCode 
		 contextInfo: (void *) contextInfo;

#pragma mark-
#pragma mark Perform match and show results
- (void) interruptMatch;
- (void) handleInterrupt;
- (void) newMatch;
- (void) newReplace;
- (void) startMatch: (NSNotification *) aNotification;
- (void) startReplace: (NSNotification *) aNotification;
- (void) performMatch;
- (void) performReplace;
- (NSSet *) regExModifiersSet;
- (void) matchFinished: (NSNotification *) note;
- (void) prepareDrawing;
- (void) clearTextToMatch;
- (void) clearReplaceResultText;
- (void) displayMatchResults;
- (void) finishDrawing;

#pragma mark-
#pragma mark Other methods
- (int) firstMatchToDraw: (int) firstVisibleCharacter lowerLimit: (int) lowerLimit upperLimit: (int) upperLimit;

- (void) runProgressIndicator: (BOOL) animateProgressIndicator;
- (void) regExInvalid: (BOOL) regExInvalid;
- (void) regExAborted: (BOOL) regExAborted;

- (IBAction) showDetails: (id) sender;
- (IBAction) switchTab: (id) sender;

@end

@interface NSCountedSet (RegExhibit)
- (int) lowestInt;
- (int) occurencesCount;
@end

@interface NSTextView (RegExhibit)
- (void) appendString: (NSString*) aString;
@end
