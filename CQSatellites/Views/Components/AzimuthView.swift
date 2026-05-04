import SwiftUI

/// Compass-style indicator showing the pass trajectory arc from AOS to LOS.
/// When a device heading is provided, the compass rotates so that N always
/// points toward true north (standard compass behavior).
struct AzimuthView: View {
    let aosAzimuth: Double
    let losAzimuth: Double
    /// Device heading in degrees (0 = true north). Compass rotates by -heading.
    var heading: Double = 0

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Smaller compass in landscape (compact height) so it doesn't dominate the short viewport.
    private var compassSize: CGFloat {
        verticalSizeClass == .compact ? 150 : 200
    }
    private var radius: CGFloat { compassSize / 2 - 28 }

    private let directions: [(label: String, angle: Double)] = [
        ("N", 0), ("NE", 45), ("E", 90), ("SE", 135),
        ("S", 180), ("SW", 225), ("W", 270), ("NW", 315)
    ]

    var body: some View {
        ZStack {
            // Outer compass ring
            Circle()
                .stroke(.secondary.opacity(0.3), lineWidth: 1.5)
                .frame(width: radius * 2, height: radius * 2)

            // Tick marks every 45°
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(.secondary.opacity(0.4))
                    .frame(width: 1, height: 6)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            // Cardinal direction labels (counter-rotated to stay screen-upright)
            ForEach(directions, id: \.label) { dir in
                Text(dir.label)
                    .font(.system(size: 11, weight: dir.label == "N" ? .bold : .regular))
                    .foregroundStyle(dir.label == "N" ? .red : .secondary)
                    .rotationEffect(.degrees(-dir.angle + heading))
                    .offset(y: -(radius + 16))
                    .rotationEffect(.degrees(dir.angle))
            }

            // Pass trajectory arc
            PassArcShape(
                aosAngle: aosAzimuth,
                losAngle: losAzimuth,
                arcRadius: radius
            )
            .stroke(.blue.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: compassSize, height: compassSize)

            // AOS marker (green — where to point your antenna first)
            Circle()
                .fill(.green)
                .frame(width: 10, height: 10)
                .offset(y: -radius)
                .rotationEffect(.degrees(aosAzimuth))

            // LOS marker (red — where the signal is lost)
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .offset(y: -radius)
                .rotationEffect(.degrees(losAzimuth))

            // AOS / LOS labels next to dots (counter-rotated to stay screen-upright)
            Text("AOS")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.green)
                .rotationEffect(.degrees(-aosAzimuth + heading))
                .offset(y: -(radius - 14))
                .rotationEffect(.degrees(aosAzimuth))

            Text("LOS")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.red)
                .rotationEffect(.degrees(-losAzimuth + heading))
                .offset(y: -(radius - 14))
                .rotationEffect(.degrees(losAzimuth))

            // Center dot
            Circle()
                .fill(.primary.opacity(0.3))
                .frame(width: 4, height: 4)
        }
        .rotationEffect(.degrees(-heading))
        .animation(.easeOut(duration: 0.3), value: heading)
        .frame(width: compassSize, height: compassSize)
        .padding(.vertical, verticalSizeClass == .compact ? 2 : 8)
    }
}

/// Custom shape that draws the pass arc from AOS to LOS on the compass.
private struct PassArcShape: Shape {
    let aosAngle: Double
    let losAngle: Double
    let arcRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Determine shorter arc direction
        let clockwiseDist = ((losAngle - aosAngle).truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)

        // In SwiftUI's flipped coords: clockwise param true = visually counterclockwise.
        // We pass `clockwiseDist > 180` so the shorter arc is always drawn.
        let swiftUIClockwise = clockwiseDist > 180

        var path = Path()
        path.addArc(
            center: center,
            radius: arcRadius,
            startAngle: .degrees(aosAngle - 90),
            endAngle: .degrees(losAngle - 90),
            clockwise: swiftUIClockwise
        )
        return path
    }
}
