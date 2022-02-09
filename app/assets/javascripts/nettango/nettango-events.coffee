netTangoEvents = Object.freeze([
  {
    'name': 'nettango-error'
  , 'args': [
      'source'    # 'parse-project-json' | 'load-from-url' | 'export-nlogo' | 'export-html' | 'load-library-json' | 'json-apply' | 'workspace-refresh'
    , 'exception' # Exception
    ]
  }
])

export { netTangoEvents }
