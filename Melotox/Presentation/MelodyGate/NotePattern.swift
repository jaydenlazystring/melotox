import Foundation

// MARK: - StreamPath

/// Describes the beam's horizontal path over time for a melody-gate sequence.
/// Each control point defines where the beam should be (as a fraction of screen width)
/// at a given timestamp. The beam smoothly interpolates between points.
struct StreamPath: Codable, Sendable {

    struct ControlPoint: Codable, Sendable {
        /// Seconds from the start of the session.
        let time: TimeInterval
        /// Horizontal position as a fraction: 0.0 = left edge, 1.0 = right edge.
        let xFraction: CGFloat
    }

    let controlPoints: [ControlPoint]
    let totalDuration: TimeInterval

    // MARK: - Interpolation

    /// Returns the interpolated X fraction at the given time using smooth (cosine) interpolation.
    func xFraction(at time: TimeInterval) -> CGFloat {
        guard !controlPoints.isEmpty else { return 0.5 }

        let clamped = max(0, min(time, totalDuration))

        // Before first point
        if clamped <= controlPoints.first!.time {
            return controlPoints.first!.xFraction
        }

        // After last point
        if clamped >= controlPoints.last!.time {
            return controlPoints.last!.xFraction
        }

        // Find surrounding control points
        for i in 0..<(controlPoints.count - 1) {
            let a = controlPoints[i]
            let b = controlPoints[i + 1]

            if clamped >= a.time && clamped <= b.time {
                let segmentDuration = b.time - a.time
                guard segmentDuration > 0 else { return a.xFraction }

                let t = (clamped - a.time) / segmentDuration
                // Cosine interpolation for smooth, organic motion
                let smooth = (1.0 - cos(t * .pi)) / 2.0
                return a.xFraction + (b.xFraction - a.xFraction) * smooth
            }
        }

        return 0.5
    }

    // MARK: - Built-in Paths

    /// A gentle zigzag: centre -> right -> left -> right -> left … over 60 seconds.
    /// Nine direction changes producing a meditative, flowing motion.
    static func defaultPath() -> StreamPath {
        StreamPath(
            controlPoints: [
                ControlPoint(time: 0.0,  xFraction: 0.50),
                ControlPoint(time: 6.0,  xFraction: 0.78),
                ControlPoint(time: 13.0, xFraction: 0.22),
                ControlPoint(time: 20.0, xFraction: 0.72),
                ControlPoint(time: 27.0, xFraction: 0.28),
                ControlPoint(time: 34.0, xFraction: 0.75),
                ControlPoint(time: 41.0, xFraction: 0.25),
                ControlPoint(time: 48.0, xFraction: 0.70),
                ControlPoint(time: 54.0, xFraction: 0.30),
                ControlPoint(time: 60.0, xFraction: 0.50),
            ],
            totalDuration: 60.0
        )
    }

    // MARK: - JSON Loading

    /// Decodes a `StreamPath` from raw JSON data.
    /// Returns `nil` if the data is malformed.
    static func fromJSON(data: Data) -> StreamPath? {
        try? JSONDecoder().decode(StreamPath.self, from: data)
    }
}
