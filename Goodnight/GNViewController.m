//
//  GNViewController.m
//  Goodnight
//
//  Created by Matt Zanchelli on 5/4/12.
//  Copyright (c) 2012 Matt Zanchelli. All rights reserved.
//

#import "GNViewController.h"
#import "MTZOutlinedButton.h"
#import "MTZTriangleView.h"
#import "GNInfoViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface GNViewController ()

#pragma mark Private Property

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIImageView *sky;
@property (strong, nonatomic) IBOutlet UIImageView *stars;
@property (strong, nonatomic) IBOutlet UIImageView *dusk;
@property (strong, nonatomic) IBOutlet UIImageView *sunrise;

@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) UIView *info;

@property (strong, nonatomic) IBOutlet UILabel *instructions;

@property (strong, nonatomic) IBOutlet UIButton *sleepButton;
@property (strong, nonatomic) IBOutlet UIButton *wakeButton;

@property (strong, nonatomic) IBOutlet MTZTriangleView *triangleMarker;

@property (strong, nonatomic) IBOutlet UIView *selectorView;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet MTZOutlinedButton *goodnightButton;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) UILabel *timeBad;
@property (strong, nonatomic) UILabel *timeFine;
@property (strong, nonatomic) UILabel *timeGood;
@property (strong, nonatomic) UILabel *timeGreat;

@property (nonatomic) BOOL hasUsedAppBefore;

@property (strong, nonatomic) NSDate *dateToResumeAnimatingInstructions;

@property (nonatomic) CGFloat yChange;

@end

#define ANIMATION_DURATION 0.75f

#define NUMBER_OF_CARDS 4

#define BAD_OPACITY   0.7f
#define FINE_OPACITY  0.8f
#define GOOD_OPACITY  0.9f
#define GREAT_OPACITY 1.0f

#define FALL_ASLEEP_TIME (14*60)
#define SLEEP_CYCLE_TIME (90*60)
#define BAD_SLEEP_TIME   (FALL_ASLEEP_TIME+(3*SLEEP_CYCLE_TIME))
#define FINE_SLEEP_TIME  (FALL_ASLEEP_TIME+(4*SLEEP_CYCLE_TIME))
#define GOOD_SLEEP_TIME  (FALL_ASLEEP_TIME+(5*SLEEP_CYCLE_TIME))
#define GREAT_SLEEP_TIME (FALL_ASLEEP_TIME+(6*SLEEP_CYCLE_TIME))

@implementation GNViewController


#pragma mark Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	// Find necessary y change to hide main UI
	_yChange = self.view.frame.size.height - _wakeButton.frame.origin.y;
	
	// Make sure sky imageView is tall enough
	_sky.frame = (CGRect){_sky.frame.origin.x, _sky.frame.origin.y, _sky.image.size.width, _sky.image.size.height};
	
	// Setup background motion effects
	UIInterpolatingMotionEffect *horizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
	horizontal.minimumRelativeValue = @(20);
	horizontal.maximumRelativeValue = @(-20);
	UIInterpolatingMotionEffect *vertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	vertical.minimumRelativeValue = @(20);
	vertical.maximumRelativeValue = @(-20);
	_stars.motionEffects = @[horizontal, vertical];
	_sunrise.motionEffects = @[vertical];
	_dusk.motionEffects = @[vertical];
	
	// Add goodnight button action
	[_goodnightButton addTarget:self
						 action:@selector(tappedGoodnightButton:)
			   forControlEvents:UIControlEventTouchUpInside];
	
	// Add Info button action
	[_infoButton addTarget:self
					action:@selector(tappedInfoButton:)
		  forControlEvents:UIControlEventTouchUpInside];
	
	// Autoresize top and bottom views
	_selectorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// Add targets to buttons for events
	[_sleepButton addTarget:self
					 action:@selector(tappedSleepButton:)
		   forControlEvents:UIControlEventTouchUpInside];
	[_wakeButton addTarget:self
					action:@selector(tappedWakeButton:)
		  forControlEvents:UIControlEventTouchUpInside];
	
	// Picker actions
	[_datePicker addTarget:self
					action:@selector(sleepPickerDidChange:)
		  forControlEvents:UIControlEventValueChanged];
	
	// Setup formatter
	_dateFormatter = [[NSDateFormatter alloc] init];
	_dateFormatter.dateFormat = @"h:mm a";
	
	// Setup times
#warning frames for times?
	_timeBad   = [[UILabel alloc] init];
	_timeFine  = [[UILabel alloc] init];
	_timeGood  = [[UILabel alloc] init];
	_timeGreat = [[UILabel alloc] init];
	
	// Update times
	[self updateTimes];
	
#warning store last used mode in preferences and use below
	[self setMode:GNViewControllerModeSetSleepTime];
	
