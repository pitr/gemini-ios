/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class TrayToBrowserAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewController(forKey: .to) as? BrowserViewController,
           let tabTray = transitionContext.viewController(forKey: .from) as? TabTrayController {
            transitionFromTray(tabTray, toBrowser: bvc, usingContext: transitionContext)
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
}

private extension TrayToBrowserAnimator {
    func transitionFromTray(_ tabTray: TabTrayController, toBrowser bvc: BrowserViewController, usingContext transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        guard let selectedTab = bvc.tabManager.selectedTab else { return }

        let tabManager = bvc.tabManager
        let displayedTabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let expandFromIndex = displayedTabs.firstIndex(of: selectedTab) else { return }

        //Disable toolbar until animation completes
        tabTray.toolbar.isUserInteractionEnabled = false

        bvc.view.frame = transitionContext.finalFrame(for: bvc)

        // Hide browser components
        bvc.toggleSnackBarVisibility(show: false)
        toggleWebViewVisibility(false, usingTabManager: bvc.tabManager)
        bvc.geminiHomeViewController?.view.isHidden = true

        bvc.webViewContainerBackdrop.isHidden = true
        bvc.statusBarOverlay.isHidden = false

        // Take a snapshot of the collection view that we can scale/fade out. We don't need to wait for screen updates since it's already rendered on the screen
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotView(afterScreenUpdates: false)!
        tabTray.collectionView.alpha = 0
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        container.insertSubview(tabCollectionViewSnapshot, at: 0)

        // Create a fake cell to use for the upscaling animation
        let startingFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView, atIndex: expandFromIndex)
        let cell = createTransitionCellFromTab(bvc.tabManager.selectedTab, withFrame: startingFrame)
        cell.backgroundHolder.layer.cornerRadius = 0

        container.insertSubview(bvc.view, aboveSubview: tabCollectionViewSnapshot)
        container.insertSubview(cell, aboveSubview: bvc.view)

        // Flush any pending layout/animation code in preperation of the animation call
        container.layoutIfNeeded()

        let finalFrame = calculateExpandedCellFrameFromBVC(bvc)
        bvc.footer.alpha = shouldDisplayFooterForBVC(bvc) ? 1 : 0
        bvc.urlBar.isTransitioning = true

        // Re-calculate the starting transforms for header/footer views in case we switch orientation
        resetTransformsForViews([bvc.header, bvc.footer])
        transformHeaderFooterForBVC(bvc, toFrame: startingFrame, container: container)
        
        let frameResizeClosure = {
            // Scale up the cell and reset the transforms for the header/footers
            cell.frame = finalFrame
            container.layoutIfNeeded()
            cell.title.transform = CGAffineTransform(translationX: 0, y: -cell.title.frame.height)
            bvc.tabTrayDidDismiss(tabTray)
            tabTray.toolbar.transform = CGAffineTransform(translationX: 0, y: UIConstants.BottomToolbarHeight)
            tabCollectionViewSnapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) 
        }

        if UIAccessibility.isReduceMotionEnabled {
            frameResizeClosure()
        }

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
            delay: 0, usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [],
            animations: {
            if !UIAccessibility.isReduceMotionEnabled {
                frameResizeClosure()
            }
            UIApplication.shared.windows.first?.backgroundColor = UIColor.theme.browser.background
            tabTray.navigationController?.setNeedsStatusBarAppearanceUpdate()
            tabCollectionViewSnapshot.alpha = 0
            tabTray.statusBarBG.alpha = 0
            tabTray.searchBarHolder.alpha = 0
        }, completion: { finished in
            // Remove any of the views we used for the animation
            cell.removeFromSuperview()
            tabCollectionViewSnapshot.removeFromSuperview()
            bvc.footer.alpha = 1
            bvc.toggleSnackBarVisibility(show: true)
            toggleWebViewVisibility(true, usingTabManager: bvc.tabManager)
            bvc.webViewContainerBackdrop.isHidden = false
            bvc.geminiHomeViewController?.view.isHidden = false
            bvc.urlBar.isTransitioning = false
            tabTray.toolbar.isUserInteractionEnabled = true
            transitionContext.completeTransition(true)
        })
    }
}

class BrowserToTrayAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewController(forKey: .from) as? BrowserViewController,
           let tabTray = transitionContext.viewController(forKey: .to) as? TabTrayController {
            transitionFromBrowser(bvc, toTabTray: tabTray, usingContext: transitionContext)
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
}

private extension BrowserToTrayAnimator {
    func transitionFromBrowser(_ bvc: BrowserViewController, toTabTray tabTray: TabTrayController, usingContext transitionContext: UIViewControllerContextTransitioning) {

        let container = transitionContext.containerView
        guard let selectedTab = bvc.tabManager.selectedTab else { return }

        let tabManager = bvc.tabManager
        let displayedTabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let scrollToIndex = displayedTabs.firstIndex(of: selectedTab) else { return }

        //Disable toolbar until animation completes
        tabTray.toolbar.isUserInteractionEnabled = false

        tabTray.view.frame = transitionContext.finalFrame(for: tabTray)

        // Insert tab tray below the browser and force a layout so the collection view can get it's frame right
        container.insertSubview(tabTray.view, belowSubview: bvc.view)

        // Force subview layout on the collection view so we can calculate the correct end frame for the animation
        tabTray.view.layoutIfNeeded()
        tabTray.focusTab()

        // Build a tab cell that we will use to animate the scaling of the browser to the tab
        let expandedFrame = calculateExpandedCellFrameFromBVC(bvc)
        let cell = createTransitionCellFromTab(bvc.tabManager.selectedTab, withFrame: expandedFrame)
        cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius

        // Take a snapshot of the collection view to perform the scaling/alpha effect
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotView(afterScreenUpdates: true)!
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        tabCollectionViewSnapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        tabCollectionViewSnapshot.alpha = 0
        tabTray.view.insertSubview(tabCollectionViewSnapshot, belowSubview: tabTray.toolbar)

        if let toast = bvc.clipboardBarDisplayHandler?.clipboardToast {
            toast.removeFromSuperview()
        }

        container.addSubview(cell)
        cell.layoutIfNeeded()
        cell.title.transform = CGAffineTransform(translationX: 0, y: -cell.title.frame.size.height)

        // Hide views we don't want to show during the animation in the BVC
        bvc.geminiHomeViewController?.view.isHidden = true
        bvc.statusBarOverlay.isHidden = true
        bvc.toggleSnackBarVisibility(show: false)
        toggleWebViewVisibility(false, usingTabManager: bvc.tabManager)
        bvc.urlBar.isTransitioning = true

        // On iPhone, fading these in produces a darkening at the top of the screen, and then
        // it brightens back to full white as they fade in. Setting these to not fade in produces a better effect.
        if UIDevice.current.userInterfaceIdiom == .phone {
            tabTray.statusBarBG.alpha = 1
            tabTray.searchBarHolder.alpha = 1
        }

        // Since we are hiding the collection view and the snapshot API takes the snapshot after the next screen update,
        // the screenshot ends up being blank unless we set the collection view hidden after the screen update happens.
        // To work around this, we dispatch the setting of collection view to hidden after the screen update is completed.

        DispatchQueue.main.async {
            tabTray.collectionView.isHidden = true
            let finalFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView,
                atIndex: scrollToIndex)
            tabTray.toolbar.transform = CGAffineTransform(translationX: 0, y: UIConstants.BottomToolbarHeight)
            
            let frameResizeClosure = {
                cell.frame = finalFrame
                cell.layoutIfNeeded()
                transformHeaderFooterForBVC(bvc, toFrame: finalFrame, container: container)
                resetTransformsForViews([tabCollectionViewSnapshot])
            }
            
            if UIAccessibility.isReduceMotionEnabled {
                frameResizeClosure()
            }

            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                delay: 0, usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [],
                animations: {
                cell.title.transform = .identity

                UIApplication.shared.windows.first?.backgroundColor = UIColor.theme.tabTray.background
                tabTray.navigationController?.setNeedsStatusBarAppearanceUpdate()

                bvc.urlBar.updateAlphaForSubviews(0)
                bvc.footer.alpha = 0
                tabCollectionViewSnapshot.alpha = 1

                tabTray.statusBarBG.alpha = 1
                tabTray.searchBarHolder.alpha = 1
                tabTray.toolbar.transform = .identity
                
                if !UIAccessibility.isReduceMotionEnabled {
                    frameResizeClosure()
                }
                    
            }, completion: { finished in
                // Remove any of the views we used for the animation
                cell.removeFromSuperview()
                tabCollectionViewSnapshot.removeFromSuperview()
                tabTray.collectionView.isHidden = false

                bvc.toggleSnackBarVisibility(show: true)
                toggleWebViewVisibility(true, usingTabManager: bvc.tabManager)
                bvc.geminiHomeViewController?.view.isHidden = false

                resetTransformsForViews([bvc.header, bvc.footer])
                bvc.urlBar.isTransitioning = false
                tabTray.toolbar.isUserInteractionEnabled = true
                transitionContext.completeTransition(true)
            })
        }
    }
}

