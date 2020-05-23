const glob = require("glob");
const path = require("path");

const UglifyJsPlugin = require("terser-webpack-plugin");

const AllFramesAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentStart/*.js");
const AllFramesAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentEnd/*.js");
const MainFrameAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentStart/*.js");
const MainFrameAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentEnd/*.js");

// Ensure the first script loaded at document start is __gemini__.js
// since it defines the `window.__gemini__` global.
const needsFirefoxFile = {
  AllFramesAtDocumentStart,

  // PDF content does not execute user scripts designated to
  // run at document start for some reason. So, we also need
  // to include __gemini__.js for the document end scripts.
  // ¯\_(ツ)_/¯
  AllFramesAtDocumentEnd,
};

for (let [name, files] of Object.entries(needsFirefoxFile)) {
  if (path.basename(files[0]) !== "__gemini__.js") {
    throw `ERROR: __gemini__.js is expected to be the first script in ${name}.js`;
  }
}

module.exports = {
  mode: "production",
  entry: {
    AllFramesAtDocumentStart,
    AllFramesAtDocumentEnd,
    MainFrameAtDocumentStart,
    MainFrameAtDocumentEnd,
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "Client/Assets")
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules\/(?!(readability|page-metadata-parser)\/).*/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [
              ["@babel/preset-env", {
                targets: {
                  iOS: "10.3"
                }
              }]
            ]
          }
        }
      }
    ]
  },
  plugins: [
    new UglifyJsPlugin()
  ]
};
