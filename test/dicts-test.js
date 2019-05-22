'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

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
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI + '/dicts', { 
                // Accessing dicts without a username and password is only possible without
                // 'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });
            expect(response).to.have.status(200);
            expect(response).to.have.header("content-type", "application/json;charset=utf-8");
            expect(response).to.comprise.of.json({
                "_links": {
                    "_self": {
                        "href": "/restvle/dicts?pageSize=25"
                    },
                    "_first": {
                        "href": "/restvle/dicts?page=1&pageSize=25"
                    },
                    "_last": {
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

        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', baseURI + '/dicts', { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'time': true
            });

            expect(response).to.have.status(406);
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


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"anim labore pariatur"},
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'time': true
            });

            expect(response).to.have.status(406);
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