private func transformHeaderFooterForBVC(_ bvc: BrowserViewController, toFrame finalFrame: CGRect, container: UIView) {
    let footerForTransform = footerTransform(bvc.footer.frame, toFrame: finalFrame, container: container)
    let headerForTransform = headerTransform(bvc.header.frame, toFrame: finalFrame, container: container)

    bvc.footer.transform = footerForTransform
    bvc.header.transform = headerForTransform
}

private func footerTransform( _ frame: CGRect, toFrame finalFrame: CGRect, container: UIView) -> CGAffineTransform {
    let frame = container.convert(frame, to: container)
    let endY = finalFrame.maxY - (frame.size.height / 2)
    let endX = finalFrame.midX
    let translation = CGPoint(x: endX - frame.midX, y: endY - frame.midY)

    let scaleX = finalFrame.width / frame.width

    var transform: CGAffineTransform = .identity
    transform = transform.translatedBy(x: translation.x, y: translation.y)
    transform = transform.scaledBy(x: scaleX, y: scaleX)
    return transform
}

private func headerTransform(_ frame: CGRect, toFrame finalFrame: CGRect, container: UIView) -> CGAffineTransform {
    let frame = container.convert(frame, to: container)
    let endY = finalFrame.minY + (frame.size.height / 2)
    let endX = finalFrame.midX
    let translation = CGPoint(x: endX - frame.midX, y: endY - frame.midY)

    let scaleX = finalFrame.width / frame.width

    var transform: CGAffineTransform = .identity
    transform = transform.translatedBy(x: translation.x, y: translation.y)
    transform = transform.scaledBy(x: scaleX, y: scaleX)
    return transform
}

//MARK: Private Helper Methods
private func calculateCollapsedCellFrameUsingCollectionView(_ collectionView: UICollectionView, atIndex index: Int) -> CGRect {
    guard index < collectionView.numberOfItems(inSection: 0) else {
        return .zero
    }
    if let attr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) {
        return collectionView.convert(attr.frame, to: collectionView.superview)
    } else {
        return .zero
    }
}

private func calculateExpandedCellFrameFromBVC(_ bvc: BrowserViewController) -> CGRect {
    var frame = bvc.webViewContainer.frame

    // If we're navigating to a home panel and we were expecting to show the toolbar, add more height to end frame since
    // there is no toolbar for home panels
    if !bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) {
        return frame
    }

    if let url = bvc.tabManager.selectedTab?.url, bvc.toolbar == nil, let internalPage = InternalURL(url), internalPage.isAboutURL {
        frame.size.height += UIConstants.BottomToolbarHeight
    }

    return frame
}

private func shouldDisplayFooterForBVC(_ bvc: BrowserViewController) -> Bool {
    guard let url = bvc.tabManager.selectedTab?.url else { return false }
    let isAboutPage = InternalURL(url)?.isAboutURL ?? false
    return bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) && !isAboutPage
}

private func toggleWebViewVisibility(_ show: Bool, usingTabManager tabManager: TabManager) {
    for i in 0..<tabManager.count {
        if let tab = tabManager[i] {
            tab.webView?.isHidden = !show
        }
    }
}

private func resetTransformsForViews(_ views: [UIView?]) {
    for view in views {
        // Reset back to origin
        view?.transform = .identity
    }
}

private func createTransitionCellFromTab(_ tab: Tab?, withFrame frame: CGRect) -> TabCell {
    let cell = TabCell(frame: frame)
    cell.screenshotView.image = tab?.screenshot
    cell.titleText.text = tab?.displayTitle

    return cell
}
