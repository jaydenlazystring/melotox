import SpriteKit

// MARK: - MelodyGateSceneDelegate

/// Callback interface for melody-gate completion / failure.
protocol MelodyGateSceneDelegate: AnyObject {
    func didComplete()
    func didFail()
}

// MARK: - MelodyGateScene

/// A SpriteKit scene implementing a hold-and-follow beam mechanic.
///
/// A neon beam flows from top to bottom, zigzagging left and right. The player
/// must press and hold their finger on the hit zone, tracking the beam's
/// horizontal position as it moves. Accuracy is measured each frame; too many
/// cumulative miss-frames cause the gate to fail. Surviving for the full
/// duration completes the gate.
///
/// The scene does **not** manage audio -- that responsibility belongs to the
/// owning ViewModel.
final class MelodyGateScene: SKScene {

    // MARK: - Configuration

    /// Total gate duration in seconds.
    private let gateDuration: TimeInterval = 60.0

    /// Seconds of upcoming path visible above the hit zone.
    private let previewWindow: TimeInterval = 3.0

    /// Vertical fraction (from bottom) where the hit zone sits.
    private let hitZoneFraction: CGFloat = 0.15

    /// Horizontal tolerance in points -- finger must be within this distance.
    private let hitTolerance: CGFloat = 50.0

    /// Maximum cumulative miss-frames before the gate fails (~3 seconds at 60fps).
    private let maxMissFrames: Int = 180

    // MARK: - Stream Path

    private var streamPath: StreamPath = .defaultPath()

    // MARK: - State

    private var sceneStartTime: TimeInterval?
    private var isRunning: Bool = false
    private var holdFrames: Int = 0
    private var missFrames: Int = 0

    /// Whether the user's finger is currently down.
    private var isTouching: Bool = false

    /// Current X position of the user's finger (in scene coordinates).
    private var fingerX: CGFloat = 0.0

    weak var gateDelegate: MelodyGateSceneDelegate?

    // MARK: - Nodes

    private var beamNode: SKShapeNode?
    private var beamGlowNode: SKShapeNode?
    private var hitZoneBar: SKShapeNode?
    private var hitZoneIndicator: SKShapeNode?
    private var hitZoneGlow: SKShapeNode?
    private var trailEmitter: SKEmitterNode?

    // MARK: - Computed

    private var hitZoneY: CGFloat {
        size.height * hitZoneFraction
    }

    // MARK: - Public Setup

    /// Supply a custom stream path before presenting the scene.
    func configure(path: StreamPath) {
        streamPath = path
    }

    /// Reset the scene for a retry.
    func resetSession() {
        removeAllChildren()
        removeAllActions()

        sceneStartTime = nil
        isRunning = false
        holdFrames = 0
        missFrames = 0
        isTouching = false
        fingerX = 0.0

        beamNode = nil
        beamGlowNode = nil
        hitZoneBar = nil
        hitZoneIndicator = nil
        hitZoneGlow = nil
        trailEmitter = nil

        streamPath = .defaultPath()

        if let view = self.view {
            didMove(to: view)
        }
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0, y: 0)

        buildBackground()
        buildHitZone()
        buildBeam()
        buildTrailEmitter()
        buildParticles()

