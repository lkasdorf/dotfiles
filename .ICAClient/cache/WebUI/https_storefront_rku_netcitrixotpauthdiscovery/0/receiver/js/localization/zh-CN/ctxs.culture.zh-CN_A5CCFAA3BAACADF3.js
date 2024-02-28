(function ($) {
    var cultureSettings = {
        name: "zh-CN",
        englishName: "Chinese (Simplified, PRC)",
        nativeName: "简体中文(中华人民共和国)",
        stringBundle: "receiver/js/localization/zh-CN/ctxs.strings.zh-CN_133F2A428C5087DA.js",
        customStringBundle: "custom/strings.zh-CN.js"
    };
    
    $.globalization.availableCulture("zh-CN", cultureSettings);
    $.globalization.availableCulture("zh-Hans", cultureSettings);
})(jQuery);