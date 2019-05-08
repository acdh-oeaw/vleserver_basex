'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dicts_name}', function() {
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

    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            return request('post', baseURI + '/restvle/dicts', {

            })
            .then(function(dictCreatedResponse) {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/deseruntsitsuntproident', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/magna', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/minimconsequataliquaoccaecat', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/insed', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/animlaborisdolore', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/sitqui', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for delete', function() {
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/reprehenderit', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/dolorinsint', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/eiusmodtempor', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/voluptateirure', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/aliquipcommodoid', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/consecteturnulla', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
});
}