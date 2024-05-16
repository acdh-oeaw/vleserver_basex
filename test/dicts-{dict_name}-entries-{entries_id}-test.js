'use strict';
const mocha = require('mocha');
const chakram = require('chakram');
const assert = require('chai').assert;
const request = chakram.request;
const expect = chakram.expect;
const fs = require('fs');
const Handlebars = require('handlebars');

require('./utilSetup');

const wrong_accept_basex_9 = "No function found that matches the request."
const wrong_accept_basex_9_7 = "Service not found."

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}/entries/{entries_id}', function() {
    var superuser = {
        "id": "",
        "userID": basexAdminUser,
        "pw": basexAdminPW,
        "read": "y",
        "write": "y",
        "writeown": "n",
        "table": "dict_users"
      },
        superuserauth = {"user":superuser.userID, "pass":superuser.pw},
        newSuperUserID,
        dictuser = { // a superuser for the test table
            "id": "",
            "userID": 'testUser0',
            "pw": 'PassW0rd',
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "enimmollitirure"
        },
        dictuser2 = {
            "id": "",
            "userID": 'testUser1',
            "pw": 'PassW0rd',
            "read": "y",
            "write": "y",
            "writeown": "y",
            "table": "enimmollitirure"
        },
        dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
        dictuserauth2 = {"user":dictuser2.userID, "pass":dictuser.pw},
        newDictUserID,
        newDictUserID2,
        compiledProfileTemplate,
        compiledEntryTemplate;
    
    before('Read templated test data', function() {
        var testProfileTemplate = fs.readFileSync('test/fixtures/testProfile.xml', 'utf8');
        expect(testProfileTemplate).to.contain("<tableName>{{dictName}}</tableName>");
        compiledProfileTemplate = Handlebars.compile(testProfileTemplate);
        testProfileTemplate = compiledProfileTemplate({'dictName': 'replaced'});
        expect(testProfileTemplate).to.contain("<tableName>replaced</tableName>");
        var testEntryTemplate = fs.readFileSync('test/fixtures/testEntry.xml', 'utf8');
        expect(testEntryTemplate).to.contain('"http://www.tei-c.org/ns/1.0"');        
        expect(testEntryTemplate).to.contain('xml:id="{{xmlID}}"');
        expect(testEntryTemplate).to.contain('>{{translation_en}}<');
        expect(testEntryTemplate).to.contain('>{{translation_de}}<');
        compiledEntryTemplate = Handlebars.compile(testEntryTemplate);
        testEntryTemplate = compiledEntryTemplate({
            'xmlID': 'testID',
            'translation_en': 'test',
            'translation_de': 'Test',
            });
        expect(testEntryTemplate).to.contain('xml:id="testID"');
        expect(testEntryTemplate).to.contain('>test<');
        expect(testEntryTemplate).to.contain('>Test<');
    });

    beforeEach('Set up dictionary and users', async function(){
        await request('post', baseURI + '/dicts', {
            'headers': {
                "Accept": "application/vnd.wde.v2+json",
                "Content-Type": "application/json"
            },
            'body': { 'name': 'dict_users' },
            'time': true
        });
        var userCreateResponse = await request('post', baseURI + '/dicts/dict_users/users', {
            'headers': {
                "Accept": "application/vnd.wde.v2+json",
                "Content-Type": "application/json"
            },
            'body': superuser,
            'time': true
        });
        newSuperUserID = userCreateResponse.body.id;
        var userCreateResponse = await request('post', baseURI + '/dicts/dict_users/users', {
            'headers': {
                "Accept": "application/vnd.wde.v2+json",
                "Content-Type": "application/json"
            },
            'auth': superuserauth,
            'body': dictuser,
            'time': true
        });
        newDictUserID = userCreateResponse.body.id;
        var userCreateResponse = await request('post', baseURI + '/dicts/dict_users/users', {
            'headers': {
                "Accept": "application/vnd.wde.v2+json",
                "Content-Type": "application/json"
            },
            'auth': superuserauth,
            'body': dictuser2,
            'time': true
        });
        newDictUserID2 = userCreateResponse.body.id;
        var newDictCreateResponse = await request('post', baseURI + '/dicts', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'body': { "name": dictuser.table },
            'time': true
        });
        expect(newDictCreateResponse.body.status).to.equal('201');
        
        var profileCreateResponse = await request('get', baseURI + '/dicts/'+dictuser.table+'/entries/dictProfile', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'qs': {'lock': 2},
            'auth': dictuserauth,                    
        })
        
        expect(profileCreateResponse).to.have.status(200);
        
        profileCreateResponse = await request('put', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
            'headers' : {"Accept":"application/vnd.wde.v2+json","Content-Type":"application/json"},
            'auth' : dictuserauth,
            'body': {
                "sid": "dictProfile",
                "lemma": "",
                "entry": compiledProfileTemplate({ 'dictName': dictuser.table })
            },
            'time' : true 
        });
        expect(profileCreateResponse).to.have.status(200);
        expect(profileCreateResponse.body.id).to.equal('dictProfile');
    });
    describe('tests for get', function() {
        var entryID = 'Utnisiveniam';
        beforeEach('Add a test entry', function(){
            return request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":entryID,
                        "lemma":"",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'test',
                            'translation_de': 'Test',
                            })
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
            })
        });
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(200);
            expect(response).to.have.json(function(body){
                expect(body.id).to.equal(entryID);
                expect(body.lemma).to.equal("[]");
            })
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', baseURI+'/dicts/'+dictuser.table+'/entries/' + entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', baseURI+'/dicts/'+dictuser.table+'/entries/' + entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth':{'user':'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        // try to get a dictionary entry that does not exist
        it('should respond 404 for "Not Found"', function() {
            var response = request('get', baseURI+'/dicts/'+dictuser.table+'/entries/autelaboresed', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });

        // try to get a dictionary entry in a format that is not supported
        it('should respond 404 "' + wrong_accept_basex_9_7 + '" for wrong accept', function() {
            var response = request('get', baseURI+'/dicts/'+dictuser.table+'/entries/' + entryID, { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json(
                (value) => assert(value === 'No function found that matches the request.' || 
                                  value === 'Service not found.', 'Unexpected status message: '+value)
                );
            return chakram.wait();
        });

        it('should respond 422 for "Unprocessable Entity"', async function() {
            await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth,
                'time': true
            })
            var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries/' + entryID, {
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth2,
                'time': true
            });

            expect(response).to.have.status(422);
            expect(response).to.have.json(function(body){
                expect(body.detail).to.contain("testUser0");
            });
            return chakram.wait();
        });

        afterEach('Remove test entry', function(){
            return request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth,
                'time': true
            })
            .then(function(){
            return request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            })
        });
        });
    });
    
    xdescribe('tests for patch', function() { // not implemented yet
        var entryID = 'testentry';
        beforeEach('Add a test entry', function(){
            return request('post', baseURI + '/dicts/' + dictuser.table + '/entries', { 
                    'body': {
                        "sid":entryID,
                        "lemma":"",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'test',
                            'translation_de': 'Test',
                            })
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
            })
        });
        // try to change an existing entry?
        xit('should respond 200 for "OK"', function() {
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/' + entryID, { 
                'body': {"sid" : "in","lemma" : "qui velit sunt","entry" : "irure quis pariatur"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });

        xit('should respond 400 for "Client Error"', function() {
            var response = request('patch', baseURI+'/dicts/'+dictuser.table+'/entries/laboristempormollitet', { 
                'body': {"sid":"laboris reprehenderit sed eiusmod amet","lemma":"consectetur velit","entry":"ad est"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });

        // try to change an entry without credentials
        xit('should respond 401 for "Unauthorized"', function() {
            var response = request('patch', baseURI + '/dicts/'+ dictuser.table + '/entries/' + entryID, { 
                'body': {"sid":"minim nulla reprehende","lemma":"in do","entry":"qui quis vo"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });

        // try to change an entry without sufficient credentials
        xit('should respond 403 for "Forbidden"', function() {
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/' + entryID, { 
                'body': {"sid":"non laboris culpa est","lemma":"sint commodo Lorem et","entry":"pari"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : "someuser", "pass" : "somepassword"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        // try to change an entry that does not exist
        it('should respond 404 for "Not Found"', function() {
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/irgendeineintrag', { 
                'body': {"sid":"ad enim fugiat","lemma":"sed","entry":"Lorem ad"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });

        // try to change an entry with an empty id
        it('should respond 404 for "Not Found"', function() {
            let entry = "";
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/' + entry, { 
                'body': {"sid":"ad enim fugiat","lemma":"sed","entry":"Lorem ad"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });

        // don't know what parameters should be not acceptable
        xit('should respond 406 for "Not Acceptable"', function() {
            var response = request('patch', baseURI+'/dicts//entries/velitnostrudipsumenimdo', { 
                'body': {"sid":"ea in","lemma":"ut ut est Ut","entry":"Ut mollit "},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });

        // try to access an entry with a wrong media type
        xit('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/' + entryID, { 
                'body' : {"sid":"in ea","lemma":"veniam sed Duis","entry":"irure eiusmod e"},
                'headers' : {"Accept":"application/vnd.wde.v8+json"},
                'auth' : dictuserauth,
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });

        xit('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/' + entryID, { 
                'body': {"sid":"cillum sed","lemma":"elit nostrud","entry":"proident eiusmod nostrud"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
        afterEach('Remove test entry', function(){
            return request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth,
                'time': true
            })
            .then(function(){
            return request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            })
        });
        });
    });
    
    describe('tests for put', function() {
        var entryID = 'innisiut';
        beforeEach('Add a test entry', async function(){
            let postNewEntry = { 
                'body': {
                    "sid":entryID,
                    "lemma":"",
                    "entry": compiledEntryTemplate({
                        'xmlID': entryID,
                        'translation_en': 'test',
                        'translation_de': 'Test',
                        })
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            }
            await request('post', baseURI+'/dicts/'+dictuser.table+'/entries', postNewEntry);
            await request('get', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, {
                    'qs': {'lock': 2},
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
            });
        });
        describe('should respond 200 for "OK"', function() {
            it('when changing an entry', function(){
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/'+ entryID, { 
                'body': {
                    "sid":entryID,
                    "lemma":"pariatur proident quis",
                    "entry": compiledEntryTemplate({
                        'xmlID': entryID,
                        'translation_en': 'changed',
                        'translation_de': 'verändert',
                        })
                    },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(200);
            expect(response).to.have.json(function(body){
                expect(body.id).to.equal(entryID);
                expect(body.lemma).to.equal("[]");
            })
            return chakram.wait();
            });
            it('when enabling caching', async function () {
                await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': { 'lock': 2 },
                    'auth': dictuserauth,
                    'time': true
                });
                var response = request('put', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', {
                    'body': {
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'useCache': true,
                        })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function (body) {
                    expect(body.id).to.equal('dictProfile');
                    expect(body.lemma).to.equal("  profile");
                });
                await chakram.wait()
            });

            it('when disabling caching', async function(){
                await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': { 'lock': 2 },
                    'auth': dictuserauth,
                    'time': true
                });
                var response = request('put', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', {
                    'body': {
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'useCache': true,
                        })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function (body) {
                    expect(body.id).to.equal('dictProfile');
                    expect(body.lemma).to.equal("  profile");
                });
                await chakram.wait()
            });

            it('when changing status', async function(){
                var response = await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': { 'lock': 5 },
                    'auth': dictuserauth,
                    'time': true
                });
                let putUnreleased = {
                    'body': {
                        "sid": "",
                        "lemma": "",
                        "entry": response.body.entry,
                        "status": 'unreleased'
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                }
                response = await request('put', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, putUnreleased);
                let putReleased = {
                    'body': {
                        "sid": "",
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'changed 2',
                            'translation_de': 'verändert 2',
                            }),
                        "status": 'released'
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                }
                var response = request('put', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, putReleased);

                expect(response).to.have.status(200);
                expect(response).to.have.json(function (body) {
                    expect(body.id).to.equal(entryID);
                    expect(body.lemma).to.equal("[]");
                    expect(body.status).to.equal("released")
                });
                await chakram.wait()
            });
            it('when leaving status alone', async function(){
                await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': { 'lock': 5 },
                    'auth': dictuserauth,
                    'time': true
                });
                await request('put', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'body': {
                        "sid": "",
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'changed',
                            'translation_de': 'verändert',
                            }),
                        "status": 'unreleased'
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });
                var response = request('put', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'body': {
                        "sid": "",
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'changed 2',
                            'translation_de': 'verändert 2',
                            })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function (body) {
                    expect(body.id).to.equal(entryID);
                    expect(body.lemma).to.equal("[]");
                    expect(body.status).to.equal("unreleased")
                });
                await chakram.wait()
            });
            it('when settinge status to ""', async function(){
                await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': { 'lock': 5 },
                    'auth': dictuserauth,
                    'time': true
                });
                await request('put', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'body': {
                        "sid": "",
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'changed',
                            'translation_de': 'verändert',
                            }),
                        "status": 'unreleased'
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });
                var response = request('put', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, {
                    'body': {
                        "sid": "",
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'changed 2',
                            'translation_de': 'verändert 2',
                            }),
                        "status": ''
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function (body) {
                    expect(body.id).to.equal(entryID);
                    expect(body.lemma).to.equal("[]");
                    expect(body.status).to.equal("")
                });
                await chakram.wait()
            });
        });


        // xit('should respond 400 for "Client Error"', function() {
        //     var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/exer', { 
        //         'body': {"sid":"non culpa sit cillum amet","lemma":"ipsum","entry":"sit consectetur deserunt incididunt"},
        //         'headers': {"Accept":"application/vnd.wde.v2+json"},
        //         'time': true
        //     });

        //     expect(response).to.have.status(400);
        //     return chakram.wait();
        // });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/esse', { 
                'body': {
                    "sid":"eu minim voluptate elit ut",
                    "lemma":"ea nulla",
                    "entry":"voluptate dolor"
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/utDuisLoremenimullamco', { 
                'body': {
                    "sid":"dolor ut Excepteur consectetur Ut",
                    "lemma":"officia nulla d",
                    "entry":"dolor dolore minim id ex"
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth':{'user':'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        // There is a 404 response when trying to lock the entry. If some entry can not be found is changed
        // then the lock is missing (and cannot be acquired)

        it('should respond 404 "' + wrong_accept_basex_9_7 + '" for wrong accept', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/deseruntenimeu', { 
                'body': {
                    "sid": "",
                    "lemma": "",
                    "entry": ""
                },
                'headers': { "Accept": "application/vnd.wde.v8+json" },
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json(
                (value) => assert(value === 'No function found that matches the request.' || 
                                  value === 'Service not found.', 'Unexpected status message: '+value)
                );
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/sintidauteexoccaecat', {
                'json': false, 
                'body': "sid non in occaecat lemma in incididunt entry laborum Ut nulla",
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        describe('should respond 422 for "Unprocessable Entity"', function() {
            it('when entry is no well formed XML', function(){
                var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, { 
                    'body': {
                        "sid":entryID,
                        "lemma":"labore sint",
                        "entry":"occaecat nisi aliqua"
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
                });
    
                expect(response).to.have.status(422);
                return chakram.wait();
            });
            it('when the lock is not held (anymore)', function(){
                return later(2000)
                    .then(function(){
                    var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, { 
                        'body': {
                            "sid": entryID,
                            "lemma":"cillum ea amet eiusmod",
                            "entry": compiledEntryTemplate({
                                'xmlID': entryID,
                                'translation_en': 'changed',
                                'translation_de': 'verändert',
                                })
                        },
                        'auth': dictuserauth,
                        'headers': {"Accept":"application/vnd.wde.v2+json"},
                        'time': true
                    });

                    expect(response).to.have.status(422);
                    return chakram.wait();
                });
            });
        });

        afterEach('Remove test entry', async function(){
            await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth,
                'time': true
            });
            await request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });
        });   
    });
    
    describe('tests for delete', function() {
        var entryID = 'insitofficiadeserunt';
        beforeEach('Add a test entry', function(){
            return request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":entryID,
                        "lemma":"",
                        "entry": compiledEntryTemplate({
                            'xmlID': entryID,
                            'translation_en': 'test',
                            'translation_de': 'Test',
                            })
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
            })
            .then(function(testEntryCreated){
                return request('get', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, {
                    'qs': {'lock': 2},
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
                });
            });
        });
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(204);
            expect(response).to.have.json(function(body){
                expect(body).to.be.undefined;
            })
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth':{'user':'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        // 404 is not possible because you would need a lock for a non existing entry.
        // Trying to get this lock will return 404

        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/incididuntExcepteursedullamco', { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });
        
        it('should respond 422 for "Unprocessable Entity"', function(){
            return later(2000)
                .then(function(){
                var response = request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/'+entryID, {
                    'auth': dictuserauth,
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'time': true
                });

                expect(response).to.have.status(422);
                return chakram.wait();
            });
        });        
        afterEach('Remove test entry', function(){
            return request('get', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth,
                'time': true
            })
            .then(function(){
            return request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/'+ entryID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });
            });
        });
    
    });   
    afterEach('Tear down dictionary and usesrs', async function(){
        await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'qs': { 'lock': 2 },
            'auth': dictuserauth,
            'time': true
        });
        await request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': dictuserauth,
            'time': true
        });
        await request('delete', baseURI + '/dicts/' + dictuser.table, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': dictuserauth,
            'time': true
        });
        await request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
        await request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID2, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
        await request('delete', baseURI + '/dicts/dict_users', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
    });
});
};