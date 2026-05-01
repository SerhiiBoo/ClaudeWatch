import SwiftUI

enum UI {
    enum Padding {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    enum Size {
        static let popoverWidth:       CGFloat = 320
        static let settingsWidth:      CGFloat = 360
        static let settingsRowIconWidth: CGFloat = 22
        static let iconSize:           CGFloat = 16
        static let avatarSize:         CGFloat = 32
    }
    enum Sparkline {
        /// Minimum number of history snapshots required before the sparkline is shown.
        static let minimumPoints: Int = 5
        /// Minimum time span (seconds) that the snapshot window must cover.
        static let minimumSpanSeconds: TimeInterval = 1800  // 30 minutes
    }
}
