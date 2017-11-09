//
// Created by Lucas Maris on 7/14/17.
// Copyright (c) 2017 toucheapp. All rights reserved.
//

import Foundation
import UIKit
import Cupcake
import MapKit
import SwiftDate
import SwiftyJSON

class ToucheStatusBar: UIView {

    private var distanceInMeters: Double!
    private var lastSeen: String!;

    private var distLabel: UILabel!
    private var seenLabel: UILabel!
    private var polyLabel: UILabel!

    private var dot: UIImageView!

    private var polys: [JSON]!


    public init(frame: CGRect, distance: Double, lastSeen: String) {
        super.init(frame: frame)
        self.distanceInMeters = distance
        self.lastSeen = lastSeen
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setup() {

        self.distLabel = Label.str(buildDistanceString()).font("Montserrat-Regular,12").color("white")
        self.seenLabel = Label.str(buildLastSeenString()).font("Montserrat-Regular,12").color("green")

        self.polyLabel = Label.str(buildPolyString()).font("Montserrat-Regular,12").color("white")

        self.dot = buildDot()
        self.dot.tint(buildDotColor())

        VStack(
                "<-->",
                HStack(
                        10,
                        self.polyLabel,
                        10
                ),
                5,
                HStack(
                        10,
                        HStack(
                                ImageView.img("002-navigation").pin(.wh(10, 10)),
                                5,
                                self.distLabel
                        ),
                        10,
                        HStack(
                                dot.pin(.wh(10, 10)),
                                5,
                                self.seenLabel
                        ),
                        10
                ),
                "<-->"
        ).embedIn(self)
    }

    private func buildLastSeenString() -> String {
        if let date = DateManager.getDateFromMillis(self.lastSeen) {
            let d_str = try! date.colloquialSinceNow()
            return d_str.colloquial
        }
        return ""
    }

    private func buildPolyString() -> String {
        if polys != nil && polys.count > 0 {
            return self.polys.map {
                "📍 \($0.stringValue)"
            }.first!
        }
        return ""
    }

    private func buildDot() -> UIImageView {
        return ImageView.img("$001-circle").tint(UIColor.clear)
    }

    private func buildDistanceString() -> String {
        if self.distanceInMeters == 0.0 {
            return ""
        }
        return "\(self.formatDistance(self.distanceInMeters))"
    }

    func formatDistance(_ dist: Double) -> String {

        let formatter = MeasurementFormatter()
        var distanceInMeters = Measurement(value: round(dist), unit: UnitLength.meters)

//        let locale = Locale(identifier: Locale.preferredLanguages[0])
//
//        let numberFormatter = NumberFormatter()
//        numberFormatter.numberStyle = .decimal
//        numberFormatter.locale = locale
//        numberFormatter.maximumFractionDigits = 0
//        formatter.numberFormatter = numberFormatter
//
//        formatter.locale = locale
//
//        formatter.unitStyle = MeasurementFormatter.UnitStyle.short
//        formatter.unitOptions = .naturalScale
//        return formatter.string(from: distanceInMeters)

        let locale = Locale(identifier: Locale.preferredLanguages[0])

        let n = NumberFormatter()
        n.maximumFractionDigits = 0
        n.minimumFractionDigits = 0
        //n.locale = locale
        let m = MeasurementFormatter()
        m.numberFormatter = n
        //m.locale = locale

        m.unitOptions = .naturalScale

        return m.string(from: distanceInMeters)
    }

    func refresh(_ dist: Double, _ seen: String, _ polys: [JSON]) {
        self.lastSeen = seen
        self.distanceInMeters = dist
        self.polys = polys

        self.distLabel.str(buildDistanceString())
        self.seenLabel.str(buildLastSeenString()).color(buildLabelColor())
        self.polyLabel.str(buildPolyString())
        self.dot.tint(buildDotColor())
    }

    private func buildLabelColor() -> UIColor {
        if let date = DateManager.getDateFromMillis(self.lastSeen) {
            if date.isAfter(date: (60.minutes).ago()!, granularity: Calendar.Component.minute) {
                return Color("green")!
            }
            return Color("white")!
        }
        return UIColor.clear
    }

    private func buildDotColor() -> UIColor {
        if let date = DateManager.getDateFromMillis(self.lastSeen) {
            if date.isAfter(date: (60.minutes).ago()!, granularity: Calendar.Component.minute) {
                return Color("green")!
            }
            return UIColor.gray
        }
        return UIColor.clear
    }
}