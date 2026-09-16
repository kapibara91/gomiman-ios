import SwiftUI

public struct SelectablePillView: View {
    public let title: String
    public var subtitle: String? = nil
    public let isSelected: Bool
    public var width: CGFloat? = nil
    public var height: CGFloat = 36
    public var fontSize: CGFloat = 14
    public let action: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        width: CGFloat? = nil,
        height: CGFloat = 36,
        fontSize: CGFloat = 14,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.width = width
        self.height = height
        self.fontSize = fontSize
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: fontSize, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .defaultTheme)

                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .customTextSecondary)
                }
            }
            .frame(maxWidth: width != nil ? width : .infinity)
            .frame(height: height)
            .background(isSelected ? Color.defaultTheme : Color.white)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.clear : Color.defaultTheme, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
