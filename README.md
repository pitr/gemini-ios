Gemini for iOS
===============

A [Project Gemini](https://gemini.circumlunar.space/) browser.

This is a fork of an open source [Firefox Browser for iOS](https://github.com/mozilla-mobile/firefox-ios)

Download on [the App Store](https://apps.apple.com/app/id1514950389).

![Gemini screenshot](https://raw.githubusercontent.com/pitr/gemini-ios/master/screenshot.png)

Requirements
------------

This branch only works with [Xcode 11.4](https://apps.apple.com/app/xcode/id497799835), Swift 5.2 and supports iOS 12.0 and above.

Building the code
-----------------

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

## Building User Scripts

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
