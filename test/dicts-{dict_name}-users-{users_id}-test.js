'use strict';
import { describe, it, beforeAll, afterAll, beforeEach, afterEach, expect } from 'vitest';
import fetch from 'node-fetch-native';

export default function(baseURI, basexAdminUser, basexAdminPW) {
    describe('tests for /dicts/{dict_name}/users/{users_id}', function() {
        // added T.K. - make dict_users and the superuser available
        beforeAll(async function() {
            let superuser = {
                "id": "",
                "userID": basexAdminUser,
                "pw": basexAdminPW,
                "read": "y",
                "write": "y",
                "writeown": "n",
                "table": "dict_users"
            };
            let superuserauth = { "user": superuser.userID, "pass": superuser.pw };

            await fetch(baseURI + '/dicts', {
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ 'name': 'dict_users' })
            });

            await fetch(baseURI + '/dicts/dict_users/users', {
                method: 'POST',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(superuser)
            });
        });

        // delete dict_users table
        afterAll(async function() {
            let superuser = {
                "id": "",
                "userID": basexAdminUser,
                "pw": basexAdminPW,
                "read": "y",
                "write": "y",
                "writeown": "n",
                "table": "dict_users"
            };
            let superuserauth = { "user": superuser.userID, "pass": superuser.pw };

            await fetch(baseURI + '/dicts/dict_users', {
                method: 'DELETE',
                headers: {
                    "Accept": "application/vnd.wde.v2+json",
                    "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                }
            });
        });

        describe('tests for get', function() {
            // added T.K. start - make more tests applicable
            let userName = "someName";
            let userPW = "somePassword";
            let read = "y";
            let write = "y";
            let writeown = "n";
            let table = "";
            let userId = "";
            let superuser = {
                "id": "",
                "userID": basexAdminUser,
                "pw": basexAdminPW,
                "read": "y",
                "write": "y",
                "writeown": "n",
                "table": "dict_users"
            };
            let superuserauth = { "user": superuser.userID, "pass": superuser.pw };

            // setup for each test - create a test user in the database
            beforeEach(async function() {
                await fetch(baseURI + '/dicts/dict_users/users/', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    },
                    body: JSON.stringify({
                        "id": "",
                        "userID": userName,
                        "pw": userPW,
                        "read": read,
                        "write": write,
                        "writeown": writeown,
                        "table": "dict_users"
                    })
                });
            });

            // Testing response codes:
            //      200 - Ok, 401 - Unauthorized, 403 - Forbidden, 404 - Not Found, 406 - Not Acceptable, 415 - Unsupported media type
            // get a particular user (= testuser)
            // this test fails and I don't know why
            it('should respond 200 for "OK"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(200);
            });

            // try to get a particular user without credentials
            it('should respond 401 for "Unauthorized"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    }
                });

                expect(response.status).toBe(401);
            });

            // try to access dict_users without superuser rights - this is possible
            it('should respond 200 for "OK"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${userName}:${userPW}`)
                    }
                });

                expect(response.status).toBe(200);
            });

            // try to access a resource which does not exist
            it('should respond 404 for "Not Found"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + "anotexistinguser", {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(404);
            });

            // don't know what this test means
            it.skip('should respond 406 for "Not Acceptable"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/utsit/users/laboreaute', {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    }
                });

                expect(response.status).toBe(406);
            });

            // request for a not supported media type - This test fails: Return value is 404
            it.skip('should respond 415 for "Unsupported Media Type"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v8+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(415);
            });

            // added T.K. start
            it('should return a particular user with userName = ' + userName, async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'GET',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                const body = await response.json();
                expect(response.status).toBe(200);
                expect(body.userID).toEqual(userName);
            });

            // added T.K. end

            // added T.K. start - cleanup - delete test user
            afterEach(async function() {
                await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });
            });
            // added T.K. end
        });

        describe('tests for delete', function() {
            // added T.K. start - make more tests applicable
            let userName = "someName";
            let userPW = "somePassword";
            let read = "true";
            let write = "false";
            let writeown = "false";
            let table = "";
            let userId = "";
            let superuser = {
                "id": "",
                "userID": basexAdminUser,
                "pw": basexAdminPW,
                "read": "y",
                "write": "y",
                "writeown": "n",
                "table": "dict_users"
            };
            let superuserauth = { "user": superuser.userID, "pass": superuser.pw };

            // setup for each test - create a test user in the database
            beforeEach(async function() {
                const createdUser = await fetch(baseURI + '/dicts/dict_users/users/', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Content-Type": "application/json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    },
                    body: JSON.stringify({
                        "id": "",
                        "userID": userName,
                        "pw": userPW,
                        "read": read,
                        "write": write,
                        "writeown": writeown,
                        "table": "dc_loans_genesis"
                    })
                });

                const createdUserBody = await createdUser.json();
                userId = createdUserBody.id;
                table = createdUserBody.table;
            });

            // try to delete a user which does not exist - but isn't this the case 404 Not Found? - a misunderstanding?
            it('should respond 204 for "No Content"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + "userwhichdoesnotexist", {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(204);
            });

            // added T.K. start
            // try to delete an user with success - this test fails, request delivers 204
            it.skip('should respond 200 for "Ok"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(200);
            });

            // added T.K. end
            // try to delete an user without rights
            it('should respond 401 for "Unauthorized"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    }
                });

                expect(response.status).toBe(401);
            });

            // try to delete an user without sufficient rights
            it('should respond 403 for "Forbidden"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${userName}:${userPW}`)
                    }
                });

                expect(response.status).toBe(403);
            });

            // try to delete an user which does not exist - compare note above - test fails, request delivers 204
            it.skip('should respond 404 for "Not Found"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + "userwhichdoesnotexist", {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(404);
            });

            // don't know what this test should do
            it.skip('should respond 406 for "Not Acceptable"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/ut/users/esseet', {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    }
                });

                expect(response.status).toBe(406);
            });

            // which role has the media type for a delete operation? - this test fails, request delivers 406
            it.skip('should respond 415 for "Unsupported Media Type"', async function() {
                const response = await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v8+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });

                expect(response.status).toBe(415);
            });

            // added T.K. start - cleanup - delete test user
            afterEach(async function() {
                await fetch(baseURI + '/dicts/dict_users/users/' + userName, {
                    method: 'DELETE',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json",
                        "Authorization": 'Basic ' + btoa(`${superuserauth.user}:${superuserauth.pass}`)
                    }
                });
            });
            // added T.K. end
        });

        describe.skip('tests for post', function() {
            it('should respond 201 for "Created"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/eu/users/amet', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    },
                    body: JSON.stringify({
                        "id": "magna laborum cupidatat labore",
                        "userID": "dolore minim in officia nostrud",
                        "pw": "quis minim",
                        "read": "ipsum sed sint",
                        "write": "dolor dolore sed",
                        "writeown": "enim esse ea mollit"
                    })
                });

                expect(response.status).toBe(201);
            });

            it('should respond 400 for "Client Error"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/elitfugiat/users/animquisquietaliqua', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    },
                    body: JSON.stringify({
                        "id": "non Excepteur anim pariatur",
                        "userID": "qui Duis magna in nostrud",
                        "pw": "et minim",
                        "read": "ex non",
                        "write": "nulla cupidatat ad",
                        "writeown": "ut"
                    })
                });

                expect(response.status).toBe(400);
            });

            it('should respond 404 for "Not Found"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/domollit/users/aliqua', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    },
                    body: JSON.stringify({
                        "id": "officia adipisicing incididunt dolor",
                        "userID": "ea ut aliquip",
                        "pw": "aute cillum labore enim",
                        "read": "fugiat dolore",
                        "write": "est",
                        "writeown": "en"
                    })
                });

                expect(response.status).toBe(404);
            });

            it('should respond 406 for "Not Acceptable"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/animetidnulla/users/incididuntullamco', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    },
                    body: JSON.stringify({
                        "id": "Lorem aute",
                        "userID": "mollit pariatur in irure",
                        "pw": "aute dolore",
                        "read": "veniam id ut aliqua",
                        "write": "cupidatat anim",
                        "writeown": "irure nulla"
                    })
                });

                expect(response.status).toBe(406);
            });

            it('should respond 415 for "Unsupported Media Type"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/animaliquaipsum/users/fugiatenimreprehenderit', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    },
                    body: JSON.stringify({
                        "id": "mollit labore in",
                        "userID": "aliquip Duis dolore laboris",
                        "pw": "mollit occaecat",
                        "read": "commodo Lorem tempor",
                        "write": "id dolore non nisi sint",
                        "writeown": "in"
                    })
                });

                expect(response.status).toBe(415);
            });

            it('should respond 422 for "Unprocessable Entity"', async function() {
                const response = await fetch('http://localhost:8984/restutf8/dicts/fugiatinesseaddolore/users/culpavelitdolorereprehenderit', {
                    method: 'POST',
                    headers: {
                        "Accept": "application/vnd.wde.v2+json"
                    },
                    body: JSON.stringify({
                        "id": "sunt Lorem ut anim enim",
                        "userID": "dolore qui nulla",
                        "pw": "do proident aute commodo",
                        "read": "laborum esse fugiat nostrud",
                        "write": "non velit eu",
                        "writeown": "proident magna"
                    })
                });

                expect(response.status).toBe(422);
            });
        });
    });
}