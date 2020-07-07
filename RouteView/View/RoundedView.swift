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
        self.layer.cornerRadius = 10.0
        self.clipsToBounds = true
        
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = 0.5
        
        self.layer.shadowColor = UIColor.black.cgColor
    }

}
