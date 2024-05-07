//
//  CustomCameraController.swift
//  SegmentHeight
//
//  Created by Arun Rathore on 09/04/24.
//

import UIKit
import AVFoundation
import Vision

class CustomCameraController: UIViewController, AVCapturePhotoCaptureDelegate {

    // MARK: - Variables
    lazy private var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()

    lazy private var takePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "capture_photo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleTakePhoto), for: .touchUpInside)
        return button
    }()

    lazy private var changeCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        button.addTarget(self, action: #selector(toggleCameraButtonPressed), for: .touchUpInside)
        return button
    }()

    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private var backCamera: Bool = false


    private var ovalMaskView: UIView?

    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()

        self.ovalMaskView = UIView(frame: view.frame)
        let ovalMaskView = OvalMaskView(frame: self.view.frame)
        self.ovalMaskView?.addSubview(ovalMaskView)
        ovalMaskView.overlayColor = .white.withAlphaComponent(0.5)


        self.view.addSubview(self.ovalMaskView!)

        if let view = self.ovalMaskView { self.view.bringSubviewToFront(view) }
        [backButton, takePhotoButton, changeCameraButton].forEach { view in
            self.view.bringSubviewToFront(view)
        }
    }

    // MARK: - Private Methods
    private func setupUI() {

        view.addSubviews(backButton, takePhotoButton, changeCameraButton)

        takePhotoButton.makeConstraints(top: nil, left: nil, right: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, topMargin: 0, leftMargin: 0, rightMargin: 0, bottomMargin: 15, width: 80, height: 80)
        takePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        changeCameraButton.makeConstraints(top: nil, left: nil, right: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, topMargin: 0, leftMargin: 0, rightMargin: 40, bottomMargin: 15, width: 100, height: 100)
        changeCameraButton.leadingAnchor.constraint(equalTo: takePhotoButton.trailingAnchor, constant: 200).isActive = true

        backButton.makeConstraints(top: view.safeAreaLayoutGuide.topAnchor, left: nil, right: view.rightAnchor, bottom: nil, topMargin: 15, leftMargin: 0, rightMargin: 10, bottomMargin: 0, width: 50, height: 50)

    }

    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // the user has already authorized to access the camera.
                self.setupCaptureSession(completion: { hasStart in
                    if hasStart {
                        self.startSession()
                    }
                })
            case .notDetermined: // the user has not yet asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { (granted) in
                    if granted { // if user has granted to access the camera.
                        print("the user has granted to access the camera")
                        DispatchQueue.main.async {
                            self.setupCaptureSession(completion: { hasStart in
                                if hasStart {
                                    self.startSession()
                                }
                            })
                        }
                    } else {
                        print("the user has not granted to access the camera")
                        self.handleDismiss()
                    }
                }

            case .denied:
                print("the user has denied previously to access the camera.")
                self.handleDismiss()

            case .restricted:
                print("the user can't give camera access due to some restriction.")
                self.handleDismiss()

            default:
                print("something has wrong due to we can't access the camera.")
                self.handleDismiss()
        }
    }

    private func setupCaptureSession(completion: @escaping (Bool) -> ()) {
        DispatchQueue.global(qos: .background).async {
            var hasError = false
            self.captureSession.sessionPreset = .high
            var videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
            if (!self.backCamera){
                videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)!
            }
            do {
                let input = try AVCaptureDeviceInput(device: videoDevice)
                for i : AVCaptureDeviceInput in (self.captureSession.inputs as! [AVCaptureDeviceInput]){
                    self.captureSession.removeInput(i)
                }

                // checking and adding to session...
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    if videoDevice.isSmoothAutoFocusSupported {
                        try videoDevice.lockForConfiguration()
                        videoDevice.isSmoothAutoFocusEnabled = false
                        videoDevice.unlockForConfiguration()
                    }
                    try videoDevice.lockForConfiguration()
                    videoDevice.unlockForConfiguration()
                }
            } catch {
                print(error.localizedDescription)
                hasError = true
            }

            if hasError{
                completion(false)
            }else{
                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                }
                completion(true)
            }
        }

        let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraLayer.frame = self.view.frame
        cameraLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(cameraLayer)
        DispatchQueue.global(qos: .background).async { [self] in
            captureSession.startRunning()
        }
        self.setupUI()
    }


    @objc private func handleDismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc private func handleTakePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    // Add a button to your UI and connect it to this action
    @IBAction func toggleCameraButtonPressed(_ sender: UIButton) {
        DispatchQueue.global().async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self.backCamera = !self.backCamera
                    self.setupCaptureSession(completion: { startSession in
                        if startSession{
                            self.startSession()
                        }
                    })
                }
            }

            DispatchQueue.main.async {
                if let view = self.ovalMaskView { self.view.bringSubviewToFront(view) }
                [
                    self.backButton,
                    self.takePhotoButton,
                    self.changeCameraButton
                ].forEach { view in
                    self.view.bringSubviewToFront(view)
                }
            }
        }
    }

        func startSession() {
            DispatchQueue.global().async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            }
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.previewCGImageRepresentation() else { return }
            let previewImage = UIImage(cgImage: imageData)

            let photoPreviewContainer = PhotoPreviewView(frame: self.view.frame)
            let orientation = (photo.metadata[kCGImagePropertyOrientation as String] as? Int) ?? 1
            let imageOrientation = UIImage.Orientation(rawValue: orientation) ?? .up
            let image = UIImage(cgImage: previewImage.cgImage!, scale: UIScreen.main.scale, orientation: imageOrientation)
            let tempImage = self.correctImageOrientation(image)

            let segmentHeightCalculator = SegmentHeightCalculator(image: tempImage)

            segmentHeightCalculator.callback = { image in
                photoPreviewContainer.photoImageView.image = image
                self.captureSession.stopRunning()

            }
            segmentHeightCalculator.executeHandler()

            self.view.addSubviews(photoPreviewContainer)
        }

        func correctImageOrientation(_ image: UIImage) -> UIImage {
            // Check image orientation
            if image.imageOrientation == .up {
                // No orientation adjustment needed
                return image
            }

            // Rotate or flip the image to correct its orientation
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let correctedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Return the corrected image
            if let correctedImage = correctedImage {
                return correctedImage
            } else {
                // If failed to create corrected image, return original image
                return image
            }
        }
    }


