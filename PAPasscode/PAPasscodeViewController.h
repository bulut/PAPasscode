//
//  PAPasscodeViewController.h
//  PAPasscode
//
//  Created by Denis Hennessy on 15/10/2012.
//  Copyright (c) 2012 Peer Assembly. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PasscodeActionSet,
    PasscodeActionEnter,
    PasscodeActionChange,
    PassCodeActionReceive
} PasscodeAction;

@class PAPasscodeViewController;

@protocol PAPasscodeViewControllerDelegate <NSObject>

@optional

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewControllerDidChangePasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewControllerDidEnterAlternativePasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts;
- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didReceivePasscode:(NSString *)passcode;
- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didSetPasscode:(NSString *)passcode;

@end

@interface PAPasscodeViewController : UIViewController {
    UIView *contentView;
    NSInteger phase;
    UILabel *promptLabel;
    UILabel *messageLabel;
    UIImageView *failedImageView;
    UILabel *failedAttemptsLabel;
    UITextField *passcodeTextField;
    UIImageView *digitImageViews[4];
    UIImageView *snapshotImageView;
    UILabel *clarificationMessageLabel;
}

@property (strong) UIView *backgroundView;
@property (readonly) PasscodeAction action;
@property (weak) id<PAPasscodeViewControllerDelegate> delegate;
@property (strong) NSString *alternativePasscode;
@property (strong) NSString *passcode;
@property (assign) BOOL simple;
@property (assign) NSInteger failedAttempts;
@property (strong) NSString *enterPrompt;
@property (strong) NSString *confirmPrompt;
@property (strong) NSString *changePrompt;
@property (strong) NSString *message;
@property (strong) NSString *moreConfirmPrompt;
@property (strong) NSString *moreEnterPrompt;

- (id)initForAction:(PasscodeAction)action;

@end