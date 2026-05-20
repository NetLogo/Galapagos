import assert from 'assert'
import * as TortoiseUtils from '../../main/beak/tortoise-utils.js'

describe('TortoiseUtils', () ->
  describe('#toNetLogoWebMarkdown()', () ->
    assertConverts = (source, target) ->
      assert.equal(TortoiseUtils.toNetLogoWebMarkdown(source), target)

    it("doesn't mess with markdown without comments", () ->
      assertConverts("", "")
      assertConverts("# title here", "# title here")
    )

    it("converts comments to well-formatted markdown-style comments", () ->
      assertConverts("<!-- comment -->", "[nlw-comment]: <> (comment)")
      assertConverts("<!--- comment --->", "[nlw-comment]: <> (comment)")
      assertConverts("<!---   comment    --->", "[nlw-comment]: <> (comment)")
      assertConverts("<!----- comment ----->", "[nlw-comment]: <> (comment)")
      assertConverts("<!-- comment -->\n<!-- comment2 -->",
        "[nlw-comment]: <> (comment)\n[nlw-comment]: <> (comment2)")
      assertConverts("<!-- com-ment -->", "[nlw-comment]: <> (com-ment)")
    )

    # note: This produces markdown that is (depending on your parser)
    # invalid. However, adding newlines is tricky when converting back.
    it("does not add newlines to markdown-style comments", () ->
      assertConverts("<!-- comment --><!-- comment2 -->",
        "[nlw-comment]: <> (comment)[nlw-comment]: <> (comment2)")
    )
  )

  describe('#markdownToHtml()', () ->

    # --- basic rendering (marked) ---

    it('renders h1 headings', () ->
      assert.match(TortoiseUtils.markdownToHtml('# Hello World'), /<h1[^>]*>Hello World<\/h1>/)
    )

    it('renders bold and italic', () ->
      assert.match(TortoiseUtils.markdownToHtml('**bold**'),  /<strong>bold<\/strong>/)
      assert.match(TortoiseUtils.markdownToHtml('*italic*'),  /<em>italic<\/em>/)
    )

    it('renders inline code', () ->
      assert.match(TortoiseUtils.markdownToHtml('`code`'), /<code>code<\/code>/)
    )

    it('renders unordered lists', () ->
      result = TortoiseUtils.markdownToHtml('- item one\n- item two')
      assert.match(result, /<ul/)
      assert.match(result, /item one/)
    )

    it('converts single newlines to <br> (breaks: true)', () ->
      assert.match(TortoiseUtils.markdownToHtml('line one\nline two'), /<br/)
    )

    # --- DOMPurify sanitization (XSS vectors) ---

    it('strips script tags', () ->
      assert.doesNotMatch(TortoiseUtils.markdownToHtml('<script>alert(1)</script>'), /<script/)
    )

    it('strips inline event handlers', () ->
      assert.doesNotMatch(TortoiseUtils.markdownToHtml('<p onclick="alert(1)">text</p>'), /onclick/)
    )

    it('strips javascript: URIs from links', () ->
      assert.doesNotMatch(TortoiseUtils.markdownToHtml('[x](javascript:alert(1))'), /javascript:/)
    )

    it('strips data:text/html URIs from links', () ->
      assert.doesNotMatch(
        TortoiseUtils.markdownToHtml('[x](data:text/html,<script>alert(1)</script>)'),
        /data:text\/html/
      )
    )

    # --- safe content preserved ---

    it('preserves https links', () ->
      assert.match(
        TortoiseUtils.markdownToHtml('[NetLogo](https://ccl.northwestern.edu)'),
        /href="https:\/\/ccl\.northwestern\.edu"/
      )
    )

    it('preserves image tags with safe src', () ->
      assert.match(TortoiseUtils.markdownToHtml('![alt](image.png)'), /<img[^>]+src="image\.png"/)
    )

    # --- uponSanitizeElement hook ---

    it('does not crash when img src is not a workspace resource', () ->
      assert.doesNotThrow(() -> TortoiseUtils.markdownToHtml('![alt](missing.png)'))
    )

    it('substitutes workspace resource images with base64 data URIs', () ->
      global.workspace.resources['my-diagram.png'] = { extension: 'png', data: 'abc123==' }
      try
        result = TortoiseUtils.markdownToHtml('![diagram](my-diagram.png)')
        assert.match(result, /src="data:image\/png;base64,abc123=="/)
      finally
        delete global.workspace.resources['my-diagram.png']
    )
  )

  describe('#toNetLogoMarkdown()', () ->
    assertConverts = (source, target) ->
      assert.equal(TortoiseUtils.toNetLogoMarkdown(source), target)

    it("doesn't mess with markdown without comments", () ->
      assertConverts("", "")
      assertConverts("# h1", "# h1")
      assertConverts("text (in parentheses)", "text (in parentheses)")
    )

    it("converts nlw-comment tags back to html comments", () ->
      assertConverts("[nlw-comment]: <> (comment)", "<!-- comment -->")
      assertConverts("[nlw-comment]: <> (comment)\n[nlw-comment]: <> (comment2)",
        "<!-- comment -->\n<!-- comment2 -->")
    )

    it("doesn't mess with other markdown comment tags", () ->
      assertConverts("[comment]: <> (comment)", "[comment]: <> (comment)")
      assertConverts("[//]: <> (comment)", "[//]: <> (comment)")
      assertConverts("[//]: # (comment)",  "[//]: # (comment)")
    )

    # see comment on newlines above
    it("handles multiple markdown comments on the same line", () ->
      assertConverts("[nlw-comment]: <> (comment)[nlw-comment]: <> (comment2)",
        "<!-- comment --><!-- comment2 -->")
    )
  )
)
