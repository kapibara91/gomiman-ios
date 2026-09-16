import SwiftUI

public struct GarbageTypeBadgeView: View {
    public let title: String
    public var size: CGFloat = 38
    public var fontSize: CGFloat = 12

    public init(title: String, size: CGFloat = 38, fontSize: CGFloat = 12) {
        self.title = title
        self.size = size
        self.fontSize = fontSize
    }

    public var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(.defaultTheme)
            .frame(width: size, height: size)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.defaultTheme, lineWidth: 1)
            )
    }
}