#warning see if the app has been used
	_hasUsedAppBefore = NO;
	if ( !_hasUsedAppBefore ) {
		[UIView animateWithDuration:2 * ANIMATION_DURATION
							  delay:2 * ANIMATION_DURATION
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 _instructions.alpha = 0.7;
						 }
						 completion:^(BOOL finished) {}];
	}
	
	// Setup instructions
	_info = [[GNInfoViewController alloc] initWithNibName:@"GNInfoViewController"
													 bundle:nil].view;
	_info.alpha = 0.0f;
	[_scrollView insertSubview:_info belowSubview:_infoButton];
}


#pragma mark Button Actions

#warning able to tap two buttons near simultaneously
- (IBAction)tappedSleepButton:(id)sender
{
	[self setMode:GNViewControllerModeSetSleepTime];
	
	// Have to do this since UIDatePicker doesn't perform action for UIControlEventValueChanged when using setDate:Animated:
	[self updateTimes];
}

- (IBAction)tappedWakeButton:(id)sender
{
	[self setMode:GNViewControllerModeSetWakeTime];
	
	// Have to do this since UIDatePicker doesn't perform action for UIControlEventValueChanged when using setDate:Animated:
	[self updateTimes];
}

- (void)tappedGoodnightButton:(id)sender
{
#warning animate and show times
	NSLog(@"tappedGoodnightButton: %@", sender);
}

- (void)tappedInfoButton:(id)sender
{
	_infoButton.selected = !_infoButton.selected;
	
	if ( _infoButton.selected ) {
		[self showInfo];
	} else {
		[self hideInfo];
	}
}

- (void)showInfo
{
	[UIView animateWithDuration:ANIMATION_DURATION/2
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 _instructions.alpha = 0.0f;
					 }
					 completion:^(BOOL finished) {
						 _instructions.hidden = YES;
					 }];
	
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
//						 _stars.alpha = 0.33f;
						 
						 _sleepButton.frame = CGRectOffset(_sleepButton.frame, 0, _yChange);
						 _wakeButton.frame = CGRectOffset(_wakeButton.frame, 0, _yChange);
						 _triangleMarker.frame = CGRectOffset(_triangleMarker.frame, 0, _yChange);
						 _selectorView.frame = CGRectOffset(_selectorView.frame, 0, _yChange);
						 _dusk.frame = CGRectOffset(_dusk.frame, 0, _yChange);
						 _sunrise.frame = CGRectOffset(_sunrise.frame, 0, _yChange);
					 }
					 completion:^(BOOL finished) {}];
	
	// Show Info text
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 _info.alpha = 1.0f;
					 }
					 completion:^(BOOL finished) {}];
}

- (void)hideInfo
{
	// make sure it's at alpha 0.0f?
	_instructions.alpha = 0.0f;
	_instructions.hidden = NO;
	
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 _info.alpha = 0.0f;
					 }
					 completion:^(BOOL finished) {
						 if ( !_hasUsedAppBefore ) {
							 [UIView animateWithDuration:ANIMATION_DURATION*2
												   delay:0.0f
								  usingSpringWithDamping:1.0f
								   initialSpringVelocity:1.0f
												 options:UIViewAnimationOptionBeginFromCurrentState
											  animations:^{
												  _instructions.alpha = 0.7f;
											  }
											  completion:^(BOOL finished) {}];
						 }
					 }];
	
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
//						 _stars.alpha = 1.0f;
						 
						 _sleepButton.frame = CGRectOffset(_sleepButton.frame, 0, -_yChange);
						 _wakeButton.frame = CGRectOffset(_wakeButton.frame, 0, -_yChange);
						 _triangleMarker.frame = CGRectOffset(_triangleMarker.frame, 0, -_yChange);
						 _selectorView.frame = CGRectOffset(_selectorView.frame, 0, -_yChange);
						 _dusk.frame = CGRectOffset(_dusk.frame, 0, -_yChange);
						 _sunrise.frame = CGRectOffset(_sunrise.frame, 0, -_yChange);
					 }
					 completion:^(BOOL finished) { }];
}


#pragma mark Modes

- (void)setMode:(GNViewControllerMode)mode
{
	// Only manipulate instructions if necessary
	if ( _mode != mode && !_hasUsedAppBefore ) {
		[self fadeInstructionsOut];
	}
	
	_mode = mode;
	switch (mode) {
		case GNViewControllerModeSetSleepTime:
			[self sleepMode];
			break;
		case GNViewControllerModeSetWakeTime:
			[self wakeMode];
			break;
	}
		
}

