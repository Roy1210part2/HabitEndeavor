import SwiftUI
import SceneKit

#if os(iOS)
private typealias PlatformColor = UIColor
#else
private typealias PlatformColor = NSColor
#endif

// MARK: - Public View

struct GlobeSceneView: View {
    let ownedCodes: Set<String>

    var body: some View {
        SceneView(
            scene: GlobeSceneBuilder.scene(ownedCodes: ownedCodes),
            options: [.allowsCameraControl, .autoenablesDefaultLighting]
        )
        .id(ownedCodes.sorted().joined()) // 구매 변경 시 씬 재생성
    }
}

// MARK: - Scene Builder

enum GlobeSceneBuilder {

    static func scene(ownedCodes: Set<String>) -> SCNScene {
        let scene = SCNScene()

        // 우주 배경
        scene.background.contents = PlatformColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1)

        // 별 필드
        let starsNode = makeStars()
        scene.rootNode.addChildNode(starsNode)

        // 지구 본체 (파란 해양)
        let globe = makeGlobe()
        scene.rootNode.addChildNode(globe)

        // 자동 회전 (30초/바퀴)
        let spin = CABasicAnimation(keyPath: "eulerAngles.y")
        spin.fromValue = 0
        spin.toValue = Float.pi * 2
        spin.duration = 30
        spin.repeatCount = .greatestFiniteMagnitude
        globe.addAnimation(spin, forKey: "autoSpin")

        // 대기권 글로우
        let atmosphere = makeAtmosphere()
        scene.rootNode.addChildNode(atmosphere)

        // 국가 마커
        for country in allCountries {
            let isOwned = ownedCodes.contains(country.id)
            let marker = makeMarker(country: country, isOwned: isOwned)
            globe.addChildNode(marker)

            // 구매 직후 국가는 pulse 애니메이션
            if isOwned {
                let pulse = CABasicAnimation(keyPath: "scale")
                pulse.fromValue = SCNVector3(1, 1, 1)
                pulse.toValue   = SCNVector3(1.5, 1.5, 1.5)
                pulse.duration  = 1.2
                pulse.autoreverses = true
                pulse.repeatCount = .greatestFiniteMagnitude
                pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                marker.addAnimation(pulse, forKey: "pulse")
            }
        }

        // 태양광 (측면에서 비춤)
        let sunNode = SCNNode()
        sunNode.light = {
            let l = SCNLight()
            l.type = .directional
            l.intensity = 1200
            l.color = PlatformColor.white
            return l
        }()
        sunNode.position = SCNVector3(4, 3, 4)
        scene.rootNode.addChildNode(sunNode)

        // 부드러운 주변광
        let ambientNode = SCNNode()
        ambientNode.light = {
            let l = SCNLight()
            l.type = .ambient
            l.intensity = 300
            l.color = PlatformColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1)
            return l
        }()
        scene.rootNode.addChildNode(ambientNode)

        // 카메라
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.zNear = 0.1
        cam.position = SCNVector3(0, 0, 2.8)
        scene.rootNode.addChildNode(cam)

        return scene
    }

    // MARK: - Globe

    private static func makeGlobe() -> SCNNode {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 72

        let mat = SCNMaterial()
        // 깊은 바다색 기반
        mat.diffuse.contents  = PlatformColor(red: 0.06, green: 0.18, blue: 0.38, alpha: 1)
        mat.specular.contents = PlatformColor(white: 0.4, alpha: 1)
        mat.shininess = 0.6
        mat.lightingModel = .phong
        sphere.materials = [mat]

        return SCNNode(geometry: sphere)
    }

    // MARK: - Atmosphere

    private static func makeAtmosphere() -> SCNNode {
        let sphere = SCNSphere(radius: 1.06)
        sphere.segmentCount = 48

        let mat = SCNMaterial()
        mat.diffuse.contents  = PlatformColor.clear
        mat.emission.contents = PlatformColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 0.1)
        mat.isDoubleSided = true
        mat.lightingModel = .constant
        mat.writesToDepthBuffer = false
        mat.blendMode = .add
        sphere.materials = [mat]

        return SCNNode(geometry: sphere)
    }

    // MARK: - Stars

    private static func makeStars() -> SCNNode {
        let root = SCNNode()
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let dot = SCNSphere(radius: CGFloat.random(in: 0.004...0.012, using: &rng))
            dot.segmentCount = 4
            let m = SCNMaterial()
            let brightness = Float.random(in: 0.5...1.0, using: &rng)
            m.emission.contents = PlatformColor(white: CGFloat(brightness), alpha: 1)
            m.lightingModel = .constant
            dot.materials = [m]

            let node = SCNNode(geometry: dot)
            let r: Double = 6.0
            let theta = Double.random(in: 0...(2 * .pi), using: &rng)
            let phi   = Double.random(in: 0...(.pi), using: &rng)
            node.position = SCNVector3(
                Float(r * sin(phi) * cos(theta)),
                Float(r * cos(phi)),
                Float(r * sin(phi) * sin(theta))
            )
            root.addChildNode(node)
        }
        return root
    }

    // MARK: - Country Marker

    private static func makeMarker(country: Country, isOwned: Bool) -> SCNNode {
        let radius: CGFloat = isOwned ? 0.05 : 0.02
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = isOwned ? 16 : 8

        let mat = SCNMaterial()
        mat.lightingModel = .constant

        if isOwned {
            let c = continentColor(country.continent)
            mat.diffuse.contents  = c
            mat.emission.contents = c.withAlphaComponent(0.7)
        } else {
            mat.diffuse.contents  = PlatformColor(white: 0.55, alpha: 0.3)
            mat.emission.contents = PlatformColor(white: 0.2,  alpha: 0.2)
        }
        sphere.materials = [mat]

        let node = SCNNode(geometry: sphere)
        node.position = globePosition(
            lat: country.coordinate.lat,
            lon: country.coordinate.lon,
            radius: 1.0 + Double(radius) * 0.3
        )
        node.name = country.id
        return node
    }

    // MARK: - Helpers

    private static func globePosition(lat: Double, lon: Double, radius: Double) -> SCNVector3 {
        let latR = lat * .pi / 180
        let lonR = lon * .pi / 180
        return SCNVector3(
            Float(radius * cos(latR) * sin(lonR)),
            Float(radius * sin(latR)),
            Float(radius * cos(latR) * cos(lonR))
        )
    }

    private static func continentColor(_ continent: Country.Continent) -> PlatformColor {
        switch continent {
        case .asia:         return PlatformColor(red: 1.00, green: 0.80, blue: 0.20, alpha: 1) // 황금
        case .europe:       return PlatformColor(red: 0.40, green: 0.70, blue: 1.00, alpha: 1) // 파랑
        case .northAmerica: return PlatformColor(red: 1.00, green: 0.40, blue: 0.40, alpha: 1) // 빨강
        case .southAmerica: return PlatformColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1) // 주황
        case .africa:       return PlatformColor(red: 0.35, green: 0.90, blue: 0.45, alpha: 1) // 초록
        case .oceania:      return PlatformColor(red: 0.35, green: 0.90, blue: 0.90, alpha: 1) // 청록
        }
    }
}

#Preview {
    GlobeSceneView(ownedCodes: ["KR", "JP", "US", "DE", "AU"])
        .frame(height: 320)
}
