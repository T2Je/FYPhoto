//
//  FGProgressView.swift
//  FGBase
//
//  Created by kun wang on 2019/09/05.
//

import UIKit

class BaseProgressLayer: CALayer {
    var progressTintColor = UIColor.white
    var borderTintColor = UIColor.white
    var progressBackgroundColor = UIColor.white
    var progress: CGFloat = 0.0

    var progressBorderWidth: CGFloat = 0
    var progressRadius: CGFloat = 4

    override func draw(in ctx: CGContext) {
        let borderRect = bounds.insetBy(dx: progressBorderWidth, dy: progressBorderWidth)
        //draw border
        if progressBorderWidth > 0 {
            ctx.setLineWidth(progressBorderWidth)
            ctx.setStrokeColor(borderTintColor.cgColor)
            drawRectangle(in: ctx, in: borderRect, withRadius: progressRadius - progressBorderWidth)
            ctx.strokePath()
        }

        ctx.setFillColor(progressTintColor.cgColor)
        let fixedProgressRadius = progressRadius - 3 * progressBorderWidth
        var progressRect = borderRect.insetBy(dx: 2 * progressBorderWidth, dy: 2 * progressBorderWidth)
        progressRect.size.width = progress * progressRect.size.width
        drawRectangle(in: ctx, in: progressRect, withRadius: fixedProgressRadius)
        ctx.fillPath()

        ctx.setFillColor(progressBackgroundColor.cgColor)
        var progressBackgroundRect = progressRect
        progressBackgroundRect.size.width = borderRect.size.width - 4 * progressBorderWidth - progressRect.size.width
        progressBackgroundRect.origin.x = progressRect.origin.x + progressRect.size.width
        drawProgressBackgroundRectangle(in: ctx, in: progressBackgroundRect, withRadius: fixedProgressRadius)
        ctx.fillPath()
    }

    func drawRectangle(in context: CGContext, in rect: CGRect, withRadius radius: CGFloat) {
        context.beginPath()
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + radius))
        context.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height - radius))
        context.addArc(center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + rect.size.height - radius), radius: radius, startAngle: .pi, endAngle: .pi / 2, clockwise: true)

        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + rect.size.height))
        context.addArc(center: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + rect.size.height - radius), radius: radius, startAngle: .pi / 2, endAngle: 0.0, clockwise: true)

        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + radius))
        context.addArc(center: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + radius), radius: radius, startAngle: 0.0, endAngle: -.pi / 2, clockwise: true)

        context.addLine(to: CGPoint(x: rect.origin.x + radius, y: rect.origin.y))
        context.addArc(center: CGPoint(x: rect.origin.x + radius, y: rect.origin.y + radius), radius: radius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: true)
        context.closePath()
    }

    func drawProgressBackgroundRectangle(in context: CGContext, in rect: CGRect, withRadius radius: CGFloat) {
        context.beginPath()
        context.move(to: CGPoint(x: rect.origin.x - radius, y: rect.origin.y))
        context.addArc(center: CGPoint(x: rect.origin.x - radius, y: rect.origin.y + radius),
                       radius: radius,
                       startAngle: 3 * .pi / 2,
                       endAngle: 2 * .pi,
                       clockwise: false)
        context.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height - radius))

        context.addArc(center: CGPoint(x: rect.origin.x - radius, y: rect.origin.y + rect.size.height - radius),
                       radius: radius,
                       startAngle: 0.0,
                       endAngle: .pi / 2,
                       clockwise: false)
        context.move(to: CGPoint(x: rect.origin.x - radius, y: rect.origin.y + rect.size.height))
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + rect.size.height))

        context.addArc(center: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + rect.size.height - radius),
                       radius: radius,
                       startAngle: .pi / 2,
                       endAngle: 0.0,
                       clockwise: true)
        context.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + radius))

        context.addArc(center: CGPoint(x: rect.origin.x + rect.size.width - radius, y: rect.origin.y + radius),
                       radius: radius,
                       startAngle: 2 * .pi,
                       endAngle: 3 * .pi / 2,
                       clockwise: true)
        context.addLine(to: CGPoint(x: rect.origin.x - radius, y: rect.origin.y))
        context.closePath()
    }
}

