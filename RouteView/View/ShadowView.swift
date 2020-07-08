//
//  ShadowView.swift
//  RouteView
//
//  Created by Kelly O'Brien on 7/8/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import UIKit

class ShadowView: UIView {

    override func awakeFromNib() {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = 15.0
        self.layer.shadowRadius = 7
        self.layer.shadowOffset = .zero
        self.layer.shadowOpacity = 0.8
        self.layer.shadowColor = UIColor.black.cgColor
    }
}
