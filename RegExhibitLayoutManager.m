//
//  RegExhibitLayoutManager.m
//  RegExhibit
//
//  Copyright 2007 Roger Jolly. All rights reserved.
//
// NSLayoutManager doesn't underline leading and trailing whitespace. It makes this decision in this function. By overriding it and always calling the
// drawUnderlineForGlyphRange method, this subclass will underline leading and trailing whitespace.
//

#import "RegExhibitLayoutManager.h"

@implementation RegExhibitLayoutManager

- (void) underlineGlyphRange: (NSRange) glyphRange 
			   underlineType: (int) underlineType 
			lineFragmentRect: (NSRect) lineRect 
	  lineFragmentGlyphRange: (NSRange) lineGlyphRange 
			 containerOrigin: (NSPoint) containerOrigin
{
// The baseline offset of an underline seems to be roughly -1.0 * (descenderposition - leading) rounded to the nearest integer.
// This is "highly empirical" :-) and not quite precise, but it will do for now.

	float leading = [[[self attributedString]attribute:NSFontAttributeName atIndex:0 longestEffectiveRange:NULL inRange:glyphRange]leading];
	float descender = [[[self attributedString]attribute:NSFontAttributeName atIndex:0 longestEffectiveRange:NULL inRange:glyphRange]descender];

	float theOffset = (int) (-1.0 * (descender - leading) + 0.5);

	[self drawUnderlineForGlyphRange: glyphRange
					   underlineType: underlineType 
					  baselineOffset: theOffset
					lineFragmentRect: lineRect 
			  lineFragmentGlyphRange: lineGlyphRange 
					 containerOrigin: containerOrigin];
}

@end
