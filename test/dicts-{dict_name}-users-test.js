import { describe, it, expect } from "vitest";
import fetch from "node-fetch-native";
import "./utilSetup";

export default function (baseURI, basexAdminUser, basexAdminPW) {
  describe("tests for /dicts/{dict_name}/users", function () {
    // accessing the users of a particular dictionary is still not implemented.
    describe.skip("tests for get", function () {
      it('should respond 200 for "OK"', async function () {
        const response = await fetch(
          baseURI + "/dicts/essedolorecillum/users",
          {
            method: "GET",
            headers: { Accept: "application/vnd.wde.v2+json" },
          }
        );

        expect(response.status).toBe(200);
      });

      it('should respond 401 for "Unauthorized"', async function () {
        const response = await fetch(baseURI + "/dicts/cillum/users", {
          method: "GET",
          headers: { Accept: "application/vnd.wde.v2+json" },
        });

        expect(response.status).toBe(401);
      });

      it('should respond 403 for "Forbidden"', async function () {
        const response = await fetch(baseURI + "/dicts/Excepteurirure/users", {
          method: "GET",
          headers: { Accept: "application/vnd.wde.v2+json" },
        });

        expect(response.status).toBe(403);
      });

      it('should respond 406 for "Not Acceptable"', async function () {
        const response = await fetch(baseURI + "/dicts/deseruntculpa/users", {
          method: "GET",
          headers: { Accept: "application/vnd.wde.v2+json" },
        });

        expect(response.status).toBe(406);
      });

      it('should respond 415 for "Unsupported Media Type"', async function () {
        const response = await fetch(
          baseURI + "/dicts/occaecatmagnaDuis/users",
          {
            method: "GET",
            headers: { Accept: "application/vnd.wde.v2+json" },
          }
        );

        expect(response.status).toBe(415);
      });
    });

    describe.skip("tests for post", function () {
      it('should respond 201 for "Created"', async function () {
        const response = await fetch(baseURI + "/dicts/c/users", {
          method: "POST",
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            id: "reprehenderit",
            userID: "non deserunt nulla id",
            pw: "in anim esse",
            read: "esse ut",
            write: "laboris tempor",
            writeown: "culpa",
          }),
        });

        expect(response.status).toBe(201);
      });

      it('should respond 400 for "Client Error"', async function () {
        const response = await fetch(baseURI + "/dicts/irureconsequat/users", {
          method: "POST",
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            id: "pariatur qui",
            userID: "irure Lorem Excepteur",
            pw: "et ex",
            read: "elit in ",
            write: "pariatur aliqua",
            writeown: "cupidatat ea fugiat adipisicing",
          }),
        });

        expect(response.status).toBe(400);
      });

      it('should respond 401 for "Unauthorized"', async function () {
        const response = await fetch(
          baseURI + "/dicts/nullaveniamExcepteu/users",
          {
            method: "POST",
            headers: {
              Accept: "application/vnd.wde.v2+json",
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              id: "proident velit occaecat",
              userID: "in deserunt in tempor",
              pw: "mollit pariatur",
              read: "velit",
              write: "sed Ut esse ea",
              writeown: "Excepteur Lorem in deserunt",
            }),
          }
        );

        expect(response.status).toBe(401);
      });

      it('should respond 403 for "Forbidden"', async function () {
        const response = await fetch(
          baseURI + "/dicts/adipisicingcommodoessedoloremagna/users",
          {
            method: "POST",
            headers: {
              Accept: "application/vnd.wde.v2+json",
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              id: "Ut ut cillum dolore",
              userID: "ut et in ullamco",
              pw: "qui",
              read: "enim ut sed labore",
              write: "dolore anim Lorem",
              writeown: "velit et",
            }),
          }
        );

        expect(response.status).toBe(403);
      });

      it('should respond 406 for "Not Acceptable"', async function () {
        const response = await fetch(baseURI + "/dicts/ineuid/users", {
          method: "POST",
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            id: "pari",
            userID: "labore ad anim deserunt",
            pw: "sint",
            read: "enim do",
            write: "elit esse et consequat culpa",
            writeown: "esse Lorem",
          }),
        });

        expect(response.status).toBe(406);
      });

      it('should respond 415 for "Unsupported Media Type"', async function () {
        const response = await fetch(
          baseURI + "/dicts/veniamadipisicingeacupidatat/users",
          {
            method: "POST",
            headers: {
              Accept: "application/vnd.wde.v2+json",
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              id: "sunt et nostrud dolore",
              userID: "veniam sunt",
              pw: "cupidatat pariatur",
              read: "cupidatat",
              write: "nostrud dolor",
              writeown: "aliquip Ut enim eu",
            }),
          }
        );

        expect(response.status).toBe(415);
      });

      it('should respond 422 for "Unprocessable Entity"', async function () {
        const response = await fetch(baseURI + "/dicts/incididunt/users", {
          method: "POST",
          headers: {
            Accept: "application/vnd.wde.v2+json",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            id: "laboris do adipisicing laborum",
            userID: "dolor dolore",
            pw: "mollit eiusmod cupidatat dolor",
            read: "reprehenderit irure cillum magna",
            write: "veniam am",
            writeown: "ea magna",
          }),
        });

        expect(response.status).toBe(422);
      });
    });
  });
}
