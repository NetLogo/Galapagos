import newModel from "../new-model.js"
import { normalizedFileName } from "./tortoise-utils.js"

dropNlogoExtension = (s) ->
  if s.toLocaleLowerCase().endsWith('.nlogo')?
    s.slice(0, -6)
  else
    s

class NlogoSource
  constructor: (@type, @fileName, @nlogo) ->

  # () => String
  getModelTitle: () ->
    dropNlogoExtension(@fileName)

  # () => String
  getWipKey: () ->
    'dummy'

class UrlSource extends NlogoSource
  constructor: (url, nlogo) ->
    super('url', normalizedFileName(url), nlogo)
    @url = decodeURI(url)

  getWipKey: () ->
    @url

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
