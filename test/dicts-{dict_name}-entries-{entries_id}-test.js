'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

describe('tests for /dicts/{dict_name}/entries/{entries_id}', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/Lo/entries/Utnisiveniam', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/enimmollitirure/entries/iruredoUtminimsunt', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/in/entries/consequatdoloreexercitation', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/elitdoloreiusmodlaborum/entries/autelaboresed', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/doloreenim/entries/ut', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/fugiatelitdolornisi/entries/adipisicingeuullamcoessefugiat', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for patch', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/involuptateullamcoeulabori/entries/dolorcommodolaborisea', { 
                'body': {"sid":"in","lemma":"qui velit sunt","entry":"irure quis pariatur"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/consecteturvoluptatenulla/entries/laboristempormollitet', { 
                'body': {"sid":"laboris reprehenderit sed eiusmod amet","lemma":"consectetur velit","entry":"ad est"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/proidentnostrudExcepteur/entries/esseincididunt', { 
                'body': {"sid":"minim nulla reprehende","lemma":"in do","entry":"qui quis vo"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/ametnostruddolore/entries/doloreminim', { 
                'body': {"sid":"non laboris culpa est","lemma":"sint commodo Lorem et","entry":"pari"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/sint/entries/dofugiatin', { 
                'body': {"sid":"ad enim fugiat","lemma":"sed","entry":"Lorem ad"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts//entries/velitnostrudipsumenimdo', { 
                'body': {"sid":"ea in","lemma":"ut ut est Ut","entry":"Ut mollit "},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/exipsumquinulladolore/entries/magnaaliquip', { 
                'body': {"sid":"in ea","lemma":"veniam sed Duis","entry":"irure eiusmod e"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('patch', 'http://localhost:8984/restutf8/dicts/consecte/entries/inincididuntlaboru', { 
                'body': {"sid":"cillum sed","lemma":"elit nostrud","entry":"proident eiusmod nostrud"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
    
    describe('tests for put', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/mollitofficia/entries/innisiut', { 
                'body': {"sid":"id proident cillum","lemma":"pariatur proident quis","entry":"eiusmod enim fugiat minim"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/consectetureiusmodlaboris/entries/exer', { 
                'body': {"sid":"non culpa sit cillum amet","lemma":"ipsum","entry":"sit consectetur deserunt incididunt"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/indolore/entries/esse', { 
                'body': {"sid":"eu minim voluptate elit ut","lemma":"ea nulla","entry":"voluptate dolor"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/consequatmagnanullatempordolor/entries/utDuisLoremenimullamco', { 
                'body': {"sid":"dolor ut Excepteur consectetur Ut","lemma":"officia nulla d","entry":"dolor dolore minim id ex"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/quiculp/entries/laborumlaboreExcepteurad', { 
                'body': {"sid":"nulla ullamco laboris anim","lemma":"dolor","entry":"occaecat magna"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/ineuin/entries/deseruntenimeu', { 
                'body': {"sid":"voluptate est","lemma":"labore sint","entry":"occaecat nisi aliqua"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/reprehenderitestullamconos/entries/sintidauteexoccaecat', { 
                'body': {"sid":"non in occaecat","lemma":"in incididunt","entry":"laborum Ut nulla"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/officia/entries/etDuisdoloripsum', { 
                'body': {"sid":"dolore dolor nisi","lemma":"cillum ea amet eiusmod","entry":"dolor non"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
    
    describe('tests for delete', function() {
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/cupidatatadlaborum/entries/insitofficiadeserunt', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/estvoluptateofficia/entries/invelit', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/reprehenderit/entries/ametlaboreExcepteurminim', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/incididunt/entries/proidentlaboriscupidatat', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/utproident/entries/incididuntExcepteursedullamco', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/utvoluptatealiquaE/entries/esseexercitationsuntculpa', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
});