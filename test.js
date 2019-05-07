const _ = '_'
  , baseURI = 'http://localhost:8984/restvle'
  , basexAdminUser = 'admin'
  , basexAdminPW = 'admin';
  // , baseURI = 'https://basex-curation.eos.arz.oeaw.ac.at'
  // , basexAdminUser = 'BaseXTestAdmin'
  // , basexAdminPW = 'Stoßwellentherapie';

require('./test/utilSetup')

describe('WDE REST API', function() {
    this.timeout(20000);
    describe('Diictionary listing', require('./test/dicts-test').curry(baseURI, basexAdminUser, basexAdminPW))
    describe('User Management', require('./test/dicts-{dict_name}-users-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary Data Usage', require('./test/dicts-{dict_name}-entries-test').curry(baseURI, basexAdminUser, basexAdminPW));
})