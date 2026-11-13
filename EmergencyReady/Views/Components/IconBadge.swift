import SwiftUI
import UIKit

// A round badge that shows an image from Assets.xcassets if one with that name exists,
// otherwise an SF Symbol. This way the app looks good even before you add your own images.
struct IconBadge: View {
    let imageName: String?
    let symbolName: String
    let color: Color
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.15))

            if let imageName = imageName, !imageName.isEmpty, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)   // decorative: screen readers read the text instead
    }
}
