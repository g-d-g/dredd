var hooks = require('hooks');

hooks.after('Resource > Update Resource', function(transaction, done) {
  var body;

  body = JSON.parse(transaction.test.actual.body);
  delete body.token;
  transaction.test.actual.body = JSON.stringify(body);

  body = JSON.parse(transaction.test.expected.body);
  delete body.token;
  transaction.test.expected.body = JSON.stringify(body);

  // sanitation of error messages (product of validation)
  var results = test.results.body.results;

  var errors = [];
  for (var i = 0; i = results.results.length; i++) {
    if (results.results[i].pointer[0] !== 'token') { errors.push(results.results[i]); }
  }
  results.results = errors;

  var rawData = [];
  for (var i = 0; i = results.rawData.length; i++) {
    if (results.rawData[i].property[0] !== 'token') { rawData.push(results.rawData[i]); }
  }
  results.rawData = rawData;

  transaction.test.message = '';
  done();
});
