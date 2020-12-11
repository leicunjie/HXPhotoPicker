//
//  HXPHPickerViewCell.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/29.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit
import Photos

protocol HXPHPickerViewCellDelegate: NSObjectProtocol {
    
    func cellDidSelectControlClick(_ cell: HXPHPickerMultiSelectViewCell, isSelected: Bool)
    
}

class HXPHPickerViewCell: UICollectionViewCell {
    
    weak var delegate: HXPHPickerViewCellDelegate?
    var config: HXPHPhotoListCellConfiguration? {
        didSet {
            backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
        }
    }
    lazy var imageView: UIImageView = {
        let imageView = UIImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.addSublayer(assetTypeMaskLayer)
        return imageView
    }()
    lazy var assetTypeMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.contentsScale = UIScreen.main.scale
        let blackColor = UIColor.black
        layer.colors = [blackColor.withAlphaComponent(0).cgColor,
                        blackColor.withAlphaComponent(0.15).cgColor,
                        blackColor.withAlphaComponent(0.35).cgColor,
                        blackColor.withAlphaComponent(0.6).cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        layer.locations = [0.15, 0.35, 0.6, 0.9]
        layer.borderWidth = 0.0
        layer.isHidden = true
        return layer
    }()
    lazy var assetTypeLb: UILabel = {
        let assetTypeLb = UILabel.init()
        assetTypeLb.font = UIFont.hx_mediumPingFang(size: 14)
        assetTypeLb.textColor = .white
        assetTypeLb.textAlignment = .right
        return assetTypeLb
    }()
    lazy var videoIcon: UIImageView = {
        let videoIcon = UIImageView.init(image: UIImage.hx_named(named: "hx_picker_cell_video_icon"))
        videoIcon.hx_size = videoIcon.image?.size ?? CGSize.zero
        return videoIcon
    }()
    
    lazy var disableMaskLayer: CALayer = {
        let disableMaskLayer = CALayer.init()
        disableMaskLayer.backgroundColor = UIColor.white.withAlphaComponent(0.6).cgColor
        disableMaskLayer.frame = bounds
        disableMaskLayer.isHidden = true
        return disableMaskLayer
    }()
    var requestID: PHImageRequestID?
    var photoAsset: HXPHAsset? {
        didSet {
            switch photoAsset?.mediaSubType {
            case .imageAnimated:
                assetTypeLb.text = "GIF"
                assetTypeMaskLayer.isHidden = false
                break
            case .livePhoto:
                assetTypeLb.text = "Live"
                assetTypeMaskLayer.isHidden = false
                break
            case .video, .localVideo:
                assetTypeLb.text = photoAsset?.videoTime
                assetTypeMaskLayer.isHidden = false
                break
            default:
                assetTypeLb.text = nil
                assetTypeMaskLayer.isHidden = true
            }
            videoIcon.isHidden = photoAsset?.mediaType != .video
            weak var weakSelf = self
            requestID = photoAsset?.requestThumbnailImage(completion: { (image, photoAsset, info) in
                if photoAsset == weakSelf?.photoAsset && image != nil {
                    if !(weakSelf?.firstLoadCompletion ?? true) {
                        weakSelf?.isHidden = false
                        weakSelf?.firstLoadCompletion = true
                    }
                    weakSelf?.imageView.image = image
                    if !HXPHAssetManager.assetDownloadIsDegraded(for: info) {
                        weakSelf?.requestID = nil
                    }
                }
            })
        }
    }
    
