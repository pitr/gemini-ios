/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Strings {}

/// Return the main application bundle. Even if called from an extension. If for some reason we cannot find the
/// application bundle, the current bundle is returned, which will then result in an English base language string.
private func applicationBundle() -> Bundle {
    let bundle = Bundle.main
    guard bundle.bundleURL.pathExtension == "appex", let applicationBundleURL = (bundle.bundleURL as NSURL).deletingLastPathComponent?.deletingLastPathComponent() else {
        return bundle
    }
    return Bundle(url: applicationBundleURL) ?? bundle
}

extension Strings {
    public static let OKString = NSLocalizedString("OK", comment: "OK button")
    public static let CancelString = NSLocalizedString("Cancel", comment: "Label for Cancel button")
    public static let NotNowString = NSLocalizedString("Toasts.NotNow", value: "Not Now", comment: "label for Not Now button")
    public static let AppStoreString = NSLocalizedString("Toasts.OpenAppStore", value: "Open App Store", comment: "Open App Store button")
    public static let UndoString = NSLocalizedString("Toasts.Undo", value: "Undo", comment: "Label for button to undo the action just performed")
    public static let OpenSettingsString = NSLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7")

    public static let AllBookmarksTitle = NSLocalizedString("All Bookmarks", comment: "Title of root bookmark folder")
}

// Table date section titles.
extension Strings {
    public static let TableDateSectionTitleToday = NSLocalizedString("Today", comment: "History tableview section header")
    public static let TableDateSectionTitleYesterday = NSLocalizedString("Yesterday", comment: "History tableview section header")
    public static let TableDateSectionTitleLastWeek = NSLocalizedString("Last week", comment: "History tableview section header")
    public static let TableDateSectionTitleLastMonth = NSLocalizedString("Last month", comment: "History tableview section header")
}

// Top Sites.
extension Strings {
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let ASTopSitesTitle =  NSLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let TopSitesRowSettingFooter = NSLocalizedString("ActivityStream.TopSites.RowSettingFooter", value: "Set Rows", comment: "The title for the setting page which lets you select the number of top site rows")
    public static let TopSitesRowCount = NSLocalizedString("ActivityStream.TopSites.RowCount", value: "Rows: %d", comment: "label showing how many rows of topsites are shown. %d represents a number")
    public static let RecentlyBookmarkedTitle = NSLocalizedString("ActivityStream.NewRecentBookmarks.Title", value: "Recent Bookmarks", comment: "Section title label for recently bookmarked websites")
}

// Home Panel Context Menu.
extension Strings {
    public static let OpenInNewTabContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.OpenInNewTab", value: "Open in New Tab", comment: "The title for the Open in New Tab context menu action for sites in Home Panels")
    public static let BookmarkContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.Bookmark", value: "Bookmark", comment: "The title for the Bookmark context menu action for sites in Home Panels")
    public static let RemoveBookmarkContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.RemoveBookmark", value: "Remove Bookmark", comment: "The title for the Remove Bookmark context menu action for sites in Home Panels")
    public static let DeleteFromHistoryContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.DeleteFromHistory", value: "Delete from History", comment: "The title for the Delete from History context menu action for sites in Home Panels")
    public static let ShareContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.Share", value: "Share", comment: "The title for the Share context menu action for sites in Home Panels")
    public static let RemoveContextMenuTitle = NSLocalizedString("HomePanel.ContextMenu.Remove", value: "Remove", comment: "The title for the Remove context menu action for sites in Home Panels")
    public static let PinTopsiteActionTitle = NSLocalizedString("ActivityStream.ContextMenu.PinTopsite", value: "Pin to Top Sites", comment: "The title for the pinning a topsite action")
    public static let RemovePinTopsiteActionTitle = NSLocalizedString("ActivityStream.ContextMenu.RemovePinTopsite", value: "Remove Pinned Site", comment: "The title for removing a pinned topsite action")
}

//  PhotonActionSheet Strings
extension Strings {
    public static let CloseButtonTitle = NSLocalizedString("PhotonMenu.close", value: "Close", comment: "Button for closing the menu action sheet")

}

// $eopen last tab.
extension Strings {
    public static let ReopenLastTabAlertTitle = NSLocalizedString("ReopenAlert.Title", value: "Reopen Last Closed Tab", comment: "Reopen alert title shown at home page.")
    public static let ReopenLastTabButtonText = NSLocalizedString("ReopenAlert.Actions.Reopen", value: "Reopen", comment: "Reopen button text shown in reopen-alert at home page.")
    public static let ReopenLastTabCancelText = NSLocalizedString("ReopenAlert.Actions.Cancel", value: "Cancel", comment: "Cancel button text shown in reopen-alert at home page.")
}

