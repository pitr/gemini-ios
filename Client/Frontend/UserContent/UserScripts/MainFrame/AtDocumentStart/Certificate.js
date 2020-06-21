"use strict";

window.addEventListener("DOMContentLoaded", function() {
  if(document.getElementById("need-certificate")) {
    webkit.messageHandlers.certificateHelper.postMessage({transient: false});
  }
});
