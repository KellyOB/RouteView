//
//  Int+ConvertTime.swift
//  RouteView
//
//  Created by Kelly O'Brien on 7/8/20.
//  Copyright © 2020 Kismet Development. All rights reserved.
//

import Foundation

extension Int {
    func convertTime() -> String {
        let duration: TimeInterval = TimeInterval(self)

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional // Use the appropriate positioning for the current locale
        formatter.allowedUnits = [ .hour, .minute, .second ] // Units to display in the formatted string
        formatter.zeroFormattingBehavior = [ .pad ] // Pad with zeroes where appropriate for the locale

        let formattedDuration = formatter.string(from: duration)
        return formattedDuration!
    }
}
