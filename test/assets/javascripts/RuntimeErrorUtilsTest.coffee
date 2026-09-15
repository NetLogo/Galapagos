import assert from 'assert'
import { isModelCodeError } from '../main/runtime-error-utils.js'

describe('RuntimeErrorUtils', () ->
  describe('#isModelCodeError()', () ->

    it("is false for a failure in a widget's own code", () ->
      assert.equal(isModelCodeError({ stackTrace: [] }), false)
    )

    it("is false for a `run` string in a widget's own code", () ->
      assert.equal(isModelCodeError({ stackTrace: [{ type: 'run' }] }), false)
      assert.equal(isModelCodeError({ stackTrace: [{ type: 'runresult' }] }), false)
    )

    it("is true for a failure inside a procedure", () ->
      assert.equal(isModelCodeError({ stackTrace: [{ type: 'command', name: 'go' }] }), true)
      assert.equal(isModelCodeError({ stackTrace: [{ type: 'reporter', name: 'score' }] }), true)
    )

    it("is true for a `run` string inside a procedure", () ->
      assert.equal(isModelCodeError({ stackTrace: [{ type: 'run' }, { type: 'command', name: 'go' }] }), true)
    )

    it("is false for plot code that calls no procedure", () ->
      assert.equal(isModelCodeError({ stackTrace: [{ type: 'plot', name: 'counts' }] }), false)
    )

    it("is false when there is no stack trace at all", () ->
      assert.equal(isModelCodeError({}), false)
    )

  )
)