class OvalMaskView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }

    var overlayColor: UIColor = .white.withAlphaComponent(0.5) {
        didSet {
            // Call setNeedsDisplay to update the view's appearance
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Clear the context to make it transparent
        context.clear(rect)

        // Set the fill color to green
        self.overlayColor.setFill()

        // Draw the green rectangle
        UIRectFill(rect)

        // Create an oval path
        let frame = rect


        // Get the screen size and calculate the aspect ratio
        let screenSize = UIScreen.main.bounds.size
        let aspectRatio = screenSize.width / screenSize.height

        // Calculate the width and height of the oval based on the screen's aspect ratio
        var ovalWidth: CGFloat
        var ovalHeight: CGFloat

        // Define a constant for oval size (adjust as needed)
        let ovalSizeConstant: CGFloat = 0.5 // Percentage of screen size
        // Define the desired aspect ratio (4:3)
        let desiredAspectRatio: CGFloat = 1.0

        if aspectRatio > 1 {
            // Landscape orientation or wider screen
            ovalWidth = screenSize.width * ovalSizeConstant
            ovalHeight = ovalWidth / aspectRatio / desiredAspectRatio
        } else {
            // Portrait orientation or taller screen
            ovalHeight = screenSize.height * ovalSizeConstant
            ovalWidth = ovalHeight * aspectRatio * desiredAspectRatio
        }

        // Calculate the center position of the oval within the view
        let centerX = (screenSize.width / 2) - 50
        let centerY = screenSize.height / 2

        // Create UIBezierPath for the oval
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: centerX - ovalWidth / 2, y: centerY - ovalHeight / 2, width: ovalWidth, height: ovalHeight))


        // Set the blend mode to clear
        context.setBlendMode(.clear)

        // Fill the oval path to clear the shape
        UIColor.clear.setFill()
        ovalPath.fill()
    }
}