        isRunning = true
    }

    override func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }

        // Capture scene start time on first frame.
        if sceneStartTime == nil {
            sceneStartTime = currentTime
        }

        let elapsed = currentTime - (sceneStartTime ?? currentTime)

        // Check for completion.
        if elapsed >= gateDuration {
            isRunning = false
            gateDelegate?.didComplete()
            return
        }

        // Current beam X at the hit zone.
        let beamFraction = streamPath.xFraction(at: elapsed)
        let beamX = beamFraction * size.width

        // Update beam visual.
        updateBeamPath(elapsed: elapsed)

        // Update hit zone indicator position.
        hitZoneIndicator?.position.x = beamX
        hitZoneGlow?.position.x = beamX

        // Scoring: check finger proximity.
        if isTouching && abs(fingerX - beamX) <= hitTolerance {
            holdFrames += 1
            applyHoldFeedback()
        } else {
            missFrames += 1
            applyMissFeedback()

            if missFrames >= maxMissFrames {
                isRunning = false
                gateDelegate?.didFail()
                return
            }
        }

        // Update trail emitter position.
        trailEmitter?.position = CGPoint(x: beamX, y: hitZoneY)
        trailEmitter?.particleBirthRate = (isTouching && abs(fingerX - beamX) <= hitTolerance) ? 30 : 0
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first else { return }
        isTouching = true
        fingerX = touch.location(in: self).x
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first else { return }
        fingerX = touch.location(in: self).x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    // MARK: - Beam Rendering

    private func buildBeam() {
        let beam = SKShapeNode()
        beam.strokeColor = SKColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 0.9)
        beam.lineWidth = 3.0
        beam.lineCap = .round
        beam.zPosition = 10
        beam.isAntialiased = true
        addChild(beam)
        beamNode = beam

        let glow = SKShapeNode()
        glow.strokeColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.3)
        glow.lineWidth = 12.0
        glow.lineCap = .round
        glow.zPosition = 9
        glow.isAntialiased = true
        addChild(glow)
        beamGlowNode = glow
    }

    /// Rebuild the beam's CGPath each frame to reflect current scroll position.
    private func updateBeamPath(elapsed: TimeInterval) {
        let path = CGMutablePath()

        // The beam shows from current time (at hit zone) up to previewWindow seconds ahead (at top).
        // We sample the stream path and map time -> screen position.
        let steps = 60
        let timeStart = elapsed                        // bottom (hit zone)
        let timeEnd = elapsed + previewWindow          // top of visible beam

        let yBottom = hitZoneY
        let yTop = size.height + 20 // slightly off-screen top

        for i in 0...steps {
            let fraction = CGFloat(i) / CGFloat(steps)
            let t = timeStart + Double(fraction) * (timeEnd - timeStart)
            let xFrac = streamPath.xFraction(at: t)
            let x = xFrac * size.width
            let y = yBottom + fraction * (yTop - yBottom)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        beamNode?.path = path
        beamGlowNode?.path = path
    }

    // MARK: - Hit Zone

    private func buildHitZone() {
        // Full-width horizontal bar.
        let bar = SKShapeNode(rectOf: CGSize(width: size.width * 0.85, height: 3),
                              cornerRadius: 1.5)
        bar.name = "hitZone"
        bar.position = CGPoint(x: size.width / 2, y: hitZoneY)
        bar.fillColor = SKColor(red: 0.72, green: 0.58, blue: 1.0, alpha: 0.3)
        bar.strokeColor = .clear
        bar.glowWidth = 4
        bar.zPosition = 5
        addChild(bar)
        hitZoneBar = bar

        // Glow circle behind the indicator.
        let glow = SKShapeNode(circleOfRadius: 28)
        glow.position = CGPoint(x: size.width / 2, y: hitZoneY)
        glow.fillColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.10)
        glow.strokeColor = .clear
        glow.zPosition = 6
        addChild(glow)
        hitZoneGlow = glow

        // Small circle indicator where the beam crosses the hit zone.
        let indicator = SKShapeNode(circleOfRadius: 14)
        indicator.position = CGPoint(x: size.width / 2, y: hitZoneY)
        indicator.fillColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.8)
        indicator.strokeColor = SKColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 0.6)
        indicator.lineWidth = 2
        indicator.glowWidth = 6
        indicator.zPosition = 12
        addChild(indicator)
        hitZoneIndicator = indicator

        // Subtle breathing pulse on the indicator.
        let grow = SKAction.scale(to: 1.15, duration: 0.8)
        grow.timingMode = .easeInEaseOut
        let shrink = SKAction.scale(to: 0.9, duration: 0.8)
        shrink.timingMode = .easeInEaseOut
        indicator.run(SKAction.repeatForever(SKAction.sequence([grow, shrink])))
    }

    // MARK: - Trail Emitter

    private func buildTrailEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 0  // starts off, enabled when holding correctly
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.emissionAngle = .pi / 2  // upward
        emitter.emissionAngleRange = .pi / 4
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 15
        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -1.0
        emitter.particleScale = 0.05
        emitter.particleScaleSpeed = -0.05
        emitter.particleColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.position = CGPoint(x: size.width / 2, y: hitZoneY)
        emitter.zPosition = 15
        addChild(emitter)
        trailEmitter = emitter
    }

    // MARK: - Visual Feedback

    private func applyHoldFeedback() {
        beamNode?.strokeColor = SKColor(red: 0.50, green: 0.85, blue: 1.0, alpha: 1.0)
        beamGlowNode?.strokeColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.45)

        hitZoneIndicator?.fillColor = SKColor(red: 0.40, green: 0.90, blue: 1.0, alpha: 0.9)
        hitZoneGlow?.fillColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.15)
    }

    private func applyMissFeedback() {
        beamNode?.strokeColor = SKColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 0.5)
        beamGlowNode?.strokeColor = SKColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 0.12)

        hitZoneIndicator?.fillColor = SKColor(red: 0.80, green: 0.25, blue: 0.25, alpha: 0.7)
        hitZoneGlow?.fillColor = SKColor(red: 0.80, green: 0.25, blue: 0.25, alpha: 0.10)
    }

    // MARK: - Scene Construction

    private func buildBackground() {
        let bg = SKSpriteNode(color: SKColor(red: 0.05, green: 0.03, blue: 0.12, alpha: 1.0),
                              size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        addChild(bg)
    }

    private func buildParticles() {
        guard let emitter = SKEmitterNode.ambientOrbEmitter(sceneSize: size) else { return }
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.zPosition = -5
        addChild(emitter)
    }
}

// MARK: - SKEmitterNode Helpers

private extension SKEmitterNode {

    /// Floating ambient orbs drifting slowly across the background.
    static func ambientOrbEmitter(sceneSize: CGSize) -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 1.5
        emitter.particleLifetime = 8
        emitter.particleLifetimeRange = 3
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 10
        emitter.particleSpeedRange = 6
        emitter.particleAlpha = 0.15
        emitter.particleAlphaRange = 0.1
        emitter.particleAlphaSpeed = -0.02
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleColor = SKColor(red: 0.48, green: 0.34, blue: 0.76, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.particlePositionRange = CGVector(dx: sceneSize.width, dy: sceneSize.height)
        return emitter
    }
}
