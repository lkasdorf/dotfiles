(function ($) {
    var cultureSettings = {
        name: "zh-TW",
        englishName: "Chinese (Traditional, Taiwan)",
        nativeName: "繁體中文(台灣)",
        stringBundle: "receiver/js/localization/zh-TW/ctxs.strings.zh-TW_3D2A507FDF04B0F3.js",
        customStringBundle: "custom/strings.zh-TW.js"
    };
    
    $.globalization.availableCulture("zh-TW", cultureSettings);
    $.globalization.availableCulture("zh-Hant", cultureSettings);
})(jQuery);