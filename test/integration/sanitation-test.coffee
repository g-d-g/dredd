{assert} = require('chai')
express = require('express')
{EventEmitter} = require('events')

{runDredd} = require('./utils')
Dredd = require('../../src/dredd')


describe('Sanitation of Reported Data', ->
  # sample sensitive data (this value is used in API Blueprint fixtures as well)
  sensitiveKey = 'token'
  sensitiveHeaderName = 'authorization'
  sensitiveValue = '5229c6e8e4b0bd7dbb07e29c'

  # recording events sent to reporters
  events = undefined
  emitter = undefined
  expectedEventNames = ['start', 'fail', 'end']

  beforeEach( ->
    events = []
    emitter = new EventEmitter()
    emitter.on('start', (apiDescription, cb) -> events.push({name: 'start'}); cb() )
    emitter.on('test pass', (test) -> events.push({name: 'pass', test}))
    emitter.on('test skip', (test) -> events.push({name: 'skip', test}))
    emitter.on('test fail', (test) -> events.push({name: 'fail', test}))
    emitter.on('test error', (err, test) -> events.push({name: 'error', err, test}))
    emitter.on('end', (cb) -> events.push({name: 'end'}); cb() )
  )

  # helper for preparing Dredd instance with our custom emitter
  createDredd = (fixtureName) ->
    new Dredd({
      emitter
      options: {
        path: "./test/fixtures/sanitation/#{fixtureName}.apib"
        hookfiles: "./test/fixtures/sanitation/#{fixtureName}.js"
      }
    })

  # helper for preparing server
  createServer = (response) ->
    app = express()
    app.put('/resource', (req, res) -> res.json(response))
    return app


  describe('Sanitation of the Entire Request Body', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('entire-request-body')
      app = createServer({name: 123}) # 'name' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does not contain request body', ->
      assert.equal(events[1].test.request.body, '')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      test = JSON.stringify(events[1].test)
      assert.notInclude(test, sensitiveKey)
      assert.notInclude(test, sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveKey)
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  describe('Sanitation of the Entire Response Body', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('entire-response-body')
      app = createServer({token: 123}) # 'token' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does not contain response body', ->
      assert.equal(events[1].test.actual.body, '')
      assert.equal(events[1].test.expected.body, '')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      test = JSON.stringify(events[1].test)
      assert.notInclude(test, sensitiveKey)
      assert.notInclude(test, sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveKey)
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  describe('Sanitation of a Request Body Attribute', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('request-body-attribute')
      app = createServer({name: 123}) # 'name' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does not contain confidential body attribute', ->
      attrs = Object.keys(JSON.parse(events[1].test.request.body))
      assert.deepEqual(attrs, ['name'])
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      test = JSON.stringify(events[1].test)
      assert.notInclude(test, sensitiveKey)
      assert.notInclude(test, sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveKey)
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  describe('Sanitation of a Response Body Attribute', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('response-body-attribute')
      app = createServer({token: 123, name: 'Bob'}) # 'token' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does not contain confidential body attribute', ->
      attrs = Object.keys(JSON.parse(events[1].test.actual.body))
      assert.deepEqual(attrs, ['name'])

      attrs = Object.keys(JSON.parse(events[1].test.expected.body))
      assert.deepEqual(attrs, ['name'])
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      test = JSON.stringify(events[1].test)
      assert.notInclude(test, sensitiveKey)
      assert.notInclude(test, sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveKey)
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  describe('Sanitation of Plain Text Response Body by Pattern Matching', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('plain-text-response-body')
      app = createServer("#{sensitiveKey}=42#{sensitiveValue}") # should be without '42' → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does contain the sensitive data censored', ->
      assert.include(events[1].test.actual.body, '--- CENSORED ---')
      assert.include(events[1].test.expected.body, '--- CENSORED ---')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      assert.notInclude(JSON.stringify(events[1].test), sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  describe('Sanitation of Request Headers', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('request-headers')
      app = createServer({name: 123}) # 'name' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does not contain confidential header', ->
      names = (name.toLowerCase() for name of events[1].test.request.headers)
      assert.notInclude(names, sensitiveHeaderName)
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      test = JSON.stringify(events[1].test).toLowerCase()
      assert.notInclude(test, sensitiveHeaderName)
      assert.notInclude(test, sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      logging = results.logging.toLowerCase()
      assert.notInclude(logging, sensitiveHeaderName)
      assert.notInclude(logging, sensitiveValue)
    )
  )

  describe('Sanitation of Response Headers', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('response-headers')
      app = createServer({name: 'Bob'}) # Authorization header is missing → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does not contain confidential header', ->
      names = (name.toLowerCase() for name of events[1].test.actual.headers)
      assert.notInclude(names, sensitiveHeaderName)

      names = (name.toLowerCase() for name of events[1].test.expected.headers)
      assert.notInclude(names, sensitiveHeaderName)
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      test = JSON.stringify(events[1].test).toLowerCase()
      assert.notInclude(test, sensitiveHeaderName)
      assert.notInclude(test, sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      logging = results.logging.toLowerCase()
      assert.notInclude(logging, sensitiveHeaderName)
      assert.notInclude(logging, sensitiveValue)
    )
  )

  describe('Sanitation of URI Parameters by Pattern Matching', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('uri-parameters')
      app = createServer({name: 123}) # 'name' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does contain the sensitive data censored', ->
      assert.include(events[1].test.request.uri, 'CENSORED')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      assert.notInclude(JSON.stringify(events[1].test), sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  # This fails because it's not possible to do 'transaction.test = myOwnTestObject;'
  # at the moment, Dredd ignores the new object.
  describe('Sanitation of Any Content by Pattern Matching', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('any-content-pattern-matching')
      app = createServer({name: 123}) # 'name' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('emitted test data does contain the sensitive data censored', ->
      assert.include(JSON.stringify(events[1].test), 'CENSORED')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      assert.notInclude(JSON.stringify(events[1].test), sensitiveValue)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveValue)
    )
  )

  # This fails because Dredd incorrectly handles try/catch (search for
  # 'Beware! This is very problematic part of code.' in transaction runner).
  describe('Ultimate \'afterEach\' Guard Using Pattern Matching', ->
    results = undefined

    beforeEach((done) ->
      dredd = createDredd('any-content-guard-pattern-matching')
      app = createServer({name: 123}) # 'name' should be string → failing test

      runDredd(dredd, app, (args...) ->
        [err, results] = args
        done(err)
      )
    )

    it('results in one failed test', ->
      assert.equal(results.stats.failures, 1)
      assert.equal(results.stats.tests, 1)
    )
    it("emits expected events in expected order: #{expectedEventNames.join(', ')}", ->
      assert.deepEqual((event.name for event in events), expectedEventNames)
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      assert.notInclude(JSON.stringify(events[1].test), sensitiveValue)
    )
    it('Dredd prints message about failed assertion in hooks', ->
      assert.include(results.logging, 'Failed assertion in hooks')
    )
  )

  # some more gotchas:
  #
  # - if hook itself fails (e.g. on JSON.parse), logically, nothing gets sanitized -> test should ensure Dredd
  #   won't leak any data to reporters (stdout/stderr doesn't matter)
  # - test for case when sensitive data contains something which gets escaped in stringify
)
