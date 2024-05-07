//
//  MyViewControllerWrapper.swift
//  SegmentHeight
//
//  Created by Arun Rathore on 09/04/24.
//

import SwiftUI

struct MyViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = CustomCameraController

    func makeUIViewController(context: Context) -> CustomCameraController {
        return CustomCameraController()
    }

    func updateUIViewController(_ uiViewController: CustomCameraController, context: Context) {
        // Update the CustomCameraController if needed
    }
}


//struct PhotoPreviewViewWrapper: UIViewRepresentable {
//    let image: UIImage
//
//    func makeUIView(context: Context) -> PhotoPreviewView {
//        let photoPreviewView = PhotoPreviewView()
//        photoPreviewView.setImage(image)
//        return photoPreviewView
//    }
//
//    func updateUIView(_ uiView: PhotoPreviewView, context: Context) {
//        uiView.setImage(image)
//    }
//}
