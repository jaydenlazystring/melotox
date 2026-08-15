import SpriteKit

// MARK: - MelodyGateSceneDelegate

protocol MelodyGateSceneDelegate: AnyObject {
    func didStart()
    func didComplete()
    func didFail()
}

// MARK: - MelodyGateScene

final class MelodyGateScene: SKScene {

    // MARK: - Configuration

    private let gateDuration: TimeInterval = 60.0
    private let previewWindow: TimeInterval = 5.0
    private let hitTolerance: CGFloat = 85.0
    private let maxMissFrames: Int = 180

    // MARK: - Stream Path

    private var streamPath: StreamPath = .defaultPath()

    // MARK: - State

    private var sceneStartTime: TimeInterval?
    private var isRunning: Bool = false
    private var isWaitingForFirstTouch: Bool = true
    private var holdFrames: Int = 0
    private var missFrames: Int = 0
    private var isTouching: Bool = false
    private var fingerPosition: CGPoint = .zero

    weak var gateDelegate: MelodyGateSceneDelegate?

    /// Target audio loudness (0...1) pushed in from the view model. The scene
    /// smooths toward this each frame so the halo/indicator pulse with the music.
    var audioLevel: CGFloat = 0
    private var smoothedAudioLevel: CGFloat = 0

    // MARK: - Nodes

    private var targetIndicator: SKShapeNode?
    private var targetGlow: SKShapeNode?
    private var targetOuterRing: SKShapeNode?
    private var trailGlowOuter: SKShapeNode?
    private var trailGlowInner: SKShapeNode?
    private var trailCore: SKShapeNode?
    private var trailEmitter: SKEmitterNode?

    // MARK: - Public

    func configure(path: StreamPath) {
        streamPath = path
    }

    func resetSession() {
        removeAllChildren()
        removeAllActions()

        sceneStartTime = nil
        isRunning = false
        isWaitingForFirstTouch = true
        holdFrames = 0
        missFrames = 0
        isTouching = false
        fingerPosition = .zero
        audioLevel = 0
        smoothedAudioLevel = 0

        targetIndicator = nil
        targetGlow = nil
        targetOuterRing = nil
        trailGlowOuter = nil
        trailGlowInner = nil
        trailCore = nil
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
        buildAurora()
        buildTrail()
        buildTarget()
        buildTrailEmitter()
        buildParticles()

        isWaitingForFirstTouch = true
        isRunning = false

        updateTrailPath(elapsed: 0)
    }

