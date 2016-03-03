//
//  VideoViewController.m
//  BMLPVideoArchiver
//
//  Created by Justine Kay on 10/26/15.
//  Copyright © 2015 Justine Kay. All rights reserved.

#import <MobileCoreServices/MobileCoreServices.h>
#import "VideoViewController.h"
#import "LogInViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

static NSString *const kKeychainItemName = @"BMLP Video Archiver";
static NSString *const kClientID = @"749579524688-b1oaiu8cc4obq06aal4org55qie5lho2.apps.googleusercontent.com";
static NSString *const kClientSecret = @"0U67OQ3UNhX72tmba7ZhMSYK";

@interface VideoViewController ()

{
    BOOL isAuthorized;
}

- (void)createCamera;
- (void)startRecording;
- (void)stopRecording;

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@property (nonatomic, retain) GTLServiceDrive *driveService;
@property (nonatomic) CustomCameraOverlayView *customCameraOverlayView;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger timeInSeconds;

@end

@implementation VideoViewController

@synthesize driveService;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    [self createCamera];
    
    self.timeInSeconds = 0;
    
    // Initialize the drive service & load existing credentials from the keychain if available
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                         clientID:kClientID
                                                                                     clientSecret:kClientSecret];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    
    if (![self isAuthorized]) {
        
        // Not yet authorized, request authorization and push the login UI onto the navigation stack.
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[self createAuthController]];
        navigationController.navigationBarHidden = YES;
        [self presentViewController:navigationController animated:YES completion:nil];

        //[self presentViewController:[self createAuthController] animated:YES completion:nil];
        
    }else {
        
        [self presentViewController:camera animated:animated completion:nil];
    }
}

-(void)customCameraOverlay
{
    CameraOverlayViewController *overlayVC = [[CameraOverlayViewController alloc] initWithNibName:@"CameraOverlayViewController" bundle:nil];
    self.customCameraOverlayView = (CustomCameraOverlayView *)overlayVC.view;
    
    self.customCameraOverlayView.delegate = self;
    
    self.customCameraOverlayView.cameraSelectionButton.alpha = 0.0;
    self.customCameraOverlayView.flashModeButton.alpha = 0.0;
    self.customCameraOverlayView.recordIndicatorView.alpha = 0.0;
    self.customCameraOverlayView.uploadingLabel.alpha = 0.0;
    self.customCameraOverlayView.fileSavedLabel.alpha = 0.0;
    self.customCameraOverlayView.backgroundColor = [UIColor clearColor];
    
    self.customCameraOverlayView.frame = camera.view.frame;
    
    recordGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginVideoRecording)];
    recordGestureRecognizer.numberOfTapsRequired = 2;
    
    [self.customCameraOverlayView addGestureRecognizer:recordGestureRecognizer];
    
}

- (void)createCamera
{
    camera = [[UIImagePickerController alloc] init];
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    camera.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    camera.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    camera.showsCameraControls = NO;
    camera.cameraViewTransform = CGAffineTransformIdentity;
    
    //create custom overlay and apply to camera
    [self customCameraOverlay];
    camera.cameraOverlayView = self.customCameraOverlayView;
    
    // not all devices have two cameras or a flash so just check here
    if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceRear] ) {
        
        camera.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        
        if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront] ) {
            
            [self.customCameraOverlayView.cameraSelectionButton setImage:[UIImage imageNamed:@"camera-toggle"] forState:UIControlStateNormal];
            self.customCameraOverlayView.cameraSelectionButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
            self.customCameraOverlayView.cameraSelectionButton.alpha = 1.0;
            showCameraSelection = YES;
        }
        
    } else {
        
        camera.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    }
    
    
    if ( [UIImagePickerController isFlashAvailableForCameraDevice:camera.cameraDevice] ) {
        
        camera.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [self.customCameraOverlayView.flashModeButton setImage:[UIImage imageNamed:@"flash-off.png"] forState:UIControlStateNormal];
        self.customCameraOverlayView.flashModeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.customCameraOverlayView.flashModeButton.alpha = 1.0;
        showFlashMode = YES;
    
    }
    
    
    camera.videoQuality = UIImagePickerControllerQualityType640x480;
    
    camera.delegate = self;
    camera.edgesForExtendedLayout = UIRectEdgeAll;
    
    
}

