import { normalizedFileName } from "./tortoise-utils.js"

dropNlogoExtension = (s) ->
  if s.toLocaleLowerCase().endsWith('.nlogo')?
    s.slice(0, -6)
  else
    s

class NlogoSource
  constructor: (@type, @fileName) ->

  getModelTitle: () ->
    dropNlogoExtension(@fileName)

class UrlSource extends NlogoSource
  constructor: (url) ->
    super('url', normalizedFileName(url))
    @url = url

class DiskSource extends NlogoSource
  constructor: (fileName) ->
    super('disk', fileName)

class NewSource extends NlogoSource
  constructor: () ->
    super('new', 'New Model.nlogo')

class ScriptSource extends NlogoSource
  constructor: (fileName) ->
    super('script-element', fileName)

export {
  UrlSource
, DiskSource
, NewSource
, ScriptSource
}
