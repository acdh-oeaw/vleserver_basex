'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

describe('tests for /dicts/{dict_name}/entries/{entries_id}/entries_ndx/{entries_ndx_id}', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/exercitationsitquipariaturcillum/entries/magnaeu/entries_ndx/addeseruntvoluptate', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/deseruntDuisnostrudproident/entries/utLoremdeserunt/entries_ndx/proident', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/veniamanimdodolor/entries/deseruntcommodovoluptate/entries_ndx/cillumLoremcommodo', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/sitcillum/entries/a/entries_ndx/deseruntinExcepteur', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/utcommodoeu/entries/minimculpaconsequat/entries_ndx/ut', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/Loremirureconsequa/entries/laborumexercitation/entries_ndx/culpanoncillumUt', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for put', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/Excepteuridad/entries/inestdolore/entries_ndx/occaecatirureut', { 
                'body': {"id":"sunt et U","xpath":"ipsum ex elit","txt":"tempor cillum id sit"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/quiproident/entries/eiusmodDuis/entries_ndx/dolorestexeiusmod', { 
                'body': {"id":"Ut voluptate est","xpath":"laborum et sit commodo aliquip","txt":"exercitation"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/ut/entries/velitinsuntex/entries_ndx/occaecatinDuis', { 
                'body': {"id":"enim adipisicing sed est","xpath":"ut tempor","txt":"labore esse dolore ea pariatur"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/quicillumullamcoipsum/entries/cupidatatoccaecat/entries_ndx/auteexExcepteur', { 
                'body': {"id":"consequat","xpath":"ut laborum","txt":"sunt eu"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/euindolore/entries/Excepteurutsit/entries_ndx/ametoccaecatea', { 
                'body': {"id":"dolor deserunt","xpath":"cupidatat incididunt commodo","txt":"proident quis sed ut dolore"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/utmagnaessereprehenderit/entries/animsuntincididuntreprehenderitcupidatat/entries_ndx/culpasit', { 
                'body': {"id":"proident","xpath":"reprehenderit velit non sunt","txt":"nulla eiusmod Ut ex"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/consequatDuis/entries/magnasittemporsuntvoluptate/entries_ndx/animve', { 
                'body': {"id":"dolor commodo","xpath":"non qui aliqua deserunt","txt":"exercitatio"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('put', 'http://localhost:8984/restutf8/dicts/Utminimveniam/entries/enimquietipsum/entries_ndx/autedoelit', { 
                'body': {"id":"officia mollit reprehenderit Ut in","xpath":"elit consequat aliquip commodo","txt":"ullamco veniam reprehenderit et"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
    
    describe('tests for delete', function() {
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/nonoccaecatcillum/entries/pariatur/entries_ndx/eanisiculpanulla', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/proidentvoluptatedolor/entries/ut/entries_ndx/essedoofficiamollit', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/Lorem/entries/elitlaborumdolorquislabore/entries_ndx/Duisvelitadipisicingaliquanostrud', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/occaecatculpacillumesse/entries/occaecatcomm/entries_ndx/ininveniam', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/estsint/entries/laborum/entries_ndx/doirureametea', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/officia/entries/aliquipenim/entries_ndx/nostrudDuisquiin', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for post', function() {
        it('should respond 201 for "Created"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/eiusmodenimlaboriscon/entries/nulladolorepariaturvelit/entries_ndx/adipisicing', { 
                'body': {"id":"labore dolore culpa reprehenderit","xpath":"Ut ut sit","txt":"est nostrud "},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(201);
            return chakram.wait();
        });


        it('should respond 400 for "Client Error"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/laboreexercitation/entries/adlaborumest/entries_ndx/irure', { 
                'body': {"id":"veniam","xpath":"dolor pariatur labore laborum","txt":"ipsum dolor"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(400);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/sedest/entries/eiusmodex/entries_ndx/aliquaexsedaliquip', { 
                'body': {"id":"sunt ut proident","xpath":"magna irure","txt":"laboris"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/id/entries/proidentestsunt/entries_ndx/Loremofficiased', { 
                'body': {"id":"dolor occaecat","xpath":"proident ut","txt":"pariatur"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/et/entries/qui/entries_ndx/noneairuread', { 
                'body': {"id":"id ex","xpath":"eiusmod tempor non nulla qui","txt":"proident Excepteur et"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/quiscupidatat/entries/ipsumreprehenderit/entries_ndx/commodoofficia', { 
                'body': {"id":"do elit Excepteur aliqua irure","xpath":"eiusmod voluptate in consectetur culpa","txt":"minim est ut enim"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/dolorculpaipsumreprehenderit/entries/deseruntpariatur/entries_ndx/voluptateDuisUtquismagna', { 
                'body': {"id":"minim","xpath":"do minim fugiat ullamco","txt":"commodo exercitation laboris ex"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });


        it('should respond 422 for "Unprocessable Entity"', function() {
            var response = request('post', 'http://localhost:8984/restutf8/dicts/nostrudlaborisaliquipullamco/entries/enimametcillumlabore/entries_ndx/consecteturutanimreprehenderit', { 
                'body': {"id":"sed ut voluptate","xpath":"culpa Ut sunt","txt":"dolor eiusmod cupidatat"},
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(422);
            return chakram.wait();
        });
    
    });
});