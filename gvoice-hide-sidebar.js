// ==UserScript==
// @name         Hide Google Voice sidebar
// @version      0.1
// @author       Adam Saponara
// @match        https://voice.google.com/*
// ==/UserScript==

(function() {
    'use strict';
    for (let gv of document.getElementsByTagName('gv-call-sidebar')) {
        gv.style.display = 'none';
    }
})();
