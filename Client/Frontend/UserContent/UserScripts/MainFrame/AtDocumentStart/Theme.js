"use strict";

Object.defineProperty(window.__gemini__, "setTheme", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: function(theme){
      document.body.classList.remove("normal","dark");
      document.body.classList.add(theme);
  }
});
