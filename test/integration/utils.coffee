url = require('url')
express = require('express')

logger = require('../../src/logger')


DEFAULT_SERVER_PORT = 9876


runDredd = (dredd, app, port, cb) ->
  [cb, port] = [port, DEFAULT_SERVER_PORT] if arguments.length is 3
  [cb, port, app] = [app, DEFAULT_SERVER_PORT, express()] if arguments.length is 2

  dredd.configuration.server ?= "http://localhost:#{port}"

  silent = !!logger.transports.console.silent
  logger.transports.console.silent = true # supress Dredd's console output (remove if debugging)

  err = undefined
  stats = undefined
  logging = ''

  recordLogging = (transport, level, message, meta) ->
    logging += "#{level}: #{message}\n"

  server = app.listen(port, (err) ->
    return cb(err) if err

    logger.on('logging', recordLogging)
    dredd.run((args...) ->
      logger.removeListener('logging', recordLogging)
      logger.transports.console.silent = silent

      [err, stats] = args
      server.close()
    )
  )
  server.once('close', ->
    cb(null, {err, stats, logging})
  )


module.exports = {
  DEFAULT_SERVER_PORT
  runDredd
}
