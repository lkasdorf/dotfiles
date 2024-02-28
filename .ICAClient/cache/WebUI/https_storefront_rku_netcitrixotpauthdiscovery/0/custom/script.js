// Edit this file to add your customized JavaScript or load additional JavaScript files.

CTXS.allowReloginWithoutBrowserClose = true

/* Example customization - Show a click through screen on web and native */

/*
var doneClickThrough = false;

// Before web login
CTXS.Extensions.beforeLogon = function (callback) {
    doneClickThrough = true;
    CTXS.ExtensionAPI.showMessage({
        messageTitle: "Welcome!",
        messageText: "Only for WWCo Employees",
        okButtonText: "Accept",
        okAction: callback
    });
};

// Before main screen (both web and native)
CTXS.Extensions.beforeDisplayHomeScreen = function (callback) {
    if (!doneClickThrough) {
        CTXS.ExtensionAPI.showMessage({
            messageTitle: "Welcome!",
            messageText: "Only for WWCo Employees",
            okButtonText: "Accept",
            okAction: callback
        });
    } else {
        callback();
    }
}; */

var req = new XMLHttpRequest();
req.open('GET', document.location, false);
req.send(null);

var servername = req.getResponseHeader('SF-ServerName');

$('.customAuthFooter').html(servername);
$('#customBottom').html(servername);

CTXS.Extensions.preProcessAppData = function(store, appData) {
    if (appData.bundles) {
        $.each(appData.bundles, function(i, bundle) {
            bundle.numAppsToShow = 10;
        });
    }
};

CTXS.ExtensionsHead.postRedraw = function() {

    if (CTXS.currentView == 'store' && $('.store-toolbar .selected').hasClass('folder-view')) {

        $('.applicationBundleContainer').show();

    }

};

/* End of example customization */