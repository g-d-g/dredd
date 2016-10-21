var hooks = require('hooks');
var caseless = require('caseless');

hooks.after('Resource > Update Resource', function(transaction, done) {
  var headers = caseless(transaction.test.request.headers);
  var name = headers.has('Authorization');
  delete headers[name];
  transaction.test.request.headers = headers;
  done();
});
