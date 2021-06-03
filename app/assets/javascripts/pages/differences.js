import "/codemirror-mode.js";

window.addEventListener('load', function() {
  var elem    = document.getElementById('wait-example-code');
  var config  = { mode: 'netlogo', readOnly: 'nocursor', theme: 'netlogo-default', viewportMargin: Infinity };
  var editor  = CodeMirror.fromTextArea(elem, config);
  editor.setSize(null, 375);
});
