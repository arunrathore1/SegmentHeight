//
//  ImageViewController.swift
//  SegmentHeight
//
//  Created by Arun Rathore on 09/04/24.
//


import Foundation
import CoreML
import Vision
import UIKit

class SegmentHeightCalculator: NSObject {
  
  // glass detections
  private var glassDetectionModel: GlassDetection!
  private var vnRequest: VNCoreMLRequest!
  private var image: UIImage!
  private var cgImage: CGImage?
  private var boundingBox: CGRect = .zero
  
  // face landmarks detection
  private var faceLandmarkRequest: VNCoreMLRequest!
  
  private var imageResult: UIImage? = nil
  private var leftVector: CGPoint = .zero
  private var rightVector: CGPoint = .zero
  
  private let hardCodedPupilSize = 8.0
  private let lineIncement = 3.0
  
  var callback: ((_ image: UIImage) -> Void)?
  
  private override init() {
    super.init()
    self.loadTrainedModal()
  }
  
  convenience init(image: UIImage) {
    self.init()
    self.image = image
    self.cgImage = self.image.cgImage
    self.imageResult = self.image
  }
  
  convenience init(cgImage: CGImage) {
    self.init()
    self.image = UIImage(cgImage: cgImage)
    self.cgImage = cgImage
    self.imageResult = self.image
  }
  
  
  private func loadTrainedModal() {
    do {
      self.glassDetectionModel = try GlassDetection(configuration: MLModelConfiguration())
      guard let visionModel = try? VNCoreMLModel(for: glassDetectionModel!.model) else {
        fatalError("Failed to create VNCoreMLModel")
      }
      // Set up Vision request
      let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
        
        guard let self = self else { return }
        
        if let error = error {
          print("Error: \(error)")
          return
        }
        
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
          print("Model failed to process image")
          return
        }
        
        // Process the results here
        
        guard let object = results.first else {
          print("object failed to process")
          return
        }
        
        self.boundingBox = object.boundingBox
        self.cropImageWithBounding(self.boundingBox, on: self.imageResult!)
        
      }
      // Add the request to the array of requests
      self.vnRequest = request
    } catch {
      print("Error initializing Core ML model: \(error)")
    }
  }
  
  
  func executeHandler() {
    guard let cgImage = self.cgImage else {
      print("Invalid Core Image")
      return
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    // Create a face landmarks detection request
    let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceLandmarks)
    // Perform the request
    do {
      try handler.perform([faceLandmarksRequest])
    } catch {
      print("Error performing face landmarks request: \(error)")
    }
  }
  
  private func frameDetection() {
    guard let cgImage = self.cgImage else {
      print("Invalid Core Image")
      return
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      /// Perform the Vision request
      try handler.perform([self.vnRequest])
    } catch {
      print("Failed to perform Vision request: \(error)")
    }
  }
  
  
  private func handleFaceLandmarks(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNFaceObservation] else {
      fatalError("Unexpected result type from VNFaceObservation")
    }
    
    for observation in observations {
      guard let landmarks = observation.landmarks else {
        continue
      }
      
      let boundingBox = observation.boundingBox
      //Calculating Left Pupil Center
      let leftPupilCenterPoint = self.getPointOnImage(centre: self.getCenterPoint(for: (landmarks.leftPupil)!, boundingBox: boundingBox))
      //Calculating Right Pupil Center
      let rightPupilCenterPoint = self.getPointOnImage(centre: self.getCenterPoint(for: (landmarks.rightPupil)!, boundingBox: boundingBox))
      self.leftVector = leftPupilCenterPoint
      self.rightVector = rightPupilCenterPoint
      //Calling Frame Detection method
      frameDetection()
    }
  }
  
  private func calculateDistance(frameBoundingBox: CGRect, pupilCoordinates: CGPoint) -> CGFloat? {
    print(frameBoundingBox.maxY, pupilCoordinates.y)
    let distance = (frameBoundingBox.maxY - pupilCoordinates.y)
    return distance
  }
  
  
  private func convert(boundingBox: CGRect, to bounds: CGRect) -> CGRect {
    let imageWidth = bounds.width
    let imageHeight = bounds.height
    
    // Begin with input rect.
    var rect = boundingBox
    
    // Reposition origin.
    rect.origin.x *= imageWidth
    rect.origin.x += bounds.minX
    rect.origin.y = (1 - rect.maxY) * imageHeight + bounds.minY
    
    // Rescale normalized coordinates.
    rect.size.width *= imageWidth
    rect.size.height *= imageHeight
    
    return rect
  }
  
  private func cropImageWithBounding(_ boundingBox: CGRect, on image: UIImage) {
    let imageSize = image.size
    //getting bounding box of frame on image coordinates
    let boundingofFrame = convert(boundingBox: boundingBox, to: CGRect(origin: .zero, size: imageSize))
    //calculating distance of left pupil to bottom of frame
    let leftdistacne = calculateDistance(frameBoundingBox: boundingofFrame, pupilCoordinates: leftVector)
    //calculating distance of right pupil to bottom of frame
    let rightDistance = calculateDistance(frameBoundingBox: boundingofFrame, pupilCoordinates: rightVector)
    print(leftVector, "Left Vector", rightVector, "Right", boundingofFrame, "Bounding of Frame", leftdistacne!, "Left Distance", rightDistance!)
    DispatchQueue.main.async { [self] in
      //Draw horizontal line line for left and for right it will bottom of pupil
      let updatedImage = drawPointsOnImage(self.imageResult!, points: [leftVector, rightVector])
      // Draw vertical on left side
      guard let updateImage1 = self.drawLineAndTextOnImage(image: updatedImage, startPoint: leftVector, endPoint: CGPoint(x: self.leftVector.x, y: boundingofFrame.maxY), text: "\(String(format: "%.2f mm", leftdistacne ?? 0.0))") else {return}
      // Draw vertical line on right side
      guard let updatedImage2 = self.drawLineAndTextOnImage(image: updateImage1, startPoint: CGPoint(x: rightVector.x, y: rightVector.y + hardCodedPupilSize), endPoint: CGPoint(x: rightVector.x, y: boundingofFrame.maxY), text: "\(String(format: "%.2f mm", rightDistance ?? 0.0))") else {return}
      let newImage = cropImage(updatedImage2, with: boundingofFrame)
      self.imageResult = newImage
      self.callback?(newImage!)
    }
  }
  
  
   private func drawLineAndTextOnImage(
        image: UIImage,
        startPoint: CGPoint,
        endPoint: CGPoint,
        text: String
    ) -> UIImage? {
    // Create a copy of the original image
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    image.draw(at: CGPoint.zero)
    print(endPoint, "In drawline and text")
    // Draw a line
    let context = UIGraphicsGetCurrentContext()
    context?.setStrokeColor(UIColor.red.cgColor)
    context?.setLineWidth(0.5)
    context?.move(to: startPoint)
    context?.addLine(to: endPoint)
    context?.strokePath()
    
    
    let bottomStartPoint = CGPoint(x: endPoint.x - lineIncement, y: endPoint.y)
    let bottomEndPoint = CGPoint(x: endPoint.x + lineIncement, y: endPoint.y)
    context?.move(to: bottomStartPoint)
    context?.addLine(to: bottomEndPoint)
    context?.strokePath()
    
    // Calculate midpoint of the line
    let midPoint = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: (startPoint.y + endPoint.y) / 2)
    
    // Draw text alongside the line
    let textAttributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.red,
      .font: UIFont.systemFont(ofSize: 12.0)
    ]
    let textSize = (text as NSString).size(withAttributes: textAttributes)
        let textRect = CGRect(
            x: midPoint.x - textSize.width / 2,
            y: midPoint.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
    (text as NSString).draw(in: textRect, withAttributes: textAttributes)
    
    // Get the updated image
    let updatedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return updatedImage
  }
  
    private func drawPointsOnImage(
        _ image: UIImage,
        points: [CGPoint]
    ) -> UIImage {
    // Begin an image context to draw on
    UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
    defer { UIGraphicsEndImageContext() }
    
    // Draw the original image
    image.draw(at: .zero)
    
    // Get the graphics context
    guard let context = UIGraphicsGetCurrentContext() else {
      fatalError("Failed to get the graphics context")
    }
    
    // Set point properties
    let pointColor = UIColor.red
    
    // Draw points on the image// Example points
    context.setStrokeColor(pointColor.cgColor)
    context.setLineWidth(0.5)
    var pointForOne = 0
    for point in points {
      // Draw lines
      print(point, "more point")
      var startPoint: CGPoint = .zero
      var endPoint: CGPoint = .zero
      if(pointForOne > 0) {
        startPoint = CGPoint(x: point.x - lineIncement, y: point.y + hardCodedPupilSize)
        endPoint = CGPoint(x: point.x + lineIncement, y: point.y + hardCodedPupilSize)
      } else {
        startPoint = CGPoint(x: point.x - 3, y: point.y)
        endPoint = CGPoint(x: point.x + 3, y: point.y)
      }
      pointForOne += 1
      context.move(to: startPoint)
      context.addLine(to: endPoint)
      context.strokePath()
    }
    
    // Get the image with drawn points
    guard let imageWithPoints = UIGraphicsGetImageFromCurrentImageContext() else {
      fatalError("Failed to get image with drawn points from context")
    }
    
    return imageWithPoints
  }
  
    private func cropImage(
        _ image: UIImage,
        with boundingBox: CGRect
    ) -> UIImage? {
        let scale = image.scale
        let normalizedRect = CGRect(
            x: boundingBox.origin.x * scale,
            y: boundingBox.origin.y * scale,
            width: boundingBox.size.width * scale,
            height: boundingBox.size.height * scale
        )

        // Ensure the normalized rect fits within the image bounds
        let intersectionRect = normalizedRect.intersection(
            CGRect(
                x: 0,
                y: 0,
                width: image.size.width * scale,
                height: image.size.height * scale
            )
        )
        print(intersectionRect.size, intersectionRect.origin, "Intersection erect")

        // Increasing by 12 because magic number needed it was taking eyebrows into account
        let changedRect = CGRect(
            x: intersectionRect.origin.x,
            y: intersectionRect.origin.y + 12,
            width: intersectionRect.size.width,
            height: intersectionRect.size.height
        )
        // Check if intersection rect is valid
        guard !intersectionRect.isNull, let cgImage = image.cgImage?.cropping(to: changedRect) else {
            return nil
        }

        // Create and return cropped image
        let croppedImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
        return croppedImage
    }

    private func getPointOnImage(centre point: CGPoint?) -> CGPoint {
        let startX = (self.image.size.width * (point?.x ?? 0.0))
        let startY = abs((self.image.size.height * (point?.y ?? 0.0)) - self.image.size.height)
        return .init(x: startX, y: startY)
    }

    private func getCenterPoint(
        for landmarkRegion: VNFaceLandmarkRegion2D,
        boundingBox: CGRect
    ) -> CGPoint? {
        guard !landmarkRegion.normalizedPoints.isEmpty else {
            return nil
        }
        // Calculate the average of all points within the region
        let averagePoint = landmarkRegion.normalizedPoints.reduce(CGPoint.zero) { (result, point) -> CGPoint in
            return CGPoint(
                x: result.x + point.x / CGFloat(landmarkRegion.normalizedPoints.count),
                y: result.y + point.y / CGFloat(landmarkRegion.normalizedPoints.count)
            )
        }

        // Convert the normalized point to the coordinate space of the image
        let centerPoint = CGPoint(
            x: averagePoint.x * boundingBox.width + boundingBox.origin.x,
            y: averagePoint.y * boundingBox.height + boundingBox.origin.y
        )
        return centerPoint
    }

}
