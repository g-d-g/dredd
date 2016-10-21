{assert} = require('chai')
express = require('express')
{EventEmitter} = require('events')

{runDredd} = require('./utils')
Dredd = require('../../src/dredd')


describe('Sanitation of Reported Data', ->
  # recording events sent to reporters
  events = undefined
  emitter = undefined

  beforeEach( ->
    events = []
    emitter = new EventEmitter()
    emitter.on('test pass', (test) -> events.push({name: 'pass', test}))
    emitter.on('test skip', (test) -> events.push({name: 'skip', test}))
    emitter.on('test fail', (test) -> events.push({name: 'fail', test}))
    emitter.on('test error', (err, test) -> events.push({name: 'error', err, test}))
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
    sensitiveData = '5229c6e8e4b0bd7dbb07e29c'
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
    it('emits one failed test', ->
      assert.equal(events.length, 1)
      assert.equal(events[0].name, 'fail')
    )
    it('emitted test data does not contain request body', ->
      assert.equal(events[0].test.request.body, '')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      assert.notInclude(JSON.stringify(events[0].test), sensitiveData)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveData)
    )
  )

  describe('Sanitation of the Entire Response Body', ->
    sensitiveData = '5229c6e8e4b0bd7dbb07e29c'
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
    it('emits one failed test', ->
      assert.equal(events.length, 1)
      assert.equal(events[0].name, 'fail')
    )
    it('emitted test data does not contain response body', ->
      assert.equal(events[0].test.actual.body, '')
      assert.equal(events[0].test.expected.body, '')
    )
    it('sensitive data cannot be found anywhere in the emitted test data', ->
      assert.notInclude(JSON.stringify(events[0].test), sensitiveData)
    )
    it('sensitive data cannot be found anywhere in Dredd output', ->
      assert.notInclude(results.logging, sensitiveData)
    )
  )

  # describe('Sanitation of a Request Body Attribute', -> )
  # describe('Sanitation of a Response Body Attribute', -> )
  # describe('Sanitation of Plain Text Response Body by Pattern Matching', -> )
  # describe('Sanitation of Request Headers', -> )
  # describe('Sanitation of Response Headers', -> )
  # describe('Sanitation of URI Parameters', -> )
  # describe('Sanitation of Any Content by Pattern Matching', -> )
  # describe('Ultimate \'afterEach\' Guard Using Pattern Matching', -> )
)
