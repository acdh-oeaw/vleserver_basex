'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;
var fs = require('fs');
var Handlebars = require('handlebars');

require('./utilSetup');

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}/entries - with additional schema', function() {
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
            "table": "nostrudsedeaincididunt"
        },
        dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
        newDictUserID,
        compiledProfileWithSchemaTemplate,
        compiledProfileWithAdditionalSchemaTemplate,
        testEntryForValidation,
        testEntryForValidationWithErrorRecognizedBySchematron;
    
    before('Read templated test data', function() {
        // data for testing server side validation
        var testProfileWithAdditionalSchemaTemplate = fs.readFileSync('test/fixtures/testProfileWithAdditionalSchema.xml','utf8');
        expect(testProfileWithAdditionalSchemaTemplate).to.contain('<sch:assert test="@type" role="error">');
        compiledProfileWithAdditionalSchemaTemplate = Handlebars.compile(testProfileWithAdditionalSchemaTemplate);
        testEntryForValidation = fs.readFileSync('test/fixtures/testEntryForValidation.xml','utf8');
        expect(testEntryForValidation).to.contain('xml:id="biyyah_001"');
        // the following entry should fail only when validating with the additional schematron schema
        testEntryForValidationWithErrorRecognizedBySchematron = fs.readFileSync('test/fixtures/testEntryForValidationWithErrorForAdditionalSchematron.xml','utf8');
        expect(testEntryForValidationWithErrorRecognizedBySchematron).to.contain('<entry xmlns="http://www.tei-c.org/ns/1.0" xml:id="biyyah_001" type="irgendwas">');
    });

// tests for additional validation - start
    beforeEach(function(){
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
            })
            .then(function(){
                return request('post', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers' : {"Accept":"application/vnd.wde.v2+json","Content-Type":"application/json"},
                    'auth' : dictuserauth,
                    'body' : { "sid" : "dictProfile",
                               "lemma" : "profile",
                               "entry" : compiledProfileWithAdditionalSchemaTemplate({ 'dictname' : dictuser.table }) },
                    'time' : true 
                })
            });
        });
        });
    });
    
    describe('tests for post - with additional validation', function() {
        // test if the adding of entries is possible although the validation is present now
        it('should respond 201 for "Created"', function(){
            var config = {
                'body' : {
                    "sid" : 'biyyah_001',
                    "lemma" : "",
                    "entry" : testEntryForValidation
                },
                'headers' : { "Accept" : "application/vnd.wde.v2+json", "Content-Type" : "application/json" },
                'auth' : dictuserauth,
                'time' : true 
            },
            response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', config);
            expect(response).to.have.json((body) => {
                var statusCode = response.valueOf().response.statusCode;
                expect(body).to.satisfy((body) =>{
                    return (statusCode == 201 && body.id === 'biyyah_001' && body.type === 'entry') ||
                           (statusCode == 503 && body.detail.includes('Please install') && body.detail.includes('http://github.com/Schematron/schematron-basex'))
                });
            });
            return chakram.wait();
        });

            it('should respond 422 for "Unprocessable Entity" if entry does not conform the schema', function() {
                var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"biyyah_001",
                        "lemma":"",
                        "entry": testEntryForValidationWithErrorRecognizedBySchematron
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json","Content-Type" : "application/json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.json((body) => {
                    var statusCode = response.valueOf().response.statusCode;
                    expect(body.detail).to.satisfy((detail) =>{
                        return statusCode == 422 && detail.includes('Unknown error during additional validation.') ||
                               statusCode == 503 && detail.includes('Please install') && detail.includes('http://github.com/Schematron/schematron-basex')
                    });
                });
                
                return chakram.wait();
            });
    });
        afterEach('Remove the test profile', function(){
            return request('get', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth
            })
            .then(function(){
            return request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth
            }).then(function(){
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
    // Tests for additional validation - end