#!/usr/bin/env swift
import Cocoa
import Foundation

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "./ClaudeCodeManager/Resources/Assets.xcassets/AppIcon.appiconset"

let iconSpecs: [(String, Int)] = [
    ("icon_16x16",     16),
    ("icon_16x16@2x",  32),
    ("icon_32x32",     32),
    ("icon_32x32@2x",  64),
    ("icon_128x128",   128),
    ("icon_128x128@2x",256),
    ("icon_256x256",   256),
    ("icon_256x256@2x",512),
    ("icon_512x512",   512),
    ("icon_512x512@2x",1024),
]

func gearPath(cx: CGFloat, cy: CGFloat,
              outerR: CGFloat, innerR: CGFloat,
              holeR: CGFloat, teeth: Int) -> NSBezierPath {

    let path = NSBezierPath()
    let step = CGFloat.pi * 2.0 / CGFloat(teeth)
    let half = step * 0.30
    let ramp = step * 0.07
    let startAngle = -CGFloat.pi / 2.0

    for i in 0..<teeth {
        let base = startAngle + CGFloat(i) * step
        let angles: [CGFloat] = [
            base - half,
            base - half + ramp,
            base + half - ramp,
            base + half,
        ]
        let radii: [CGFloat] = [innerR, outerR, outerR, innerR]

        for (j, (angle, r)) in zip(angles, radii).enumerated() {
            let pt = NSPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            if i == 0 && j == 0 { path.move(to: pt) } else { path.line(to: pt) }
        }
        // Arc connecting teeth on inner circle
        let arcStart = (base + half) * 180.0 / .pi
        let arcEnd   = (base + step - half) * 180.0 / .pi
        path.appendArc(withCenter: NSPoint(x: cx, y: cy),
                       radius: innerR,
                       startAngle: arcStart,
                       endAngle: arcEnd,
                       clockwise: false)
    }
    path.close()

    // Center hole (drawn as subpath; use even-odd fill rule)
    let hole = NSBezierPath(ovalIn: NSRect(x: cx - holeR, y: cy - holeR,
                                           width: holeR * 2, height: holeR * 2))
    path.append(hole)
    return path
}

func makeIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))

    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // --- Rounded rect clip ---
    let radius = s * 0.2232
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s),
                               xRadius: radius, yRadius: radius)
    bgPath.setClip()

    // --- Background gradient (deep indigo → near-black) ---
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors: [CGColor] = [
        CGColor(red: 0.11, green: 0.09, blue: 0.25, alpha: 1),
        CGColor(red: 0.05, green: 0.04, blue: 0.12, alpha: 1),
    ]
    let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors as CFArray, locations: [0, 1])!
    let cx = s * 0.5, cy = s * 0.5
    ctx.drawLinearGradient(bgGrad,
                           start: CGPoint(x: 0, y: s),
                           end:   CGPoint(x: s, y: 0),
                           options: [])

    // --- Purple glow behind gear ---
    let glowColors: [CGColor] = [
        CGColor(red: 0.42, green: 0.28, blue: 0.82, alpha: 0.35),
        CGColor(red: 0.42, green: 0.28, blue: 0.82, alpha: 0.00),
    ]
    let glowGrad = CGGradient(colorsSpace: colorSpace,
                               colors: glowColors as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glowGrad,
                           startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                           endCenter:   CGPoint(x: cx, y: cy), endRadius: s * 0.45,
                           options: [])

    // --- Gear shadow (soft purple glow) ---
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: s * 0.06,
                  color: CGColor(red: 0.55, green: 0.40, blue: 1.0, alpha: 0.7))

    let gear = gearPath(cx: cx, cy: cy,
                        outerR: s * 0.355,
                        innerR: s * 0.265,
                        holeR:  s * 0.155,
                        teeth: 10)
    gear.windingRule = .evenOdd
    NSColor(red: 0.87, green: 0.86, blue: 0.96, alpha: 1.0).setFill()
    gear.fill()
    ctx.restoreGState()

    // --- </> text ---
    let fontSize = max(s * 0.148, 6)
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
    let teal = NSColor(red: 0.08, green: 0.88, blue: 0.72, alpha: 1.0)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: teal]
    let label = NSAttributedString(string: "</>", attributes: attrs)
    let lsz = label.size()
    label.draw(at: NSPoint(x: cx - lsz.width / 2, y: cy - lsz.height / 2))

    // --- Teal dot accent (bottom-right) ---
    if size >= 32 {
        let dotR = s * 0.055
        let dotX = cx + s * 0.255
        let dotY = cy - s * 0.255
        let dotRect = NSRect(x: dotX - dotR, y: dotY - dotR, width: dotR * 2, height: dotR * 2)
        NSColor(red: 0.08, green: 0.88, blue: 0.72, alpha: 1.0).setFill()
        NSBezierPath(ovalIn: dotRect).fill()
    }

    image.unlockFocus()
    return image
}

// --- Generate ---
for (name, pixels) in iconSpecs {
    let img = makeIcon(size: pixels)
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("✗ \(name).png — failed to encode")
        continue
    }
    let path = "\(outputDir)/\(name).png"
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("✓ \(name).png  (\(pixels)px)")
    } catch {
        print("✗ \(name).png — \(error.localizedDescription)")
    }
}
print("\nIcons saved to: \(outputDir)")
