import newModel from "../new-model.js"
import { normalizedFileName } from "./tortoise-utils.js"

dropNlogoExtension = (s) ->
  if s.toLocaleLowerCase().endsWith('.nlogo')
    s.slice(0, -6)
  else
    s

class NlogoSource
  constructor: (@type, @fileName, @nlogo) ->
    @_title = null

  setModelTitle: (title) ->
    @_title = title

  # () => String
  getModelTitle: () ->
    if @_title? then @_title else dropNlogoExtension(@fileName)

  # () => String
  getWipKey: () ->
    'dummy'

  # ((String) => String) => Unit
  transform: (nlogoTransformer) ->
    @nlogo = nlogoTransformer(@nlogo)
    return

class UrlSource extends NlogoSource
  constructor: (url, nlogo) ->
    super('url', normalizedFileName(url), nlogo)
    @url = decodeURI(url)

    # Treat relative/HTTP/HTTPS links to the same model as the same source.
    [@host, @path] = if @url.startsWith('http:') or @url.startsWith('https:')
      uri = new URL(@url)
      [uri.host, decodeURI(uri.pathname)]
    else
      # host-relative URL
      p = if @url.startsWith('/') then @url else "/#{@url}"
      [globalThis.location.host, p]

  getWipKey: () ->
    "url://#{@host}#{@path}"

class DiskSource extends NlogoSource
  constructor: (fileName, nlogo) ->
    super('disk', normalizedFileName(fileName), nlogo)

  getWipKey: () ->
    "disk://#{@fileName}"

class NewSource extends NlogoSource
  constructor: (nlogo = newModel) ->
    super('new', 'New Model', nlogo)

  getWipKey: () ->
    'new'

class ScriptSource extends NlogoSource
  constructor: (fileName, nlogo) ->
    super('script-element', normalizedFileName(fileName), nlogo)

  getWipKey: () ->
    "script-element://#{@fileName}"

export {
  UrlSource
, DiskSource
, NewSource
, ScriptSource
}
