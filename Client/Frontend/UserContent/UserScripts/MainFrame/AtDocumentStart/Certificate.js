"use strict";

window.addEventListener("DOMContentLoaded", function() {
  if(document.getElementById("need-certificate")) {
    webkit.messageHandlers.certificateHelper.postMessage({transient: false});
  }
  if(document.getElementById("need-transient-certificate")) {
    webkit.messageHandlers.certificateHelper.postMessage({transient: true});
  }
});