- (void)beginVideoRecording
{
    if (!recording) {
        
        sessionInProgress = YES;
        
        [self startRecording];
        
        NSLog(@"recording started");
    
    }
}

#pragma mark - Video Recording Timer

-(void)startVideoRecordingTimer
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.timer = timer;
    
}

-(void)fireTimer: (NSTimer *) timer
{
    self.timeInSeconds += 1;
    
    if (self.timeInSeconds == 30) {
        
        [self stopRecording];
    }
    
    NSLog(@"Timer Fired, time in seconds: %ld", (long)self.timeInSeconds);
}

-(void)resetTimer
{
    if (self.timer){
        
        [self.timer invalidate];
        
        self.timeInSeconds = 0;
    }
}


#pragma mark - ShakeGesture

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        if (recording) {
            
            sessionInProgress = NO;
            
            [self stopRecording];
            
            NSLog(@"session ended");
            
        }
    }
}

#pragma Mark - CustomCameraOverlayDelegate methods

-(void)didSignOut
{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:SignedInKey];
    
    UINavigationController *navigationController = self.navigationController;
    
    //Get all view controllers in navigation controller currently
    NSMutableArray *controllers=[[NSMutableArray alloc] initWithArray:navigationController.viewControllers] ;
    
    //Remove the last view controller
    [controllers removeLastObject];
    
    //set the new set of view controllers
    [navigationController setViewControllers:controllers];
    
    [camera dismissViewControllerAnimated:NO completion:^{
        
        [navigationController popToRootViewControllerAnimated:NO];
        
    }];

}

- (void)didChangeFlashMode
{
    if (camera.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        
        camera.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        [self.customCameraOverlayView.flashModeButton setImage:[UIImage imageNamed:@"flash-on.png"] forState:UIControlStateNormal];
    
    } else {
        
        camera.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [self.customCameraOverlayView.flashModeButton setImage:[UIImage imageNamed:@"flash-off.png"] forState:UIControlStateNormal];
    
    }
}

- (void)didChangeCamera
{
    if (camera.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        
        camera.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    } else {
        
        camera.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    
    if ( ![UIImagePickerController isFlashAvailableForCameraDevice:camera.cameraDevice] ) {
        
        [UIView animateWithDuration:0.3 animations:^(void) {self.customCameraOverlayView.flashModeButton.alpha = 0;}];
        showFlashMode = NO;
    
    } else {
        
        [UIView animateWithDuration:0.3 animations:^(void) {self.customCameraOverlayView.flashModeButton.alpha = 1.0;}];
        showFlashMode = YES;
    
    }
}


#pragma mark - UIImagePickerController camera and delegate methods

- (void)startRecording
{
    void (^hideControls)(void);
    hideControls = ^(void) {
        self.customCameraOverlayView.cameraSelectionButton.alpha = 0;
        self.customCameraOverlayView.flashModeButton.alpha = 0;
        self.customCameraOverlayView.recordIndicatorView.alpha = 1.0;
    };
    
    void (^recordMovie)(BOOL finished);
    recordMovie = ^(BOOL finished) {
        
        recording = YES;
        [camera startVideoCapture];
        [self startVideoRecordingTimer];
    };
    
    // Hide controls
    [UIView  animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:hideControls completion:recordMovie];
}

- (void)stopRecording
{
    [self resetTimer];
    
    recording = NO;
    
    [camera stopVideoCapture];
    
    NSLog(@"recording stopped");
}


// Handle selection of an image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        NSString *videoPath = [videoUrl path];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (videoPath)) {
            
            //save to Google Drive
            [self uploadVideo:videoPath];
            
            //save to photo album
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
            
        } else {
            
            [self video:videoPath didFinishSavingWithError:nil contextInfo:NULL];
        }
    
    }
    
    if (sessionInProgress) {
        
        recording = YES;
        [camera startVideoCapture];
        [self startVideoRecordingTimer];
        
        NSLog(@"recording continued...");
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
   if (!sessionInProgress) {
        
    void (^showControls)(void);
    showControls = ^(void) {
        if (showCameraSelection) self.customCameraOverlayView.cameraSelectionButton.alpha = 1.0;
        if (showFlashMode) self.customCameraOverlayView.flashModeButton.alpha = 1.0;
        self.customCameraOverlayView.recordIndicatorView.alpha = 0.0;
        
    };
    
    // Show controls
    [UIView  animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:showControls completion:NULL];
        
    }
    
}

