const _ = '_'
  , baseURI = 'http://localhost:8984/restvle'
  , basexAdminUser = 'admin'
  , basexAdminPW = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";
  // , baseURI = 'https://basex-curation.eos.arz.oeaw.ac.at'
  // , basexAdminUser = 'BaseXTestAdmin'
  // , basexAdminPW = 'Stoßwellentherapie';

require('./test/utilSetup')

describe('WDE REST API', function() {
    this.timeout(20000);
    describe('Dictionary listing and creation', require('./test/dicts-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary management', require('./test/dicts-{dicts_name}-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('User management - first part', require('./test/dicts-{dict_name}-users-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('User management - second part',require('./test/dicts-{dict_name}-users-{users_id}-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data creation', require('./test/dicts-{dict_name}-entries-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data usage', require('./test/dicts-{dict_name}-entries-{entries_id}-test').curry(baseURI, basexAdminUser, basexAdminPW));
})