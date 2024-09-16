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
      compiledFileTemplate;

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
        useCache: true,
      });
      expect(testProfileTemplate).to.contain("<tableName>replaced</tableName>");
      expect(testProfileTemplate).to.contain(
        "displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<"
      );
      expect(testProfileTemplate).to.contain(
        'altDisplayString label="test">//mds:titleInfo/mds:title<'
      );
      expect(testProfileTemplate).to.contain("mainLangLabel>aNCName<");
      expect(testProfileTemplate).to.contain("useCache/>");
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

    beforeEach(async function () {
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
      // newDictUserID = userCreateResponse.body.id;
      await request("post", baseURI + "/dicts", {
        headers: { Accept: "application/vnd.wde.v2+json" },
        auth: superuserauth,
        body: { name: dictuser.table },
        time: true,
      });
    });

    describe("tests for get", function () {
      it('should respond 200 for "OK"', async function () {
        var response = await request(
          "get",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            headers: { Accept: "application/vnd.wde.v2+json" },
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

      it('should respond 403 for "Forbidden"', async function () {
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

      it('should respond 406 for "Not Acceptable"', async function () {
        var response = await request(
          "get",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(406);
        await chakram.wait();
      });

      it('should respond 415 for "Unsupported Media Type"', async function () {
        var response = await request(
          "get",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(415);
        await chakram.wait();
      });
    });

    describe("tests for post", () => {
      it('should respond 201 for "Created"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: {
              filename: "Excepteur mollit culpa Ut",
              content: "esse veniam proident enim",
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(201);
        await chakram.wait();
      });

      it('should respond 400 for "Client Error"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: {
              filename: "occaecat nulla culpa minim",
              content: "reprehenderit dolore in anim",
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(400);
        await chakram.wait();
      });

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
            time: true,
          }
        );

        expect(response).to.have.status(403);
        await chakram.wait();
      });

      it('should respond 406 for "Not Acceptable"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: {
              filename: "nostrud sed dolor",
              content: "ullamco proident sed dolor ut",
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(406);
        await chakram.wait();
      });

      it('should respond 415 for "Unsupported Media Type"', async function () {
        var response = await request(
          "post",
          baseURI + "/dicts/" + dictuser.table + "/files",
          {
            body: {
              filename: "anim quis aliqua",
              content: "aliqua nulla exercitation",
            },
            headers: { Accept: "application/vnd.wde.v2+json" },
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
            time: true,
          }
        );

        expect(response).to.have.status(422);
        await chakram.wait();
      });
    });

    afterEach("Remove the test profile", function () {
      return request(
        "get",
        baseURI + "/dicts/" + dictuser.table + "/entries/dictProfile",
        {
          headers: { Accept: "application/vnd.wde.v2+json" },
          qs: { lock: 2 },
          auth: dictuserauth,
        }
      ).then(function () {
        return request(
          "delete",
          baseURI + "/dicts/" + dictuser.table + "/entries/dictProfile",
          {
            headers: { Accept: "application/vnd.wde.v2+json" },
            auth: dictuserauth,
          }
        );
      });
    });
  });
};
