//
//  PAPasscodeViewController.m
//  PAPasscode
//
//  Created by Denis Hennessy on 15/10/2012.
//  Copyright (c) 2012 Peer Assembly. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PAPasscodeViewController.h"


#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define IS_RETINA ([[UIScreen mainScreen] scale] == 2.0f)

#define NAVBAR_HEIGHT   0
#define PROMPT_HEIGHT   230
#define NONRETINA_PROMPT_HEIGHT   152
#define PP_PROMPT_HEIGHT 300
#define NONRETINA_PP_PROMPT_HEIGHT   274
#define DIGIT_SPACING   25
#define DIGIT_WIDTH     16
#define DIGIT_HEIGHT    1
#define MARKER_WIDTH    16
#define MARKER_HEIGHT   1
#define MARKER_X        0
#define MARKER_Y        -5
#define MESSAGE_HEIGHT  65
#define FAILED_LCAP     19
#define FAILED_RCAP     19
#define FAILED_HEIGHT   26
#define FAILED_MARGIN   10
#define TEXTFIELD_MARGIN 8
#define SLIDE_DURATION  0.3

@interface PAPasscodeViewController ()
@property  BOOL failedPINSetup;

- (void)cancel:(id)sender;
- (void)handleFailedAttempt;
- (void)handleCompleteField;
- (void)passcodeChanged:(id)sender;
- (void)resetFailedAttempts;
- (void)showFailedAttempts;
- (void)showScreenForPhase:(NSInteger)phase animated:(BOOL)animated;
@end

@implementation PAPasscodeViewController

- (id)initForAction:(PasscodeAction)action {
    self = [super init];
    if (self) {
        _action = action;
        switch (action) {
            case PasscodeActionSet:
                self.title = NSLocalizedString(@"Create a PIN", nil);
                _enterPrompt = NSLocalizedString(@"Create a PIN", nil);
                _confirmPrompt = NSLocalizedString(@"Re-enter your PIN", nil);
                break;
                
            case PassCodeActionReceive:
                self.title = NSLocalizedString(@"Enter your PIN", nil);
                _enterPrompt = NSLocalizedString(@"Enter your PIN", nil);
                break;
                
            case PasscodeActionEnter:
                self.title = NSLocalizedString(@"Enter your PIN", nil);
                _enterPrompt = NSLocalizedString(@"Enter your PIN", nil);
                break;
                
            case PasscodeActionChange:
                self.title = NSLocalizedString(@"Change your PIN", nil);
                _changePrompt = NSLocalizedString(@"Enter your old PIN", nil);
                _enterPrompt = NSLocalizedString(@"Enter your new PIN", nil);
                _confirmPrompt = NSLocalizedString(@"Re-enter your new PIN", nil);
                break;
        }
        self.modalPresentationStyle = UIModalPresentationFormSheet;
        _simple = YES;
    }
    return self;
}

