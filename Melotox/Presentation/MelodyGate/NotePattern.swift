import Foundation

// MARK: - StreamPath

/// Describes the target indicator's 2D path over time for a melody-gate sequence.
/// Each control point defines where the target should be (as fractions of screen size)
/// at a given timestamp. The target smoothly interpolates between points.
struct StreamPath: Codable, Sendable {

    struct ControlPoint: Codable, Sendable {
        let time: TimeInterval
        let xFraction: CGFloat
        let yFraction: CGFloat
    }

    let controlPoints: [ControlPoint]
    let totalDuration: TimeInterval

    // MARK: - Interpolation

    func position(at time: TimeInterval) -> (x: CGFloat, y: CGFloat) {
        guard !controlPoints.isEmpty else { return (0.5, 0.5) }

        let clamped = max(0, min(time, totalDuration))

        if clamped <= controlPoints.first!.time {
            return (controlPoints.first!.xFraction, controlPoints.first!.yFraction)
        }

        if clamped >= controlPoints.last!.time {
            return (controlPoints.last!.xFraction, controlPoints.last!.yFraction)
        }

        for i in 0..<(controlPoints.count - 1) {
            let a = controlPoints[i]
            let b = controlPoints[i + 1]

            if clamped >= a.time && clamped <= b.time {
                let segmentDuration = b.time - a.time
                guard segmentDuration > 0 else { return (a.xFraction, a.yFraction) }

                let t = (clamped - a.time) / segmentDuration
                let smooth = (1.0 - cos(t * .pi)) / 2.0

                let x = a.xFraction + (b.xFraction - a.xFraction) * smooth
                let y = a.yFraction + (b.yFraction - a.yFraction) * smooth
                return (x, y)
            }
        }

        return (0.5, 0.5)
    }

    // MARK: - Built-in Paths

    /// A gentle, flowing path. Direction changes every ~5 seconds.
    /// Movements are smooth and meditative, not jarring.
    static func defaultPath() -> StreamPath {
        StreamPath(
            controlPoints: [
                ControlPoint(time: 0.0,  xFraction: 0.50, yFraction: 0.50),
                ControlPoint(time: 5.0,  xFraction: 0.72, yFraction: 0.60),
                ControlPoint(time: 10.0, xFraction: 0.30, yFraction: 0.45),
                ControlPoint(time: 15.0, xFraction: 0.68, yFraction: 0.65),
                ControlPoint(time: 20.0, xFraction: 0.25, yFraction: 0.38),
                ControlPoint(time: 25.0, xFraction: 0.75, yFraction: 0.55),
                ControlPoint(time: 30.0, xFraction: 0.35, yFraction: 0.62),
                ControlPoint(time: 35.0, xFraction: 0.65, yFraction: 0.35),
                ControlPoint(time: 40.0, xFraction: 0.28, yFraction: 0.55),
                ControlPoint(time: 45.0, xFraction: 0.70, yFraction: 0.48),
                ControlPoint(time: 50.0, xFraction: 0.38, yFraction: 0.60),
                ControlPoint(time: 55.0, xFraction: 0.62, yFraction: 0.42),
                ControlPoint(time: 60.0, xFraction: 0.50, yFraction: 0.50),
            ],
            totalDuration: 60.0
        )
    }

    // MARK: - JSON Loading

    static func fromJSON(data: Data) -> StreamPath? {
        try? JSONDecoder().decode(StreamPath.self, from: data)
    }
}
