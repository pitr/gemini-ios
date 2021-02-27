/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import XCGLogger

private let log = Logger.browserLogger

protocol TabLocationViewDelegate {
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapCert(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView)
    func tabLocationViewDidTapStop(_ tabLocationView: TabLocationView)
    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView)
    func tabLocationViewLocationAccessibilityActions(_ tabLocationView: TabLocationView) -> [UIAccessibilityCustomAction]?
}

private struct TabLocationViewUX {
    static let HostFontColor = UIColor.black
    static let BaseURLFontColor = UIColor.Photon.Grey50
    static let Spacing: CGFloat = 8
    static let StatusIconSize: CGFloat = 18
    static let CertIconSize: CGFloat = 44
    static let StopReloadIconSize: CGFloat = 44
    static let ButtonSize: CGFloat = 44
}

class TabLocationView: UIView {
    var delegate: TabLocationViewDelegate?
    var longPressRecognizer: UILongPressGestureRecognizer!
    var tapRecognizer: UITapGestureRecognizer!
    var contentView: UIStackView!

    @objc dynamic var baseURLFontColor: UIColor = TabLocationViewUX.BaseURLFontColor {
        didSet { updateTextWithURL() }
    }

    var url: URL? {
        didSet {
            updateTextWithURL()
            certificateButton.isHidden = !["gemini"].contains(url?.scheme ?? "")
            setNeedsUpdateConstraints()
        }
    }

    lazy var placeholder: NSAttributedString = {
        let placeholderText = NSLocalizedString("Search or enter address", comment: "The text shown in the URL bar on about:home")
        return NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.Photon.Grey50])
    }()

    lazy var urlTextField: UITextField = {
        let urlTextField = DisplayTextField()

        // Prevent the field from compressing the toolbar buttons on the 4S in landscape.
        urlTextField.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 250), for: .horizontal)
        urlTextField.attributedPlaceholder = self.placeholder
        urlTextField.accessibilityIdentifier = "url"
        urlTextField.accessibilityActionsSource = self
        urlTextField.font = UIConstants.DefaultChromeFont
        urlTextField.backgroundColor = .clear
        urlTextField.accessibilityLabel = "Address Bar"

        // Remove the default drop interaction from the URL text field so that our
        // custom drop interaction on the BVC can accept dropped URLs.
        if let dropInteraction = urlTextField.textDropInteraction {
            urlTextField.removeInteraction(dropInteraction)
        }

        return urlTextField
    }()

    class SeparatedButton: UIButton {
        override var isHidden: Bool {
            didSet {
                separatorLine?.isHidden = isHidden
            }
        }

        var separatorLine: UIView?
    }

    lazy var certificateButton: SeparatedButton = {
        let certificateButton = SeparatedButton()
        certificateButton.setImage(UIImage.templateImageNamed("lock_verified"), for: .normal)
        certificateButton.addTarget(self, action: #selector(didPressCertButton(_:)), for: .touchUpInside)
        certificateButton.tintColor = UIColor.theme.browser.tint
        certificateButton.imageView?.contentMode = .scaleAspectFill
        certificateButton.accessibilityIdentifier = NSLocalizedString("Certificates", comment: "Accessibility Label for toolbar Certificate button")
        return certificateButton
    }()

    let ImageReload = UIImage.templateImageNamed("nav-refresh")
    let ImageStop = UIImage.templateImageNamed("nav-stop")

    var loading: Bool = false {
        didSet {
            if loading {
                stopReloadButton.setImage(ImageStop, for: .normal)
                stopReloadButton.accessibilityLabel = NSLocalizedString("Stop", comment: "Accessibility Label for the tab toolbar Stop button")
            } else {
                stopReloadButton.setImage(ImageReload, for: .normal)
                stopReloadButton.accessibilityLabel = NSLocalizedString("Reload", comment: "Accessibility Label for the tab toolbar Reload button")
            }
        }
    }

    lazy var stopReloadButton: UIButton = {
        let stopReloadButton = UIButton()
        stopReloadButton.setImage(ImageReload, for: .normal)
        stopReloadButton.addTarget(self, action: #selector(didClickStopReload(_:)), for: .touchUpInside)
        stopReloadButton.tintColor = UIColor.theme.browser.tint
        stopReloadButton.imageView?.contentMode = .scaleAspectFill
        stopReloadButton.accessibilityIdentifier = "TabLocationView.refreshButton"
        return stopReloadButton
    }()

    private func makeSeparator() -> UIView {
        let line = UIView()
        line.layer.cornerRadius = 2
        return line
    }

    lazy var separatorLineForTP: UIView = makeSeparator()

    override init(frame: CGRect) {
        super.init(frame: frame)

        register(self, forTabEvents: .didGainFocus)

        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressLocation))
        longPressRecognizer.delegate = self

        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapLocation))
        tapRecognizer.delegate = self

        addGestureRecognizer(longPressRecognizer)
        addGestureRecognizer(tapRecognizer)

        let space10px = UIView()
        space10px.snp.makeConstraints { make in
            make.width.equalTo(10)
        }

        // Link these so they hide/show in-sync.
        certificateButton.separatorLine = separatorLineForTP

        let subviews = [certificateButton, separatorLineForTP, space10px, urlTextField, stopReloadButton]
        contentView = UIStackView(arrangedSubviews: subviews)
        contentView.distribution = .fill
        contentView.alignment = .center
        addSubview(contentView)

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        certificateButton.snp.makeConstraints { make in
            make.width.equalTo(TabLocationViewUX.CertIconSize)
            make.height.equalTo(TabLocationViewUX.ButtonSize)
        }
        separatorLineForTP.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(26)
        }
        stopReloadButton.snp.makeConstraints { make in
            make.width.equalTo(TabLocationViewUX.StopReloadIconSize)
            make.height.equalTo(TabLocationViewUX.StopReloadIconSize)
        }

        // Setup UIDragInteraction to handle dragging the location
        // bar for dropping its URL into other apps.
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        self.addInteraction(dragInteraction)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var _accessibilityElements = [urlTextField, certificateButton, stopReloadButton]

    override var accessibilityElements: [Any]? {
        get {
            return _accessibilityElements.filter { !$0.isHidden }
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    func overrideAccessibility(enabled: Bool) {
        _accessibilityElements.forEach {
            $0.isAccessibilityElement = enabled
        }
    }

    @objc func longPressLocation(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
            delegate?.tabLocationViewDidLongPressLocation(self)
        }
    }

    @objc func tapLocation(_ recognizer: UITapGestureRecognizer) {
        delegate?.tabLocationViewDidTapLocation(self)
    }

    @objc func didPressCertButton(_ button: UIButton) {
        delegate?.tabLocationViewDidTapCert(self)
    }

    @objc func didClickStopReload(_ button: UIButton) {
        if loading {
            delegate?.tabLocationViewDidTapStop(self)
        } else {
            delegate?.tabLocationViewDidTapReload(self)
        }
    }

    fileprivate func updateTextWithURL() {
        if let host = url?.host {
            urlTextField.text = url?.absoluteString.replacingOccurrences(of: host, with: host.asciiHostToUTF8())
        } else {
            urlTextField.text = url?.absoluteString
        }

        // remove gemini:// (the scheme) from the url when displaying
        if let scheme = url?.scheme, let range = url?.absoluteString.range(of: "\(scheme)://") {
            urlTextField.text = url?.absoluteString.replacingCharacters(in: range, with: "")
        }
    }
}

