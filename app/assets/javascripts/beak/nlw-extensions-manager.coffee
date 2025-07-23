


# This is a singleton class for managing NetLogo Web (NLW) extensions.
# There is a few, unfortunately, global objects that we have to depend on:
#  1. Extensions.          -- Managed by Tortoise Engine
#  2. nlwExtensionsManager -- Managed by Galapagos
class NLWExtensionManager
    @instance: null
    constructor: (compiler) ->
        if NLWExtensionManager.instance?
            return NLWExtensionManager.instance

        NLWExtensionManager.instance = this
        window.nlwExtensionManager = NLWExtensionManager.instance

        @compiler = compiler
        @urlRepo = {}

    loadURLExtensions: (source) ->
        urlRepo = @urlRepo
        extensions = @compiler.listExtensions(source)
        url_extensions = Object.fromEntries (await Promise.all(extensions
            .filter((ext) -> ext.url != null)                     
            .map((ext) ->
                {name, url} = ext
                baseName = NLWExtensionManager.getBaseNameFromURL(url)
                primURL  = NLWExtensionManager.getPrimitiveJSONSrc(url)
                if urlRepo[baseName]?
                    # If the extension is already loaded, just return it
                    return [baseName, urlRepo[baseName]]
                # We want to get a lazy loader for the extension,
                # and fetch the primitives JSON file before we 
                # trigger the recompilation.   
                return Promise.resolve().then(() ->
                    prims = await NLWExtensionManager.fetchPrimitives(primURL)
                    NLWExtensionManager.confirmNamesMatch(prims, name)
                    return [baseName, {
                        getExtension: () -> import(url),
                        prims
                    }]
                )
            )
        ))

        Object.assign(@urlRepo, url_extensions)
        NLWExtensionManager.updateGlobalExtensionsObject(url_extensions)
        console.log("Loaded URL extensions:", url_extensions)
        url_extensions

    # Helpers
    @updateGlobalExtensionsObject: (url_extensions) ->
        # Update the global Extensions object with the new URL extensions
        if not window.Extensions?
            window.Extensions = {}
        for _, ext of url_extensions
            key = ext.prims.name
            if window.Extensions[key]?
                console.warn("Extension '#{key}' already exists in global Extensions object.")
            window.Extensions[key] = ext
        console.log("NLW Extensions updated in global object:", window.Extensions)

    @confirmNamesMatch: (primitives, name) ->
        # Check if the primitives JSON file name matches the extension name
        if primitives?.name.toLowerCase() isnt name.toLowerCase()
            console.warn("Primitives JSON file name '#{primitives.name.toLowerCase()}' does not match extension import name '#{name.toLowerCase()}'")

    @fetchPrimitives: (primURL) ->
        try
            response = await fetch(primURL)
            if response.ok
               return await response.json()
            else
                throw new Error("Failed to fetch primitives from #{primURL}: HTTP #{response.status}")
        catch ex
            console.error("Error fetching primitives from #{primURL}: #{ex.message}")
        return null

    @getBaseNameFromURL: (url) ->
        # Remove the file extension from the URL
        # to get the base name. By convention, the
        # primitives JSON file is named after the extension
        # base name, with a .json extension.
        # e.g. "my-extension.js" becomes "my-extension.json"
        url.split('.').slice(0, -1).join('.')
    
    @getPrimitiveJSONSrc: (url) ->
        # Get the base name from the URL and append '.json'
        baseName = NLWExtensionManager.getBaseNameFromURL(url)
        return "#{baseName}.json"


# Exports
export default NLWExtensionManager