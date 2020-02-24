'use strict';
var mocha = require('mocha');
var chakram = require('chakram');
var request = chakram.request;
var expect = chakram.expect;
var fs = require('fs');
var Handlebars = require('handlebars');

require('./utilSetup');

module.exports = function(baseURI, basexAdminUser, basexAdminPW) {
describe('tests for /dicts/{dict_name}/entries', function() {
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
        newSuperUserID,
        dictuser = { // a superuser for the test table
            "id": "",
            "userID": 'testUser0',
            "pw": 'PassW0rd',
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "nostrudsedeaincididunt"
        },
        dictuserauth = {"user":dictuser.userID, "pass":dictuser.pw},
        newDictUserID,
        compiledProfileTemplate,
        compiledEntryTemplate,
        compiledProfileWithSchemaTemplate,
        testEntryForValidation,
        testEntryForValidationWithError;
    
    before('Read templated test data', function() {
        var testProfileTemplate = fs.readFileSync('test/fixtures/testProfile.xml', 'utf8');
        expect(testProfileTemplate).to.contain("<tableName>{{dictName}}</tableName>");
        expect(testProfileTemplate).to.contain("<displayString>{{displayString}}</displayString>");
        compiledProfileTemplate = Handlebars.compile(testProfileTemplate);
        testProfileTemplate = compiledProfileTemplate({
            'dictName': 'replaced',
            'mainLangLabel': 'aNCName',        
            'displayString': '{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}',
            'altDisplayString': {
                'label': 'test',
                'displayString': '//mds:titleInfo/mds:title'
            },
            'useCache': true
        });
        expect(testProfileTemplate).to.contain("<tableName>replaced</tableName>");
        expect(testProfileTemplate).to.contain('displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<');
        expect(testProfileTemplate).to.contain('altDisplayString label="test">//mds:titleInfo/mds:title<');
        expect(testProfileTemplate).to.contain('mainLangLabel>aNCName<');
        expect(testProfileTemplate).to.contain('useCache/>');
        var testEntryTemplate = fs.readFileSync('test/fixtures/testEntry.xml', 'utf8');
        expect(testEntryTemplate).to.contain('"http://www.tei-c.org/ns/1.0"');        
        expect(testEntryTemplate).to.contain('xml:id="{{xmlID}}"');
        expect(testEntryTemplate).to.contain('>{{translation_en}}<');
        expect(testEntryTemplate).to.contain('>{{translation_de}}<');
        compiledEntryTemplate = Handlebars.compile(testEntryTemplate);
        testEntryTemplate = compiledEntryTemplate({
            'xmlID': 'testID',
            'formFaArab': 'تست',
            'formFaXModDMG': 'ṭēsṯ',
            'translation_en': 'test',
            'translation_de': 'Test',
            });
        expect(testEntryTemplate).to.contain('xml:id="testID"');
        expect(testEntryTemplate).to.contain('>test<');
        expect(testEntryTemplate).to.contain('>Test<');
        expect(testEntryTemplate).to.contain('>تست<');
        expect(testEntryTemplate).to.contain('>ṭēsṯ<');
        // data for testing server side validation
        var testProfileWithSchemaTemplate = fs.readFileSync('test/fixtures/testProfileWithSchema.xml','utf8');
        expect(testProfileWithSchemaTemplate).to.contain("<tableName>{{dictname}}</tableName>");
        compiledProfileWithSchemaTemplate = Handlebars.compile(testProfileWithSchemaTemplate);
        testEntryForValidation = fs.readFileSync('test/fixtures/testEntryForValidation.xml','utf8');
        expect(testEntryForValidation).to.contain('xml:id="biyyah_001"');
        testEntryForValidationWithError = fs.readFileSync('test/fixtures/testEntryForValidationWithError.xml','utf8');
        expect(testEntryForValidationWithError).to.contain('<hom id="error-entry-1" xml:lang="de">');
    });

    beforeEach(async function(){
        await request('post', baseURI + '/dicts', {
            'headers': {"Accept":"application/vnd.wde.v2+json",
                        "Content-Type":"application/json"},
            'body': {'name': 'dict_users'},
            'time': true
            });
        var userCreateResponse = await request('post', baseURI + '/dicts/dict_users/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'body': superuser,
                'time': true
            });
        newSuperUserID = userCreateResponse.body.id;
        userCreateResponse = await request('post', baseURI + '/dicts/dict_users/users', { 
                'headers': {"Accept":"application/vnd.wde.v2+json",
                            "Content-Type":"application/json"},
                'auth': superuserauth,
                'body': dictuser,
                'time': true
            });
        newDictUserID = userCreateResponse.body.id;               
        await request('post', baseURI + '/dicts', {
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': superuserauth,
                    'body': {"name": dictuser.table},
                    'time': true
            });
    });
    
    describe('tests for post', function() {        
        it('should respond 201 for "Created" for a profile', function() {
            var config = { 
                'body': {
                    "sid": "dictProfile",
                    "lemma": "",
                    "entry": compiledProfileTemplate({
                        'dictName': dictuser.table,
                        'displayString': '//tei:form/tei:orth[1]', 
                     })
                },
                'headers': { "Accept": "application/vnd.wde.v2+json" },
                'auth': dictuserauth,
                'time': true
            },
                response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', config);

            expect(response).to.have.status(201)
            expect(response).to.have.json(function(body){
                expect(body.id).to.equal('dictProfile');
                expect(body.type).to.equal('profile');
                expect(body.lemma).to.equal('  profile');
            })
            return chakram.wait()
        });

        // test if the adding of entries is possible also the validation is present now
        it('should respond 201 for "Created" for an entry', async function(){
            var config = { 
                'body': {
                    "sid": "dictProfile",
                    "lemma": "",
                    "entry": compiledProfileTemplate({
                        'dictName': dictuser.table,
                        'displayString': '//tei:form/tei:orth[1]', 
                     })
                },
                'headers': { "Accept": "application/vnd.wde.v2+json" },
                'auth': dictuserauth,
                'time': true
            },
            response = await request('post', baseURI + '/dicts/' + dictuser.table + '/entries', config),
            config = {
                'body' : {
                    "sid" : 'biyyah_001',
                    "lemma" : "",
                    "entry" : testEntryForValidation
                },
                'headers' : { "Accept" : "application/vnd.wde.v2+json", "Content-Type" : "application/json" },
                'auth' : dictuserauth,
                'time' : true 
            },
            response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', config);
            expect(response).to.have.status(201);
            expect(response).to.have.json(function(body){
                expect(body.id).to.equal('biyyah_001')
                expect(body.type).to.equal('entry')
            })
            return chakram.wait();
        });
        
        // xxit('should respond 400 for "Client Error"', function() {
        //     //there is no 400 psot error right now.
        // });


        it('should respond 401 for "Unauthorized"', function() {
            var response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', { 
                'body': {
                    "sid":"mollit nostrud adipisicing",
                    "lemma":"sunt sint",
                    "entry":"adipisicing sunt amet laborum"
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'time': true
            });

            expect(response).to.have.status(401);
            return chakram.wait();
        });


        it('should respond 403 for "Forbidden"', function() {
            var response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', { 
                'body': {
                    "sid":"magna in",
                    "lemma":"Duis",
                    "entry":"officia proident anim dolor"
                },
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': {'user': 'nonexisting', 'pass': 'nonsense'},
                'time': true
            });

            expect(response).to.have.status(403);
            return chakram.wait();
        });


        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', { 
                'body': {
                    "sid":"irure",
                    "lemma":"ut aliquip",
                    "entry":"id eiusmod est eu"
                },
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json('No function found that matches the request.')
            return chakram.wait();
        });


        it('should respond 415 for "Unsupported Media Type"', function() {
            var response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', {
                'json': false,
                'body': "ut deserunt voluptate",
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(415);
            return chakram.wait();
        });

        describe('should respond 422 for "Unprocessable Entity"', function() {
            it('if entry is not well formed XML"', function() {
                var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"dictProfile",
                        "lemma":"",
                        "entry": "<profile><tabeName></profile></tableName>"
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(422);
                return chakram.wait();
            });

            it('if an entry is no XML, just text', async function(){
                var response = request('post', baseURI + '/dicts/' + dictuser.table + '/entries', { 
                    'body': {"sid":"cillum Ut","lemma":"proident officia dolore","entry":"eu et ipsum"},
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth' : dictuserauth,
                    'time': true
                });
    
                expect(response).to.have.status(422);
                expect(response).to.have.json(function(body){
                    expect(body.detail).to.equal("Data consists only of text - no markup")
                });
                return chakram.wait();
            })

            it('if entry does not conform the schema"', async function() {
                var config = { 
                    'body': {
                        "sid": "dictProfile",
                        "lemma": "",
                        "entry": compiledProfileTemplate({
                            'dictName': dictuser.table,
                            'displayString': '//tei:form/tei:orth[1]', 
                         })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                },
                response = await request('post', baseURI + '/dicts/' + dictuser.table + '/entries', config),
                response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"biyyah_001",
                        "lemma":"",
                        "entry": testEntryForValidationWithError
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json","Content-Type" : "application/json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(422);
                expect(response).to.have.json(function(body){
                    expect(body.detail).to.contain('element "hom" not allowed anywhere')
                    expect(body.detail).to.contain('expected the element end-tag or element');
                    expect(body.detail).to.contain(', "entry"')
                })
                
                return chakram.wait();
            });
            
            it('if entry has no @xml:id"', function() {
                var response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', { 
                    'body': {
                        "sid":"dictProfile",
                        "lemma":"",
                        "entry": "<profile><tableName></tableName></profile>"
                    },
                    'headers': {"Accept":"application/vnd.wde.v2+json"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(422);
                return chakram.wait();
            });
        });
        afterEach('Remove the test profile', function(){
            return request('get', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': {'lock': 2},
                'auth': dictuserauth
            })
            .then(function(){
            return request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'auth': dictuserauth
            });
        });
        });
    });

    describe('tests for get', function() {
        describe('should respond 200 for "OK"', response200tests.curry(false));        
        describe('should respond 200 for "OK" (using cache)', response200tests.curry(true));
        function response200tests (useCache) {
            beforeEach('Add test data', create_test_data.curry(useCache));
            it('just get all entries (standard sorted by lemma ascending)', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("10")
                    expect(body._embedded.entries).to.have.length(10)
                    expect(body._embedded.entries[0].id).to.equal("dictProfile")
                    expect(body._embedded.entries[1].id).to.equal("test01")
                    expect(body._embedded.entries[1].lemma).to.equal("ṭēsṯ")
                    expect(body._embedded.entries[9].id).to.equal("test09")
                    expect(body._embedded.entries[9].lemma).to.equal("ṭēsṯ 9")
                });
                return chakram.wait();
            });

            it('get all entries with an alternate lemma', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"altLemma": "fa-Arab"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("10")
                    expect(body._embedded.entries).to.have.length(10)
                    expect(body._embedded.entries[0].id).to.equal("dictProfile")
                    expect(body._embedded.entries[1].id).to.equal("test01")
                    expect(body._embedded.entries[1].lemma).to.equal("تست")
                    expect(body._embedded.entries[9].id).to.equal("test09")
                    expect(body._embedded.entries[9].lemma).to.equal("تست 9")
                });
                return chakram.wait();
            });
            
            it('query using a stored template XQuery', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"q": "tei_all=ṭēsṯ"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("9")
                    expect(body._embedded.entries).to.have.length(9)
                    expect(body._embedded.entries[0].id).to.equal("test01")
                    expect(body._embedded.entries[0].lemma).to.equal("ṭēsṯ")
                    expect(body._links.self.href).to.contain("q=tei_all")
                    expect(body._links.first.href).to.contain("q=tei_all")
                    expect(body._links.last.href).to.contain("q=tei_all")
                });
                return chakram.wait();
            });
            
            it('filter by id', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"id": "test01"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("1")
                    expect(body._embedded.entries).to.have.length(1)
                    expect(body._embedded.entries[0].id).to.equal("test01")
                    expect(body._embedded.entries[0].lemma).to.equal("ṭēsṯ")
                    expect(body._links.self.href).to.contain("id=test01")
                    expect(body._links.first.href).to.contain("id=test01")
                    expect(body._links.last.href).to.contain("id=test01")
                });
                return chakram.wait();
            });

            // added T.K. start - Task 14954: More 404 tests needed for id parameters
            it('query for empty id - should response 404 "Not Found"', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"id": ""},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(404);
                return chakram.wait();
            });

            it('query for empty ids - should response 404 "Not Found"', function(){
                var response = request('get', baseURI + "/dicts/" + dictuser.table + "/entries", {
                    'headers' : {"Accept" : "application/vnd.wde.v2+json"},
                    'qs' : {"ids" : ""},
                    'auth' : dictuserauth,
                    'time' : true
                });

                expect(response).to.have.status(404);
                return chakram.wait();
            });
            
            it('filter by id that starts with something', async function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"id": "test*"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("9")
                    expect(body._embedded.entries).to.have.length(9)
                    expect(body._embedded.entries[0].id).to.equal("test01")
                    expect(body._embedded.entries[8].id).to.equal("test09")
                    expect(body._links.self.href).to.contain("id=test%2A")
                    expect(body._links.first.href).to.contain("id=test%2A")
                    expect(body._links.last.href).to.contain("id=test%2A")
                })
                await chakram.wait();
            });
                        
            it('filter by a comma separated list of ids', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"ids": "test01,dictProfile,test_does_not_exist"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("2")
                    expect(body._embedded.entries).to.have.length(2)
                    expect(body._embedded.entries[0].id).to.equal("dictProfile")
                    expect(body._embedded.entries[1].id).to.equal("test01")
                    expect(body._links.self.href).to.contain("ids=test01%2CdictProfile")
                    expect(body._links.first.href).to.contain("ids=test01%2CdictProfile")
                    expect(body._links.last.href).to.contain("ids=test01%2CdictProfile")
                });
                return chakram.wait();
            });
                        
            it('filter using an XQuery', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"q": "collection($__db__)//tei:entry/tei:form[@type='lemma']/tei:orth[text() contains text \"ṭēs.*\" using wildcards]"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(500);
                expect(response).to.have.json(function(body){
                    expect(body.type).to.equal("not_implemented")
                });
                return chakram.wait();
            });
            
            it('get all entries sorted by lemma descending', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"sort": "desc"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("10")
                    expect(body._embedded.entries).to.have.length(10)
                    expect(body._embedded.entries[0].id).to.equal("test09")
                    expect(body._embedded.entries[1].id).to.equal("test08")
                    expect(body._embedded.entries[1].lemma).to.equal("ṭēsṯ 8")
                    expect(body._embedded.entries[9].id).to.equal("dictProfile")
                    expect(body._embedded.entries[9].lemma).to.equal("  profile")
                });
                return chakram.wait();
            });

            it('get all entries sorted as inserted/document order', function () {
                var response = request('get', baseURI + '/dicts/' + dictuser.table + '/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': {"sort": "none"},
                    'auth': dictuserauth,
                    'time': true
                });

                expect(response).to.have.status(200);
                expect(response).to.have.json(function(body){
                    expect(body.total_items).to.equal("10")
                    expect(body._embedded.entries).to.have.length(10)
                    expect(body._embedded.entries[0].id).to.equal("dictProfile")
                    expect(body._embedded.entries[1].id).to.equal("test01")
                    expect(body._embedded.entries[1].lemma).to.equal("ṭēsṯ")
                    expect(body._embedded.entries[9].id).to.equal("test05")
                    expect(body._embedded.entries[9].lemma).to.equal("ṭēsṯ 5")
                });
                return chakram.wait();
            });
            afterEach('Remove test data', remove_test_data);
        }

        async function create_test_data(useCache) {
            // chakram.startDebug();
            var config = { 
                'body': {
                    "sid": "dictProfile",
                    "lemma": "",
                    "entry": compiledProfileTemplate({
                        'dictName': dictuser.table,                            
                        'mainLangLabel': 'fa-x-modDMG',     
                        'displayString': '//tei:form/tei:orth[@xml:lang = "{langid}"]',
                        'altDisplayString': {
                            'label': 'fa-Arab',
                            'displayString': '//tei:form/tei:orth[@xml:lang = "fa-Arab"]'
                        },
                        'useCache': useCache
                    })
                },
                'headers': { "Accept": "application/vnd.wde.v2+json" },
                'auth': dictuserauth,
                'time': true
            },
            response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);
    
            expect(response).to.have.status(201);
            await chakram.wait();
            response = request('get', baseURI+'/dicts/'+dictuser.table)
            
            expect(response).to.have.status(200);
            expect(response).to.have.json(function(body){
                expect(body._embedded._[0].queryTemplates).to.have.length(8);
                expect(body._embedded._[0].queryTemplates).to.include('tei_all');
            });
            await chakram.wait();

            config = { 
                'body': {
                    "sid": "test01",
                    "lemma": "",
                    "entry": compiledEntryTemplate({
                        'xmlID': 'test01',
                        'formFaArab': 'تست',
                        'formFaXModDMG': 'ṭēsṯ',
                        'translation_en': 'test',
                        'translation_de': 'Test',
                        })
                },
                'headers': { "Accept": "application/vnd.wde.v2+json" },
                'auth': dictuserauth,
                'time': true
            },
            response = request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);
    
            expect(response).to.have.status(201);
            await chakram.wait();
            response = request('get', baseURI+'/dicts/'+dictuser.table)
            
            expect(response).to.have.status(200);
            expect(response).to.have.json(function(body){
                expect(body._embedded._[0].dbNames).to.have.length(1);
                expect(body._embedded._[0].dbNames).to.include(dictuser.table);
            });
            await chakram.wait();
            for (let i = 2; i < 5; i++) {
                config = { 
                    'body': {
                        "sid": "test0" + i,
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': 'test0' + i,
                            'formFaArab': 'تست ' + i,
                            'formFaXModDMG': 'ṭēsṯ ' + i,
                            'translation_en': 'test' + i,
                            'translation_de': 'Test' + i,
                            })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                },
                await request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);
            }
            for (let i = 9; i > 4; i--) {
                config = { 
                    'body': {
                        "sid": "test0" + i,
                        "lemma": "",
                        "entry": compiledEntryTemplate({
                            'xmlID': 'test0' + i,
                            'formFaArab': 'تست ' + i,
                            'formFaXModDMG': 'ṭēsṯ ' + i,
                            'translation_en': 'test' + i,
                            'translation_de': 'Test' + i,
                            })
                    },
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth,
                    'time': true
                },
                await request('post', baseURI+'/dicts/'+dictuser.table+'/entries', config);
            }
            //chakram.startDebug();
        }
    
        async function remove_test_data() {
            // chakram.stopDebug();
            for (let i = 1; i < 10; i++) {
                await request('get', baseURI + '/dicts/' + dictuser.table + '/entries/test0' + i, {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'qs': { 'lock': 2 },
                    'auth': dictuserauth
                });
            }
            for (let i = 1; i < 10; i++) {
                await request('delete', baseURI + '/dicts/' + dictuser.table + '/entries/test0' + i, {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': dictuserauth
                });
            }
            // especially using cache needs a bit of time to finish removing all the database files.
            // if no pause is here there are 500 errors complaining about renaming if xxx.cache.0
            await later(300);
        }

        it('should respond 400 for useless "filter"', function() {
            var response = request('get', baseURI+'/dicts/' + dictuser.table + '/entries', { 
                'headers': {"Accept":"application/vnd.wde.v2+json"},
                'qs': { id: '*' },
                'auth': dictuserauth,
                'time': true
            });

            expect(response).to.have.status(400)
            expect(response).to.have.json(function(body){
                expect(body.detail).to.equal("id=* is no useful filter")
            });
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

        describe('should respond 403 for "Forbidden"', function() {
            beforeEach('Create test data', create_test_data.curry(false));
            it('on wrong username and password', function () {
                var response = request('get', baseURI + '/dicts/doin/entries', {
                    'headers': { "Accept": "application/vnd.wde.v2+json" },
                    'auth': { 'user': 'nonexisting', 'pass': 'nonsense' },
                    'time': true
                });

                expect(response).to.have.status(403);
                return chakram.wait();
            });

            it('on using a query not stored in a template without authentication', function () {
                var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries', {
                    'headers': { "Accept": "application/json" },
                    'qs': {"q": "//someelement"},
                    'time': true
                });

                expect(response).to.have.status(403);
                return chakram.wait();                
            });
            
            it('on using a sort not one of "asc", "desc" or "none" without authentication', function () {
                var response = request('get', baseURI + '/dicts/'+dictuser.table+'/entries', {
                    'headers': { "Accept": "application/json" },
                    'qs': {"sort": "//someelement"},
                    'time': true
                });

                expect(response).to.have.status(403);
                return chakram.wait();                
            });
            afterEach('Remove test data', remove_test_data);
        });

        it('should respond 404 "No function found that matches the request." for wrong accept', function() {
            var response = request('get', baseURI + '/dicts/inmollit/entries', { 
                'headers': {"Accept":"application/vnd.wde.v8+json"},
                'time': true
            });

            expect(response).to.have.status(404);
            expect(response).to.have.json('No function found that matches the request.')
            return chakram.wait();
        });
    
    });
    
    // Perhaps not needed at all: Warnung! Dangerous! Deletes every entry except the system entries < 699 from the dictionary.
    // describe('tests for delete', function() {
    //     it('should respond 204 for "No Content"', function() {
    //         var response = request('delete', baseURI+'/dicts/pariatur/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(204);
    //         return chakram.wait();
    //     });


    //     it('should respond 401 for "Unauthorized"', function() {
    //         var response = request('delete', baseURI+'/dicts/irureinfugiatculpaelit/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(401);
    //         return chakram.wait();
    //     });


    //     it('should respond 403 for "Forbidden"', function() {
    //         var response = request('delete', baseURI+'/dicts/quisconsequatveniamametlaborum/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(403);
    //         return chakram.wait();
    //     });


    //     it('should respond 406 for "Not Acceptable"', function() {
    //         var response = request('delete', baseURI+'/dicts/velit/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(406);
    //         return chakram.wait();
    //     });


    //     it('should respond 415 for "Unsupported Media Type"', function() {
    //         var response = request('delete', baseURI+'/dicts/autenonnulla/entries', { 
    //             'headers': {"Accept":"application/vnd.wde.v2+json"},
    //             'time': true
    //         });

    //         expect(response).to.have.status(415);
    //         return chakram.wait();
    //     });
    
    // });
    
    xdescribe('tests for patch', function() {
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
    afterEach(async function(){
        await request('delete', baseURI + '/dicts/' + dictuser.table, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': dictuserauth,
            'time': true
        })
        await request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
        await request('delete', baseURI + '/dicts/dict_users', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
    });
});
}