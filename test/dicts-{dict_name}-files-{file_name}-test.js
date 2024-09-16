"use strict";
const mocha = require("mocha");
const chakram = require("chakram");
const assert = require("chai").assert;
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
      compiledFileTemplate;

    describe("tests for get", () => {
      it('should respond 200 for "OK"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/nulla/files/ullamcodoloreincididuntnon",
          {
            qs: { lock: "" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(200);
        
      });

      it('should respond 401 for "Unauthorized"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/eiusmodsitminimreprehenderit/files/easedextempor",
          {
            qs: { lock: "" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(401);
        
      });

      it('should respond 403 for "Forbidden"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/deseruntproidentdolorutaliquip/files/velit",
          {
            qs: { lock: "367699" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(403);
        
      });

      it('should respond 404 for "Not Found"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/esse/files/euetpariaturofficiaculpa",
          {
            qs: { lock: "8539126661" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(404);
        
      });

      it('should respond 406 for "Not Acceptable"', async () => {
        var response = await request(
          "get",
          baseURI + "/dicts/deseruntcommodoaliqua/files/eiusmodUtproident",
          {
            qs: { lock: "1728143477" },
            headers: { Accept: "application/vnd.wde.v2+json" },
            time: true,
          }
        );

        expect(response).to.have.status(406);
        
      });
    });
  });
};
