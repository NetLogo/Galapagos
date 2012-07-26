/*
 * Event handlers
 */

function clearChat() {
    $chatLog.text('');
    state = 0;
    logList = [];
    $inputBuffer.focus();
}
function nameSelect(id) {
    var row = $("#"+id);
    row.css({backgroundColor: '#0033CC', color: '#FFFFFF', fontWeight: 'bold'});
}
function nameDeselect(id) {
    var row = $('#'+id);
    row.css({backgroundColor: '#FFFFFF', color: '#000000', fontWeight: 'normal'});
}
function copySetup(text) {
    $copier.attr('name', text);
    $copier.val(text);
    $copier.focus();
    $copier.select();
}

function handleTextRowOnMouseUp(row) {
    getSelText();
    if ($textCopier.val() === '') {
        textCollapse(row);
        $container.focus();
    }
    return false;
}


/*
 * Event-handling utilities
 */

// Credit to Jeff Anderson
// Source: http://www.codetoad.com/javascript_get_selected_text.asp
function getSelText() {

    var txt = "";
    if (window.getSelection) {
        txt = window.getSelection();
    } else if (document.getSelection) {
        txt = document.getSelection();
    } else if (document.selection) {
        txt = document.selection.createRange().text;
    } else return;

    // The regular expression 'timestamp' matches time strings of the form hh:mm in 24-hour format.
    var timestamp = /\t((?:(?:[0-1][0-9])|(?:2[0-3])):[0-5][0-9])$/gm;
    var modText = txt.toString().replace(timestamp, "   [$1]");
    var finalText = modText.replace(/\t/g, "   ");
    $textCopier.hide();  // Hide to avoid ghostly scrollbar issue on Chrome/Safari (on Mac OS)
    $textCopier.val(finalText);

}

function textCollapse(row) {
    var textObj = logList[row.id];
    var middle = row.getElementsByClassName('middle')[0];
    textObj.change();
    middle.innerHTML = textObj.toString();
}
