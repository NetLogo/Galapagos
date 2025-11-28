import { markdownToHtml } from "/beak/tortoise-utils.js"

import { argbIntToCSS } from "/colors.js"
import RactiveWidget from "./widget.js"
import EditForm from "./edit-form.js"
import RactiveIntColorInput from "./subcomponent/int-color-input.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import RactiveEditFormFontSize from "./subcomponent/font-size.js"
import { RactiveEditFormLabeledInput } from "./subcomponent/labeled-input.js"

NoteEditForm = EditForm.extend({

  data: -> {
    backgroundLight:  undefined # Int
  , textColorLight:   undefined # Int
  , fontSize:         undefined # Number
  , markdown:         undefined # Boolean
  , text:             undefined # String
  , _backgroundLight: undefined # Int
  , _textColorLight:  undefined # Int
  }

  twoway: false

  components: {
    colorInput:   RactiveIntColorInput
  , formCheckbox: RactiveEditFormCheckbox
  , formFontSize: RactiveEditFormFontSize
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  genProps: (form) ->
    {
      backgroundLight: @get('_backgroundLight')
    ,         display: form.text.value
    ,        fontSize: parseInt(form.fontSize.value)
    ,        markdown: form.markdown.checked
    ,  textColorLight: @get('_textColorLight')
    }

  on: {
    init: ->
      # A hack (because two-way binding isn't fully properly disabling?!)
      # --Jason B. (4/11/18)
      @set('_backgroundLight', @get('backgroundLight'))
      @set('_textColorLight',  @get('textColorLight'))
      return
  }

  partials: {

    title: "Note"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <label for="{{id}}-text">Text</label><br>
      <textarea id="{{id}}-text" class="widget-edit-textbox"
                name="text" placeholder="Enter note text here..."
                value="{{text}}" autofocus></textarea>

      <spacer height="20px" />

      <div class="flex-row" style="align-items: center;">
        <div style="width: 100%;">
          <formFontSize id="{{id}}-font-size" name="fontSize" value="{{fontSize}}"/>
        </div>
      </div>
      <spacer height="10px" />

      <div style="width: 50%;">
        <div class="flex-row" style="align-items: center; width: 100%; justify-content: space-between;">
          <label for="{{id}}-text-color" class="widget-edit-input-label">Text color</label>
          <colorInput
            id="{{id}}-text-color" name="color" class="widget-edit-text widget-edit-input widget-edit-color-pick"
            value="{{_textColorLight}}" useAlpha="true" />
        </div>
        <div class="flex-row" style="align-items: center; width: 100%; justify-content: space-between;">
          <label for="{{id}}-background-color" class="widget-edit-input-label">Background color</label>
          <colorInput
            id="{{id}}-background-color" name="bgColor" class="widget-edit-text widget-edit-input widget-edit-color-pick"
            value="{{_backgroundLight}}" useAlpha="true" />
        </div>
      </div>

      <spacer height="15px" />

      <formCheckbox id="{{id}}-markdown" isChecked={{markdown}} labelText="Markdown" name="markdown" />

      """
    # coffeelint: enable=max_line_length

  }

})

HNWNoteEditForm = NoteEditForm

RactiveNote = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
    style:              ""
  }

  observe: {
    'dims': ->
      @updateStyleAndDisplay()

    'widget.*': ->
      @updateStyleAndDisplay()
  }

  updateStyleAndDisplay: ->
    widget          = @get('widget')
    dims            = @get('dims')
    color           = argbIntToCSS(widget.textColorLight)
    backgroundColor = argbIntToCSS(widget.backgroundLight)
    @set('style',   "#{dims} color: #{color}; font-size: #{widget.fontSize}px; background-color: #{backgroundColor};")
    @set('display', if widget.markdown then markdownToHtml(widget.display) else widget.display)
    return

  components: {
    editForm: NoteEditForm
  }

  eventTriggers: ->
    {}

  # (Widget) => Array[Any]
  getExtraNotificationArgs: () ->
    widget = @get('widget')
    [widget.display]

  minWidth:  13
  minHeight: 13

  template:
    """
    {{>editorOverlay}}
    {{>label}}
    {{>form}}
    """

  # coffeelint: disable=max_line_length
  partials: {

    # Note that ">{{ display }}</pre>" thing is necessary. Since <pre> formats
    # text exactly as it appears, an extra space between the ">" and the
    # "{{ display }}" would result in an actual newline in the widget.
    # BCH 7/28/2015
    label:
      """
      {{# widget.markdown }}
        <div
          id="{{id}}"
          class="netlogo-widget netlogo-note {{classes}}"
          style="{{style}}"
          >
          {{{display}}}
        </div>
      {{else}}
        <pre
          id="{{id}}"
          class="netlogo-widget netlogo-note {{classes}}"
          style="{{style}}"
          >{{display}}</pre>
      {{/ widget.markdown}}
      """

    form:
      """
      <editForm
        idBasis="{{id}}"
        textColorLight="{{widget.textColorLight}}"
        backgroundLight="{{widget.backgroundLight}}"
        fontSize="{{widget.fontSize}}"
        markdown="{{widget.markdown}}"
        text="{{widget.display}}"
        />
      """

  }
  # coffeelint: enable=max_line_length

})

RactiveHNWNote = RactiveNote.extend({
  components: {
    editForm: HNWNoteEditForm
  }
})

export { RactiveNote, RactiveHNWNote }
