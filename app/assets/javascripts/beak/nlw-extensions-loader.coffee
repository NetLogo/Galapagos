


# This is a singleton class for managing NetLogo Web (NLW) extensions.
# There is a few, unfortunately, global objects that we have to depend on:
#  1. Extensions.          -- Managed by Tortoise Engine
#  2. URLExtensionsRepo    -- Managed by Galapagos
# 
# I tried to keep this file the main source of truth for NLW extensions as
# much as possible. This works hand-in-hand with the Tortoise Engine, particularly
# the NLWExtensionsManager class, which is responsible for managing the
# extensions in the Tortoise Engine.
#
# A lot of the functionality here is part of an API used by the Tortoise Engine.
# I could've implemented those in Scala, but I chose not to do so because
# I wanted to keep the NLW extensions management logic in JavaScript, where
# it is easier to work with URLs and dynamic imports.
# Also, because we cannot trigger asynchronous work in Scala and support in JavaScript
# easily––at least without the browser complaining about it––the `loadURLExtensions`
# had to be implemented in JavaScript anyways.
#
# - Omar Ibrahim, July 2025
#
class NLWExtensionsLoader
    @instance: null
    @allowedExtensions = ["js"]
    constructor: (compiler) ->
        if NLWExtensionsLoader.instance?
            return NLWExtensionsLoader.instance

        NLWExtensionsLoader.instance = this
        window.NLWExtensionsLoader = NLWExtensionsLoader.instance

        @compiler = compiler
        @urlRepo = {}

    loadURLExtensions: (source) ->
        urlRepo = @urlRepo
        extensions = @compiler.listExtensions(source)
        url_extensions = Object.fromEntries (await Promise.all(extensions
            .filter((ext) -> ext.url != null)                     
            .map((ext) ->
                {name, url} = ext
                baseName = NLWExtensionsLoader.getBaseNameFromURL(url)
                primURL  = NLWExtensionsLoader.getPrimitiveJSONSrc(url)
                if urlRepo[baseName]?
                    # If the extension is already loaded, just return it
                    return [baseName, urlRepo[baseName]]
                # We want to get a lazy loader for the extension,
                # and fetch the primitives JSON file before we 
                # trigger the recompilation.   
                return Promise.resolve().then(() ->
                    extensionModule = await NLWExtensionsLoader.getModuleFromURL(url)
                    prims = await NLWExtensionsLoader.fetchPrimitives(primURL)
                    NLWExtensionsLoader.confirmNamesMatch(prims, name)
                    return [baseName, {
                        extensionModule,
                        prims
                    }]
                )
            )
        ))

        Object.assign(@urlRepo, url_extensions)
        NLWExtensionsLoader.updateGlobalExtensionsObject(url_extensions)
        url_extensions

    # Public API
    getPrimitivesFromURL: (url) ->
        # Get the primitives JSON file from the URL, if it exists
        url = @removeURLProtocol(url)
        baseName = NLWExtensionsLoader.getBaseNameFromURL(url)
        if @urlRepo[baseName]?
            return @urlRepo[baseName].prims
        else
            return null

    getExtensionModuleFromURL: (url) ->
        # Get the extension module from the URL, if it exists
        url = @removeURLProtocol(url)
        baseName = NLWExtensionsLoader.getBaseNameFromURL(url)
        if @urlRepo[baseName]?
            return @urlRepo[baseName].extensionModule
        else
            return null

    appendURLProtocol: (url) ->
       if not url.startsWith("url://")
            return "url://" + url
        else
            return url

    removeURLProtocol: (name) ->
        # Remove the "url://" protocol from the name
        if name.startsWith("url://")
            return name.slice("url://".length)
        else
            return name

    isURL: (name) ->
        return name.startsWith("url://")

    validateURL: (url) ->
        url = @removeURLProtocol(url)
        try
            new URL(url)
            fileExtension = url.split('.').pop()
            if @allowedExtensions.includes(fileExtension)
                return true
            else
                console.error("Invalid file extension: #{fileExtension}. Allowed extensions are: #{@allowedExtensions.join(', ')}")
                return false 
        catch e
            console.error("Invalid URL: #{url} - #{e.message}")
            return false

    # Helpers
    @getModuleFromURL: (url) ->
        # Get the module from the URL, if it exists
        extensionImport = await import(url)
        extensionKeys = Object.keys(extensionImport)
        if extensionKeys.length > 0
            return extensionImport[extensionKeys[0]]
        else
            throw new Error("Extension module at #{url} does not export anything.")
            
    @updateGlobalExtensionsObject: (url_extensions) ->
        # Update the global Extensions object with the new URL extensions
        if not window.URLExtensionsRepo?
            window.URLExtensionsRepo = {}
        Object.assign(window.URLExtensionsRepo, url_extensions)

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
        baseName = NLWExtensionsLoader.getBaseNameFromURL(url)
        return "#{baseName}.json"


# Exports
export default NLWExtensionsLoader