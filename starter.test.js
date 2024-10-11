import { describe, test } from 'vitest';
import { functionAddCurry } from './test/utilSetup';
import dictsTest from './test/dicts-test';
import dictsDictNameTest from './test/dicts-{dict_name}-test';
import dictsDictNameUsersTest from './test/dicts-{dict_name}-users-test';
import dictsDictNameUsersUsersIdTest from './test/dicts-{dict_name}-users-{users_id}-test';
import dictsDictNameEntriesTest from './test/dicts-{dict_name}-entries-test';
/* import dictsDictNameEntriesTestWithXsd from './test/dicts-{dict_name}-entries-test-with-xsd';
import dictsDictNameEntriesTestWithSchematron from './test/dicts-{dict_name}-entries-test-with-schematron';
import dictsDictNameEntriesTestWithAdditionalSchema from './test/dicts-{dict_name}-entries-test-with-additional-schema';
import dictsDictNameEntriesEntriesIdTest from './test/dicts-{dict_name}-entries-{entries_id}-test';
import dictsDictNameFilesTest from './test/dicts-{dict_name}-files-test';
import dictsDictNameFilesFileNameTest from './test/dicts-{dict_name}-files-{file_name}-test'; */

const _ = '_'
  , baseURI = 'http://localhost:8984/restvle'
  , basexAdminUser = 'admin'
  , basexAdminPW = "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918";
  // , baseURI = 'https://basex-curation.eos.arz.oeaw.ac.at'
  // , basexAdminUser = 'BaseXTestAdmin'
  // , basexAdminPW = 'Stoßwellentherapie';

functionAddCurry();

describe('WDE REST API', () => {
  describe('Dictionary listing and creation', dictsTest.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('Dictionary management', dictsDictNameTest.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('User management - first part', dictsDictNameUsersTest.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('User management - second part', dictsDictNameUsersUsersIdTest.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('Dictionary data creation', dictsDictNameEntriesTest.curry(baseURI, basexAdminUser, basexAdminPW));
/*  describe('Dictionary data creation with xsd', dictsDictNameEntriesTestWithXsd.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('Dictionary data creation with schematron', dictsDictNameEntriesTestWithSchematron.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('Dictionary data creation with additional schematron schema', dictsDictNameEntriesTestWithAdditionalSchema.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('Dictionary data usage', dictsDictNameEntriesEntriesIdTest.curry(baseURI, basexAdminUser, basexAdminPW));
  describe('Dictionary file listing and upload', dictsDictNameFilesTest.curry(baseURI, basexAdminUser, basexAdminPW));
  describe.skip('Dictionary file download and locking', dictsDictNameFilesFileNameTest.curry(baseURI, basexAdminUser, basexAdminPW)); */
});