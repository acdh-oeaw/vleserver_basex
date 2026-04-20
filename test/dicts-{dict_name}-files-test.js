"use strict";
const mocha = require("mocha");
const chakram = require("chakram");
const request = chakram.request;
const expect = chakram.expect;
const fs = require("fs");
const Handlebars = require("handlebars");

require("./utilSetup");

module.exports = function (baseURI, basexAdminUser, basexAdminPW) {
  describe("tests for /dicts/{dict_name}/files", function () {
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
      response = await request("post", baseURI + "/dicts", {
        headers: { Accept: "application/vnd.wde.v2+json" },
        auth: superuserauth,
        body: { name: dictuser.table },
        time: true,
      });
      expect(response).to.have.status(201);

      var config = {
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
        },
        response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/entries",
          config
        );

      expect(response).to.have.status(201);
      await chakram.wait();
    });

    describe("tests for get", function () {
      beforeEach(async () => {
        let config = {
          body: {
            fileName: "test.xml",
            xmlData: compiledFileTemplate({
              xmlIDentry1: "testID",
              xmlIDentry2: "testID2",
              xmlIDcit3: "testID3",
              formFaArab: "تست",
              formFaXModDMG: "ṭēsṯ",
              translation_en: "test",
              translation_de: "Test",
              formFaXModDMG2: "ṭēsṯ",
              translation_en2: "test2",
              translation_de2: "Test2",
              formFaXModDMG3: "example transcribed",
              translation_en3: "example translated",
              translation_de3: "Beispiel übersetzt",            
            })
          },
          headers: { Accept: "application/vnd.wde.v2+json" },
          auth: dictuserauth,
          time: true,
        },
        response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          config
        );
        expect(response).to.have.status(201);
      });
      it('should respond 200 for "OK"', async function () {
        var response = await request(
          "get",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            time: true,
          }
        );

        expect(response).to.have.status(200);
        await chakram.wait();
      });

      it('should respond 401 for "Unauthorized"', async function () {
        var response = await request(
          "get",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(401);
        await chakram.wait();
      });

      xit('should respond 403 for "Forbidden"', async function () {
        var response = await request(
          "get",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(403);
        await chakram.wait();
      });
    });

    describe("tests for post", () => {
      it('should respond 201 for "Created"', async function () {
        let config = {
          body: {
            fileName: "test.xml",
            xmlData: compiledFileTemplate({
              xmlIDentry1: "testID",
              xmlIDentry2: "testID2",
              xmlIDcit3: "testID3",
              formFaArab: "تست",
              formFaXModDMG: "ṭēsṯ",
              translation_en: "test",
              translation_de: "Test",
              formFaXModDMG2: "ṭēsṯ",
              translation_en2: "test2",
              translation_de2: "Test2",
              formFaXModDMG3: "example transcribed",
              translation_en3: "example translated",
              translation_de3: "Beispiel übersetzt",            
            })
          },
          headers: { Accept: "application/vnd.wde.v2+json" },
          auth: dictuserauth,
          time: true,
        },
        response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          config
        );

        expect(response).to.have.status(201);
        await chakram.wait();
      });

      // xit('should respond 400 for "Client Error"', function() {
      //     //there is no 400 psot error right now.
      // });

      it('should respond 401 for "Unauthorized"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: { filename: "nostrud fugiat eiusmod et", content: "nostrud" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(401);
        await chakram.wait();
      });

      it('should respond 403 for "Forbidden"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: {
              filename: "minim dolor ut Excepteur",
              content: "in incididunt sit ea ipsum",
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
            auth: {user: 'nonexisting', pass: 'nonsense'},
            time: true,
          }
        );

        expect(response).to.have.status(403);
        await chakram.wait();
      });

      it('should respond 415 for "Unsupported Media Type"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            json: false,
            body: "aliqua nulla exercitation",
            headers: { Accept: "application/vnd.wde.v2+json" },
            auth: dictuserauth,
            time: true,
          }
        );

        expect(response).to.have.status(415);
        await chakram.wait();
      });

      it('should respond 422 for "Unprocessable Entity"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: {
              filename: "elit",
              content: "exercitation anim ut ipsum tempor",
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
            auth: dictuserauth,
            time: true,
          }
        );

        expect(response).to.have.status(422);
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
