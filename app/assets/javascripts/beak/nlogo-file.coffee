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

class NlogoFile extends AbstractNlogoFile
    constructor: (source) ->
        super(source)
        @delimiter = "@#$#@#$#@"

    getSource: ->
        return @source

    getCode: ->
        # Extract the code from the source using the delimiter
        parts = @source.split(@delimiter)
        if parts.length > 1
            return parts[0].trim()
        else
            return @source.trim()

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

export { NlogoXFile, NlogoFile }