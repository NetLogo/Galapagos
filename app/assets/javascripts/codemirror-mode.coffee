{ commands, constants, directives, linkVars, patchVars, reporters, turtleVars } = window.keywords

notWordCh = /[\s\[\(\]\)]/.source
wordCh    = /[^\s\[\(\]\)]/.source
wordEnd   = "(?=#{notWordCh}|$)"

wordRegEx    = (pattern) -> new RegExp("#{pattern}#{wordEnd}", 'i')
memberRegEx  = (words)   -> wordRegEx("(?:#{words.join('|')})")

# Rules for multiple states
commentRule  = {token: 'comment', regex: /;.*/}
constantRule = {token: 'constant', regex: memberRegEx(constants)}
openBracket  = {regex: /[\[\(]/, indent: true}
closeBracket = {regex: /[\]\)]/, dedent: true}
variable     = {token: 'variable', regex: new RegExp(wordCh + "+")}

# Some arrays are reversed so that longer strings match first - BCH 1/9/2015, JAB (4/28/18)
allReporters = [].concat(reporters, turtleVars, patchVars, linkVars).reverse()
CodeMirror.defineSimpleMode('netlogo', {
  start: [
    {token: 'keyword',  regex: wordRegEx("to(?:-report)?"), indent: true},
    {token: 'keyword',  regex: wordRegEx("end"), dedent: true},
    {token: 'keyword',  regex: memberRegEx(directives)},
    {token: 'keyword',  regex: wordRegEx("#{wordCh}*-own")},
    {token: 'command',  regex: memberRegEx(commands.reverse())},
    {token: 'reporter', regex: memberRegEx(allReporters)},
    {token: 'string',   regex: /"(?:[^\\]|\\.)*?"/},
    {token: 'number',   regex: /0x[a-f\d]+|[-+]?(?:\.\d+|\d+\.?\d*)(?:e[-+]?\d+)?/i},
    constantRule,
    commentRule,
    openBracket,
    closeBracket,
    variable,
  ],
  meta: {
      electricChars: "dD])\n" # The 'd's here are so that it reindents on `end`. BCH 1/9/2015,
    , lineComment:   ";"
  }
})
