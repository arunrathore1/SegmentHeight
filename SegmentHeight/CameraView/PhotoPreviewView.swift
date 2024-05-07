//
//  PhotoPreviewView.swift
//  SegmentHeight
//
//  Created by Arun Rathore on 09/04/24.
//

import UIKit
import Photos

class PhotoPreviewView: UIView {

    let photoImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
      imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy private var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()



    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubviews(photoImageView, cancelButton)

        photoImageView.makeConstraints(top: topAnchor, left: leftAnchor, right: rightAnchor, bottom: bottomAnchor, topMargin: 0, leftMargin: 0, rightMargin: 0, bottomMargin: 0, width: 0, height: 0)

        cancelButton.makeConstraints(top: safeAreaLayoutGuide.topAnchor, left: nil, right: rightAnchor, bottom: nil, topMargin: 15, leftMargin: 0, rightMargin: 10, bottomMargin: 0, width: 50, height: 50)

    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func handleCancel() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }

    func setImage(_ image: UIImage) {
        photoImageView.image = image
    }
}
