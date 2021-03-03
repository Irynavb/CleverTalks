//
//  CTTextField.swift
//  CleverTalks
//
//  Created by Iryna V Betancourt on 3/2/21.
//

import UIKit

class CTTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.darkGreen.cgColor

        autocorrectionType = .no
        autocapitalizationType = .none

        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        leftViewMode = .always
        backgroundColor = .secondarySystemBackground
    }

}