// Handle cancel from image picker/camera.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma Mark - Google Drive Authorization and Uploading methods

// Helper to check if user is authorized
- (BOOL)isAuthorized
{
    
    BOOL auth = [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];
    
    if (auth == YES) {
        
        //Set Bool for presenting LogInVC
        [[NSUserDefaults standardUserDefaults] setBool:auth forKey:SignedInKey];

    }
    
    return auth;
}

// Creates the auth controller for authorizing access to Google Drive.
- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    return authController;
}

// Handle completion of the authorization process, and updates the Drive service
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error
{
    if (error != nil)
    {
        NSString *errorMessage = [NSString stringWithFormat:@"Authentication Error: %@", error];
        NSLog( @"%@", errorMessage);
        //[self fadeInFadeOutInfoLabel:self.customCameraOverlayView.uploadingLabel WithMessage:errorMessage];
        self.driveService.authorizer = nil;
    }
    else
    {
        [self.parentViewController dismissViewControllerAnimated:NO completion:nil];
        [viewController removeFromParentViewController];
        
        self.driveService.authorizer = authResult;
        


    }
}

// Upload video to Google Drive
- (void)uploadVideo:(NSString *)videoURLPath
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"BMLP Video Archiver Uploaded File ('EEEE MMMM d, YYYY h:mm a, zzz')"];
    
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = [dateFormat stringFromDate:[NSDate date]];
    file.descriptionProperty = @"Uploaded from BMLP Video Archiver";
    file.mimeType = @"video/quicktime";
    
    NSError *error = nil;
    
    NSData *data = [NSData dataWithContentsOfFile:videoURLPath options:NSDataReadingMappedIfSafe error:&error];
    
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:file.mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                       uploadParameters:uploadParameters];
    
    
    //create animation
    CABasicAnimation *animation = [self animateOpacity];
    
    //animation will start immediately
    [self.customCameraOverlayView.uploadingLabel.layer addAnimation:animation forKey:@"animateOpacity"];
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFile *insertedFile, NSError *error) {
                      
                      
                      if (error == nil)
                      {
                          NSLog(@"File ID: %@", insertedFile.identifier);
                          
                          [self.customCameraOverlayView.uploadingLabel.layer removeAllAnimations];
                          self.customCameraOverlayView.uploadingLabel.alpha = 0.0;
                          
                          [self fadeInFadeOutInfoLabel:self.customCameraOverlayView.fileSavedLabel WithMessage:@"File Saved"];
                          
                          
                      }
                      else
                      {
                          NSLog(@"An error occurred: %@", error);
                          
                          [self.customCameraOverlayView.uploadingLabel.layer removeAllAnimations];
                          self.customCameraOverlayView.uploadingLabel.alpha = 0.0;
                          
                          [self fadeInFadeOutInfoLabel:self.customCameraOverlayView.fileSavedLabel WithMessage:@"Sorry an error occurred."];
                          
                      }
                  }];
}


// Helper for showing Info Label

-(void)fadeInFadeOutInfoLabel:(UILabel *)label WithMessage: (NSString *) message{

    
    label.text = message;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];

    //fade in
    [UIView animateWithDuration:0.5f animations:^{

        [label setAlpha:1.0f];

    } completion:^(BOOL finished) {

        //fade out
        [UIView animateWithDuration:5.0f animations:^{

            [label setAlpha:0.0f];

        } completion:nil];

    }];
}

-(CABasicAnimation *)animateOpacity
{
    //Create an animation with pulsating effect
    CABasicAnimation *theAnimation;
    
    //within the animation we will adjust the "opacity"
    //value of the layer
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    
    //animation lasts 0.7 seconds
    theAnimation.duration=0.7;
    
    //and it repeats forever
    theAnimation.repeatCount= HUGE_VALF;
    
    //we want a reverse animation
    theAnimation.autoreverses=YES;
    
    //justify the opacity as you like (1=fully visible, 0=unvisible)
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.1];
    
    return theAnimation;
    
}


@end
