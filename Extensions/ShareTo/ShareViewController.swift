/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared
import Storage

extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }

    func rightLeftEdges(inset: CGFloat) {
        layoutMargins = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        isLayoutMarginsRelativeArrangement = true
    }
}

extension UILabel {
    // Ensures labels can span a second line and will compress to fit text
    func handleLongLabels() {
        numberOfLines = 2
        adjustsFontSizeToFitWidth = true
        allowsDefaultTighteningForTruncation = true
    }
}

// Credit: https://stackoverflow.com/a/48860391/490488
extension String {
    static var quotes: (String, String) {
        guard
            let bQuote = Locale.current.quotationBeginDelimiter,
            let eQuote = Locale.current.quotationEndDelimiter
            else { return ("“", "”") }

        return (bQuote, eQuote)
    }

    var quoted: String {
        let (bQuote, eQuote) = String.quotes
        return bQuote + self + eQuote
    }
}

protocol ShareControllerDelegate: AnyObject {
    func finish(afterDelay: TimeInterval)
    func getValidExtensionContext() -> NSExtensionContext?
    func hidePopupWhenShowingAlert()
}

class ShareViewController: UIViewController {
    var shareItem: ExtensionUtils.ExtractedShareItem?
    private var viewsShownDuringDoneAnimation = [UIView]()
    private var stackView: UIStackView!
    private var actionDoneRow: (row: UIStackView, label: UILabel)!
    private var pageInfoHeight: Constraint?
    private var actionRowHeights = [Constraint]()
    private var pageInfoRowTitleLabel: UILabel?
    private var pageInfoRowUrlLabel: UILabel?

    weak var delegate: ShareControllerDelegate?

