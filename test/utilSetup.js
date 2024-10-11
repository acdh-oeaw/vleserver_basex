import { xit } from 'vitest';
// Replace xit with xxit to disable tests but keep pending methods intact
export const xxit = xit;

// Function.prototype.curry binds the this parameter which is wrong for the inner workings of it
export const functionAddCurry = () => Function.prototype.curry = function() {       
    function toArray(enm) {
        return Array.prototype.slice.call(enm);
    }
    if (arguments.length < 1) {
        return this; // nothing to curry with - return function
    }
    const __method = this;
    const args = toArray(arguments);
    return function() {
        return __method.apply(this, args.concat(toArray(arguments)));
    }
}

// setTimeout as a Promise. Vitest as a whole is good at dealing with promises
export const later = function(delay) {
    return new Promise(function(resolve) {
        setTimeout(resolve, delay);
    });
}

export const safeJSONParse = function (text, defaultValue = {}) {
    try {
        return JSON.parse(text);
    } catch (e) {
        return defaultValue;
    }
}