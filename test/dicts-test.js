'use strict';
const mocha = require('mocha');
const chakram = require('chakram');
const assert = require('chai').assert;
const request = chakram.request;
const expect = chakram.expect;

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts', function() {
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
    // added T.K. start
    // try if it is possible to create the dict_users table
    // this works, however, it should not be possible to create the dict_users table without authentification
    describe('test the creation of the dict_users table - it is possible to create the dict-users table without credentials if the table does not exist', function(){
        it('should response 200 for "OK"',function(){
            var response = request('post', baseURI + '/dicts', {
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'body': {'name': 'dict_users'},
                'time': true
                })
                .then(function(dictUsersCreated){
                    // why is it possible to add an user without authentification? Probably because it is the first user.
                    return request('post', baseURI + '/dicts/dict_users/users', { 
                        'headers': {"Accept":"application/vnd.wde.v2+json",
                                    "Content-Type":"application/json"},
                        'body': superuser,
                        'time': true
                        });
                });

            expect(response).to.have.status(200);
            return chakram.wait();
        });
        // delete the dict_users table after the test
        afterEach(function(){
            return request('delete', baseURI + '/dicts/dict_users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });
        });
    });
    // added T.K. end
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI + '/dicts', { 
                // Accessing dicts without a username and password is only possible without
                // 'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });
            expect(response).to.have.status(200);
            expect(response).to.have.header("content-type", "application/json;charset=utf-8");
            // No dictionaries exist
            expect(response).to.comprise.of.json({
                "_links": {
                    "self": {
                        "href": "/restvle/dicts?pageSize=25"
                    },
                    "first": {
                        "href": "/restvle/dicts?page=1&pageSize=25"
                    },
                    "last": {
                        "href": "/restvle/dicts?page=0&pageSize=25"
                    }
                },
                "_embedded": {
                    "dicts": []
                },
                "page_count": "0",
                "page_size": "25",
                "total_items": "0",
                "page": "1"
            });
            return chakram.wait();
        });

        describe('Authentication messages', function() {
            beforeEach(function(){
                return request('post', baseURI + '/dicts', {
                    'headers': {"Accept":"application/vnd.wde.v2+json",
                                "Content-Type":"application/json"},
                    'body': {'name': 'dict_users'},
                    'time': true
                    })
                    .then(function(dictUsersCreated){
                    // why is it possible to add an user without authentification? Probably because it is the first user.
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
            
            it('should respond 401 for "Unauthorized"', function() {
                var response = request('get', baseURI + '/dicts', { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'time': true
                });

                expect(response).to.have.status(401);
                return chakram.wait();
            });
            
            it('should respond 403 for "Forbidden"', function() {
                var response = request('get', baseURI + '/dicts', { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': {'user': 'notadmin', 'pass': 'wrongpw'},
                    'time': true
                });

                expect(response).to.have.status(403);
                return chakram.wait();
            });
            afterEach(function(){
                return request('delete', baseURI + '/dicts/dict_users', { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': superuserauth,
                    'time': true
                });
            });
        });

        // Accept will now select a particular function the %rest:produces that mime type.
        // Else the less useful 404 No function found that matches the request. is returned.
        // So 406 can not occur anymore.
        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('get', baseURI + '/dicts', { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json(
                (value) => assert(value === 'No function found that matches the request.' || 
                                  value === 'Service not found.', 'Unexpected status message: '+value)
                );
            return chakram.wait();
        });
         
        // 415 is related to the request body, not meaningful here
   
    });
    
    describe('tests for post', function() {
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
        describe('Creating a dictionary', function(){
            var dictname = "sit_laborum_id";
            it('should respond 201 for "Created"', function() {                
                var response = request('post', baseURI + '/dicts', { 
                    'body': {"name": dictname},
                    'headers': {"Accept":"application/vnd.wde.v2+json"},                
                    'auth': superuserauth,
                    'time': true
                });

                expect(response).to.have.status(201);
                expect(response).to.have.json(function(body) {
                    expect(body.title).to.equal("Created")
                });
                return chakram.wait();
            });
            afterEach('Delete that dictionary', function(){
                var dictuser = { // a superuser for the test table
                    "id": "",
                    "userID": 'testUser0',
                    "pw": 'PassW0rd',
                    "read": "y",
                    "write": "y",
                    "writeown": "n",
                    "table": dictname
                },
                    dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
                    newDictUserID;
                return request('post', baseURI + '/dicts/dict_users/users', { 
                    'headers': {"Accept":"application/vnd.wde.v2+json",
                                "Content-Type":"application/json"},
                    'auth': superuserauth,
                    'body': dictuser,
                    'time': true
                })
                .then(function(userCreateResponse) {
                    newDictUserID = userCreateResponse.body.id;
                    return request('delete', baseURI + '/dicts/' + dictname, { 
                        'headers': {"Accept":"application/vnd.wde.v2+json"},
                        'auth': dictuserauth,
                        'time': true
                    });
                })
                .then(function(dictDeletedResponse){                   
                    return request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, { 
                        'headers': {"Accept":"application/vnd.wde.v2+json"},
                        'auth': superuserauth,
                        'time': true
                    });
                });
            });
        });


        xit('should respond 400 for "Client Error"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"ut ut dolore Ut"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"velit anim laboris"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        xit('should respond 403 for "Forbidden"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"quis et"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': {},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"anim labore pariatur"},
                'headers': {"Accept":"application/vnd.wde.v8+json"},
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
            var response = request('post', baseURI + '/dicts', { 
                'form': {"name":"quis"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        xit('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'form': {"name":"irure aliqua exercitation mollit laboris"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
        afterEach(function(){
            return request('delete', baseURI + '/dicts/dict_users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });
        });
    
    });
});
};