extension TabLocationView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // When long pressing a button make sure the textfield's long press gesture is not triggered
        return !(otherGestureRecognizer.view is UIButton)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the longPressRecognizer is active, fail the tap recognizer to avoid conflicts.
        return gestureRecognizer == longPressRecognizer && otherGestureRecognizer == tapRecognizer
    }
}

@available(iOS 11.0, *)
extension TabLocationView: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        // Ensure we actually have a URL in the location bar and that the URL is not local.
        guard let url = self.url, !InternalURL.isValid(url: url), let itemProvider = NSItemProvider(contentsOf: url) else {
            return []
        }

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: UIDragSession) {
        delegate?.tabLocationViewDidBeginDragInteraction(self)
    }
}

extension TabLocationView: AccessibilityActionsSource {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]? {
        if view === urlTextField {
            return delegate?.tabLocationViewLocationAccessibilityActions(self)
        }
        return nil
    }
}

extension TabLocationView: Themeable {
    func applyTheme() {
        backgroundColor = UIColor.theme.textField.background
        urlTextField.textColor = UIColor.theme.textField.textAndTint
        separatorLineForTP.backgroundColor = UIColor.Photon.Grey40
        certificateButton.tintColor = UIColor.theme.browser.tint
        stopReloadButton.tintColor = UIColor.theme.browser.tint
    }
}

extension TabLocationView: TabEventHandler {
    func tabDidGainFocus(_ tab: Tab) {
    }
}

private class DisplayTextField: UITextField {
    weak var accessibilityActionsSource: AccessibilityActionsSource?

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return accessibilityActionsSource?.accessibilityCustomActionsForView(self)
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }

    fileprivate override var canBecomeFirstResponder: Bool {
        return false
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: TabLocationViewUX.Spacing, dy: 0)
    }
}
