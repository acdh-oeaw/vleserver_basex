"use strict";
const mocha = require("mocha");
const chakram = require("chakram");
const request = chakram.request;
const expect = chakram.expect;
const fs = require("fs");
const Handlebars = require("handlebars");

require("./utilSetup");

module.exports = function (baseURI, basexAdminUser, basexAdminPW) {
  describe("tests for /dicts/{dict_name}/files/{file_name}", () => {
    var superuser = {
        id: "",
        userID: basexAdminUser,
        pw: basexAdminPW,
        read: "y",
        write: "y",
        writeown: "n",
        table: "dict_users",
      },
      superuserauth = { user: superuser.userID, pass: superuser.pw },
      dictuser = {
        // a superuser for the test table
        id: "",
        userID: "testUser0",
        pw: "PassW0rd",
        read: "y",
        write: "y",
        writeown: "n",
        table: "aliqua",
      },
      dictuserauth = { user: dictuser.userID, pass: dictuser.pw },
      compiledProfileTemplate,
      compiledFileTemplate,
      newDictUserID;
      
      before("Read templated test data", function () {
        var testProfileTemplate = fs.readFileSync(
          "test/fixtures/testProfile.xml",
          "utf8"
        );
        expect(testProfileTemplate).to.contain(
          "<tableName>{{dictName}}</tableName>"
        );
        expect(testProfileTemplate).to.contain(
          "<displayString>{{displayString}}</displayString>"
        );
        compiledProfileTemplate = Handlebars.compile(testProfileTemplate);
        testProfileTemplate = compiledProfileTemplate({
          dictName: "replaced",
          mainLangLabel: "aNCName",
          displayString:
            "{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}",
          altDisplayString: {
            label: "test",
            displayString: "//mds:titleInfo/mds:title",
          },
          useCache: false,
        });
        expect(testProfileTemplate).to.contain("<tableName>replaced</tableName>");
        expect(testProfileTemplate).to.contain(
          "displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<"
        );
        expect(testProfileTemplate).to.contain(
          'altDisplayString label="test">//mds:titleInfo/mds:title<'
        );
        expect(testProfileTemplate).to.contain("mainLangLabel>aNCName<");
        var testFileTemplate = fs.readFileSync(
          "test/fixtures/testFile.xml",
          "utf8"
        );
        expect(testFileTemplate).to.contain('"http://www.tei-c.org/ns/1.0"');
        expect(testFileTemplate).to.contain('xml:id="{{xmlIDentry1}}"');
        expect(testFileTemplate).to.contain(">{{translation_en}}<");
        expect(testFileTemplate).to.contain(">{{translation_de}}<");
        compiledFileTemplate = Handlebars.compile(testFileTemplate);
        testFileTemplate = compiledFileTemplate({
          xmlIDentry1: "testID",
          formFaArab: "تست",
          formFaXModDMG: "ṭēsṯ",
          translation_en: "test",
          translation_de: "Test",
          formFaXModDMG3: "example transcribed",
          translation_en3: "example translated",
          translation_de3: "Beispiel übersetzt",
        });
        expect(testFileTemplate).to.contain('xml:id="testID"');
        expect(testFileTemplate).to.contain(">test<");
        expect(testFileTemplate).to.contain(">Test<");
        expect(testFileTemplate).to.contain(">تست<");
        expect(testFileTemplate).to.contain(">ṭēsṯ<");
        expect(testFileTemplate).to.contain(">example transcribed<");
        expect(testFileTemplate).to.contain(">example translated<");
        expect(testFileTemplate).to.contain(">Beispiel übersetzt<");
      });
  
      beforeEach(async () => {
        await request("post", baseURI + "/dicts", {
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
          },
          body: { name: "dict_users" },
          time: true,
        });
        var userCreateResponse = await request(
          "post",
          baseURI + "/dicts/dict_users/users",
          {
            headers: {
              Accept: "application/vnd.wde.v2+json",
              "Content-Type": "application/json",
            },
            body: superuser,
            time: true,
          }
        );
        // newSuperUserID = userCreateResponse.body.id;
        userCreateResponse = await request(
          "post",
          baseURI + "/dicts/dict_users/users",
          {
            headers: {
              Accept: "application/vnd.wde.v2+json",
              "Content-Type": "application/json",
            },
            auth: superuserauth,
            body: dictuser,
            time: true,
          }
        );
        newDictUserID = userCreateResponse.body.id;
        let response = await request("post", baseURI + "/dicts", {
          headers: { Accept: "application/vnd.wde.v2+json" },
          auth: superuserauth,
          body: { name: dictuser.table },
          time: true,
        });
        expect(response).to.have.status(201);
  
        let config = {
            body: {
              sid: "dictProfile",
              lemma: "",
              entry: compiledProfileTemplate({
                dictName: dictuser.table,
                mainLangLabel: "fa-x-modDMG",
                displayString: '//tei:form/tei:orth[@xml:lang = "{langid}"]',
                altDisplayString: {
                  label: "fa-Arab",
                  displayString: '//tei:form/tei:orth[@xml:lang = "fa-Arab"]',
                },
                useCache: false,
              }),
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
            auth: dictuserauth,
            time: true,
        }
        
        response = await request('get', baseURI + '/dicts/'+dictuser.table+'/entries/dictProfile', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'qs': {'lock': 2},
            'auth': dictuserauth,                    
        })
        expect(response).to.have.status(200);
  
        response = await request(
          "put",
          baseURI + "/dicts/" + dictuser.table + "/entries/dictProfile",
          config
        );
  
        expect(response).to.have.status(200);
        await chakram.wait();
      });

    describe("tests for get", () => {
      it('should respond 200 for "OK"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/aliqua/files/aliqua.xml",
          {
            headers: { Accept: "application/xml" },
            time: true,
          }
        );

        expect(response).to.have.status(200);
        await chakram.wait();
      });

      it('should respond 401 for "Unauthorized"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/aliqua/files/aliqua.xml",
          {
            qs: { lock: "" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(401);
        await chakram.wait();
      });

      it('should respond 403 for "Forbidden"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/aliqua/files/aliqua.xml",
          {
            qs: { lock: "367699" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(403);
        await chakram.wait();
      });

      it('should respond 404 for "Not Found"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/aliqua/files/euetpariaturofficiaculpa.xml",
          {
            qs: { lock: "8539126661" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(404);
        await chakram.wait();
      });

      it('should respond 406 for "Not Acceptable"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/aliqua/files/aliqua.xml",
          {
            qs: { lock: "1728143477" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(406);
        await chakram.wait();
      });
    });

    afterEach("Remove the test profile", async () => {
        let 
        response = await request('get', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
            'headers': {"Accept":"application/vnd.wde.v2+json"},
            'qs': {'lock': 2},
            'auth': dictuserauth
        })
        response = await request('delete', baseURI+'/dicts/'+dictuser.table+'/entries/dictProfile', {
            'headers': {"Accept":"application/vnd.wde.v2+json"},
            'auth': dictuserauth
        });
        response = await request('delete', baseURI + '/dicts/' + dictuser.table, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': dictuserauth,
            'time': true
        })
        response = await request('delete', baseURI + '/dicts/dict_users/users/' + newDictUserID, {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
        response = await request('delete', baseURI + '/dicts/dict_users', {
            'headers': { "Accept": "application/vnd.wde.v2+json" },
            'auth': superuserauth,
            'time': true
        });
    });
  });
};
