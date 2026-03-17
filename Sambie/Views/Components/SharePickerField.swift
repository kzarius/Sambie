//
//  SharePickerField.swift
//  Sambie
//
//  Created by Kaeo McKeague-Clark on 17/3/2026.
//

import SwiftUI

///  A share text field with a browse button that opens a ShareBrowserView popover.
struct SharePickerField: View {

    // MARK: - Properties
    @Binding var share: String
    let host: String
    let username: String
    let password: String


    // MARK: - View
    var body: some View {
        PopoverPickerField(
            text: self.$share,
            icon: "list.bullet.rectangle",
            help: "Browse available shares"
        ) {
            // Generate the share list when the popover opens, and update the share field when a share is selected:
            ShareBrowserView(
                host: self.host,
                username: self.username,
                password: self.password
            ) { selected in
                self.share = selected
            }
        }
    }
}
