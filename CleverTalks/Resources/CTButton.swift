//
//  CTButton.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 3/2/21.
//

import UIKit

class CTButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        backgroundColor = .darkBrown
        setTitleColor(.white, for: .normal)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)

    }
}
