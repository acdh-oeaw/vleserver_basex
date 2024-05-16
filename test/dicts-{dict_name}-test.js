'use strict';
const mocha = require('mocha');
const chakram = require('chakram');
const assert = require('chai').assert;
const request = chakram.request;
const expect = chakram.expect;
const fs = require('fs');
const Handlebars = require('handlebars');

const wrong_accept_basex_9 = "No function found that matches the request."
const wrong_accept_basex_9_7 = "Service not found."

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}', function() {
    var superuser = {
        "id": "",
        "userID": basexAdminUser,
        "pw": basexAdminPW,
        "read": "y",
        "write": "y",
        "writeown": "n",
        "table": "dict_users"
      },
        superuserauth = { "user": superuser.userID, "pass": superuser.pw },
        newSuperUserID,
        compiledProfileTemplate;
    before(function () {
        var testProfileTemplate = fs.readFileSync('test/fixtures/testProfile.xml', 'utf8');
        expect(testProfileTemplate).to.contain("<tableName>{{dictName}}</tableName>");
        expect(testProfileTemplate).to.contain("<displayString>{{displayString}}</displayString>");
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
        expect(testProfileTemplate).to.contain("<tableName>replaced</tableName>");
        expect(testProfileTemplate).to.contain('displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<');
        expect(testProfileTemplate).to.contain('altDisplayString label="test">//mds:titleInfo/mds:title<');
        expect(testProfileTemplate).to.contain('mainLangLabel>aNCName<');
        expect(testProfileTemplate).to.contain('useCache/>');
    });
    beforeEach(function () {
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
                });
        });
    });

    describe('tests for get', function() {
        var dictuser = {
            "id": "",
            "userID": 'testUser0',
            "pw": 'PassW0rd',
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "deseruntsitsuntproident"
        },
            dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
            newDictUserID;
        
        beforeEach('Create test user and test table', async function(){
            var userCreateResponse = await request('post', baseURI + '/dicts/dict_users/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'auth': superuserauth,
                'body': dictuser,
                'time': true
            });
            newDictUserID = userCreateResponse.body.id;
            await request('post', baseURI + '/dicts', {
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': superuserauth,
                    'body': {"name": dictuser.table},
                    'time': true
            });
        });
        describe('should respond 200 for "OK', async function() {
            it('when authenticated', async function() {
                var response = request('get', baseURI + '/dicts/deseruntsitsuntproident', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json((body) => {
                    expect(body.total_items).to.equal("2");
                    expect(body._embedded._[0].note).to.equal("all entries");
                    expect(body._embedded._[0].cache).to.be.undefined;
                    expect(body._embedded._[0].dbNames).to.be.an.instanceof(Array);
                    expect(body._embedded._[0].queryTemplates).to.be.an.instanceof(Array);
                    expect(body._embedded._[1].note).to.equal("all users with access to this dictionary");
                });
                return chakram.wait();
            });

            it('when unauthenticated (public)', async function() {
                var response = request('get', baseURI + '/dicts/deseruntsitsuntproident', {
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json((body) => {
                    expect(body.total_items).to.equal("2")
                    expect(body._embedded._[0].note).to.equal("all entries");
                    expect(body._embedded._[0].cache).to.be.undefined;
                    expect(body._embedded._[0].dbNames).to.be.an.instanceof(Array);
                    expect(body._embedded._[0].queryTemplates).to.be.an.instanceof(Array);
                    expect(body._embedded._[1].note).to.equal("all users with access to this dictionary");
                });
                return chakram.wait();
            });

            it('should report whether the cache is activated', async function(){
                var config = { 
                    'body': {
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'displayString': '//tei:form/tei:orth[1]',
                            'useCache': true
                         })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                };

                var response = await request('get', baseURI + '/dicts/'+dictuser.table+'/entries/dictProfile', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {'lock': 2},
                    'auth': dictuserauth,                    
                })
                expect(response).to.have.status(200);
                
                response = await request('put', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', config);
                expect(response).to.have.status(200);

                response = await request('get', baseURI + '/dicts/deseruntsitsuntproident', {
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json((body) => {
                    expect(body.total_items).to.equal("2")
                    expect(body._embedded._[0].note).to.equal("all entries");
                    expect(body._embedded._[0].cache).to.equal("true");
                });
                return chakram.wait();
            });
        });

        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', baseURI + '/dicts/magna', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                // access needs auth with wde.v2
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', baseURI + '/dicts/minimconsequataliquaoccaecat', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': {'user': 'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        // 404 with wde.v2 is only possible if the table is gone but the user still exists.
        // This should never happen as the delete command removes also all the users.
        // Otherwise: 403

        it('should respond 404 for "Not Found" (public)', function() {
            var response = request('get', baseURI + '/dicts/insed', { 
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });

        it('should respond 404 "' + wrong_accept_basex_9_7 + '" for wrong accept', function () {
            var response = request('get', baseURI + '/dicts/animlaborisdolore', {
                'headers': { "Accept": "application/vnd.wde.v8+json" },
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json(
                (value) => assert(value === 'No function found that matches the request.' || 
                                  value === 'Service not found.', 'Unexpected status message: '+value)
                );
            return chakram.wait();
        });

        // 415 is used for rejecting a body, so makes no sense here

        afterEach(function() {
            return request('delete', baseURI + '/dicts/' + dictuser.table, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            })
            .then(function(dictDeletedResponse) {
            return request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });
            });
        });
    });
    
    describe('tests for delete', function() {
        var dictuser = { // a superuser for the test table
            "id": "",
            "userID": 'testUser0',
            "pw": 'PassW0rd',
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "deseruntsitsuntproident"
        },
            dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
            newDictUserID;
        beforeEach('Create test user', function(){
            return request('post', baseURI + '/dicts/dict_users/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'auth': superuserauth,
                'body': dictuser,
                'time': true
            })
            .then(function(userCreateResponse) {
                newDictUserID = userCreateResponse.body.id;
            });
        });
        it('should respond 204 for "No Content"', function() {
            // A new table can only be created by a global super user
            return request('post', baseURI + '/dicts', {
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'body': {"name": dictuser.table},
                'time': true
            })
            .then(function(dictCreatedResponse) {
                // A table can only be deleted by a super user of that table
                // A global super user would need to make himself superuser of that table
                var response = request('delete', baseURI + '/dicts/' + dictuser.table, { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(204);
                return chakram.wait();
            });
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', baseURI + '/dicts/' + dictuser.table, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', baseURI + '/dicts/eiusmodtempor', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': {'user': 'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        // 404 for delete is not possible, it is always 403

        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', baseURI + '/dicts/aliquipcommodoid', { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });

        // 415 is used for rejecting a body, so makes no sense here

        afterEach('Remove test user', function(){
            return request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });
        });
    
    });
    afterEach(function(){
        return request('delete', baseURI + '/dicts/dict_users', { 
            'headers': {"Accept":"application/vnd.wde.v2+json"},
            'auth': superuserauth,
            'time': true
        });
    });
});
}