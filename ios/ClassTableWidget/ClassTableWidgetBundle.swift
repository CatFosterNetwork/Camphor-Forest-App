//
//  ClassTableWidgetBundle.swift
//  ClassTableWidget
//
//  Created by 韩沛霖 on 2025/10/16.
//

import WidgetKit
import SwiftUI

@main
struct ClassTableWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClassTableWidget()
        ClassTableWidgetControl()
        ClassTableWidgetLiveActivity()
    }
}
