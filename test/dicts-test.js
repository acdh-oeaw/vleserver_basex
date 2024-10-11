import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import fetch from 'node-fetch-native';
import { safeJSONParse } from './utilSetup';

export default function(baseURI, basexAdminUser, basexAdminPW) {
    describe('tests for /dicts', () => {
        const superuser = {
            id: '',
            userID: basexAdminUser,
            pw: basexAdminPW,
            read: 'y',
            write: 'y',
            writeown: 'n',
            table: 'dict_users',
        };
        const superuserauth = { username: superuser.userID, password: superuser.pw };
        let newSuperUserID;
        // added T.K. start
        // try if it is possible to create the dict_users table
        // this works, however, it should not be possible to create the dict_users table without authentification

        describe('test the creation of the dict_users table - it is possible to create the dict_users table without credentials if the table does not exist', () => {
            it('should respond 200 for "OK"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ name: 'dict_users' }),
                });

                expect(response.status).toBe(201);

                const userResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(superuser),
                });

                expect(userResponse.status).toBe(200);
            });

            afterEach(async () => {
                const response = await fetch(baseURI + '/dicts/dict_users', {
                    method: 'DELETE',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    }
                });
                const body = await response.text(),
                      jsonBody = safeJSONParse(body);
                expect(response.status).toBe(204);
            });
        });

        describe('tests for get', () => {
            it('should respond 200 for "OK"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'GET',
                });

                expect(response.status).toBe(200);
                expect(response.headers.get('content-type')).toBe('application/json;charset=utf-8');

                const jsonResponse = await response.json();
                expect(jsonResponse._links).toEqual({
                    self: { href: '/restvle/dicts/?pageSize=25' },
                    first: { href: '/restvle/dicts/?page=1&pageSize=25' },
                    last: { href: '/restvle/dicts/?page=0&pageSize=25' },
                });
                expect(jsonResponse._embedded).toEqual({ dicts: [] });
                expect(jsonResponse.page_count).toBe('0');
                expect(jsonResponse.page_size).toBe('25');
                expect(jsonResponse.total_items).toBe('0');
                expect(jsonResponse.page).toBe('1');
            });

            describe('Authentication messages', () => {
                beforeEach(async () => {
                    const response = await fetch(baseURI + '/dicts', {
                        method: 'POST',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({ name: 'dict_users' }),
                    });

                    const userResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                        method: 'POST',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify(superuser),
                    });

                    const userCreateResponse = await userResponse.json();
                    newSuperUserID = userCreateResponse.id;
                });

                it('should respond 401 for "Unauthorized"', async () => {
                    const response = await fetch(baseURI + '/dicts', {
                        method: 'GET',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                        },
                    });

                    expect(response.status).toBe(401);
                });

                it('should respond 403 for "Forbidden"', async () => {
                    const response = await fetch(baseURI + '/dicts', {
                        method: 'GET',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            Authorization: 'Basic ' + btoa("notadmin:wrongpw")
                        },
                    });

                    expect(response.status).toBe(403);
                });

                afterEach(async () => {
                    await fetch(baseURI + '/dicts/dict_users', {
                        method: 'DELETE',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                        }
                    });
                });
            });
            // Accept will now select a particular function the %rest:produces that mime type.
            // Else the less useful 404 No function found that matches the request. is returned.
            // So 406 can not occur anymore.
            it('should respond 404 "No function found that matches the request." for wrong accept', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'GET',
                    headers: {
                        Accept: 'application/vnd.wde.v8+json',
                    },
                });

                expect(response.status).toBe(404);

                const body = await response.text();
                expect(
                    body === 'No function found that matches the request.' ||
                    body === 'Service not found.'
                ).toBe(true);
            });

         
            // 415 is related to the request body, not meaningful here
        });

        describe('tests for post', () => {
            beforeEach(async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        'Content-Type': 'application/json',
                        Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify({ name: 'dict_users' }),
                });

                const userResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(superuser),
                });

                const userCreateResponse = await userResponse.json();
                newSuperUserID = userCreateResponse.id;
            });

            describe('Creating a dictionary', () => {
                const dictname = 'sit_laborum_id';

                it('should respond 201 for "Created"', async () => {
                    const response = await fetch(baseURI + '/dicts', {
                        method: 'POST',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            'Content-Type': 'application/json',
                            Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                        },
                        body: JSON.stringify({ name: dictname }),
                    });

                    const body = await response.text(),
                          jsonBody = safeJSONParse(body);
                    expect(response.status).toBe(201);

                    expect(jsonBody.title).toBe('Created');
                });

                afterEach(async () => {
                    // a superuser for the test table
                    const dictuser = {
                        id: '',
                        userID: 'testUser0',
                        pw: 'PassW0rd',
                        read: 'y',
                        write: 'y',
                        writeown: 'n',
                        table: dictname,
                    };
                    const dictuserauth = { username: dictuser.userID, password: dictuser.pw };
                    let newDictUserID;

                    const userResponse = await fetch(baseURI + '/dicts/dict_users/users', {
                        method: 'POST',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            'Content-Type': 'application/json',
                            Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                        },
                        body: JSON.stringify(dictuser),
                    });

                    const userCreateResponse = await userResponse.json();
                    newDictUserID = userCreateResponse.id;

                    let response = await fetch(baseURI + '/dicts/' + dictname, {
                        method: 'DELETE',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            Authorization: 'Basic ' + btoa(`${dictuserauth.username}:${dictuserauth.password}`)
                        },
                    });

                    expect(response.status).toBe(204);

                    response = await fetch(baseURI + '/dicts/dict_users/users/' + newDictUserID, {
                        method: 'DELETE',
                        headers: {
                            Accept: 'application/vnd.wde.v2+json',
                            Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                        },
                    });

                    expect(response.status).toBe(204);
                });
            });

            it('should respond 400 for "Client Error"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        'Content-Type': 'application/json',
                        Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`),
                    },
                    body: JSON.stringify({ name: 'ut ut dolore Ut' }),
                });

                const body = await response.text(),
                      jsonBody = safeJSONParse(body);
                expect(response.status).toBe(400);
            });

            it('should respond 401 for "Unauthorized"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                    },
                    body: JSON.stringify({ name: 'velit anim laboris' }),
                });

                expect(response.status).toBe(401);
            });

            it('should respond 403 for "Forbidden"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        Authorization: 'Basic '
                    },
                    body: JSON.stringify({ name: 'quis et' }),
                });
                const body = await response.text(),
                      jsonBody = safeJSONParse(body);
                expect(response.status).toBe(403);
            });

            it('should respond 404 "No function found that matches the request." for wrong accept', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v8+json',
                    },
                    body: JSON.stringify({ name: 'anim labore pariatur' }),
                });

                expect(response.status).toBe(404);


                const body = await response.text(),
                      jsonBody = safeJSONParse(body);
                expect(
                    body === 'No function found that matches the request.' ||
                    body === 'Service not found.'
                ).toBe(true);
            });

            it('should respond 415 for "Unsupported Media Type"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify({ form: { name: 'quis' } }),
                });

                expect(response.status).toBe(415);
            });

            it('should respond 422 for "Unprocessable Entity"', async () => {
                const response = await fetch(baseURI + '/dicts', {
                    method: 'POST',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        'Content-Type': 'application/json',
                        Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                    body: JSON.stringify({ form: { name: 'irure aliqua exercitation mollit laboris' } }),
                });

                expect(response.status).toBe(422);
            });

            afterEach(async () => {
                await fetch(baseURI + '/dicts/dict_users', {
                    method: 'DELETE',
                    headers: {
                        Accept: 'application/vnd.wde.v2+json',
                        Authorization: 'Basic ' + btoa(`${superuserauth.username}:${superuserauth.password}`)
                    },
                });
            });
        });
    });
}