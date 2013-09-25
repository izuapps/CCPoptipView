CCPoptipView
============

CCPoptipView is a heavily modified version of Chris Miles's library,
CMPopTipView. It has several new features and improvements, and its
code is substantially cleaned up.

Extra Features:

- Automatically manages a FIFO queue of poptips to present, making the
  presentation of multiple poptips in a row much simpler
- Built-in support for keeping track of which poptips have been presented before, so as to not show them again; just set the -poptipID property on your CCPoptipView, and then later use +poptipHasBeenPresentedWithID: to check if a poptip has been presented in the past with that same ID. The info is stored in a file called PoptipHistory.plist in your app's Documents directory.
- Poptips are now automatically retained and released for you; you don't need to keep a reference to poptips you're displaying
- Removed rarely used "slide" animation option
- Support for iOS 7 parallax effects

Known bugs:

- On iPad, poptips presented from UIBarButtonItems often don't point to the right spot. I'm not sure how to fix this, since CCPoptipView uses a sneaky, undocumented way to get ahold of the view for the bar button item. Don't worry, though; it's App Store-safe. It seems to work fine on iPhone and iPod touch.

URLs
----

 * https://github.com/chrismiles/CMPopTipView
 * http://chrismiles-tech.blogspot.com/2010/12/cmpoptipview-custom-popup-view-for-ios.html
 * http://chrismiles-tech.blogspot.com/2011/05/cmpoptipview-new-animation-option.html

Used in apps:
 * Wikigeek
 * Zadachi
 * *Your app here ...?*


Screenshots
-----------

|iphone_demo_1| |iphone_demo_2| |ipad_demo_1|

.. |iphone_demo_1| image:: http://farm5.static.flickr.com/4005/5191641030_2b93a4a559.jpg
.. |iphone_demo_2| image:: http://farm5.static.flickr.com/4112/5191046667_109a98dfc7.jpg
.. |ipad_demo_1| image:: http://farm6.static.flickr.com/5170/5266199718_4720c56384.jpg


Usage
-----

Example 1 - point at a UIBarButtonItem in a nav bar::

  // Present a CCPoptipView pointing at a UIBarButtonItem in the nav bar
  CCPoptipView *poptip = [[CCPoptipView alloc] initWithMessage:@"A Message"];
  poptip.dismissalBlock = ^(CCPoptipView *poptip) {
    // Any cleanup code, such as releasing a CMPopTipView instance variable, if necessary
  };
  poptip.targetObject = self.navigationItem.leftBarButtonItem;
  [poptop presentAnimated:YES];
  
  // Dismiss a CCPoptipView
  [poptip dismissAnimated:YES];


Example 2 - pointing at a UIButton, with custom color scheme::

  - (IBAction)buttonAction:(id)sender {
    // Toggle popTipView when a standard UIButton is pressed
    if (nil == self.roundRectButtonPopTipView) {
      CCPoptipView *poptip = [[CCPoptipView alloc] initWithMessage:@"My message"];
      poptip.backgroundColor = [UIColor lightGrayColor];
      poptip.targetObject = sender;
      poptip.textColor = [UIColor darkTextColor];
      
      self.roundRectButtonPopTipView = poptip;
      [poptip presentanimated:YES];
    }
    else {
      // Dismiss
      [self.roundRectButtonPopTipView dismissAnimated:YES];
      self.roundRectButtonPopTipView = nil;
    }
  }


Support
-------

CCPoptipView is provided open source with no warranty and no guarantee
of support. However, best effort is made to address issues raised on Github
https://github.com/valsyrie/CCPoptipView/issues .

If you would like assistance with integrating CCPoptipView or modifying
it for your needs, contact the author Colin Chivers <izuapps@gmail.com> for consulting
opportunities.


License
-------

CMPopTipView is Copyright (c) 2010-2013 Chris Miles and released open source
under a MIT license:

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
