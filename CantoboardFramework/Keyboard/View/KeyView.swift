//
//  StockboardKey.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/16/21.
//

import Foundation
import UIKit

class KeyView: UIButton {
    private var keyHintLayer: KeyHintLayer?
    private var popupView: KeyPopupView?
    private var isPopupInLongPressMode: Bool?
    
    private var _keyCap: KeyCap = .none
    var keyCap: KeyCap {
        get { _keyCap }
        set {
            if _keyCap != newValue {
                setKeyCap(newValue)
            }
        }
    }
    private var action: KeyboardAction = KeyboardAction.none
    
    var isKeyEnabled: Bool = true {
        didSet {
            setupView()
        }
    }
    
    var selectedAction: KeyboardAction {
        if keyCap.childrenKeyCaps.count > 1 {
            return popupView?.selectedAction ?? action
        } else {
            return action
        }
    }
    
    var hitTestFrame: CGRect?
    
    var isLabelHidden: Bool {
        get { titleLabel?.isHidden ?? true }
        set { titleLabel?.isHidden = newValue }
    }
    
    var hasInputAcceptingPopup: Bool {
        popupView?.keyCaps.count ?? 0 > 1
    }
    
    var heightClearance: CGFloat?
    
    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    init() {
        super.init(frame: .zero)
        setupUIButton()
    }
    
    private func setupUIButton() {
        setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(weight: .light), forImageIn: .normal)
        
