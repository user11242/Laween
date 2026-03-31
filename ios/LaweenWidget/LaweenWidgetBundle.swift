//
//  LaweenWidgetBundle.swift
//  LaweenWidget
//
//  Created by Yazan Qattous on 31/03/2026.
//

import WidgetKit
import SwiftUI

@main
struct LaweenWidgetBundle: WidgetBundle {
    var body: some Widget {
        LaweenWidget()
        LaweenWidgetControl()
        LaweenWidgetLiveActivity()
    }
}
