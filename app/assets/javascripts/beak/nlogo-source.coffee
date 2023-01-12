import { normalizedFileName } from "./tortoise-utils.js"

dropNlogoExtension = (s) ->
  if s.toLocaleLowerCase().endsWith('.nlogo')?
    s.slice(0, -6)
  else
    s

class NlogoSource
  constructor: (@type, @fileName) ->

  # () => String
  getModelTitle: () ->
    dropNlogoExtension(@fileName)

  # () => String
  getWipKey: () ->
    'dummy'

class UrlSource extends NlogoSource
  constructor: (url) ->
    super('url', normalizedFileName(url))
    @url = decodeURI(url)

  getWipKey: () ->
    @url

class DiskSource extends NlogoSource
  constructor: (fileName) ->
    super('disk', normalizedFileName(fileName))

  getWipKey: () ->
    "disk://#{@fileName}"

class NewSource extends NlogoSource
  constructor: () ->
    super('new', 'New Model')

  getWipKey: () ->
    'new'

class ScriptSource extends NlogoSource
  constructor: (fileName) ->
    super('script-element', normalizedFileName(fileName))

  getWipKey: () ->
    "script-element://#{@fileName}"

export {
  UrlSource
, DiskSource
, NewSource
, ScriptSource
}
