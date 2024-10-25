import {
  describe,
  it,
  beforeAll,
  beforeEach,
  afterEach,
  expect,
} from "vitest";
import fetch from "node-fetch-native";
import fs from "fs";
import Handlebars from "handlebars";

import { safeJSONParse, later } from './utilSetup';

export default function (baseURI, basexAdminUser, basexAdminPW) {
  describe("tests for /dicts/{dict_name}/entries", () => {
    var superuser = {
        id: "",
        userID: basexAdminUser,
        pw: basexAdminPW,
        read: "y",
        write: "y",
        writeown: "n",
        table: "dict_users",
      },
      superuserauth = { username: superuser.userID, password: superuser.pw },
      newSuperUserID,
      dictuser = {
        // a superuser for the test table
        id: "",
        userID: "testUser0",
        pw: "PassW0rd",
        read: "y",
        write: "y",
        writeown: "n",
        table: "nostrudsedeaincididunt",
      },
      dictuserauth = { username: dictuser.userID, password: dictuser.pw },
      newDictUserID,
      compiledProfileTemplate,
      compiledEntryTemplate,
      compiledProfileWithSchemaTemplate,
      testEntryForValidation,
      testEntryForValidationWithError;

    beforeAll(function () {
      var testProfileTemplate = fs.readFileSync(
        "test/fixtures/testProfile.xml",
        "utf8"
      );
      expect(testProfileTemplate).toContain(
        "<tableName>{{dictName}}</tableName>"
      );
      expect(testProfileTemplate).toContain(
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
      expect(testProfileTemplate).toContain("<tableName>replaced</tableName>");
      expect(testProfileTemplate).toContain(
        "displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<"
      );
      expect(testProfileTemplate).toContain(
        'altDisplayString label="test">//mds:titleInfo/mds:title<'
      );
      expect(testProfileTemplate).toContain("mainLangLabel>aNCName<");
      expect(testProfileTemplate).toContain("useCache/>");
      var testEntryTemplate = fs.readFileSync(
        "test/fixtures/testEntry.xml",
        "utf8"
      );
      expect(testEntryTemplate).toContain('"http://www.tei-c.org/ns/1.0"');
      expect(testEntryTemplate).toContain('xml:id="{{xmlID}}"');
      expect(testEntryTemplate).toContain(">{{translation_en}}<");
      expect(testEntryTemplate).toContain(">{{translation_de}}<");
      compiledEntryTemplate = Handlebars.compile(testEntryTemplate);
      testEntryTemplate = compiledEntryTemplate({
        xmlID: "testID",
        formFaArab: "تست",
        formFaXModDMG: "ṭēsṯ",
        translation_en: "test",
        translation_de: "Test",
      });
      expect(testEntryTemplate).toContain('xml:id="testID"');
      expect(testEntryTemplate).toContain(">test<");
      expect(testEntryTemplate).toContain(">Test<");
      expect(testEntryTemplate).toContain(">تست<");
      expect(testEntryTemplate).toContain(">ṭēsṯ<");
      // data for testing server side validation
      var testProfileWithSchemaTemplate = fs.readFileSync(
        "test/fixtures/testProfileWithSchema.xml",
        "utf8"
      );
      expect(testProfileWithSchemaTemplate).toContain(
        "<tableName>{{dictname}}</tableName>"
      );
      compiledProfileWithSchemaTemplate = Handlebars.compile(
        testProfileWithSchemaTemplate
      );
      testEntryForValidation = fs.readFileSync(
        "test/fixtures/testEntryForValidation.xml",
        "utf8"
      );
      expect(testEntryForValidation).toContain('xml:id="biyyah_001"');
      testEntryForValidationWithError = fs.readFileSync(
        "test/fixtures/testEntryForValidationWithError.xml",
        "utf8"
      );
      expect(testEntryForValidationWithError).toContain(
        '<hom id="error-entry-1" xml:lang="de">'
      );
    });
    beforeEach(async function () {
      let response = await fetch(baseURI + "/dicts", {
        method: "POST",
        headers: {
          Accept: "application/vnd.wde.v2+json",
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ name: "dict_users" }),
      });
      expect(response.status).toBe(201);
      let userCreateResponse = await fetch(
        baseURI + "/dicts/dict_users/users",
        {
          method: "POST",
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
          },
          body: JSON.stringify(superuser),
        }
      );
      expect(userCreateResponse.status).toBe(200);
      newSuperUserID = (await userCreateResponse.json()).id;
      userCreateResponse = await fetch(baseURI + "/dicts/dict_users/users", {
        method: "POST",
        headers: {
          Accept: "application/vnd.wde.v2+json",
          "Content-Type": "application/json",
          Authorization:
            "Basic " +
            btoa(superuserauth.username + ":" + superuserauth.password),
        },
        body: JSON.stringify(dictuser),
        auth: superuserauth,
      });
      expect(userCreateResponse.status).toBe(200);
      newDictUserID = (await userCreateResponse.json()).id;
      response = await fetch(baseURI + "/dicts", {
        method: "POST",
        headers: {
          Accept: "application/vnd.wde.v2+json",
          "Content-Type": "application/json",
          Authorization:
            "Basic " +
            btoa(superuserauth.username + ":" + superuserauth.password),
        },
        body: JSON.stringify({ name: dictuser.table }),
      });
      expect(response.status).toBe(201);
    });

    describe("tests for post", function () {
      it('should respond 201 for "Created" for a profile', async function () {
        var config = {
          body: JSON.stringify({
            sid: "dictProfile",
            lemma: "",
            entry: compiledProfileTemplate({
              dictName: dictuser.table,
              displayString: "//tei:form/tei:orth[1]",
            }),
          }),
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
            Authorization:
              "Basic " +
              btoa(dictuserauth.username + ":" + dictuserauth.password),
          },
        };
        const response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            ...config,
          }
        );

        expect(response.status).toBe(201);
        const body = await response.json();
        expect(body.id).toBe("dictProfile");
        expect(body.type).toBe("profile");
        expect(body.lemma).toBe("  profile");
      });

      // test if the adding of entries is possible also the validation is present now
      it('should respond 201 for "Created" for an entry', async function () {
        var config = {
          body: JSON.stringify({
            sid: "dictProfile",
            lemma: "",
            entry: compiledProfileTemplate({
              dictName: dictuser.table,
              displayString: "//tei:form/tei:orth[1]",
            }),
          }),
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
            Authorization:
              "Basic " +
              btoa(dictuserauth.username + ":" + dictuserauth.password),
          },
        };
        let response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            ...config,
          }
        );

        expect(response.status).toBe(201);

        config = {
          body: JSON.stringify({
            sid: "biyyah_001",
            lemma: "",
            entry: testEntryForValidation,
          }),
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
            Authorization:
              "Basic " +
              btoa(dictuserauth.username + ":" + dictuserauth.password),
          },
        };
        response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            ...config,
          }
        );

        expect(response.status).toBe(201);
        const body = await response.json();
        expect(body).toBeDefined();
      });

      it('should respond 201 for "Created" for an entry with owner and status set', async () => {
        var config = {
          body: JSON.stringify({
            sid: "dictProfile",
            lemma: "",
            entry: compiledProfileTemplate({
              dictName: dictuser.table,
              displayString: "//tei:form/tei:orth[1]",
            }),
          }),
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
            Authorization:
              "Basic " +
              btoa(dictuserauth.username + ":" + dictuserauth.password),
          },
        };
        let response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            ...config,
          }
        );

        expect(response.status).toBe(201);

        config = {
          body: JSON.stringify({
            sid: "biyyah_001",
            lemma: "",
            entry: testEntryForValidation,
            owner: dictuser.userID,
            status: "unreleased",
          }),
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
            Authorization:
              "Basic " +
              btoa(dictuserauth.username + ":" + dictuserauth.password),
          },
        };
        response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            ...config,
          }
        );

        expect(response.status).toBe(201);
        const body = await response.json();
        expect(body.id).toBe("biyyah_001");
        expect(body.type).toBe("entry");
        expect(body.owner).toBe(dictuser.userID);
        expect(body.status).toBe("unreleased");
      });

      // xit('should respond 400 for "Client Error"', function() {
      //     //there is no 400 psot error right now.
      // });

      it('should respond 401 for "Unauthorized"', async function () {
        const response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            body: JSON.stringify({
              sid: "mollit nostrud adipisicing",
              lemma: "sunt sint",
              entry: "adipisicing sunt amet laborum",
            }),
            headers: { Accept: "application/vnd.wde.v2+json" },
          }
        );

        expect(response.status).toBe(401);
      });

      it('should respond 403 for "Forbidden"', async function () {
        const response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            body: JSON.stringify({
              sid: "magna in",
              lemma: "Duis",
              entry: "officia proident anim dolor",
            }),
            headers: {
              Accept: "application/vnd.wde.v2+json",
              "Content-Type": "application/json",
              Authorization: "Basic " + btoa("nonexisting:nonsense"),
            },
          }
        );

        expect(response.status).toBe(403);
      });

      it('should respond 404 "No function found that matches the request." for wrong accept', async function () {
        const response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            body: JSON.stringify({
              sid: "irure",
              lemma: "ut aliquip",
              entry: "id eiusmod est eu",
            }),
            headers: { Accept: "application/vnd.wde.v8+json" },
            auth: dictuserauth,
          }
        );

        expect(response.status).toBe(404);
        const value = await response.text();
        expect(
          value === "No function found that matches the request." ||
            value === "Service not found."
        ).toBe(true);
      });

      it('should respond 415 for "Unsupported Media Type"', async function () {
        const response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            json: false,
            body: "ut deserunt voluptate",
            headers: {
              Accept: "application/vnd.wde.v2+json",
              Authorization:
                "Basic " +
                btoa(dictuserauth.username + ":" + dictuserauth.password),
            },
          }
        );

        expect(response.status).toBe(415);
      });

      describe('should respond 422 for "Unprocessable Entity"', function () {
        it('if entry is not well formed XML"', async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries",
            {
              method: "POST",
              body: JSON.stringify({
                sid: "dictProfile",
                lemma: "",
                entry: "<profile><tabeName></profile></tableName>",
              }),
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
                "Content-Type": "application/json",
              },
            }
          );

          const body = await response.text(),
          jsonBody = safeJSONParse(body);
          expect(response.status).toBe(422);
        });

        it("if an entry is no XML, just text", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries",
            {
              method: "POST",
              body: JSON.stringify({
                sid: "cillum Ut",
                lemma: "proident officia dolore",
                entry: "eu et ipsum",
              }),
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
                  "Content-Type": "application/json",
              },
            }
          );

          expect(response.status).toBe(422);
          const body = await response.json();
          expect(body.detail).toBe("Data consists only of text - no markup");
        });

        it('if entry has no @xml:id"', async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries",
            {
              method: "POST",
              body: JSON.stringify({
                sid: "dictProfile",
                lemma: "",
                entry: "<profile><tableName></tableName></profile>",
              }),
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
                  "Content-Type": "application/json",
              },
            }
          );

          expect(response.status).toBe(422);
        });
      });

      afterEach(async () => {
        let response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries/dictProfile?lock=2",
          {
            method: "GET",
            headers: {
              Accept: "application/vnd.wde.v2+json",
              Authorization:
                "Basic " +
                btoa(dictuserauth.username + ":" + dictuserauth.password),
            },
          }
        );
        if (response.status === 404) return
        expect(response.status).toBe(200);
        response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries/dictProfile",
          {
            method: "DELETE",
            headers: {
              Accept: "application/vnd.wde.v2+json",
              Authorization:
                "Basic " +
                btoa(dictuserauth.username + ":" + dictuserauth.password),
            },
          }
        );
        const body = await response.text(),
              jsonBody = safeJSONParse(body);
        expect(response.status).toBe(204);
      });
    });

    describe("tests for get", function () {
      describe('should respond 200 for "OK"', response200tests.curry(false));
      describe(
        'should respond 200 for "OK" (using cache)',
        response200tests.curry(true)
      );
      function response200tests(useCache) {
        beforeEach(create_test_data.curry(useCache));
        it("just get all entries (standard sorted by lemma ascending)", async () => {
          let response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries",
            {
              method: "GET",
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
              },
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("10");
          expect(body._embedded.entries).to.have.length(10);
          expect(body._embedded.entries[0].id).toBe("dictProfile");
          expect(body._embedded.entries[1].id).toBe("test01");
          expect(body._embedded.entries[1].lemma).toBe("ṭēsṯ");
          expect(body._embedded.entries[9].id).toBe("test09");
          expect(body._embedded.entries[9].lemma).toBe("ṭēsṯ 9");
        });

        it("get all entries with an alternate lemma", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?altLemma=fa-Arab",
            {
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
              },
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("10");
          expect(body._embedded.entries).to.have.length(10);
          expect(body._embedded.entries[0].id).toBe("dictProfile");
          expect(body._embedded.entries[1].id).toBe("test01");
          expect(body._embedded.entries[1].lemma).toBe("تست");
          expect(body._embedded.entries[9].id).toBe("test09");
          expect(body._embedded.entries[9].lemma).toBe("تست 9");
        });

        it("query using a stored template XQuery", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?q=tei_all=ṭēsṯ",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );

          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("9");
          expect(body._embedded.entries.length).toBe(9);
          expect(body._embedded.entries[0].id).toBe("test01");
          expect(body._embedded.entries[0].lemma).toBe("ṭēsṯ");
          expect(body._links.self.href).toContain("q=tei_all");
          expect(body._links.first.href).toContain("q=tei_all");
          expect(body._links.last.href).toContain("q=tei_all");
        });

        it("filter by id", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?id=test01",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("1");
          expect(body._embedded.entries.length).toBe(1);
          expect(body._embedded.entries[0].id).toBe("test01");
          expect(body._embedded.entries[0].lemma).toBe("ṭēsṯ");
          expect(body._links.self.href).toContain("id=test01");
          expect(body._links.first.href).toContain("id=test01");
          expect(body._links.last.href).toContain("id=test01");
        });

        // added T.K. start - Task 14954: More 404 tests needed for id parameters
        it('query for empty id - should response 404 "Not Found"', async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?id=",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );

          expect(response.status).toBe(404);
        });

        it('query for empty ids - should response 404 "Not Found"', async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?ids=",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );

          expect(response.status).toBe(404);
        });

        it("filter by id that starts with something", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?id=test*",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("9");
          expect(body._embedded.entries).to.have.length(9);
          expect(body._embedded.entries[0].id).toBe("test01");
          expect(body._embedded.entries[8].id).toBe("test09");
          expect(body._links.self.href).toContain("id=test%2A");
          expect(body._links.first.href).toContain("id=test%2A");
          expect(body._links.last.href).toContain("id=test%2A");
        });

        it("filter by a comma separated list of ids", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?ids=test01,dictProfile,test_does_not_exist",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("2");
          expect(body._embedded.entries).to.have.length(2);
          expect(body._embedded.entries[0].id).toBe("dictProfile");
          expect(body._embedded.entries[1].id).toBe("test01");
          expect(body._links.self.href).toContain("ids=test01%2CdictProfile");
          expect(body._links.first.href).toContain("ids=test01%2CdictProfile");
          expect(body._links.last.href).toContain("ids=test01%2CdictProfile");
        });

        it("filter using an XQuery", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?q=collection($__db__)//tei:entry/tei:form[@type='lemma']/tei:orth[text() contains text \"ṭēs.*\" using wildcards]",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
              Authorization:
                "Basic " +
                btoa(dictuserauth.username + ":" + dictuserauth.password),},

            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(500);
          expect(body.type).toBe("not_implemented");
        });

        it("get all entries sorted by lemma descending", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?sort=desc",
            {
              headers: { Accept: "application/vnd.wde.v2+json", 
              Authorization:
                "Basic " +
                btoa(dictuserauth.username + ":" + dictuserauth.password),},
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("10");
          expect(body._embedded.entries).to.have.length(10);
          expect(body._embedded.entries[0].id).toBe("test09");
          expect(body._embedded.entries[1].id).toBe("test08");
          expect(body._embedded.entries[1].lemma).toBe("ṭēsṯ 8");
          expect(body._embedded.entries[9].id).toBe("dictProfile");
          expect(body._embedded.entries[9].lemma).toBe("  profile");
        });

        it("get all entries sorted as inserted/document order", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?sort=none",
            {
              headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password), }
            }
          );
          
          const bodyText = await response.text(),
                body = safeJSONParse(bodyText);
          expect(response.status).toBe(200);
          expect(body.total_items).toBe("10");
          expect(body._embedded.entries).to.have.length(10);
          expect(body._embedded.entries[0].id).toBe("dictProfile");
          expect(body._embedded.entries[1].id).toBe("test01");
          expect(body._embedded.entries[1].lemma).toBe("ṭēsṯ");
          expect(body._embedded.entries[9].id).toBe("test09");
          expect(body._embedded.entries[9].lemma).toBe("ṭēsṯ 9");
        });
        afterEach(remove_test_data);
      }

      it('should respond 400 for useless "filter"', async () => {
        var response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries?id=*",
          {
            headers: { Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),  },
          }
        );
          
        const bodyText = await response.text(),
        body = safeJSONParse(bodyText);
        expect(response.status).toBe(400);
        expect(body.detail).toBe("id=* is no useful filter");
      });

      it('should respond 401 for "Unauthorized"', async () => {
        var response = await fetch(baseURI + "/dicts/idDuisveniamqui/entries", {
          headers: { Accept: "application/vnd.wde.v2+json" },
          time: true,
        });

        expect(response.status).toBe(401);
      });

      describe('should respond 403 for "Forbidden"', async () => {
        beforeEach(create_test_data.curry(false));
        it("on wrong username and password", async () => {
          var response = await fetch(baseURI + "/dicts/doin/entries", {
            headers: { Accept: "application/vnd.wde.v2+json",
                Authorization: "Basic "+btoa("nonexisting:nonsense")
             },
          });

          expect(response.status).toBe(403);
        });

        it("on using a query not stored in a template without authentication", async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?q=//someelement",
            {
              headers: { Accept: "application/json" },
            }
          );
          
          const bodyText = await response.text(),
          body = safeJSONParse(bodyText);
          expect(response.status).toBe(403);
        });

        it('on using a sort not one of "asc", "desc" or "none" without authentication', async () => {
          var response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries?sort=//someelement",
            {
              headers: { Accept: "application/json" },
            }
          );

          expect(response.status).toBe(403);
        });
        afterEach(remove_test_data);
      });

      it('should respond 404 "No function found that matches the request." for wrong accept', async () => {
        var response = await fetch(baseURI + "/dicts/inmollit/entries", {
          headers: { Accept: "application/vnd.wde.v8+json" },
        });

        const value = await response.text()
        expect(response.status).toBe(404);
        expect(
        value === "No function found that matches the request." ||
        value === "Service not found."
        ).toBe(true)
      });
    });

    async function create_test_data(useCache) {
      var config = {
          body: JSON.stringify({
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
              useCache: useCache,
            }),
          }),
          headers: {
            Accept: "application/vnd.wde.v2+json",
            Authorization:
              "Basic " +
              btoa(dictuserauth.username + ":" + dictuserauth.password),
            "Content-Type": "application/json",
          },
        },
        response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries",
          {
            method: "POST",
            ...config,
          }
        );

      expect(response.status).toBe(201);

      response = await fetch(baseURI + "/dicts/" + dictuser.table);

      let bodyText = await response.text(),
          body = safeJSONParse(bodyText);
      expect(response.status).toBe(200);
      expect(body._embedded._[0].queryTemplates).to.have.length(8);
      expect(body._embedded._[0].queryTemplates).to.include("tei_all");

      config = {
        body: JSON.stringify({
          sid: "test01",
          lemma: "",
          entry: compiledEntryTemplate({
            xmlID: "test01",
            formFaArab: "تست",
            formFaXModDMG: "ṭēsṯ",
            translation_en: "test",
            translation_de: "Test",
          }),
        }),
        headers: {
          Accept: "application/vnd.wde.v2+json",
          Authorization:
            "Basic " +
            btoa(dictuserauth.username + ":" + dictuserauth.password),
            "Content-Type": "application/json",
        },
      },
      response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries", {
            method: 'POST',
            ...config
          }
        );

      bodyText = await response.text();
      body = safeJSONParse(bodyText);
      expect(response.status).toBe(201);

      response = await fetch(baseURI + "/dicts/" + dictuser.table);

      bodyText = await response.text();
      body = safeJSONParse(bodyText);
      expect(response.status).toBe(200);
      expect(body._embedded._[0].dbNames).to.have.length(1);
      expect(body._embedded._[0].dbNames).to.include(dictuser.table);

      config = {
        body: { entries: [] },
        headers: {
          Accept: "application/vnd.wde.v2+json",
          Authorization:
            "Basic " +
            btoa(dictuserauth.username + ":" + dictuserauth.password),
            "Content-Type": "application/json",
        },
      };
      for (let i = 2; i < 5; i++) {
        config.body.entries.push({
          sid: "test0" + i,
          lemma: "",
          entry: compiledEntryTemplate({
            xmlID: "test0" + i,
            formFaArab: "تست " + i,
            formFaXModDMG: "ṭēsṯ " + i,
            translation_en: "test" + i,
            translation_de: "Test" + i,
          }),
        });
      }
      for (let i = 9; i > 4; i--) {
        config.body.entries.push({
          sid: "test0" + i,
          lemma: "",
          entry: compiledEntryTemplate({
            xmlID: "test0" + i,
            formFaArab: "تست " + i,
            formFaXModDMG: "ṭēsṯ " + i,
            translation_en: "test" + i,
            translation_de: "Test" + i,
          }),
        });
      }
      config.body = JSON.stringify(config.body);
      response = await fetch(
        baseURI + "/dicts/" + dictuser.table + "/entries", {
            method: 'POST',
            ...config
        }
      );
      bodyText = await response.text();
      body = safeJSONParse(bodyText);
      expect(response.status).toBe(200);
    }

    async function remove_test_data() {
      {
        let ids = "";
        for (let i = 1; i < 10; i++) {
          ids += "test0" + i + ",";
        }
        let response = await fetch(
          baseURI + "/dicts/" + dictuser.table + "/entries?lock=10&ids=" + ids,
          {
            headers: {
              Accept: "application/vnd.wde.v2+json",
              Authorization:
                "Basic " +
                btoa(dictuserauth.username + ":" + dictuserauth.password),
            },
          }
        );
        let bodyText = await response.text(),
            body = safeJSONParse(bodyText);
        expect(response.status).toBe(200);

        for (let i = 1; i < 10; i++) {
          response = await fetch(
            baseURI + "/dicts/" + dictuser.table + "/entries/test0" + i,
            {
              method: "DELETE",
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
              },
            }
          );
          bodyText = await response.text();
          body = safeJSONParse(bodyText);
          expect(response.status).toBe(204);
          // especially using cache needs a bit of time to finish removing all the database files.
          // if no pause is here there are 500 errors complaining about renaming if xxx.cache.0
          await later(100);
        }
      }

      // Perhaps not needed at all: Warnung! Dangerous! Deletes every entry except the system entries < 699 from the dictionary.
      // describe('tests for delete', function() {
      //     it('should respond 204 for "No Content"', function() {
      //         var response = request('delete', baseURI+'/dicts/pariatur/entries', {
      //             'headers': {"Accept":"application/vnd.wde.v2+json"},
      //             'time': true
      //         });

      //         expect(response.status).toBe(204);
      //         return chakram.wait();
      //     });

      //     it('should respond 401 for "Unauthorized"', function() {
      //         var response = request('delete', baseURI+'/dicts/irureinfugiatculpaelit/entries', {
      //             'headers': {"Accept":"application/vnd.wde.v2+json"},
      //             'time': true
      //         });

      //         expect(response.status).toBe(401);
      //         return chakram.wait();
      //     });

      //     it('should respond 403 for "Forbidden"', function() {
      //         var response = request('delete', baseURI+'/dicts/quisconsequatveniamametlaborum/entries', {
      //             'headers': {"Accept":"application/vnd.wde.v2+json"},
      //             'time': true
      //         });

      //         expect(response.status).toBe(403);
      //         return chakram.wait();
      //     });

      //     it('should respond 406 for "Not Acceptable"', function() {
      //         var response = request('delete', baseURI+'/dicts/velit/entries', {
      //             'headers': {"Accept":"application/vnd.wde.v2+json"},
      //             'time': true
      //         });

      //         expect(response.status).toBe(406);
      //         return chakram.wait();
      //     });

      //     it('should respond 415 for "Unsupported Media Type"', function() {
      //         var response = request('delete', baseURI+'/dicts/autenonnulla/entries', {
      //             'headers': {"Accept":"application/vnd.wde.v2+json"},
      //             'time': true
      //         });

      //         expect(response.status).toBe(415);
      //         return chakram.wait();
      //     });

      // });

      describe("tests for patch", function () {
        var changedEntries = [],
          changedIds = "test03,test08";
        beforeAll(function () {
          changedEntries = [
            {
              id: "test03",
              sid: "",
              lemma: "",
              entry: compiledEntryTemplate({
                xmlID: "test03",
                formFaArab: "تست 03 changed",
                formFaXModDMG: "ṭēsṯ 03 changed",
                translation_en: "test 03 changed",
                translation_de: "Test 03 geändert",
              }),
            },
            {
              id: "test08",
              sid: "",
              lemma: "",
              entry: compiledEntryTemplate({
                xmlID: "test08",
                formFaArab: "تست 08 changed",
                formFaXModDMG: "ṭēsṯ 08 changed",
                translation_en: "test 08 changed",
                translation_de: "Test 08 geändert",
              }),
            },
          ];
        });
        describe('should respond 200 for "OK"', response200tests.curry(false));
        describe(
          'should respond 200 for "OK" (using cache)',
          response200tests.curry(true)
        );
        function response200tests(useCache) {
          beforeEach("Add test data", create_test_data.curry(useCache));
          it("when chnaging two entries", async () => {
            var currentEntries = await await fetch(
              baseURI + "/dicts/" + dictuser.table + "/entries",
              {
                headers: { Accept: "application/vnd.wde.v2+json" },
                qs: {
                  lock: 5,
                  ids: changedIds,
                },
                auth: dictuserauth,
              }
            );
            changedEntries[0].storedEntryMd5 =
              currentEntries.body._embedded.entries.filter(
                (entry) => entry.id === changedEntries[0].id
              )[0].storedEntryMd5;
            changedEntries[1].storedEntryMd5 =
              currentEntries.body._embedded.entries.filter(
                (entry) => entry.id === changedEntries[1].id
              )[0].storedEntryMd5;
            var requestData = {
              headers: { Accept: "application/vnd.wde.v2+json" },
              auth: dictuserauth,
              body: {
                entries: changedEntries,
              },
              time: true,
            };
            var response = request(
              "patch",
              baseURI + "/dicts/" + dictuser.table + "/entries",
              requestData
            );

            expect(response.status).toBe(200);
            expect(response).to.have.json(function (body) {
              expect(body.total_items).toBe("2");
              expect(body._embedded.entries).to.have.length(2);
              expect(body._embedded.entries[0].id).toBe("test03");
              expect(body._embedded.entries[0].lemma).toBe("ṭēsṯ 03 changed");
              expect(body._embedded.entries[1].id).toBe("test08");
              expect(body._embedded.entries[1].lemma).toBe("ṭēsṯ 08 changed");
            });
            afterEach("Remove test data", remove_test_data);

            // when will this happen?
            // it('should respond 400 for "Client Error"', function() {
            //     var response = request('patch', baseURI+'/dicts/eiusmodconsequ/entries', {
            //         'body': {"sid":"nostrud quis consequa","lemma":"ullamco qui dolore ipsum","entry":"consequat consectetur"},
            //         'headers': {"Accept":"application/vnd.wde.v2+json"},
            //         'time': true
            //     });

            //     expect(response.status).toBe(400);
            //     return chakram.wait();
            // });

            it('should respond 401 for "Unauthorized"', function () {
              var response = request(
                "patch",
                baseURI + "/dicts/" + dictuser.table + "/entries",
                {
                  body: {
                    entries: changedEntries,
                  },
                  headers: { Accept: "application/vnd.wde.v2+json" },
                  time: true,
                }
              );

              expect(response.status).toBe(401);
            });

            it('should respond 403 for "Forbidden"', function () {
              var response = request(
                "patch",
                baseURI + "/dicts/" + dictuser.table + "/entries",
                {
                  body: {
                    entries: changedEntries,
                  },
                  headers: { Accept: "application/vnd.wde.v2+json" },
                  auth: { user: "nonexisting", pass: "nonsense" },
                  time: true,
                }
              );

              expect(response.status).toBe(403);
            });

            it('should respond 404 "No function found that matches the request." for wrong accept', async () => {
              var response = request(
                "patch",
                baseURI + "/dicts/" + dictuser.table + "/entries",
                {
                  body: {
                    entries: [
                      {
                        id: "test05",
                        sid: "",
                        lemma: "",
                        entry: "<entry><orth></orth></entry>",
                      },
                    ],
                  },
                  headers: { Accept: "application/vnd.wde.v8+json" },
                  auth: dictuserauth,
                  time: true,
                }
              );

              expect(response.status).toBe(404);
              const value = await response.text();
              expect(
                value === "No function found that matches the request." ||
                  value === "Service not found."
              ).toBe(true);
            });

            describe('should respond 409 for "Conflict"', () => {
              beforeEach("Add test data", create_test_data.curry(false));
              it("when the checksum for the stored entry does not match", async () => {
                await await fetch(
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    qs: {
                      lock: 5,
                      ids: "test03,test08",
                    },
                    auth: dictuserauth,
                  }
                );
                changedEntries[0].storedEntryMd5 = "no valid md5";
                var response = request(
                  "patch",
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    body: {
                      entries: changedEntries,
                    },
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    auth: dictuserauth,
                    time: true,
                  }
                );

                expect(response.status).toBe(409);
                const body = await response.json();
                expect(body.detail).toContain("no valid md5");
              });
              afterEach("Remove test data", remove_test_data);
            });

            it('should respond 415 for "Unsupported Media Type"', function () {
              var response = request(
                "patch",
                baseURI + "/dicts/" + dictuser.table + "/entries",
                {
                  json: false,
                  body: "ut deserunt voluptate",
                  headers: { Accept: "application/vnd.wde.v2+json" },
                  auth: dictuserauth,
                  time: true,
                }
              );

              expect(response.status).toBe(415);
            });

            describe('should respond 422 for "Unprocessable Entity"', function () {
              beforeEach("Lock test entry", async () => {
                return await fetch(
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    qs: {
                      lock: 5,
                      ids: "test03,test08,test05",
                    },
                    auth: dictuserauth,
                  }
                );
              });
              it("if there are no entries sent in the body", function () {
                var response = request(
                  "patch",
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    body: {
                      something: [
                        {
                          id: "test05",
                          sid: "",
                          lemma: "",
                          entry: "<entry><orth></orth></entry>",
                        },
                      ],
                    },
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    auth: dictuserauth,
                    time: true,
                  }
                );

                expect(response.status).toBe(422);
              });
              it("if there are no IDs for the entries sent in the body", function () {
                var response = request(
                  "patch",
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    body: {
                      something: [
                        {
                          sid: "",
                          lemma: "",
                          entry: "<entry><orth></orth></entry>",
                        },
                      ],
                    },
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    auth: dictuserauth,
                    time: true,
                  }
                );

                expect(response.status).toBe(422);
              });
              it("if entry is not well formed XML", function () {
                var response = request(
                  "patch",
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    body: {
                      entries: [
                        {
                          id: "test05",
                          sid: "",
                          lemma: "",
                          entry: "<entry><orth></entry></orth>",
                        },
                      ],
                    },
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    auth: dictuserauth,
                    time: true,
                  }
                );

                expect(response.status).toBe(422);
              });

              it("if an entry is no XML, just text", async function () {
                var response = request(
                  "patch",
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  {
                    body: {
                      entries: [
                        {
                          id: "test03",
                          sid: "",
                          lemma: "",
                          entry: "eu et ipsum",
                        },
                      ],
                    },
                    headers: { Accept: "application/vnd.wde.v2+json" },
                    auth: dictuserauth,
                    time: true,
                  }
                );

                expect(response.status).toBe(422);
                const body = await response.json();
                expect(body.detail).toBe(
                  "Data consists only of text - no markup"
                );
              });

              it("if entry has no @xml:id", function () {
                var requestData = {
                  body: {
                    entries: JSON.parse(
                      JSON.stringify(changedEntries).replace(
                        /xml:id=\\"[^\\]+\\"\s/,
                        ""
                      )
                    ),
                  },
                  headers: { Accept: "application/vnd.wde.v2+json" },
                  auth: dictuserauth,
                  time: true,
                };
                var response = request(
                  "patch",
                  baseURI + "/dicts/" + dictuser.table + "/entries",
                  requestData
                );

                expect(response.status).toBe(422);
              });
            });
          });

        }
    });
    
}
          afterEach(async () => {
            let response = await fetch(baseURI + "/dicts/" + dictuser.table, {
              method: "DELETE",
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(dictuserauth.username + ":" + dictuserauth.password),
              },
            });

            expect(response.status).toBe(204);

            response = await fetch(
              baseURI + "/dicts/dict_users/users/" + newDictUserID,
              {
                method: "DELETE",
                headers: {
                  Accept: "application/vnd.wde.v2+json",
                  Authorization:
                    "Basic " +
                    btoa(superuserauth.username + ":" + superuserauth.password),
                },
              }
            );

            expect(response.status).toBe(204);

            response = await fetch(baseURI + "/dicts/dict_users", {
              method: "DELETE",
              headers: {
                Accept: "application/vnd.wde.v2+json",
                Authorization:
                  "Basic " +
                  btoa(superuserauth.username + ":" + superuserauth.password),
              },
            });

            expect(response.status).toBe(204);
          });
  });
}