// Settings.
extension Strings {
    public static let AppSettingsTitle = NSLocalizedString("Settings", comment: "Title in the settings view controller title bar")
    public static let AppSettingsDone = NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar")
    public static let AppSettingsSearch = NSLocalizedString("Search", comment: "Open search section of settings")

    public static let SettingsGeneralSectionTitle = NSLocalizedString("Settings.General.SectionName", value: "General", comment: "General settings section title")
    public static let SettingsWebsiteDataTitle = NSLocalizedString("Settings.WebsiteData.Title", value: "Website Data", comment: "Title displayed in header of the Data Management panel.")
    public static let SettingsSearchDoneButton = NSLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.")

    public static let SettingsFeedbackTitle = NSLocalizedString("Settings.Feedback.Title", value: "Feedback", comment: "Title of feedback section in settings.")
    public static let SettingsFeedbackButton = NSLocalizedString("Settings.Feedback.Button", value: "Send Feedback", comment: "Title of feedback button in settings.")
    public static let SettingsRateButton = NSLocalizedString("Settings.Rate.Button", value: "Rate Elaho", comment: "Title of rate button in settings.")

    public static let SettingsEnableSiteThemeTitle = NSLocalizedString("Settings.EnableSiteTheme.Title", value: "Enable Site Themes", comment: "Title of setting to enable site-specific themes")
    public static let SettingsEnableSiteThemeStatus = NSLocalizedString("Settings.EnableSiteTheme.Status", value: "Site themes are auto-generated based on site URL", comment: "Status of setting to enable site-specific themes")

    public static let SettingsEnableAnsiCodeTitle = NSLocalizedString("Settings.EnableAnsiCode.Title", value: "Enable ANSI Escape Codes", comment: "Title of setting to enable ANSI Escape Codes")
    public static let SettingsEnableAnsiCodeStatus = NSLocalizedString("Settings.EnableAnsiCode.Status", value: "Only supports colours, and only in the prefformatted blocks", comment: "Status of setting to enable ANSI Escape Codes")

}

// Error pages.
extension Strings {
    public static let ErrorPageTryAgain = NSLocalizedString("Try again", tableName: "ErrorPages", comment: "Shown in error pages on a button that will try to load the page again")
    public static let ErrorPageOpenInSafari = NSLocalizedString("Open in Safari", tableName: "ErrorPages", comment: "Shown in error pages for files that can't be shown and need to be downloaded.")