    var canSelect = true {
        didSet {
            disableMaskLayer.isHidden = canSelect
        }
    }
    private var firstLoadCompletion: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initView() {
        isHidden = true
        contentView.addSubview(imageView)
        contentView.addSubview(assetTypeLb)
        contentView.addSubview(videoIcon)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    func cancelRequest() {
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
        disableMaskLayer.frame = imageView.bounds
        assetTypeMaskLayer.frame = CGRect(x: 0, y: imageView.hx_height - 25, width: hx_width, height: 25)
        assetTypeLb.frame = CGRect(x: 0, y: hx_height - 19, width: hx_width - 5, height: 18)
        videoIcon.hx_x = 5
        videoIcon.hx_y = hx_height - videoIcon.hx_height - 5
        assetTypeLb.hx_centerY = videoIcon.hx_centerY
    }
}

class HXPHPickerMultiSelectViewCell : HXPHPickerViewCell {
    
    lazy var selectControl: HXPHPickerCellSelectBoxControl = {
        let selectControl = HXPHPickerCellSelectBoxControl.init()
        selectControl.backgroundColor = .clear
        selectControl.addTarget(self, action: #selector(didSelectControlClick(control:)), for: .touchUpInside)
        return selectControl
    }()
    
    lazy var selectMaskLayer: CALayer = {
        let selectMaskLayer = CALayer.init()
        selectMaskLayer.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
        selectMaskLayer.frame = bounds
        selectMaskLayer.isHidden = true
        return selectMaskLayer
    }()
    
    override var photoAsset: HXPHAsset? {
        didSet {
            updateSelectedState(isSelected: photoAsset!.isSelected, animated: false)
        }
    }
    
    override var config: HXPHPhotoListCellConfiguration? {
        didSet {
            selectControl.config = config!.selectBox
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.layer.addSublayer(selectMaskLayer)
        contentView.addSubview(selectControl)
        contentView.layer.addSublayer(disableMaskLayer)
    }
    
    @objc func didSelectControlClick(control: HXPHPickerCellSelectBoxControl) {
//        if !canSelect {
//            return
//        }
        delegate?.cellDidSelectControlClick(self, isSelected: control.isSelected)
    }
    
    func updateSelectedState(isSelected: Bool, animated: Bool) {
        let boxWidth = config!.selectBox.size.width
        let boxHeight = config!.selectBox.size.height
        if isSelected {
            selectMaskLayer.isHidden = false
            if config!.selectBox.type == .number {
                let text = String(format: "%d", arguments: [photoAsset!.selectIndex + 1])
                let font = UIFont.systemFont(ofSize: config!.selectBox.titleFontSize)
                let textHeight = text.hx_stringHeight(ofFont: font, maxWidth: boxWidth)
                var textWidth = text.hx_stringWidth(ofFont: font, maxHeight: textHeight)
                selectControl.textSize = CGSize(width: textWidth, height: textHeight)
                textWidth += boxHeight * 0.5
                if textWidth < boxWidth {
                    textWidth = boxWidth
                }
                selectControl.text = text
                updateSelectControlFrame(width: textWidth, height: boxHeight)
            }else {
                updateSelectControlFrame(width: boxWidth, height: boxHeight)
            }
        }else {
            selectMaskLayer.isHidden = true
            updateSelectControlFrame(width: boxWidth, height: boxHeight)
        }
        selectControl.isSelected = isSelected
        if animated {
            selectControl.layer.removeAnimation(forKey: "SelectControlAnimation")
            let keyAnimation = CAKeyframeAnimation.init(keyPath: "transform.scale")
            keyAnimation.duration = 0.3
            keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
            selectControl.layer.add(keyAnimation, forKey: "SelectControlAnimation")
        }
    }
    
    func updateSelectControlFrame(width: CGFloat, height: CGFloat) {
        let topMargin = config?.selectBoxTopMargin ?? 5
        let rightMargin = config?.selectBoxRightMargin ?? 5
        selectControl.frame = CGRect(x: hx_width - rightMargin - width, y: topMargin, width: width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectMaskLayer.frame = imageView.bounds
        if selectControl.hx_width != hx_width - 5 - selectControl.hx_width {
            updateSelectControlFrame(width: selectControl.hx_width, height: selectControl.hx_height)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                backgroundColor = HXPHManager.shared.isDark ? config?.backgroundDarkColor : config?.backgroundColor
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class HXPHPickerCellSelectBoxControl: UIControl {
    var text: String = "0"
    var textSize: CGSize = CGSize.zero
    lazy var config: HXPHSelectBoxConfiguration = {
        return HXPHSelectBoxConfiguration.init()
    }()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let ctx = UIGraphicsGetCurrentContext()!
        var fillRect : CGRect
        var fillColor : UIColor?
        if isSelected {
            fillRect = rect
            fillColor = HXPHManager.shared.isDark ? config.selectedBackgroudDarkColor : config.selectedBackgroundColor
        }else {
            let borderWidth = config.borderWidth
            let height = hx_height - borderWidth
            fillRect = CGRect(x: borderWidth, y: borderWidth, width: hx_width - borderWidth * 2, height: height - borderWidth)
            let strokePath = UIBezierPath.init(roundedRect: CGRect(x: borderWidth * 0.5, y: borderWidth * 0.5, width: hx_width - borderWidth, height: height), cornerRadius: height / 2)
            fillColor = HXPHManager.shared.isDark ? config.darkBackgroundColor : config.backgroundColor
            ctx.addPath(strokePath.cgPath)
            ctx.setLineWidth(borderWidth)
            ctx.setStrokeColor(HXPHManager.shared.isDark ? config.borderDarkColor.cgColor : config.borderColor.cgColor)
            ctx.strokePath()
        }
        let fillPath = UIBezierPath.init(roundedRect: fillRect, cornerRadius: fillRect.size.height / 2)
        ctx.addPath(fillPath.cgPath)
        ctx.setFillColor(fillColor!.cgColor)
        ctx.fillPath()
        if isSelected {
            if config.type == .number {
                ctx.textMatrix = CGAffineTransform.identity
                ctx.translateBy(x: 0, y: hx_height)
                ctx.scaleBy(x: 1, y: -1)
                let textPath = CGMutablePath()
                let font = UIFont.systemFont(ofSize: config.titleFontSize)
                var textHeight: CGFloat
                var textWidth: CGFloat
                if textSize.equalTo(CGSize.zero) {
                    textHeight = text.hx_stringHeight(ofFont: font, maxWidth: hx_width)
                    textWidth = text.hx_stringWidth(ofFont: font, maxHeight: textHeight)
                }else {
                    textHeight = textSize.height
                    textWidth = textSize.width
                }
                textPath.addRect(CGRect(x: (hx_width - textWidth) * 0.5, y: (hx_height - textHeight) * 0.5, width: textWidth, height: textHeight))
                ctx.addPath(textPath)
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                let attrString = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font : font ,
                                                                               NSAttributedString.Key.foregroundColor: HXPHManager.shared.isDark ? config.titleDarkColor : config.titleColor ,
                    NSAttributedString.Key.paragraphStyle: style])
                let framesetter = CTFramesetterCreateWithAttributedString(attrString)
                let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attrString.length), textPath, nil)
                CTFrameDraw(frame, ctx)
            }else if config.type == .tick {
                let tickPath = UIBezierPath.init()
                tickPath.move(to: CGPoint(x: scale(8), y: hx_height * 0.5 + scale(1)))
                tickPath.addLine(to: CGPoint(x: hx_width * 0.5 - scale(2), y: hx_height - scale(8)))
                tickPath.addLine(to: CGPoint(x: hx_width - scale(7), y: scale(9)))
                ctx.addPath(tickPath.cgPath)
                ctx.setLineWidth(config.tickWidth)
                ctx.setStrokeColor(HXPHManager.shared.isDark ? config.tickDarkColor.cgColor : config.tickColor.cgColor)
                ctx.strokePath()
            }
        }
    }
    
    private func scale(_ numerator: CGFloat) -> CGFloat {
        return numerator / 30 * hx_height
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if CGRect(x: -15, y: -15, width: hx_width + 30, height: hx_height + 30).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
