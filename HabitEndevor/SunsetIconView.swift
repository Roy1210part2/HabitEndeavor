import SwiftUI

struct SunsetIconView: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.27, green: 0.12, blue: 0.51), location: 0),
                    .init(color: Color(red: 0.95, green: 0.42, blue: 0.18), location: 0.52),
                    .init(color: Color(red: 1.0,  green: 0.78, blue: 0.32), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Sea (bottom 40%)
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.20, blue: 0.44),
                        Color(red: 0.04, green: 0.10, blue: 0.24),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size * 0.40)
            }

            // Sun glow halo
            Circle()
                .fill(Color(red: 1.0, green: 0.72, blue: 0.22).opacity(0.38))
                .frame(width: size * 0.50, height: size * 0.50)
                .offset(y: size * 0.08)
                .blur(radius: size * 0.07)

            // Sun body (full circle, sea layer clips the bottom half)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.97, blue: 0.62),
                            Color(red: 1.0, green: 0.72, blue: 0.22),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.12
                    )
                )
                .frame(width: size * 0.24, height: size * 0.24)
                .offset(y: size * 0.08)

            // Sea overlay (re-draws on top of sun bottom half)
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.20, blue: 0.44),
                        Color(red: 0.04, green: 0.10, blue: 0.24),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: size * 0.38)
            }

            // Horizon shimmer lines
            VStack(spacing: size * 0.055) {
                ForEach(0..<3, id: \.self) { i in
                    let w = size * (0.28 - CGFloat(i) * 0.07)
                    Rectangle()
                        .fill(Color(red: 1.0, green: 0.84, blue: 0.38).opacity(0.55 - Double(i) * 0.13))
                        .frame(width: w, height: max(1, size * 0.018))
                        .blur(radius: 0.4)
                }
            }
            .offset(y: size * 0.20)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    HStack(spacing: 16) {
        SunsetIconView(size: 28)
        SunsetIconView(size: 44)
        SunsetIconView(size: 80)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
