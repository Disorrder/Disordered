const HTTP_CODES = {
    OK: 200,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    RETRY_WITH: 449
}

// --- expand Object ---

Object.hidePrivate = (obj) => {
    let prefix = '_',
        privates = {};

    for (let k in obj) {
        if (k[0] === prefix) privates[k] = {enumerable: false}
    }

    Object.defineProperties(obj, privates)
    return obj;
}

Object.fixProperties = (obj) => {
    var properties = {}
    for (let k in obj) {
        properties[k] = {configurable: false}
    }

    Object.defineProperties(obj, properties)
    return obj;
}

Object.clear = (obj) => {
    // safe delete properties, deleting un-configurable properties throwing error!
    for (let k in obj) {
        try { delete obj[k] } catch(e) {}
    }
}

// --- Class methods ---

function _publicClassArguments(instance, argv) {
    var constructor = instance.constructor;
    if (typeof constructor !== 'function') return false;    
                                   // find 1st brackets        remove spaces      make array
    var args = constructor.toString().match(/\(([^()]*)\)/)[1].replace(/\s/g, '').split(',');

    _.each(args, (v, k) => {
        instance[v] = argv[k];
    });
    return true;
}
