'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;
var fs = require('fs');
var Handlebars = require('handlebars');

require('./utilSetup');

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
        dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
        newDictUserID,
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

    beforeEach('Set up dictionary and users', function(){
        // I think here is a contradiction: It should not be possible to create any table without credentials. <-> The dict_users table manages credentials. The dict_users table has to be present before any access is possible and at least the superuser must be in the table.
        return request('post', baseURI + '/dicts', {
        'headers': {"Accept":"application/vnd.wde.v2+json",
                    "Content-Type":"application/json"},
        'body': {'name': 'dict_users'},
        'time': true
        })
        .then(function(dictUsersCreated){
        return request('post', baseURI + '/dicts/dict_users/users', { 
            'headers': {"Accept":"application/vnd.wde.v2+json",
                        "Content-Type":"application/json"},
            'body': superuser,
            'time': true
        })
        .then(function(userCreateResponse) {
            newSuperUserID = userCreateResponse.body.id;
            return request('post', baseURI + '/dicts/dict_users/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'auth': superuserauth,
                'body': dictuser,
                'time': true
                })
                .then(function(userCreateResponse) {
                    newDictUserID = userCreateResponse.body.id;               
                    return request('post', baseURI + '/dicts', {
                        'headers': {"Accept":"application/vnd.wde.v2+json"},
                        'auth': superuserauth,
                        'body': {"name": dictuser.table},
                        'time': true
                    })
                    .then(function(dictCreatedResponse){
                        return request('post', baseURI + '/dicts/' + dictuser.table + '/entries', { 
                            'body': {
                                "sid":"dictProfile",
                                "lemma":"",
                                "entry": compiledProfileTemplate({'dictName' : dictuser.table})
                            },
                            'headers': {"Accept":"application/vnd.wde.v2+json"},
                            'auth': dictuserauth,
                            'time': true
                            });                    
                    });            
            });            
        });
        });
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
        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('get', baseURI+'/dicts/'+dictuser.table+'/entries/' + entryID, { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json('No function found that matches the request.')
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
    
    describe('tests for patch', function() {
        // added T.K. start - create an entry which could be changed with patch
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
        // added T.K. end
        // try to change an existing entry - test fails: returned status code is 404 (?)
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

        // don't know which case should give this error
        xit('should respond 400 for "Client Error"', function() {
            var response = request('patch', baseURI+'/dicts/'+dictuser.table+'/entries/laboristempormollitet', { 
                'body': {"sid":"laboris reprehenderit sed eiusmod amet","lemma":"consectetur velit","entry":"ad est"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });

        // try to change an entry without credentials - test fails: returns status code 404 (?)
        xit('should respond 401 for "Unauthorized"', function() {
            var response = request('patch', baseURI + '/dicts/'+ dictuser.table + '/entries/' + entryID, { 
                'body': {"sid":"minim nulla reprehende","lemma":"in do","entry":"qui quis vo"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });

        // try to change an entry without sufficient credentials - is this appropriatelly understood? Either one user is authorized or not unauthorized for a particular database. What should forbidden mean?
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

        // try to access an entry with a wrong media type - test fails: returned status code is 404
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

        // this test seems to be for a write lock on the server - needs more setup
        xit('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('patch', baseURI + '/dicts/' + dictuser.table + '/entries/' + entryID, { 
                'body': {"sid":"cillum sed","lemma":"elit nostrud","entry":"proident eiusmod nostrud"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
        // added T.K. start - delete test entry
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
        // added T.K. end
    });
    
    describe('tests for put', function() {
        var entryID = 'innisiut';
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
        it('should respond 200 for "OK"', function() {
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
                expect(body.id).to.equal(entryID)
            })
            return chakram.wait();
        });


        xit('should respond 400 for "Client Error"', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/exer', { 
                'body': {"sid":"non culpa sit cillum amet","lemma":"ipsum","entry":"sit consectetur deserunt incididunt"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


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


        xit('should respond 404 for "Not Found"', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/laborumlaboreExcepteurad', { 
                'body': {"sid":"nulla ullamco laboris anim","lemma":"dolor","entry":"occaecat magna"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('put', baseURI+'/dicts/'+dictuser.table+'/entries/deseruntenimeu', { 
                'body': {
                    "sid":"voluptate est",
                    "lemma":"labore sint",
                    "entry":"occaecat nisi aliqua"
                },
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json('No function found that matches the request.')
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
    afterEach('Tear down dictionary and usesrs', function(){
        return request('get', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', { 
            'headers': {"Accept":"application/vnd.wde.v2+json"},
            'qs': {'lock': 2},
            'auth': dictuserauth,
            'time': true
        })
        .then(function(){       
        return request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/dictProfile', { 
            'headers': {"Accept":"application/vnd.wde.v2+json"},
            'auth': dictuserauth,
            'time': true
        })
        .then(function(){       
            return request('delete', baseURI + '/dicts/' + dictuser.table, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            })
            .then(function(){
                return request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': superuserauth,
                    'time': true
                })
                .then(function(){
                    return request('delete', baseURI + '/dicts/dict_users', { 
                        'headers': {"Accept":"application/vnd.wde.v2+json"},
                        'auth': superuserauth,
                    'time': true
                    });
                });
            });
        });
    });
    });
});
};