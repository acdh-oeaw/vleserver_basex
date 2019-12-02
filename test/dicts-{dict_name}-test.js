'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

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
        superuserauth = {"user":superuser.userID, "pass":superuser.pw},
        newSuperUserID;
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
        
        beforeEach('Create test user and test table', function(){
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
                });
            });
        });
        it('should respond 200 for "OK"', function() {             
            var response = request('get', baseURI + '/dicts/deseruntsitsuntproident', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });
            
            expect(response).to.have.status(200);
            return chakram.wait();
        });

        it('should respond 200 for "OK" (public)', function() {             
            var response = request('get', baseURI + '/dicts/deseruntsitsuntproident', { 
                'time': true
            });
            
            expect(response).to.have.status(200);
            return chakram.wait();
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

        it('should respond 404 "No function found that matches the request." for wrong accept', function () {
            var response = request('get', baseURI + '/dicts/animlaborisdolore', {
                'headers': { "Accept": "application/vnd.wde.v8+json" },
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json('No function found that matches the request.')
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