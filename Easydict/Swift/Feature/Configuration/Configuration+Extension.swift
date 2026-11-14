//
//  Configuration+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: Window Frame

extension MyConfiguration {
    func windowFrameWithType(_ windowType: EZWindowType) -> CGRect {
        Defaults[.windowFrame(for: windowType)]
    }

    func setWindowFrame(_ frame: CGRect, windowType: EZWindowType) {
        Defaults[.windowFrame(for: windowType)] = frame
    }
}

// MARK: Window Configuration

extension MyConfiguration {
    func showInputTextField(key: WindowConfigurationKey, windowType: EZWindowType) -> Bool {
        Defaults[windowConfigurationKey(key, windowType: windowType, defaultValue: true)]
    }
}