    override func update(_ currentTime: TimeInterval) {
        guard isRunning, !isWaitingForFirstTouch else { return }

        if sceneStartTime == nil {
            sceneStartTime = currentTime
        }

        let elapsed = currentTime - (sceneStartTime ?? currentTime)

        // Audio-reactive pulse — smooth toward the latest level for 60fps fluidity.
        smoothedAudioLevel += (audioLevel - smoothedAudioLevel) * 0.2
        targetGlow?.setScale(1.0 + smoothedAudioLevel * 0.7)
        targetIndicator?.setScale(1.0 + smoothedAudioLevel * 0.22)

        if elapsed >= gateDuration {
            isRunning = false
            gateDelegate?.didComplete()
            return
        }

        let pos = streamPath.position(at: elapsed)
        let targetX = pos.x * size.width
        let targetY = pos.y * size.height
        let targetPoint = CGPoint(x: targetX, y: targetY)

        // Smooth movement using lerp for extra fluidity
        if let indicator = targetIndicator {
            let lerpFactor: CGFloat = 0.15
            let smoothX = indicator.position.x + (targetX - indicator.position.x) * lerpFactor
            let smoothY = indicator.position.y + (targetY - indicator.position.y) * lerpFactor
            let smoothPoint = CGPoint(x: smoothX, y: smoothY)

            indicator.position = smoothPoint
            targetGlow?.position = smoothPoint
            targetOuterRing?.position = smoothPoint
            trailEmitter?.position = smoothPoint
        }

        updateTrailPath(elapsed: elapsed)

        // Scoring — use the actual target position for fairness
        if isTouching {
            let dx = fingerPosition.x - targetX
            let dy = fingerPosition.y - targetY
            let distance = sqrt(dx * dx + dy * dy)

            if distance <= hitTolerance {
                holdFrames += 1
                applyHoldFeedback()
            } else {
                missFrames += 1
                applyMissFeedback()
            }
        } else {
            missFrames += 1
            applyMissFeedback()
        }

        if missFrames >= maxMissFrames {
            isRunning = false
            gateDelegate?.didFail()
            return
        }

        let isHolding = isTouching && {
            let dx = fingerPosition.x - targetX
            let dy = fingerPosition.y - targetY
            return sqrt(dx * dx + dy * dy) <= hitTolerance
        }()
        trailEmitter?.particleBirthRate = isHolding ? 20 : 0
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if isWaitingForFirstTouch {
            isWaitingForFirstTouch = false
            isRunning = true
            sceneStartTime = nil
            isTouching = true
            fingerPosition = touch.location(in: self)
            gateDelegate?.didStart()
            return
        }

        guard isRunning else { return }
        isTouching = true
        fingerPosition = touch.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let touch = touches.first else { return }
        fingerPosition = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    // MARK: - Trail Rendering (soft light guide)

    private func buildTrail() {
        // Outermost glow — very wide, faint, dreamy
        let outer = SKShapeNode()
        outer.strokeColor = SKColor(red: 0.45, green: 0.30, blue: 0.90, alpha: 0.06)
        outer.lineWidth = 28.0
        outer.lineCap = .round
        outer.lineJoin = .round
        outer.zPosition = 3
        outer.isAntialiased = true
        addChild(outer)
        trailGlowOuter = outer

        // Inner glow — medium, soft
        let inner = SKShapeNode()
        inner.strokeColor = SKColor(red: 0.40, green: 0.70, blue: 1.0, alpha: 0.12)
        inner.lineWidth = 14.0
        inner.lineCap = .round
        inner.lineJoin = .round
        inner.zPosition = 4
        inner.isAntialiased = true
        addChild(inner)
        trailGlowInner = inner

        // Core line — thin, brighter
        let core = SKShapeNode()
        core.strokeColor = SKColor(red: 0.55, green: 0.40, blue: 1.0, alpha: 0.35)
        core.lineWidth = 3.0
        core.lineCap = .round
        core.lineJoin = .round
        core.zPosition = 5
        core.isAntialiased = true
        addChild(core)
        trailCore = core
    }

    private func updateTrailPath(elapsed: TimeInterval) {
        let path = CGMutablePath()
        let steps = 100

        // Build smooth curve using quad curves
        var points: [CGPoint] = []
        for i in 0...steps {
            let fraction = CGFloat(i) / CGFloat(steps)
            let t = elapsed + Double(fraction) * previewWindow
            let pos = streamPath.position(at: t)
            points.append(CGPoint(x: pos.x * size.width, y: pos.y * size.height))
        }

        guard points.count >= 2 else { return }

        path.move(to: points[0])
        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]
            let midX = (prev.x + curr.x) / 2
            let midY = (prev.y + curr.y) / 2
            path.addQuadCurve(to: CGPoint(x: midX, y: midY), control: prev)
        }
        if let last = points.last {
            path.addLine(to: last)
        }

