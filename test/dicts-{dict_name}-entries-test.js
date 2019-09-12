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
            });
        });
        });
    });
    
    describe('tests for post', function() {
        it('should respond 201 for "Created"', function() {
            var config = { 
                'body': {
                    "sid": "dictProfile",
                    "lemma": "",
                    "entry": compiledProfileTemplate({ 'dictName': dictuser.table })
                },
                'headers': { "Accept": "application/vnd.wde.v2+json" },
                'auth': dictuserauth,
                'time': true
            },
                response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);

            expect(response).to.have.status(201)
            expect(response).to.have.json(function(body){
                expect(body.id).to.equal('dictProfile')
                expect(body.type).to.equal('profile')
            })
            return chakram.wait()
        });


        xit('should respond 400 for "Client Error"', function() {
            var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                'body': {"sid":"cillum Ut","lemma":"proident officia dolore","entry":"eu et ipsum"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                'body': {
                    "sid":"mollit nostrud adipisicing",
                    "lemma":"sunt sint",
                    "entry":"adipisicing sunt amet laborum"
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                'body': {
                    "sid":"magna in",
                    "lemma":"Duis",
                    "entry":"officia proident anim dolor"
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': {'user': 'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                'body': {
                    "sid":"irure",
                    "lemma":"ut aliquip",
                    "entry":"id eiusmod est eu"
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
            var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', {
                'json': false,
                'body': "ut deserunt voluptate",
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });

        describe('should respond 422 for "Unprocessable Entity"', function() {
            it('if entry is not well formed XML"', function() {
                var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"dictProfile",
                        "lemma":"",
                        "entry": "<profile><tabeName></profile></tableName>"
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(422);
                return chakram.wait();
            });
            
            it('if entry has no @xml:id"', function() {
                var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"dictProfile",
                        "lemma":"",
                        "entry": "<profile><tabeName></tableName></profile>"
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
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

    describe('tests for get', function() {
        describe('should respond 200 for "OK"', function() {
            beforeEach('Add test data', function() {
                // chakram.startDebug();
                var config = { 
                    'body': {
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({ 'dictName': dictuser.table })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                },
                    response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);
    
                expect(response).to.have.status(201);
                return chakram.wait()
                .then(function() {
                var config = { 
                    'body': {
                        "sid": "test01",
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': 'test01',
                            'translation_en': 'test',
                            'translation_de': 'Test',
                            })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                },
                    response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);
    
                expect(response).to.have.status(201);
                return chakram.wait();                
                })
                .then(function() {
                    //chakram.startDebug();
                });
            });
            it('just get all entries', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("2")
                    expect(body._embedded.entries).to.have.length(2)
                    expect(body._embedded.entries[0].id).to.equal("dictProfile")
                    expect(body._embedded.entries[1].id).to.equal("test01")
                });
                return chakram.wait();
            });
            
            it('filter by id', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"id": "test01"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("1")
                    expect(body._embedded.entries).to.have.length(1)
                    expect(body._embedded.entries[0].id).to.equal("test01")
                    expect(body._links.self.href).to.contain("id=test01")
                    expect(body._links.first.href).to.contain("id=test01")
                    expect(body._links.last.href).to.contain("id=test01")
                });
                return chakram.wait();
            });
            
            it('filter by id that starts with something', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"id": "test*"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("1")
                    expect(body._embedded.entries).to.have.length(1)
                    expect(body._embedded.entries[0].id).to.equal("test01")
                    expect(body._links.self.href).to.contain("id=test%2A")
                    expect(body._links.first.href).to.contain("id=test%2A")
                    expect(body._links.last.href).to.contain("id=test%2A")
                })
                return chakram.wait();
            });
                        
            it('filter by a comma separated list of ids', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"ids": "test01,dictProfile"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("2")
                    expect(body._embedded.entries).to.have.length(2)
                    expect(body._embedded.entries[0].id).to.equal("dictProfile")
                    expect(body._embedded.entries[1].id).to.equal("test01")
                    expect(body._links.self.href).to.contain("ids=test01%2CdictProfile")
                    expect(body._links.first.href).to.contain("ids=test01%2CdictProfile")
                    expect(body._links.last.href).to.contain("ids=test01%2CdictProfile")
                });
                return chakram.wait();
            });
                        
            xit('filter using an XQuery', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                return chakram.wait();
            });
            afterEach('Remove test data', function() {
                // chakram.stopDebug();
                return request('get', baseURI+'/dicts/'+dictuser.table+'/entries/test01', {
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'qs': {'lock': 2},
                    'auth': dictuserauth
                })
                .then(function(){
                return request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/test01', {
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth
                });
                });
            });
        });

        it('should respond 400 for useless "filter"', function() {
            var response = request('get', baseURI+'/dicts/' + dictuser.table + '/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': { id: '*' },
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(400)
            expect(response).to.have.json(function(body){
                expect(body.detail).to.equal("id=* is no useful filter")
            });
            return chakram.wait();
        });

        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', baseURI+'/dicts/idDuisveniamqui/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', baseURI+'/dicts/doin/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth':{'user':'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('get', baseURI + '/dicts/inmollit/entries', { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json('No function found that matches the request.')
            return chakram.wait();
        });
    
    });
    
    // Perhaps not needed at all: Warnung! Dangerous! Deletes every entry except the system entries < 699 from the dictionary.
    // describe('tests for delete', function() {
    //     it('should respond 204 for "No Content"', function() {
    //         var response = request('delete', baseURI+'/dicts/pariatur/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(204);
    //         return chakram.wait();
    //     });


    //     it('should respond 401 for "Unauthorized"', function() {
    //         var response = request('delete', baseURI+'/dicts/irureinfugiatculpaelit/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(401);
    //         return chakram.wait();
    //     });


    //     it('should respond 403 for "Forbidden"', function() {
    //         var response = request('delete', baseURI+'/dicts/quisconsequatveniamametlaborum/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(403);
    //         return chakram.wait();
    //     });


    //     it('should respond 406 for "Not Acceptable"', function() {
    //         var response = request('delete', baseURI+'/dicts/velit/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(406);
    //         return chakram.wait();
    //     });


    //     it('should respond 415 for "Unsupported Media Type"', function() {
    //         var response = request('delete', baseURI+'/dicts/autenonnulla/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(415);
    //         return chakram.wait();
    //     });
    
    // });
    
    xdescribe('tests for patch', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('patch', baseURI+'/dicts/nostrudsit/entries', { 
                'body': {"sid":"est velit dolore","lemma":"eiusmod aliquip proident","entry":"esse"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('patch', baseURI+'/dicts/eiusmodconsequ/entries', { 
                'body': {"sid":"nostrud quis consequa","lemma":"ullamco qui dolore ipsum","entry":"consequat consectetur"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('patch', baseURI+'/dicts/ametineuUt/entries', { 
                'body': {"sid":"ut ut consectetur ad aliquip","lemma":"laborum proident","entry":"do nostrud qui"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('patch', baseURI+'/dicts/aute/entries', { 
                'body': {"sid":"incididunt veniam aute sint ex","lemma":"irure","entry":"ut in qui et Ut"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('patch', baseURI+'/dicts/s/entries', { 
                'body': {"sid":"co","lemma":"ut","entry":"magna sed"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('patch', baseURI+'/dicts/dolorecommodo/entries', { 
                'body': {"sid":"reprehenderit sint","lemma":"dolor labore aliqua voluptate","entry":"sit in"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


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