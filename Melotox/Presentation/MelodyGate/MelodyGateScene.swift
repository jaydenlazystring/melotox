import SpriteKit

// MARK: - MelodyGateSceneDelegate

/// Callback interface for melody-gate completion / failure.
protocol MelodyGateSceneDelegate: AnyObject {
    func didComplete()
    func didFail()
}

// MARK: - MelodyGateScene

/// A minimal SpriteKit rhythm scene.
///
/// Notes (glowing orbs) fall down a single centre lane. The player taps when
/// a note overlaps the hit-zone bar near the bottom of the screen.
/// The scene does **not** manage audio -- that responsibility belongs to the
/// owning ViewModel.
final class MelodyGateScene: SKScene {

    // MARK: - Configuration

    /// Maximum allowed misses before the gate fails.
    private let maxMisses: Int = 2

    /// Seconds a note takes to fall from spawn to off-screen.
    private let noteFallDuration: TimeInterval = 3.0

    /// Vertical fraction (from bottom) where the hit-zone sits.
    private let hitZoneFraction: CGFloat = 0.15

    /// Vertical tolerance (points) around the hit-zone centre.
    private let hitZoneTolerance: CGFloat = 40.0

    // MARK: - State

    private var notePattern: NotePattern = .defaultPattern()
    private var noteIndex: Int = 0
    private var missCount: Int = 0
    private var sceneStartTime: TimeInterval?
    private var isRunning: Bool = false

    /// Currently live (falling) note nodes keyed by their unique name.
    private var activeNotes: [String: SKNode] = [:]

    weak var gateDelegate: MelodyGateSceneDelegate?

    // MARK: - Computed

    private var totalNotes: Int { notePattern.count }

    private var hitZoneY: CGFloat {
        size.height * hitZoneFraction
    }

    // MARK: - Public Setup

    /// Call before presenting the scene to supply a custom pattern.
    func configure(pattern: NotePattern) {
        notePattern = pattern
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0)

        buildBackground()
        buildHitZone()
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
        spawnNotesIfNeeded(elapsed: elapsed)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else { return }

        // Find the first active note inside the hit zone.
        var hitNote: String?
        for (name, node) in activeNotes {
            let nodeY = node.position.y
            if abs(nodeY - hitZoneY) <= hitZoneTolerance {
                hitNote = name
                break
            }
        }

        if let name = hitNote {
            burstNote(named: name)
        } else {
            // Tap with nothing in the zone counts as a miss.
            registerMiss()
        }
    }

    // MARK: - Note Spawning

    private func spawnNotesIfNeeded(elapsed: TimeInterval) {
        while noteIndex < totalNotes {
            let spawnTime = notePattern.notes[noteIndex]
            guard elapsed >= spawnTime else { break }
            spawnNote(index: noteIndex)
            noteIndex += 1
        }
    }

    private func spawnNote(index: Int) {
        let name = "note_\(index)"

        let note = SKShapeNode(circleOfRadius: 22)
        note.name = name
        note.position = CGPoint(x: 0, y: size.height + 30)
        note.fillColor = SKColor(red: 0.58, green: 0.44, blue: 0.86, alpha: 1.0)  // purple
        note.strokeColor = SKColor(red: 0.72, green: 0.58, blue: 1.0, alpha: 0.6)
        note.lineWidth = 3
        note.glowWidth = 8
        note.zPosition = 10

        addChild(note)
        activeNotes[name] = note

        // Fall action: move to below the hit zone, then mark as missed and remove.
        let destination = CGPoint(x: 0, y: -40)
        let fall = SKAction.move(to: destination, duration: noteFallDuration)

        let cleanup = SKAction.run { [weak self] in
            self?.handleNoteMissedByFalling(name: name)
        }

        let remove = SKAction.removeFromParent()
        note.run(SKAction.sequence([fall, cleanup, remove]))
    }

    // MARK: - Hit / Miss Logic

    private func burstNote(named name: String) {
        guard let node = activeNotes.removeValue(forKey: name) else { return }
        node.removeAllActions()

        // Burst animation.
        let scaleUp = SKAction.scale(to: 2.5, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        let burst = SKAction.group([scaleUp, fadeOut])
        let remove = SKAction.removeFromParent()

        node.run(SKAction.sequence([burst, remove]))

        // Emit a small particle burst.
        if let particles = SKEmitterNode.noteBurstEmitter() {
            particles.position = node.position
            particles.zPosition = 15
            addChild(particles)
            particles.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.6),
                SKAction.removeFromParent()
            ]))
        }

        checkCompletion()
    }

    private func handleNoteMissedByFalling(name: String) {
        guard activeNotes.removeValue(forKey: name) != nil else { return }
        registerMiss()
    }

    private func registerMiss() {
        missCount += 1
        pulseHitZoneRed()

        if missCount > maxMisses {
            isRunning = false
            gateDelegate?.didFail()
        } else {
            checkCompletion()
        }
    }

    private func checkCompletion() {
        // All notes have been spawned and none remain active.
        guard noteIndex >= totalNotes, activeNotes.isEmpty else { return }
        isRunning = false
        gateDelegate?.didComplete()
    }

    // MARK: - Scene Construction

    private func buildBackground() {
        let bg = SKSpriteNode(color: SKColor(red: 0.05, green: 0.03, blue: 0.12, alpha: 1.0),
                              size: size)
        bg.position = CGPoint(x: 0, y: size.height / 2)
        bg.zPosition = -10
        addChild(bg)
    }

    private func buildHitZone() {
        let bar = SKShapeNode(rectOf: CGSize(width: size.width * 0.6, height: 4),
                              cornerRadius: 2)
        bar.name = "hitZone"
        bar.position = CGPoint(x: 0, y: hitZoneY)
        bar.fillColor = SKColor(red: 0.72, green: 0.58, blue: 1.0, alpha: 0.5)
        bar.strokeColor = .clear
        bar.glowWidth = 6
        bar.zPosition = 5

        // Subtle breathing pulse.
        let grow = SKAction.scaleX(to: 1.05, y: 1.0, duration: 1.2)
        let shrink = SKAction.scaleX(to: 0.95, y: 1.0, duration: 1.2)
        bar.run(SKAction.repeatForever(SKAction.sequence([grow, shrink])))

        addChild(bar)
    }

    private func buildParticles() {
        guard let emitter = SKEmitterNode.ambientOrbEmitter(sceneSize: size) else { return }
        emitter.position = CGPoint(x: 0, y: size.height / 2)
        emitter.zPosition = -5
        addChild(emitter)
    }

    // MARK: - Visual Feedback

    private func pulseHitZoneRed() {
        guard let bar = childNode(withName: "hitZone") as? SKShapeNode else { return }
        let original = bar.fillColor
        let flash = SKAction.run { bar.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 0.7) }
        let wait = SKAction.wait(forDuration: 0.25)
        let restore = SKAction.run { bar.fillColor = original }
        bar.run(SKAction.sequence([flash, wait, restore]))
    }
}

// MARK: - SKEmitterNode Helpers

private extension SKEmitterNode {

    /// Small burst emitted when a note is successfully tapped.
    static func noteBurstEmitter() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 40
        emitter.numParticlesToEmit = 12
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 30
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.6
        emitter.particleScale = 0.08
        emitter.particleScaleSpeed = -0.1
        emitter.particleColor = SKColor(red: 0.72, green: 0.58, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        return emitter
    }

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
