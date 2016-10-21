var hooks = require('hooks');
var url = require('url');
var qs = require('querystring');

hooks.after('Resource > Update Resource', function(transaction, done) {
  var urlParts = url.parse(transaction.test.request.uri);
  var parameters = qs.parse(urlParts.query);
  delete parameters.token;
  urlParts.query = parameters;
  transaction.test.request.uri = url.format(urlParts);
  done();
});
