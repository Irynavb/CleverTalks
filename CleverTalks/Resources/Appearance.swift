//
//  Appearance.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 9/28/20.
//

import UIKit

extension UIColor {

    static let darkBrown = UIColor(named: "Dark Brown")!
    static let darkGreen = UIColor(named: "Dark Green")!
    static let mediumGreen = UIColor(named: "Medium Green")!
    static let backgroundLightGreen = UIColor(named: "Background Light Green")!
}

extension UIView {

    public var width: CGFloat {

        self.frame.size.width

    }

    public var height: CGFloat {

        self.frame.size.height

    }

    public var top: CGFloat {

        self.frame.origin.y

    }

    public var bottom: CGFloat {

        self.frame.size.height + self.frame.origin.y

    }

    public var left: CGFloat {

        self.frame.origin.x

    }

    public var right: CGFloat {

        self.frame.size.width + self.frame.origin.x

    }

}