- (void)sleepMode
{
	// Select Sleep segmented control button
	// Hide sunrise
	// Bring in stars
	// Move triangle
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
#warning UIButton does not animate between selected states
						 _sleepButton.selected = YES;
						 _wakeButton.selected = NO;
						 
						 _sunrise.alpha = 0.0f; // Animate down, too
						 
						 _stars.center = (CGPoint){_stars.center.x, _stars.center.y + 50.0f};
						 _stars.alpha = 1.0f;
						 
						 _triangleMarker.center = (CGPoint){_sleepButton.center.x, _triangleMarker.center.y};
					 }
					 completion:^(BOOL finished) {}];
	
	// Animate sky
	// Bring up dusk
	// Change goodnight button tint color
	[UIView animateWithDuration:ANIMATION_DURATION * 3
						  delay:0.0f
		 usingSpringWithDamping:10.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 CGPoint skyStart = (CGPoint){self.view.frame.size.width/2, -20+(_sky.image.size.height/2)};
						 _sky.center = skyStart;
						 _dusk.alpha = 1.0f;	// Animate up, too
						 
						 UIColor *color = [UIColor colorWithRed:157.0f/255.0f
														  green: 75.0f/255.0f
														   blue:212.0f/255.0f
														  alpha:1.0f];
						 [_goodnightButton setTintColor:color];
					 }
					 completion:^(BOOL finished) { }];
}

- (void)wakeMode
{
	// Select Sleep segmented control button
	// Hide sunrise
	// Bring in stars
	// Move triangle
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
		 usingSpringWithDamping:1.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
#warning UIButton does not animate between selected states
						 _wakeButton.selected = YES;
						 _sleepButton.selected = NO;
						 
						 _dusk.alpha = 0.0f;	// Animate down, too
						 
						 _stars.center = (CGPoint){_stars.center.x, _stars.center.y - 50.0f};
						 _stars.alpha = 0.0f;
						 
						 _triangleMarker.center = (CGPoint){_wakeButton.center.x, _triangleMarker.center.y};
					 }
					 completion:^(BOOL finished) {}];
	
	// Animate sky
	// Bring up dusk
	// Change goodnight button tint color
	[UIView animateWithDuration:ANIMATION_DURATION * 3
						  delay:0.0f
		 usingSpringWithDamping:10.0f
		  initialSpringVelocity:1.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 CGPoint skyEnd = (CGPoint){self.view.frame.size.width/2, 20+self.view.bounds.size.height-(_sky.image.size.height/2)};
						 _sky.center = skyEnd;
						 _sunrise.alpha = 0.5f; // Animate up, too
						 
						 UIColor *color = [UIColor colorWithRed: 69.0f/255.0f
														  green:172.0f/255.0f
														   blue:245.0f/255.0f
														  alpha:1.0f];
						 [_goodnightButton setTintColor:color];
					 }
					 completion:^(BOOL finished) { }];
}

- (void)fadeInstructionsOut
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(fadeInstructionsIn)
											   object:nil];
	
	[UIView animateWithDuration:ANIMATION_DURATION
						  delay:0.0f
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 _instructions.alpha = 0.0f;
					 }
					 completion:^(BOOL finished) {}];
	
	[self performSelector:@selector(fadeInstructionsIn) withObject:nil afterDelay:ANIMATION_DURATION];
}

- (void)fadeInstructionsIn
{
	#warning get localized string
	if ( _mode == GNViewControllerModeSetWakeTime ) {
		_instructions.text = @"Set the time you’d\nlike to wake up at";
	} else {
		_instructions.text = @"Set the time you’d\nlike to fall asleep at";
	}
	
	[UIView animateWithDuration:2 * ANIMATION_DURATION
						  delay:2 * ANIMATION_DURATION
						options:UIViewAnimationOptionBeginFromCurrentState
					 animations:^{
						 _instructions.alpha = 0.75f;
					 }
					 completion:^(BOOL finished) {}];
}


#pragma mark Picker actions

- (void)sleepPickerDidChange:(id)sender
{
	[self updateTimes];
}

- (void)updateTimes
{
	NSDate *date = _datePicker.date;
	_timeBad.text   = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:BAD_SLEEP_TIME]];
	_timeFine.text  = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:FINE_SLEEP_TIME]];
	_timeGood.text  = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:GOOD_SLEEP_TIME]];
	_timeGreat.text = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:GREAT_SLEEP_TIME]];
}


- (void)wakePickerDidChange:(id)sender
{
	[self updateSleepCardTimes];
}

- (void)updateSleepCardTimes
{
	NSDate *date = _datePicker.date;
	_timeBad.text   = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:-BAD_SLEEP_TIME]];
	_timeFine.text  = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:-FINE_SLEEP_TIME]];
	_timeGood.text  = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:-GOOD_SLEEP_TIME]];
	_timeGreat.text = [_dateFormatter stringFromDate:[date dateByAddingTimeInterval:-GREAT_SLEEP_TIME]];
}


#pragma mark UIViewController Stuff

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}


@end