    public static let ErrorPagesAdvancedButton = NSLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = NSLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can’t confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesAdvancedWarning2 = NSLocalizedString("ErrorPages.AdvancedWarning2.Text", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesCertWarningDescription = NSLocalizedString("ErrorPages.CertWarning.Description", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Elaho has not connected to this website.", comment: "Warning text on the certificate error page")
    public static let ErrorPagesCertWarningTitle = NSLocalizedString("ErrorPages.CertWarning.Title", value: "This Connection is Untrusted", comment: "Title on the certificate error page")
    public static let ErrorPagesGoBackButton = NSLocalizedString("ErrorPages.GoBack.Button", value: "Go Back", comment: "Label for button to go back from the error page")
    public static let ErrorPagesVisitOnceButton = NSLocalizedString("ErrorPages.VisitOnce.Button", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page")
}

// Certificates Panel
extension Strings {
    public static let CertificatesPanelEmptyStateTitle = NSLocalizedString("CertificatesPanel.EmptyState.Title", value: "Client certificates will show up here.", comment: "Title for the Client certificates Panel empty state.")
    public static let CertificatesPanelDeleteTitle = NSLocalizedString("CertificatesPanel.Delete.Title", value: "Delete", comment: "Action button for deleting certificate in the Certificates panel.")
    public static let CertificatesPanelActivateTitle = NSLocalizedString("CertificatesPanel.Activate.Title", value: "Activate", comment: "Action button for activating Certificates in the Certificates panel.")
    public static let CertificatesPanelDeactivateTitle = NSLocalizedString("CertificatesPanel.Deactivate.Title", value: "Deactivate", comment: "Action button for deactivating Certificates in the Certificates panel.")

    public static let CertificatesActivePrefix = NSLocalizedString("(active)", comment: "Label prefix indicating that the certificate is active.")
    public static let CertificatesLastUsedDescription = NSLocalizedString("last used %@", comment: "Description of certificate, showing when certificate was last used.")
}

// History Panel
extension Strings {
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = NSLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let HistoryPanelClearHistoryButtonTitle = NSLocalizedString("HistoryPanel.ClearHistoryButtonTitle", value: "Clear Recent History…", comment: "Title for button in the history panel to clear recent history")
    public static let GeminiHomePage = NSLocalizedString("Gemini.HomePage.Title", value: "Elaho Home Page", comment: "Title for Elaho about:home page in tab history list")

    public static let HistoryPanelDelete = NSLocalizedString("Delete", tableName: "HistoryPanel", comment: "Action button for deleting history entries in the history panel.")
}

// Clear recent history action menu
extension Strings {
    public static let ClearHistoryMenuTitle = NSLocalizedString("HistoryPanel.ClearHistoryMenuTitle", value: "Clearing Recent History will remove all history data.", comment: "Title for popup action menu to clear recent history.")
    public static let ClearHistoryMenuOptionTheLastHour = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionTheLastHour", value: "The Last Hour", comment: "Button to perform action to clear history for the last hour")
    public static let ClearHistoryMenuOptionToday = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionToday", value: "Today", comment: "Button to perform action to clear history for today only")
    public static let ClearHistoryMenuOptionTodayAndYesterday = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionTodayAndYesterday", value: "Today and Yesterday", comment: "Button to perform action to clear history for yesterday and today")
    public static let ClearHistoryMenuOptionEverything = NSLocalizedString("HistoryPanel.ClearHistoryMenuOptionEverything", value: "Everything", comment: "Option title to clear all browsing history.")
}

//Hotkey Titles
extension Strings {
    public static let ReloadPageTitle = NSLocalizedString("Hotkeys.Reload.DiscoveryTitle", value: "Reload Page", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let BackTitle = NSLocalizedString("Hotkeys.Back.DiscoveryTitle", value: "Back", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ForwardTitle = NSLocalizedString("Hotkeys.Forward.DiscoveryTitle", value: "Forward", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")

    public static let FindTitle = NSLocalizedString("Hotkeys.Find.DiscoveryTitle", value: "Find", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let SelectLocationBarTitle = NSLocalizedString("Hotkeys.SelectLocationBar.DiscoveryTitle", value: "Select Location Bar", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let NewTabTitle = NSLocalizedString("Hotkeys.NewTab.DiscoveryTitle", value: "New Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let CloseTabTitle = NSLocalizedString("Hotkeys.CloseTab.DiscoveryTitle", value: "Close Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowNextTabTitle = NSLocalizedString("Hotkeys.ShowNextTab.DiscoveryTitle", value: "Show Next Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
    public static let ShowPreviousTabTitle = NSLocalizedString("Hotkeys.ShowPreviousTab.DiscoveryTitle", value: "Show Previous Tab", comment: "Label to display in the Discoverability overlay for keyboard shortcuts")
}

// New tab choice settings
extension Strings {
    public static let CustomNewPageURL = NSLocalizedString("Settings.NewTab.CustomURL", value: "Custom URL", comment: "Label used to set a custom url as the new tab option (homepage).")
    public static let SettingsNewTabSectionName = NSLocalizedString("Settings.NewTab.SectionName", value: "New Tab", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the new tab behavior.")
    public static let NewTabSectionName =
        NSLocalizedString("Settings.NewTab.TopSectionName", value: "Show", comment: "Label at the top of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTitle = NSLocalizedString("Settings.NewTab.Title", value: "New Tab", comment: "Title displayed in header of the setting panel.")
    public static let NewTabSectionNameFooter =
        NSLocalizedString("Settings.NewTab.TopSectionNameFooter", value: "Choose what to load when opening a new tab", comment: "Footer at the bottom of the New Tab screen after entering New Tab in settings")
    public static let SettingsNewTabTopSites = NSLocalizedString("Settings.NewTab.Option.GeminiHome", value: "Elaho Home", comment: "Option in settings to show Elaho Home when you open a new tab")
    public static let SettingsNewTabBlankPage = NSLocalizedString("Settings.NewTab.Option.BlankPage", value: "Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = NSLocalizedString("Settings.NewTab.Option.CustomPage", value: "Custom Page", comment: "Option in settings to show your custom page when you open a new tab")
    // AS Panel settings
    public static let SettingsTopSitesCustomizeTitle = NSLocalizedString("Settings.NewTab.Option.CustomizeTitle", value: "Customize Elaho Home", comment: "The title for the section to customize top sites in the new tab settings page.")
    public static let SettingsTopSitesCustomizeFooter = NSLocalizedString("Settings.NewTab.Option.CustomizeFooter", value: "The sites you visit most", comment: "The footer for the section to customize top sites in the new tab settings page.")

}

// Open With Settings
extension Strings {
    public static let SettingsOpenWithSectionName = NSLocalizedString("Settings.OpenWith.SectionName", value: "Mail App", comment: "Label used as an item in Settings. When touched it will open a dialog to configure the open with (mail links) behavior.")
    public static let SettingsOpenWithPageTitle = NSLocalizedString("Settings.OpenWith.PageTitle", value: "Open mail links with", comment: "Title for Open With Settings")
}

// Third Party Search Engines
extension Strings {
    public static let ThirdPartySearchEngineAdded = NSLocalizedString("Search.ThirdPartyEngines.AddSuccess", value: "Added Search engine!", comment: "The success message that appears after a user sucessfully adds a new search engine")
    public static let ThirdPartySearchAddTitle = NSLocalizedString("Search.ThirdPartyEngines.AddTitle", value: "Add Search Provider?", comment: "The title that asks the user to Add the search provider")
    public static let ThirdPartySearchAddMessage = NSLocalizedString("Search.ThirdPartyEngines.AddMessage", value: "The new search engine will appear in the quick search bar.", comment: "The message that asks the user to Add the search provider explaining where the search engine will appear")
    public static let ThirdPartySearchCancelButton = NSLocalizedString("Search.ThirdPartyEngines.Cancel", value: "Cancel", comment: "The cancel button if you do not want to add a search engine.")
    public static let ThirdPartySearchOkayButton = NSLocalizedString("Search.ThirdPartyEngines.OK", value: "OK", comment: "The confirmation button")
    public static let ThirdPartySearchFailedTitle = NSLocalizedString("Search.ThirdPartyEngines.FailedTitle", value: "Failed", comment: "A title explaining that we failed to add a search engine")
    public static let ThirdPartySearchFailedMessage = NSLocalizedString("Search.ThirdPartyEngines.FailedMessage", value: "The search provider could not be added.", comment: "A title explaining that we failed to add a search engine")
    public static let CustomEngineFormErrorTitle = NSLocalizedString("Search.ThirdPartyEngines.FormErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineFormErrorMessage = NSLocalizedString("Search.ThirdPartyEngines.FormErrorMessage", value: "Please fill all fields correctly.", comment: "A message explaining fault in custom search engine form.")
    public static let CustomEngineDuplicateErrorTitle = NSLocalizedString("Search.ThirdPartyEngines.DuplicateErrorTitle", value: "Failed", comment: "A title stating that we failed to add custom search engine.")
    public static let CustomEngineDuplicateErrorMessage = NSLocalizedString("Search.ThirdPartyEngines.DuplicateErrorMessage", value: "A search engine with this title or URL has already been added.", comment: "A message explaining fault in custom search engine form.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = NSLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksNewBookmark = NSLocalizedString("Bookmarks.NewBookmark.Label", value: "New Bookmark", comment: "The button to create a new bookmark")
    public static let BookmarksNewFolder = NSLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksNewSeparator = NSLocalizedString("Bookmarks.NewSeparator.Label", value: "New Separator", comment: "The button to create a new separator")
    public static let BookmarksEditBookmark = NSLocalizedString("Bookmarks.EditBookmark.Label", value: "Edit Bookmark", comment: "The button to edit a bookmark")
    public static let BookmarksEditFolder = NSLocalizedString("Bookmarks.EditFolder.Label", value: "Edit Folder", comment: "The button to edit a folder")
    public static let BookmarksDeleteFolderWarningTitle = NSLocalizedString("Bookmarks.DeleteFolderWarning.Title", tableName: "BookmarkPanelDeleteConfirm", value: "This folder isn’t empty.", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderWarningDescription = NSLocalizedString("Bookmarks.DeleteFolderWarning.Description", tableName: "BookmarkPanelDeleteConfirm", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderCancelButtonLabel = NSLocalizedString("Bookmarks.DeleteFolderWarning.CancelButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Cancel", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
    public static let BookmarksDeleteFolderDeleteButtonLabel = NSLocalizedString("Bookmarks.DeleteFolderWarning.DeleteButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Delete", comment: "Button label for the button that deletes a folder and all of its children.")
    public static let BookmarksPanelDeleteTableAction = NSLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")
    public static let BookmarkDetailFieldTitle = NSLocalizedString("Bookmark.DetailFieldTitle.Label", value: "Title", comment: "The label for the Title field when editing a bookmark")
    public static let BookmarkDetailFieldURL = NSLocalizedString("Bookmark.DetailFieldURL.Label", value: "URL", comment: "The label for the URL field when editing a bookmark")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = NSLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = NSLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs")
    public static let TabSearchPlaceholderText = NSLocalizedString("Tabs.Search.PlaceholderText", value: "Search Tabs", comment: "The placeholder text for the tab search bar")
    public static let TabTrayCurrentlySelectedTabAccessibilityLabel = NSLocalizedString("Currently selected tab.", comment: "Accessibility label for the currently selected tab.")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = NSLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = NSLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = NSLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = NSLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Elaho", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")

    public static let SettingsUseInAppSafariTitle = NSLocalizedString("Settings.InAppSafari.Title", value: "Use In-App Safari", comment: "Title of setting to open http links in-app.")
    public static let SettingsUseInAppSafariStatus = NSLocalizedString("Settings.InAppSafari.Status", value: "Otherwise uses your default browser", comment: "Description displayed under the ”Use In-App Safari” option.")
}

extension Strings {
    public static let LibraryPanelChooserAccessibilityLabel = NSLocalizedString("Panel Chooser", comment: "Accessibility label for the Library panel's bottom toolbar containing a list of the home panels (top sites, bookmarks, history).")

    public static let LibraryBookmarksAccessibilityLabel = NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
    public static let LibraryHistoryAccessibilityLabel = NSLocalizedString("History", comment: "Panel accessibility label")
    public static let LibraryCertificatesAccessibilityLabel = NSLocalizedString("Certificates", comment: "Panel accessibility label")
}

// Link Previews
extension Strings {
    public static let SettingsShowLinkPreviewsTitle = NSLocalizedString("Settings.ShowLinkPreviews.Title", value: "Show Link Previews", comment: "Title of setting to enable link previews when long-pressing links.")
    public static let SettingsShowLinkPreviewsStatus = NSLocalizedString("Settings.ShowLinkPreviews.Status", value: "When Long-pressing Links", comment: "Description displayed under the ”Show Link Previews” option")
}

// Errors
extension Strings {
    public static let UnableToOpenURLError = NSLocalizedString("OpenURL.Error.Message", value: "Elaho cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Elaho, or any external app.")
    public static let UnableToOpenURLErrorTitle = NSLocalizedString("OpenURL.Error.Title", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
}

// Certificate Helper
extension Strings {
    public static let CertificateHelperAlertCreate = NSLocalizedString("Certificates.Alert.Create", value: "Create Certificate", comment: "The label of the button the user will press to create certificate")
    public static let CertificatesButtonTitle = NSLocalizedString("Certificates.Toast.GoToCertificates.Button", value: "Certificates", comment: "The button to open a new tab with the Certificates home panel")
}

// Add Custom Search Engine
extension Strings {
    public static let SettingsAddCustomEngine = NSLocalizedString("Settings.AddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitle = NSLocalizedString("Settings.AddCustomEngine.Title", value: "Add Search Engine", comment: "The title of the Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitleLabel = NSLocalizedString("Settings.AddCustomEngine.TitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.")
    public static let SettingsAddCustomEngineURLLabel = NSLocalizedString("Settings.AddCustomEngine.URLLabel", value: "URL", comment: "The title for URL Field of the Custom Search Engine")
    public static let SettingsAddCustomEngineURLDescription = NSLocalizedString("Settings.AddCustomEngine.URLDescription", value: "Example: gemini://gus.guru/search?%s", comment: "The description for URL Field of the Custom Search Engine")
    public static let SettingsAddCustomEngineTitlePlaceholder = NSLocalizedString("Settings.AddCustomEngine.TitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.")
    public static let SettingsAddCustomEngineURLPlaceholder = NSLocalizedString("Settings.AddCustomEngine.URLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine")
}

// SearchEngine Picker
extension String {
    public static let SearchEnginePickerTitle = NSLocalizedString("Default Search Engine", comment: "Title for default search engine picker.")
    public static let SearchEnginePickerCancel = NSLocalizedString("Cancel", comment: "Label for Cancel button")
}


// Context menu ButtonToast instances.
extension Strings {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = NSLocalizedString("ContextMenu.ButtonToast.NewTabOpened.LabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewTabOpenedButtonText = NSLocalizedString("ContextMenu.ButtonToast.NewTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.")
}

// Page context menu items (i.e. links and images).
extension Strings {
    public static let ContextMenuOpenInNewTab = NSLocalizedString("ContextMenu.OpenInNewTabButtonTitle", value: "Open in New Tab", comment: "Context menu item for opening a link in a new tab")
    public static let ContextMenuBookmarkLink = NSLocalizedString("ContextMenu.BookmarkLinkButtonTitle", value: "Bookmark Link", comment: "Context menu item for bookmarking a link URL")
    public static let ContextMenuCopyLink = NSLocalizedString("ContextMenu.CopyLinkButtonTitle", value: "Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
    public static let ContextMenuShareLink = NSLocalizedString("ContextMenu.ShareLinkButtonTitle", value: "Share Link", comment: "Context menu item for sharing a link URL")
    public static let ContextMenuSaveImage = NSLocalizedString("ContextMenu.SaveImageButtonTitle", value: "Save Image", comment: "Context menu item for saving an image")
    public static let ContextMenuCopyImage = NSLocalizedString("ContextMenu.CopyImageButtonTitle", value: "Copy Image", comment: "Context menu item for copying an image to the clipboard")
    public static let ContextMenuCopyImageLink = NSLocalizedString("ContextMenu.CopyImageLinkButtonTitle", value: "Copy Image Link", comment: "Context menu item for copying an image URL to the clipboard")
}

// Photo Library access.
extension Strings {
    public static let PhotoLibraryGeminiWouldLikeAccessTitle = NSLocalizedString("PhotoLibrary.GeminiWouldLikeAccessTitle", value: "Elaho would like to access your Photos", comment: "")
    public static let PhotoLibraryGeminiWouldLikeAccessMessage = NSLocalizedString("PhotoLibrary.GeminiWouldLikeAccessMessage", value: "This allows you to save the image to your Camera Roll.", comment: "")
}

// App menu.
extension Strings {
    public static let AppMenuLibraryTitleString = NSLocalizedString("Menu.Library.Title", tableName: "Menu", value: "Your Library", comment: "Label for the button, displayed in the menu, used to open the Library")
    public static let AppMenuSharePageTitleString = NSLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuCopyURLTitleString = NSLocalizedString("Menu.CopyAddress.Title", tableName: "Menu", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.")
    public static let AppMenuNewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "App Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel.v2", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel.v2", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuCertificatesTitleString = NSLocalizedString("Menu.OpenCertificatesAction.AccessibilityLabel.v2", tableName: "Menu", value: "Certificates", comment: "Accessibility label for the button, displayed in the menu, used to open the Certificates home panel. Please keep as short as possible, <15 chars of space available.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuCopyURLConfirmMessage = NSLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    public static let AppMenuAddBookmarkConfirmMessage = NSLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuRemoveBookmarkConfirmMessage = NSLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let SendToDeviceTitle = NSLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
}

// Snackbar shown when tapping app store link
extension Strings {
    public static let ExternalLinkAppStoreConfirmationTitle = NSLocalizedString("ExternalLink.AppStore.ConfirmationTitle", value: "Open this link in the App Store?", comment: "Question shown to user when tapping a link that opens the App Store app")
    public static let ExternalLinkGenericConfirmation = NSLocalizedString("ExternalLink.AppStore.GenericConfirmationTitle", value: "Open this link in external app?", comment: "Question shown to user when tapping an SMS or MailTo link that opens the external app for those.")
}

// Certificate strings
extension Strings {
    public static let CertPageMenuTitle = NSLocalizedString("Menu.Certificate.Title", value: "Certificate for %@", comment: "Title on certificate menu showing the domain. eg. Certificate for gus.guru")
}

// Location bar long press menu
extension Strings {
    public static let PasteAndGoTitle = NSLocalizedString("Menu.PasteAndGo.Title", value: "Paste & Go", comment: "The title for the button that lets you paste and go to a URL")
    public static let PasteTitle = NSLocalizedString("Menu.Paste.Title", value: "Paste", comment: "The title for the button that lets you paste into the location bar")
    public static let CopyAddressTitle = NSLocalizedString("Menu.Copy.Title", value: "Copy Address", comment: "The title for the button that lets you copy the url from the location bar.")
}

// Settings Home
extension Strings {
    public static let SettingsSiriSectionName = NSLocalizedString("Settings.Siri.SectionName", value: "Siri Shortcuts", comment: "The option that takes you to the siri shortcuts settings page")
    public static let SettingsSiriSectionDescription = NSLocalizedString("Settings.Siri.SectionDescription", value: "Use Siri shortcuts to quickly open Elaho via Siri", comment: "The description that describes what siri shortcuts are")
    public static let SettingsSiriOpenURL = NSLocalizedString("Settings.Siri.OpenTabShortcut", value: "Open New Tab", comment: "The description of the open new tab siri shortcut")
}

// Intro Onboarding slides
extension Strings {
    // First Card
    public static let CardTitleWelcome = NSLocalizedString("Intro.Slides.Welcome.Title", tableName: "Intro", value: "gemini://", comment: "Title for the first panel 'Welcome' in the intro tour.")
    public static let CardTextWelcome = NSLocalizedString("Intro.Slides.Welcome.Description", tableName: "Intro", value: "A new internet protocol.", comment: "Description for the 'Welcome' panel in the intro tour.")
    public static let IntroNextButtonTitle = NSLocalizedString("Intro.Slides.Welcome.Next", tableName: "Intro", value: "Next", comment: "Next button on the first intro panel.")

    // Second Card
    public static let CardTitleNext = NSLocalizedString("Intro.Slides.Next.Title", tableName: "Intro", value: "Web, but stripped to its essence", comment: "Title for the second intro panel in the intro tour.")
    public static let CardTextNext = NSLocalizedString("Intro.Slides.Next.Description", tableName: "Intro", value: "No banner ads, slow pages, gunk.", comment: "Description second panel in the intro tour.")
    public static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "Start browsing button to finish intro.")
}

// Keyboard short cuts
extension Strings {
    public static let ShowTabTrayFromTabKeyCodeTitle = NSLocalizedString("Tab.ShowTabTray.KeyCodeTitle", value: "Show All Tabs", comment: "Hardware shortcut to open the tab tray from a tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.CloseTab.KeyCodeTitle", value: "Close Selected Tab", comment: "Hardware shortcut to close the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let CloseAllTabsFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.CloseAllTabs.KeyCodeTitle", value: "Close All Tabs", comment: "Hardware shortcut to close all tabs from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenSelectedTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.OpenSelectedTab.KeyCodeTitle", value: "Open Selected Tab", comment: "Hardware shortcut open the selected tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let OpenNewTabFromTabTrayKeyCodeTitle = NSLocalizedString("TabTray.OpenNewTab.KeyCodeTitle", value: "Open New Tab", comment: "Hardware shortcut to open a new tab from the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
}

// Share extension
extension Strings {
    public static let SendToCancelButton = NSLocalizedString("SendTo.Cancel.Button", bundle: applicationBundle(), value: "Cancel", comment: "Button title for cancelling share screen")
    public static let SendToErrorOKButton = NSLocalizedString("SendTo.Error.OK.Button", bundle: applicationBundle(), value: "OK", comment: "OK button to dismiss the error prompt.")
    public static let SendToErrorTitle = NSLocalizedString("SendTo.Error.Title", bundle: applicationBundle(), value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.")
    public static let SendToErrorMessage = NSLocalizedString("SendTo.Error.Message", bundle: applicationBundle(), value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.")

    public static let ShareOpenInGemini = NSLocalizedString("ShareExtension.OpenInGeminiAction.Title", value: "Open in Elaho", comment: "Action label on share extension to immediately open page in Elaho.")
    public static let ShareSearchInGemini = NSLocalizedString("ShareExtension.SeachInGeminiAction.Title", value: "Search in Elaho", comment: "Action label on share extension to search for the selected text in Elaho.")

    public static let ShareLoadInBackground = NSLocalizedString("ShareExtension.LoadInBackgroundAction.Title", value: "Load in Background", comment: "Action label on share extension to load the page in Elaho when user switches apps to bring it to foreground.")
    public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtension.LoadInBackgroundActionDone.Title", value: "Loading in Elaho", comment: "Share extension label shown after user has performed 'Load in Background' action.")
}

// SearchSettings
extension String {
    public static let SearchSettingsTitle = NSLocalizedString("Search", comment: "Navigation title for search settings.")
    public static let SearchSettingsDefaultSearchEngineAccessibilityLabel = NSLocalizedString("Default Search Engine", comment: "Accessibility label for default search engine setting.")
    public static let SearchSettingsDefaultSearchEngineTitle = NSLocalizedString("Default Search Engine", comment: "Title for default search engine settings section.")
    public static let SearchSettingsQuickSearchEnginesTitle = NSLocalizedString("Quick-Search Engines", comment: "Title for quick-search engines settings section.")
}

// TimeConstants
extension String {
    public static let TimeConstantMoreThanAMonth = NSLocalizedString("more than a month ago", comment: "Relative date for dates older than a month and less than two months.")
    public static let TimeConstantMoreThanAWeek = NSLocalizedString("more than a week ago", comment: "Description for a date more than a week ago, but less than a month ago.")
    public static let TimeConstantYesterday = NSLocalizedString("yesterday", comment: "Relative date for yesterday.")
    public static let TimeConstantThisWeek = NSLocalizedString("this week", comment: "Relative date for date in past week.")
    public static let TimeConstantRelativeToday = NSLocalizedString("today at %@", comment: "Relative date for date older than a minute.")
    public static let TimeConstantJustNow = NSLocalizedString("just now", comment: "Relative time for a tab that was visited within the last few moments.")
}

// Gemini
extension Strings {
    public static let GeminiCouldNotRender = NSLocalizedString("Could not render", comment: "Error to show when client could not render a page.")
    public static let GeminiCouldNotDownloadFile = NSLocalizedString("Could not download file", comment: "Error to show when client could not download a file.")
    public static let GeminiCouldNotFindAWayToRedirect = NSLocalizedString("Could not find a way to redirect to %@", comment: "Error to show when client could not redirect user.")
    public static let GeminiCouldNotParseBodyWithEncoding = NSLocalizedString("Could not parse body with encoding %@", comment: "Error to show when client could not parse response.")
    public static let GeminiCouldNotParseBody = NSLocalizedString("Could not parse body", comment: "Error to show when client could not parse response.")
    public static let GeminiCouldNotRedirect = NSLocalizedString("Could not redirect to %@", comment: "Error to show when.")
    public static let GeminiCouldNotRenderForm = NSLocalizedString("Could not render form to ask server's question: %@", comment: "Error to show when client could not render an input form.")
    public static let GeminiCouldNotRenderCertificationMessage = NSLocalizedString("Could not render server's certification message: %@", comment: "Error to show when client could not render server's certification message.")
    public static let GeminiCouldNotPrepareRequest = NSLocalizedString("Could not prepare request to %@", comment: "Error to show when client could not prepare a request to server.")
    public static let GeminiInvalidHeader = NSLocalizedString("Invalid header: %@", comment: "Error to show when server responds with an invalid header.")
    public static let GeminiInvalidResponse = NSLocalizedString("Invalid response", comment: "Error to show when server responds with an invalid response.")
    public static let GeminiPleaseConfirmRedirect = NSLocalizedString("Please confirm redirect", comment: "Title to show when user is redirected to another server.")
    public static let GeminiServerRespondedWithNoContent = NSLocalizedString("Server responded with no content", comment: "Error to show when server did not send any response.")
    public static let GeminiSlowDown = NSLocalizedString("Slow down: please wait at least %@ seconds before retrying", comment: "Error to show when server requested that user slows down with requests.")
    public static let GeminiSubmit = NSLocalizedString("Submit", comment: "Button title to submit user input.")
    public static let GeminiTooManyRedirects = NSLocalizedString("Too many redirects", comment: "Error to show when user is being redirected too many times.")

    public static let GeminiUnlabelledPreformattedText = NSLocalizedString("Unlabelled preformatted text", comment: "Accessibility title for unlabelled preformatted text.")
}

// MenuHelper
extension String {
    public static let MenuHelperPasteAndGo = NSLocalizedString("UIMenuItem.PasteGo", value: "Paste & Go", comment: "The menu item that pastes the current contents of the clipboard into the URL bar and navigates to the page")
    public static let MenuHelperReveal = NSLocalizedString("Reveal", tableName: "LoginManager", comment: "Reveal password text selection menu item")
    public static let MenuHelperHide =  NSLocalizedString("Hide", tableName: "LoginManager", comment: "Hide password text selection menu item")
    public static let MenuHelperCopy = NSLocalizedString("Copy", tableName: "LoginManager", comment: "Copy password text selection menu item")
    public static let MenuHelperOpenAndFill = NSLocalizedString("Open & Fill", tableName: "LoginManager", comment: "Open and Fill website text selection menu item")
    public static let MenuHelperFindInPage = NSLocalizedString("Find in Page", tableName: "FindInPage", comment: "Text selection menu item")
    public static let MenuHelperSearchWithGemini = NSLocalizedString("UIMenuItem.SearchWithGemini", value: "Search with Gemini", comment: "Search in New Tab Text selection menu item")
}
