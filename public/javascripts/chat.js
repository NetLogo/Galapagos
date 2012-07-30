/*
 * Created with JetBrains WebStorm.
 * User: Joe
 * Date: 6/22/12
 * Time: 4:50 PM
 */

// Imports
var TextHolder = exports.TextHolder;
var DoubleList = exports.DoubleList;
var CircleMap  = exports.CircleMap;

const THROTTLE_DELAY = 100;

// Variables into which to cache jQuery selector results
var $inputBuffer;
var $usersOnline;
var $chatLog;
var $container;
var $copier;
var $textCopier;
var $agentType;
var $outputState;

// Other globals
var userName;
var socket;
var state = 0;
var messageList = new DoubleList(20);
var agentTypeList = new CircleMap();
var logList = [];

// Onload
document.body.onload = function() {

    startup();
    initSelectors();
    initAgentList();

    $agentType.text(agentTypeList.getCurrent());
    var throttledSend = throttle(send, THROTTLE_DELAY);

    var WS = window['MozWebSocket'] ? MozWebSocket : WebSocket;
    socket = new WS(socketURL);

    //@WS
    socket.on('connected', function() {
        socket.emit('name reply', userName);
    });

    //@WS
    socket.on('users changed', function (data) {
        $usersOnline.text("");
        var user, row;
        for (user in data) {
            row = "<tr><td>" +
                "<input id='"+user+"' value='"+user+"' type='button' " +
                "onclick='copySetup(this.value)' " +
                "style='border:none; background-color: #FFFFFF; width: 100%; text-align: left'>" +
                "</td></tr>";
            $usersOnline.append(row);
        }
    });

    //@WS
    socket.on('message', function (data) {

        var d = new Date();
        var time = d.toTimeString().slice(0, 5);
        var user = data.user;
        var message = data.processed_message;
        var serverState = data.server_state;
        var final_text = "";

        switch (serverState) {
            case 0:
                final_text = message;
                break;
            case 1:
                final_text = message.reverse();
                break;
            case 2:
                final_text = message.wordReverse();
                break;
        }

        logList[state] = new TextHolder(final_text);
        var difference = $container[0].scrollHeight - $container.scrollTop();
        $chatLog.append(messageSwitcher(user, final_text, time));
        if ((difference === $container.innerHeight()) || (user === userName)) { textScroll(); }

    });

    var keyString =
            'abcdefghijklmnopqrstuvwxyz' +
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
            '1234567890!@#$%^&*()' +
            '\<>-_=+[{]};:",.?\\|\'`~';
    var keyArray = keyString.split('');
    var notNumberRE = /\D/g;

    Mousetrap.bind('tab', function(e) {
        e.preventDefault();
        agentTypeList.next();
        setShout();
    }, 'keydown');

    Mousetrap.bind(keyArray, function() {
        focusInput();
    }, 'keydown');

    Mousetrap.bind('enter', function(e) {
        if ((e.target.id === 'inputBuffer') && (/\S/g.test($inputBuffer.val()))) {
            throttledSend($inputBuffer.val());
        }
    });

    Mousetrap.bind(['up', 'down'], function(e) {
        if (e.target.id === 'inputBuffer') {
            var charCode = extractCharCode(e);
            e.preventDefault();
            scroll(charCode);
        }
    });

    Mousetrap.bind('space', function(e) {
        if ((e.target.id === 'container') ||
            (e.target.id === 'copier')) {
            e.preventDefault();
            textScroll();
            focusInput();
        }
    });

    Mousetrap.bind(['ctrl+c', 'command+c'], function(e) {
        // If there are only digit characters in e.target.id...
        // This would mean that e.target is a table row in the chat output.
        if ((e.target.id === 'container') || (!notNumberRE.test(e.target.id))) {
            $textCopier.show();  // Show so we can select the text for copying
            $textCopier.focus();
            $textCopier.select();
            setTimeout(function() {
                $textCopier.hide();
                focusInput();
            }, 50);
        }
    }, 'keydown');

    Mousetrap.bind('pageup', function() {
        $container.focus();
    });

};

