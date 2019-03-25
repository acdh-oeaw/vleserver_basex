'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

require('./utilSetup');

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}/entries', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', baseURI+'/dicts/nostrudsedeaincididunt/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
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
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', baseURI+'/dicts/inmollit/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', baseURI+'/dicts/elitiruretemporreprehenderit/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for post', function() {
        it('should respond 201 for "Created"', function() {
            var response = request('post', baseURI+'/dicts/pariaturaute/entries', { 
                'body': {"sid":"incididunt in veniam eiusmod","lemma":"velit","entry":"velit laborum"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(201);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('post', baseURI+'/dicts/Excepteurdolor/entries', { 
                'body': {"sid":"cillum Ut","lemma":"proident officia dolore","entry":"eu et ipsum"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('post', baseURI+'/dicts/aute/entries', { 
                'body': {"sid":"mollit nostrud adipisicing","lemma":"sunt sint","entry":"adipisicing sunt amet laborum"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('post', baseURI+'/dicts/sitsintmagn/entries', { 
                'body': {"sid":"magna in","lemma":"Duis","entry":"officia proident anim dolor"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('post', baseURI+'/dicts/suntDuis/entries', { 
                'body': {"sid":"irure","lemma":"ut aliquip","entry":"id eiusmod est eu"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('post', baseURI+'/dicts/Loremid/entries', { 
                'body': {"sid":"aliqua id","lemma":"amet Excepteur","entry":"ut deserunt voluptate"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('post', baseURI+'/dicts/et/entries', { 
                'body': {"sid":"veniam enim","lemma":"Excepteur minim eu","entry":"ut sed"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
    
    describe('tests for delete', function() {
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', baseURI+'/dicts/pariatur/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', baseURI+'/dicts/irureinfugiatculpaelit/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', baseURI+'/dicts/quisconsequatveniamametlaborum/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', baseURI+'/dicts/velit/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', baseURI+'/dicts/autenonnulla/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for patch', function() {
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
});
}