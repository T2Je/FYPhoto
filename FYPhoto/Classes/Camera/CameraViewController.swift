//
//  CameraViewController.swift
//  FYPhoto
//
//  Created by xiaoyang on 2020/9/24.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices

public struct WatermarkImage {
    let image: UIImage
    let frame: CGRect
    
    public init(image: UIImage, frame: CGRect) {
        self.image = image
        self.frame = frame
    }
}

public protocol CameraViewControllerDelegate: class {
    func camera(_ cameraViewController: CameraViewController, didFinishCapturingMediaInfo info: [CameraViewController.InfoKey: Any])
    func cameraDidCancel(_ cameraViewController: CameraViewController)
    func watermarkImage() -> WatermarkImage?
    func cameraViewControllerStartAddingWatermark(_ cameraViewController: CameraViewController)
    func camera(_ cameraViewController: CameraViewController, didFinishAddingWatermarkAt path: URL)
}

public extension CameraViewControllerDelegate {
    func watermarkImage() -> WatermarkImage? {
        return nil
    }
    func cameraViewControllerStartAddingWatermark(_ cameraViewController: CameraViewController) {}
    func camera(_ cameraViewController: CameraViewController, didFinishAddingWatermarkAt path: URL) {}
}

public class CameraViewController: UIViewController {
    public weak var delegate: CameraViewControllerDelegate?

    /// capture mode. Default is image.
    public var captureMode: MediaOptions = .image
    
    public var cameraOverlayView: VideoCaptureOverlay!
    public var moviePathExtension = "mov"
    /// maximum video capture duration. Default 15s
    public var videoMaximumDuration: TimeInterval = 15

    var previewView = VideoPreviewView()

