    /* so replace it( -> xit( just disables anything but keeps those methods intact that were pending in the first place. */
        xxit = xit;
    
        /* Function.prototype.bind binds the this parameter which is wrong for the inner workings of it */
        Function.prototype.curry = function() {       
            function toArray(enm) {
                return Array.prototype.slice.call(enm);
            }
            if (arguments.length<1) {
                return this; //nothing to curry with - return function
            }
            var __method = this;
            var args = toArray(arguments);
            return function() {
                return __method.apply(this, args.concat(toArray(arguments)));
            }
        }
        
        /* setTimeout as a Promise. Mocha as a whole is good at dealing with promises */
        later = function (delay) {
            return new Promise(function(resolve) {
                setTimeout(resolve, delay);
            });
        }

module.exports = function(){};