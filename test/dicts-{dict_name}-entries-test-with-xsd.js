'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;
var fs = require('fs');
var Handlebars = require('handlebars');

require('./utilSetup');

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
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
        testEntryForValidation,
        testEntryForValidationWithError;
    
    before('Read templated test data', function() {
        // data for testing server side validation
        var testProfileWithSchemaTemplate = fs.readFileSync('test/fixtures/testProfileWithSchemaXSD.xml','utf8');
        expect(testProfileWithSchemaTemplate).to.contain("<tableName>{{dictname}}</tableName>");
        compiledProfileWithSchemaTemplate = Handlebars.compile(testProfileWithSchemaTemplate);
        testEntryForValidation = fs.readFileSync('test/fixtures/testEntryForValidation.xml','utf8');
        expect(testEntryForValidation).to.contain('xml:id="biyyah_001"');
        testEntryForValidationWithError = fs.readFileSync('test/fixtures/testEntryForValidationWithError.xml','utf8');
        expect(testEntryForValidationWithError).to.contain('<hom id="error-entry-1" xml:lang="de">');
    });

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
                               "entry" : compiledProfileWithSchemaTemplate({ 'dictname' : dictuser.table }) },
                    'time' : true 
                })
            });
        });
        });
    });
    
    describe('tests for post with xsd', function() {
        // test if the adding of entries is possible also the validation is present now
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
            expect(response).to.have.status(201);
            return chakram.wait();
        });

        describe('should respond 422 for "Unprocessable Entity" with xsd', function() {
            it('if entry does not conform the schema"', function() {
                var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"biyyah_001",
                        "lemma":"",
                        "entry": testEntryForValidationWithError
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json","Content-Type" : "application/json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(422);
                
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
            });
        });
        });
    });
    
    xdescribe('tests for patch with xsd', function() {

        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('patch', baseURI+'/dicts/magna/entries', { 
                'body': {"sid":"do adipisicing elit est","lemma":"sunt in exercitation","entry":"proident consectetur cillum ex"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });   
    afterEach(function(){
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
}