    // Session
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    fileprivate let session = AVCaptureSession()
    private var isSessionRunning = false
    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "com.fyphoto.camera.sessionQueue")
    private var setupResult: SessionSetupResult = .success
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

    // Photos
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    // Devices
    private var videoDeviceDiscoverySession: AVCaptureDevice.DiscoverySession?
    /// the current flash mode
    private var flashMode: AVCaptureDevice.FlashMode = .auto

    // Movie
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    var windowOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return view.window?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }

    public var captureDeviceIsAvailable: Bool {
        videoDeviceInput != nil
    }

    private let tintColor: UIColor
    
    public init(tintColor: UIColor = .systemBlue) {
        self.tintColor = tintColor
        super.init(nibName: nil, bundle: nil)
        initVideoDeviceDiscoverySession()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        cameraOverlayView = VideoCaptureOverlay(videoMaximumDuration: videoMaximumDuration, tintColor: tintColor)

        view.addSubview(previewView)
        view.addSubview(cameraOverlayView)
        makeConstraints()

        cameraOverlayView.captureMode = captureMode
        cameraOverlayView.delegate = self

        previewView.session = session
        
        // there is no need to request microphone authorization when only taking photos
        handleVideoAuthority(for: captureMode)
        
        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.

         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
    }

    public override var shouldAutorotate: Bool {
        // Disable autorotation of the interface when recording is in progress.
        if let movieFileOutput = movieFileOutput {
            return !movieFileOutput.isRecording
        }
        return true
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning

            case .notAuthorized:
                DispatchQueue.main.async {
                    self.alertNotAuthorized()
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.alertCameraConfigurationFailed()
                }
            }
            
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        // FIXME: Crashed when switch camera!
        //                self.session.commitConfiguration()
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }

        super.viewWillDisappear(animated)
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }

            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    func makeConstraints() {
        let safeArea = self.view.safeAreaLayoutGuide
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        cameraOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraOverlayView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            cameraOverlayView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            cameraOverlayView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            cameraOverlayView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    func alertNotAuthorized() {
        let bundleDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? ""
        let changePrivacySetting = "\(bundleDisplayName as? String) \(L10n.withoutCameraPermission)"
        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
        let alertController = UIAlertController(title: "\(bundleDisplayName)", message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString(L10n.ok, comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString(L10n.settings, comment: "Alert button to open Settings"),
                                                style: .`default`,
                                                handler: { _ in
                                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                                              options: [:],
                                                                              completionHandler: nil)
                                                }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func alertCameraConfigurationFailed() {
        let alertMsg = "Alert message when something goes wrong during capture session configuration"
        let message = NSLocalizedString(L10n.cameraConfigurationFailed, comment: alertMsg)
        let alertController = UIAlertController(title: L10n.camera, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString(L10n.ok, comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    /*
     Check the video authorization status. Video access is required and audio
     access is optional. If the user denies audio access, FYphoto won't
     record audio during movie recording. If Mode is image, set result to success.
     */
    fileprivate func handleVideoAuthority(for mode: MediaOptions) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            setupResult = .success
        case .notDetermined:
            if mode == .image {
                setupResult = .success
            } else {
                /*
                 The user has not yet been presented with the option to grant
                 video access. Suspend the session queue to delay session
                 setup until the access request has completed.
                 
                 Note that audio access will be implicitly requested when we
                 create an AVCaptureDeviceInput for audio during session setup.
                 */
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
            }
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
                
    }
    
    // MARK: Session Management

    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        guard setupResult == .success else {
            return
        }
        session.beginConfiguration()

        /*
         Do not create an AVCaptureMovieFileOutput when setting up the session because
         Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
         */
        session.sessionPreset = .high
        
        // Input
        addDeviceInput()
        if captureMode.contains(.video) {
            addAudioInput()
        }
        
        // Output
        addPhotoOutput()
        addMovieOutput()
        
        session.commitConfiguration()
    }

    func addDeviceInput() {
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput =  try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async {
                    /*
                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
                     You can manipulate UIView only on the main thread.
                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
                     handled by CameraViewController.viewWillTransition(to:with:).
                     */
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
    }
    
    func addAudioInput() {
        // Add an audio input device.
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                print("Default audio device is unavailable.")
                return
            }
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
    }
    
    func addPhotoOutput() {
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            if #available(iOS 11.0, *) {
                photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            }
            if #available(iOS 12.0, *) {
                photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            }
            if #available(iOS 13.0, *) {
                photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
        }
    }
    
    func addMovieOutput() {
        let movieFileOutput = AVCaptureMovieFileOutput()

        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
        }
    }
    
    func initVideoDeviceDiscoverySession() {
        if #available(iOS 10.2, *) {
            if #available(iOS 11.1, *) {
                videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                               mediaType: .video, position: .unspecified)
            } else {
                videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                                                                               mediaType: .video, position: .unspecified)
            }
        } else {
            videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                           mediaType: .video, position: .unspecified)
        }
    }


    // MARK: KVO and Notifications
    private var keyValueObservations = [NSKeyValueObservation]()
    /// - Tag: ObserveInterruption
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                if let uniqueDevicePositionsCount = self.videoDeviceDiscoverySession?.uniqueDevicePositionsCount, uniqueDevicePositionsCount > 1 {
                    self.cameraOverlayView.enableSwitchCamera = isSessionRunning
                }
                self.cameraOverlayView.enableTakePicture = isSessionRunning
                self.cameraOverlayView.enableTakeVideo = isSessionRunning && self.movieFileOutput != nil
            }
        }
        keyValueObservations.append(keyValueObservation)

        if #available(iOS 11.1, *) {
            let systemPressureStateObservation = observe(\.videoDeviceInput.device.systemPressureState, options: .new) { _, change in
                guard let systemPressureState = change.newValue else { return }
                self.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
            }
            keyValueObservations.append(systemPressureStateObservation)
        }


        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)

        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)

        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }

    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }

    /// - Tag: HandleRuntimeError
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }

        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        self.cameraOverlayView.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            self.cameraOverlayView.isHidden = false
        }
    }

    /// - Tag: HandleSystemPressure
    @available(iOS 11.1, *)
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        /*
         The frame rates used here are only for demonstration purposes.
         Your frame rate throttling may be different depending on your app's camera configuration.
         */
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            if self.movieFileOutput == nil || self.movieFileOutput?.isRecording == false {
                do {
                    try self.videoDeviceInput.device.lockForConfiguration()
                    print("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                    self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                    self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                    self.videoDeviceInput.device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to shutdown system pressure level.")
        }
    }

    /// - Tag: HandleInterruption
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios you want to enable the user to resume the session.
         For example, if music playback is initiated from Control Center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in Control Center will not automatically resume the session.
         Also note that it's not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")

            var showResumeButton = false
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
                self.cameraOverlayView.cameraUnavailableLabel.alpha = 0
                self.cameraOverlayView.cameraUnavailableLabel.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.cameraOverlayView.cameraUnavailableLabel.alpha = 1
                }
            } else {
                if #available(iOS 11.1, *) {
                    if reason == .videoDeviceNotAvailableDueToSystemPressure {
                        print("Session stopped running due to shutdown system pressure level.")
                    }
                }
            }

            if showResumeButton {
                // Fade-in a button to enable the user to try to resume the session running.
                self.cameraOverlayView.resumeButton.alpha = 0
                self.cameraOverlayView.resumeButton.isHidden = false
                UIView.animate(withDuration: 0.25) {
                    self.cameraOverlayView.resumeButton.alpha = 1
                }
            }
        }
    }

    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")

        if !self.cameraOverlayView.resumeButton.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraOverlayView.resumeButton.alpha = 0
            }, completion: { _ in
                self.cameraOverlayView.resumeButton.isHidden = true
            })
        }
        if !self.cameraOverlayView.cameraUnavailableLabel.isHidden {
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.cameraOverlayView.cameraUnavailableLabel.alpha = 0
            }, completion: { _ in
                self.cameraOverlayView.cameraUnavailableLabel.isHidden = true
            }
            )
        }
    }

    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {

        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()

                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }

                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }

                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }


    public struct InfoKey : Hashable, Equatable, RawRepresentable {
        public let rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension CameraViewController: VideoCaptureOverlayDelegate {
    public func flashSwitch() {
        if flashMode == AVCaptureDevice.FlashMode.off {
            flashMode = AVCaptureDevice.FlashMode.auto
        } else {
            flashMode = AVCaptureDevice.FlashMode.off
        }
    }

    public func switchCameraDevice(_ cameraButton: UIButton) {
        cameraButton.isEnabled = false
        cameraOverlayView.enableTakeVideo = false
        cameraOverlayView.enableTakePicture = false

        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position

            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType

            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            case .back:
                preferredPosition = .front
                if #available(iOS 11.1, *) {
                    preferredDeviceType = .builtInTrueDepthCamera
                } else {
                    preferredDeviceType = .builtInDualCamera
                }
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            if let devices = self.videoDeviceDiscoverySession?.devices {
                var newVideoDevice: AVCaptureDevice? = nil

                // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
                if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                    newVideoDevice = device
                } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                    newVideoDevice = device
                }
                if let videoDevice = newVideoDevice {
                    do {
                        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                        self.session.beginConfiguration()
                        // Remove the existing device input first, because AVCaptureSession doesn't support
                        // simultaneous use of the rear and front cameras.
                        self.session.removeInput(self.videoDeviceInput)
                        if self.session.canAddInput(videoDeviceInput) {
                            self.session.addInput(videoDeviceInput)
                            self.videoDeviceInput = videoDeviceInput
                            NotificationCenter.default.removeObserver(self, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                            NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        } else {
                            self.session.addInput(self.videoDeviceInput)
                        }
                        if let connection = self.movieFileOutput?.connection(with: .video) {
                            if connection.isVideoStabilizationSupported {
                                connection.preferredVideoStabilizationMode = .auto
                            }
                        }
                        /*
                         Set Live Photo capture and depth data delivery if it's supported. When changing cameras, the
                         `livePhotoCaptureEnabled` and `depthDataDeliveryEnabled` properties of the AVCapturePhotoOutput
                         get set to false when a video device is disconnected from the session. After the new video device is
                         added to the session, re-enable them on the AVCapturePhotoOutput, if supported.
                         */
                        self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                        if #available(iOS 11.0, *) {
                            self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                        }
                        if #available(iOS 12.0, *) {
                            self.photoOutput.isPortraitEffectsMatteDeliveryEnabled = self.photoOutput.isPortraitEffectsMatteDeliverySupported
                        }
                        if #available(iOS 13.0, *) {
                            self.photoOutput.enabledSemanticSegmentationMatteTypes = self.photoOutput.availableSemanticSegmentationMatteTypes
                            self.photoOutput.maxPhotoQualityPrioritization = .quality
                        }
                        self.session.commitConfiguration()
                    } catch {
                        print("Error occurred while creating video device input: \(error)")
                    }
                }

            } else {
                print("Capture devices are unavaliable")
                return
            }

            DispatchQueue.main.sync {
                self.cameraOverlayView.enableTakeVideo = self.movieFileOutput != nil
                self.cameraOverlayView.enableTakePicture = true
                self.cameraOverlayView.enableSwitchCamera = true
            }
        }
    }

    public func takePicture() {
        guard captureDeviceIsAvailable else {
            print("Default video device is unavailable.", #file)
            return
        }
        cameraOverlayView.enableFlash = false
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. Do this to ensure that UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation

        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            var photoSettings = AVCapturePhotoSettings()

            // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }

            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = self.flashMode
            }

            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }

            if #available(iOS 13.0, *) {
                photoSettings.photoQualityPrioritization = .balanced
            }

            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings) {
                // Flash the screen to signal that AVCam took a photo.
                DispatchQueue.main.async {
                    self.previewView.videoPreviewLayer.opacity = 0
                    UIView.animate(withDuration: 0.25) {
                        self.previewView.videoPreviewLayer.opacity = 1
                    }
                }
            } livePhotoCaptureHandler: { _ in

            } completionHandler: { photoCaptureProcessor, url, data  in
                self.cameraOverlayView.enableFlash = false
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
                var mediaInfo: [InfoKey: Any] = [:]
                mediaInfo[InfoKey.imageURL] = url
                mediaInfo[InfoKey.mediaType] = kUTTypeImage as String
                if let data = data {
                    let image = UIImage(data: data)
                    mediaInfo[InfoKey.originalImage] = image
                    mediaInfo[InfoKey.mediaMetadata] = data
                    if let image = image, let watermarkImage = self.delegate?.watermarkImage() {
                        mediaInfo[InfoKey.watermarkImage] = self.addWaterMarkImage(watermarkImage, on: image)
                    }
                }
                self.delegate?.camera(self, didFinishCapturingMediaInfo: mediaInfo)
            } photoProcessingHandler: { _ in

            }

            // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }    
    
    public func startVideoCapturing() {
        guard captureDeviceIsAvailable else {
            print("Default video device is unavailable.", #file)
            return
        }
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        cameraOverlayView.enableFlash = false
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        sessionQueue.async {
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(withName: "Finish recording movie", expirationHandler: {
                        // End the task if time expires.
                        if let id = self.backgroundRecordingID {
                            UIApplication.shared.endBackgroundTask(id)
                        }
                        self.backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                    })
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!

                let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes

                if availableVideoCodecTypes.contains(.hevc) {
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }

                // Start recording video to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension(self.moviePathExtension)!)
                movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                movieFileOutput.stopRecording()
            }
        }
    }

    public func stopVideoCapturing(_ isCancel: Bool) {
        cameraOverlayView.enableFlash = true
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        sessionQueue.async {
            movieFileOutput.stopRecording()
        }
    }

    public func dismissVideoCapture() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {

    }
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        defer {
            cameraOverlayView.enableFlash = true
        }

        func endBackgroundTask() {
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid

                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            endBackgroundTask()
        }

        var success = true

        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = false
