//
//  RoundButton.swift
//  RouteView
//
//  Created by Kelly O'Brien on 6/25/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import UIKit

class RoundButton: UIButton {

    override func awakeFromNib() {
        self.layer.cornerRadius = self.frame.height / 2
        
        self.layer.shadowRadius = 20
        self.layer.shadowOpacity = 0.5
        
        self.layer.shadowColor = UIColor.black.cgColor
        //self.setTitle("Start Run", for: .normal)
        self.tintColor = .systemGreen
    }

}
