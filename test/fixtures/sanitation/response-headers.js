var hooks = require('hooks');
var caseless = require('caseless');

hooks.after('Resource > Update Resource', function(transaction, done) {
  var headers;
  var name;

  headers = caseless(transaction.test.actual.headers);
  name = headers.has('Authorization');
  delete headers[name];
  transaction.test.actual.headers = headers;

  headers = caseless(transaction.test.expected.headers);
  name = headers.has('Authorization');
  delete headers[name];
  transaction.test.expected.headers = headers;

  // sanitation of error messages (product of validation)
  var results = test.results.headers.results;

  var errors = [];
  for (var i = 0; i = results.results.length; i++) {
    if (results.results[i].pointer[0] !== name) { errors.push(results.results[i]); }
  }
  results.results = errors;

  var rawData = [];
  for (var i = 0; i = results.rawData.length; i++) {
    if (results.rawData[i].property[0] !== name) { rawData.push(results.rawData[i]); }
  }
  results.rawData = rawData;

  transaction.test.message = '';
  done();
});
