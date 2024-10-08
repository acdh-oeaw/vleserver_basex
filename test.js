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
    describe('Dictionary management', require('./test/dicts-{dict_name}-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('User management - first part', require('./test/dicts-{dict_name}-users-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('User management - second part',require('./test/dicts-{dict_name}-users-{users_id}-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data creation', require('./test/dicts-{dict_name}-entries-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data creation with xsd', require('./test/dicts-{dict_name}-entries-test-with-xsd').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data creation with schematron', require('./test/dicts-{dict_name}-entries-test-with-schematron').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data creation with additional schematron schema', require('./test/dicts-{dict_name}-entries-test-with-additional-schema').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary data usage', require('./test/dicts-{dict_name}-entries-{entries_id}-test').curry(baseURI, basexAdminUser, basexAdminPW));
    describe('Dictionary file listing and upload', require('./test/dicts-{dict_name}-files-test').curry(baseURI, basexAdminUser, basexAdminPW));
    xdescribe('Dictionary file download and locking', require('./test/dicts-{dict_name}-files-{file_name}-test').curry(baseURI, basexAdminUser, basexAdminPW));
});