        isUserInteractionEnabled = true
        layer.cornerRadius = 5
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shadowColor = ButtonColor.KeyShadowColor.resolvedColor(with: traitCollection).cgColor
        layer.shadowRadius = 0.0
        layer.masksToBounds = false
        layer.cornerRadius = 5
    }
    
    func setKeyCap(_ keyCap: KeyCap) {
        self._keyCap = keyCap
        self.action = keyCap.getAction()
        setupView()
    }
        
    private func setupView() {
        backgroundColor = keyCap.buttonBgColor
        
        let foregroundColor = keyCap.buttonFgColor
        setTitleColor(foregroundColor, for: .normal)
        tintColor = foregroundColor
        
        var maskedCorners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        var shadowOpacity: Float = 1.0
        var buttonHintTitle = keyCap.buttonHint
        
        if !isKeyEnabled {
            setImage(nil, for: .normal)
            setTitle(nil, for: .normal)
            titleLabel?.text = nil
            let backgroundColorAlpha = backgroundColor?.alpha ?? 1
            if case .shift = keyCap {
                // Hide the highlighted color in swipe mode.
                backgroundColor = ButtonColor.SystemKeyBackgroundColor
            }
            backgroundColor = backgroundColor?.withAlphaComponent(backgroundColorAlpha * 0.8)
            shadowOpacity = 0
            buttonHintTitle = nil
        } else if popupView != nil {
            setImage(nil, for: .normal)
            setTitle(nil, for: .normal)
            titleLabel?.text = nil
            backgroundColor = ButtonColor.PopupBackgroundColor
            maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else if let buttonText = keyCap.buttonText {
            setImage(nil, for: .normal)
            setTitle(buttonText, for: .normal)
            titleLabel?.font = keyCap.buttonFont
            titleLabel?.baselineAdjustment = .alignCenters
        } else if let buttonImage = keyCap.buttonImage {
            setImage(buttonImage, for: .normal)
            setTitle(nil, for: .normal)
            titleLabel?.text = nil
        }
        
        setupKeyHint(keyCap, buttonHintTitle, foregroundColor)
        
        layer.maskedCorners = maskedCorners
        layer.shadowOpacity = shadowOpacity
        
        // isUserInteractionEnabled = action == .nextKeyboard
        // layoutPopupView()
        setNeedsLayout()
    }
    
    private func setupKeyHint(_ keyCap: KeyCap, _ buttonHintTitle: String?, _ foregroundColor: UIColor) {
        if let buttonHintTitle = buttonHintTitle {
            if keyHintLayer == nil {
                let keyHintLayer = KeyHintLayer()
                keyHintLayer.foregroundColor = keyCap.buttonFgColor.resolvedColor(with: traitCollection).cgColor
                self.keyHintLayer = keyHintLayer
                layer.addSublayer(keyHintLayer)
                keyHintLayer.layoutSublayers()
            }
            self.keyHintLayer?.setup(keyCap, buttonHintTitle)
        } else {
            keyHintLayer?.removeFromSuperlayer()
            keyHintLayer = nil
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let hitTestFrame = hitTestFrame {
            if isHidden || window == nil { return false }
            // Translate hit test frame to hit test bounds.
            let hitTestBounds = hitTestFrame.offsetBy(dx: -frame.origin.x, dy: -frame.origin.y)
            return hitTestBounds.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.shadowColor = ButtonColor.KeyShadowColor.resolvedColor(with: traitCollection).cgColor
        
        if let keyHintLayer = keyHintLayer {
            keyHintLayer.foregroundColor = keyCap.buttonFgColor.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutPopupView()
        keyHintLayer?.isHidden = popupView != nil
        keyHintLayer?.layout()
    }
    
    private func layoutPopupView() {
        guard let superview = superview, let popupView = popupView else { return }
        
        popupView.heightClearance = heightClearance
        popupView.leftClearance = frame.minX - superview.bounds.minX
        popupView.rightClearance = superview.bounds.maxX - frame.maxX
        popupView.layoutView()
        
        let popupViewSize = popupView.bounds.size
        let layoutOffsetX = popupView.leftAnchorX
        var popupViewFrame = CGRect(origin: CGPoint(x: -layoutOffsetX, y: -popupViewSize.height), size: popupViewSize)
        let popupViewFrameInSuperview = convert(popupViewFrame, to: superview)
        
        if popupViewFrameInSuperview.minX < 0 {
            popupViewFrame = popupViewFrame.offsetBy(dx: -popupViewFrameInSuperview.minX, dy: 0)
        }/* TODO Fix this to make sure popup view isn't OOB.
         else if popupViewFrameInSuperview.maxX > super.bounds.maxX {
            popupViewFrame = popupViewFrame.offsetBy(dx: -popupViewFrameInSuperview.maxX - super.bounds.maxX, dy: 0)
        }*/
        
        popupView.frame = popupViewFrame
    }
}

extension KeyView {
    // Forward all touch events to the superview.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesCancelled(touches, with: event)
    }
}

extension KeyView {
    func keyTouchBegan() {
        updatePopup(isLongPress: false)
    }
    
    func keyTouchMoved(_ touch: UITouch) {
        popupView?.updateSelectedAction(touch)
    }
    
    func keyTouchEnded() {
        popupView?.removeFromSuperview()
        popupView = nil
        
        isPopupInLongPressMode = nil
        
        // Restore lables and rounded corners.
        setupView()
    }
    
    func keyLongPressed() {
        updatePopup(isLongPress: true)
    }
    
    private func updatePopup(isLongPress: Bool) {
        guard keyCap.hasPopup else { return }
        
        // Special case, do not show "enhance" keycap of the emoji button.
        if keyCap == .keyboardType(.emojis) && !isLongPress {
            return
        }
                
        createPopupViewIfNecessary()
        guard let popup = popupView else { return }
        guard isLongPress != isPopupInLongPressMode else { return }
        
        let popupDirection = computePopupDirection()
        let keyCaps = computeKeyCap(isLongPress: isLongPress)
        popup.setup(keyCaps: keyCaps, direction: popupDirection)
        
        isPopupInLongPressMode = isLongPress
        setupView()
    }
    
    private func createPopupViewIfNecessary() {
        if popupView == nil {
            let popup = KeyPopupView()
            addSubview(popup)
            self.popupView = popup
        }
    }
    
    private func computePopupDirection() -> KeyPopupView.PopupDirection {
        guard let superview = superview else { return .middle }

        let keyViewFrame = convert(bounds, to: superview)
        if keyViewFrame.minX < LayoutConstants.forMainScreen.keyButtonWidth / 2 {
            return .right
        }
        
        if superview.bounds.width - keyViewFrame.maxX < LayoutConstants.forMainScreen.keyButtonWidth / 2 {
            return .left
        }
        
        let isKeyOnTheLeft = keyViewFrame.midX / superview.bounds.width <= 0.5
        return isKeyOnTheLeft ? .middle : .middleExtendLeft
    }
    
    private func computeKeyCap(isLongPress: Bool) -> [KeyCap] {
        if isLongPress {
            return keyCap.childrenKeyCaps
        } else {
            return [keyCap]
        }
    }
}