//            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }

        if success {
            var mediaInfo: [CameraViewController.InfoKey: Any] = [:]
            mediaInfo[CameraViewController.InfoKey.mediaType] = kUTTypeMovie as String
            mediaInfo[CameraViewController.InfoKey.mediaURL] = outputFileURL
            
            if let waterMark = self.delegate?.watermarkImage() {
                delegate?.cameraViewControllerStartAddingWatermark(self)
                createWaterMark(waterMarkImage: waterMark, onVideo: outputFileURL) { (url) in
                    DispatchQueue.main.async {
                        self.delegate?.camera(self, didFinishAddingWatermarkAt: url)
                        
                        mediaInfo[CameraViewController.InfoKey.watermarkVideoURL] = url
                        self.delegate?.camera(self, didFinishCapturingMediaInfo: mediaInfo)
                    }
                }
                
            } else {
                delegate?.camera(self, didFinishCapturingMediaInfo: mediaInfo)
            }
            endBackgroundTask()
        } else {
            cleanup()
            delegate?.cameraDidCancel(self)
        }
    }
    
    func getVideoSize(with assetTrack: AVAssetTrack) -> CGSize {
//        var videoAssetOrientation = UIImage.Orientation.up
        var isVideoAssetPortrait = false
        let videoTransform = assetTrack.preferredTransform

        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
//            videoAssetOrientation = .right
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
//            videoAssetOrientation = .left
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
//            videoAssetOrientation = .up
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
//            videoAssetOrientation = .down
        }

        let videoSize: CGSize
        if isVideoAssetPortrait {
            videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        return videoSize
    }
    
    
}

public extension CameraViewController.InfoKey {
    static let mediaType: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "mediaType")

    static let originalImage: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "originalImage") // a UIImage

    static let editedImage: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "editedImage")// a UIImage

    static let cropRect: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "cropRect")// an NSValue (CGRect)

    static let mediaURL: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "mediaURL") // an URL

    static let mediaMetadata: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "mediaMetadata") // an NSDictionary containing metadata from a captured photo
    static let livePhoto: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "livePhoto") // a PHLivePhoto

    static let imageURL: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "imageURL") // a URL
    
    static let watermarkImage: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "watermarkImage") // a UIImage
    static let watermarkVideoURL: CameraViewController.InfoKey = CameraViewController.InfoKey(rawValue: "watermarkVideoURL") // a URL
}
