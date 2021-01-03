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
    public static let TopSitesEmptyStateDescription = NSLocalizedString("TopSites.EmptyState.Description", value: "Your most visited sites will show up here.", comment: "Description label for the empty Top Sites state.")
    public static let TopSitesEmptyStateTitle = NSLocalizedString("TopSites.EmptyState.Title", value: "Welcome to Top Sites", comment: "The title for the empty Top Sites state")
    public static let TopSitesRemoveButtonAccessibilityLabel = NSLocalizedString("TopSites.RemovePage.Button", value: "Remove page — %@", comment: "Button shown in editing mode to remove this site from the top sites panel.")
}

// Activity Stream.
extension Strings {
    public static let ASTopSitesTitle =  NSLocalizedString("ActivityStream.TopSites.SectionTitle", value: "Top Sites", comment: "Section title label for Top Sites")
    public static let HighlightVistedText = NSLocalizedString("ActivityStream.Highlights.Visited", value: "Visited", comment: "The description of a highlight if it is a site the user has visited")
    public static let HighlightBookmarkText = NSLocalizedString("ActivityStream.Highlights.Bookmark", value: "Bookmarked", comment: "The description of a highlight if it is a site the user has bookmarked")
    public static let PocketTrendingText = NSLocalizedString("ActivityStream.Pocket.Trending", value: "Trending", comment: "The description of a Pocket Story")
    public static let PocketMoreStoriesText = NSLocalizedString("ActivityStream.Pocket.MoreLink", value: "More", comment: "The link that shows more Pocket trending stories")
    public static let TopSitesRowSettingFooter = NSLocalizedString("ActivityStream.TopSites.RowSettingFooter", value: "Set Rows", comment: "The title for the setting page which lets you select the number of top site rows")
    public static let TopSitesRowCount = NSLocalizedString("ActivityStream.TopSites.RowCount", value: "Rows: %d", comment: "label showing how many rows of topsites are shown. %d represents a number")
    public static let RecentlyBookmarkedTitle = NSLocalizedString("ActivityStream.NewRecentBookmarks.Title", value: "Recent Bookmarks", comment: "Section title label for recently bookmarked websites")
    public static let RecentlyVisitedTitle = NSLocalizedString("ActivityStream.RecentHistory.Title", value: "Recently Visited", comment: "Section title label for recently visited websites")
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
    public static let SettingsGeneralSectionTitle = NSLocalizedString("Settings.General.SectionName", value: "General", comment: "General settings section title")
    public static let SettingsClearPrivateDataClearButton = NSLocalizedString("Settings.ClearPrivateData.Clear.Button", value: "Clear Private Data", comment: "Button in settings that clears private data for the selected items.")
    public static let SettingsClearAllWebsiteDataButton = NSLocalizedString("Settings.ClearAllWebsiteData.Clear.Button", value: "Clear All Website Data", comment: "Button in Data Management that clears private data for the selected items.")
    public static let SettingsClearPrivateDataSectionName = NSLocalizedString("Settings.ClearPrivateData.SectionName", value: "Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsDataManagementSectionName = NSLocalizedString("Settings.DataManagement.SectionName", value: "Data Management", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
    public static let SettingsFilterSitesSearchLabel = NSLocalizedString("Settings.DataManagement.SearchLabel", value: "Filter Sites", comment: "Default text in search bar for Data Management")
    public static let SettingsClearPrivateDataTitle = NSLocalizedString("Settings.ClearPrivateData.Title", value: "Clear Private Data", comment: "Title displayed in header of the setting panel.")
    public static let SettingsDataManagementTitle = NSLocalizedString("Settings.DataManagement.Title", value: "Data Management", comment: "Title displayed in header of the setting panel.")
    public static let SettingsWebsiteDataTitle = NSLocalizedString("Settings.WebsiteData.Title", value: "Website Data", comment: "Title displayed in header of the Data Management panel.")
    public static let SettingsWebsiteDataShowMoreButton = NSLocalizedString("Settings.WebsiteData.ButtonShowMore", value: "Show More", comment: "Button shows all websites on website data tableview")
    public static let SettingsClearWebsiteDataMessage = NSLocalizedString("Settings.WebsiteData.ConfirmPrompt", value: "This action will clear all of your website data. It cannot be undone.", comment: "Description of the confirmation dialog shown when a user tries to clear their private data.")
    public static let SettingsEditWebsiteSearchButton = NSLocalizedString("Settings.WebsiteData.ButtonEdit", value: "Edit", comment: "Button to edit website search results")
    public static let SettingsDeleteWebsiteSearchButton = NSLocalizedString("Settings.WebsiteData.ButtonDelete", value: "Delete", comment: "Button to delete website in search results")
    public static let SettingsDoneWebsiteSearchButton = NSLocalizedString("Settings.WebsiteData.ButtonDone", value: "Done", comment: "Button to exit edit website search results")
    public static let SettingsSearchDoneButton = NSLocalizedString("Settings.Search.Done.Button", value: "Done", comment: "Button displayed at the top of the search settings.")
    public static let SettingsSearchEditButton = NSLocalizedString("Settings.Search.Edit.Button", value: "Edit", comment: "Button displayed at the top of the search settings.")
    public static let SettingsCopyAppVersionAlertTitle = NSLocalizedString("Settings.CopyAppVersion.Title", value: "Copied to clipboard", comment: "Copy app version alert shown in settings.")
}

// Error pages.
extension Strings {
    public static let ErrorPagesAdvancedButton = NSLocalizedString("ErrorPages.Advanced.Button", value: "Advanced", comment: "Label for button to perform advanced actions on the error page")
    public static let ErrorPagesAdvancedWarning1 = NSLocalizedString("ErrorPages.AdvancedWarning1.Text", value: "Warning: we can’t confirm your connection to this website is secure.", comment: "Warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesAdvancedWarning2 = NSLocalizedString("ErrorPages.AdvancedWarning2.Text", value: "It may be a misconfiguration or tampering by an attacker. Proceed if you accept the potential risk.", comment: "Additional warning text when clicking the Advanced button on error pages")
    public static let ErrorPagesCertWarningDescription = NSLocalizedString("ErrorPages.CertWarning.Description", value: "The owner of %@ has configured their website improperly. To protect your information from being stolen, Gemini has not connected to this website.", comment: "Warning text on the certificate error page")
    public static let ErrorPagesCertWarningTitle = NSLocalizedString("ErrorPages.CertWarning.Title", value: "This Connection is Untrusted", comment: "Title on the certificate error page")
    public static let ErrorPagesGoBackButton = NSLocalizedString("ErrorPages.GoBack.Button", value: "Go Back", comment: "Label for button to go back from the error page")
    public static let ErrorPagesVisitOnceButton = NSLocalizedString("ErrorPages.VisitOnce.Button", value: "Visit site anyway", comment: "Button label to temporarily continue to the site from the certificate error page")
}

// Logins Helper.
extension Strings {
    public static let LoginsHelperSaveLoginButtonTitle = NSLocalizedString("LoginsHelper.SaveLogin.Button", value: "Save Login", comment: "Button to save the user's password")
    public static let LoginsHelperDontSaveButtonTitle = NSLocalizedString("LoginsHelper.DontSave.Button", value: "Don’t Save", comment: "Button to not save the user's password")
    public static let LoginsHelperUpdateButtonTitle = NSLocalizedString("LoginsHelper.Update.Button", value: "Update", comment: "Button to update the user's password")
    public static let LoginsHelperDontUpdateButtonTitle = NSLocalizedString("LoginsHelper.DontUpdate.Button", value: "Don’t Update", comment: "Button to not update the user's password")
}

// Certificates Panel
extension Strings {
    public static let CertificatesPanelEmptyStateTitle = NSLocalizedString("CertificatesPanel.EmptyState.Title", value: "Certificates will show up here.", comment: "Title for the Certificates Panel empty state.")
    public static let CertificatesPanelDeleteTitle = NSLocalizedString("CertificatesPanel.Delete.Title", value: "Delete", comment: "Action button for deleting certificate in the Certificates panel.")
    public static let CertificatesPanelActivateTitle = NSLocalizedString("CertificatesPanel.Activate.Title", value: "Activate", comment: "Action button for activating Certificates in the Certificates panel.")
    public static let CertificatesPanelDeactivateTitle = NSLocalizedString("CertificatesPanel.Deactivate.Title", value: "Deactivate", comment: "Action button for deactivating Certificates in the Certificates panel.")
}

// History Panel
extension Strings {
    public static let HistoryBackButtonTitle = NSLocalizedString("HistoryPanel.HistoryBackButton.Title", value: "History", comment: "Title for the Back to History button in the History Panel")
    public static let SyncedTabsTableViewCellDescription = NSLocalizedString("HistoryPanel.SyncedTabsCell.Description.Pluralized", value: "%d device(s) connected", comment: "Description that corresponds with a number of devices connected for the Synced Tabs Cell in the History Panel")
    public static let HistoryPanelEmptyStateTitle = NSLocalizedString("HistoryPanel.EmptyState.Title", value: "Websites you’ve visited recently will show up here.", comment: "Title for the History Panel empty state.")
    public static let RecentlyClosedTabsButtonTitle = NSLocalizedString("HistoryPanel.RecentlyClosedTabsButton.Title", value: "Recently Closed", comment: "Title for the Recently Closed button in the History Panel")
    public static let RecentlyClosedTabsPanelTitle = NSLocalizedString("RecentlyClosedTabsPanel.Title", value: "Recently Closed", comment: "Title for the Recently Closed Tabs Panel")
    public static let HistoryPanelClearHistoryButtonTitle = NSLocalizedString("HistoryPanel.ClearHistoryButtonTitle", value: "Clear Recent History…", comment: "Title for button in the history panel to clear recent history")
    public static let FirefoxHomePage = NSLocalizedString("Firefox.HomePage.Title", value: "Gemini Home Page", comment: "Title for gemini about:home page in tab history list")
}

// Clear recent history action menu
extension Strings {
    public static let ClearHistoryMenuTitle = NSLocalizedString("HistoryPanel.ClearHistoryMenuTitle", value: "Clearing Recent History will remove history, cookies, and other browser data.", comment: "Title for popup action menu to clear recent history.")
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
    public static let privateBrowsingModeTitle = NSLocalizedString("Hotkeys.PrivateMode.DiscoveryTitle", value: "Private Browsing Mode", comment: "Label to switch to private browsing mode")
    public static let normalBrowsingModeTitle = NSLocalizedString("Hotkeys.NormalMode.DiscoveryTitle", value: "Normal Browsing Mode", comment: "Label to switch to normal browsing mode")
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
    public static let SettingsNewTabTopSites = NSLocalizedString("Settings.NewTab.Option.FirefoxHome", value: "Gemini Home", comment: "Option in settings to show Gemini Home when you open a new tab")
    public static let SettingsNewTabBookmarks = NSLocalizedString("Settings.NewTab.Option.Bookmarks", value: "Bookmarks", comment: "Option in settings to show bookmarks when you open a new tab")
    public static let SettingsNewTabHistory = NSLocalizedString("Settings.NewTab.Option.History", value: "History", comment: "Option in settings to show history when you open a new tab")
    public static let SettingsNewTabBlankPage = NSLocalizedString("Settings.NewTab.Option.BlankPage", value: "Blank Page", comment: "Option in settings to show a blank page when you open a new tab")
    public static let SettingsNewTabHomePage = NSLocalizedString("Settings.NewTab.Option.CustomPage", value: "Custom Page", comment: "Option in settings to show your custom page when you open a new tab")
    public static let SettingsNewTabDescription = NSLocalizedString("Settings.NewTab.Description", value: "When you open a New Tab:", comment: "A description in settings of what the new tab choice means")
    // AS Panel settings
    public static let SettingsNewTabASTitle = NSLocalizedString("Settings.NewTab.Option.ASTitle", value: "Customize Top Sites", comment: "The title of the section in newtab that lets you modify the topsites panel")
    public static let SettingsNewTabHiglightsHistory = NSLocalizedString("Settings.NewTab.Option.HighlightsHistory", value: "Visited", comment: "Option in settings to turn off history in the highlights section")
    public static let SettingsNewTabHighlightsBookmarks = NSLocalizedString("Settings.NewTab.Option.HighlightsBookmarks", value: "Recent Bookmarks", comment: "Option in the settings to turn off recent bookmarks in the Highlights section")
    public static let SettingsTopSitesCustomizeTitle = NSLocalizedString("Settings.NewTab.Option.CustomizeTitle", value: "Customize Gemini Home", comment: "The title for the section to customize top sites in the new tab settings page.")
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

// Root Bookmarks folders
extension Strings {
    public static let BookmarksFolderTitleMobile = NSLocalizedString("All Bookmarks", tableName: "Storage", comment: "The title of the folder that contains all bookmarks.")
}

// Bookmark Management
extension Strings {
    public static let BookmarksTitle = NSLocalizedString("Bookmarks.Title.Label", value: "Title", comment: "The label for the title of a bookmark")
    public static let BookmarksURL = NSLocalizedString("Bookmarks.URL.Label", value: "URL", comment: "The label for the URL of a bookmark")
    public static let BookmarksFolder = NSLocalizedString("Bookmarks.Folder.Label", value: "Folder", comment: "The label to show the location of the folder where the bookmark is located")
    public static let BookmarksNewBookmark = NSLocalizedString("Bookmarks.NewBookmark.Label", value: "New Bookmark", comment: "The button to create a new bookmark")
    public static let BookmarksNewFolder = NSLocalizedString("Bookmarks.NewFolder.Label", value: "New Folder", comment: "The button to create a new folder")
    public static let BookmarksNewSeparator = NSLocalizedString("Bookmarks.NewSeparator.Label", value: "New Separator", comment: "The button to create a new separator")
    public static let BookmarksEditBookmark = NSLocalizedString("Bookmarks.EditBookmark.Label", value: "Edit Bookmark", comment: "The button to edit a bookmark")
    public static let BookmarksEditFolder = NSLocalizedString("Bookmarks.EditFolder.Label", value: "Edit Folder", comment: "The button to edit a folder")
    public static let BookmarksFolderName = NSLocalizedString("Bookmarks.FolderName.Label", value: "Folder Name", comment: "The label for the title of the new folder")
    public static let BookmarksFolderLocation = NSLocalizedString("Bookmarks.FolderLocation.Label", value: "Location", comment: "The label for the location of the new folder")
    public static let BookmarksDeleteFolderWarningTitle = NSLocalizedString("Bookmarks.DeleteFolderWarning.Title", tableName: "BookmarkPanelDeleteConfirm", value: "This folder isn’t empty.", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderWarningDescription = NSLocalizedString("Bookmarks.DeleteFolderWarning.Description", tableName: "BookmarkPanelDeleteConfirm", value: "Are you sure you want to delete it and its contents?", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
    public static let BookmarksDeleteFolderCancelButtonLabel = NSLocalizedString("Bookmarks.DeleteFolderWarning.CancelButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Cancel", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
    public static let BookmarksDeleteFolderDeleteButtonLabel = NSLocalizedString("Bookmarks.DeleteFolderWarning.DeleteButton.Label", tableName: "BookmarkPanelDeleteConfirm", value: "Delete", comment: "Button label for the button that deletes a folder and all of its children.")
    public static let BookmarksPanelEmptyStateTitle = NSLocalizedString("BookmarksPanel.EmptyState.Title", value: "Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")
    public static let BookmarksPanelDeleteTableAction = NSLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")
    public static let BookmarkDetailFieldTitle = NSLocalizedString("Bookmark.DetailFieldTitle.Label", value: "Title", comment: "The label for the Title field when editing a bookmark")
    public static let BookmarkDetailFieldURL = NSLocalizedString("Bookmark.DetailFieldURL.Label", value: "URL", comment: "The label for the URL field when editing a bookmark")
    public static let BookmarkDetailFieldsHeaderBookmarkTitle = NSLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Bookmark.Title", value: "Bookmark", comment: "The header title for the fields when editing a Bookmark")
    public static let BookmarkDetailFieldsHeaderFolderTitle = NSLocalizedString("Bookmark.BookmarkDetail.FieldsHeader.Folder.Title", value: "Folder", comment: "The header title for the fields when editing a Folder")
}

// Tabs Delete All Undo Toast
extension Strings {
    public static let TabsDeleteAllUndoTitle = NSLocalizedString("Tabs.DeleteAllUndo.Title", value: "%d tab(s) closed", comment: "The label indicating that all the tabs were closed")
    public static let TabsDeleteAllUndoAction = NSLocalizedString("Tabs.DeleteAllUndo.Button", value: "Undo", comment: "The button to undo the delete all tabs")
    public static let TabSearchPlaceholderText = NSLocalizedString("Tabs.Search.PlaceholderText", value: "Search Tabs", comment: "The placeholder text for the tab search bar")
}

//Clipboard Toast
extension Strings {
    public static let GoToCopiedLink = NSLocalizedString("ClipboardToast.GoToCopiedLink.Title", value: "Go to copied link?", comment: "Message displayed when the user has a copied link on the clipboard")
    public static let GoButtonTittle = NSLocalizedString("ClipboardToast.GoToCopiedLink.Button", value: "Go", comment: "The button to open a new tab with the copied link")

    public static let SettingsOfferClipboardBarTitle = NSLocalizedString("Settings.OfferClipboardBar.Title", value: "Offer to Open Copied Links", comment: "Title of setting to enable the Go to Copied URL feature. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")
    public static let SettingsOfferClipboardBarStatus = NSLocalizedString("Settings.OfferClipboardBar.Status", value: "When Opening Gemini", comment: "Description displayed under the ”Offer to Open Copied Link” option. See https://bug1223660.bmoattachments.org/attachment.cgi?id=8898349")

    public static let SettingsUseInAppSafariTitle = NSLocalizedString("Settings.InAppSafari.Title", value: "Use In-App Safari", comment: "Title of setting to open http links in-app.")
    public static let SettingsUseInAppSafariStatus = NSLocalizedString("Settings.InAppSafari.Status", value: "Otherwise uses your default browser", comment: "Description displayed under the ”Use In-App Safari” option.")

    public static let SettingsShowLinkURLTitle = NSLocalizedString("Settings.ShowLinkURL.Title", value: "Show Link URL", comment: "Title of setting to show link URL")
    public static let SettingsShowLinkURLStatus = NSLocalizedString("Settings.ShowLinkURL.Status", value: "Instead of link title", comment: "Status of setting to show link URL")
    public static let SettingsDisableSiteThemeTitle = NSLocalizedString("Settings.DisableSiteTheme.Title", value: "Disable Site Themes", comment: "Title of setting to disable site-specific themes")
    public static let SettingsDisableSiteThemeStatus = NSLocalizedString("Settings.DisableSiteTheme.Status", value: "Site themes are auto-generated based on site URL", comment: "Status of setting to disable site-specific themes")
}

// Link Previews
extension Strings {
    public static let SettingsShowLinkPreviewsTitle = NSLocalizedString("Settings.ShowLinkPreviews.Title", value: "Show Link Previews", comment: "Title of setting to enable link previews when long-pressing links.")
    public static let SettingsShowLinkPreviewsStatus = NSLocalizedString("Settings.ShowLinkPreviews.Status", value: "When Long-pressing Links", comment: "Description displayed under the ”Show Link Previews” option")
}

// errors
extension Strings {
    public static let UnableToDownloadError = NSLocalizedString("Downloads.Error.Message", value: "Downloads aren’t supported in Gemini yet.", comment: "The message displayed to a user when they try and perform the download of an asset that Gemini cannot currently handle.")
    public static let UnableToAddPassErrorTitle = NSLocalizedString("AddPass.Error.Title", value: "Failed to Add Pass", comment: "Title of the 'Add Pass Failed' alert. See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorMessage = NSLocalizedString("AddPass.Error.Message", value: "An error occured while adding the pass to Wallet. Please try again later.", comment: "Text of the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToAddPassErrorDismiss = NSLocalizedString("AddPass.Error.Dismiss", value: "OK", comment: "Button to dismiss the 'Add Pass Failed' alert.  See https://support.apple.com/HT204003 for context on Wallet.")
    public static let UnableToOpenURLError = NSLocalizedString("OpenURL.Error.Message", value: "Gemini cannot open the page because it has an invalid address.", comment: "The message displayed to a user when they try to open a URL that cannot be handled by Gemini, or any external app.")
    public static let UnableToOpenURLErrorTitle = NSLocalizedString("OpenURL.Error.Title", value: "Cannot Open Page", comment: "Title of the message shown when the user attempts to navigate to an invalid link.")
}

// Certificate Helper
extension Strings {
    public static let CertificateHelperAlertCreate = NSLocalizedString("Certificates.Alert.Create", value: "Create Certificate", comment: "The label of the button the user will press to create certificate")
    public static let CertificatesButtonTitle = NSLocalizedString("Certificates.Toast.GoToCertificates.Button", value: "Certificates", comment: "The button to open a new tab with the Certificates home panel")
    public static let CancelDownloadDialogTitle = NSLocalizedString("Downloads.CancelDialog.Title", value: "Cancel Download", comment: "Alert dialog title when the user taps the cancel download icon.")
    public static let CancelDownloadDialogMessage = NSLocalizedString("Downloads.CancelDialog.Message", value: "Are you sure you want to cancel this download?", comment: "Alert dialog body when the user taps the cancel download icon.")
    public static let CancelDownloadDialogResume = NSLocalizedString("Downloads.CancelDialog.Resume", value: "Resume", comment: "Button declining the cancellation of the download.")
    public static let CancelDownloadDialogCancel = NSLocalizedString("Downloads.CancelDialog.Cancel", value: "Cancel", comment: "Button confirming the cancellation of the download.")
    public static let DownloadCancelledToastLabelText = NSLocalizedString("Downloads.Toast.Cancelled.LabelText", value: "Download Cancelled", comment: "The label text in the Download Cancelled toast for showing confirmation that the download was cancelled.")
    public static let DownloadFailedToastLabelText = NSLocalizedString("Downloads.Toast.Failed.LabelText", value: "Download Failed", comment: "The label text in the Download Failed toast for showing confirmation that the download has failed.")
    public static let DownloadFailedToastButtonTitled = NSLocalizedString("Downloads.Toast.Failed.RetryButton", value: "Retry", comment: "The button to retry a failed download from the Download Failed toast.")
    public static let DownloadMultipleFilesToastDescriptionText = NSLocalizedString("Downloads.Toast.MultipleFiles.DescriptionText", value: "1 of %d files", comment: "The description text in the Download progress toast for showing the number of files when multiple files are downloading.")
    public static let DownloadProgressToastDescriptionText = NSLocalizedString("Downloads.Toast.Progress.DescriptionText", value: "%1$@/%2$@", comment: "The description text in the Download progress toast for showing the downloaded file size (1$) out of the total expected file size (2$).")
    public static let DownloadMultipleFilesAndProgressToastDescriptionText = NSLocalizedString("Downloads.Toast.MultipleFilesAndProgress.DescriptionText", value: "%1$@ %2$@", comment: "The description text in the Download progress toast for showing the number of files (1$) and download progress (2$). This string only consists of two placeholders for purposes of displaying two other strings side-by-side where 1$ is Downloads.Toast.MultipleFiles.DescriptionText and 2$ is Downloads.Toast.Progress.DescriptionText. This string should only consist of the two placeholders side-by-side separated by a single space and 1$ should come before 2$ everywhere except for right-to-left locales.")
}

// Add Custom Search Engine
extension Strings {
    public static let SettingsAddCustomEngine = NSLocalizedString("Settings.AddCustomEngine", value: "Add Search Engine", comment: "The button text in Search Settings that opens the Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitle = NSLocalizedString("Settings.AddCustomEngine.Title", value: "Add Search Engine", comment: "The title of the  Custom Search Engine view.")
    public static let SettingsAddCustomEngineTitleLabel = NSLocalizedString("Settings.AddCustomEngine.TitleLabel", value: "Title", comment: "The title for the field which sets the title for a custom search engine.")
    public static let SettingsAddCustomEngineURLLabel = NSLocalizedString("Settings.AddCustomEngine.URLLabel", value: "URL", comment: "The title for URL Field")
    public static let SettingsAddCustomEngineTitlePlaceholder = NSLocalizedString("Settings.AddCustomEngine.TitlePlaceholder", value: "Search Engine", comment: "The placeholder for Title Field when saving a custom search engine.")
    public static let SettingsAddCustomEngineURLPlaceholder = NSLocalizedString("Settings.AddCustomEngine.URLPlaceholder", value: "URL (Replace Query with %s)", comment: "The placeholder for URL Field when saving a custom search engine")
    public static let SettingsAddCustomEngineSaveButtonText = NSLocalizedString("Settings.AddCustomEngine.SaveButtonText", value: "Save", comment: "The text on the Save button when saving a custom search engine")
}

// Context menu ButtonToast instances.
extension Strings {
    public static let ContextMenuButtonToastNewTabOpenedLabelText = NSLocalizedString("ContextMenu.ButtonToast.NewTabOpened.LabelText", value: "New Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewTabOpenedButtonText = NSLocalizedString("ContextMenu.ButtonToast.NewTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedLabelText = NSLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.LabelText", value: "New Private Tab opened", comment: "The label text in the Button Toast for switching to a fresh New Private Tab.")
    public static let ContextMenuButtonToastNewPrivateTabOpenedButtonText = NSLocalizedString("ContextMenu.ButtonToast.NewPrivateTabOpened.ButtonText", value: "Switch", comment: "The button text in the Button Toast for switching to a fresh New Private Tab.")
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
    public static let PhotoLibraryFirefoxWouldLikeAccessTitle = NSLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessTitle", value: "Gemini would like to access your Photos", comment: "")
    public static let PhotoLibraryFirefoxWouldLikeAccessMessage = NSLocalizedString("PhotoLibrary.FirefoxWouldLikeAccessMessage", value: "This allows you to save the image to your Camera Roll.", comment: "")
}

// App menu.
extension Strings {
    public static let AppMenuLibraryTitleString = NSLocalizedString("Menu.Library.Title", tableName: "Menu", value: "Your Library", comment: "Label for the button, displayed in the menu, used to open the Library")
    public static let AppMenuShowTabsTitleString = NSLocalizedString("Menu.ShowTabs.Title", tableName: "Menu", value: "Show Tabs", comment: "Label for the button, displayed in the menu, used to open the tabs tray")
    public static let AppMenuSharePageTitleString = NSLocalizedString("Menu.SharePageAction.Title", tableName: "Menu", value: "Share Page With…", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    public static let AppMenuCopyURLTitleString = NSLocalizedString("Menu.CopyAddress.Title", tableName: "Menu", value: "Copy Address", comment: "Label for the button, displayed in the menu, used to copy the page url to the clipboard.")
    public static let AppMenuNewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "Open New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    public static let AppMenuAddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Bookmark This Page", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    public static let AppMenuRemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    public static let AppMenuFindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find in Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    public static let AppMenuViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    public static let AppMenuViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    public static let AppMenuTranslatePageTitleString = NSLocalizedString("Menu.TranslatePageAction.Title", tableName: "Menu", value: "Translate Page", comment: "Label for the button, displayed in the menu, used to translate the current page.")
    public static let AppMenuSettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    public static let AppMenuCloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    public static let AppMenuOpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    public static let AppMenuTopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    public static let AppMenuBookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel.v2", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bookmarks home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuHistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel.v2", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuCertificatesTitleString = NSLocalizedString("Menu.OpenCertificatesAction.AccessibilityLabel.v2", tableName: "Menu", value: "Certificates", comment: "Accessibility label for the button, displayed in the menu, used to open the Certificates home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuSyncedTabsTitleString = NSLocalizedString("Menu.OpenSyncedTabsAction.AccessibilityLabel.v2", tableName: "Menu", value: "Synced Tabs", comment: "Accessibility label for the button, displayed in the menu, used to open the Synced Tabs home panel. Please keep as short as possible, <15 chars of space available.")
    public static let AppMenuLibrarySeeAllTitleString = NSLocalizedString("Menu.SeeAllAction.Title", tableName: "Menu", value: "See All", comment: "Label for the button, displayed in Gemini Home, used to see all Library panels.")
    public static let AppMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
    public static let TabTrayDeleteMenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.CloseAllTabs", value: "Close All Tabs", comment: "Accessibility label for the Close All Tabs menu button.")
    public static let AppMenuCopyURLConfirmMessage = NSLocalizedString("Menu.CopyURL.Confirm", value: "URL Copied To Clipboard", comment: "Toast displayed to user after copy url pressed.")
    public static let AppMenuAddBookmarkConfirmMessage = NSLocalizedString("Menu.AddBookmark.Confirm", value: "Bookmark Added", comment: "Toast displayed to the user after a bookmark has been added.")
    public static let AppMenuRemoveBookmarkConfirmMessage = NSLocalizedString("Menu.RemoveBookmark.Confirm", value: "Bookmark Removed", comment: "Toast displayed to the user after a bookmark has been removed.")
    public static let SendToDeviceTitle = NSLocalizedString("Send to Device", tableName: "3DTouchActions", comment: "Label for preview action on Tab Tray Tab to send the current tab to another device")
    public static let PageActionMenuTitle = NSLocalizedString("Menu.PageActions.Title", value: "Page Actions", comment: "Label for title in page action menu.")
    public static let AppMenuShowPageSourceString = NSLocalizedString("Menu.PageSourceAction.Title", tableName: "Menu", value: "View Page Source", comment: "Label for the button, displayed in the menu, used to show the html page source")
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
    public static let SendUsageSettingTitle = NSLocalizedString("Settings.SendUsage.Title", value: "Send Usage Data", comment: "The title for the setting to send usage data.")
    public static let SettingsSiriSectionName = NSLocalizedString("Settings.Siri.SectionName", value: "Siri Shortcuts", comment: "The option that takes you to the siri shortcuts settings page")
    public static let SettingsSiriSectionDescription = NSLocalizedString("Settings.Siri.SectionDescription", value: "Use Siri shortcuts to quickly open Gemini via Siri", comment: "The description that describes what siri shortcuts are")
    public static let SettingsSiriOpenURL = NSLocalizedString("Settings.Siri.OpenTabShortcut", value: "Open New Tab", comment: "The description of the open new tab siri shortcut")
}

// Do not track
extension Strings {
    public static let SettingsDoNotTrackTitle = NSLocalizedString("Settings.DNT.Title", value: "Send websites a Do Not Track signal that you don’t want to be tracked", comment: "DNT Settings title")
    public static let SettingsDoNotTrackOptionOnWithTP = NSLocalizedString("Settings.DNT.OptionOnWithTP", value: "Only when using Tracking Protection", comment: "DNT Settings option for only turning on when Tracking Protection is also on")
    public static let SettingsDoNotTrackOptionAlwaysOn = NSLocalizedString("Settings.DNT.OptionAlwaysOn", value: "Always", comment: "DNT Settings option for always on")
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
    public static let ReopenClosedTabKeyCodeTitle = NSLocalizedString("ReopenClosedTab.KeyCodeTitle", value: "Reopen Closed Tab", comment: "Hardware shortcut to reopen the last closed tab, from the tab or the tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToPBMKeyCodeTitle = NSLocalizedString("SwitchToPBM.KeyCodeTitle", value: "Private Browsing Mode", comment: "Hardware shortcut switch to the private browsing tab or tab tray. Shown in the Discoverability overlay when the hardware Command Key is held down.")
    public static let SwitchToNonPBMKeyCodeTitle = NSLocalizedString("SwitchToNonPBM.KeyCodeTitle", value: "Normal Browsing Mode", comment: "Hardware shortcut for non-private tab or tab. Shown in the Discoverability overlay when the hardware Command Key is held down.")
}

// Share extension
extension Strings {
    public static let SendToCancelButton = NSLocalizedString("SendTo.Cancel.Button", bundle: applicationBundle(), value: "Cancel", comment: "Button title for cancelling share screen")
    public static let SendToErrorOKButton = NSLocalizedString("SendTo.Error.OK.Button", bundle: applicationBundle(), value: "OK", comment: "OK button to dismiss the error prompt.")
    public static let SendToErrorTitle = NSLocalizedString("SendTo.Error.Title", bundle: applicationBundle(), value: "The link you are trying to share cannot be shared.", comment: "Title of error prompt displayed when an invalid URL is shared.")
    public static let SendToErrorMessage = NSLocalizedString("SendTo.Error.Message", bundle: applicationBundle(), value: "Only HTTP and HTTPS links can be shared.", comment: "Message in error prompt explaining why the URL is invalid.")
    public static let SendToCloseButton = NSLocalizedString("SendTo.Cancel.Button", bundle: applicationBundle(), value: "Close", comment: "Close button in top navigation bar")
    public static let SendToTitle = NSLocalizedString("SendTo.NavBar.Title", bundle: applicationBundle(), value: "Send Tab", comment: "Title of the dialog that allows you to send a tab to a different device")
    public static let SendToSendButtonTitle = NSLocalizedString("SendTo.SendAction.Text", bundle: applicationBundle(), value: "Send", comment: "Navigation bar button to Send the current page to a device")

    // The above items are re-used strings from the old extension. New strings below.

    public static let ShareBookmarkThisPage = NSLocalizedString("ShareExtension.BookmarkThisPageAction.Title", value: "Bookmark This Page", comment: "Action label on share extension to bookmark the page in Gemini.")
    public static let ShareBookmarkThisPageDone = NSLocalizedString("ShareExtension.BookmarkThisPageActionDone.Title", value: "Bookmarked", comment: "Share extension label shown after user has performed 'Bookmark this Page' action.")

    public static let ShareOpenInFirefox = NSLocalizedString("ShareExtension.OpenInFirefoxAction.Title", value: "Open in Gemini", comment: "Action label on share extension to immediately open page in Gemini.")
    public static let ShareSearchInFirefox = NSLocalizedString("ShareExtension.SeachInFirefoxAction.Title", value: "Search in Gemini", comment: "Action label on share extension to search for the selected text in Gemini.")

    public static let ShareLoadInBackground = NSLocalizedString("ShareExtension.LoadInBackgroundAction.Title", value: "Load in Background", comment: "Action label on share extension to load the page in Gemini when user switches apps to bring it to foreground.")
    public static let ShareLoadInBackgroundDone = NSLocalizedString("ShareExtension.LoadInBackgroundActionDone.Title", value: "Loading in Gemini", comment: "Share extension label shown after user has performed 'Load in Background' action.")

}

// Display Theme
extension Strings {
    public static let SettingsDisplayThemeTitle = NSLocalizedString("Settings.DisplayTheme.Title.v2", value: "Theme", comment: "Title in main app settings for Theme settings")
    public static let DisplayThemeBrightnessThresholdSectionHeader = NSLocalizedString("Settings.DisplayTheme.BrightnessThreshold.SectionHeader", value: "Threshold", comment: "Section header for brightness slider.")
    public static let DisplayThemeSectionFooter = NSLocalizedString("Settings.DisplayTheme.SectionFooter", value: "The theme will automatically change based on your display brightness. You can set the threshold where the theme changes. The circle indicates your display's current brightness.", comment: "Display (theme) settings footer describing how the brightness slider works.")
    public static let SystemThemeSectionHeader = NSLocalizedString("Settings.DisplayTheme.SystemTheme.SectionHeader", value: "System Theme", comment: "System theme settings section title")
    public static let SystemThemeSectionSwitchTitle = NSLocalizedString("Settings.DisplayTheme.SystemTheme.SwitchTitle", value: "Use System Light/Dark Mode", comment: "System theme settings switch to choose whether to use the same theme as the system")
    public static let ThemeSwitchModeSectionHeader = NSLocalizedString("Settings.DisplayTheme.SwitchMode.SectionHeader", value: "Switch Mode", comment: "Switch mode settings section title")
    public static let ThemePickerSectionHeader = NSLocalizedString("Settings.DisplayTheme.ThemePicker.SectionHeader", value: "Theme Picker", comment: "Theme picker settings section title")
    public static let DisplayThemeAutomaticSwitchTitle = NSLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatically", comment: "Display (theme) settings switch to choose whether to set the dark mode manually, or automatically based on the brightness slider.")
    public static let DisplayThemeAutomaticStatusLabel = NSLocalizedString("Settings.DisplayTheme.SwitchTitle", value: "Automatic", comment: "Display (theme) settings label to show if automatically switch theme is enabled.")
    public static let DisplayThemeAutomaticSwitchSubtitle = NSLocalizedString("Settings.DisplayTheme.SwitchSubtitle", value: "Switch automatically based on screen brightness", comment: "Display (theme) settings switch subtitle, explaining the title 'Automatically'.")
    public static let DisplayThemeManualSwitchTitle = NSLocalizedString("Settings.DisplayTheme.Manual.SwitchTitle", value: "Manually", comment: "Display (theme) setting to choose the theme manually.")
    public static let DisplayThemeManualSwitchSubtitle = NSLocalizedString("Settings.DisplayTheme.Manual.SwitchSubtitle", value: "Pick which theme you want", comment: "Display (theme) settings switch subtitle, explaining the title 'Manually'.")
    public static let DisplayThemeManualStatusLabel = NSLocalizedString("Settings.DisplayTheme.Manual.StatusLabel", value: "Manual", comment: "Display (theme) settings label to show if manually switch theme is enabled.")
    public static let DisplayThemeOptionLight = NSLocalizedString("Settings.DisplayTheme.OptionLight", value: "Light", comment: "Option choice in display theme settings for light theme")
    public static let DisplayThemeOptionDark = NSLocalizedString("Settings.DisplayTheme.OptionDark", value: "Dark", comment: "Option choice in display theme settings for dark theme")
}

// Cover Sheet
extension Strings {
    // Dark Mode Cover Sheet
    public static let CoverSheetV22DarkModeTitle = NSLocalizedString("CoverSheet.v22.DarkMode.Title", value: "Dark theme now includes a dark keyboard and dark splash screen.", comment: "Title for the new dark mode change in the version 22 app release.")
    public static let CoverSheetV22DarkModeDescription = NSLocalizedString("CoverSheet.v22.DarkMode.Description", value: "For iOS 13 users, Gemini now automatically switches to a dark theme when your phone is set to Dark Mode. To change this behavior, go to Settings > Theme.", comment: "Description for the new dark mode change in the version 22 app release. It describes the new automatic dark theme and how to change the theme settings.")
    
    // ETP Cover Sheet
    public static let CoverSheetETPTitle = NSLocalizedString("CoverSheet.v24.ETP.Title", value: "Protection Against Ad Tracking", comment: "Title for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPDescription = NSLocalizedString("CoverSheet.v24.ETP.Description", value: "Built-in Enhanced Tracking Protection helps stop ads from following you around. Turn on Strict to block even more trackers, ads, and popups. ", comment: "Description for the new ETP mode i.e. standard vs strict")
    public static let CoverSheetETPSettingsButton = NSLocalizedString("CoverSheet.v24.ETP.Settings.Button", value: "Go to Settings", comment: "Text for the new ETP settings button")
}