        trailGlowOuter?.path = path
        trailGlowInner?.path = path
        trailCore?.path = path
    }

    // MARK: - Target Indicator (larger, softer)

    private func buildTarget() {
        // Outer ring — wide and gentle
        let outer = SKShapeNode(circleOfRadius: 44)
        outer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        outer.fillColor = .clear
        outer.strokeColor = SKColor(red: 0.40, green: 0.75, blue: 1.0, alpha: 0.25)
        outer.lineWidth = 1.5
        outer.glowWidth = 8
        outer.zPosition = 11
        addChild(outer)
        targetOuterRing = outer

        let grow = SKAction.scale(to: 1.15, duration: 1.2)
        grow.timingMode = .easeInEaseOut
        let shrink = SKAction.scale(to: 0.9, duration: 1.2)
        shrink.timingMode = .easeInEaseOut
        outer.run(SKAction.repeatForever(SKAction.sequence([grow, shrink])))

        // Glow halo — large, soft
        let glow = SKShapeNode(circleOfRadius: 60)
        glow.position = CGPoint(x: size.width / 2, y: size.height / 2)
        glow.fillColor = SKColor(red: 0.40, green: 0.75, blue: 1.0, alpha: 0.05)
        glow.strokeColor = .clear
        glow.zPosition = 9
        addChild(glow)
        targetGlow = glow

        // Core indicator — bigger for thumb
        let indicator = SKShapeNode(circleOfRadius: 24)
        indicator.position = CGPoint(x: size.width / 2, y: size.height / 2)
        indicator.fillColor = SKColor(red: 0.45, green: 0.80, blue: 1.0, alpha: 0.75)
        indicator.strokeColor = SKColor(red: 0.50, green: 0.35, blue: 1.0, alpha: 0.4)
        indicator.lineWidth = 1.5
        indicator.glowWidth = 12
        indicator.zPosition = 12
        addChild(indicator)
        targetIndicator = indicator
    }

    // MARK: - Trail Emitter

    private func buildTrailEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 0
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 12
        emitter.particleSpeedRange = 6
        emitter.particleAlpha = 0.35
        emitter.particleAlphaSpeed = -0.4
        emitter.particleScale = 0.06
        emitter.particleScaleSpeed = -0.04
        emitter.particleColor = SKColor(red: 0.45, green: 0.80, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.zPosition = 15
        addChild(emitter)
        trailEmitter = emitter
    }

    // MARK: - Visual Feedback

    private func applyHoldFeedback() {
        targetIndicator?.fillColor = SKColor(red: 0.45, green: 0.90, blue: 1.0, alpha: 0.85)
        targetIndicator?.glowWidth = 16
        targetGlow?.fillColor = SKColor(red: 0.40, green: 0.75, blue: 1.0, alpha: 0.10)
        targetOuterRing?.strokeColor = SKColor(red: 0.40, green: 0.85, blue: 1.0, alpha: 0.4)

        trailCore?.strokeColor = SKColor(red: 0.50, green: 0.85, blue: 1.0, alpha: 0.5)
        trailGlowInner?.strokeColor = SKColor(red: 0.40, green: 0.75, blue: 1.0, alpha: 0.18)
        trailGlowOuter?.strokeColor = SKColor(red: 0.45, green: 0.30, blue: 0.90, alpha: 0.10)
    }

    private func applyMissFeedback() {
        targetIndicator?.fillColor = SKColor(red: 0.70, green: 0.25, blue: 0.30, alpha: 0.55)
        targetIndicator?.glowWidth = 8
        targetGlow?.fillColor = SKColor(red: 0.70, green: 0.25, blue: 0.25, alpha: 0.06)
        targetOuterRing?.strokeColor = SKColor(red: 0.70, green: 0.30, blue: 0.30, alpha: 0.25)

        trailCore?.strokeColor = SKColor(red: 0.55, green: 0.40, blue: 1.0, alpha: 0.25)
        trailGlowInner?.strokeColor = SKColor(red: 0.40, green: 0.70, blue: 1.0, alpha: 0.08)
        trailGlowOuter?.strokeColor = SKColor(red: 0.45, green: 0.30, blue: 0.90, alpha: 0.04)
    }

    // MARK: - Aurora

    private func buildAurora() {
        let configs: [(color: SKColor, lineWidth: CGFloat, glowWidth: CGFloat, yOffset: CGFloat, amplitude: CGFloat, speed: TimeInterval, xDrift: CGFloat, zPos: CGFloat)] = [
            // Bottom band — wide, slow, purple
            (
                SKColor(red: 0.45, green: 0.20, blue: 0.85, alpha: 0.06),
                60, 30,
                size.height * 0.25, 40,
                12.0, 30,
                -8
            ),
            // Middle band — medium, cyan-teal
            (
                SKColor(red: 0.20, green: 0.60, blue: 0.80, alpha: 0.05),
                50, 25,
                size.height * 0.50, 50,
                15.0, -25,
                -7
            ),
            // Upper band — narrow, pink-magenta
            (
                SKColor(red: 0.65, green: 0.25, blue: 0.70, alpha: 0.04),
                45, 20,
                size.height * 0.72, 35,
                18.0, 20,
                -6
            ),
            // Top accent — very faint, wide, slow
            (
                SKColor(red: 0.30, green: 0.50, blue: 0.90, alpha: 0.035),
                70, 35,
                size.height * 0.85, 30,
                20.0, -35,
                -6.5
            ),
        ]

        for config in configs {
            let band = createAuroraBand(
                yCenter: config.yOffset,
                amplitude: config.amplitude,
                color: config.color,
                lineWidth: config.lineWidth,
                glowWidth: config.glowWidth
            )
            band.zPosition = config.zPos
            addChild(band)

            // Vertical wave — slow up/down drift
            let moveUp = SKAction.moveBy(x: 0, y: config.amplitude * 0.8, duration: config.speed)
            moveUp.timingMode = .easeInEaseOut
            let moveDown = SKAction.moveBy(x: 0, y: -config.amplitude * 0.8, duration: config.speed)
            moveDown.timingMode = .easeInEaseOut
            band.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))

            // Horizontal drift
            let driftRight = SKAction.moveBy(x: config.xDrift, y: 0, duration: config.speed * 0.7)
            driftRight.timingMode = .easeInEaseOut
            let driftLeft = SKAction.moveBy(x: -config.xDrift, y: 0, duration: config.speed * 0.7)
            driftLeft.timingMode = .easeInEaseOut
            band.run(SKAction.repeatForever(SKAction.sequence([driftRight, driftLeft])))

            // Subtle scale breathing
            let scaleUp = SKAction.scaleX(to: 1.08, y: 1.03, duration: config.speed * 1.2)
            scaleUp.timingMode = .easeInEaseOut
            let scaleDown = SKAction.scaleX(to: 0.95, y: 0.97, duration: config.speed * 1.2)
            scaleDown.timingMode = .easeInEaseOut
            band.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))

            // Gentle alpha pulse
            let fadeIn = SKAction.fadeAlpha(to: 1.2, duration: config.speed * 0.8)
            fadeIn.timingMode = .easeInEaseOut
            let fadeOut = SKAction.fadeAlpha(to: 0.7, duration: config.speed * 0.8)
            fadeOut.timingMode = .easeInEaseOut
            band.run(SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut])))
        }
    }

    private func createAuroraBand(yCenter: CGFloat, amplitude: CGFloat, color: SKColor, lineWidth: CGFloat, glowWidth: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let width = size.width * 1.4  // wider than screen for drift
        let startX = -size.width * 0.2
        let steps = 60

        for i in 0...steps {
            let fraction = CGFloat(i) / CGFloat(steps)
            let x = startX + fraction * width
            // Double sine wave for organic shape
            let y = yCenter
                + sin(fraction * .pi * 2.5) * amplitude
                + sin(fraction * .pi * 1.3 + 0.8) * (amplitude * 0.4)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                // Smooth quad curves
                let prevFraction = CGFloat(i - 1) / CGFloat(steps)
                let prevX = startX + prevFraction * width
                let prevY = yCenter
                    + sin(prevFraction * .pi * 2.5) * amplitude
                    + sin(prevFraction * .pi * 1.3 + 0.8) * (amplitude * 0.4)
                let midX = (prevX + x) / 2
                let midY = (prevY + y) / 2
                path.addQuadCurve(to: CGPoint(x: midX, y: midY), control: CGPoint(x: prevX, y: prevY))
            }
        }

        let band = SKShapeNode()
        band.path = path
        band.strokeColor = color
        band.lineWidth = lineWidth
        band.lineCap = .round
        band.lineJoin = .round
        band.glowWidth = glowWidth
        band.isAntialiased = true
        band.fillColor = .clear
        return band
    }

    // MARK: - Background

    private func buildBackground() {
        let bg = SKSpriteNode(color: SKColor(red: 0.04, green: 0.02, blue: 0.10, alpha: 1.0),
                              size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -10
        addChild(bg)
    }

    private func buildParticles() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 1.2
        emitter.particleLifetime = 10
        emitter.particleLifetimeRange = 4
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 6
        emitter.particleSpeedRange = 4
        emitter.particleAlpha = 0.10
        emitter.particleAlphaRange = 0.06
        emitter.particleAlphaSpeed = -0.01
        emitter.particleScale = 0.18
        emitter.particleScaleRange = 0.12
        emitter.particleColor = SKColor(red: 0.45, green: 0.30, blue: 0.75, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.zPosition = -5
        addChild(emitter)
    }
}
