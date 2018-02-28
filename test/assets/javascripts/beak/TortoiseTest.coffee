assert   = require("assert")
Tortoise = require("./tortoise").Tortoise

describe('Tortoise', () ->
  describe('#toNetLogoWebMarkdown()', () ->
    assertConverts = (source, target) ->
      assert.equal(Tortoise.toNetLogoWebMarkdown(source), target)

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

  describe('#toNetLogoMarkdown()', () ->
    assertConverts = (source, target) ->
      assert.equal(Tortoise.toNetLogoMarkdown(source), target)

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
