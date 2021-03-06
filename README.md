![Logo](https://github.com/pitr/gemini-ios/raw/master/Client/Assets/Images.xcassets/AppIcon.appiconset/180.png)

# Elaho (Gemini for iOS)

[![app store](https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg)](https://apps.apple.com/app/id1514950389)

A [Project Gemini](https://gemini.circumlunar.space/) browser.

Supports latest Gemini standard, including:
- all status codes
- input (including sensitive input)
- client certificates
- all of text/gemini

Built on a fork of an open source [Firefox Browser for iOS](https://github.com/mozilla-mobile/firefox-ios), inheriting the following features:
- tabs
- bookmarks
- history
- customizable search engines
- share extension
- etc

Download on [the App Store](https://apps.apple.com/app/id1514950389). Supports iOS 12.0 and above.

![Gemini screenshot](https://raw.githubusercontent.com/pitr/gemini-ios/master/screenshot.png)

## Building Requirements

* [Relatively recent Xcode](https://apps.apple.com/app/xcode/id497799835)
* [Carthage](https://github.com/Carthage/Carthage)
* [Node.js](https://nodejs.org/) (to build user scripts)

### Building the code

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install Carthage and Node
    ```shell
    brew update
    brew install carthage
    brew install node
    ```
1. Clone the repository:
    ```shell
    git clone https://github.com/pitr/gemini-ios
    ```
1. Pull in the project dependencies:
    ```shell
    cd gemini-ios
    sh ./bootstrap.sh
    ```
1. Open `Client.xcodeproj` in Xcode.
1. Build the `Gemini` scheme in Xcode.

#### Building User Scripts

User Scripts (JavaScript injected into the `WKWebView`) are compiled, concatenated and minified using [webpack](https://webpack.js.org/). User Scripts to be aggregated are placed in the following directories:

```
/Client
|-- /Frontend
    |-- /UserContent
        |-- /UserScripts
            |-- /AllFrames
            |   |-- /AtDocumentEnd
            |   |-- /AtDocumentStart
            |-- /MainFrame
                |-- /AtDocumentEnd
                |-- /AtDocumentStart
```

This reduces the total possible number of User Scripts down to four. The compiled output from concatenating and minifying the User Scripts placed in these folders resides in `/Client/Assets` and are named accordingly:

* `AllFramesAtDocumentEnd.js`
* `AllFramesAtDocumentStart.js`
* `MainFrameAtDocumentEnd.js`
* `MainFrameAtDocumentStart.js`

To simplify the build process, these compiled files are checked-in to this repository. When adding or editing User Scripts, these files can be re-compiled with `webpack` manually. This requires Node.js to be installed and all required `npm` packages can be installed by running `npm install` in the root directory of the project. User Scripts can be compiled by running the following `npm` command in the root directory of the project:

```
npm run build
```
