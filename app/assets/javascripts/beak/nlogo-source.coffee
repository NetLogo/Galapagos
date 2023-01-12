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
    @url = url

  getWipKey: () ->
    @url

class DiskSource extends NlogoSource
  constructor: (fileName) ->
    super('disk', fileName)

  getWipKey: () ->
    "disk://#{@fileName}"

class NewSource extends NlogoSource
  constructor: () ->
    super('new', 'New Model.nlogo')

  getWipKey: () ->
    'new'

class ScriptSource extends NlogoSource
  constructor: (fileName) ->
    super('script-element', fileName)

  getWipKey: () ->
    "script-element://#{@fileName}"

export {
  UrlSource
, DiskSource
, NewSource
, ScriptSource
}
