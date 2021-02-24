//
//  Media.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 2/23/21.
//

import UIKit
import MessageKit

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