- (void)loadView {
    UIView *view = [[UIView alloc] init];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, NAVBAR_HEIGHT)];
    navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navigationBar.items = @[self.navigationItem];
    [view addSubview:navigationBar];
    
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height)];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    if (_backgroundView) {
        [contentView addSubview:_backgroundView];
    }
    
    contentView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [view addSubview:contentView];
    
    CGFloat panelWidth = DIGIT_WIDTH*4+DIGIT_SPACING*3;
    if (_simple) {
        UIView *digitPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelWidth, DIGIT_HEIGHT)];
        if (IS_IPHONE_5) {
            digitPanel.frame = CGRectOffset(digitPanel.frame, (contentView.bounds.size.width-digitPanel.bounds.size.width)/2, PROMPT_HEIGHT);
        } else {
            digitPanel.frame = CGRectOffset(digitPanel.frame, (contentView.bounds.size.width-digitPanel.bounds.size.width)/2, NONRETINA_PROMPT_HEIGHT);
        }
        digitPanel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [contentView addSubview:digitPanel];
        
        UIImage *backgroundImage = [UIImage imageNamed:@"papasscode_background.png"];
        UIImage *markerImage = [UIImage imageNamed:@"papasscode_marker.png"];
        CGFloat xLeft = 0;
        for (int i=0;i<4;i++) {
            backgroundImageView[i] = [[UIImageView alloc] initWithImage:backgroundImage];
            backgroundImageView[i].frame = CGRectOffset(backgroundImageView[i].frame, xLeft, 0);
            [digitPanel addSubview:backgroundImageView[i]];
            digitImageViews[i] = [[UIImageView alloc] initWithImage:markerImage];
            digitImageViews[i].autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            digitImageViews[i].frame = CGRectOffset(digitImageViews[i].frame, backgroundImageView[i].frame.origin.x+MARKER_X, MARKER_Y);
            [digitPanel addSubview:digitImageViews[i]];
            xLeft += DIGIT_SPACING + backgroundImage.size.width;
        }
        passcodeTextField = [[UITextField alloc] initWithFrame:digitPanel.frame];
        
    } else {
        UIView *passcodePanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, panelWidth, DIGIT_HEIGHT)];
        passcodePanel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        if (IS_IPHONE_5) {
            passcodePanel.frame = CGRectOffset(passcodePanel.frame, (contentView.bounds.size.width-passcodePanel.bounds.size.width)/2, PROMPT_HEIGHT);
        } else {
            passcodePanel.frame = CGRectOffset(passcodePanel.frame, (contentView.bounds.size.width-passcodePanel.bounds.size.width)/2, NONRETINA_PROMPT_HEIGHT);
        }

        passcodePanel.frame = CGRectInset(passcodePanel.frame, TEXTFIELD_MARGIN, TEXTFIELD_MARGIN);
        passcodePanel.layer.borderColor = [UIColor colorWithRed:0.65 green:0.67 blue:0.70 alpha:1.0].CGColor;
        passcodePanel.layer.borderWidth = 1.0;
        passcodePanel.layer.cornerRadius = 5.0;
        passcodePanel.layer.shadowColor = [UIColor whiteColor].CGColor;
        passcodePanel.layer.shadowOffset = CGSizeMake(0, 1);
        passcodePanel.layer.shadowOpacity = 1.0;
        passcodePanel.layer.shadowRadius = 1.0;
        passcodePanel.backgroundColor = [UIColor whiteColor];
        [contentView addSubview:passcodePanel];
        passcodeTextField = [[UITextField alloc] initWithFrame:CGRectInset(passcodePanel.frame, 6, 6)];
    }
    passcodeTextField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    passcodeTextField.borderStyle = UITextBorderStyleNone;
    passcodeTextField.secureTextEntry = YES;
    passcodeTextField.textColor = [UIColor colorWithRed:0.23 green:0.33 blue:0.52 alpha:1.0];
    passcodeTextField.keyboardType = UIKeyboardTypeNumberPad;
    [passcodeTextField addTarget:self action:@selector(passcodeChanged:) forControlEvents:UIControlEventEditingChanged];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    [contentView addSubview:passcodeTextField];
    
    if (IS_IPHONE_5) {
        promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, contentView.bounds.size.width, PP_PROMPT_HEIGHT)];
        clarificationMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 165, 320, 22)];
        
    } else {
        promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, contentView.bounds.size.width, NONRETINA_PP_PROMPT_HEIGHT)];
        clarificationMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 206, 320, 22)];
    }

    clarificationMessageLabel.backgroundColor = [UIColor clearColor];
    clarificationMessageLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15.0];
    clarificationMessageLabel.textColor = [UIColor colorWithRed:54.0/255.0 green:158.0/255.0 blue:189.0/255.0 alpha:1.0];
    promptLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    promptLabel.textColor = [UIColor colorWithRed:54.0/255.0 green:158.0/255.0 blue:189.0/255.0 alpha:1.0];
    promptLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:30];

    promptLabel.textAlignment = NSTextAlignmentCenter;
    clarificationMessageLabel.textAlignment = NSTextAlignmentCenter;
    promptLabel.numberOfLines = 0;
    [contentView addSubview:promptLabel];
    [contentView addSubview:clarificationMessageLabel];

    if (IS_IPHONE_5){
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, PROMPT_HEIGHT+DIGIT_HEIGHT, contentView.bounds.size.width, MESSAGE_HEIGHT)];
    } else {
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, NONRETINA_PROMPT_HEIGHT+DIGIT_HEIGHT, contentView.bounds.size.width, MESSAGE_HEIGHT)];
    }
    messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.textColor = [UIColor colorWithRed:0.30 green:0.34 blue:0.42 alpha:1.0];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.shadowColor = [UIColor whiteColor];
    messageLabel.shadowOffset = CGSizeMake(0, 1);
    messageLabel.textAlignment = NSTextAlignmentCenter;

    messageLabel.numberOfLines = 0;
	messageLabel.text = _message;
    [contentView addSubview:messageLabel];
    
    UIImage *failedBg = [[UIImage imageNamed:@"papasscode_failed_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, FAILED_LCAP, 0, FAILED_RCAP)];
    failedImageView = [[UIImageView alloc] initWithImage:failedBg];
    failedImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    failedImageView.hidden = YES;
    [contentView addSubview:failedImageView];
    
    failedAttemptsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    failedAttemptsLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    failedAttemptsLabel.backgroundColor = [UIColor clearColor];
    failedAttemptsLabel.textColor = [UIColor whiteColor];
    failedAttemptsLabel.font = [UIFont boldSystemFontOfSize:12];
    failedAttemptsLabel.shadowColor = [UIColor blackColor];
    failedAttemptsLabel.shadowOffset = CGSizeMake(0, -1);
    failedAttemptsLabel.textAlignment = NSTextAlignmentCenter;
    failedAttemptsLabel.hidden = YES;
    [contentView addSubview:failedAttemptsLabel];
    
    self.view = view;
}

- (void)showKeyboard:(id)sender {
    [passcodeTextField becomeFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([_delegate respondsToSelector:@selector(PAPasscodeViewControllerDidCancel:)]) {
        if (_simple) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        } else {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        }
    }
    
    if (_failedAttempts > 0) {
        [self showFailedAttempts];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showScreenForPhase:0 animated:NO];
    [passcodeTextField becomeFirstResponder];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void)cancel:(id)sender {
    [_delegate PAPasscodeViewControllerDidCancel:self];
}

#pragma mark - implementation helpers

- (void)handleCompleteField {
    NSString *text = passcodeTextField.text;
   
    switch (_action) {
        case PasscodeActionSet:
            if (phase == 0) {
                _passcode = text;
                messageLabel.text = @"";
                self.failedPINSetup = false;
                [self showScreenForPhase:1 animated:YES];
            } else {
                if ([text isEqualToString:_passcode]) {
                    self.failedPINSetup = false;
                    if ([_delegate respondsToSelector:@selector(PAPasscodeViewController:didSetPasscode:)]) {
                        [_delegate PAPasscodeViewController:self didSetPasscode:text];
                    }
                } else {
                    self.failedPINSetup = true;
                    [self showScreenForPhase:0 animated:YES];
                }
            }
            break;
            
        case PassCodeActionReceive:
            if ([_delegate respondsToSelector:@selector(PAPasscodeViewController:didReceivePasscode:)]) {
                [_delegate PAPasscodeViewController:self didReceivePasscode:text];
            }
            break;
            
        case PasscodeActionEnter:
            if ([text isEqualToString:_passcode]) {
                [self resetFailedAttempts];
                if ([_delegate respondsToSelector:@selector(PAPasscodeViewControllerDidEnterPasscode:)]) {
                    [_delegate PAPasscodeViewControllerDidEnterPasscode:self];
                }
            } else {
                if (_alternativePasscode && [text isEqualToString:_alternativePasscode]) {
                    [self resetFailedAttempts];
                    if ([_delegate respondsToSelector:@selector(PAPasscodeViewControllerDidEnterAlternativePasscode:)]) {
                        [_delegate PAPasscodeViewControllerDidEnterAlternativePasscode:self];
                    }
                } else {
                    [self handleFailedAttempt];
                    [self showScreenForPhase:0 animated:NO];
                }
            }
            break;
            
        case PasscodeActionChange:
            if (phase == 0) {
                if ([text isEqualToString:_passcode]) {
                    [self resetFailedAttempts];
                    [self showScreenForPhase:1 animated:YES];
                } else {
                    [self handleFailedAttempt];
                    [self showScreenForPhase:0 animated:NO];
                }
            } else if (phase == 1) {
                _passcode = text;
                messageLabel.text = @"";
                [self showScreenForPhase:2 animated:YES];
            } else {
                if ([text isEqualToString:_passcode]) {
                    if ([_delegate respondsToSelector:@selector(PAPasscodeViewControllerDidChangePasscode:)]) {
                        [_delegate PAPasscodeViewControllerDidChangePasscode:self];
                    }
                } else {
                    [self showScreenForPhase:1 animated:YES];
                    messageLabel.text = NSLocalizedString(@"PIN did not match. Try again.", nil);
                }
            }
            break;
    }
}

- (void)handleFailedAttempt {
    _failedAttempts++;
    [self showFailedAttempts];
    if ([_delegate respondsToSelector:@selector(PAPasscodeViewController:didFailToEnterPasscode:)]) {
        [_delegate PAPasscodeViewController:self didFailToEnterPasscode:_failedAttempts];
    }
}

- (void)resetFailedAttempts {
    messageLabel.hidden = NO;
    failedImageView.hidden = YES;
    failedAttemptsLabel.hidden = YES;
    _failedAttempts = 0;
}

- (void)showFailedAttempts {
    messageLabel.hidden = YES;
    failedImageView.hidden = NO;
    failedAttemptsLabel.hidden = NO;
    if (_failedAttempts == 1) {
        failedAttemptsLabel.text = NSLocalizedString(@"1 Failed Passcode Attempt", nil);
    } else {
        failedAttemptsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d Failed Passcode Attempts", nil), _failedAttempts];
    }
    [failedAttemptsLabel sizeToFit];
    CGFloat bgWidth = failedAttemptsLabel.bounds.size.width + FAILED_MARGIN*2;
    CGFloat x = floor((contentView.bounds.size.width-bgWidth)/2);
    CGFloat y;
    
    if (IS_IPHONE_5){
         y = PROMPT_HEIGHT+DIGIT_HEIGHT+floor((MESSAGE_HEIGHT-FAILED_HEIGHT)/2);
     } else {
         y = NONRETINA_PROMPT_HEIGHT+DIGIT_HEIGHT+floor((MESSAGE_HEIGHT-FAILED_HEIGHT)/2);
     }
    failedImageView.frame = CGRectMake(x, y, bgWidth, FAILED_HEIGHT);
    x = failedImageView.frame.origin.x+FAILED_MARGIN;
    y = failedImageView.frame.origin.y+floor((failedImageView.bounds.size.height-failedAttemptsLabel.frame.size.height)/2);
    failedAttemptsLabel.frame = CGRectMake(x, y, failedAttemptsLabel.bounds.size.width, failedAttemptsLabel.bounds.size.height);
}

- (void)showFailedPINSetup {
    messageLabel.hidden = YES;
    failedImageView.hidden = NO;
    failedAttemptsLabel.hidden = NO;
    failedAttemptsLabel.text = NSLocalizedString(@"The PIN numbers didn't match. Try again!", nil);
    [failedAttemptsLabel sizeToFit];
    CGFloat bgWidth = failedAttemptsLabel.bounds.size.width + FAILED_MARGIN*2;
    CGFloat x = floor((contentView.bounds.size.width-bgWidth)/2);
    CGFloat y;
    if (IS_IPHONE_5){
         y = PROMPT_HEIGHT+DIGIT_HEIGHT+floor((MESSAGE_HEIGHT-FAILED_HEIGHT)/2);
    } else {
         y = NONRETINA_PROMPT_HEIGHT+DIGIT_HEIGHT+floor((MESSAGE_HEIGHT-FAILED_HEIGHT)/2);
    }
    failedImageView.frame = CGRectMake(x, y, bgWidth, FAILED_HEIGHT);
    x = failedImageView.frame.origin.x+FAILED_MARGIN;
    y = failedImageView.frame.origin.y+floor((failedImageView.bounds.size.height-failedAttemptsLabel.frame.size.height)/2);
    failedAttemptsLabel.frame = CGRectMake(x, y, failedAttemptsLabel.bounds.size.width, failedAttemptsLabel.bounds.size.height);
}

- (void)passcodeChanged:(id)sender {
    NSString *text = passcodeTextField.text;
    
    if (_simple) {
        if ([text length] > 4) {
            text = [text substringToIndex:4];
        }
        for (int i=0;i<4;i++) {
            
            digitImageViews[i].hidden = i >= [text length];
            backgroundImageView[i].hidden = i < [text length];
        }
        if ([text length] == 4) {
            [self handleCompleteField];
        }
    } else {
        self.navigationItem.rightBarButtonItem.enabled = [text length] > 0;
    }
}

- (void)showScreenForPhase:(NSInteger)newPhase animated:(BOOL)animated {
    if (self.failedPINSetup){
        [self showFailedPINSetup];
    } else {
        messageLabel.hidden = NO;
        failedImageView.hidden = YES;
        failedAttemptsLabel.hidden = YES;
    }
    
    CGFloat dir = (newPhase > phase) ? 1 : -1;
    if (animated) {
        UIGraphicsBeginImageContext(self.view.bounds.size);
        [contentView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        snapshotImageView = [[UIImageView alloc] initWithImage:snapshot];
        snapshotImageView.frame = CGRectOffset(snapshotImageView.frame, -contentView.frame.size.width*dir, 0);
        [contentView addSubview:snapshotImageView];
    }
    phase = newPhase;
    passcodeTextField.text = @"";
    if (!_simple) {
        BOOL finalScreen = _action == PasscodeActionSet && phase == 1;
        finalScreen |= _action == PasscodeActionEnter && phase == 0;
        finalScreen |= _action == PasscodeActionChange && phase == 2;
        if (finalScreen) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleCompleteField)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil) style:UIBarButtonItemStylePlain target:self action:@selector(handleCompleteField)];
        }
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    switch (_action) {
        case PasscodeActionSet:
            if (phase == 0) {
                promptLabel.text = _enterPrompt;
                clarificationMessageLabel.text = self.moreEnterPrompt;
            } else {
                promptLabel.text = _confirmPrompt;
                clarificationMessageLabel.text = self.moreConfirmPrompt;
            }
            break;
            
        case PasscodeActionEnter:
            promptLabel.text = _enterPrompt;
            break;
            
        case PassCodeActionReceive:
            promptLabel.text = _enterPrompt;
            break;
            
        case PasscodeActionChange:
            if (phase == 0) {
                promptLabel.text = _changePrompt;
            } else if (phase == 1) {
                promptLabel.text = _enterPrompt;
            } else {
                promptLabel.text = _confirmPrompt;
            }
            break;
    }
    
    for (int i=0;i<4;i++) {
        backgroundImageView[i].hidden = NO;
        digitImageViews[i].hidden = YES;
    }
    
    if (animated) {
        contentView.frame = CGRectOffset(contentView.frame, contentView.frame.size.width*dir, 0);
        [UIView animateWithDuration:SLIDE_DURATION animations:^() {
            self->contentView.frame = CGRectOffset(self->contentView.frame, -self->contentView.frame.size.width*dir, 0);
        } completion:^(BOOL finished) {
            [self->snapshotImageView removeFromSuperview];
            self->snapshotImageView = nil;
        }];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
