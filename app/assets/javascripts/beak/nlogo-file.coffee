#
# NlogoFile class is a utility class to handle NetLogo files.
# This is not a full implementation. Expand as necessary.
#
class AbstractNlogoFile
    constructor: (source) ->
        @source = source

    getSource: ->
        return @source
    
    getCode: ->
        return 'dummy'

class NlogoXFile extends AbstractNlogoFile
    constructor: (source) ->
        super(source)
        parser = new DOMParser();
        @doc = parser.parseFromString(source, "text/xml");
        errorNode = @doc.querySelector("parsererror")
        if errorNode
            throw new Error("Invalid Nlogo XML: " + errorNode.textContent)

    getSource: ->
        return @source 
    
    getCode: ->
        codeElement = @doc.querySelector("code")
        codeText    = codeElement.innerHTML
        code        = if not codeText.startsWith("<![CDATA[")
            codeText
        else
            codeText.slice("<![CDATA[".length, -1 * ("]]>".length))

        return code

export { NlogoXFile }