/*
 * Basic page functionality
 */

function startup() {
    $.post('/validate_name', { username: prompt("Please type your user name:") }, function(data) {
        var obj = JSON.parse(data);
        if (obj['valid'] === 'true') {
            name = obj['body'];
        }
        else {
            document.location.href = '/client_error';
        }
    });
}

// Caching jQuery selector results for easy access throughout the code
function initSelectors() {
    $inputBuffer = $("#inputBuffer");
    $usersOnline = $("#usersOnline");
    $chatLog     = $("#chatLog");
    $container   = $("#container");
    $copier      = $("#copier");
    $textCopier  = $("#textCopier");
    $agentType   = $("#agentType");
    $outputState = $("#outputState");
}

function initAgentList() {
    var agentTypes = ['observer', 'turtles', 'patches', 'links'];
    agentTypes.map(function(type) { agentTypeList.append(type) });
}

function messageSwitcher(user, final_text, time) {

    var color;
    if (state % 2 === 0) {
        color = "#FFFFFF";
    } else {
        color = "#CCFFFF";
    }
    state++;

    return "<tr style='vertical-align: middle; outline: none; width: 100%; border-collapse: collapse;' onmouseup='handleTextRowOnMouseUp(this)' tabindex='1' id='"+(state-1)+"'>"+
               "<td style='color: #CC0000; width: 20%; background-color: " + color + "; border-color: " + color + "'>" +
                   user + ":" +
               "</td>" +
               "<td  class='middle' style='width: 70%; white-space: pre-wrap; word-wrap: break-word; background-color: " + color + "; border-color: " + color + "'>" +
                   final_text +
               "</td>" +
               "<td style='color: #00CC00; width: 10%; text-align: right; background-color: " + color + "; border-color: " + color + "'>" +
                   time +
               "</td>" +
           "</tr>";

}

function textScroll() {
    var bottom = $container[0].scrollHeight - $container.height();
    var font = $container.css('font-size');
    var size = parseInt(font.substr(0, font.length - 2));
    $container.scrollTop(bottom - size);
    $container.animate({'scrollTop': bottom}, 'fast');
}

// Credit to Remy Sharp.
// http://remysharp.com/2010/07/21/throttling-function-calls/
function throttle(fn, delay) {
    var timer = null;
    return function () {
        var context = this, args = arguments;
        clearTimeout(timer);
        timer = setTimeout(function () {
            fn.apply(context, args);
        }, delay);
    };
}

function extractCharCode(e) {
    if (e && e.which) {
        return e.which;
    } else if (window.event) {
        return window.event.which;
    } else {
        return e;  // Should pretty much never happen
    }
}

function setShout() {
    var newState = agentTypeList.getCurrent();
    $agentType.text(newState);
}

function scroll(key) {

    if (key === 38) { // Up arrow
        if (messageList.cursor === null) {
            messageList.addCurrent($inputBuffer.val(), agentTypeList.getCurrent());
            messageList.cursor = messageList.head;
        } else {
            messageList.cursor = messageList.cursor.prev != null ? messageList.cursor.prev : messageList.cursor;
        }
    } else if (key === 40) { // Down arrow
        messageList.cursor = messageList.cursor.next;
    }

    var info, type;
    if (messageList.cursor !== null) {
        info = messageList.cursor.data;
        type = messageList.cursor.type;
    } else {
        info = messageList.current.data;
        type = messageList.current.type;
        messageList.clearCursor();
    }

    agentTypeList.setCurrent(type);
    setShout();
    $inputBuffer.val(info);

}

function send(message) {

    var shout = $agentType.text();
    var output = $outputState.prop("checked");
    var packet = { Message: message, Shout: shout, Output: output };
    socket.json.send(packet);
    messageList.append(message, agentTypeList.getCurrent());
    messageList.clearCursor();
    $inputBuffer.val("");
    focusInput();

}

function focusInput() { $inputBuffer.focus() }