    override var extensionContext: NSExtensionContext? {
        get {
            return delegate?.getValidExtensionContext()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = Theme.defaultBackground.color
        view.subviews.forEach({ $0.removeFromSuperview() })

        setupNavBar()
        setupStackView()
        setupRows()

        guard let shareItem = shareItem else { return }

        switch shareItem {
        case .shareItem(let item):
            self.pageInfoRowUrlLabel?.text = item.url
            self.pageInfoRowTitleLabel?.text = item.title
        case .rawText(let text):
            self.pageInfoRowTitleLabel?.text = text.quoted
        }
    }

    private func setupRows() {
        let pageInfoRow = makePageInfoRow(addTo: stackView)
        pageInfoRowTitleLabel = pageInfoRow.pageTitleLabel
        pageInfoRowUrlLabel = pageInfoRow.urlLabel
        makeSeparator(addTo: stackView)

        if shareItem?.isUrlType() ?? true {
            makeActionRow(addTo: stackView, label: Strings.ShareOpenInGemini, imageName: "open-in-gemini", action: #selector(actionOpenInGeminiNow), hasNavigation: false)
            makeActionRow(addTo: stackView, label: Strings.ShareLoadInBackground, imageName: "menu-Show-Tabs", action: #selector(actionLoadInBackground), hasNavigation: false)
        } else {
            pageInfoRowUrlLabel?.removeFromSuperview()
            makeActionRow(addTo: stackView, label: Strings.ShareSearchInGemini, imageName: "quickSearch", action: #selector(actionSearchInGemini), hasNavigation: false)
        }

        let footerSpaceRow = UIView()
        stackView.addArrangedSubview(footerSpaceRow)
        // Without some growable space at the bottom there are constraint errors because the UIView space doesn't subdivide equally, and none of the rows are growable.
        // Also, during the animation to the done state, without this space, the page info label moves down slightly.
        footerSpaceRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(0)
        }

        actionDoneRow = makeActionDoneRow(addTo: stackView)
        // Fully constructing and pre-adding as a subview ensures that only the show operation will animate during the UIView.animate(),
        // and other animatable properties will not unexpectedly animate because they are modified in the same event loop as the animation.
        actionDoneRow.row.isHidden = true

        // All other views are hidden for the done animation.
        viewsShownDuringDoneAnimation += [pageInfoRow.row, footerSpaceRow, actionDoneRow.row]
    }

    private func makeSeparator(addTo parent: UIStackView) {
        let view = UIView()
        view.backgroundColor = Theme.separator.color
        parent.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    func layout(forTraitCollection traitCollection: UITraitCollection) {
        let isSearchMode = !(shareItem?.isUrlType() ?? true) // Dialog doesn't change size in search mode
        if !UX.enableResizeRowsForSmallScreens || isSearchMode {
            return
        }

        pageInfoHeight?.update(offset: isLandscapeSmallScreen(traitCollection) ? UX.pageInfoRowHeight - UX.perRowShrinkageForLandscape : UX.pageInfoRowHeight)
        actionRowHeights.forEach {
            $0.update(offset: isLandscapeSmallScreen(traitCollection) ? UX.actionRowHeight - UX.perRowShrinkageForLandscape : UX.actionRowHeight)
        }
    }

    private func makePageInfoRow(addTo parent: UIStackView) -> (row: UIStackView, pageTitleLabel: UILabel, urlLabel: UILabel) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        row.snp.makeConstraints { make in
            pageInfoHeight = make.height.equalTo(isLandscapeSmallScreen(traitCollection) ? UX.pageInfoRowHeight - UX.perRowShrinkageForLandscape : UX.pageInfoRowHeight).constraint
        }

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = UX.pageInfoLineSpacing

        row.addArrangedSubview(verticalStackView)

        let pageTitleLabel = UILabel()
        let urlLabel = UILabel()
        [pageTitleLabel, urlLabel].forEach { label in
            verticalStackView.addArrangedSubview(label)
            label.allowsDefaultTighteningForTruncation = true
            label.lineBreakMode = .byTruncatingMiddle
            label.font = UX.baseFont
        }

        pageTitleLabel.font = UIFont.boldSystemFont(ofSize: UX.baseFont.pointSize)

        return (row, pageTitleLabel, urlLabel)
    }

    private func makeActionRow(addTo parent: UIStackView, label: String, imageName: String, action: Selector, hasNavigation: Bool) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = UX.actionRowSpacingBetweenIconAndTitle
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        row.snp.makeConstraints { make in
            let c = make.height.equalTo(isLandscapeSmallScreen(traitCollection) ? UX.actionRowHeight - UX.perRowShrinkageForLandscape : UX.actionRowHeight).constraint
            actionRowHeights.append(c)
        }

        let icon = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = Theme.actionRowTextAndIcon.color

        let title = UILabel()
        title.font = UX.baseFont
        title.handleLongLabels()
        title.textColor = Theme.actionRowTextAndIcon.color
        title.text = label
        [icon, title].forEach { row.addArrangedSubview($0) }

        icon.snp.makeConstraints { make in
            make.width.equalTo(UX.actionRowIconSize)
        }

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate))
            navButton.contentMode = .scaleAspectFit
            navButton.tintColor = Theme.actionRowTextAndIcon.color
            row.addArrangedSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.width.equalTo(14)
            }
        }

        let gesture = UITapGestureRecognizer(target: self, action: action)
        row.addGestureRecognizer(gesture)
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.snp.updateConstraints { make in
            make.height.equalTo(UX.viewHeightForDoneState)
        }

        actionDoneRow.label.text = title

        UIView.animate(withDuration: UX.doneDialogAnimationDuration) {
            self.actionDoneRow.row.isHidden = false
            self.stackView.arrangedSubviews
                .filter { !self.viewsShownDuringDoneAnimation.contains($0) }
                .forEach { $0.removeFromSuperview() }

            self.navigationController?.view.superview?.layoutIfNeeded()
        }
    }

    @objc func finish(afterDelay: TimeInterval = UX.durationToShowDoneDialog) {
        delegate?.finish(afterDelay: afterDelay)
    }

    private func makeActionDoneRow(addTo parent: UIStackView) -> (row: UIStackView, label: UILabel) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.addBackground(color: Theme.doneLabelBackground.color)
        stackView.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.height.equalTo(UX.pageInfoRowHeight)
        }

        let label = UILabel()
        label.font = UX.doneLabelFont
        label.handleLongLabels()

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 22)

        [label, checkmark].forEach {
            stackView.addArrangedSubview($0)
            $0.textColor = .white
        }

        checkmark.snp.makeConstraints { make in
            make.width.equalTo(20)
        }

        return (stackView, label)
    }

    private func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow") // hide separator line
        navigationItem.titleView = UIImageView(image: UIImage(named: "Icon-Small"))
        navigationItem.titleView?.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.SendToCancelButton, style: .plain, target: self, action: #selector(finish))
        navigationController?.navigationBar.barTintColor = Theme.defaultBackground.color
    }

    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension ShareViewController {
    @objc func actionLoadInBackground(gesture: UIGestureRecognizer) {
        // To avoid re-rentry from double tap, each action function disables the gesture
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: Strings.ShareLoadInBackgroundDone)

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile()
            if let err = profile.db.addToQueue(item).failureValue {
                print(err)
            }
            profile._shutdown()
        }

        finish()
    }

    func openGemini(withUrl url: String, isSearch: Bool) {
       func geminiUrl(_ url: String) -> String {
            let encoded = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics) ?? ""
            if isSearch {
                return "gemini://open-text?text=\(encoded)"
            }
            return "gemini://open-url?url=\(encoded)"
        }

        guard let url = URL(string: geminiUrl(url)) else { return }
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: selectorOpenURL) {
                current.perform(selectorOpenURL, with: url, afterDelay: 0)
                break
            }

            responder = current.next
        }
    }

    @objc func actionSearchInGemini(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false

        if let shareItem = shareItem, case .rawText(let text) = shareItem {
            openGemini(withUrl: text, isSearch: true)
        }

        finish(afterDelay: 0)
    }

    @objc func actionOpenInGeminiNow(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            openGemini(withUrl: item.url, isSearch: false)
        }

        finish(afterDelay: 0)
    }
}