@objc public class FGProgressView: UIView {
    @objc public var progressTintColor: UIColor {
        get {
            return progressLayer.progressTintColor
        }
        set {
            progressLayer.progressTintColor = newValue
            setNeedsDisplay()
        }
    }

    @objc public var borderTintColor: UIColor  {
        get {
            return progressLayer.borderTintColor
        }
        set {
            progressLayer.borderTintColor = newValue
            setNeedsDisplay()
        }
    }

    @objc public var progressBackgroundColor: UIColor {
        get {
            return progressLayer.progressBackgroundColor
        }
        set {
            progressLayer.progressBackgroundColor = newValue
            setNeedsDisplay()
        }
    }

    @objc public var progress: CGFloat {
        get {
            return progressLayer.progress
        }
        set {
            setProgress(newValue, animated: false)
        }
    }

    @objc public var progressRadius: CGFloat {
        get {
            return progressLayer.progressRadius
        }
        set {
            progressLayer.progressRadius = newValue
        }
    }

    @objc public var progressBorderWidth: CGFloat {
        get {
            return progressLayer.progressBorderWidth
        }
        set {
            progressLayer.progressBorderWidth = newValue
        }
    }

    @objc public var showPluse: Bool = false {
        didSet {
            plusView.removeFromSuperview()
            plusView.layer.removeAllAnimations()
            if showPluse {
                addSubview(plusView)
                pluseAnimation(with: progress)
            }
        }
    }

    fileprivate func initialize() {
        backgroundColor = .clear
    }

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
        setProgress(0, animated: false)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        self.progressLayer.contentsScale = window?.screen.scale ?? 1
    }

    public override class var layerClass: AnyClass {
        return BaseProgressLayer.self
    }

    var progressLayer: BaseProgressLayer {
        if let player = self.layer as? BaseProgressLayer {
            return player
        } else {
            fatalError()
        }
    }

    @objc public func setProgress(_ progress: CGFloat, animated: Bool) {
        progressLayer.removeAnimation(forKey: "progress")
        if animated {
            progressAnimation(with: progress)
        } else {

        }
        progressLayer.setNeedsDisplay()
        let pinnedProgress = min(max(progress, 0.0), 1.0)
        progressLayer.progress = pinnedProgress

        plusView.layer.removeAllAnimations()
        if showPluse {
            pluseAnimation(with: progress)
        }
    }

    func pluseAnimation(with progress: CGFloat) {
        let progressRect = bounds.insetBy(dx: 3 * progressBorderWidth, dy: 3 * progressBorderWidth)
        plusView.frame = CGRect(x: progress * progressRect.size.width - 100, y: (self.bounds.size.height - progressRect.size.height)/2, width: 100, height: progressRect.size.height)

        let pluseAnimation = CABasicAnimation(keyPath: "opacity")
        pluseAnimation.fromValue = NSNumber(value: 1.0)
        pluseAnimation.toValue = NSNumber(value: 0.1)
        pluseAnimation.duration = 1
        pluseAnimation.autoreverses = true
        pluseAnimation.repeatCount = Float(INT32_MAX)
        plusView.layer.add(pluseAnimation, forKey: "pluse")
    }

    func progressAnimation(with progress: CGFloat) {
        let pinnedProgress = min(max(progress, 0.0), 1.0)
        let animation = CABasicAnimation(keyPath: "progress")
        animation.duration = CFTimeInterval(abs(Float(self.progress - pinnedProgress)) + 0.1)
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fromValue = NSNumber(value: Float(self.progress))
        animation.toValue = NSNumber(value: Float(pinnedProgress))
        progressLayer.add(animation, forKey: "progress")
    }

    lazy var plusView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.backgroundColor = .clear
        view.image = "fg_ic_progress_shine".baseImage
        return view
    }()
}
