import { ZoomMtg } from '@zoomus/websdk';

require("@zoomus/websdk/dist/css/bootstrap.css");
require("@zoomus/websdk/dist/css/react-select.css");

require("../../../semantic/dist/semantic.css")
require("stylesheets/zoom.scss")

function on_element_created(is_selected, on_created, on_changed) {
    // select the target node
    var target = document.getRootNode();

    // create an observer instance
    var observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            mutation.addedNodes.forEach(function (element) {
                //console.log('created', element);
                if (is_selected(element)) {
                    if (on_created) {
                        on_created(element);
                    } else {
                        var button = element.children[0];
                        //console.log("on_element_created", class_name, button);
                        var observer_button = new MutationObserver(function (mutations) {
                            on_changed(button);
                            observer_button.disconnect();
                        });
                        observer_button.observe(button, {
                            attributes: true,
                            attributeOldValue: true,
                            characterData: true,
                            characterDataOldValue: true
                        });
                    }
                    observer.disconnect();
                }
            });
        });
    });

    const config = { subtree: true, childList: true };
    observer.observe(target, config);
}

function click_on_join_voip_when_displayed() {
    on_element_created(function(element) {
        return element.className === 'join-audio-by-voip';
    },
    null,
    function(button) {
        //console.log('join-by-voip-button.click()', button);
        button.click();
    });
}

function htmlToElement(html) {
    var template = document.createElement('template');
    html = html.trim(); // Never return a text node of whitespace as the result
    template.innerHTML = html;
    return template.content.firstChild;
}


function tip_button() {
    const elem = htmlToElement(
        '<button tabindex="0" class="footer-button__button ax-outline" type="button" aria-label="Give a tip">' +
        '<div class="footer-button__img-layer">' +
        '<i id="tip-icon" class="hand holding usd icon"></i>' +
        '</div>' +
        '<span class="footer-button__button-label">Give a tip</span>' +
        '</button>');
    return elem;
}

function add_give_tip_button() {
    on_element_created(function(element) {
        return element.data === 'Chat' && element.parentElement && element.parentElement.className === 'footer-button__button-label';
    }, function(elem) {
        //console.log('Chat', elem);
        elem.parentElement.parentElement.parentElement.appendChild(tip_button());
    },
    null);
}

function hide_participants_button() {
    on_element_created(function(element) {
        return element.data === 'Participants' && element.parentElement && element.parentElement.className === 'footer-button__button-label';
    }, function(elem) {
        //console.log('Participants', elem);
        elem.parentElement.parentElement.style.display = 'none';
    },
    null);
}

ZoomMtg.setZoomJSLib('https://source.zoom.us/1.9.9/lib', '/av');
ZoomMtg.preLoadWasm();
ZoomMtg.prepareJssdk();


init_zoom();
click_on_join_voip_when_displayed();
add_give_tip_button();
hide_participants_button();