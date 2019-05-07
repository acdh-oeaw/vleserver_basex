'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI + '/dicts', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });
            expect(response).to.have.status(200);
            expect(response).to.have.header("content-type", "application/json;charset=utf-8");
            expect(response).to.comprise.of.json({
                "_embedded": {
                  "dicts": []
                 },
                "_links": {
                  "_first": {
                    "href": "/restvle/dicts?page=1&pageSize=25"
                  },
                  "_last": {
                    "href": "/restvle/dicts?page=0&pageSize=25"
                  },
                  "_self": {
                    "href": "/restvle/dicts?pageSize=25"
                  }
                },
                "page": "1",
                "page_count": "0",
                "page_size": "25",
                "total_items": "0"
            });
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var newUserID;
            return request('post', baseURI + '/dicts/dict_users/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'body': {
                    "id": "",
                    "userID": "admin",
                    "pw": "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
                    "read": "y",
                    "write": "y",
                    "writeown": "n",
                    "table": "dict_users"
                  },
                'time': true
            })
            .then(function(userCreateResponse) {
                newUserID = userCreateResponse.body.id;
                var response = request('get', baseURI + '/dicts', { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'time': true
                });

                expect(response).to.have.status(401);
                return chakram.wait();
            })
            .then(function(){
                return request('delete', baseURI + '/dicts/dict_users/users/' + newUserID, { 
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth':{"user":"admin", "pass":"8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"},
                    'time': true
                });
            })
            .then(function(userDeletedResonse){
                var worked = userDeletedResonse.status;
            });
        });


        xit('should respond 403 for "Forbidden"', function() {
            var response = request('get', baseURI + '/dicts', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        xit('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', baseURI + '/dicts', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        xit('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', baseURI + '/dicts', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    xdescribe('tests for post', function() {
        it('should respond 201 for "Created"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"sit laborum id"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(201);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
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


        it('should respond 403 for "Forbidden"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"quis et"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"anim labore pariatur"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"quis"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('post', baseURI + '/dicts', { 
                'body': {"name":"irure aliqua exercitation mollit laboris"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
});
};