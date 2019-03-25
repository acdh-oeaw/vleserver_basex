'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

require('./utilSetup');

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}/users', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI+'/dicts/essedolorecillum/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', baseURI+'/dicts/cillum/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', baseURI+'/dicts/Excepteurirure/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', baseURI+'/dicts/deseruntculpa/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', baseURI+'/dicts/occaecatmagnaDuis/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for post', function() {
        it('should respond 201 for "Created"', function() {
            var response = request('post', baseURI+'/dicts/c/users', { 
                'body': {"id":"reprehenderit","userID":"non deserunt nulla id","pw":"in anim esse","read":"esse ut","write":"laboris tempor","writeown":"culpa"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(201);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('post', baseURI+'/dicts/irureconsequat/users', { 
                'body': {"id":"pariatur qui","userID":"irure Lorem Excepteur","pw":"et ex","read":"elit in ","write":"pariatur aliqua","writeown":"cupidatat ea fugiat adipisicing"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('post', baseURI+'/dicts/nullaveniamExcepteu/users', { 
                'body': {"id":"proident velit occaecat","userID":"in deserunt in tempor","pw":"mollit pariatur","read":"velit","write":"sed Ut esse ea","writeown":"Excepteur Lorem in deserunt"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('post', baseURI+'/dicts/adipisicingcommodoessedoloremagna/users', { 
                'body': {"id":"Ut ut cillum dolore","userID":"ut et in ullamco","pw":"qui","read":"enim ut sed labore","write":"dolore anim Lorem","writeown":"velit et"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('post', baseURI+'/dicts/ineuid/users', { 
                'body': {"id":"pari","userID":"labore ad anim deserunt","pw":"sint","read":"enim do","write":"elit esse et consequat culpa","writeown":"esse Lorem"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('post', baseURI+'/dicts/veniamadipisicingeacupidatat/users', { 
                'body': {"id":"sunt et nostrud dolore","userID":"veniam sunt","pw":"cupidatat pariatur","read":"cupidatat","write":"nostrud dolor","writeown":"aliquip Ut enim eu"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('post', baseURI+'/dicts/incididunt/users', { 
                'body': {"id":"laboris do adipisicing laborum","userID":"dolor dolore","pw":"mollit eiusmod cupidatat dolor","read":"reprehenderit irure cillum magna","write":"veniam am","writeown":"ea magna"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
});
}