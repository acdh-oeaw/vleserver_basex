'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;

describe('tests for /dicts/{dict_name}/users/{users_id}', function() {
    describe('tests for get', function() {
        it('should respond 200 for "OK"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/Utproidentametincididunt/users/dolor', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(200);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/consecteturcillumdolor/users/dolo', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/sit/users/quivelit', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/estofficiaesse/users/pariaturdeseruntexe', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/utsit/users/laboreaute', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('get', 'http://localhost:8984/restutf8/dicts/mollitdeserunteualiqua/users/irureincididuntveniampariaturlab', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for delete', function() {
        it('should respond 204 for "No Content"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/irureconsecteturcupidatatadea/users/pariaturin', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(204);
            return chakram.wait();
        });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/doloreveniamofficiaLoremin/users/qui', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/nostrudquivolu/users/quissedut', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 for "Not Found"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/laborenostrudadvoluptate/users/sintcommodo', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            return chakram.wait();
        });


        it('should respond 406 for "Not Acceptable"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/ut/users/esseet', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(406);
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('delete', 'http://localhost:8984/restutf8/dicts/nostrudamet/users/esse', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });
    
    });
    
    describe('tests for post', function() {
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