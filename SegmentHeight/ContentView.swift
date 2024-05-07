//
//  ContentView.swift
//  SegmentHeight
//
//  Created by Arun Rathore on 09/04/24.
//

import SwiftUI

struct CameraView: View {
    @State var isSheetenabled: Bool = false
//    @State var image: UIImage = UIImage(named: "Arun Singh Rathore")!
//    @State private var hideAddVideoButton = false
//    @State private var isNavigationLinkActive = false

    var body: some View {
//        if !hideAddVideoButton {
//            NavigationLink(destination: CameraView1, isActive: $isNavigationLinkActive){
//                Button {
////                    isNavigationLinkActive = true
//                    CameraView1()
//                } label: {
//                    HStack {
//                        Text("Add Video")
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .frame(height: 50)
//                        Image(systemName: "arrow.right")
//                    }
//
        VStack {
            CustomButton(buttonText: "Take Photo", action: {
                self.isSheetenabled = true
            })
        }
        .sheet(isPresented: $isSheetenabled, content: {
            MyViewControllerWrapper()
        })
    }
}


struct CustomButton: View {
    var buttonText: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(buttonText)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .background(.blue)
                .cornerRadius(8)
        }
    }
}
