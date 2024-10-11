import { describe, it, beforeAll, beforeEach, afterEach, expect } from 'vitest';
import fetch from 'node-fetch-native';
import fs from 'fs';
import Handlebars from 'handlebars';
import { safeJSONParse } from './utilSetup';

export default function(baseURI, basexAdminUser, basexAdminPW) {
    describe('tests for /dicts/{dict_name}', function() {
        const superuser = {
            "id": "",
            "userID": basexAdminUser,
            "pw": basexAdminPW,
            "read": "y",
            "write": "y",
            "writeown": "n",
            "table": "dict_users"
        };
        const superuserauth = { "username": superuser.userID, "password": superuser.pw };
        let newSuperUserID;
        let compiledProfileTemplate;

        beforeAll(async function () {
            const testProfileTemplate = fs.readFileSync('test/fixtures/testProfile.xml', 'utf8');
            expect(testProfileTemplate).toContain("<tableName>{{dictName}}</tableName>");
            expect(testProfileTemplate).toContain("<displayString>{{displayString}}</displayString>");
            compiledProfileTemplate = Handlebars.compile(testProfileTemplate);
            const compiledTemplate = compiledProfileTemplate({
                'dictName': 'replaced',
                'mainLangLabel': 'aNCName',        
                'displayString': '{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}',
                'altDisplayString': {
                    'label': 'test',
                    'displayString': '//mds:titleInfo/mds:title'
                },
                'useCache': true
            });
            expect(compiledTemplate).toContain("<tableName>replaced</tableName>");
            expect(compiledTemplate).toContain('displayString>{//mds:name[1]/mds:namePart}: {//mds:titleInfo/mds:title}<');
            expect(compiledTemplate).toContain('altDisplayString label="test">//mds:titleInfo/mds:title<');
            expect(compiledTemplate).toContain('mainLangLabel>aNCName<');
            expect(compiledTemplate).toContain('useCache/>');
        });

        beforeEach(async function () {
            const dictUsersCreated = await fetch(baseURI + '/dicts', {
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ 'name': 'dict_users' })
            });

            const userCreateResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(superuser)
            });

            const userCreateResponseBody = await userCreateResponse.json();
            newSuperUserID = userCreateResponseBody.id;
        });

        describe('tests for get', function() {
            const dictuser = {
                "id": "",
                "userID": 'testUser0',
                "pw": 'PassW0rd',
                "read": "y",
                "write": "y",
                "writeown": "n",
                "table": "deseruntsitsuntproident"
            };
            const dictuserauth = { "username": dictuser.userID, "password": dictuser.pw };
            let newDictUserID;

            beforeEach(async function() {
                const userCreateResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify(dictuser)
                });

                const userCreateResponseBody = await userCreateResponse.json();
                newDictUserID = userCreateResponseBody.id;

                const createDictUserTableResponse = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify({ "name": dictuser.table })
                });
                
                const body = await createDictUserTableResponse.text(),
                      jsonBody = safeJSONParse(body);

                expect(createDictUserTableResponse.status).toBe(201);
            });

            describe('should respond 200 for "OK"', function() {
                it('when authenticated', async function() {
                    const config = {
                        method: 'POST',
                        headers: {
                            "Accept": "application/vnd.wde.v2+json",
                            "Content-Type": "application/json",
                            "Authorization": 'Basic ' + btoa(`${dictuserauth.username}:${dictuserauth.password}`)
                        },
                        body: JSON.stringify({
                            "sid": "dictProfile",
                            "lemma": "",
                            "entry": compiledProfileTemplate({
                                'dictName': dictuser.table,
                                'displayString': '//tei:form/tei:orth[1]',
                                'useCache': false
                            })
                        })
                    };

                    let response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', config),
                        body = await response.text(),
                        jsonBody = safeJSONParse(body);
                    expect(response.status).toBe(201);

                    response = await fetch(baseURI + '/dicts/' + dictuser.table, {
                        method: 'GET',
                        headers: {
                            "Accept": "application/vnd.wde.v2+json",
                            "Authorization": 'Basic ' + btoa(`${dictuserauth.username}:${dictuserauth.password}`)
                        }
                    });

                    body = await response.text(),
                    jsonBody = safeJSONParse(body);
                    expect(response.status).toBe(200);
                    expect(jsonBody.total_items).toBe("2");
                    expect(jsonBody._embedded._[0].note).toBe("all entries");
                    expect(jsonBody._embedded._[0].cache).toBeUndefined();
                    expect(jsonBody._embedded._[0].dbNames).toBeInstanceOf(Array);
                    expect(jsonBody._embedded._[0].queryTemplates).toEqual(["tei_all", "tei_lem", "tei_sid", "tei_pos", "tei_tr", "mds_names", "mds_any", "mds_title"]);
                    expect(jsonBody._embedded._[0].specialCharacters).toEqual([{ "value": "’" }, { "value": "ʔ" }, { "value": "ā" }, { "value": "ḅ" }]);
                    expect(jsonBody._embedded._[1].note).toBe("all users with access to this dictionary");
                });

                it('when unauthenticated (public)', async function() {
                    const response = await fetch(baseURI + '/dicts/deseruntsitsuntproident', {
                        method: 'GET'
                    });

                    const body = await response.text(),
                          jsonBody = safeJSONParse(body);
                    expect(response.status).toBe(200);
                    expect(jsonBody.total_items).toBe("2");
                    expect(jsonBody._embedded._[0].note).toBe("all entries");
                    expect(jsonBody._embedded._[0].cache).toBeUndefined();
                    expect(jsonBody._embedded._[0].dbNames).toBeInstanceOf(Array);
                    expect(jsonBody._embedded._[0].queryTemplates).toBeInstanceOf(Array);
                    expect(jsonBody._embedded._[0].specialCharacters).toBeInstanceOf(Array);
                    expect(jsonBody._embedded._[1].note).toBe("all users with access to this dictionary");
                });

                it('should report whether the cache is activated', async function() {
                    const config = {
                        method: 'POST',
                        headers: {
                            "Accept": "application/vnd.wde.v2+json",
                            "Content-Type": "application/json",
                            "Authorization": 'Basic ' + btoa(`${dictuserauth.username}:${dictuserauth.password}`)
                        },
                        body: JSON.stringify({
                            "sid": "dictProfile",
                            "lemma": "",
                            "entry": compiledProfileTemplate({
                                'dictName': dictuser.table,
                                'displayString': '//tei:form/tei:orth[1]',
                                'useCache': true
                            })
                        })
                    };

                    let response = await fetch(baseURI + '/dicts/' + dictuser.table + '/entries', config),
                    body = await response.text(),
                    jsonBody = safeJSONParse(body);

                    expect(response.status).toBe(201);

                    response = await fetch(baseURI + '/dicts/deseruntsitsuntproident', {
                        method: 'GET'
                    });

                    body = await response.text(),
                    jsonBody = safeJSONParse(body);;
                    expect(response.status).toBe(200);
                    expect(jsonBody.total_items).toBe("2");
                    expect(jsonBody._embedded._[0].note).toBe("all entries");
                    expect(jsonBody._embedded._[0].cache).toBe("true");
                });
            });

            it('should respond 401 for "Unauthorized"', async function() {
                const response = await fetch(baseURI + '/dicts/magna', {
                    method: 'GET',
                    headers: {
                        // access needs auth with wde.v2
                        "Accept": "application/vnd.wde.v2+json"
                    }
                });

                expect(response.status).toBe(401);
            });

            it('should respond 403 for "Forbidden"', async function() {
                const response = await fetch(baseURI + '/dicts/minimconsequataliquaoccaecat', {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa('nonexisting:nonsense')
                    }
                });

                expect(response.status).toBe(403);
            });

        // 404 with wde.v2 is only possible if the table is gone but the user still exists.
        // This should never happen as the delete command removes also all the users.
        // Otherwise: 403

            it('should respond 404 for "Not Found" (public)', async function() {
                const response = await fetch(baseURI + '/dicts/insed', {
                    method: 'GET'
                });

                expect(response.status).toBe(404);
            });

            it('should respond 404 "No function found that matches the request." for wrong accept', async function() {
                const response = await fetch(baseURI + '/dicts/animlaborisdolore', {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v8+json"
                    }
                });

                const body = await response.text(),
                      jsonBody = safeJSONParse(body);
                expect(response.status).toBe(404);
                expect(body === 'No function found that matches the request.' || body === 'Service not found.').toBe(true);
            });

            // 415 is used for rejecting a body, so makes no sense here

            afterEach(async function() {
                await fetch(baseURI + '/dicts/' + dictuser.table, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${dictuserauth.username}:${dictuserauth.password}`)
                    }
                });

                await fetch(baseURI + '/dicts/dict_users/users/' + newDictUserID, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    }
                });
            });
        });

        describe('tests for delete', function() {
            // a superuser for the test table
            const dictuser = {
                "id": "",
                "userID": 'testUser0',
                "pw": 'PassW0rd',
                "read": "y",
                "write": "y",
                "writeown": "n",
                "table": "deseruntsitsuntproident"
            };
            const dictuserauth = { "username": dictuser.userID, "password": dictuser.pw };
            let newDictUserID;

            beforeEach(async function() {
                const userCreateResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify(dictuser)
                });

                const userCreateResponseBody = await userCreateResponse.json();
                newDictUserID = userCreateResponseBody.id;
            });

            it('should respond 204 for "No Content"', async function() {
                let response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        // A new table can only be created by a global super user
                        "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify({ "name": dictuser.table })
                }),
                body = await response.text(),
                jsonBody = safeJSONParse(body);

                expect(response.status).toBe(201);

                // A table can only be deleted by a super user of that table
                // A global super user would need to make himself superuser of that table

                response = await fetch(baseURI + '/dicts/' + dictuser.table, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${dictuserauth.username}:${dictuserauth.password}`)
                    }
                });
                
                body = await response.text(),
                jsonBody = safeJSONParse(body);
                expect(response.status).toBe(204);
            });

            it('should respond 401 for "Unauthorized"', async function() {
                const response = await fetch(baseURI + '/dicts/' + dictuser.table, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    }
                });

                expect(response.status).toBe(401);
            });

            it('should respond 403 for "Forbidden"', async function() {
                const response = await fetch(baseURI + '/dicts/eiusmodtempor', {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa('nonexisting:nonsense')
                    }
                });

                const body = await response.text(),
                      jsonBody = safeJSONParse(body);
                expect(response.status).toBe(403);
            });

            // 404 for delete is not possible, it is always 403

            it('should respond 406 for "Not Acceptable"', async function() {
                const response = await fetch(baseURI + '/dicts/aliquipcommodoid', {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v8+json"
                    }
                });

                expect(response.status).toBe(406);
            });

            // 415 is used for rejecting a body, so makes no sense here

            afterEach(async function() {
                await fetch(baseURI + '/dicts/dict_users/users/' + newDictUserID, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    }
                });
            });
        });

        afterEach(async function() {
            await fetch(baseURI + '/dicts/dict_users', {
                method: 'DELETE',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Authorization": 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                }
            });
        });
    });
}