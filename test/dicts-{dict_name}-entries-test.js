import { describe, it, beforeAll, afterAll, beforeEach, afterEach, expect } from 'vitest';
import fetch from 'node-fetch-native';
import fs from 'fs';
import Handlebars from 'handlebars';

import './utilSetup';

export default function(baseURI, basexAdminUser, basexAdminPW) {
    describe('tests for /dicts/{dict_name}/entries', function() {
        var superuser = {
            "id": "",
            "userID": basexAdminUser,
            "pw": basexAdminPW,
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "dict_users"
        },
        superuserauth = {"username": superuser.userID, "password": superuser.pw},
        newSuperUserID,
        dictuser = { // a superuser for the test table
            "id": "",
            "userID": 'testUser0',
            "pw": 'PassW0rd',
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "nostrudsedeaincididunt"
        },
        dictuserauth = {"username": dictuser.userID, "password": dictuser.pw},
        newDictUserID,
        compiledProfileTemplate,
        compiledEntryTemplate,
        compiledProfileWithSchemaTemplate,
        testEntryForValidation,
        testEntryForValidationWithError;

        beforeAll(function() {
            var testProfileTemplate = fs.readFileSync('test/fixtures/testProfile.xml', 'utf8');
            expect(testProfileTemplate).toContain("<tableName>{{dictName}}</tableName>");
            expect(testProfileTemplate).toContain("<displayString>{{displayString}}</displayString>");
            compiledProfileTemplate = Handlebars.compile(testProfileTemplate);
            testProfileTemplate = compiledProfileTemplate({
                'dictName': 'replaced',
                'mainLangLabel': 'aNCName',        
                'displayString': '{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}',
                'altDisplayString': {
                    'label': 'test',
                    'displayString': '//mds:titleInfo/mds:title'
                },
                'useCache': true
            });
            expect(testProfileTemplate).toContain("<tableName>replaced</tableName>");
            expect(testProfileTemplate).toContain('displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<');
            expect(testProfileTemplate).toContain('altDisplayString label="test">//mds:titleInfo/mds:title<');
            expect(testProfileTemplate).toContain('mainLangLabel>aNCName<');
            expect(testProfileTemplate).toContain('useCache/>');
            var testEntryTemplate = fs.readFileSync('test/fixtures/testEntry.xml', 'utf8');
            expect(testEntryTemplate).toContain('"http://www.tei-c.org/ns/1.0"');        
            expect(testEntryTemplate).toContain('xml:id="{{xmlID}}"');
            expect(testEntryTemplate).toContain('>{{translation_en}}<');
            expect(testEntryTemplate).toContain('>{{translation_de}}<');
            compiledEntryTemplate = Handlebars.compile(testEntryTemplate);
            testEntryTemplate = compiledEntryTemplate({
                'xmlID': 'testID',
                'formFaArab': 'تست',
                'formFaXModDMG': 'ṭēsṯ',
                'translation_en': 'test',
                'translation_de': 'Test',
            });
            expect(testEntryTemplate).toContain('xml:id="testID"');
            expect(testEntryTemplate).toContain('>test<');
            expect(testEntryTemplate).toContain('>Test<');
            expect(testEntryTemplate).toContain('>تست<');
            expect(testEntryTemplate).toContain('>ṭēsṯ<');
            // data for testing server side validation
            var testProfileWithSchemaTemplate = fs.readFileSync('test/fixtures/testProfileWithSchema.xml','utf8');
            expect(testProfileWithSchemaTemplate).toContain("<tableName>{{dictname}}</tableName>");
            compiledProfileWithSchemaTemplate = Handlebars.compile(testProfileWithSchemaTemplate);
            testEntryForValidation = fs.readFileSync('test/fixtures/testEntryForValidation.xml','utf8');
            expect(testEntryForValidation).toContain('xml:id="biyyah_001"');
            testEntryForValidationWithError = fs.readFileSync('test/fixtures/testEntryForValidationWithError.xml','utf8');
            expect(testEntryForValidationWithError).toContain('<hom id="error-entry-1" xml:lang="de">');
        });

        beforeEach(async function(){
            let response = await fetch(baseURI + '/dicts', {
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({'name': 'dict_users'})
            });
            expect(response.status).toBe(201);
            let userCreateResponse = await fetch(baseURI + '/dicts/dict_users/users', { 
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(superuser)
            });
            expect(userCreateResponse.status).toBe(200);
            newSuperUserID = (await userCreateResponse.json()).id;
            userCreateResponse = await fetch(baseURI + '/dicts/dict_users/users', { 
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json",
                    "Authorization": "Basic " + btoa(superuserauth.username + ":" + superuserauth.password)
                },
                body: JSON.stringify(dictuser),
                auth: superuserauth
            });
            expect(userCreateResponse.status).toBe(200);
            newDictUserID = (await userCreateResponse.json()).id;               
            response = await fetch(baseURI + '/dicts', {
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json",
                    "Authorization": "Basic " + btoa(superuserauth.username + ":" + superuserauth.password)
                },
                body: JSON.stringify({"name": dictuser.table}),
            });
            expect(response.status).toBe(201);
        });

        describe('tests for post', function() {        
            it('should respond 201 for "Created" for a profile', async function() {
                var config = { 
                    body: JSON.stringify({
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'displayString': '//tei:form/tei:orth[1]', 
                        })
                    }),
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": "Basic " + btoa(dictuserauth.username+ ":" + dictuserauth.password)
                    },
                };
                const response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', {
                    method: 'POST',
                    ...config
                });

                expect(response.status).toBe(201);
                const body = await response.json();
                expect(body).toBeDefined();
            });

            // test if the adding of entries is possible also the validation is present now
            it('should respond 201 for "Created" for an entry', async function(){
                var config = { 
                    body: JSON.stringify({
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'displayString': '//tei:form/tei:orth[1]', 
                        })
                    }),
                    headers: { 
                      "Accept": "application/vnd.wde.v2+json",
                      "Content-Type": "application/json",
                      "Authorization": "Basic " + btoa(dictuserauth.username + ":" + dictuserauth.password)
                    }
                };
                let response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', {
                    method: 'POST',
                    ...config
                });

                expect(response.status).toBe(201);

                config = {
                    body: JSON.stringify({
                        "sid": 'biyyah_001',
                        "lemma": "",
                        "entry": testEntryForValidation
                    }),
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": "Basic " + btoa(dictuserauth.username + ":" + dictuserauth.password)
                    }
                };
                response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', {
                    method: 'POST',
                    ...config
                });

                expect(response.status).toBe(201);
                const body = await response.json();
                expect(body).toBeDefined();
            });

            it('should respond 201 for "Created" for an entry with owner and status set', async function(){
                var config = { 
                    body: JSON.stringify({
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'displayString': '//tei:form/tei:orth[1]', 
                        })
                    }),
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": "Basic " + btoa(dictuserauth.username + ":" + dictuserauth.password)
                    }
                };
                let response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', {
                    method: 'POST',
                    ...config
                });

                expect(response.status).toBe(201);

                config = {
                    body: JSON.stringify({
                        "sid": 'biyyah_001',
                        "lemma": "",
                        "entry": testEntryForValidation,
                        "owner": dictuser.userID,
                        "status": "unreleased"
                    }),
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": "Basic " + btoa(dictuserauth.username + ":" + dictuserauth.password)
                    }
                };
                response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', {
                    method: 'POST',
                    ...config
                });

                expect(response.status).toBe(201);
                const body = await response.json();
                expect(body).toBeDefined();
            });

            it('should respond 401 for "Unauthorized"', async function() {
                const response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', { 
                    method: 'POST',
                    body: JSON.stringify({
                        "sid":"mollit nostrud adipisicing",
                        "lemma":"sunt sint",
                        "entry":"adipisicing sunt amet laborum"
                    }),
                    headers: { "Accept": "application/vnd.wde.v2+json" }
                });

                expect(response.status).toBe(401);
            });

            it('should respond 403 for "Forbidden"', async function() {
                const response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', { 
                    method: 'POST',
                    body: JSON.stringify({
                        "sid":"magna in",
                        "lemma":"Duis",
                        "entry":"officia proident anim dolor"
                    }),
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": "Basic " + btoa("nonexisting:nonsense")
                    }
                });

                expect(response.status).toBe(403);
            });

            it('should respond 404 "No function found that matches the request." for wrong accept', async function() {
                const response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', { 
                    method: 'POST',
                    body: JSON.stringify({
                        "sid":"irure",
                        "lemma":"ut aliquip",
                        "entry":"id eiusmod est eu"
                    }),
                    headers: { "Accept": "application/vnd.wde.v8+json" },
                    auth: dictuserauth
                });

                expect(response.status).toBe(404);
            });

            it('should respond 415 for "Unsupported Media Type"', async function() {
                // Add the implementation for this test case
            });

            describe('should respond 422 for "Unprocessable Entity"', function() {
                // Add the implementation for this test case
            });

            afterEach(async () => {
                // Add the implementation for this test case
            });
        });

        describe('tests for get', function() {
            describe('should respond 200 for "OK"', response200tests.curry(false));        
            describe('should respond 200 for "OK" (using cache)', response200tests.curry(true));
            function response200tests (useCache) {
                // Add the implementation for this test case
            }

            it('should respond 400 for useless "filter"', function() {
                // Add the implementation for this test case
            });

            it('should respond 401 for "Unauthorized"', function() {
                // Add the implementation for this test case
            });

            describe('should respond 403 for "Forbidden"', function() {
                // Add the implementation for this test case
            });

            it('should respond 404 "No function found that matches the request." for wrong accept', function() {
                // Add the implementation for this test case
            });
        });

        async function create_test_data(useCache) {
            // Add the implementation for this test case
        }

        async function remove_test_data() {
            // Add the implementation for this test case
        }

        describe('tests for patch', function() {
            var changedEntries = [],
                changedIds = "test03,test08";
            beforeAll(function() {
                // Add the implementation for this test case
            });        
            describe('should respond 200 for "OK"', response200tests.curry(false));
            describe('should respond 200 for "OK" (using cache)', response200tests.curry(true));
            function response200tests(useCache) {
                // Add the implementation for this test case
            }

            it('should respond 401 for "Unauthorized"', function() {
                // Add the implementation for this test case
            });

            it('should respond 403 for "Forbidden"', function() {
                // Add the implementation for this test case
            });

            it('should respond 404 "No function found that matches the request." for wrong accept', function() {
                // Add the implementation for this test case
            });

            describe('should respond 409 for "Conflict"', function () {
                // Add the implementation for this test case
            });

            it('should respond 415 for "Unsupported Media Type"', function() {
                // Add the implementation for this test case
            });

            describe('should respond 422 for "Unprocessable Entity"', function() {
                // Add the implementation for this test case
            });
        });

        afterEach(async function(){
            let response = await fetch(baseURI + '/dicts/' + dictuser.table, {
                method: 'DELETE',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Authorization": "Basic " + btoa(dictuserauth.username + ":" + dictuserauth.password)
                }
            });

            expect(response.status).toBe(204);

            response = await fetch(baseURI + '/dicts/dict_users/users/' + newDictUserID, {
                method: 'DELETE',
                headers: {
                  "Accept": "application/vnd.wde.v2+json",
                  "Authorization": "Basic " + btoa(superuserauth.username + ":" + superuserauth.password)
                }
            });

            expect(response.status).toBe(204);
            
            response = await fetch(baseURI + '/dicts/dict_users', {
                method: 'DELETE',
                headers: 
                {
                  "Accept": "application/vnd.wde.v2+json",
                  "Authorization": "Basic " + btoa(superuserauth.username + ":" + superuserauth.password)
                }
            });

            expect(response.status).toBe(204);           
        });
    });
}