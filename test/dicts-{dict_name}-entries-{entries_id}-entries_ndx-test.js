'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

describe('tests for /dicts/{dict_name}/entries/{entries_id}/entries_ndx', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/nostrudpr/entries/suntexercitationeuofficiamollit/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/sitaliquipenimmollit/entries/elit/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/doetquisdolor/entries/deseruntpariaturauteUteiusmod/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/enimmollitDuisdolor/entries/cillumproidentexLorem/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/adautedeserunteiusmod/entries/consequatincididuntest/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for delete', function() {
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/enim/entries/quilaboris/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/utametadipisicing/entries/culpa/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/aliquautenim/entries/utnonincididuntautein/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/aliquaDuisad/entries/aliquipesse/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/incididun/entries/adeteiusmodoccaecat/entries_ndx', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for patch', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/veniam/entries/reprehenderitutexLoremesse/entries_ndx', { 
                'body': {"id":"ipsum dolore quis","xpath":"ex al","txt":"adipisicing et consequat nostrud"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/aliqui/entries/dolordeseruntUtautelaborum/entries_ndx', { 
                'body': {"id":"minim","xpath":"eiusmod reprehenderit","txt":"id ut"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/tempor/entries/cillumsit/entries_ndx', { 
                'body': {"id":"Excepteur ut commodo","xpath":"incididunt laborum","txt":"id est"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/utLoremdolor/entries/inirurequis/entries_ndx', { 
                'body': {"id":"ipsum ullamco proident dolor veniam","xpath":"sit nostrud","txt":"minim nisi consectetur aute eu"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/cupidatat/entries/exercitationullamcolaboreut/entries_ndx', { 
                'body': {"id":"qui enim magna","xpath":"non","txt":"nulla enim"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/fugiatexercitation/entries/proidentnostrudquisveniam/entries_ndx', { 
                'body': {"id":"s","xpath":"dolore","txt":"Duis nulla nostrud"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/Excepteurnulla/entries/inetLoremnon/entries_ndx', { 
                'body': {"id":"id consequat sed in esse","xpath":"et adipisicing","txt":"in commodo eu esse"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
});