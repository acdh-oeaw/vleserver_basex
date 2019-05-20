'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;var fs = require('fs');
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
            "table": "inad"
        },
        dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
        newDictUserID,
        compiledProfileTemplate,
        compiledEntryTemplate,
        compiledModsEntryTemplate,
        entryID = "animculpaex";
    
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
        var testModsEntryTemplate = fs.readFileSync('test/fixtures/testModsEntry.xml', 'utf8');
        expect(testEntryTemplate).to.contain('"http://www.loc.gov/mods/v3"');
        expect(testEntryTemplate).to.contain('ID="{{id}}"');
        expect(testEntryTemplate).to.contain('>{{author}}<');
        expect(testEntryTemplate).to.contain('>{{translator}}<');
        compiledModsEntryTemplate = Handlebars.compile(testModsEntryTemplate);
        testModsEntryTemplate = ompiledModsEntryTemplate({
            'id': 'testID',
            'author': 'me, I',
            'translator': 'myself, me'
        });       
        expect(testEntryTemplate).to.contain('ID="testID"');
        expect(testEntryTemplate).to.contain('>me, I<');
        expect(testEntryTemplate).to.contain('>myself, me<');
    });

    beforeEach('Set up dictionary and users', function(){
        return request('post', baseURI + '/dicts/'+dictuser.table+'/users', { 
            'headers': {"Accept":"application/vnd.wde.v2+json",
                        "Content-Type":"application/json"},
            'body': superuser,
            'time': true
        })
        .then(function(userCreateResponse) {
            newSuperUserID = userCreateResponse.body.id;
            return request('post', baseURI + '/dicts/'+dictuser.table+'/users', { 
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
                        return request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                            'body': {
                                "sid":"dictProfile",
                                "lemma":"",
                                "entry": compiledProfileTemplate({'dictName': dictuser.table})
                            },
                            'headers': {"Accept":"application/vnd.wde.v2+json"},
                            'auth': dictuserauth,
                            'time': true
                            });                    
                    });            
            });
        });
    });

describe('tests for /dicts/{dict_name}/entries/{entries_id}/changes/{changes_id}', function() {
    describe('tests for get', function() {
        xit('should respond 200 for "OK"', function() {
            var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries/'+entryID+'/changes/ipsumeaeiusmodculpa', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        xit('should respond 401 for "Unauthorized"', function() {
            var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries/'+entryID+'/changes/autefugiatetquisex', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        xit('should respond 403 for "Forbidden"', function() {
            var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries/'+entryID+'/changes/sedametenimtemporaute', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        xit('should respond 404 for "Not Found"', function() {
            var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries/'+entryID+'/changes/indo', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        xit('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries/'+entryID+'/changes/sit', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        xit('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries/'+entryID+'/changes/consecteturdolorlaborisex', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
});
});
};