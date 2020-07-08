//
//  RoundButton.swift
//  RouteView
//
//  Created by Kelly O'Brien on 6/25/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import UIKit

class RoundedView: UIView {

    override func awakeFromNib() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 15.0
    }
}
