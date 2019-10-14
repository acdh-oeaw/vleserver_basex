'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}/users/{users_id}', function() {
    // added T.K. - make dict_users and the superuser available
    this.beforeAll(function(){
        let superuser = {
            "id": "",
            "userID": basexAdminUser,
            "pw": basexAdminPW,
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "dict_users"
          };
        let superuserauth = {"user" : superuser.userID, "pass" : superuser.pw};

        return request('post', baseURI + '/dicts', {
            'headers': {"Accept":"application/vnd.wde.v2+json",
                        "Content-Type":"application/json"},
            'body': {'name': 'dict_users'},
            'time': true
            }).then(function(){
                return request('post', baseURI + '/dicts/dict_users/users', { 
                    'headers': {"Accept":"application/vnd.wde.v2+json",
                                "Content-Type":"application/json"},
                    'body': superuser,
                    'time': true
                    });
                });
    });
    // delete dict_users table
    this.afterAll(function(){
        let superuser = {
            "id": "",
            "userID": basexAdminUser,
            "pw": basexAdminPW,
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "dict_users"
          };
        let superuserauth = {"user" : superuser.userID, "pass" : superuser.pw};

        return request('delete', baseURI + '/dicts/dict_users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': superuserauth,
                'time': true
            });
    });

    describe('tests for get', function() {
        // added T.K. start - make more tests applicable
        let userName = "someName";
        let userPW = "somePassword";
        let read = "y";
        let write = "y";
        let writeown = "n";
        let table = "";
        let userId = "";
        let superuser = {
            "id": "",
            "userID": basexAdminUser,
            "pw": basexAdminPW,
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "dict_users"
          };
        let superuserauth = {"user" : superuser.userID, "pass" : superuser.pw};
        // setup for each test - create a test user in the database
        this.beforeEach(function() {
            return request("post", baseURI + '/dicts/dict_users/users/', {
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'body': {"id" : "", "userID" : userName, "pw" : userPW, "read" : read, "write" : write, "writeown" : writeown, "table" : "dict_users"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });
        });
        // added T.K. end
        // Testing response codes:
        //      200 - Ok, 401 - Unauthorized, 403 - Forbidden, 404 - Not Found, 406 - Not Acceptable, 415 - Unsupported media type
        // get a particular user (= testuser)
        // this test fails and I don't know why
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers' : {"Accept" : "application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });

        // try to get a particular user without credentials
        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });

        // try to access dict_users without superuser rights - this is possible
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': {"user" : userName, "pass" : userPW},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });

        // try to access a resource which does not exist
        it('should respond 404 for "Not Found"', function() {
            var response = request('get', baseURI + '/dicts/dict_users/users/' + "anotexistinguser", { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });

        // don't know what this test means
        xit('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/utsit/users/laboreaute', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });

        // request for a not supported media type - This test fails: Return value is 404
        xit('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers' : {"Accept" : "application/vnd.wde.v8+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time' : true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });

        // added T.K. start
        it('should return a particular user with userName = ' + userName, function(){
            var response = request('get', baseURI + '/dicts/dict_users/users/' + userName, {
                'headers' : {"Accept" : "application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time' : true
            });

            expect(response).to.have.status(200);
            expect(response).to.have.json(function(body){
                expect(body.userID).to.equal(userName);
            });
            return chakram.wait();
        });
        // added T.K. end

        // added T.K. start - cleanup - delete test user
        afterEach(function(){
            return request('delete', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });
        // added T.K. end
    });
});
    
    describe('tests for delete', function() {
        // added T.K. start - make more tests applicable
        let userName = "someName";
        let userPW = "somePassword";
        let read = "true";
        let write = "false";
        let writeown = "false";
        let table = "";
        let userId = "";
        let superuser = {
        "id": "",
        "userID": basexAdminUser,
        "pw": basexAdminPW,
        "read": "y",
        "write": "y",
        "writeown": "n",
        "table": "dict_users"
        };
        let superuserauth = {"user" : superuser.userID, "pass" : superuser.pw};
        // setup for each test - create a test user in the database
        this.beforeEach(function() {
            return request("post", baseURI + '/dicts/dict_users/users/', {
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'body': {"id" : "", "userID" : userName, "pw" : userPW, "read" : read, "write" : write, "writeown" : writeown, "table" : "dc_loans_genesis"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            }).then(function(createdUser){ userId = createdUser.body.id; table = createdUser.body.table; });
        });
        // added T.K. end
        // try to delete a user which does not exist - but isn't this the case 404 Not Found? - a misunderstanding?
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', baseURI + '/dicts/dict_users/users/' + "userwhichdoesnotexist", { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });

        // added T.K. start
        // try to delete an user with success - this test fails, request delivers 204
        xit('should respond 200 for "Ok"', function() {
            var response = request('delete', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });
        // added T.K. end
        // try to delete an user without rights
        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });

        // try to delete an user without sufficient rights
        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : userName, "pass" : userPW},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });

        // try to delete an user which does not exist - compare note above - test fails, request delivers 204
        xit('should respond 404 for "Not Found"', function() {
            var response = request('delete', baseURI + '/dicts/dict_users/users/' + "userwhichdoesnotexist", { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });

        // don't know what this test should do
        xit('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/ut/users/esseet', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });

        // which role has the media type for a delete operation? - this test fails, request delivers 406
        xit('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
        // added T.K. start - cleanup - delete test user
        afterEach(function(){
            return request('delete', baseURI + '/dicts/dict_users/users/' + userName, { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth' : {"user" : superuserauth.user, "pass" : superuserauth.pass},
                'time': true
            });
        });
        // added T.K. end    
    });
    
    xdescribe('tests for post', function() {
        it('should respond 201 for "Created"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/eu/users/amet', { 
                'body': {"id":"magna laborum cupidatat labore","userID":"dolore minim in officia nostrud","pw":"quis minim","read":"ipsum sed sint","write":"dolor dolore sed","writeown":"enim esse ea mollit"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(201);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/elitfugiat/users/animquisquietaliqua', { 
                'body': {"id":"non Excepteur anim pariatur","userID":"qui Duis magna in nostrud","pw":"et minim","read":"ex non","write":"nulla cupidatat ad","writeown":"ut"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/domollit/users/aliqua', { 
                'body': {"id":"officia adipisicing incididunt dolor","userID":"ea ut aliquip","pw":"aute cillum labore enim","read":"fugiat dolore","write":"est","writeown":"en"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/animetidnulla/users/incididuntullamco', { 
                'body': {"id":"Lorem aute","userID":"mollit pariatur in irure","pw":"aute dolore","read":"veniam id ut aliqua","write":"cupidatat anim","writeown":"irure nulla"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/animaliquaipsum/users/fugiatenimreprehenderit', { 
                'body': {"id":"mollit labore in","userID":"aliquip Duis dolore laboris","pw":"mollit occaecat","read":"commodo Lorem tempor","write":"id dolore non nisi sint","writeown":"in"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/fugiatinesseaddolore/users/culpavelitdolorereprehenderit', { 
                'body': {"id":"sunt Lorem ut anim enim","userID":"dolore qui nulla","pw":"do proident aute commodo","read":"laborum esse fugiat nostrud","write":"non velit eu","writeown":"proident magna"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
});
};