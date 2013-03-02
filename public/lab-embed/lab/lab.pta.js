(function() {
/**
 * almond 0.1.2 Copyright (c) 2011, The Dojo Foundation All Rights Reserved.
 * Available via the MIT or new BSD license.
 * see: http://github.com/jrburke/almond for details
 */
//Going sloppy to avoid 'use strict' string cost, but strict practices should
//be followed.
/*jslint sloppy: true */
/*global setTimeout: false */

var requirejs, require, define;
(function (undef) {
    var defined = {},
        waiting = {},
        config = {},
        defining = {},
        aps = [].slice,
        main, req;

    /**
     * Given a relative module name, like ./something, normalize it to
     * a real name that can be mapped to a path.
     * @param {String} name the relative name
     * @param {String} baseName a real name that the name arg is relative
     * to.
     * @returns {String} normalized name
     */
    function normalize(name, baseName) {
        var baseParts = baseName && baseName.split("/"),
            map = config.map,
            starMap = (map && map['*']) || {},
            nameParts, nameSegment, mapValue, foundMap,
            foundI, foundStarMap, starI, i, j, part;

        //Adjust any relative paths.
        if (name && name.charAt(0) === ".") {
            //If have a base name, try to normalize against it,
            //otherwise, assume it is a top-level require that will
            //be relative to baseUrl in the end.
            if (baseName) {
                //Convert baseName to array, and lop off the last part,
                //so that . matches that "directory" and not name of the baseName's
                //module. For instance, baseName of "one/two/three", maps to
                //"one/two/three.js", but we want the directory, "one/two" for
                //this normalization.
                baseParts = baseParts.slice(0, baseParts.length - 1);

                name = baseParts.concat(name.split("/"));

                //start trimDots
                for (i = 0; (part = name[i]); i++) {
                    if (part === ".") {
                        name.splice(i, 1);
                        i -= 1;
                    } else if (part === "..") {
                        if (i === 1 && (name[2] === '..' || name[0] === '..')) {
                            //End of the line. Keep at least one non-dot
                            //path segment at the front so it can be mapped
                            //correctly to disk. Otherwise, there is likely
                            //no path mapping for a path starting with '..'.
                            //This can still fail, but catches the most reasonable
                            //uses of ..
                            return true;
                        } else if (i > 0) {
                            name.splice(i - 1, 2);
                            i -= 2;
                        }
                    }
                }
                //end trimDots

                name = name.join("/");
            }
        }

        //Apply map config if available.
        if ((baseParts || starMap) && map) {
            nameParts = name.split('/');

            for (i = nameParts.length; i > 0; i -= 1) {
                nameSegment = nameParts.slice(0, i).join("/");

                if (baseParts) {
                    //Find the longest baseName segment match in the config.
                    //So, do joins on the biggest to smallest lengths of baseParts.
                    for (j = baseParts.length; j > 0; j -= 1) {
                        mapValue = map[baseParts.slice(0, j).join('/')];

                        //baseName segment has  config, find if it has one for
                        //this name.
                        if (mapValue) {
                            mapValue = mapValue[nameSegment];
                            if (mapValue) {
                                //Match, update name to the new value.
                                foundMap = mapValue;
                                foundI = i;
                                break;
                            }
                        }
                    }
                }

                if (foundMap) {
                    break;
                }

                //Check for a star map match, but just hold on to it,
                //if there is a shorter segment match later in a matching
                //config, then favor over this star map.
                if (!foundStarMap && starMap && starMap[nameSegment]) {
                    foundStarMap = starMap[nameSegment];
                    starI = i;
                }
            }

            if (!foundMap && foundStarMap) {
                foundMap = foundStarMap;
                foundI = starI;
            }

            if (foundMap) {
                nameParts.splice(0, foundI, foundMap);
                name = nameParts.join('/');
            }
        }

        return name;
    }

    function makeRequire(relName, forceSync) {
        return function () {
            //A version of a require function that passes a moduleName
            //value for items that may need to
            //look up paths relative to the moduleName
            return req.apply(undef, aps.call(arguments, 0).concat([relName, forceSync]));
        };
    }

    function makeNormalize(relName) {
        return function (name) {
            return normalize(name, relName);
        };
    }

    function makeLoad(depName) {
        return function (value) {
            defined[depName] = value;
        };
    }

    function callDep(name) {
        if (waiting.hasOwnProperty(name)) {
            var args = waiting[name];
            delete waiting[name];
            defining[name] = true;
            main.apply(undef, args);
        }

        if (!defined.hasOwnProperty(name)) {
            throw new Error('No ' + name);
        }
        return defined[name];
    }

    /**
     * Makes a name map, normalizing the name, and using a plugin
     * for normalization if necessary. Grabs a ref to plugin
     * too, as an optimization.
     */
    function makeMap(name, relName) {
        var prefix, plugin,
            index = name.indexOf('!');

        if (index !== -1) {
            prefix = normalize(name.slice(0, index), relName);
            name = name.slice(index + 1);
            plugin = callDep(prefix);

            //Normalize according
            if (plugin && plugin.normalize) {
                name = plugin.normalize(name, makeNormalize(relName));
            } else {
                name = normalize(name, relName);
            }
        } else {
            name = normalize(name, relName);
        }

        //Using ridiculous property names for space reasons
        return {
            f: prefix ? prefix + '!' + name : name, //fullName
            n: name,
            p: plugin
        };
    }

    function makeConfig(name) {
        return function () {
            return (config && config.config && config.config[name]) || {};
        };
    }

    main = function (name, deps, callback, relName) {
        var args = [],
            usingExports,
            cjsModule, depName, ret, map, i;

        //Use name if no relName
        relName = relName || name;

        //Call the callback to define the module, if necessary.
        if (typeof callback === 'function') {

            //Pull out the defined dependencies and pass the ordered
            //values to the callback.
            //Default to [require, exports, module] if no deps
            deps = !deps.length && callback.length ? ['require', 'exports', 'module'] : deps;
            for (i = 0; i < deps.length; i++) {
                map = makeMap(deps[i], relName);
                depName = map.f;

                //Fast path CommonJS standard dependencies.
                if (depName === "require") {
                    args[i] = makeRequire(name);
                } else if (depName === "exports") {
                    //CommonJS module spec 1.1
                    args[i] = defined[name] = {};
                    usingExports = true;
                } else if (depName === "module") {
                    //CommonJS module spec 1.1
                    cjsModule = args[i] = {
                        id: name,
                        uri: '',
                        exports: defined[name],
                        config: makeConfig(name)
                    };
                } else if (defined.hasOwnProperty(depName) || waiting.hasOwnProperty(depName)) {
                    args[i] = callDep(depName);
                } else if (map.p) {
                    map.p.load(map.n, makeRequire(relName, true), makeLoad(depName), {});
                    args[i] = defined[depName];
                } else if (!defining[depName]) {
                    throw new Error(name + ' missing ' + depName);
                }
            }

            ret = callback.apply(defined[name], args);

            if (name) {
                //If setting exports via "module" is in play,
                //favor that over return value and exports. After that,
                //favor a non-undefined return value over exports use.
                if (cjsModule && cjsModule.exports !== undef &&
                    cjsModule.exports !== defined[name]) {
                    defined[name] = cjsModule.exports;
                } else if (ret !== undef || !usingExports) {
                    //Use the return value from the function.
                    defined[name] = ret;
                }
            }
        } else if (name) {
            //May just be an object definition for the module. Only
            //worry about defining if have a module name.
            defined[name] = callback;
        }
    };

    requirejs = require = req = function (deps, callback, relName, forceSync) {
        if (typeof deps === "string") {
            //Just return the module wanted. In this scenario, the
            //deps arg is the module name, and second arg (if passed)
            //is just the relName.
            //Normalize module name, if it contains . or ..
            return callDep(makeMap(deps, callback).f);
        } else if (!deps.splice) {
            //deps is a config object, not an array.
            config = deps;
            if (callback.splice) {
                //callback is an array, which means it is a dependency list.
                //Adjust args if there are dependencies
                deps = callback;
                callback = relName;
                relName = null;
            } else {
                deps = undef;
            }
        }

        //Support require(['a'])
        callback = callback || function () {};

        //Simulate async callback;
        if (forceSync) {
            main(undef, deps, callback, relName);
        } else {
            setTimeout(function () {
                main(undef, deps, callback, relName);
            }, 15);
        }

        return req;
    };

    /**
     * Just drops the config on the floor, but returns req in case
     * the config return value is used.
     */
    req.config = function (cfg) {
        config = cfg;
        return req;
    };

    define = function (name, deps, callback) {

        //This module may not have dependencies
        if (!deps.splice) {
            //deps is not an array, so probably means
            //an object literal or factory function for
            //the value. Adjust args.
            callback = deps;
            deps = [];
        }

        waiting[name] = [name, deps, callback];
    };

    define.amd = {
        jQuery: true
    };
}());

define("../vendor/almond/almond", function(){});

/*global define: false */

define('common/actual-root',['require'],function (require) {
  // Dependencies.
  var staticResourceMatch = new RegExp("(\\/.*?)\\/(doc|examples|experiments)(\\/\\w+)*?\\/\\w+\\.html"),
      // String to be returned.
      value;

  function actualRoot() {
    var match = document.location.pathname.match(staticResourceMatch);
    if (match && match[1]) {
      return match[1]
    } else {
      return ""
    }
  }

  value = actualRoot();
  return value;
});

// this file is generated during build process by: ./script/generate-js-config.rb
define('lab.config',['require','common/actual-root'],function (require) {
  var actualRoot = require('common/actual-root'),
      publicAPI;
  publicAPI = {
  "sharing": true,
  "logging": true,
  "tracing": false,
  "home": "http://lab.concord.org",
  "homeInteractivePath": "/examples/interactives/interactive.html",
  "homeEmbeddablePath": "/examples/interactives/embeddable.html",
  "actualRoot": "",
  "utmCampaign": null,
  "authoring": false
};
  publicAPI.actualRoot = actualRoot;
  return publicAPI;
});

/*global window Uint8Array Uint8ClampedArray Int8Array Uint16Array Int16Array Uint32Array Int32Array Float32Array Float64Array */
/*jshint newcap: false */

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. R.JS Optimizer will strip out this if statement.


define('arrays/index',['require','exports','module'],function (require, exports, module) {
  var arrays = {};

  arrays.version = '0.0.1';

  arrays.webgl = (typeof window !== 'undefined') && !!window.WebGLRenderingContext;

  arrays.typed = (function() {
    try {
      new Float64Array(0);
      return true;
    } catch(e) {
      return false;
    }
  }());

  // http://www.khronos.org/registry/typedarray/specs/latest/#TYPEDARRAYS
  // regular
  // Uint8Array
  // Uint8ClampedArray
  // Uint16Array
  // Uint32Array
  // Int8Array
  // Int16Array
  // Int32Array
  // Float32Array
  // Float64Array

  arrays.create = function(size, fill, array_type) {
    if (!array_type) {
      if (arrays.webgl || arrays.typed) {
        array_type = "Float32Array";
      } else {
        array_type = "regular";
      }
    }
    if (fill === undefined) {
      fill = 0;
    }
    var a, i;
    if (array_type === "regular") {
      a = new Array(size);
    } else {
      switch(array_type) {
        case "Float64Array":
          a = new Float64Array(size);
          break;
        case "Float32Array":
          a = new Float32Array(size);
          break;
        case "Int32Array":
          a = new Int32Array(size);
          break;
        case "Int16Array":
          a = new Int16Array(size);
          break;
        case "Int8Array":
          a = new Int8Array(size);
          break;
        case "Uint32Array":
          a = new Uint32Array(size);
          break;
        case "Uint16Array":
          a = new Uint16Array(size);
          break;
        case "Uint8Array":
          a = new Uint8Array(size);
          break;
        case "Uint8ClampedArray":
          a = new Uint8ClampedArray(size);
          break;
        default:
          throw new Error("arrays: couldn't understand array type \"" + array_type + "\".");
      }
    }
    i=-1; while(++i < size) { a[i] = fill; }
    return a;
  };

  arrays.constructor_function = function(source) {
    if (source.buffer &&
        source.buffer.__proto__ &&
        source.buffer.__proto__.constructor &&
        Object.prototype.toString.call(source) === "[object Array]") {
      return source.__proto__.constructor;
    }

    switch(source.constructor) {
      case Array:             return Array;
      case Float32Array:      return Float32Array;
      case Uint8Array:        return Uint8Array;
      case Float64Array:      return Float64Array;
      case Int32Array:        return Int32Array;
      case Int16Array:        return Int16Array;
      case Int8Array:         return Int8Array;
      case Uint32Array:       return Uint32Array;
      case Uint16Array:       return Uint16Array;
      case Uint8ClampedArray: return Uint8ClampedArray;
      default:
        throw new Error(
            "arrays.constructor_function: must be an Array or Typed Array: " + "  source: " + source);
            // ", source.constructor: " + source.constructor +
            // ", source.buffer: " + source.buffer +
            // ", source.buffer.slice: " + source.buffer.slice +
            // ", source.buffer.__proto__: " + source.buffer.__proto__ +
            // ", source.buffer.__proto__.constructor: " + source.buffer.__proto__.constructor
      }
  };

  arrays.copy = function(source, dest) {
    var len = source.length,
        i = -1;
    while(++i < len) { dest[i] = source[i]; }
    if (arrays.constructor_function(dest) === Array) dest.length = len;
    return dest;
  };

  arrays.clone = function(source) {
    var i, len = source.length, clone, constructor;
    constructor = arrays.constructor_function(source);
    if (constructor === Array) {
      clone = new constructor(len);
      for (i = 0; i < len; i++) { clone[i] = source[i]; }
      return clone;
    }
    if (source.buffer.slice) {
      clone = new constructor(source.buffer.slice(0));
      return clone;
    }
    clone = new constructor(len);
    for (i = 0; i < len; i++) { clone[i] = source[i]; }
    return clone;
  };

  /** @return true if x is between a and b. */
  // float a, float b, float x
  arrays.between = function(a, b, x) {
    return x < Math.max(a, b) && x > Math.min(a, b);
  };

  // float[] array
  arrays.max = function(array) {
    return Math.max.apply( Math, array );
  };

  // float[] array
  arrays.min = function(array) {
    return Math.min.apply( Math, array );
  };

  // FloatxxArray[] array
  arrays.maxTypedArray = function(array) {
    var test, i,
    max = Number.MIN_VALUE,
    length = array.length;
    for(i = 0; i < length; i++) {
      test = array[i];
      max = test > max ? test : max;
    }
    return max;
  };

  // FloatxxArray[] array
  arrays.minTypedArray = function(array) {
    var test, i,
    min = Number.MAX_VALUE,
    length = array.length;
    for(i = 0; i < length; i++) {
      test = array[i];
      min = test < min ? test : min;
    }
    return min;
  };

  // float[] array
  arrays.maxAnyArray = function(array) {
    try {
      return Math.max.apply( Math, array );
    }
    catch (e) {
      if (e instanceof TypeError) {
        var test, i,
        max = Number.MIN_VALUE,
        length = array.length;
        for(i = 0; i < length; i++) {
          test = array[i];
          max = test > max ? test : max;
        }
        return max;
      }
    }
  };

  // float[] array
  arrays.minAnyArray = function(array) {
    try {
      return Math.min.apply( Math, array );
    }
    catch (e) {
      if (e instanceof TypeError) {
        var test, i,
        min = Number.MAX_VALUE,
        length = array.length;
        for(i = 0; i < length; i++) {
          test = array[i];
          min = test < min ? test : min;
        }
        return min;
      }
    }
  };

  arrays.average = function(array) {
    var i, acc = 0,
    length = array.length;
    for (i = 0; i < length; i++) {
      acc += array[i];
    }
    return acc / length;
  };

  /**
    Create a new array of the same type as 'array' and of length 'newLength', and copies as many
    elements from 'array' to the new array as is possible.

    If 'newLength' is less than 'array.length', and 'array' is  a typed array, we still allocate a
    new, shorter array in order to allow GC to work.

    The returned array should always take the place of the passed-in 'array' in client code, and this
    method should not be counted on to always return a copy. If 'array' is non-typed, we manipulate
    its length instead of copying it. But if 'array' is typed, we cannot increase its size in-place,
    therefore must pas a *new* object reference back to client code.
  */
  arrays.extend = function(array, newLength) {
    var extendedArray,
        Constructor,
        i;

    Constructor = arrays.constructor_function(array);

    if (Constructor === Array) {
      i = array.length;
      array.length = newLength;
      // replicate behavior of typed-arrays by filling with 0
      for(;i < newLength; i++) { array[i] = 0; }
      return array;
    }

    extendedArray = new Constructor(newLength);

    // prevent 'set' method from erroring when array.length > newLength, by using the (no-copy) method
    // 'subarray' to get an array view that is clamped to length = min(array.length, newLength)
    extendedArray.set(array.subarray(0, newLength));

    return extendedArray;
  };

  arrays.remove = function(array, idx) {
    var constructor = arrays.constructor_function(array),
        rest;

    if (constructor !== Array) {
      throw new Error("arrays.remove for typed arrays not implemented yet.");
    }

    rest = array.slice(idx + 1);
    array.length = idx;
    Array.prototype.push.apply(array, rest);

    return array;
  };

  arrays.isArray = function (object) {
    if (object === undefined || object === null) {
      return false;
    }
    switch(Object.prototype.toString.call(object)) {
      case "[object Array]":
      case "[object Float32Array]":
      case "[object Float64Array]":
      case "[object Uint8Array]":
      case "[object Uint16Array]":
      case "[object Uint32Array]":
      case "[object Uint8ClampedArray]":
      case "[object Int8Array]":
      case "[object Int16Array]":
      case "[object Int32Array]":
        return true;
      default:
        return false;
    }
  };

  // publish everything to exports
  for (var key in arrays) {
    if (arrays.hasOwnProperty(key)) exports[key] = arrays[key];
  }
});

define('arrays', ['arrays/index'], function (main) { return main; });

/*global define: false console: true */

define('common/console',['require','lab.config'],function (require) {
  // Dependencies.
  var labConfig = require('lab.config'),

      // Object to be returned.
      publicAPI,
      cons,
      emptyFunction = function () {};

  // Prevent a console.log from blowing things up if we are on a browser that
  // does not support it ... like IE9.
  if (typeof console === 'undefined') {
    console = {};
    if (window) window.console = console;
  }
  // Assign shortcut.
  cons = console;
  // Make sure that every method is defined.
  if (cons.log === undefined)
    cons.log = emptyFunction;
  if (cons.info === undefined)
    cons.info = emptyFunction;
  if (cons.warn === undefined)
    cons.warn = emptyFunction;
  if (cons.error === undefined)
    cons.error = emptyFunction;
  if (cons.time === undefined)
    cons.time = emptyFunction;
  if (cons.timeEnd === undefined)
    cons.timeEnd = emptyFunction;

  publicAPI = {
    log: function () {
      if (labConfig.logging)
        cons.log.apply(cons, arguments);
    },
    info: function () {
      if (labConfig.logging)
        cons.info.apply(cons, arguments);
    },
    warn: function () {
      if (labConfig.logging)
        cons.warn.apply(cons, arguments);
    },
    error: function () {
      if (labConfig.logging)
        cons.error.apply(cons, arguments);
    },
    time: function () {
      if (labConfig.tracing)
        cons.time.apply(cons, arguments);
    },
    timeEnd: function () {
      if (labConfig.tracing)
        cons.timeEnd.apply(cons, arguments);
    }
  };

  return publicAPI;
});

/*global define: false alert: false */

/**
  Tiny module providing global way to show errors to user.

  It's better to use module, as in the future, we may want to replace basic
  alert with more sophisticated solution (for example jQuery UI dialog).
*/
define('common/alert',['require','common/console'],function (require) {
  // Dependencies.
  var console = require('common/console'),

      // Try to use global alert. If it's not available, use console.error (node.js).
      alertFunc = typeof alert !== 'undefined' ? alert : console.error;

  return function alert(msg) {
    alertFunc(msg);
  };
});

/*global define: false */

define('common/controllers/interactive-metadata',[],function() {

  return {
    /**
      Interactive top-level properties:
    */
    interactive: {
      title: {
        required: true
      },

      publicationStatus: {
        defaultValue: "public"
      },

      subtitle: {
        defaultValue: ""
      },

      about: {
        defaultValue: ""
      },

      models: {
        // List of model definitions. Its definition is below ('model').
        required: true
      },

      parameters: {
        // List of custom parameters.
        defaultValue: []
      },

      outputs: {
        // List of outputs.
        defaultValue: []
      },

      filteredOutputs: {
        // List of filtered outputs.
        defaultValue: []
      },

      exports: {
        required: false
      },

      components: {
        // List of the interactive components. Their definitions are below ('button', 'checkbox' etc.).
        defaultValue: []
      },

      layout: {
        // Layout definition.
        defaultValue: {}
      },

      template: {
        // Layout template definition.
        defaultValue: "simple"
      }
    },

    model: {
      // Definition of a model. Note that it is *NOT* a physical model options hash.
      // It includes a URL to physical model options.
      id: {
        required: true
      },
      url: {
        required: true
      },
      // Optional "onLoad" script.
      onLoad: {},
      // Optional hash of options overwriting model options.
      viewOptions: {},
      modelOptions: {},
      // Parameters, outputs and filtered outputs can be also specified per model.
      parameters: {},
      outputs: {},
      filteredOutputs: {}
    },

    parameter: {
      name: {
        required: true
      },
      initialValue: {
        required: true
      },
      // Optional "onChange" script.
      onChange: {},
      // Optional description.
      label: {},
      units: {}
    },

    output: {
      name: {
        required: true
      },
      value: {
        required: true
      },
      // Optional description.
      label: {},
      units: {}
    },

    filteredOutput: {
      name: {
        required: true
      },
      property: {
        required: true
      },
      type: {
        // For now, only "RunningAverage" is supported.
        required: true
      },
      period: {
        // Smoothing time period in ps.
        // e.g. 2500
        required: true
      },
      // Optional description.
      label: {},
      units: {}
    },

    exports: {
      perRun: {
        required: false,
        defaultValue: []
      },
      perTick: {
        required: true
      }
    },

    /**
      Interactive components:
    */
    button: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      action: {
        required: true
      },
      text: {
        defaultValue: ""
      }
    },

    checkbox: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      text: {
        defaultValue: ""
      },
      property: {},
      onClick: {},
      // Note that 'initialValue' makes sense only for checkboxes without property binding.
      initialValue: {}
    },

    slider: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      min: {
        required: true
      },
      max: {
        required: true
      },
      steps: {
        required: true
      },
      title: {
        defaultValue: ""
      },
      labels: {
        defaultValue: []
      },
      width: {
        defaultValue: "12em"
      },
      height: {
        defaultValue: "1em"
      },
      displayValue: {},
      property: {},
      action: {},
      initialValue: {}
    },

    pulldown: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      options: {
        defaultValue: []
      }
    },

    pulldownOption: {
      text: {
        defaultValue: ""
      },
      disabled: {},
      selected: {},
      action: {},
      loadModel: {}
    },

    radio: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      orientation: {
        defaultValue: "vertical"
      },
      options: {
        defaultValue: []
      }
    },

    radioOption: {
      text: {
        defaultValue: ""
      },
      disabled: {},
      selected: {},
      action: {},
      loadModel: {}
    },

    numericOutput: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      label: {
        defaultValue: ""
      },
      units: {
        defaultValue: ""
      },
      property: {},
      displayValue: {}
    },

    thermometer: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      min: {
        required: true
      },
      max: {
        required: true
      },
      labelIsReading: {
        defaultValue: false
      },
      reading: {
        defaultValue: {
          units: "K",
          offset: 0,
          scale: 1,
          digits: 0
        }
      }
    },

    graph: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      properties: {
        defaultValue: []
      },
      title: {
        defaultValue: "Graph"
      },
      width: {
        defaultValue: "100%"
      },
      height: {
        defaultValue: "100%"
      },
      xlabel: {
        defaultValue: "Model Time (ps)"
      },
      xmin: {
        defaultValue: 0
      },
      xmax: {
        defaultValue: 20
      },
      ylabel: {
        defaultValue: ""
      },
      ymin: {
        defaultValue: 0
      },
      ymax: {
        defaultValue: 10
      }
    },

    barGraph: {
      id: {
        required: true
      },
      type: {
        required: true
      },
      property: {
        required: true
      },
      width: {
        defaultValue: "100%"
      },
      height: {
        defaultValue: "100%"
      },
      options: {
        defaultValue: {
          // Min value displayed.
          minValue:  0,
          // Max value displayed.
          maxValue:  10,
          // Graph title.
          title:     "",
          // Color of the main bar.
          barColor:  "green",
          // Color of the area behind the bar.
          fillColor: "white",
          // Color of axis, labels, title.
          textColor: "#555",
          // Number of ticks displayed on the axis.
          // This value is *only* a suggestion. The most clean
          // and human-readable values are used.
          ticks:          10,
          // Number of subdivisions between major ticks.
          tickSubdivide: 1,
          // Enables or disables displaying of numerical labels.
          displayLabels: true,
          // Format of labels.
          // See the specification of this format:
          // https://github.com/mbostock/d3/wiki/Formatting#wiki-d3_format
          // or:
          // http://docs.python.org/release/3.1.3/library/string.html#formatspec
          labelFormat: "0.1f"
        }
      }
    }
  };
});

/*global define: false, $: false */

// For now, only defaultValue, readOnly and immutable
// meta-properties are supported.
define('common/validator',['require','arrays'],function(require) {

  var arrays = require('arrays');

  // Create a new object, that prototypically inherits from the Error constructor.
  // It provides a direct information which property of the input caused an error.
  function ValidationError(prop, message) {
      this.prop = prop;
      this.message = message;
  }
  ValidationError.prototype = new Error();
  ValidationError.prototype.constructor = ValidationError;

  return {

    // Basic validation.
    // Check if provided 'input' hash doesn't try to overwrite properties
    // which are marked as read-only or immutable. Don't take into account
    // 'defaultValue' as the 'input' hash is allowed to be incomplete.
    // It should be used *only* for update of an object.
    // While creating new object, use validateCompleteness() instead!
    validate: function (metadata, input, ignoreImmutable) {
      var result = {},
          prop, propMetadata;

      if (arguments.length < 2) {
        throw new Error("Incorrect usage. Provide metadata and hash which should be validated.");
      }

      for (prop in input) {
        if (input.hasOwnProperty(prop)) {
          // Try to get meta-data for this property.
          propMetadata = metadata[prop];
          // Continue only if the property is listed in meta-data.
          if (propMetadata !== undefined) {
            // Check if this is readOnly property.
            if (propMetadata.readOnly === true) {
              throw new ValidationError(prop, "Properties set tries to overwrite read-only property " + prop);
            }
            if (!ignoreImmutable && propMetadata.immutable === true) {
              throw new ValidationError(prop, "Properties set tries to overwrite immutable property " + prop);
            }
            result[prop] = input[prop];
          }
        }
      }
      return result;
    },

    // Complete validation.
    // Assume that provided 'input' hash is used for creation of new
    // object. Start with checking if all required values are provided,
    // and using default values if they are provided.
    // Later perform basic validation.
    validateCompleteness: function (metadata, input) {
      var result = {},
          prop, propMetadata;

      if (arguments.length < 2) {
        throw new Error("Incorrect usage. Provide metadata and hash which should be validated.");
      }

      for (prop in metadata) {
        if (metadata.hasOwnProperty(prop)) {
          propMetadata = metadata[prop];

          if (input[prop] === undefined || input[prop] === null) {
            // Value is not declared in the input data.
            if (propMetadata.required === true) {
              throw new ValidationError(prop, "Properties set is missing required property " + prop);
            } else if (arrays.isArray(propMetadata.defaultValue)) {
              // Copy an array defined as a default value.
              // Do not use instance defined in metadata.
              result[prop] = arrays.copy(propMetadata.defaultValue, []);
            } else if (typeof propMetadata.defaultValue === "object") {
              // Copy an object defined as a default value.
              // Do not use instance defined in metadata.
              result[prop] = $.extend(true, {}, propMetadata.defaultValue);
            } else if (propMetadata.defaultValue !== undefined) {
              // If it's basic type, just set value.
              result[prop] = propMetadata.defaultValue;
            }
          } else if (!arrays.isArray(input[prop]) && typeof input[prop] === "object" && typeof propMetadata.defaultValue === "object") {
            // Note that typeof [] is also "object" - that is the reason of the isArray() check.
            result[prop] = $.extend(true, {}, propMetadata.defaultValue, input[prop]);
          } else if (arrays.isArray(input[prop])) {
            // Deep copy of an array.
            result[prop] = $.extend(true, [], input[prop]);
          } else {
            // Basic type like number, so '=' is enough.
            result[prop] = input[prop];
          }
        }
      }

      // Perform standard check like for hash meant to update object.
      // However, ignore immutable check, as these properties are supposed
      // to create a new object.
      return this.validate(metadata, result, true);
    },

    // Expose ValidationError. It can be useful for the custom validation routines.
    ValidationError: ValidationError
  };
});

//     Underscore.js 1.4.2
//     http://underscorejs.org
//     (c) 2009-2012 Jeremy Ashkenas, DocumentCloud Inc.
//     Underscore may be freely distributed under the MIT license.

(function() {

  // Baseline setup
  // --------------

  // Establish the root object, `window` in the browser, or `global` on the server.
  var root = this;

  // Save the previous value of the `_` variable.
  var previousUnderscore = root._;

  // Establish the object that gets returned to break out of a loop iteration.
  var breaker = {};

  // Save bytes in the minified (but not gzipped) version:
  var ArrayProto = Array.prototype, ObjProto = Object.prototype, FuncProto = Function.prototype;

  // Create quick reference variables for speed access to core prototypes.
  var push             = ArrayProto.push,
      slice            = ArrayProto.slice,
      concat           = ArrayProto.concat,
      unshift          = ArrayProto.unshift,
      toString         = ObjProto.toString,
      hasOwnProperty   = ObjProto.hasOwnProperty;

  // All **ECMAScript 5** native function implementations that we hope to use
  // are declared here.
  var
    nativeForEach      = ArrayProto.forEach,
    nativeMap          = ArrayProto.map,
    nativeReduce       = ArrayProto.reduce,
    nativeReduceRight  = ArrayProto.reduceRight,
    nativeFilter       = ArrayProto.filter,
    nativeEvery        = ArrayProto.every,
    nativeSome         = ArrayProto.some,
    nativeIndexOf      = ArrayProto.indexOf,
    nativeLastIndexOf  = ArrayProto.lastIndexOf,
    nativeIsArray      = Array.isArray,
    nativeKeys         = Object.keys,
    nativeBind         = FuncProto.bind;

  // Create a safe reference to the Underscore object for use below.
  var _ = function(obj) {
    if (obj instanceof _) return obj;
    if (!(this instanceof _)) return new _(obj);
    this._wrapped = obj;
  };

  // Export the Underscore object for **Node.js**, with
  // backwards-compatibility for the old `require()` API. If we're in
  // the browser, add `_` as a global object via a string identifier,
  // for Closure Compiler "advanced" mode.
  if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports) {
      exports = module.exports = _;
    }
    exports._ = _;
  } else {
    root['_'] = _;
  }

  // Current version.
  _.VERSION = '1.4.2';

  // Collection Functions
  // --------------------

  // The cornerstone, an `each` implementation, aka `forEach`.
  // Handles objects with the built-in `forEach`, arrays, and raw objects.
  // Delegates to **ECMAScript 5**'s native `forEach` if available.
  var each = _.each = _.forEach = function(obj, iterator, context) {
    if (obj == null) return;
    if (nativeForEach && obj.forEach === nativeForEach) {
      obj.forEach(iterator, context);
    } else if (obj.length === +obj.length) {
      for (var i = 0, l = obj.length; i < l; i++) {
        if (iterator.call(context, obj[i], i, obj) === breaker) return;
      }
    } else {
      for (var key in obj) {
        if (_.has(obj, key)) {
          if (iterator.call(context, obj[key], key, obj) === breaker) return;
        }
      }
    }
  };

  // Return the results of applying the iterator to each element.
  // Delegates to **ECMAScript 5**'s native `map` if available.
  _.map = _.collect = function(obj, iterator, context) {
    var results = [];
    if (obj == null) return results;
    if (nativeMap && obj.map === nativeMap) return obj.map(iterator, context);
    each(obj, function(value, index, list) {
      results[results.length] = iterator.call(context, value, index, list);
    });
    return results;
  };

  // **Reduce** builds up a single result from a list of values, aka `inject`,
  // or `foldl`. Delegates to **ECMAScript 5**'s native `reduce` if available.
  _.reduce = _.foldl = _.inject = function(obj, iterator, memo, context) {
    var initial = arguments.length > 2;
    if (obj == null) obj = [];
    if (nativeReduce && obj.reduce === nativeReduce) {
      if (context) iterator = _.bind(iterator, context);
      return initial ? obj.reduce(iterator, memo) : obj.reduce(iterator);
    }
    each(obj, function(value, index, list) {
      if (!initial) {
        memo = value;
        initial = true;
      } else {
        memo = iterator.call(context, memo, value, index, list);
      }
    });
    if (!initial) throw new TypeError('Reduce of empty array with no initial value');
    return memo;
  };

  // The right-associative version of reduce, also known as `foldr`.
  // Delegates to **ECMAScript 5**'s native `reduceRight` if available.
  _.reduceRight = _.foldr = function(obj, iterator, memo, context) {
    var initial = arguments.length > 2;
    if (obj == null) obj = [];
    if (nativeReduceRight && obj.reduceRight === nativeReduceRight) {
      if (context) iterator = _.bind(iterator, context);
      return arguments.length > 2 ? obj.reduceRight(iterator, memo) : obj.reduceRight(iterator);
    }
    var length = obj.length;
    if (length !== +length) {
      var keys = _.keys(obj);
      length = keys.length;
    }
    each(obj, function(value, index, list) {
      index = keys ? keys[--length] : --length;
      if (!initial) {
        memo = obj[index];
        initial = true;
      } else {
        memo = iterator.call(context, memo, obj[index], index, list);
      }
    });
    if (!initial) throw new TypeError('Reduce of empty array with no initial value');
    return memo;
  };

  // Return the first value which passes a truth test. Aliased as `detect`.
  _.find = _.detect = function(obj, iterator, context) {
    var result;
    any(obj, function(value, index, list) {
      if (iterator.call(context, value, index, list)) {
        result = value;
        return true;
      }
    });
    return result;
  };

  // Return all the elements that pass a truth test.
  // Delegates to **ECMAScript 5**'s native `filter` if available.
  // Aliased as `select`.
  _.filter = _.select = function(obj, iterator, context) {
    var results = [];
    if (obj == null) return results;
    if (nativeFilter && obj.filter === nativeFilter) return obj.filter(iterator, context);
    each(obj, function(value, index, list) {
      if (iterator.call(context, value, index, list)) results[results.length] = value;
    });
    return results;
  };

  // Return all the elements for which a truth test fails.
  _.reject = function(obj, iterator, context) {
    return _.filter(obj, function(value, index, list) {
      return !iterator.call(context, value, index, list);
    }, context);
  };

  // Determine whether all of the elements match a truth test.
  // Delegates to **ECMAScript 5**'s native `every` if available.
  // Aliased as `all`.
  _.every = _.all = function(obj, iterator, context) {
    iterator || (iterator = _.identity);
    var result = true;
    if (obj == null) return result;
    if (nativeEvery && obj.every === nativeEvery) return obj.every(iterator, context);
    each(obj, function(value, index, list) {
      if (!(result = result && iterator.call(context, value, index, list))) return breaker;
    });
    return !!result;
  };

  // Determine if at least one element in the object matches a truth test.
  // Delegates to **ECMAScript 5**'s native `some` if available.
  // Aliased as `any`.
  var any = _.some = _.any = function(obj, iterator, context) {
    iterator || (iterator = _.identity);
    var result = false;
    if (obj == null) return result;
    if (nativeSome && obj.some === nativeSome) return obj.some(iterator, context);
    each(obj, function(value, index, list) {
      if (result || (result = iterator.call(context, value, index, list))) return breaker;
    });
    return !!result;
  };

  // Determine if the array or object contains a given value (using `===`).
  // Aliased as `include`.
  _.contains = _.include = function(obj, target) {
    if (obj == null) return false;
    if (nativeIndexOf && obj.indexOf === nativeIndexOf) return obj.indexOf(target) != -1;
    return any(obj, function(value) {
      return value === target;
    });
  };

  // Invoke a method (with arguments) on every item in a collection.
  _.invoke = function(obj, method) {
    var args = slice.call(arguments, 2);
    return _.map(obj, function(value) {
      return (_.isFunction(method) ? method : value[method]).apply(value, args);
    });
  };

  // Convenience version of a common use case of `map`: fetching a property.
  _.pluck = function(obj, key) {
    return _.map(obj, function(value){ return value[key]; });
  };

  // Convenience version of a common use case of `filter`: selecting only objects
  // with specific `key:value` pairs.
  _.where = function(obj, attrs) {
    if (_.isEmpty(attrs)) return [];
    return _.filter(obj, function(value) {
      for (var key in attrs) {
        if (attrs[key] !== value[key]) return false;
      }
      return true;
    });
  };

  // Return the maximum element or (element-based computation).
  // Can't optimize arrays of integers longer than 65,535 elements.
  // See: https://bugs.webkit.org/show_bug.cgi?id=80797
  _.max = function(obj, iterator, context) {
    if (!iterator && _.isArray(obj) && obj[0] === +obj[0] && obj.length < 65535) {
      return Math.max.apply(Math, obj);
    }
    if (!iterator && _.isEmpty(obj)) return -Infinity;
    var result = {computed : -Infinity};
    each(obj, function(value, index, list) {
      var computed = iterator ? iterator.call(context, value, index, list) : value;
      computed >= result.computed && (result = {value : value, computed : computed});
    });
    return result.value;
  };

  // Return the minimum element (or element-based computation).
  _.min = function(obj, iterator, context) {
    if (!iterator && _.isArray(obj) && obj[0] === +obj[0] && obj.length < 65535) {
      return Math.min.apply(Math, obj);
    }
    if (!iterator && _.isEmpty(obj)) return Infinity;
    var result = {computed : Infinity};
    each(obj, function(value, index, list) {
      var computed = iterator ? iterator.call(context, value, index, list) : value;
      computed < result.computed && (result = {value : value, computed : computed});
    });
    return result.value;
  };

  // Shuffle an array.
  _.shuffle = function(obj) {
    var rand;
    var index = 0;
    var shuffled = [];
    each(obj, function(value) {
      rand = _.random(index++);
      shuffled[index - 1] = shuffled[rand];
      shuffled[rand] = value;
    });
    return shuffled;
  };

  // An internal function to generate lookup iterators.
  var lookupIterator = function(value) {
    return _.isFunction(value) ? value : function(obj){ return obj[value]; };
  };

  // Sort the object's values by a criterion produced by an iterator.
  _.sortBy = function(obj, value, context) {
    var iterator = lookupIterator(value);
    return _.pluck(_.map(obj, function(value, index, list) {
      return {
        value : value,
        index : index,
        criteria : iterator.call(context, value, index, list)
      };
    }).sort(function(left, right) {
      var a = left.criteria;
      var b = right.criteria;
      if (a !== b) {
        if (a > b || a === void 0) return 1;
        if (a < b || b === void 0) return -1;
      }
      return left.index < right.index ? -1 : 1;
    }), 'value');
  };

  // An internal function used for aggregate "group by" operations.
  var group = function(obj, value, context, behavior) {
    var result = {};
    var iterator = lookupIterator(value);
    each(obj, function(value, index) {
      var key = iterator.call(context, value, index, obj);
      behavior(result, key, value);
    });
    return result;
  };

  // Groups the object's values by a criterion. Pass either a string attribute
  // to group by, or a function that returns the criterion.
  _.groupBy = function(obj, value, context) {
    return group(obj, value, context, function(result, key, value) {
      (_.has(result, key) ? result[key] : (result[key] = [])).push(value);
    });
  };

  // Counts instances of an object that group by a certain criterion. Pass
  // either a string attribute to count by, or a function that returns the
  // criterion.
  _.countBy = function(obj, value, context) {
    return group(obj, value, context, function(result, key, value) {
      if (!_.has(result, key)) result[key] = 0;
      result[key]++;
    });
  };

  // Use a comparator function to figure out the smallest index at which
  // an object should be inserted so as to maintain order. Uses binary search.
  _.sortedIndex = function(array, obj, iterator, context) {
    iterator = iterator == null ? _.identity : lookupIterator(iterator);
    var value = iterator.call(context, obj);
    var low = 0, high = array.length;
    while (low < high) {
      var mid = (low + high) >>> 1;
      iterator.call(context, array[mid]) < value ? low = mid + 1 : high = mid;
    }
    return low;
  };

  // Safely convert anything iterable into a real, live array.
  _.toArray = function(obj) {
    if (!obj) return [];
    if (obj.length === +obj.length) return slice.call(obj);
    return _.values(obj);
  };

  // Return the number of elements in an object.
  _.size = function(obj) {
    if (obj == null) return 0;
    return (obj.length === +obj.length) ? obj.length : _.keys(obj).length;
  };

  // Array Functions
  // ---------------

  // Get the first element of an array. Passing **n** will return the first N
  // values in the array. Aliased as `head` and `take`. The **guard** check
  // allows it to work with `_.map`.
  _.first = _.head = _.take = function(array, n, guard) {
    if (array == null) return void 0;
    return (n != null) && !guard ? slice.call(array, 0, n) : array[0];
  };

  // Returns everything but the last entry of the array. Especially useful on
  // the arguments object. Passing **n** will return all the values in
  // the array, excluding the last N. The **guard** check allows it to work with
  // `_.map`.
  _.initial = function(array, n, guard) {
    return slice.call(array, 0, array.length - ((n == null) || guard ? 1 : n));
  };

  // Get the last element of an array. Passing **n** will return the last N
  // values in the array. The **guard** check allows it to work with `_.map`.
  _.last = function(array, n, guard) {
    if (array == null) return void 0;
    if ((n != null) && !guard) {
      return slice.call(array, Math.max(array.length - n, 0));
    } else {
      return array[array.length - 1];
    }
  };

  // Returns everything but the first entry of the array. Aliased as `tail` and `drop`.
  // Especially useful on the arguments object. Passing an **n** will return
  // the rest N values in the array. The **guard**
  // check allows it to work with `_.map`.
  _.rest = _.tail = _.drop = function(array, n, guard) {
    return slice.call(array, (n == null) || guard ? 1 : n);
  };

  // Trim out all falsy values from an array.
  _.compact = function(array) {
    return _.filter(array, function(value){ return !!value; });
  };

  // Internal implementation of a recursive `flatten` function.
  var flatten = function(input, shallow, output) {
    each(input, function(value) {
      if (_.isArray(value)) {
        shallow ? push.apply(output, value) : flatten(value, shallow, output);
      } else {
        output.push(value);
      }
    });
    return output;
  };

  // Return a completely flattened version of an array.
  _.flatten = function(array, shallow) {
    return flatten(array, shallow, []);
  };

  // Return a version of the array that does not contain the specified value(s).
  _.without = function(array) {
    return _.difference(array, slice.call(arguments, 1));
  };

  // Produce a duplicate-free version of the array. If the array has already
  // been sorted, you have the option of using a faster algorithm.
  // Aliased as `unique`.
  _.uniq = _.unique = function(array, isSorted, iterator, context) {
    if (_.isFunction(isSorted)) {
      context = iterator;
      iterator = isSorted;
      isSorted = false;
    }
    var initial = iterator ? _.map(array, iterator, context) : array;
    var results = [];
    var seen = [];
    each(initial, function(value, index) {
      if (isSorted ? (!index || seen[seen.length - 1] !== value) : !_.contains(seen, value)) {
        seen.push(value);
        results.push(array[index]);
      }
    });
    return results;
  };

  // Produce an array that contains the union: each distinct element from all of
  // the passed-in arrays.
  _.union = function() {
    return _.uniq(concat.apply(ArrayProto, arguments));
  };

  // Produce an array that contains every item shared between all the
  // passed-in arrays.
  _.intersection = function(array) {
    var rest = slice.call(arguments, 1);
    return _.filter(_.uniq(array), function(item) {
      return _.every(rest, function(other) {
        return _.indexOf(other, item) >= 0;
      });
    });
  };

  // Take the difference between one array and a number of other arrays.
  // Only the elements present in just the first array will remain.
  _.difference = function(array) {
    var rest = concat.apply(ArrayProto, slice.call(arguments, 1));
    return _.filter(array, function(value){ return !_.contains(rest, value); });
  };

  // Zip together multiple lists into a single array -- elements that share
  // an index go together.
  _.zip = function() {
    var args = slice.call(arguments);
    var length = _.max(_.pluck(args, 'length'));
    var results = new Array(length);
    for (var i = 0; i < length; i++) {
      results[i] = _.pluck(args, "" + i);
    }
    return results;
  };

  // Converts lists into objects. Pass either a single array of `[key, value]`
  // pairs, or two parallel arrays of the same length -- one of keys, and one of
  // the corresponding values.
  _.object = function(list, values) {
    if (list == null) return {};
    var result = {};
    for (var i = 0, l = list.length; i < l; i++) {
      if (values) {
        result[list[i]] = values[i];
      } else {
        result[list[i][0]] = list[i][1];
      }
    }
    return result;
  };

  // If the browser doesn't supply us with indexOf (I'm looking at you, **MSIE**),
  // we need this function. Return the position of the first occurrence of an
  // item in an array, or -1 if the item is not included in the array.
  // Delegates to **ECMAScript 5**'s native `indexOf` if available.
  // If the array is large and already in sort order, pass `true`
  // for **isSorted** to use binary search.
  _.indexOf = function(array, item, isSorted) {
    if (array == null) return -1;
    var i = 0, l = array.length;
    if (isSorted) {
      if (typeof isSorted == 'number') {
        i = (isSorted < 0 ? Math.max(0, l + isSorted) : isSorted);
      } else {
        i = _.sortedIndex(array, item);
        return array[i] === item ? i : -1;
      }
    }
    if (nativeIndexOf && array.indexOf === nativeIndexOf) return array.indexOf(item, isSorted);
    for (; i < l; i++) if (array[i] === item) return i;
    return -1;
  };

  // Delegates to **ECMAScript 5**'s native `lastIndexOf` if available.
  _.lastIndexOf = function(array, item, from) {
    if (array == null) return -1;
    var hasIndex = from != null;
    if (nativeLastIndexOf && array.lastIndexOf === nativeLastIndexOf) {
      return hasIndex ? array.lastIndexOf(item, from) : array.lastIndexOf(item);
    }
    var i = (hasIndex ? from : array.length);
    while (i--) if (array[i] === item) return i;
    return -1;
  };

  // Generate an integer Array containing an arithmetic progression. A port of
  // the native Python `range()` function. See
  // [the Python documentation](http://docs.python.org/library/functions.html#range).
  _.range = function(start, stop, step) {
    if (arguments.length <= 1) {
      stop = start || 0;
      start = 0;
    }
    step = arguments[2] || 1;

    var len = Math.max(Math.ceil((stop - start) / step), 0);
    var idx = 0;
    var range = new Array(len);

    while(idx < len) {
      range[idx++] = start;
      start += step;
    }

    return range;
  };

  // Function (ahem) Functions
  // ------------------

  // Reusable constructor function for prototype setting.
  var ctor = function(){};

  // Create a function bound to a given object (assigning `this`, and arguments,
  // optionally). Binding with arguments is also known as `curry`.
  // Delegates to **ECMAScript 5**'s native `Function.bind` if available.
  // We check for `func.bind` first, to fail fast when `func` is undefined.
  _.bind = function bind(func, context) {
    var bound, args;
    if (func.bind === nativeBind && nativeBind) return nativeBind.apply(func, slice.call(arguments, 1));
    if (!_.isFunction(func)) throw new TypeError;
    args = slice.call(arguments, 2);
    return bound = function() {
      if (!(this instanceof bound)) return func.apply(context, args.concat(slice.call(arguments)));
      ctor.prototype = func.prototype;
      var self = new ctor;
      var result = func.apply(self, args.concat(slice.call(arguments)));
      if (Object(result) === result) return result;
      return self;
    };
  };

  // Bind all of an object's methods to that object. Useful for ensuring that
  // all callbacks defined on an object belong to it.
  _.bindAll = function(obj) {
    var funcs = slice.call(arguments, 1);
    if (funcs.length == 0) funcs = _.functions(obj);
    each(funcs, function(f) { obj[f] = _.bind(obj[f], obj); });
    return obj;
  };

  // Memoize an expensive function by storing its results.
  _.memoize = function(func, hasher) {
    var memo = {};
    hasher || (hasher = _.identity);
    return function() {
      var key = hasher.apply(this, arguments);
      return _.has(memo, key) ? memo[key] : (memo[key] = func.apply(this, arguments));
    };
  };

  // Delays a function for the given number of milliseconds, and then calls
  // it with the arguments supplied.
  _.delay = function(func, wait) {
    var args = slice.call(arguments, 2);
    return setTimeout(function(){ return func.apply(null, args); }, wait);
  };

  // Defers a function, scheduling it to run after the current call stack has
  // cleared.
  _.defer = function(func) {
    return _.delay.apply(_, [func, 1].concat(slice.call(arguments, 1)));
  };

  // Returns a function, that, when invoked, will only be triggered at most once
  // during a given window of time.
  _.throttle = function(func, wait) {
    var context, args, timeout, result;
    var previous = 0;
    var later = function() {
      previous = new Date;
      timeout = null;
      result = func.apply(context, args);
    };
    return function() {
      var now = new Date;
      var remaining = wait - (now - previous);
      context = this;
      args = arguments;
      if (remaining <= 0) {
        clearTimeout(timeout);
        previous = now;
        result = func.apply(context, args);
      } else if (!timeout) {
        timeout = setTimeout(later, remaining);
      }
      return result;
    };
  };

  // Returns a function, that, as long as it continues to be invoked, will not
  // be triggered. The function will be called after it stops being called for
  // N milliseconds. If `immediate` is passed, trigger the function on the
  // leading edge, instead of the trailing.
  _.debounce = function(func, wait, immediate) {
    var timeout, result;
    return function() {
      var context = this, args = arguments;
      var later = function() {
        timeout = null;
        if (!immediate) result = func.apply(context, args);
      };
      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) result = func.apply(context, args);
      return result;
    };
  };

  // Returns a function that will be executed at most one time, no matter how
  // often you call it. Useful for lazy initialization.
  _.once = function(func) {
    var ran = false, memo;
    return function() {
      if (ran) return memo;
      ran = true;
      memo = func.apply(this, arguments);
      func = null;
      return memo;
    };
  };

  // Returns the first function passed as an argument to the second,
  // allowing you to adjust arguments, run code before and after, and
  // conditionally execute the original function.
  _.wrap = function(func, wrapper) {
    return function() {
      var args = [func];
      push.apply(args, arguments);
      return wrapper.apply(this, args);
    };
  };

  // Returns a function that is the composition of a list of functions, each
  // consuming the return value of the function that follows.
  _.compose = function() {
    var funcs = arguments;
    return function() {
      var args = arguments;
      for (var i = funcs.length - 1; i >= 0; i--) {
        args = [funcs[i].apply(this, args)];
      }
      return args[0];
    };
  };

  // Returns a function that will only be executed after being called N times.
  _.after = function(times, func) {
    if (times <= 0) return func();
    return function() {
      if (--times < 1) {
        return func.apply(this, arguments);
      }
    };
  };

  // Object Functions
  // ----------------

  // Retrieve the names of an object's properties.
  // Delegates to **ECMAScript 5**'s native `Object.keys`
  _.keys = nativeKeys || function(obj) {
    if (obj !== Object(obj)) throw new TypeError('Invalid object');
    var keys = [];
    for (var key in obj) if (_.has(obj, key)) keys[keys.length] = key;
    return keys;
  };

  // Retrieve the values of an object's properties.
  _.values = function(obj) {
    var values = [];
    for (var key in obj) if (_.has(obj, key)) values.push(obj[key]);
    return values;
  };

  // Convert an object into a list of `[key, value]` pairs.
  _.pairs = function(obj) {
    var pairs = [];
    for (var key in obj) if (_.has(obj, key)) pairs.push([key, obj[key]]);
    return pairs;
  };

  // Invert the keys and values of an object. The values must be serializable.
  _.invert = function(obj) {
    var result = {};
    for (var key in obj) if (_.has(obj, key)) result[obj[key]] = key;
    return result;
  };

  // Return a sorted list of the function names available on the object.
  // Aliased as `methods`
  _.functions = _.methods = function(obj) {
    var names = [];
    for (var key in obj) {
      if (_.isFunction(obj[key])) names.push(key);
    }
    return names.sort();
  };

  // Extend a given object with all the properties in passed-in object(s).
  _.extend = function(obj) {
    each(slice.call(arguments, 1), function(source) {
      for (var prop in source) {
        obj[prop] = source[prop];
      }
    });
    return obj;
  };

  // Return a copy of the object only containing the whitelisted properties.
  _.pick = function(obj) {
    var copy = {};
    var keys = concat.apply(ArrayProto, slice.call(arguments, 1));
    each(keys, function(key) {
      if (key in obj) copy[key] = obj[key];
    });
    return copy;
  };

   // Return a copy of the object without the blacklisted properties.
  _.omit = function(obj) {
    var copy = {};
    var keys = concat.apply(ArrayProto, slice.call(arguments, 1));
    for (var key in obj) {
      if (!_.contains(keys, key)) copy[key] = obj[key];
    }
    return copy;
  };

  // Fill in a given object with default properties.
  _.defaults = function(obj) {
    each(slice.call(arguments, 1), function(source) {
      for (var prop in source) {
        if (obj[prop] == null) obj[prop] = source[prop];
      }
    });
    return obj;
  };

  // Create a (shallow-cloned) duplicate of an object.
  _.clone = function(obj) {
    if (!_.isObject(obj)) return obj;
    return _.isArray(obj) ? obj.slice() : _.extend({}, obj);
  };

  // Invokes interceptor with the obj, and then returns obj.
  // The primary purpose of this method is to "tap into" a method chain, in
  // order to perform operations on intermediate results within the chain.
  _.tap = function(obj, interceptor) {
    interceptor(obj);
    return obj;
  };

  // Internal recursive comparison function for `isEqual`.
  var eq = function(a, b, aStack, bStack) {
    // Identical objects are equal. `0 === -0`, but they aren't identical.
    // See the Harmony `egal` proposal: http://wiki.ecmascript.org/doku.php?id=harmony:egal.
    if (a === b) return a !== 0 || 1 / a == 1 / b;
    // A strict comparison is necessary because `null == undefined`.
    if (a == null || b == null) return a === b;
    // Unwrap any wrapped objects.
    if (a instanceof _) a = a._wrapped;
    if (b instanceof _) b = b._wrapped;
    // Compare `[[Class]]` names.
    var className = toString.call(a);
    if (className != toString.call(b)) return false;
    switch (className) {
      // Strings, numbers, dates, and booleans are compared by value.
      case '[object String]':
        // Primitives and their corresponding object wrappers are equivalent; thus, `"5"` is
        // equivalent to `new String("5")`.
        return a == String(b);
      case '[object Number]':
        // `NaN`s are equivalent, but non-reflexive. An `egal` comparison is performed for
        // other numeric values.
        return a != +a ? b != +b : (a == 0 ? 1 / a == 1 / b : a == +b);
      case '[object Date]':
      case '[object Boolean]':
        // Coerce dates and booleans to numeric primitive values. Dates are compared by their
        // millisecond representations. Note that invalid dates with millisecond representations
        // of `NaN` are not equivalent.
        return +a == +b;
      // RegExps are compared by their source patterns and flags.
      case '[object RegExp]':
        return a.source == b.source &&
               a.global == b.global &&
               a.multiline == b.multiline &&
               a.ignoreCase == b.ignoreCase;
    }
    if (typeof a != 'object' || typeof b != 'object') return false;
    // Assume equality for cyclic structures. The algorithm for detecting cyclic
    // structures is adapted from ES 5.1 section 15.12.3, abstract operation `JO`.
    var length = aStack.length;
    while (length--) {
      // Linear search. Performance is inversely proportional to the number of
      // unique nested structures.
      if (aStack[length] == a) return bStack[length] == b;
    }
    // Add the first object to the stack of traversed objects.
    aStack.push(a);
    bStack.push(b);
    var size = 0, result = true;
    // Recursively compare objects and arrays.
    if (className == '[object Array]') {
      // Compare array lengths to determine if a deep comparison is necessary.
      size = a.length;
      result = size == b.length;
      if (result) {
        // Deep compare the contents, ignoring non-numeric properties.
        while (size--) {
          if (!(result = eq(a[size], b[size], aStack, bStack))) break;
        }
      }
    } else {
      // Objects with different constructors are not equivalent, but `Object`s
      // from different frames are.
      var aCtor = a.constructor, bCtor = b.constructor;
      if (aCtor !== bCtor && !(_.isFunction(aCtor) && (aCtor instanceof aCtor) &&
                               _.isFunction(bCtor) && (bCtor instanceof bCtor))) {
        return false;
      }
      // Deep compare objects.
      for (var key in a) {
        if (_.has(a, key)) {
          // Count the expected number of properties.
          size++;
          // Deep compare each member.
          if (!(result = _.has(b, key) && eq(a[key], b[key], aStack, bStack))) break;
        }
      }
      // Ensure that both objects contain the same number of properties.
      if (result) {
        for (key in b) {
          if (_.has(b, key) && !(size--)) break;
        }
        result = !size;
      }
    }
    // Remove the first object from the stack of traversed objects.
    aStack.pop();
    bStack.pop();
    return result;
  };

  // Perform a deep comparison to check if two objects are equal.
  _.isEqual = function(a, b) {
    return eq(a, b, [], []);
  };

  // Is a given array, string, or object empty?
  // An "empty" object has no enumerable own-properties.
  _.isEmpty = function(obj) {
    if (obj == null) return true;
    if (_.isArray(obj) || _.isString(obj)) return obj.length === 0;
    for (var key in obj) if (_.has(obj, key)) return false;
    return true;
  };

  // Is a given value a DOM element?
  _.isElement = function(obj) {
    return !!(obj && obj.nodeType === 1);
  };

  // Is a given value an array?
  // Delegates to ECMA5's native Array.isArray
  _.isArray = nativeIsArray || function(obj) {
    return toString.call(obj) == '[object Array]';
  };

  // Is a given variable an object?
  _.isObject = function(obj) {
    return obj === Object(obj);
  };

  // Add some isType methods: isArguments, isFunction, isString, isNumber, isDate, isRegExp.
  each(['Arguments', 'Function', 'String', 'Number', 'Date', 'RegExp'], function(name) {
    _['is' + name] = function(obj) {
      return toString.call(obj) == '[object ' + name + ']';
    };
  });

  // Define a fallback version of the method in browsers (ahem, IE), where
  // there isn't any inspectable "Arguments" type.
  if (!_.isArguments(arguments)) {
    _.isArguments = function(obj) {
      return !!(obj && _.has(obj, 'callee'));
    };
  }

  // Optimize `isFunction` if appropriate.
  if (typeof (/./) !== 'function') {
    _.isFunction = function(obj) {
      return typeof obj === 'function';
    };
  }

  // Is a given object a finite number?
  _.isFinite = function(obj) {
    return isFinite( obj ) && !isNaN( parseFloat(obj) );
  };

  // Is the given value `NaN`? (NaN is the only number which does not equal itself).
  _.isNaN = function(obj) {
    return _.isNumber(obj) && obj != +obj;
  };

  // Is a given value a boolean?
  _.isBoolean = function(obj) {
    return obj === true || obj === false || toString.call(obj) == '[object Boolean]';
  };

  // Is a given value equal to null?
  _.isNull = function(obj) {
    return obj === null;
  };

  // Is a given variable undefined?
  _.isUndefined = function(obj) {
    return obj === void 0;
  };

  // Shortcut function for checking if an object has a given property directly
  // on itself (in other words, not on a prototype).
  _.has = function(obj, key) {
    return hasOwnProperty.call(obj, key);
  };

  // Utility Functions
  // -----------------

  // Run Underscore.js in *noConflict* mode, returning the `_` variable to its
  // previous owner. Returns a reference to the Underscore object.
  _.noConflict = function() {
    root._ = previousUnderscore;
    return this;
  };

  // Keep the identity function around for default iterators.
  _.identity = function(value) {
    return value;
  };

  // Run a function **n** times.
  _.times = function(n, iterator, context) {
    for (var i = 0; i < n; i++) iterator.call(context, i);
  };

  // Return a random integer between min and max (inclusive).
  _.random = function(min, max) {
    if (max == null) {
      max = min;
      min = 0;
    }
    return min + (0 | Math.random() * (max - min + 1));
  };

  // List of HTML entities for escaping.
  var entityMap = {
    escape: {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#x27;',
      '/': '&#x2F;'
    }
  };
  entityMap.unescape = _.invert(entityMap.escape);

  // Regexes containing the keys and values listed immediately above.
  var entityRegexes = {
    escape:   new RegExp('[' + _.keys(entityMap.escape).join('') + ']', 'g'),
    unescape: new RegExp('(' + _.keys(entityMap.unescape).join('|') + ')', 'g')
  };

  // Functions for escaping and unescaping strings to/from HTML interpolation.
  _.each(['escape', 'unescape'], function(method) {
    _[method] = function(string) {
      if (string == null) return '';
      return ('' + string).replace(entityRegexes[method], function(match) {
        return entityMap[method][match];
      });
    };
  });

  // If the value of the named property is a function then invoke it;
  // otherwise, return it.
  _.result = function(object, property) {
    if (object == null) return null;
    var value = object[property];
    return _.isFunction(value) ? value.call(object) : value;
  };

  // Add your own custom functions to the Underscore object.
  _.mixin = function(obj) {
    each(_.functions(obj), function(name){
      var func = _[name] = obj[name];
      _.prototype[name] = function() {
        var args = [this._wrapped];
        push.apply(args, arguments);
        return result.call(this, func.apply(_, args));
      };
    });
  };

  // Generate a unique integer id (unique within the entire client session).
  // Useful for temporary DOM ids.
  var idCounter = 0;
  _.uniqueId = function(prefix) {
    var id = idCounter++;
    return prefix ? prefix + id : id;
  };

  // By default, Underscore uses ERB-style template delimiters, change the
  // following template settings to use alternative delimiters.
  _.templateSettings = {
    evaluate    : /<%([\s\S]+?)%>/g,
    interpolate : /<%=([\s\S]+?)%>/g,
    escape      : /<%-([\s\S]+?)%>/g
  };

  // When customizing `templateSettings`, if you don't want to define an
  // interpolation, evaluation or escaping regex, we need one that is
  // guaranteed not to match.
  var noMatch = /(.)^/;

  // Certain characters need to be escaped so that they can be put into a
  // string literal.
  var escapes = {
    "'":      "'",
    '\\':     '\\',
    '\r':     'r',
    '\n':     'n',
    '\t':     't',
    '\u2028': 'u2028',
    '\u2029': 'u2029'
  };

  var escaper = /\\|'|\r|\n|\t|\u2028|\u2029/g;

  // JavaScript micro-templating, similar to John Resig's implementation.
  // Underscore templating handles arbitrary delimiters, preserves whitespace,
  // and correctly escapes quotes within interpolated code.
  _.template = function(text, data, settings) {
    settings = _.defaults({}, settings, _.templateSettings);

    // Combine delimiters into one regular expression via alternation.
    var matcher = new RegExp([
      (settings.escape || noMatch).source,
      (settings.interpolate || noMatch).source,
      (settings.evaluate || noMatch).source
    ].join('|') + '|$', 'g');

    // Compile the template source, escaping string literals appropriately.
    var index = 0;
    var source = "__p+='";
    text.replace(matcher, function(match, escape, interpolate, evaluate, offset) {
      source += text.slice(index, offset)
        .replace(escaper, function(match) { return '\\' + escapes[match]; });
      source +=
        escape ? "'+\n((__t=(" + escape + "))==null?'':_.escape(__t))+\n'" :
        interpolate ? "'+\n((__t=(" + interpolate + "))==null?'':__t)+\n'" :
        evaluate ? "';\n" + evaluate + "\n__p+='" : '';
      index = offset + match.length;
    });
    source += "';\n";

    // If a variable is not specified, place data values in local scope.
    if (!settings.variable) source = 'with(obj||{}){\n' + source + '}\n';

    source = "var __t,__p='',__j=Array.prototype.join," +
      "print=function(){__p+=__j.call(arguments,'');};\n" +
      source + "return __p;\n";

    try {
      var render = new Function(settings.variable || 'obj', '_', source);
    } catch (e) {
      e.source = source;
      throw e;
    }

    if (data) return render(data, _);
    var template = function(data) {
      return render.call(this, data, _);
    };

    // Provide the compiled function source as a convenience for precompilation.
    template.source = 'function(' + (settings.variable || 'obj') + '){\n' + source + '}';

    return template;
  };

  // Add a "chain" function, which will delegate to the wrapper.
  _.chain = function(obj) {
    return _(obj).chain();
  };

  // OOP
  // ---------------
  // If Underscore is called as a function, it returns a wrapped object that
  // can be used OO-style. This wrapper holds altered versions of all the
  // underscore functions. Wrapped objects may be chained.

  // Helper function to continue chaining intermediate results.
  var result = function(obj) {
    return this._chain ? _(obj).chain() : obj;
  };

  // Add all of the Underscore functions to the wrapper object.
  _.mixin(_);

  // Add all mutator Array functions to the wrapper.
  each(['pop', 'push', 'reverse', 'shift', 'sort', 'splice', 'unshift'], function(name) {
    var method = ArrayProto[name];
    _.prototype[name] = function() {
      var obj = this._wrapped;
      method.apply(obj, arguments);
      if ((name == 'shift' || name == 'splice') && obj.length === 0) delete obj[0];
      return result.call(this, obj);
    };
  });

  // Add all accessor Array functions to the wrapper.
  each(['concat', 'join', 'slice'], function(name) {
    var method = ArrayProto[name];
    _.prototype[name] = function() {
      return result.call(this, method.apply(this._wrapped, arguments));
    };
  });

  _.extend(_.prototype, {

    // Start chaining a wrapped Underscore object.
    chain: function() {
      this._chain = true;
      return this;
    },

    // Extracts the result from a wrapped and chained object.
    value: function() {
      return this._wrapped;
    }

  });

}).call(this);

define("underscore", (function (global) {
    return function () {
        return global._;
    }
}(this)));

//     Backbone.js 0.9.2

//     (c) 2010-2012 Jeremy Ashkenas, DocumentCloud Inc.
//     Backbone may be freely distributed under the MIT license.
//     For all details and documentation:
//     http://backbonejs.org

(function(){

  // Initial Setup
  // -------------

  // Save a reference to the global object (`window` in the browser, `exports`
  // on the server).
  var root = this;

  // Save the previous value of the `Backbone` variable, so that it can be
  // restored later on, if `noConflict` is used.
  var previousBackbone = root.Backbone;

  // Create a local reference to array methods.
  var ArrayProto = Array.prototype;
  var push = ArrayProto.push;
  var slice = ArrayProto.slice;
  var splice = ArrayProto.splice;

  // The top-level namespace. All public Backbone classes and modules will
  // be attached to this. Exported for both CommonJS and the browser.
  var Backbone;
  if (typeof exports !== 'undefined') {
    Backbone = exports;
  } else {
    Backbone = root.Backbone = {};
  }

  // Current version of the library. Keep in sync with `package.json`.
  Backbone.VERSION = '0.9.2';

  // Require Underscore, if we're on the server, and it's not already present.
  var _ = root._;
  if (!_ && (typeof require !== 'undefined')) _ = require('underscore');

  // For Backbone's purposes, jQuery, Zepto, or Ender owns the `$` variable.
  Backbone.$ = root.jQuery || root.Zepto || root.ender;

  // Runs Backbone.js in *noConflict* mode, returning the `Backbone` variable
  // to its previous owner. Returns a reference to this Backbone object.
  Backbone.noConflict = function() {
    root.Backbone = previousBackbone;
    return this;
  };

  // Turn on `emulateHTTP` to support legacy HTTP servers. Setting this option
  // will fake `"PUT"` and `"DELETE"` requests via the `_method` parameter and
  // set a `X-Http-Method-Override` header.
  Backbone.emulateHTTP = false;

  // Turn on `emulateJSON` to support legacy servers that can't deal with direct
  // `application/json` requests ... will encode the body as
  // `application/x-www-form-urlencoded` instead and will send the model in a
  // form param named `model`.
  Backbone.emulateJSON = false;

  // Backbone.Events
  // ---------------

  // Regular expression used to split event strings
  var eventSplitter = /\s+/;

  // A module that can be mixed in to *any object* in order to provide it with
  // custom events. You may bind with `on` or remove with `off` callback functions
  // to an event; `trigger`-ing an event fires all callbacks in succession.
  //
  //     var object = {};
  //     _.extend(object, Backbone.Events);
  //     object.on('expand', function(){ alert('expanded'); });
  //     object.trigger('expand');
  //
  var Events = Backbone.Events = {

    // Bind one or more space separated events, `events`, to a `callback`
    // function. Passing `"all"` will bind the callback to all events fired.
    on: function(events, callback, context) {
      var calls, event, list;
      if (!callback) return this;

      events = events.split(eventSplitter);
      calls = this._callbacks || (this._callbacks = {});

      while (event = events.shift()) {
        list = calls[event] || (calls[event] = []);
        list.push(callback, context);
      }

      return this;
    },

    // Remove one or many callbacks. If `context` is null, removes all callbacks
    // with that function. If `callback` is null, removes all callbacks for the
    // event. If `events` is null, removes all bound callbacks for all events.
    off: function(events, callback, context) {
      var event, calls, list, i;

      // No events, or removing *all* events.
      if (!(calls = this._callbacks)) return this;
      if (!(events || callback || context)) {
        delete this._callbacks;
        return this;
      }

      events = events ? events.split(eventSplitter) : _.keys(calls);

      // Loop through the callback list, splicing where appropriate.
      while (event = events.shift()) {
        if (!(list = calls[event]) || !(callback || context)) {
          delete calls[event];
          continue;
        }

        for (i = list.length - 2; i >= 0; i -= 2) {
          if (!(callback && list[i] !== callback || context && list[i + 1] !== context)) {
            list.splice(i, 2);
          }
        }
      }

      return this;
    },

    // Trigger one or many events, firing all bound callbacks. Callbacks are
    // passed the same arguments as `trigger` is, apart from the event name
    // (unless you're listening on `"all"`, which will cause your callback to
    // receive the true name of the event as the first argument).
    trigger: function(events) {
      var event, calls, list, i, length, args, all, rest;
      if (!(calls = this._callbacks)) return this;

      rest = [];
      events = events.split(eventSplitter);

      // Fill up `rest` with the callback arguments.  Since we're only copying
      // the tail of `arguments`, a loop is much faster than Array#slice.
      for (i = 1, length = arguments.length; i < length; i++) {
        rest[i - 1] = arguments[i];
      }

      // For each event, walk through the list of callbacks twice, first to
      // trigger the event, then to trigger any `"all"` callbacks.
      while (event = events.shift()) {
        // Copy callback lists to prevent modification.
        if (all = calls.all) all = all.slice();
        if (list = calls[event]) list = list.slice();

        // Execute event callbacks.
        if (list) {
          for (i = 0, length = list.length; i < length; i += 2) {
            list[i].apply(list[i + 1] || this, rest);
          }
        }

        // Execute "all" callbacks.
        if (all) {
          args = [event].concat(rest);
          for (i = 0, length = all.length; i < length; i += 2) {
            all[i].apply(all[i + 1] || this, args);
          }
        }
      }

      return this;
    }

  };

  // Aliases for backwards compatibility.
  Events.bind   = Events.on;
  Events.unbind = Events.off;

  // Backbone.Model
  // --------------

  // Create a new model, with defined attributes. A client id (`cid`)
  // is automatically generated and assigned for you.
  var Model = Backbone.Model = function(attributes, options) {
    var defaults;
    var attrs = attributes || {};
    if (options && options.collection) this.collection = options.collection;
    this.attributes = {};
    this._escapedAttributes = {};
    this.cid = _.uniqueId('c');
    this.changed = {};
    this._changes = {};
    this._pending = {};
    if (options && options.parse) attrs = this.parse(attrs);
    if (defaults = _.result(this, 'defaults')) {
      attrs = _.extend({}, defaults, attrs);
    }
    this.set(attrs, {silent: true});
    // Reset change tracking.
    this.changed = {};
    this._changes = {};
    this._pending = {};
    this._previousAttributes = _.clone(this.attributes);
    this.initialize.apply(this, arguments);
  };

  // Attach all inheritable methods to the Model prototype.
  _.extend(Model.prototype, Events, {

    // A hash of attributes whose current and previous value differ.
    changed: null,

    // A hash of attributes that have changed since the last time `change`
    // was called.
    _changes: null,

    // A hash of attributes that have changed since the last `change` event
    // began.
    _pending: null,

    // A hash of attributes with the current model state to determine if
    // a `change` should be recorded within a nested `change` block.
    _changing : null,

    // The default name for the JSON `id` attribute is `"id"`. MongoDB and
    // CouchDB users may want to set this to `"_id"`.
    idAttribute: 'id',

    // Initialize is an empty function by default. Override it with your own
    // initialization logic.
    initialize: function(){},

    // Return a copy of the model's `attributes` object.
    toJSON: function(options) {
      return _.clone(this.attributes);
    },

    // Proxy `Backbone.sync` by default.
    sync: function() {
      return Backbone.sync.apply(this, arguments);
    },

    // Get the value of an attribute.
    get: function(attr) {
      return this.attributes[attr];
    },

    // Get the HTML-escaped value of an attribute.
    escape: function(attr) {
      var html;
      if (html = this._escapedAttributes[attr]) return html;
      var val = this.get(attr);
      return this._escapedAttributes[attr] = _.escape(val == null ? '' : '' + val);
    },

    // Returns `true` if the attribute contains a value that is not null
    // or undefined.
    has: function(attr) {
      return this.get(attr) != null;
    },

    // Set a hash of model attributes on the object, firing `"change"` unless
    // you choose to silence it.
    set: function(key, val, options) {
      var attr, attrs;
      if (key == null) return this;

      // Handle both `"key", value` and `{key: value}` -style arguments.
      if (_.isObject(key)) {
        attrs = key;
        options = val;
      } else {
        (attrs = {})[key] = val;
      }

      // Extract attributes and options.
      var silent = options && options.silent;
      var unset = options && options.unset;
      if (attrs instanceof Model) attrs = attrs.attributes;
      if (unset) for (attr in attrs) attrs[attr] = void 0;

      // Run validation.
      if (!this._validate(attrs, options)) return false;

      // Check for changes of `id`.
      if (this.idAttribute in attrs) this.id = attrs[this.idAttribute];

      var changing = this._changing;
      var now = this.attributes;
      var escaped = this._escapedAttributes;
      var prev = this._previousAttributes || {};

      // For each `set` attribute...
      for (attr in attrs) {
        val = attrs[attr];

        // If the new and current value differ, record the change.
        if (!_.isEqual(now[attr], val) || (unset && _.has(now, attr))) {
          delete escaped[attr];
          this._changes[attr] = true;
        }

        // Update or delete the current value.
        unset ? delete now[attr] : now[attr] = val;

        // If the new and previous value differ, record the change.  If not,
        // then remove changes for this attribute.
        if (!_.isEqual(prev[attr], val) || (_.has(now, attr) !== _.has(prev, attr))) {
          this.changed[attr] = val;
          if (!silent) this._pending[attr] = true;
        } else {
          delete this.changed[attr];
          delete this._pending[attr];
          if (!changing) delete this._changes[attr];
        }

        if (changing && _.isEqual(now[attr], changing[attr])) delete this._changes[attr];
      }

      // Fire the `"change"` events.
      if (!silent) this.change(options);
      return this;
    },

    // Remove an attribute from the model, firing `"change"` unless you choose
    // to silence it. `unset` is a noop if the attribute doesn't exist.
    unset: function(attr, options) {
      options = _.extend({}, options, {unset: true});
      return this.set(attr, null, options);
    },

    // Clear all attributes on the model, firing `"change"` unless you choose
    // to silence it.
    clear: function(options) {
      options = _.extend({}, options, {unset: true});
      return this.set(_.clone(this.attributes), options);
    },

    // Fetch the model from the server. If the server's representation of the
    // model differs from its current attributes, they will be overriden,
    // triggering a `"change"` event.
    fetch: function(options) {
      options = options ? _.clone(options) : {};
      var model = this;
      var success = options.success;
      options.success = function(resp, status, xhr) {
        if (!model.set(model.parse(resp, xhr), options)) return false;
        if (success) success(model, resp, options);
      };
      return this.sync('read', this, options);
    },

    // Set a hash of model attributes, and sync the model to the server.
    // If the server returns an attributes hash that differs, the model's
    // state will be `set` again.
    save: function(key, val, options) {
      var attrs, current, done;

      // Handle both `"key", value` and `{key: value}` -style arguments.
      if (key == null || _.isObject(key)) {
        attrs = key;
        options = val;
      } else if (key != null) {
        (attrs = {})[key] = val;
      }
      options = options ? _.clone(options) : {};

      // If we're "wait"-ing to set changed attributes, validate early.
      if (options.wait) {
        if (!this._validate(attrs, options)) return false;
        current = _.clone(this.attributes);
      }

      // Regular saves `set` attributes before persisting to the server.
      var silentOptions = _.extend({}, options, {silent: true});
      if (attrs && !this.set(attrs, options.wait ? silentOptions : options)) {
        return false;
      }

      // Do not persist invalid models.
      if (!attrs && !this._validate(null, options)) return false;

      // After a successful server-side save, the client is (optionally)
      // updated with the server-side state.
      var model = this;
      var success = options.success;
      options.success = function(resp, status, xhr) {
        done = true;
        var serverAttrs = model.parse(resp, xhr);
        if (options.wait) serverAttrs = _.extend(attrs || {}, serverAttrs);
        if (!model.set(serverAttrs, options)) return false;
        if (success) success(model, resp, options);
      };

      // Finish configuring and sending the Ajax request.
      var xhr = this.sync(this.isNew() ? 'create' : 'update', this, options);

      // When using `wait`, reset attributes to original values unless
      // `success` has been called already.
      if (!done && options.wait) {
        this.clear(silentOptions);
        this.set(current, silentOptions);
      }

      return xhr;
    },

    // Destroy this model on the server if it was already persisted.
    // Optimistically removes the model from its collection, if it has one.
    // If `wait: true` is passed, waits for the server to respond before removal.
    destroy: function(options) {
      options = options ? _.clone(options) : {};
      var model = this;
      var success = options.success;

      var destroy = function() {
        model.trigger('destroy', model, model.collection, options);
      };

      options.success = function(resp) {
        if (options.wait || model.isNew()) destroy();
        if (success) success(model, resp, options);
      };

      if (this.isNew()) {
        options.success();
        return false;
      }

      var xhr = this.sync('delete', this, options);
      if (!options.wait) destroy();
      return xhr;
    },

    // Default URL for the model's representation on the server -- if you're
    // using Backbone's restful methods, override this to change the endpoint
    // that will be called.
    url: function() {
      var base = _.result(this, 'urlRoot') || _.result(this.collection, 'url') || urlError();
      if (this.isNew()) return base;
      return base + (base.charAt(base.length - 1) === '/' ? '' : '/') + encodeURIComponent(this.id);
    },

    // **parse** converts a response into the hash of attributes to be `set` on
    // the model. The default implementation is just to pass the response along.
    parse: function(resp, xhr) {
      return resp;
    },

    // Create a new model with identical attributes to this one.
    clone: function() {
      return new this.constructor(this.attributes);
    },

    // A model is new if it has never been saved to the server, and lacks an id.
    isNew: function() {
      return this.id == null;
    },

    // Call this method to manually fire a `"change"` event for this model and
    // a `"change:attribute"` event for each changed attribute.
    // Calling this will cause all objects observing the model to update.
    change: function(options) {
      var changing = this._changing;
      var current = this._changing = {};

      // Silent changes become pending changes.
      for (var attr in this._changes) this._pending[attr] = true;

      // Trigger 'change:attr' for any new or silent changes.
      var changes = this._changes;
      this._changes = {};

      // Set the correct state for this._changing values
      var triggers = [];
      for (var attr in changes) {
        current[attr] = this.get(attr);
        triggers.push(attr);
      }

      for (var i=0, l=triggers.length; i < l; i++) {
        this.trigger('change:' + triggers[i], this, current[triggers[i]], options);
      }
      if (changing) return this;

      // Continue firing `"change"` events while there are pending changes.
      while (!_.isEmpty(this._pending)) {
        this._pending = {};
        this.trigger('change', this, options);
        // Pending and silent changes still remain.
        for (var attr in this.changed) {
          if (this._pending[attr] || this._changes[attr]) continue;
          delete this.changed[attr];
        }
        this._previousAttributes = _.clone(this.attributes);
      }

      this._changing = null;
      return this;
    },

    // Determine if the model has changed since the last `"change"` event.
    // If you specify an attribute name, determine if that attribute has changed.
    hasChanged: function(attr) {
      if (attr == null) return !_.isEmpty(this.changed);
      return _.has(this.changed, attr);
    },

    // Return an object containing all the attributes that have changed, or
    // false if there are no changed attributes. Useful for determining what
    // parts of a view need to be updated and/or what attributes need to be
    // persisted to the server. Unset attributes will be set to undefined.
    // You can also pass an attributes object to diff against the model,
    // determining if there *would be* a change.
    changedAttributes: function(diff) {
      if (!diff) return this.hasChanged() ? _.clone(this.changed) : false;
      var val, changed = false, old = this._previousAttributes;
      for (var attr in diff) {
        if (_.isEqual(old[attr], (val = diff[attr]))) continue;
        (changed || (changed = {}))[attr] = val;
      }
      return changed;
    },

    // Get the previous value of an attribute, recorded at the time the last
    // `"change"` event was fired.
    previous: function(attr) {
      if (attr == null || !this._previousAttributes) return null;
      return this._previousAttributes[attr];
    },

    // Get all of the attributes of the model at the time of the previous
    // `"change"` event.
    previousAttributes: function() {
      return _.clone(this._previousAttributes);
    },

    // Check if the model is currently in a valid state. It's only possible to
    // get into an *invalid* state if you're using silent changes.
    isValid: function(options) {
      return !this.validate || !this.validate(this.attributes, options);
    },

    // Run validation against the next complete set of model attributes,
    // returning `true` if all is well. If a specific `error` callback has
    // been passed, call that instead of firing the general `"error"` event.
    _validate: function(attrs, options) {
      if (options && options.silent || !this.validate) return true;
      attrs = _.extend({}, this.attributes, attrs);
      var error = this.validate(attrs, options);
      if (!error) return true;
      if (options && options.error) options.error(this, error, options);
      this.trigger('error', this, error, options);
      return false;
    }

  });

  // Backbone.Collection
  // -------------------

  // Provides a standard collection class for our sets of models, ordered
  // or unordered. If a `comparator` is specified, the Collection will maintain
  // its models in sort order, as they're added and removed.
  var Collection = Backbone.Collection = function(models, options) {
    options || (options = {});
    if (options.model) this.model = options.model;
    if (options.comparator !== void 0) this.comparator = options.comparator;
    this._reset();
    this.initialize.apply(this, arguments);
    if (models) {
      if (options.parse) models = this.parse(models);
      this.reset(models, {silent: true, parse: options.parse});
    }
  };

  // Define the Collection's inheritable methods.
  _.extend(Collection.prototype, Events, {

    // The default model for a collection is just a **Backbone.Model**.
    // This should be overridden in most cases.
    model: Model,

    // Initialize is an empty function by default. Override it with your own
    // initialization logic.
    initialize: function(){},

    // The JSON representation of a Collection is an array of the
    // models' attributes.
    toJSON: function(options) {
      return this.map(function(model){ return model.toJSON(options); });
    },

    // Proxy `Backbone.sync` by default.
    sync: function() {
      return Backbone.sync.apply(this, arguments);
    },

    // Add a model, or list of models to the set. Pass **silent** to avoid
    // firing the `add` event for every new model.
    add: function(models, options) {
      var i, args, length, model, existing;
      var at = options && options.at;
      models = _.isArray(models) ? models.slice() : [models];

      // Begin by turning bare objects into model references, and preventing
      // invalid models from being added.
      for (i = 0, length = models.length; i < length; i++) {
        if (models[i] = this._prepareModel(models[i], options)) continue;
        throw new Error("Can't add an invalid model to a collection");
      }

      for (i = models.length - 1; i >= 0; i--) {
        model = models[i];
        existing = model.id != null && this._byId[model.id];

        // If a duplicate is found, splice it out and optionally merge it into
        // the existing model.
        if (existing || this._byCid[model.cid]) {
          if (options && options.merge && existing) {
            existing.set(model, options);
          }
          models.splice(i, 1);
          continue;
        }

        // Listen to added models' events, and index models for lookup by
        // `id` and by `cid`.
        model.on('all', this._onModelEvent, this);
        this._byCid[model.cid] = model;
        if (model.id != null) this._byId[model.id] = model;
      }

      // Update `length` and splice in new models.
      this.length += models.length;
      args = [at != null ? at : this.models.length, 0];
      push.apply(args, models);
      splice.apply(this.models, args);

      // Sort the collection if appropriate.
      if (this.comparator && at == null) this.sort({silent: true});

      if (options && options.silent) return this;

      // Trigger `add` events.
      while (model = models.shift()) {
        model.trigger('add', model, this, options);
      }

      return this;
    },

    // Remove a model, or a list of models from the set. Pass silent to avoid
    // firing the `remove` event for every model removed.
    remove: function(models, options) {
      var i, l, index, model;
      options || (options = {});
      models = _.isArray(models) ? models.slice() : [models];
      for (i = 0, l = models.length; i < l; i++) {
        model = this.getByCid(models[i]) || this.get(models[i]);
        if (!model) continue;
        delete this._byId[model.id];
        delete this._byCid[model.cid];
        index = this.indexOf(model);
        this.models.splice(index, 1);
        this.length--;
        if (!options.silent) {
          options.index = index;
          model.trigger('remove', model, this, options);
        }
        this._removeReference(model);
      }
      return this;
    },

    // Add a model to the end of the collection.
    push: function(model, options) {
      model = this._prepareModel(model, options);
      this.add(model, options);
      return model;
    },

    // Remove a model from the end of the collection.
    pop: function(options) {
      var model = this.at(this.length - 1);
      this.remove(model, options);
      return model;
    },

    // Add a model to the beginning of the collection.
    unshift: function(model, options) {
      model = this._prepareModel(model, options);
      this.add(model, _.extend({at: 0}, options));
      return model;
    },

    // Remove a model from the beginning of the collection.
    shift: function(options) {
      var model = this.at(0);
      this.remove(model, options);
      return model;
    },

    // Slice out a sub-array of models from the collection.
    slice: function(begin, end) {
      return this.models.slice(begin, end);
    },

    // Get a model from the set by id.
    get: function(id) {
      if (id == null) return void 0;
      return this._byId[id.id != null ? id.id : id];
    },

    // Get a model from the set by client id.
    getByCid: function(cid) {
      return cid && this._byCid[cid.cid || cid];
    },

    // Get the model at the given index.
    at: function(index) {
      return this.models[index];
    },

    // Return models with matching attributes. Useful for simple cases of `filter`.
    where: function(attrs) {
      if (_.isEmpty(attrs)) return [];
      return this.filter(function(model) {
        for (var key in attrs) {
          if (attrs[key] !== model.get(key)) return false;
        }
        return true;
      });
    },

    // Force the collection to re-sort itself. You don't need to call this under
    // normal circumstances, as the set will maintain sort order as each item
    // is added.
    sort: function(options) {
      if (!this.comparator) {
        throw new Error('Cannot sort a set without a comparator');
      }

      if (_.isString(this.comparator) || this.comparator.length === 1) {
        this.models = this.sortBy(this.comparator, this);
      } else {
        this.models.sort(_.bind(this.comparator, this));
      }

      if (!options || !options.silent) this.trigger('reset', this, options);
      return this;
    },

    // Pluck an attribute from each model in the collection.
    pluck: function(attr) {
      return _.invoke(this.models, 'get', attr);
    },

    // When you have more items than you want to add or remove individually,
    // you can reset the entire set with a new list of models, without firing
    // any `add` or `remove` events. Fires `reset` when finished.
    reset: function(models, options) {
      for (var i = 0, l = this.models.length; i < l; i++) {
        this._removeReference(this.models[i]);
      }
      this._reset();
      if (models) this.add(models, _.extend({silent: true}, options));
      if (!options || !options.silent) this.trigger('reset', this, options);
      return this;
    },

    // Fetch the default set of models for this collection, resetting the
    // collection when they arrive. If `add: true` is passed, appends the
    // models to the collection instead of resetting.
    fetch: function(options) {
      options = options ? _.clone(options) : {};
      if (options.parse === void 0) options.parse = true;
      var collection = this;
      var success = options.success;
      options.success = function(resp, status, xhr) {
        collection[options.add ? 'add' : 'reset'](collection.parse(resp, xhr), options);
        if (success) success(collection, resp, options);
      };
      return this.sync('read', this, options);
    },

    // Create a new instance of a model in this collection. Add the model to the
    // collection immediately, unless `wait: true` is passed, in which case we
    // wait for the server to agree.
    create: function(model, options) {
      var collection = this;
      options = options ? _.clone(options) : {};
      model = this._prepareModel(model, options);
      if (!model) return false;
      if (!options.wait) collection.add(model, options);
      var success = options.success;
      options.success = function(model, resp, options) {
        if (options.wait) collection.add(model, options);
        if (success) success(model, resp, options);
      };
      model.save(null, options);
      return model;
    },

    // **parse** converts a response into a list of models to be added to the
    // collection. The default implementation is just to pass it through.
    parse: function(resp, xhr) {
      return resp;
    },

    // Create a new collection with an identical list of models as this one.
    clone: function() {
      return new this.constructor(this.models);
    },

    // Proxy to _'s chain. Can't be proxied the same way the rest of the
    // underscore methods are proxied because it relies on the underscore
    // constructor.
    chain: function() {
      return _(this.models).chain();
    },

    // Reset all internal state. Called when the collection is reset.
    _reset: function(options) {
      this.length = 0;
      this.models = [];
      this._byId  = {};
      this._byCid = {};
    },

    // Prepare a model or hash of attributes to be added to this collection.
    _prepareModel: function(attrs, options) {
      if (attrs instanceof Model) {
        if (!attrs.collection) attrs.collection = this;
        return attrs;
      }
      options || (options = {});
      options.collection = this;
      var model = new this.model(attrs, options);
      if (!model._validate(model.attributes, options)) return false;
      return model;
    },

    // Internal method to remove a model's ties to a collection.
    _removeReference: function(model) {
      if (this === model.collection) delete model.collection;
      model.off('all', this._onModelEvent, this);
    },

    // Internal method called every time a model in the set fires an event.
    // Sets need to update their indexes when models change ids. All other
    // events simply proxy through. "add" and "remove" events that originate
    // in other collections are ignored.
    _onModelEvent: function(event, model, collection, options) {
      if ((event === 'add' || event === 'remove') && collection !== this) return;
      if (event === 'destroy') this.remove(model, options);
      if (model && event === 'change:' + model.idAttribute) {
        delete this._byId[model.previous(model.idAttribute)];
        if (model.id != null) this._byId[model.id] = model;
      }
      this.trigger.apply(this, arguments);
    }

  });

  // Underscore methods that we want to implement on the Collection.
  var methods = ['forEach', 'each', 'map', 'collect', 'reduce', 'foldl',
    'inject', 'reduceRight', 'foldr', 'find', 'detect', 'filter', 'select',
    'reject', 'every', 'all', 'some', 'any', 'include', 'contains', 'invoke',
    'max', 'min', 'sortedIndex', 'toArray', 'size', 'first', 'head', 'take',
    'initial', 'rest', 'tail', 'last', 'without', 'indexOf', 'shuffle',
    'lastIndexOf', 'isEmpty'];

  // Mix in each Underscore method as a proxy to `Collection#models`.
  _.each(methods, function(method) {
    Collection.prototype[method] = function() {
      var args = slice.call(arguments);
      args.unshift(this.models);
      return _[method].apply(_, args);
    };
  });

  // Underscore methods that take a property name as an argument.
  var attributeMethods = ['groupBy', 'countBy', 'sortBy'];

  // Use attributes instead of properties.
  _.each(attributeMethods, function(method) {
    Collection.prototype[method] = function(value, context) {
      var iterator = _.isFunction(value) ? value : function(model) {
        return model.get(value);
      };
      return _[method](this.models, iterator, context);
    };
  });

  // Backbone.Router
  // ---------------

  // Routers map faux-URLs to actions, and fire events when routes are
  // matched. Creating a new one sets its `routes` hash, if not set statically.
  var Router = Backbone.Router = function(options) {
    options || (options = {});
    if (options.routes) this.routes = options.routes;
    this._bindRoutes();
    this.initialize.apply(this, arguments);
  };

  // Cached regular expressions for matching named param parts and splatted
  // parts of route strings.
  var optionalParam = /\((.*?)\)/g;
  var namedParam    = /:\w+/g;
  var splatParam    = /\*\w+/g;
  var escapeRegExp  = /[-{}[\]+?.,\\^$|#\s]/g;

  // Set up all inheritable **Backbone.Router** properties and methods.
  _.extend(Router.prototype, Events, {

    // Initialize is an empty function by default. Override it with your own
    // initialization logic.
    initialize: function(){},

    // Manually bind a single named route to a callback. For example:
    //
    //     this.route('search/:query/p:num', 'search', function(query, num) {
    //       ...
    //     });
    //
    route: function(route, name, callback) {
      if (!_.isRegExp(route)) route = this._routeToRegExp(route);
      if (!callback) callback = this[name];
      Backbone.history.route(route, _.bind(function(fragment) {
        var args = this._extractParameters(route, fragment);
        callback && callback.apply(this, args);
        this.trigger.apply(this, ['route:' + name].concat(args));
        Backbone.history.trigger('route', this, name, args);
      }, this));
      return this;
    },

    // Simple proxy to `Backbone.history` to save a fragment into the history.
    navigate: function(fragment, options) {
      Backbone.history.navigate(fragment, options);
      return this;
    },

    // Bind all defined routes to `Backbone.history`. We have to reverse the
    // order of the routes here to support behavior where the most general
    // routes can be defined at the bottom of the route map.
    _bindRoutes: function() {
      if (!this.routes) return;
      var route, routes = _.keys(this.routes);
      while ((route = routes.pop()) != null) {
        this.route(route, this.routes[route]);
      }
    },

    // Convert a route string into a regular expression, suitable for matching
    // against the current location hash.
    _routeToRegExp: function(route) {
      route = route.replace(escapeRegExp, '\\$&')
                   .replace(optionalParam, '(?:$1)?')
                   .replace(namedParam, '([^\/]+)')
                   .replace(splatParam, '(.*?)');
      return new RegExp('^' + route + '$');
    },

    // Given a route, and a URL fragment that it matches, return the array of
    // extracted parameters.
    _extractParameters: function(route, fragment) {
      return route.exec(fragment).slice(1);
    }

  });

  // Backbone.History
  // ----------------

  // Handles cross-browser history management, based on URL fragments. If the
  // browser does not support `onhashchange`, falls back to polling.
  var History = Backbone.History = function() {
    this.handlers = [];
    _.bindAll(this, 'checkUrl');

    // #1653 - Ensure that `History` can be used outside of the browser.
    if (typeof window !== 'undefined') {
      this.location = window.location;
      this.history = window.history;
    }
  };

  // Cached regex for cleaning leading hashes and slashes.
  var routeStripper = /^[#\/]|\s+$/;

  // Cached regex for stripping leading and trailing slashes.
  var rootStripper = /^\/+|\/+$/g;

  // Cached regex for detecting MSIE.
  var isExplorer = /msie [\w.]+/;

  // Cached regex for removing a trailing slash.
  var trailingSlash = /\/$/;

  // Has the history handling already been started?
  History.started = false;

  // Set up all inheritable **Backbone.History** properties and methods.
  _.extend(History.prototype, Events, {

    // The default interval to poll for hash changes, if necessary, is
    // twenty times a second.
    interval: 50,

    // Gets the true hash value. Cannot use location.hash directly due to bug
    // in Firefox where location.hash will always be decoded.
    getHash: function(window) {
      var match = (window || this).location.href.match(/#(.*)$/);
      return match ? match[1] : '';
    },

    // Get the cross-browser normalized URL fragment, either from the URL,
    // the hash, or the override.
    getFragment: function(fragment, forcePushState) {
      if (fragment == null) {
        if (this._hasPushState || !this._wantsHashChange || forcePushState) {
          fragment = this.location.pathname;
          var root = this.root.replace(trailingSlash, '');
          if (!fragment.indexOf(root)) fragment = fragment.substr(root.length);
        } else {
          fragment = this.getHash();
        }
      }
      return decodeURIComponent(fragment.replace(routeStripper, ''));
    },

    // Start the hash change handling, returning `true` if the current URL matches
    // an existing route, and `false` otherwise.
    start: function(options) {
      if (History.started) throw new Error("Backbone.history has already been started");
      History.started = true;

      // Figure out the initial configuration. Do we need an iframe?
      // Is pushState desired ... is it available?
      this.options          = _.extend({}, {root: '/'}, this.options, options);
      this.root             = this.options.root;
      this._wantsHashChange = this.options.hashChange !== false;
      this._wantsPushState  = !!this.options.pushState;
      this._hasPushState    = !!(this.options.pushState && this.history && this.history.pushState);
      var fragment          = this.getFragment();
      var docMode           = document.documentMode;
      var oldIE             = (isExplorer.exec(navigator.userAgent.toLowerCase()) && (!docMode || docMode <= 7));

      // Normalize root to always include a leading and trailing slash.
      this.root = ('/' + this.root + '/').replace(rootStripper, '/');

      if (oldIE && this._wantsHashChange) {
        this.iframe = Backbone.$('<iframe src="javascript:0" tabindex="-1" />').hide().appendTo('body')[0].contentWindow;
        this.navigate(fragment);
      }

      // Depending on whether we're using pushState or hashes, and whether
      // 'onhashchange' is supported, determine how we check the URL state.
      if (this._hasPushState) {
        Backbone.$(window).bind('popstate', this.checkUrl);
      } else if (this._wantsHashChange && ('onhashchange' in window) && !oldIE) {
        Backbone.$(window).bind('hashchange', this.checkUrl);
      } else if (this._wantsHashChange) {
        this._checkUrlInterval = setInterval(this.checkUrl, this.interval);
      }

      // Determine if we need to change the base url, for a pushState link
      // opened by a non-pushState browser.
      this.fragment = fragment;
      var loc = this.location;
      var atRoot = loc.pathname.replace(/[^\/]$/, '$&/') === this.root;

      // If we've started off with a route from a `pushState`-enabled browser,
      // but we're currently in a browser that doesn't support it...
      if (this._wantsHashChange && this._wantsPushState && !this._hasPushState && !atRoot) {
        this.fragment = this.getFragment(null, true);
        this.location.replace(this.root + this.location.search + '#' + this.fragment);
        // Return immediately as browser will do redirect to new url
        return true;

      // Or if we've started out with a hash-based route, but we're currently
      // in a browser where it could be `pushState`-based instead...
      } else if (this._wantsPushState && this._hasPushState && atRoot && loc.hash) {
        this.fragment = this.getHash().replace(routeStripper, '');
        this.history.replaceState({}, document.title, this.root + this.fragment + loc.search);
      }

      if (!this.options.silent) return this.loadUrl();
    },

    // Disable Backbone.history, perhaps temporarily. Not useful in a real app,
    // but possibly useful for unit testing Routers.
    stop: function() {
      Backbone.$(window).unbind('popstate', this.checkUrl).unbind('hashchange', this.checkUrl);
      clearInterval(this._checkUrlInterval);
      History.started = false;
    },

    // Add a route to be tested when the fragment changes. Routes added later
    // may override previous routes.
    route: function(route, callback) {
      this.handlers.unshift({route: route, callback: callback});
    },

    // Checks the current URL to see if it has changed, and if it has,
    // calls `loadUrl`, normalizing across the hidden iframe.
    checkUrl: function(e) {
      var current = this.getFragment();
      if (current === this.fragment && this.iframe) {
        current = this.getFragment(this.getHash(this.iframe));
      }
      if (current === this.fragment) return false;
      if (this.iframe) this.navigate(current);
      this.loadUrl() || this.loadUrl(this.getHash());
    },

    // Attempt to load the current URL fragment. If a route succeeds with a
    // match, returns `true`. If no defined routes matches the fragment,
    // returns `false`.
    loadUrl: function(fragmentOverride) {
      var fragment = this.fragment = this.getFragment(fragmentOverride);
      var matched = _.any(this.handlers, function(handler) {
        if (handler.route.test(fragment)) {
          handler.callback(fragment);
          return true;
        }
      });
      return matched;
    },

    // Save a fragment into the hash history, or replace the URL state if the
    // 'replace' option is passed. You are responsible for properly URL-encoding
    // the fragment in advance.
    //
    // The options object can contain `trigger: true` if you wish to have the
    // route callback be fired (not usually desirable), or `replace: true`, if
    // you wish to modify the current URL without adding an entry to the history.
    navigate: function(fragment, options) {
      if (!History.started) return false;
      if (!options || options === true) options = {trigger: options};
      fragment = this.getFragment(fragment || '');
      if (this.fragment === fragment) return;
      this.fragment = fragment;
      var url = this.root + fragment;

      // If pushState is available, we use it to set the fragment as a real URL.
      if (this._hasPushState) {
        this.history[options.replace ? 'replaceState' : 'pushState']({}, document.title, url);

      // If hash changes haven't been explicitly disabled, update the hash
      // fragment to store history.
      } else if (this._wantsHashChange) {
        this._updateHash(this.location, fragment, options.replace);
        if (this.iframe && (fragment !== this.getFragment(this.getHash(this.iframe)))) {
          // Opening and closing the iframe tricks IE7 and earlier to push a
          // history entry on hash-tag change.  When replace is true, we don't
          // want this.
          if(!options.replace) this.iframe.document.open().close();
          this._updateHash(this.iframe.location, fragment, options.replace);
        }

      // If you've told us that you explicitly don't want fallback hashchange-
      // based history, then `navigate` becomes a page refresh.
      } else {
        return this.location.assign(url);
      }
      if (options.trigger) this.loadUrl(fragment);
    },

    // Update the hash location, either replacing the current entry, or adding
    // a new one to the browser history.
    _updateHash: function(location, fragment, replace) {
      if (replace) {
        var href = location.href.replace(/(javascript:|#).*$/, '');
        location.replace(href + '#' + fragment);
      } else {
        // #1649 - Some browsers require that `hash` contains a leading #.
        location.hash = '#' + fragment;
      }
    }

  });

  // Create the default Backbone.history.
  Backbone.history = new History;

  // Backbone.View
  // -------------

  // Creating a Backbone.View creates its initial element outside of the DOM,
  // if an existing element is not provided...
  var View = Backbone.View = function(options) {
    this.cid = _.uniqueId('view');
    this._configure(options || {});
    this._ensureElement();
    this.initialize.apply(this, arguments);
    this.delegateEvents();
  };

  // Cached regex to split keys for `delegate`.
  var delegateEventSplitter = /^(\S+)\s*(.*)$/;

  // List of view options to be merged as properties.
  var viewOptions = ['model', 'collection', 'el', 'id', 'attributes', 'className', 'tagName'];

  // Set up all inheritable **Backbone.View** properties and methods.
  _.extend(View.prototype, Events, {

    // The default `tagName` of a View's element is `"div"`.
    tagName: 'div',

    // jQuery delegate for element lookup, scoped to DOM elements within the
    // current view. This should be prefered to global lookups where possible.
    $: function(selector) {
      return this.$el.find(selector);
    },

    // Initialize is an empty function by default. Override it with your own
    // initialization logic.
    initialize: function(){},

    // **render** is the core function that your view should override, in order
    // to populate its element (`this.el`), with the appropriate HTML. The
    // convention is for **render** to always return `this`.
    render: function() {
      return this;
    },

    // Clean up references to this view in order to prevent latent effects and
    // memory leaks.
    dispose: function() {
      this.undelegateEvents();
      if (this.model && this.model.off) this.model.off(null, null, this);
      if (this.collection && this.collection.off) this.collection.off(null, null, this);
      return this;
    },

    // Remove this view from the DOM. Note that the view isn't present in the
    // DOM by default, so calling this method may be a no-op.
    remove: function() {
      this.dispose();
      this.$el.remove();
      return this;
    },

    // For small amounts of DOM Elements, where a full-blown template isn't
    // needed, use **make** to manufacture elements, one at a time.
    //
    //     var el = this.make('li', {'class': 'row'}, this.model.escape('title'));
    //
    make: function(tagName, attributes, content) {
      var el = document.createElement(tagName);
      if (attributes) Backbone.$(el).attr(attributes);
      if (content != null) Backbone.$(el).html(content);
      return el;
    },

    // Change the view's element (`this.el` property), including event
    // re-delegation.
    setElement: function(element, delegate) {
      if (this.$el) this.undelegateEvents();
      this.$el = element instanceof Backbone.$ ? element : Backbone.$(element);
      this.el = this.$el[0];
      if (delegate !== false) this.delegateEvents();
      return this;
    },

    // Set callbacks, where `this.events` is a hash of
    //
    // *{"event selector": "callback"}*
    //
    //     {
    //       'mousedown .title':  'edit',
    //       'click .button':     'save'
    //       'click .open':       function(e) { ... }
    //     }
    //
    // pairs. Callbacks will be bound to the view, with `this` set properly.
    // Uses event delegation for efficiency.
    // Omitting the selector binds the event to `this.el`.
    // This only works for delegate-able events: not `focus`, `blur`, and
    // not `change`, `submit`, and `reset` in Internet Explorer.
    delegateEvents: function(events) {
      if (!(events || (events = _.result(this, 'events')))) return;
      this.undelegateEvents();
      for (var key in events) {
        var method = events[key];
        if (!_.isFunction(method)) method = this[events[key]];
        if (!method) throw new Error('Method "' + events[key] + '" does not exist');
        var match = key.match(delegateEventSplitter);
        var eventName = match[1], selector = match[2];
        method = _.bind(method, this);
        eventName += '.delegateEvents' + this.cid;
        if (selector === '') {
          this.$el.bind(eventName, method);
        } else {
          this.$el.delegate(selector, eventName, method);
        }
      }
    },

    // Clears all callbacks previously bound to the view with `delegateEvents`.
    // You usually don't need to use this, but may wish to if you have multiple
    // Backbone views attached to the same DOM element.
    undelegateEvents: function() {
      this.$el.unbind('.delegateEvents' + this.cid);
    },

    // Performs the initial configuration of a View with a set of options.
    // Keys with special meaning *(model, collection, id, className)*, are
    // attached directly to the view.
    _configure: function(options) {
      if (this.options) options = _.extend({}, this.options, options);
      _.extend(this, _.pick(options, viewOptions));
      this.options = options;
    },

    // Ensure that the View has a DOM element to render into.
    // If `this.el` is a string, pass it through `$()`, take the first
    // matching element, and re-assign it to `el`. Otherwise, create
    // an element from the `id`, `className` and `tagName` properties.
    _ensureElement: function() {
      if (!this.el) {
        var attrs = _.extend({}, _.result(this, 'attributes'));
        if (this.id) attrs.id = _.result(this, 'id');
        if (this.className) attrs['class'] = _.result(this, 'className');
        this.setElement(this.make(_.result(this, 'tagName'), attrs), false);
      } else {
        this.setElement(_.result(this, 'el'), false);
      }
    }

  });

  // Backbone.sync
  // -------------

  // Map from CRUD to HTTP for our default `Backbone.sync` implementation.
  var methodMap = {
    'create': 'POST',
    'update': 'PUT',
    'delete': 'DELETE',
    'read':   'GET'
  };

  // Override this function to change the manner in which Backbone persists
  // models to the server. You will be passed the type of request, and the
  // model in question. By default, makes a RESTful Ajax request
  // to the model's `url()`. Some possible customizations could be:
  //
  // * Use `setTimeout` to batch rapid-fire updates into a single request.
  // * Send up the models as XML instead of JSON.
  // * Persist models via WebSockets instead of Ajax.
  //
  // Turn on `Backbone.emulateHTTP` in order to send `PUT` and `DELETE` requests
  // as `POST`, with a `_method` parameter containing the true HTTP method,
  // as well as all requests with the body as `application/x-www-form-urlencoded`
  // instead of `application/json` with the model in a param named `model`.
  // Useful when interfacing with server-side languages like **PHP** that make
  // it difficult to read the body of `PUT` requests.
  Backbone.sync = function(method, model, options) {
    var type = methodMap[method];

    // Default options, unless specified.
    _.defaults(options || (options = {}), {
      emulateHTTP: Backbone.emulateHTTP,
      emulateJSON: Backbone.emulateJSON
    });

    // Default JSON-request options.
    var params = {type: type, dataType: 'json'};

    // Ensure that we have a URL.
    if (!options.url) {
      params.url = _.result(model, 'url') || urlError();
    }

    // Ensure that we have the appropriate request data.
    if (!options.data && model && (method === 'create' || method === 'update')) {
      params.contentType = 'application/json';
      params.data = JSON.stringify(model);
    }

    // For older servers, emulate JSON by encoding the request into an HTML-form.
    if (options.emulateJSON) {
      params.contentType = 'application/x-www-form-urlencoded';
      params.data = params.data ? {model: params.data} : {};
    }

    // For older servers, emulate HTTP by mimicking the HTTP method with `_method`
    // And an `X-HTTP-Method-Override` header.
    if (options.emulateHTTP && (type === 'PUT' || type === 'DELETE')) {
      params.type = 'POST';
      if (options.emulateJSON) params.data._method = type;
      var beforeSend = options.beforeSend;
      options.beforeSend = function(xhr) {
        xhr.setRequestHeader('X-HTTP-Method-Override', type);
        if (beforeSend) return beforeSend.apply(this, arguments);
      };
    }

    // Don't process data on a non-GET request.
    if (params.type !== 'GET' && !options.emulateJSON) {
      params.processData = false;
    }

    var success = options.success;
    options.success = function(resp, status, xhr) {
      if (success) success(resp, status, xhr);
      model.trigger('sync', model, resp, options);
    };

    var error = options.error;
    options.error = function(xhr, status, thrown) {
      if (error) error(model, xhr, options);
      model.trigger('error', model, xhr, options);
    };

    // Make the request, allowing the user to override any Ajax options.
    return Backbone.ajax(_.extend(params, options));
  };

  // Set the default implementation of `Backbone.ajax` to proxy through to `$`.
  Backbone.ajax = function() {
    return Backbone.$.ajax.apply(Backbone.$, arguments);
  };

  // Helpers
  // -------

  // Helper function to correctly set up the prototype chain, for subclasses.
  // Similar to `goog.inherits`, but uses a hash of prototype properties and
  // class properties to be extended.
  var extend = function(protoProps, staticProps) {
    var parent = this;
    var child;

    // The constructor function for the new subclass is either defined by you
    // (the "constructor" property in your `extend` definition), or defaulted
    // by us to simply call the parent's constructor.
    if (protoProps && _.has(protoProps, 'constructor')) {
      child = protoProps.constructor;
    } else {
      child = function(){ parent.apply(this, arguments); };
    }

    // Add static properties to the constructor function, if supplied.
    _.extend(child, parent, staticProps);

    // Set the prototype chain to inherit from `parent`, without calling
    // `parent`'s constructor function.
    var Surrogate = function(){ this.constructor = child; };
    Surrogate.prototype = parent.prototype;
    child.prototype = new Surrogate;

    // Add prototype properties (instance properties) to the subclass,
    // if supplied.
    if (protoProps) _.extend(child.prototype, protoProps);

    // Set a convenience property in case the parent's prototype is needed
    // later.
    child.__super__ = parent.prototype;

    return child;
  };

  // Set up inheritance for the model, collection, router, view and history.
  Model.extend = Collection.extend = Router.extend = View.extend = History.extend = extend;

  // Throw an error when a URL is needed, and none is supplied.
  var urlError = function() {
    throw new Error('A "url" property or function must be specified');
  };

}).call(this);

define("backbone", ["underscore"], (function (global) {
    return function () {
        return global.Backbone;
    }
}(this)));

/*global define */

define('grapher/bar-graph/bar-graph-model',['require','backbone'],function (require) {
  // Dependencies.
  var Backbone = require('backbone'),

      BarGraphModel = Backbone.Model.extend({
        defaults: {
          // Current value displayed by bar graph.
          value:     0,
          // Min value displayed.
          minValue:  0,
          // Max value displayed.
          maxValue:  10,

          // Dimensions of the bar graph
          // (including axis and labels).
          width:     150,
          height:    500,

          // Graph title.
          title:     "",
          // Color of the main bar.
          barColor:  "green",
          // Color of the area behind the bar.
          fillColor: "white",
          // Color of axis, labels, title.
          textColor: "#555",
          // Number of ticks displayed on the axis.
          // This value is *only* a suggestion. The most clean
          // and human-readable values are used.
          ticks:          10,
          // Number of subdivisions between major ticks.
          tickSubdivide: 1,
          // Enables or disables displaying of numerical labels.
          displayLabels: true,
          // Format of labels.
          // See the specification of this format:
          // https://github.com/mbostock/d3/wiki/Formatting#wiki-d3_format
          // or:
          // http://docs.python.org/release/3.1.3/library/string.html#formatspec
          labelFormat: "0.1f"
        }
      });

  return BarGraphModel;
});

/*global define, d3 */

define('grapher/bar-graph/bar-graph-view',['require','backbone'],function (require) {
  // Dependencies.
  var Backbone = require('backbone'),

      VIEW = {
        padding: {
          left:   10,
          top:    10,
          right:  10,
          bottom: 10
        }
      },

      // Get real width SVG of element using bounding box.
      getRealWidth = function (d3selection) {
        return d3selection.node().getBBox().width;
      },

      // Get real height SVG of element using bounding box.
      getRealHeight = function (d3selection) {
        return d3selection.node().getBBox().height;
      },

      // Bar graph scales itself according to the given height.
      // We assume some CANONICAL_HEIGHT. All values which should
      // be scaled, should assume this canonical height as basic
      // reference.
      CANONICAL_HEIGHT = 500,
      getScaleFunc = function (height) {
        var factor = height / CANONICAL_HEIGHT;
        // Prevent from too small fonts.
        if (factor < 0.6)
          factor = 0.6;

        return function (val) {
          return val * factor;
        };
      },

      setupValueLabelPairs = function (yAxis, ticks) {
        var values = [],
            labels = {},
            i, len;

        for (i = 0, len = ticks.length; i < len; i++) {
          values[i] = ticks[i].value;
          labels[values[i]] = ticks[i].label;
        }

        yAxis
          .tickValues(values)
          .tickFormat(function (value) {
            return labels[value];
          });
      },

      BarGraphView = Backbone.View.extend({
        // Container is a DIV.
        tagName: "div",

        className: "bar-graph",

        initialize: function () {
          // Create all SVG elements ONLY in this function.
          // Avoid recreation of SVG elements while rendering.
          this.vis = d3.select(this.el).append("svg");
          this.fill = this.vis.append("rect");
          this.bar = this.vis.append("rect");
          this.title = this.vis.append("text");
          this.axisContainer = this.vis.append("g");

          this.yScale = d3.scale.linear();
          this.heightScale = d3.scale.linear();
          this.yAxis = d3.svg.axis();

          // Register callbacks!
          this.model.on("change", this.modelChanged, this);
        },

        // Render whole bar graph.
        render: function () {
              // toJSON() returns all attributes of the model.
              // This is equivalent to many calls like:
              // property1 = model.get("property1");
              // property2 = model.get("property2");
              // etc.
          var options    = this.model.toJSON(),
              // Scale function.
              scale      = getScaleFunc(options.height),
              // Basic padding (scaled).
              paddingLeft   = scale(VIEW.padding.left),
              paddingTop    = scale(VIEW.padding.top),
              paddingBottom = scale(VIEW.padding.bottom),
              // Note that right padding is especially important
              // in this function, as we are constructing bar graph
              // from right to left side. This variable holds current
              // padding. Later it is modified by appending of title,
              // axis, labels and all necessary elements.
              paddingRight  = scale(VIEW.padding.right);

          // Setup SVG element.
          this.vis
            .attr({
              "width":  options.width,
              "height": options.height
            })
            .style({
              "font-size": scale(15) + "px"
            });

          // Setup Y scale.
          this.yScale
            .domain([options.minValue, options.maxValue])
            .range([options.height - paddingTop, paddingBottom]);

          // Setup scale used to translation of the bar height.
          this.heightScale
            .domain([options.minValue, options.maxValue])
            .range([0, options.height - paddingTop - paddingBottom]);

          // Setup title.
          if (options.title !== undefined) {
            this.title
              .text(options.title)
              .style({
                "font-size": "140%",
                "text-anchor": "middle",
                "fill": options.textColor
              });

            // Rotate title and translate it into right place.
            // We do we use height for calculating right margin?
            // Text will be rotated 90*, so current height is expected width.
            paddingRight += getRealHeight(this.title);
            this.title
              .attr("transform", "translate(" + (options.width - paddingRight) + ", " + options.height / 2 + ") rotate(90)");
          }

          // Setup Y axis.
          this.yAxis
            .scale(this.yScale)
            .tickSubdivide(options.tickSubdivide)
            .tickSize(scale(10), scale(5), scale(10))
            .orient("right");

          if (typeof options.ticks === "number") {
            // Just normal tics.
            this.yAxis
              .ticks(options.ticks)
              .tickFormat(d3.format(options.labelFormat));
          } else {
            // Array with value - label pairs.
            setupValueLabelPairs(this.yAxis, options.ticks);
          }

          // Create and append Y axis.
          this.axisContainer
            .call(this.yAxis);

          // Style Y axis.
          this.axisContainer
            .style({
              "stroke": options.textColor,
              "stroke-width": scale(2),
              "fill": "none"
            });

          // Style Y axis labels.
          this.axisContainer.selectAll("text")
            .style({
              "fill": options.textColor,
              "stroke-width": 0,
              // Workaround for hiding numeric labels. D3 doesn't provide any convenient function
              // for that. Returning empty string as tickFormat causes that bounding box width is
              // calculated incorrectly.
              "font-size": options.displayLabels ? "100%" : 0
          });

          // Remove axis completely if ticks are equal to 0.
          if (options.ticks === 0)
            this.axisContainer.selectAll("*").remove();

          // Translate axis into right place, add narrow empty space.
          // Note that this *have* to be done after all styling to get correct width of bounding box!
          paddingRight += getRealWidth(this.axisContainer) + scale(7);
          this.axisContainer
            .attr("transform", "translate(" + (options.width - paddingRight) + ", 0)");

          // Setup background of the bar.
          paddingRight += scale(5);
          this.fill
            .attr({
              "width": (options.width - paddingLeft - paddingRight),
              "height": this.heightScale(options.maxValue),
              "x": paddingLeft,
              "y": this.yScale(options.maxValue)
            })
            .style({
              "fill": options.fillColor
            });

          // Setup the main bar.
          this.bar
            .attr({
              "width": (options.width - paddingLeft - paddingRight),
              "x": paddingLeft
            })
            .style({
              "fill": options.barColor
            });

          // Finally, update bar.
          this.updateBar();
        },

        // Updates only bar height.
        updateBar: function () {
          var value = this.model.get("value");
          this.bar
            .attr("height", this.heightScale(value))
            .attr("y", this.yScale(value));
        },

        // This function should be called whenever model attribute is changed.
        modelChanged: function () {
          var changedAttributes = this.model.changedAttributes(),
              changedAttrsCount = 0,
              name;

          // There are two possible cases.
          // Only "value" has changed, so update only bar height.
          // Other attributes have changed, so redraw whole bar graph.

          // Case 1. Check how many attributes have been changed.
          for (name in changedAttributes) {
            if (changedAttributes.hasOwnProperty(name)) {
              changedAttrsCount++;
              if (changedAttrsCount > 1) {
                // If 2 or more, redraw whole bar graph.
                this.render();
                return;
              }
            }
          }

          // Case 2. Only one attribute has changed, check if it's "value".
          if (changedAttributes.value !== undefined) {
            this.updateBar();
          } else {
            this.render();
          }
        }
      });

  return BarGraphView;
});

/*global $: false, define: false, model: false */

// Bar graph controller.
// It provides specific interface used in MD2D environment
// (by interactives-controller and layout module).
define('common/controllers/bar-graph-controller',['require','grapher/bar-graph/bar-graph-model','grapher/bar-graph/bar-graph-view','common/controllers/interactive-metadata','common/validator'],function (require) {
  var BarGraphModel = require('grapher/bar-graph/bar-graph-model'),
      BarGraphView  = require('grapher/bar-graph/bar-graph-view'),
      metadata      = require('common/controllers/interactive-metadata'),
      validator     = require('common/validator'),

      // Note: We always explicitly copy properties from component spec to bar graph options hash,
      // in order to avoid tighly coupling an externally-exposed API (the component spec) to an
      // internal implementation detail (the bar graph options format).
      barGraphOptionForComponentSpecProperty = {
        // Min value displayed.
        minValue:  'minValue',
        // Max value displayed.
        maxValue:  'maxValue',
        // Graph title.
        title:     'title',
        // Color of the main bar.
        barColor:  'barColor',
        // Color of the area behind the bar.
        fillColor: 'fillColor',
        // Color of axis, labels, title.
        textColor: 'textColor',
        // Number of ticks displayed on the axis.
        // This value is *only* a suggestion. The most clean
        // and human-readable values are used.
        ticks:      'ticks',
        // Number of subdivisions between major ticks.
        tickSubdivide: 'tickSubdivide',
        // Enables or disables displaying of numerical labels.
        displayLabels: 'displayLabels',
        // Format of labels.
        // See the specification of this format:
        // https://github.com/mbostock/d3/wiki/Formatting#wiki-d3_format
        // or:
        // http://docs.python.org/release/3.1.3/library/string.html#formatspec
        labelFormat: 'labelFormat'
      },

      // Limit options only to these supported.
      filterOptions = function(inputHash) {
        var options = {},
            cName, gName;

        for (cName in barGraphOptionForComponentSpecProperty) {
          if (barGraphOptionForComponentSpecProperty.hasOwnProperty(cName)) {
            gName = barGraphOptionForComponentSpecProperty[cName];
            if (inputHash[cName] !== undefined) {
              options[gName] = inputHash[cName];
            }
          }
        }
        return options;
      };

  return function BarGraphController(component) {
    var // Object with Public API.
        controller,
        // Model with options and current value.
        barGraphModel,
        // Main view.
        barGraphView,
        // First data channel.
        property,

        update = function () {
          barGraphModel.set({value: model.get(property)});
        };

    //
    // Initialization.
    //
    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.barGraph, component);
    barGraphModel = new BarGraphModel(filterOptions(component.options));
    barGraphView  = new BarGraphView({model: barGraphModel, id: component.id});
    // Apply custom width and height settings.
    barGraphView.$el.css({
      width: component.width,
      height: component.height
    });
    property = component.property;

    controller = {
      // This callback should be trigger when model is loaded.
      modelLoadedCallback: function () {
        if (property) {
          model.addPropertiesListener([property], update);
        }
        // Initial render...
        barGraphView.render();
        // and update.
        update();
      },

      // Returns view container (div).
      getViewContainer: function () {
        return barGraphView.$el;
      },

      // Method required by layout module.
      resize: function () {
        // Inform model about possible new dimensions (when $el dimensions
        // are specified in % or em, they will probably change each time
        // the interactive container is changed). It's important to do that,
        // as various visual elements can be adjusted (font size, padding etc.).
        barGraphModel.set({
          width: barGraphView.$el.width(),
          height: barGraphView.$el.height()
        });
      },

      // Returns serialized component definition.
      serialize: function () {
        var result = $.extend(true, {}, component);
        // Update options.
        result.options = filterOptions(barGraphModel.toJSON());
        // Return updated definition.
        return result;
      }
    };

    // Return Public API object.
    return controller;
  };
});

/*globals define */
//TODO: Should change and newdomain be global variables?

define('grapher/core/axis',['require'],function (require) {
  return {
    axisProcessDrag: function(dragstart, currentdrag, domain) {
      var originExtent, maxDragIn,
          newdomain = domain,
          origin = 0,
          axis1 = domain[0],
          axis2 = domain[1],
          extent = axis2 - axis1;
      if (currentdrag !== 0) {
        if  ((axis1 >= 0) && (axis2 > axis1)) {                 // example: (20, 10, [0, 40]) => [0, 80]
          origin = axis1;
          originExtent = dragstart-origin;
          maxDragIn = originExtent * 0.2 + origin;
          if (currentdrag > maxDragIn) {
            change = originExtent / (currentdrag-origin);
            extent = axis2 - origin;
            newdomain = [axis1, axis1 + (extent * change)];
          }
        } else if ((axis1 < 0) && (axis2 > 0)) {                // example: (20, 10, [-40, 40])       => [-80, 80]
          origin = 0;                                           //          (-0.4, -0.2, [-1.0, 0.4]) => [-1.0, 0.4]
          originExtent = dragstart-origin;
          maxDragIn = originExtent * 0.2 + origin;
          if ((dragstart >= 0 && currentdrag > maxDragIn) || (dragstart  < 0  && currentdrag < maxDragIn)) {
            change = originExtent / (currentdrag-origin);
            newdomain = [axis1 * change, axis2 * change];
          }
        } else if ((axis1 < 0) && (axis2 < 0)) {                // example: (-60, -50, [-80, -40]) => [-120, -40]
          origin = axis2;
          originExtent = dragstart-origin;
          maxDragIn = originExtent * 0.2 + origin;
          if (currentdrag < maxDragIn) {
            change = originExtent / (currentdrag-origin);
            extent = axis1 - origin;
            newdomain = [axis2 + (extent * change), axis2];
          }
        }
      }
      return newdomain;
    }
  };
});

/*globals define, d3, $ */

define('grapher/core/real-time-graph',['require','grapher/core/axis'],function (require) {
  // Dependencies.
  var axis = require('grapher/core/axis');

  return function RealTimeGraph(idOrElement, options, message) {
    var elem,
        node,
        cx,
        cy,

        stroke = function(d) { return d ? "#ccc" : "#666"; },
        tx = function(d) { return "translate(" + xScale(d) + ",0)"; },
        ty = function(d) { return "translate(0," + yScale(d) + ")"; },
        fx, fy,
        svg, vis, plot, viewbox,
        title, xlabel, ylabel, xtic, ytic,
        notification,
        padding, size,
        xScale, yScale, line,
        shiftingX = false,
        cubicEase = d3.ease('cubic'),
        ds,
        circleCursorStyle,
        displayProperties,
        emsize, strokeWidth,
        scaleFactor,
        sizeType = {
          category: "medium",
          value: 3,
          icon: 120,
          tiny: 240,
          small: 480,
          medium: 960,
          large: 1920
        },
        downx = Math.NaN,
        downy = Math.NaN,
        dragged = null,
        selected = null,
        titles = [],

        points, pointArray,
        markedPoint, marker,
        sample,
        gcanvas, gctx,
        cplot = {},

        default_options = {
          title   : "graph",
          xlabel  : "x-axis",
          ylabel  : "y-axis",
          xscale  : 'linear',
          yscale  : 'linear',
          xTicCount: 10,
          yTicCount: 10,
          xscaleExponent: 0.5,
          yscaleExponent: 0.5,
          xFormatter: "3.2r",
          yFormatter: "3.2r",
          axisShift:  10,
          xmax:       10,
          xmin:       0,
          ymax:       10,
          ymin:       0,
          dataset:    [0],
          selectable_points: true,
          circleRadius: false,
          dataChange: false,
          points: false,
          sample: 1,
          lines: true,
          bars: false
        };

    initialize(idOrElement, options, message);

    function setupOptions(options) {
      if (options) {
        for(var p in default_options) {
          if (options[p] === undefined) {
            options[p] = default_options[p];
          }
        }
      } else {
        options = default_options;
      }
      if (options.axisShift < 1) options.axisShift = 1;
      return options;
    }

    function calculateSizeType() {
      if(cx <= sizeType.icon) {
        sizeType.category = 'icon';
        sizeType.value = 0;
      } else if (cx <= sizeType.tiny) {
        sizeType.category = 'tiny';
        sizeType.value = 1;
      } else if (cx <= sizeType.small) {
        sizeType.category = 'small';
        sizeType.value = 2;
      } else if (cx <= sizeType.medium) {
        sizeType.category = 'medium';
        sizeType.value = 3;
      } else if (cx <= sizeType.large) {
        sizeType.category = 'large';
        sizeType.value = 4;
      } else {
        sizeType.category = 'extralarge';
        sizeType.value = 5;
      }
    }

    function scale(w, h) {
      if (!w && !h) {
        cx = elem.property("clientWidth");
        cy = elem.property("clientHeight");
      } else {
        cx = w;
        node.style.width =  cx +"px";
        if (!h) {
          node.style.height = "100%";
          h = elem.property("clientHeight");
          cy = h;
          node.style.height = cy +"px";
        } else {
          cy = h;
          node.style.height = cy +"px";
        }
      }
      calculateSizeType();
      emsize = parseFloat($(idOrElement).css('font-size')) / 10;
    }

    function initialize(idOrElement, opts, message) {
      if (idOrElement) {
        // d3.select works both for element ID (e.g. "#grapher")
        // and for DOM element.
        elem = d3.select(idOrElement);
        node = elem.node();
        cx = elem.property("clientWidth");
        cy = elem.property("clientHeight");
      }

      if (opts || !options) {
        options = setupOptions(opts);
      }

      if (svg !== undefined) {
        svg.remove();
        svg = undefined;
      }

      if (gcanvas !== undefined) {
        $(gcanvas).remove();
        gcanvas = undefined;
      }

      // use local variable for access speed in add_point()
      sample = options.sample;

      if (options.dataChange) {
        circleCursorStyle = "ns-resize";
      } else {
        circleCursorStyle = "crosshair";
      }

      scale();

      options.xrange = options.xmax - options.xmin;
      options.yrange = options.ymax - options.ymin;

      pointArray = [];

      switch(sizeType.value) {
        case 0:
        padding = {
         "top":    4,
         "right":  4,
         "bottom": 4,
         "left":   4
        };
        break;

        case 1:
        padding = {
         "top":    8,
         "right":  8,
         "bottom": 8,
         "left":   8
        };
        break;

        case 2:
        padding = {
         "top":    options.title  ? 25 : 15,
         "right":  15,
         "bottom": 20,
         "left":   30
        };
        break;

        case 3:
        padding = {
         "top":    options.title  ? 30 : 20,
         "right":                   30,
         "bottom": options.xlabel ? 60 : 10,
         "left":   options.ylabel ? 70 : 45
        };
        break;

        default:
        padding = {
         "top":    options.title  ? 40 : 20,
         "right":                   30,
         "bottom": options.xlabel ? 60 : 10,
         "left":   options.ylabel ? 70 : 45
        };
        break;
      }

      if (Object.prototype.toString.call(options.dataset[0]) === "[object Array]") {
        for (var i = 0; i < options.dataset.length; i++) {
          pointArray.push(indexedData(options.dataset[i], 0, sample));
        }
        points = pointArray[0];
      } else {
        points = indexedData(options.dataset, 0);
        pointArray = [points];
      }

      if (Object.prototype.toString.call(options.title) === "[object Array]") {
        titles = options.title;
      } else {
        titles = [options.title];
      }
      titles.reverse();

      if (sizeType.value > 2 ) {
        padding.top += (titles.length-1) * sizeType.value/3 * sizeType.value/3 * emsize * 22;
      } else {
        titles = [titles[0]];
      }

      size = {
        "width":  cx - padding.left - padding.right,
        "height": cy - padding.top  - padding.bottom
      };

      xScale = d3.scale[options.xscale]()
        .domain([options.xmin, options.xmax])
        .range([0, size.width]);

      if (options.xscale === "pow") {
        xScale.exponent(options.xscaleExponent);
      }

      yScale = d3.scale[options.yscale]()
        .domain([options.ymin, options.ymax]).nice()
        .range([size.height, 0]).nice();

      if (options.yscale === "pow") {
        yScale.exponent(options.yscaleExponent);
      }

      fx = d3.format(options.xFormatter);
      fy = d3.format(options.yFormatter);

      line = d3.svg.line()
            .x(function(d, i) { return xScale(points[i].x ); })
            .y(function(d, i) { return yScale(points[i].y); });

      // drag axis logic
      downx = Math.NaN;
      downy = Math.NaN;
      dragged = null;
    }


    function indexedData(dataset, initial_index, sample) {
      var i = 0,
          start_index = initial_index || 0,
          n = dataset.length,
          points = [];
      sample = sample || 1;
      for (i = 0; i < n;  i++) {
        points.push({ x: (i + start_index) * sample, y: dataset[i] });
      }
      return points;
    }

    function number_of_points() {
      if (points) {
        return points.length;
      } else {
        return false;
      }
    }

    function graph() {
      scale();

      if (svg === undefined) {

        svg = elem.append("svg")
            .attr("width",  cx)
            .attr("height", cy);

        vis = svg.append("g")
              .attr("transform", "translate(" + padding.left + "," + padding.top + ")");

        plot = vis.append("rect")
          .attr("class", "plot")
          .attr("width", size.width)
          .attr("height", size.height)
          .style("fill", "#EEEEEE")
          // .attr("fill-opacity", 0.0)
          .attr("pointer-events", "all")
          .on("mousedown", plot_drag)
          .on("touchstart", plot_drag);

        plot.call(d3.behavior.zoom().x(xScale).y(yScale).on("zoom", redraw));

        viewbox = vis.append("svg")
          .attr("class", "viewbox")
          .attr("top", 0)
          .attr("left", 0)
          .attr("width", size.width)
          .attr("height", size.height)
          .attr("viewBox", "0 0 "+size.width+" "+size.height)
          .append("path")
              .attr("class", "line")
              .attr("d", line(points));

        marker = viewbox.append("path").attr("class", "marker");
        // path without attributes cause SVG parse problem in IE9
        //     .attr("d", []);

        // add Chart Title
        if (options.title && sizeType.value > 1) {
          title = vis.selectAll("text")
            .data(titles, function(d) { return d; });
          title.enter().append("text")
              .attr("class", "title")
              .style("font-size", sizeType.value/3.2 * 100 + "%")
              .text(function(d) { return d; })
              .attr("x", size.width/2)
              .attr("dy", function(d, i) { return -0.5 + -1 * sizeType.value/2.8 * i * emsize + "em"; })
              .style("text-anchor","middle");
        }

        // Add the x-axis label
       if (options.xlabel && sizeType.value > 2) {
          xlabel = vis.append("text")
              .attr("class", "axis")
              .style("font-size", sizeType.value/2.6 * 100 + "%")
              .attr("class", "xlabel")
              .text(options.xlabel)
              .attr("x", size.width/2)
              .attr("y", size.height)
              .attr("dy","2.4em")
              .style("text-anchor","middle");
        }

        // add y-axis label
        if (options.ylabel && sizeType.value > 2) {
          ylabel = vis.append("g").append("text")
              .attr("class", "axis")
              .style("font-size", sizeType.value/2.6 * 100 + "%")
              .attr("class", "ylabel")
              .text( options.ylabel)
              .style("text-anchor","middle")
              .attr("transform","translate(" + -40 + " " + size.height/2+") rotate(-90)");
        }

        notification = vis.append("text")
            .attr("class", "graph-notification")
            .text(message)
            .attr("x", size.width/2)
            .attr("y", size.height/2)
            .style("text-anchor","middle");

        d3.select(node)
            .on("mousemove.drag", mousemove)
            .on("touchmove.drag", mousemove)
            .on("mouseup.drag",   mouseup)
            .on("touchend.drag",  mouseup);

        initialize_canvas();
        show_canvas();

      } else {

        vis
          .attr("width",  cx)
          .attr("height", cy);

        plot
          .attr("width", size.width)
          .attr("height", size.height)
          .style("fill", "#EEEEEE");

        viewbox
            .attr("top", 0)
            .attr("left", 0)
            .attr("width", size.width)
            .attr("height", size.height)
            .attr("viewBox", "0 0 "+size.width+" "+size.height);

        if (options.title && sizeType.value > 1) {
            title.each(function(d, i) {
              d3.select(this).attr("x", size.width/2);
              d3.select(this).attr("dy", function(d, i) { return 1.4 * i - titles.length + "em"; });
            });
        }

        if (options.xlabel && sizeType.value > 1) {
          xlabel
              .attr("x", size.width/2)
              .attr("y", size.height);
        }

        if (options.ylabel && sizeType.value > 1) {
          ylabel
              .attr("transform","translate(" + -40 + " " + size.height/2+") rotate(-90)");
        }

        notification
          .attr("x", size.width/2)
          .attr("y", size.height/2);

        vis.selectAll("g.x").remove();
        vis.selectAll("g.y").remove();

        resize_canvas();
      }

      redraw();

      // ------------------------------------------------------------
      //
      // Chart Notification
      //
      // ------------------------------------------------------------

      function notify(mesg) {
        message = mesg;
        if (mesg) {
          notification.text(mesg);
        } else {
          notification.text('');
        }
      }

      // ------------------------------------------------------------
      //
      // Redraw the plot canvas when it is translated or axes are re-scaled
      //
      // ------------------------------------------------------------

      function redraw() {

        // Regenerate x-ticks
        var gx = vis.selectAll("g.x")
            .data(xScale.ticks(options.xTicCount), String)
            .attr("transform", tx);

        var gxe = gx.enter().insert("g", "a")
            .attr("class", "x")
            .attr("transform", tx);

        gxe.append("line")
            .attr("stroke", stroke)
            .attr("y1", 0)
            .attr("y2", size.height);

        if (sizeType.value > 1) {
          gxe.append("text")
              .attr("class", "axis")
              .style("font-size", sizeType.value/2.7 * 100 + "%")
              .attr("y", size.height)
              .attr("dy", "1em")
              .attr("text-anchor", "middle")
              .style("cursor", "ew-resize")
              .text(fx)
              .on("mouseover", function(d) { d3.select(this).style("font-weight", "bold");})
              .on("mouseout",  function(d) { d3.select(this).style("font-weight", "normal");})
              .on("mousedown.drag",  xaxis_drag)
              .on("touchstart.drag", xaxis_drag);
        }

        gx.exit().remove();

        // Regenerate y-ticks
        var gy = vis.selectAll("g.y")
            .data(yScale.ticks(options.yTicCount), String)
            .attr("transform", ty);

        var gye = gy.enter().insert("g", "a")
            .attr("class", "y")
            .attr("transform", ty)
            .attr("background-fill", "#FFEEB6");

        gye.append("line")
            .attr("stroke", stroke)
            .attr("x1", 0)
            .attr("x2", size.width);

        if (sizeType.value > 1) {
          gye.append("text")
              .attr("class", "axis")
              .style("font-size", sizeType.value/2.7 * 100 + "%")
              .attr("x", -3)
              .attr("dy", ".35em")
              .attr("text-anchor", "end")
              .style("cursor", "ns-resize")
              .text(fy)
              .on("mouseover", function(d) { d3.select(this).style("font-weight", "bold");})
              .on("mouseout",  function(d) { d3.select(this).style("font-weight", "normal");})
              .on("mousedown.drag",  yaxis_drag)
              .on("touchstart.drag", yaxis_drag);
        }

        gy.exit().remove();
        plot.call(d3.behavior.zoom().x(xScale).y(yScale).on("zoom", redraw));
        update();
      }

      // ------------------------------------------------------------
      //
      // Draw the data
      //
      // ------------------------------------------------------------

      function update(currentSample) {
        update_canvas(currentSample);

        if (graph.selectable_points) {
          var circle = vis.selectAll("circle")
              .data(points, function(d) { return d; });

          circle.enter().append("circle")
              .attr("class", function(d) { return d === selected ? "selected" : null; })
              .attr("cx",    function(d) { return x(d.x); })
              .attr("cy",    function(d) { return y(d.y); })
              .attr("r", 1.0)
              .on("mousedown", function(d) {
                selected = dragged = d;
                update();
              });

          circle
              .attr("class", function(d) { return d === selected ? "selected" : null; })
              .attr("cx",    function(d) { return x(d.x); })
              .attr("cy",    function(d) { return y(d.y); });

          circle.exit().remove();
        }

        if (d3.event && d3.event.keyCode) {
          d3.event.preventDefault();
          d3.event.stopPropagation();
        }
      }

      function plot_drag() {
        d3.event.preventDefault();
        plot.style("cursor", "move");
        if (d3.event.altKey) {
          var p = d3.svg.mouse(vis[0][0]);
          downx = xScale.invert(p[0]);
          downy = yScale.invert(p[1]);
          dragged = false;
          d3.event.stopPropagation();
        }
      }

      function xaxis_drag(d) {
        document.onselectstart = function() { return false; };
        d3.event.preventDefault();
        var p = d3.svg.mouse(vis[0][0]);
        downx = xScale.invert(p[0]);
      }

      function yaxis_drag(d) {
        document.onselectstart = function() { return false; };
        d3.event.preventDefault();
        var p = d3.svg.mouse(vis[0][0]);
        downy = yScale.invert(p[1]);
      }

      // ------------------------------------------------------------
      //
      // Axis scaling
      //
      // attach the mousemove and mouseup to the body
      // in case one wanders off the axis line
      // ------------------------------------------------------------

      function mousemove() {
        var p = d3.svg.mouse(vis[0][0]),
            changex, changey, new_domain,
            t = d3.event.changedTouches;

        document.onselectstart = function() { return true; };
        d3.event.preventDefault();
        if (!isNaN(downx)) {
          d3.select('body').style("cursor", "ew-resize");
          xScale.domain(axis.axisProcessDrag(downx, xScale.invert(p[0]), xScale.domain()));
          redraw();
          d3.event.stopPropagation();
        }
        if (!isNaN(downy)) {
          d3.select('body').style("cursor", "ns-resize");
          yScale.domain(axis.axisProcessDrag(downy, yScale.invert(p[1]), yScale.domain()));
          redraw();
          d3.event.stopPropagation();
        }
      }

      function mouseup() {
        d3.select('body').style("cursor", "auto");
        document.onselectstart = function() { return true; };
        if (!isNaN(downx)) {
          redraw();
          downx = Math.NaN;
        }
        if (!isNaN(downy)) {
          redraw();
          downy = Math.NaN;
        }
        dragged = null;
      }

      function showMarker(index) {
        markedPoint = { x: points[index].x, y: points[index].y };
      }

      function updateOrRescale(currentSample) {
        var i,
            domain = xScale.domain(),
            xAxisStart = Math.round(domain[0]/sample),
            xAxisEnd = Math.round(domain[1]/sample),
            start = Math.max(0, xAxisStart),
            xextent = domain[1] - domain[0],
            shiftPoint = xextent * 0.9,
            currentExtent;

         if (typeof currentSample !== "number") {
           currentSample = points.length;
         }
         currentExtent = currentSample * sample;
         if (shiftingX) {
           shiftingX = ds();
            if (shiftingX) {
            redraw();
          } else {
            update(currentSample);
          }
        } else {
          if (currentExtent > domain[0] + shiftPoint) {
            ds = shiftXDomain(shiftPoint*0.9, options.axisShift);
            shiftingX = ds();
            redraw();
          } else if ( currentExtent < domain[1] - shiftPoint &&
                      currentSample < points.length &&
                      xAxisStart > 0) {
            ds = shiftXDomain(shiftPoint*0.9, options.axisShift, -1);
            shiftingX = ds();
            redraw();
          } else if (currentExtent < domain[0]) {
            ds = shiftXDomain(shiftPoint*0.1, 1, -1);
            shiftingX = ds();
            redraw();

          } else {
            update(currentSample);
          }
        }
      }

      function shiftXDomain(shift, steps, direction) {
        var d0 = xScale.domain()[0],
            d1 = xScale.domain()[1],
            increment = 1/steps,
            index = 0;
        return function() {
          var factor;
          direction = direction || 1;
          index += increment;
          factor = shift * cubicEase(index);
          if (direction > 0) {
            xScale.domain([d0 + factor, d1 + factor]);
            return xScale.domain()[0] < (d0 + shift);
          } else {
            xScale.domain([d0 - factor, d1 - factor]);
            return xScale.domain()[0] > (d0 - shift);
          }
        };
      }

      function _add_point(p) {
        if (points.length === 0) { return; }
        markedPoint = false;
        var index = points.length,
            lengthX = index * sample,
            point = { x: lengthX, y: p },
            newx, newy;
        points.push(point);
      }

      function add_point(p) {
        if (points.length === 0) { return; }
        _add_point(p);
        updateOrRescale();
      }

      function add_canvas_point(p) {
        if (points.length === 0) { return; }
        markedPoint = false;
        var index = points.length,
            lengthX = index * sample,
            previousX = lengthX - sample,
            point = { x: lengthX, y: p },
            oldx = xScale.call(self, previousX, previousX),
            oldy = yScale.call(self, points[index-1].y, index-1),
            newx, newy;

        points.push(point);
        newx = xScale.call(self, lengthX, lengthX);
        newy = yScale.call(self, p, lengthX);
        gctx.beginPath();
        gctx.moveTo(oldx, oldy);
        gctx.lineTo(newx, newy);
        gctx.stroke();
      }

      function add_points(pnts) {
        for (var i = 0; i < pointArray.length; i++) {
          points = pointArray[i];
          _add_point(pnts[i]);
        }
        updateOrRescale();
      }


      function add_canvas_points(pnts) {
        for (var i = 0; i < pointArray.length; i++) {
          points = pointArray[i];
          setStrokeColor(i);
          add_canvas_point(pnts[i]);
        }
      }

      function setStrokeColor(i, afterSamplePoint) {
        var opacity = afterSamplePoint ? 0.4 : 1.0;
        switch(i) {
          case 0:
            gctx.strokeStyle = "rgba(160,00,0," + opacity + ")";
            break;
          case 1:
            gctx.strokeStyle = "rgba(44,160,0," + opacity + ")";
            break;
          case 2:
            gctx.strokeStyle = "rgba(44,0,160," + opacity + ")";
            break;
        }
      }

      function setFillColor(i, afterSamplePoint) {
        var opacity = afterSamplePoint ? 0.4 : 1.0;
        switch(i) {
          case 0:
            gctx.fillStyle = "rgba(160,00,0," + opacity + ")";
            break;
          case 1:
            gctx.fillStyle = "rgba(44,160,0," + opacity + ")";
            break;
          case 2:
            gctx.fillStyle = "rgba(44,0,160," + opacity + ")";
            break;
        }
      }

      function new_data(d) {
        var i;
        pointArray = [];
        if (Object.prototype.toString.call(d) === "[object Array]") {
          for (i = 0; i < d.length; i++) {
            points = indexedData(d[i], 0, sample);
            pointArray.push(points);
          }
        } else {
          points = indexedData(options.dataset, 0, sample);
          pointArray = [points];
        }
        updateOrRescale();
      }

      function change_xaxis(xmax) {
        x = d3.scale[options.xscale]()
            .domain([0, xmax])
            .range([0, size.width]);
        graph.xmax = xmax;
        x_tics_scale = d3.scale[options.xscale]()
            .domain([graph.xmin*graph.sample, graph.xmax*graph.sample])
            .range([0, size.width]);
        update();
        redraw();
      }

      function change_yaxis(ymax) {
        y = d3.scale[options.yscale]()
            .domain([ymax, 0])
            .range([0, size.height]);
        graph.ymax = ymax;
        update();
        redraw();
      }

      function clear_canvas() {
        gcanvas.width = gcanvas.width;
        gctx.fillStyle = "rgba(0,255,0, 0.05)";
        gctx.fillRect(0, 0, gcanvas.width, gcanvas.height);
        gctx.strokeStyle = "rgba(255,65,0, 1.0)";
      }

      function show_canvas() {
        vis.select("path.line").remove();
        gcanvas.style.zIndex = 100;
      }

      function hide_canvas() {
        gcanvas.style.zIndex = -100;
        update();
      }

      // update real-time canvas line graph
      function update_canvas(currentSample) {
        var i, index, py, samplePoint, pointStop,
            yOrigin = yScale(0.00001),
            lines = options.lines,
            bars = options.bars,
            twopi = 2 * Math.PI,
            pointsLength = pointArray[0].length,
            numberOfLines = pointArray.length,
            xAxisStart = Math.round(xScale.domain()[0]/sample),
            xAxisEnd = Math.round(xScale.domain()[1]/sample),
            start = Math.max(0, xAxisStart);


        if (typeof currentSample === 'undefined') {
          samplePoint = pointsLength;
        } else {
          if (currentSample === pointsLength-1) {
            samplePoint = pointsLength-1;
          } else {
            samplePoint = currentSample;
          }
        }
        clear_canvas();
        gctx.fillRect(0, 0, gcanvas.width, gcanvas.height);
        if (points.length === 0 || xAxisStart >= points.length) { return; }
        if (lines) {
          for (i = 0; i < numberOfLines; i++) {
            points = pointArray[i];
            lengthX = start * sample;
            px = xScale(lengthX);
            py = yScale(points[start].y);
            setStrokeColor(i);
            gctx.beginPath();
            gctx.moveTo(px, py);
            pointStop = samplePoint - 1;
            for (index=start+1; index < pointStop; index++) {
              lengthX = index * sample;
              px = xScale(lengthX);
              py = yScale(points[index].y);
              gctx.lineTo(px, py);
            }
            gctx.stroke();
            pointStop = points.length-1;
            if (index < pointStop) {
              setStrokeColor(i, true);
              for (;index < pointStop; index++) {
                lengthX = index * sample;
                px = xScale(lengthX);
                py = yScale(points[index].y);
                gctx.lineTo(px, py);
              }
              gctx.stroke();
            }
          }
        } else if (bars) {
          for (i = 0; i < numberOfLines; i++) {
            points = pointArray[i];
            setStrokeColor(i);
            pointStop = samplePoint - 1;
            for (index=start; index < pointStop; index++) {
              lengthX = index * sample;
              px = xScale(lengthX);
              py = yScale(points[index].y);
              if (py === 0) {
                continue;
              }
              gctx.beginPath();
              gctx.moveTo(px, yOrigin);
              gctx.lineTo(px, py);
              gctx.stroke();
            }
            pointStop = points.length-1;
            if (index < pointStop) {
              setStrokeColor(i, true);
              for (;index < pointStop; index++) {
                lengthX = index * sample;
                px = xScale(lengthX);
                py = yScale(points[index].y);
                gctx.beginPath();
                gctx.moveTo(px, yOrigin);
                gctx.lineTo(px, py);
                gctx.stroke();
              }
            }
          }
        } else {
          for (i = 0; i < numberOfLines; i++) {
            points = pointArray[i];
            lengthX = 0;
            setFillColor(i);
            setStrokeColor(i, true);
            pointStop = samplePoint - 1;
            for (index=0; index < pointStop; index++) {
              px = xScale(lengthX);
              py = yScale(points[index].y);

              // gctx.beginPath();
              // gctx.moveTo(px, py);
              // gctx.lineTo(px, py);
              // gctx.stroke();

              gctx.arc(px, py, 1, 0, twopi, false);
              gctx.fill();

              lengthX += sample;
            }
            pointStop = points.length-1;
            if (index < pointStop) {
              setFillColor(i, true);
              setStrokeColor(i, true);
              for (;index < pointStop; index++) {
                px = xScale(lengthX);
                py = yScale(points[index].y);

                // gctx.beginPath();
                // gctx.moveTo(px, py);
                // gctx.lineTo(px, py);
                // gctx.stroke();

                gctx.arc(px, py, 1, 0, twopi, false);
                gctx.fill();

                lengthX += sample;
              }
            }
          }
        }
      }

      function initialize_canvas() {
        if (!gcanvas) {
          gcanvas = gcanvas || document.createElement('canvas');
          node.appendChild(gcanvas);
        }
        gcanvas.style.zIndex = -100;
        setupCanvasProperties(gcanvas);
      }

      function resize_canvas() {
        setupCanvasProperties(gcanvas);
        update_canvas();
      }

      function setupCanvasProperties(canvas) {
        cplot.rect = plot.node();
        cplot.width = cplot.rect.width['baseVal'].value;
        cplot.height = cplot.rect.height['baseVal'].value;
        cplot.left = cplot.rect.getCTM().e;
        cplot.top = cplot.rect.getCTM().f;
        canvas.style.position = 'absolute';
        canvas.width = cplot.width;
        canvas.height = cplot.height;
        canvas.style.width = cplot.width  + 'px';
        canvas.style.height = cplot.height  + 'px';
        canvas.offsetLeft = cplot.left;
        canvas.offsetTop = cplot.top;
        canvas.style.left = cplot.left + 'px';
        canvas.style.top = cplot.top + 'px';
        canvas.style.border = 'solid 1px red';
        canvas.style.pointerEvents = "none";
        canvas.className += "canvas-overlay";
        gctx = gcanvas.getContext( '2d' );
        gctx.globalCompositeOperation = "source-over";
        gctx.lineWidth = 1;
        gctx.fillStyle = "rgba(0,255,0, 0.05)";
        gctx.fillRect(0, 0, canvas.width, gcanvas.height);
        gctx.strokeStyle = "rgba(255,65,0, 1.0)";
        gcanvas.style.border = 'solid 1px red';
      }

      // make these private variables and functions available
      graph.node = node;
      graph.scale = scale;
      graph.update = update;
      graph.updateOrRescale = updateOrRescale;
      graph.redraw = redraw;
      graph.initialize = initialize;
      graph.notify = notify;

      graph.number_of_points = number_of_points;
      graph.new_data = new_data;
      graph.add_point = add_point;
      graph.add_points = add_points;
      graph.add_canvas_point = add_canvas_point;
      graph.add_canvas_points = add_canvas_points;
      graph.initialize_canvas = initialize_canvas;
      graph.show_canvas = show_canvas;
      graph.hide_canvas = hide_canvas;
      graph.clear_canvas = clear_canvas;
      graph.update_canvas = update_canvas;
      graph.showMarker = showMarker;

      graph.change_xaxis = change_xaxis;
      graph.change_yaxis = change_yaxis;
    }

    graph.add_data = function(newdata) {
      if (!arguments.length) return points;
      var domain = xScale.domain(),
          xextent = domain[1] - domain[0],
          shift = xextent * 0.8,
          ds,
          i;
      if (newdata instanceof Array && newdata.length > 0) {
        if (newdata[0] instanceof Array) {
          for(i = 0; i < newdata.length; i++) {
            points.push(newdata[i]);
          }
        } else {
          if (newdata.length === 2) {
            points.push(newdata);
          } else {
            throw new Error("invalid argument to graph.add_data() " + newdata + " length should === 2.");
          }
        }
      }
      updateOrRescale();
      return graph;
    };

    graph.getXDomain = function () {
      return xScale.domain();
    };

    graph.getYDomain = function () {
      return yScale.domain();
    };

    graph.reset = function(idOrElement, options, message) {
      if (arguments.length) {
        graph.initialize(idOrElement, options, message);
      } else {
        graph.initialize();
      }
      graph();
      return graph;
    };

    graph.resize = function(w, h) {
      graph.scale(w, h);
      graph.initialize();
      graph();
      return graph;
    };

    if (node) { graph(); }

    return graph;
  };
});

/*global define $ model*/
/*jslint boss: true eqnull: true*/

define('common/controllers/graph-controller',['require','grapher/core/real-time-graph','common/controllers/interactive-metadata','common/validator'],function (require) {
  var RealTimeGraph = require('grapher/core/real-time-graph'),
      metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator'),

      // Note: We always explicitly copy properties from component spec to grapher options hash,
      // in order to avoid tighly coupling an externally-exposed API (the component spec) to an
      // internal implementation detail (the grapher options format).
      grapherOptionForComponentSpecProperty = {
        title: 'title',
        xlabel: 'xlabel',
        xmin: 'xmin',
        xmax: 'xmax',
        ylabel: 'ylabel',
        ymin: 'ymin',
        ymax: 'ymax'
      };

  return function graphController(component) {
    var // HTML element containing view
        $container,
        grapher,
        controller,
        properties,
        data = [];

    /**
      Returns the time interval that elapses between succeessive data points, in picoseconds. (The
      current implementation of the grapher requires this knowledge.)
    */
    function getSamplePeriod() {
      return model.get('viewRefreshInterval') * model.get('timeStep') / 1000;
    }

    /**
      Returns an array containing the current value of each model property specified in
      component.properties.
    */
    function getDataPoint() {
      var ret = [], i, len;

      for (i = 0, len = properties.length; i < len; i++) {
        ret.push(model.get(properties[i]));
      }
      return ret;
    }

    /**
      Return an options hash for use by the grapher.
    */
    function getOptions() {
      var cProp,
          gOption,
          options = {
            sample: getSamplePeriod()
          };

      // update grapher options from component spec & defaults
      for (cProp in grapherOptionForComponentSpecProperty) {
        if (grapherOptionForComponentSpecProperty.hasOwnProperty(cProp)) {
          gOption = grapherOptionForComponentSpecProperty[cProp];
          options[gOption] = component[cProp];
        }
      }
      return options;
    }

    /**
      Resets the cached data array to a single, initial data point, and pushes that data into graph.
    */
    function resetData() {
      var dataPoint = getDataPoint(),
          i;

      for (i = 0; i < dataPoint.length; i++) {
        data[i] = [dataPoint[i]];
      }
      grapher.new_data(data);
    }

    /**
      Appends the current data point (as returned by getDataPoint()) to the graph and to the cached
      data array
    */
    function appendDataPoint() {
      var dataPoint = getDataPoint(),
          i;

      for (i = 0; i < dataPoint.length; i++) {
        data[i].push(dataPoint[i]);
      }
      // The grapher considers each individual (property, time) pair to be a "point", and therefore
      // considers the set of properties at any 1 time (what we consider a "point") to be "points".
      grapher.add_points(dataPoint);
    }

    /**
      Removes all data from the graph that correspond to steps following the current step pointer.
      This is used when a change is made that invalidates the future data.
    */
    function removeDataAfterStepPointer() {
      var i;

      for (i = 0; i < properties.length; i++) {
        // Account for initial data, which corresponds to stepCounter == 0
        data[i].length = model.stepCounter() + 1;
      }
      grapher.new_data(data);
    }

    /**
      Causes the graph to move the "current" pointer to the current model step. This desaturates
      the graph region corresponding to times after the current point.
    */
    function redrawCurrentStepPointer() {
      grapher.updateOrRescale(model.stepCounter());
      grapher.showMarker(model.stepCounter());
    }

    /**
      Ask the grapher to reset itself, without adding new data.
    */
    function resetGrapher() {
      grapher.reset('#' + component.id, getOptions());
    }


    function registerModelListeners() {
      // Namespace listeners to '.graphController' so we can eventually remove them all at once
      model.on('tick.graphController', appendDataPoint);
      model.on('stepBack.graphController', redrawCurrentStepPointer);
      model.on('stepForward.graphController', redrawCurrentStepPointer);
      model.on('seek.graphController', redrawCurrentStepPointer);
      model.on('reset.graphController', function() {
        resetGrapher();
        resetData();
      });
      model.on('play.pressureGraph', function() {
        if (grapher.number_of_points() && model.stepCounter() < grapher.number_of_points()) {
          removeDataAfterStepPointer();
        }
        grapher.show_canvas();
      });
      model.on('invalidation.graphController', removeDataAfterStepPointer);

      // As an imperfect hack (really the grapher should allow us to pass the correct x-axis value)
      // we reset the graph if a model property change changes the time interval between ticks
      model.addPropertiesListener(['viewRefreshInterval', 'timeStep'], function() {
        resetGrapher();
        resetData();
      });
    }

    //
    // Initialization.
    //
    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.graph, component);
    // The list of properties we are being asked to graph.
    properties = component.properties.slice();
    $container = $('<div>').attr('id', component.id).addClass('properties-graph');
    // Apply custom width and height settings.
    $container.css({
      width: component.width,
      height: component.height
    });

    return controller = {

      /**
        Called by the interactives controller when the model finishes loading.
      */
      modelLoadedCallback: function() {
        if (grapher) {
          resetGrapher();
        } else {
          grapher = new RealTimeGraph($container[0], getOptions());
        }
        resetData();
        registerModelListeners();
      },

      /**
        Returns the grapher object itself.
      */
      getView: function() {
        return grapher;
      },

      /**
        Returns a jQuery selection containing the div which contains the graph.
      */
      getViewContainer: function() {
        return $container;
      },

      resize: function () {
        // For now only "fit to parent" behavior is supported.
        if (grapher) {
          grapher.resize();
        }
      },

      /**
        Returns serialized component definition.
      */
      serialize: function () {
        // The only thing which needs to be updated is scaling of axes.
        // Note however that the serialized definition should always have
        // 'xmin' set to initial value, as after deserialization we assume
        // that there is no previous data and simulations should start from the beginning.
        var result = $.extend(true, {}, component),
            // Get current domains settings, e.g. after dragging performed by the user.
            // TODO: this should be reflected somehow in the grapher model,
            // not grabbed directly from the view as now. Waiting for refactoring.
            xDomain = grapher.getXDomain(),
            yDomain = grapher.getYDomain(),
            startX  = component.xmin;

        result.ymin = yDomain[0];
        result.ymax = yDomain[1];
        // Shift graph back to the original origin, but keep scale of the X axis.
        // This is not very clear, but follows the rule of least surprise for the user.
        result.xmin = startX;
        result.xmax = startX + xDomain[1] - xDomain[0];

        return result;
      }
    };
  };

});

/*jshint eqnull: true */
/*global define */

define('import-export/dg-exporter',['require','common/console'],function(require) {

  var console = require('common/console');

  return {
    gameName: 'Next Gen MW',
    parentCollectionName: 'Summary of Run',
    childCollectionName: 'Time Series of Run',

    perRunColumnLabelCount: 0,
    perRunColumnLabelPositions: {},

    mockDGController: {
      doCommand: function(obj) {
        console.log("action: ", obj.action);
        console.log("args: ", obj.args);
        return { caseID: 0 };
      }
    },

    isDgGameControllerDefined: function() {
      return !!(window.parent && window.parent.DG && window.parent.DG.currGameController);
    },

    // Synonym...
    isExportAvailable: function() {
      return this.isDgGameControllerDefined();
    },

    getDGGameController: function() {
      if (!this.isDgGameControllerDefined()) {
        return this.mockDGController;
      }
      return window.parent.DG.currGameController;
    },

    doCommand: function(name, args) {
      var controller = this.getDGGameController();

      return controller.doCommand({
        action: name,
        args: args
      });
    },


    /**
      Exports the summary data about a run and timeseries data from the run to DataGames as 2
      linked tables.

      perRunLabels: list of column labels for the "left" table which contains a summary of the run
        (this can contain parameters that define the run, as well as )

      perRunData: list containing 1 row of data to be added to the left table

      timeSeriesLabels: list of column labels for the "right" table which contains a set of time
        points that will be linked to the single row which is added to the "left", run-summary table

      timeSeriesData: a list of lists, each of which contains 1 row of data to be added to the
        right table.

      This method automatically adds, as the first column of the run-summary table, a column
      labeled "Number of Time Points", which contains the number of time points in the timeseries
      that is associated with the run.

      Note: Call this method once per run, or row of data to be added to the left table.
      This method "does the right thing" if per-run column labels are added, removed, and/or
      reordered between calls to the method. However, currently, it does not handle the removal
      of time series labels (except from the end of the list) and it does not handle reordering of
      time series labels.
    */
    exportData: function(perRunLabels, perRunData, timeSeriesLabels, timeSeriesData) {
      var label,
          value,
          position,
          perRunColumnLabels = [],
          perRunColumnValues = [],
          timeSeriesColumnLabels = [],
          parentCase,
          parentCollectionValues,
          i;

      // Extract metadata in the forms needed for export, ie values need to be an array of values,
      // labels need to be an array of {name: label} objects.
      // Furthermore note that during a DG session, the value for a given label needs to be in the
      // same position in the array every time the DG collection is 'created' (or reopened as the
      // case may be.)

      for (i = 0; i < perRunData.length; i++) {
        label = perRunLabels[i];
        value = perRunData[i];

        if ( this.perRunColumnLabelPositions[label] == null ) {
          this.perRunColumnLabelPositions[label] = this.perRunColumnLabelCount++;
        }
        position = this.perRunColumnLabelPositions[label];

        perRunColumnLabels[position] = { name: label };
        perRunColumnValues[position] = value;
      }

      // Extract list of data column labels into form needed for export (needs to be an array of
      // name: label objects)
      for (i = 0; i < timeSeriesLabels.length; i++) {
        timeSeriesColumnLabels.push({ name: timeSeriesLabels[i] });
      }

      // Export.

      // Step 1. Tell DG we're a "game".
      this.doCommand('initGame', {
        name: this.gameName
      });

      // Step 2. Create a parent table. Each row will have the value of each of the perRunData,
      // plus the number of time series points that are being exported for combination of
      // parameter values.
      // (It seems to be ok to call this multiple times with the same collection name, e.g., for
      // multiple exports during a single DG session.)
      this.doCommand('createCollection', {
        name: this.parentCollectionName,
        attrs: [{name: 'Number of Time Points'}].concat(perRunColumnLabels),
        childAttrName: 'contents'
      });

      // Step 3. Create a table to be the child of the parent table; each row of the child
      // has a single time series reading (time, property1, property2...)
      // (Again, it seems to be ok to call this for the same table multiple times per DG session)
      this.doCommand('createCollection', {
        name: this.childCollectionName,
        attrs: timeSeriesColumnLabels
      });

      // Step 4. Open a row in the parent table. This will contain the individual time series
      // readings as children.
      parentCollectionValues = [timeSeriesData.length].concat(perRunColumnValues);
      parentCase = this.doCommand('openCase', {
        collection: this.parentCollectionName,
        values: parentCollectionValues
      });

      // Step 5. Create rows in the child table for each data point. Using 'createCases' we can
      // do this inline, so we don't need to call openCase, closeCase for each row.
      this.doCommand('createCases', {
        collection: this.childCollectionName,
        values: timeSeriesData,
        parent: parentCase.caseID,
        log: false
      });

      // Step 6. Close the case.
      this.doCommand('closeCase', {
        collection: this.parentCollectionName,
        values: parentCollectionValues,
        caseID: parentCase.caseID
      });
    },

    /**
      Call this to cause DataGames to open the 'case table" containing the all the data exported by
      exportData() so far.
    */
    openTable: function() {
      this.doCommand('createComponent', {
        type: 'DG.TableView',
        log: false
      });
    }
  };
});

/*global define model*/
/*jslint boss: true*/

define('common/controllers/export-controller',['require','import-export/dg-exporter'],function (require) {

  var dgExporter = require('import-export/dg-exporter');

  var ExportController = function exportController(spec) {
    var perRun  = (spec.perRun || []).slice(),
        perTick = ['timeInPs'].concat(spec.perTick.slice()),
        perTickValues,
        controller;

    function getDataPoint() {
      var ret = [], i, len;

      for (i = 0, len = perTick.length; i < len; i++) {
        ret.push(model.get(perTick[i]));
      }
      return ret;
    }

    function resetData() {
      perTickValues = [getDataPoint()];
    }

    function appendDataPoint() {
      perTickValues.push(getDataPoint());
    }

    function removeDataAfterStepPointer() {
      // Account for initial data, which corresponds to stepCounter == 0
      perTickValues.length = model.stepCounter() + 1;
    }

    function registerModelListeners() {
      // Namespace listeners to '.exportController' so we can eventually remove them all at once
      model.on('tick.exportController', appendDataPoint);
      model.on('reset.exportController', resetData);
      model.on('play.exportController', removeDataAfterStepPointer);
      model.on('invalidation.exportController', removeDataAfterStepPointer);
    }

    function getLabelForProperty(property) {
      var desc = model.getPropertyDescription(property),
          ret = "";

      if (desc.label && desc.label.length > 0) {
        ret += desc.label;
      } else {
        ret += property;
      }

      if (desc.units && desc.units.length > 0) {
        ret += " (";
        ret += desc.units;
        ret += ")";
      }
      return ret;
    }

    return controller = {

      modelLoadedCallback: function() {
        // Show time in picoseconds by default b/c ps are the time unit used by the standard graph.
        model.defineOutput('timeInPs', {
          label: "Time",
          units: "ps"
        }, function() {
          return model.get('time')/1000;
        });

        // put per-run parameters before per-run outputs
        function is(type) {
          return function(p) { return model.getPropertyType(p) === type; };
        }
        perRun = perRun.filter(is('parameter')).concat(perRun.filter(is('output')));

        resetData();
        registerModelListeners();
      },

      exportData: function() {
        var perRunPropertyLabels = [],
            perRunPropertyValues = [],
            perTickLabels = [],
            i;

        for (i = 0; i < perRun.length; i++) {
          perRunPropertyLabels[i] = getLabelForProperty(perRun[i]);
          perRunPropertyValues[i] = model.get(perRun[i]);
        }

        for (i = 0; i < perTick.length; i++) {
          perTickLabels[i] = getLabelForProperty(perTick[i]);
        }

        dgExporter.exportData(perRunPropertyLabels, perRunPropertyValues, perTickLabels, perTickValues);
        dgExporter.openTable();
      }
    };
  };

  // "Class method" (want to be able to call this before instantiating)
  // Do we have a sink
  ExportController.isExportAvailable = function() {
    return dgExporter.isExportAvailable();
  };

  return ExportController;
});
/*global d3 $ define model alert */

define('common/controllers/scripting-api',['require'],function (require) {

  //
  // Define the scripting API used by 'action' scripts on interactive elements.
  //
  // The properties of the object below will be exposed to the interactive's
  // 'action' scripts as if they were local vars. All other names (including
  // all globals, but exluding Javascript builtins) will be unavailable in the
  // script context; and scripts are run in strict mode so they don't
  // accidentally expose or read globals.
  //
  return function ScriptingAPI (interactivesController, modelScriptingAPI) {

    var scriptingAPI = (function() {

      function isInteger(n) {
        // Exploits the facts that (1) NaN !== NaN, and (2) parseInt(Infinity, 10) is NaN
        return typeof n === "number" && (parseFloat(n) === parseInt(n, 10));
      }

      function isArray(obj) {
        return typeof obj === 'object' && obj.slice === Array.prototype.slice;
      }

      /** return an integer randomly chosen from the set of integers 0..n-1 */
      function randomInteger(n) {
        return Math.floor(Math.random() * n);
      }

      function swapElementsOfArray(array, i, j) {
        var tmp = array[i];
        array[i] = array[j];
        array[j] = tmp;
      }

      /** Return an array of n randomly chosen members of the set of integers 0..N-1 */
      function choose(n, N) {
        var values = [],
            i;

        for (i = 0; i < N; i++) { values[i] = i; }

        for (i = 0; i < n; i++) {
          swapElementsOfArray(values, i, i + randomInteger(N-i));
        }
        values.length = n;

        return values;
      }

      return {

        isInteger: isInteger,
        isArray: isArray,
        randomInteger: randomInteger,
        swapElementsOfArray: swapElementsOfArray,
        choose: choose,

        deg2rad: Math.PI/180,
        rad2deg: 180/Math.PI,

        format: d3.format,

        get: function get() {
          return model.get.apply(model, arguments);
        },

        set: function set() {
          return model.set.apply(model, arguments);
        },

        loadModel: function loadModel(modelId, cb) {
          model.stop();

          interactivesController.loadModel(modelId);

          if (typeof cb === 'function') {
            interactivesController.pushOnLoadScript(cb);
          }
        },

        /**
          Observe property `propertyName` on the model, and perform `action` when it changes.
          Pass property value to action.
        */
        onPropertyChange: function onPropertyChange(propertyName, action) {
          model.addPropertiesListener([propertyName], function() {
            action( model.get(propertyName) );
          });
        },

        start: function start() {
          model.start();
        },

        stop: function stop() {
          model.stop();
        },

        reset: function reset() {
          model.stop();
          interactivesController.modelController.reload();
        },

        tick: function tick() {
          model.tick();
        },


        getTime: function getTime() {
          return model.get('time');
        },

        repaint: function repaint() {
          interactivesController.getModelController().repaint();
        },

        exportData: function exportData() {
          var dgExport = interactivesController.getDGExportController();
          if (!dgExport)
            throw new Error("No exports have been specified.");
          dgExport.exportData();
        },

        Math: Math,

        // prevent us from overwriting window.undefined
        undefined: undefined,

        // rudimentary debugging functionality
        alert: alert,

        console: window.console !== null ? window.console : {
          log: function() {},
          error: function() {},
          warn: function() {},
          dir: function() {}
        }
      };

    }());

    var controller = {
      /**
        Freeze Scripting API
        Make the scripting API immutable once defined
      */
      freeze: function () {
        Object.freeze(scriptingAPI);
      },

      /**
        Extend Scripting API
      */
      extend: function (ModelScriptingAPI) {
        jQuery.extend(scriptingAPI, new ModelScriptingAPI(scriptingAPI));
      },

      /**
        Allow console users to try script actions
      */
      exposeScriptingAPI: function () {
        window.script = $.extend({}, scriptingAPI);
        window.script.run = function(source, args) {
          var prop,
              argNames = [],
              argVals = [];

          for (prop in args) {
            if (args.hasOwnProperty(prop)) {
              argNames.push(prop);
              argVals.push(args[prop]);
            }
          }
          return controller.makeFunctionInScriptContext.apply(null, argNames.concat(source)).apply(null, argVals);
        };
      },

      /**
        Given a script string, return a function that executes that script in a
        context containing *only* the bindings to names we supply.

        This isn't intended for XSS protection (in particular it relies on strict
        mode.) Rather, it's so script authors don't get too clever and start relying
        on accidentally exposed functionality, before we've made decisions about
        what scripting API and semantics we want to support.
      */
      makeFunctionInScriptContext: function () {

            // This object is the outer context in which the script is executed. Every time the script
            // is executed, it contains the value 'undefined' for all the currently defined globals.
            // This prevents at least inadvertent reliance by the script on unintentinally exposed
            // globals.

        var shadowedGlobals = {},

            // First n-1 arguments to this function are the names of the arguments to the script.
            argumentsToScript = Array.prototype.slice.call(arguments, 0, arguments.length - 1),

            // Last argument is the function body of the script, as a string or array of strings.
            scriptSource = arguments[arguments.length - 1],

            scriptFunctionMakerSource,
            scriptFunctionMaker,
            scriptFunction;

        if (typeof scriptSource !== 'string') scriptSource = scriptSource.join('      \n');

        // Make shadowedGlobals contain keys for all globals (properties of 'window')
        // Also make set and get of any such property throw a ReferenceError exactly like
        // reading or writing an undeclared variable in strict mode.
        function setShadowedGlobals() {
          var keys = Object.getOwnPropertyNames(window),
              key,
              i,
              len,
              err;

          for (i = 0, len = keys.length; i < len; i++) {
            key = keys[i];
            if (!shadowedGlobals.hasOwnProperty(key)) {
              err = (function(key) {
                return function() { throw new ReferenceError(key + " is not defined"); };
              }(key));

              Object.defineProperty(shadowedGlobals, key, {
                set: err,
                get: err
              });
            }
          }
        }

        scriptFunctionMakerSource =
          "with (shadowedGlobals) {\n" +
          "  with (scriptingAPI) {\n" +
          "    return function(" + argumentsToScript.join(',') +  ") {\n" +
          "      'use " + "strict';\n" +
          "      " + scriptSource + "\n" +
          "    };\n" +
          "  }\n" +
          "}";

        try {
          scriptFunctionMaker = new Function('shadowedGlobals', 'scriptingAPI', 'scriptSource', scriptFunctionMakerSource);
          scriptFunction = scriptFunctionMaker(shadowedGlobals, scriptingAPI, scriptSource);
        } catch (e) {
          alert("Error compiling script: \"" + e.toString() + "\"\nScript:\n\n" + scriptSource);
          return function() {
            throw new Error("Cannot run a script that could not be compiled");
          };
        }

        // This function runs the script with all globals shadowed:
        return function() {
          setShadowedGlobals();
          try {
            // invoke the script, passing only enough arguments for the whitelisted names
            return scriptFunction.apply(null, Array.prototype.slice.call(arguments));
          } catch (e) {
            alert("Error running script: \"" + e.toString() + "\"\nScript:\n\n" + scriptSource);
          }
        };
      }
    };
    return controller;
  };
});

/*global define $ */

define('common/controllers/button-controller',['common/controllers/interactive-metadata','common/validator'],function () {

  var metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  return function ButtonController(component, scriptingAPI) {
    var $button,
        controller;

    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.button, component);

    $button = $('<button>').attr('id', component.id).html(component.text);
    $button.addClass("component");

    $button.click(scriptingAPI.makeFunctionInScriptContext(component.action));

    // Public API.
    controller = {
      // No modelLoadeCallback is defined. In case of need:
      // modelLoadedCallback: function () {
      //   (...)
      // },

      // Returns view container.
      getViewContainer: function () {
        return $button;
      },

      // Returns serialized component definition.
      serialize: function () {
        // Return the initial component definition.
        // Button doesn't have any state, which can be changed.
        return $.extend(true, {}, component);
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define $ model */

define('common/controllers/checkbox-controller',['common/controllers/interactive-metadata','common/validator'],function () {

  var metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  return function CheckboxController(component, scriptingAPI) {
    var propertyName,
        onClickScript,
        initialValue,
        $checkbox,
        $label,
        $element,
        controller,

        // Updates checkbox using model property. Used in modelLoadedCallback.
        // Make sure that this function is only called when:
        // a) model is loaded,
        // b) checkbox is bound to some property.
        updateCheckbox = function () {
          var value = model.get(propertyName);
          if (value) {
            $checkbox.attr('checked', true);
          } else {
            $checkbox.attr('checked', false);
          }
        };

    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.checkbox, component);
    propertyName  = component.property;
    onClickScript = component.onClick;
    initialValue  = component.initialValue;

    $checkbox = $('<input type="checkbox">').attr('id', component.id);
    $label = $('<label>').append(component.text).append($checkbox);
    $element = $('<div>').append($label);
    // Append class to the most outer container.
    $element.addClass("interactive-checkbox");

    // Process onClick script if it is defined.
    if (onClickScript) {
      // Create a function which assumes we pass it a parameter called 'value'.
      onClickScript = scriptingAPI.makeFunctionInScriptContext('value', onClickScript);
    }

    // Register handler for click event.
    $checkbox.click(function () {
      var value = false,
          propObj;
      // $(this) will contain a reference to the checkbox.
      if ($(this).is(':checked')) {
        value = true;
      }
      // Change property value if checkbox is connected
      // with model's property.
      if (propertyName !== undefined) {
        propObj = {};
        propObj[propertyName] = value;
        model.set(propObj);
      }
      // Finally, if checkbox has onClick script attached,
      // call it in script context with checkbox status passed.
      if (onClickScript !== undefined) {
        onClickScript(value);
      }
    });

    // Public API.
    controller = {
      // This callback should be trigger when model is loaded.
      modelLoadedCallback: function () {
        // Connect checkbox with model's property if its name is defined.
        if (propertyName !== undefined) {
          // Register listener for 'propertyName'.
          model.addPropertiesListener([propertyName], updateCheckbox);
          // Perform initial checkbox setup.
          updateCheckbox();
        }
        else if (initialValue !== undefined) {
          $checkbox.attr('checked', initialValue);
        }
      },

      // Returns view container. Label tag, as it contains checkbox anyway.
      getViewContainer: function () {
        return $element;
      },

      // Returns serialized component definition.
      serialize: function () {
        var result = $.extend(true, {}, component);

        if (propertyName === undefined) {
          // No property binding. Just action script.
          // Update "initialValue" to represent current
          // value of the slider.
          result.initialValue = $checkbox.is(':checked') ? true : false;
        }

        return result;
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define $ model */

define('common/controllers/radio-controller',['common/controllers/interactive-metadata','common/validator'],function () {

  var metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  return function RadioController(component, scriptingAPI, interactivesController) {
    var $div, $option, $span,
        controller,
        options, option, i, len;

    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.radio, component);
    // Validate radio options too.
    options = component.options;
    for (i = 0, len = options.length; i < len; i++) {
      options[i] = validator.validateCompleteness(metadata.radioOption, options[i]);
    }

    $div = $('<div>').attr('id', component.id);
    $div.addClass("component");

    for (i = 0, len = options.length; i < len; i++) {
      option = options[i];
      $option = $('<input>')
        .attr('type', "radio")
        .attr('name', component.id);
      if (option.disabled) {
        $option.attr("disabled", option.disabled);
      }
      if (option.selected) {
        $option.attr("checked", option.selected);
      }
      $span = $('<span class="radio">')
        .append($option)
        .append(option.text);
      $div.append($span)
      if (component.orientation === "vertical") {
        $div.append("<br/>");
      }
      $option.change((function(option, index) {
        return function() {
          var i, len;

          // Update component definition.
          for (i = 0, len = options.length; i < len; i++) {
            delete options[i].selected;
          }
          options[index].selected = true;

          if (option.action){
            scriptingAPI.makeFunctionInScriptContext(option.action)();
          } else if (option.loadModel){
            model.stop();
            interactivesController.loadModel(option.loadModel);
          }
        };
      })(option, i));
    }

    // Public API.
    controller = {
      // No modelLoadeCallback is defined. In case of need:
      // modelLoadedCallback: function () {
      //   (...)
      // },

      // Returns view container.
      getViewContainer: function () {
        return $div;
      },

      // Returns serialized component definition.
      serialize: function () {
        // Return compoment definition. It's always valid,
        // as selected option is updated during 'change' callback.
        return $.extend(true, {}, component);
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define $ model*/

define('common/controllers/slider-controller',['common/controllers/interactive-metadata','common/validator'],function () {

  var metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  return function SliderController(component, scriptingAPI) {
    var min, max, steps, propertyName,
        action, initialValue,
        title, labels, displayValue,
        i, label,
        // View elements.
        $elem,
        $title,
        $label,
        $slider,
        $sliderHandle,
        $container,
        // Public API object.
        controller,

        // Updates slider using model property. Used in modelLoadedCallback.
        // Make sure that this function is only called when:
        // a) model is loaded,
        // b) slider is bound to some property.
        updateSlider = function  () {
          var value = model.get(propertyName);
          $slider.slider('value', value);
          if (displayValue) {
            $sliderHandle.text(displayValue(value));
          }
        };

    //
    // Initialize.
    //
    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.slider, component);
    min = component.min;
    max = component.max;
    steps = component.steps;
    action = component.action;
    propertyName = component.property;
    initialValue = component.initialValue;
    title = component.title;
    labels = component.labels;
    displayValue = component.displayValue;

    // Setup view.
    if (min === undefined) min = 0;
    if (max === undefined) max = 10;
    if (steps === undefined) steps = 10;

    $title = $('<p class="title">' + title + '</p>');
    // we pick up the SVG slider component CSS if we use the generic class name 'slider'
    $container = $('<div class="container">');
    $slider = $('<div class="html-slider">').attr('id', component.id);
    $slider.appendTo($container);

    $slider.slider({
      min: min,
      max: max,
      step: (max - min) / steps
    });

    $sliderHandle = $slider.find(".ui-slider-handle");

    $elem = $('<div class="interactive-slider">')
              .append($title)
              .append($container);

    // Apply custom width and height settings.
    // Styles for jQuery UI components (see SASS files) ensure
    // that it will follow dimensions of its container.
    $elem.css({
      width: component.width,
      height: component.height
    });

    for (i = 0; i < labels.length; i++) {
      label = labels[i];
      $label = $('<p class="label">' + label.label + '</p>');
      $label.css('left', (label.value-min) / (max-min) * 100 + '%');
      $container.append($label);
    }

    // Bind action or/and property, process other options.
    if (action) {
      // The 'action' property is a source of a function which assumes we pass it a parameter
      // called 'value'.
      action = scriptingAPI.makeFunctionInScriptContext('value', action);
      $slider.bind('slide', function(event, ui) {
        action(ui.value);
        if (displayValue) {
          $sliderHandle.text(displayValue(ui.value));
        }
      });
    }

    if (propertyName) {
      $slider.bind('slide', function(event, ui) {
        // Just ignore slide events that occur before the model is loaded.
        var obj = {};
        obj[propertyName] = ui.value;
        if (model) model.set(obj);
        if (displayValue) {
          $sliderHandle.text(displayValue(ui.value));
        }
      });
    }

    if (displayValue) {
      displayValue = scriptingAPI.makeFunctionInScriptContext('value', displayValue);
    }

    // Public API.
    controller = {
      // This callback should be trigger when model is loaded.
      modelLoadedCallback: function () {
        var obj;

        if (propertyName) {
          model.addPropertiesListener([propertyName], updateSlider);
        }

        if (initialValue !== undefined && initialValue !== null) {
          // Make sure to call the action with the startup value of slider. (The script action may
          // manipulate the model, so we have to make sure it runs after the model loads.)
          if (action) {
            $slider.slider('value', initialValue);
            action(initialValue);
            if (displayValue) {
              $sliderHandle.text(displayValue(initialValue));
            }
          }

          if (propertyName) {
            obj = {};
            obj.propertyName = initialValue;
            model.set(obj);
          }
        } else if (propertyName) {
          updateSlider();
        }
      },

      // Returns view container (div).
      getViewContainer: function () {
        return $elem;
      },

      // Returns serialized component definition.
      serialize: function () {
        var result = $.extend(true, {}, component);

        if (propertyName) {
          // Two way binding between slider and model property.
          // Initial value was used to set model property once,
          // we do not need to do this again. Value of the slider
          // will be defined by the model.
          delete result.initialValue;
        }
        else {
          // No property binding. Just action script.
          // Update "initialValue" to represent current
          // value of the slider.
          result.initialValue = $slider.slider('value');
        }

        return result;
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define $ model*/

define('common/controllers/pulldown-controller',['common/controllers/interactive-metadata','common/validator'],function () {

  var metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  return function PulldownController(component, scriptingAPI, interactivesController) {
    var $pulldown, $option,
        options, option,
        controller,
        i, len;

    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.pulldown, component);
    // Validate pulldown options too.
    options = component.options;
    for (i = 0, len = options.length; i < len; i++) {
      options[i] = validator.validateCompleteness(metadata.pulldownOption, options[i]);
    }

    $pulldown = $('<select>').attr('id', component.id);
    $pulldown.addClass("component");

    for (i = 0, len = options.length; i < len; i++) {
      option = options[i];
      $option = $('<option>').html(option.text);
      if (option.disabled) {
        $option.attr("disabled", option.disabled);
      }
      if (option.selected) {
        $option.attr("selected", option.selected);
      }
      $pulldown.append($option);
    }

    $pulldown.change(function() {
      var index = $(this).prop('selectedIndex'),
          action = component.options[index].action,
          i, len;

      // Update component definition.
      for (i = 0, len = options.length; i < len; i++) {
        delete options[i].selected;
      }
      options[index].selected = true;

      if (action){
        scriptingAPI.makeFunctionInScriptContext(action)();
      } else if (component.options[index].loadModel){
        model.stop();
        interactivesController.loadModel(component.options[index].loadModel);
      }
    });

    // Public API.
    controller = {
      // No modelLoadeCallback is defined. In case of need:
      // modelLoadedCallback: function () {
      //   (...)
      // },

      // Returns view container.
      getViewContainer: function () {
        return $pulldown;
      },

      // Returns serialized component definition.
      serialize: function () {
        // Return compoment definition. It's always valid,
        // as selected option is updated during 'change' callback.
        return $.extend(true, {}, component);
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define $ model */

define('common/controllers/numeric-output-controller',['common/controllers/interactive-metadata','common/validator'],function () {

  var metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  return function NumericOutputController(component, scriptingAPI) {
    var propertyName,
        label,
        units,
        displayValue,
        $numericOutput,
        $label,
        $number,
        $units,
        propertyDescription,
        controller,

        renderValue = function () {
          var value = model.get(propertyName);
          if (displayValue) {
            $number.text(displayValue(value));
          } else {
            $number.text(value);
          }
        };

    //
    // Initialization.
    //
    // Validate component definition, use validated copy of the properties.
    component = validator.validateCompleteness(metadata.numericOutput, component);
    propertyName = component.property;
    label = component.label;
    units = component.units;
    displayValue = component.displayValue;

    // Setup view.
    $label  = $('<span class="label"></span>');
    $number = $('<span class="value"></span>');
    $units  = $('<span class="units"></span>');
    if (label) { $label.html(label); }
    if (units) { $units.html(units); }
    $numericOutput = $('<div class="numeric-output">').attr('id', component.id)
        .append($label)
        .append($number)
        .append($units);

    if (displayValue) {
      displayValue = scriptingAPI.makeFunctionInScriptContext('value', displayValue);
    }

    // Public API.
    controller = {
      // This callback should be trigger when model is loaded.
      modelLoadedCallback: function () {
        if (propertyName) {
          propertyDescription = model.getPropertyDescription(propertyName);
          if (propertyDescription) {
            if (!label) { $label.html(propertyDescription.label); }
            if (!units) { $units.html(propertyDescription.units); }
          }
          renderValue();
          model.addPropertiesListener([propertyName], renderValue);
        }
      },

      // Returns view container. Label tag, as it contains checkbox anyway.
      getViewContainer: function () {
        return $numericOutput;
      },

      // Returns serialized component definition.
      serialize: function () {
        // Return the initial component definition.
        // Numeric output component doesn't have any state, which can be changed.
        // It's value is defined by underlying model.
        return $.extend(true, {}, component);
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define: false */
/*jshint boss: true */

define('common/parent-message-controller',[],function() {

  var parentOrigin,
      listeners = {},
      controller;

  function postToTarget(message, target) {
    // See http://dev.opera.com/articles/view/window-postmessage-messagechannel/#crossdoc
    //     https://github.com/Modernizr/Modernizr/issues/388
    //     http://jsfiddle.net/ryanseddon/uZTgD/2/
    if (Lab.structuredClone.supported()) {
      window.parent.postMessage(message, target);
    } else {
      window.parent.postMessage(JSON.stringify(message), target);
    }
  }

  function post(message) {
    postToTarget(message, parentOrigin);
  }

  // Only the initial 'hello' message goes permissively to a '*' target (because due to cross origin
  // restrictions we can't find out our parent's origin until they voluntarily send us a message
  // with it.)
  function postHello(message) {
    postToTarget(message, '*');
  }

  function addListener(type, fn) {
    listeners[type] = fn;
  }

  function removeAllListeners() {
    listeners = {};
  }

  function getListenerNames() {
    return Object.keys(listeners);
  }

  function messageListener(message) {
      // Anyone can send us a message. Only pay attention to messages from parent.
      if (message.source !== window.parent) return;

      var messageData = message.data;

      if (typeof messageData === 'string') messageData = JSON.parse(messageData);

      // We don't know origin property of parent window until it tells us.
      if (!parentOrigin) {
        // This is the return handshake from the embedding window.
        if (messageData.type === 'hello') {
          parentOrigin = messageData.origin;
        }
      }

      // Perhaps-redundantly insist on checking origin as well as source window of message.
      if (message.origin === parentOrigin) {
        if (listeners[messageData.type]) listeners[messageData.type](messageData);
      }
   }

  function initialize() {
    if (window.parent === window) return;

    // We kick off communication with the parent window by sending a "hello" message. Then we wait
    // for a handshake (another "hello" message) from the parent window.
    postHello({
      type: 'hello',
      origin: document.location.href.match(/(.*?\/\/.*?)\//)[1]
    });

    // Make sure that even if initialize() is called many times,
    // only one instance of messageListener will be registered as listener.
    // So, add closure function instead of anonymous function created here.
    window.addEventListener('message', messageListener, false);
  }

  return controller = {
    initialize         : initialize,
    getListenerNames   : getListenerNames,
    addListener        : addListener,
    removeAllListeners : removeAllListeners,
    post               : post
  };

});

/*global define:false*/

define('common/controllers/parent-message-api',['require','common/parent-message-controller'],function(require) {
  var parentMessageController = require('common/parent-message-controller');

  // Defines the default postMessage API used to communicate with parent window (i.e., an embedder)
  return function(model, view, controller) {
    parentMessageController.removeAllListeners();

    function sendPropertyValue(propertyName) {
      parentMessageController.post({
        type: 'propertyValue',
        name:  propertyName,
        value: model.get(propertyName)
      });
    }

    // on message 'setFocus' call view.setFocus
    parentMessageController.addListener('setFocus', function(message) {
      if (view && view.setFocus) {
        view.setFocus();
      }
    });

   // on message 'loadInteractive' call controller.loadInteractive
    parentMessageController.addListener('loadInteractive', function(message) {
      if (controller && controller.loadInteractive) {
        controller.loadInteractive(message.data);
      }
    });

    // on message 'loadModel' call controller.loadModel
    parentMessageController.addListener('loadModel', function(message) {
      if (controller && controller.loadModel) {
        controller.loadModel(message.data.modelId, message.data.modelObject);
      }
    });

    // on message 'getModelState' call and return controller.getModelController().state()
    parentMessageController.addListener('getModelState', function(message) {
      if (controller && controller.getModelController) {
        parentMessageController.post({
          type:  'modelState',
          values: controller.getModelController().state()
        });
      }
    });

    // on message 'getInteractiveState' call and return controller.serialize() result
    parentMessageController.addListener('getInteractiveState', function(message) {
      if (controller && controller.getModelController) {
        parentMessageController.post({
          type:  'interactiveState',
          values: controller.serialize()
        });
      }
    });

     // on message 'loadModel' call controller.loadModel
      parentMessageController.addListener('runBenchmarks', function() {
        var modelController;
        if (controller && controller.getModelController) {
          modelController = controller.getModelController();
          benchmark.bench(modelController.benchmarks, function(results) {
            console.log(results);
            parentMessageController.post({
              'type':   'returnBenchmarks',
              'values': { 'results': results, 'benchmarks': modelController.benchmarks }
            }, function() {}, function() {});
          });
        }
      });

    // Listen for events in the model, and notify using message.post
    // uses D3 disaptch on model to trigger events
    // pass in message.properties ([names]) to also send model properties
    // in values object when triggering in parent Frame
    parentMessageController.addListener('listenForDispatchEvent', function(message) {
      var eventName    = message.eventName,
          properties   = message.properties,
          values       = {},
          i            = 0,
          propertyName = null;

      model.on(eventName, function() {
        if (properties) {
          for (i = 0 ; i < properties.length; i++) {
            propertyName = properties[i];
            values[propertyName] = model.get(propertyName);
          }
        }
        parentMessageController.post({
          'type':   eventName,
          'values': values
        });
      });
    });

    // on message 'get' propertyName: return a 'propertyValue' message
    parentMessageController.addListener('get', function(message) {
      sendPropertyValue(message.propertyName);
    });

    // on message 'observe' propertyName: send 'propertyValue' once, and then every time
    // the property changes.
    parentMessageController.addListener('observe', function(message) {
      model.addPropertiesListener(message.propertyName, function() {
        sendPropertyValue(message.propertyName);
      });
      // Don't forget to send the initial value of the property too:
      sendPropertyValue(message.propertyName);
    });

    // on message 'set' propertyName: set the relevant property
    parentMessageController.addListener('set', function(message) {
      var setter = {};
      setter[message.propertyName] = message.propertyValue;
      model.set(setter);
    });

    parentMessageController.addListener('tick', function(message) {
      model.tick(message.numTimes);
    });

    parentMessageController.addListener('play', function(message) {
      model.resume();
    });

    parentMessageController.initialize();
  };
});

define('cs',{load: function(id){throw new Error("Dynamic load not allowed: " + id);}});
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define('cs!common/components/thermometer',['require'],function(require) {
    var Thermometer;
    return Thermometer = (function() {

      function Thermometer(dom_selector, value, min, max) {
        this.dom_selector = dom_selector != null ? dom_selector : "#thermometer";
        this.value = value;
        this.min = min;
        this.max = max;
        this.resize = __bind(this.resize, this);

        this.dom_element = typeof this.dom_selector === "string" ? $(this.dom_selector) : this.dom_selector;
        this.dom_element.addClass('thermometer');
        this.thermometer_fill = $('<div>').addClass('thermometer_fill');
        this.dom_element.append(this.thermometer_fill);
        this.redraw();
      }

      Thermometer.prototype.add_value = function(value) {
        this.value = value;
        return this.redraw();
      };

      Thermometer.prototype.scaled_value = function() {
        return (this.value - this.min) / (this.max - this.min);
      };

      Thermometer.prototype.resize = function() {
        return this.redraw();
      };

      Thermometer.prototype.redraw = function() {
        return this.thermometer_fill.height("" + (this.scaled_value() * this.dom_element.height()) + "px");
      };

      return Thermometer;

    })();
  });

}).call(this);

/*global define $ model */

define('common/controllers/thermometer-controller',['require','cs!common/components/thermometer','common/controllers/interactive-metadata','common/validator'],function (require) {

  var Thermometer = require('cs!common/components/thermometer'),
      metadata  = require('common/controllers/interactive-metadata'),
      validator = require('common/validator');

  /**
    An 'interactive thermometer' object, that wraps a base Thermometer with a label for use
    in Interactives.

    Properties are:

     modelLoadedCallback:  Standard interactive component callback, called as soon as the model is loaded.
     getViewContainer:     DOM element containing the Thermometer div and the label div.
     getView:              Returns base Thermometer object, with no label.
  */
  return function ThermometerController(component) {
    var reading = component.reading,
        units,
        offset,
        scale,
        digits,

        labelIsReading,
        labelText,

        $thermometer, $label, $elem,

        thermometerComponent,
        controller,

        updateLabel = function (temperature) {
          temperature = scale * temperature + offset;
          $label.text(temperature.toFixed(digits) + " " + units);
        },

        // Updates thermometer using model property. Used in modelLoadedCallback.
        // Make sure that this function is only called when model is loaded.
        updateThermometer = function () {
          var t = model.get('targetTemperature');
          thermometerComponent.add_value(t);
          if (labelIsReading) updateLabel(t);
        };

    //
    // Initialization.
    //
    component = validator.validateCompleteness(metadata.thermometer, component);
    reading = component.reading;
    units = reading.units;
    offset = reading.offset;
    scale  = reading.scale;
    digits = reading.digits;

    labelIsReading = !!component.labelIsReading;
    labelText = labelIsReading ? "" : "Thermometer";

    $thermometer = $('<div>').attr('id', component.id);
    $label = $('<p class="label">').text(labelText);
    $elem = $('<div class="interactive-thermometer">')
      .append($thermometer)
      .append($label);
    $elem.css({
      height: "100%"
    });
    thermometerComponent = new Thermometer($thermometer, null, component.min, component.max);

    // Public API.
    controller = {
      // No modelLoadeCallback is defined. In case of need:
      modelLoadedCallback: function () {
        // TODO: update to observe actual system temperature once output properties are observable
        model.addPropertiesListener('targetTemperature', function() {
          updateThermometer();
        });
        thermometerComponent.resize();
        updateThermometer();
      },

      // Returns view container.
      getViewContainer: function () {
        return $elem;
      },

      getView: function () {
        return thermometerComponent;
      },

      resize: function () {
        $thermometer.height($elem.height() - $label.height());
      },

      // Returns serialized component definition.
      serialize: function () {
        // Return the initial component definition.
        // Displayed value is always defined by the model,
        // so it shouldn't be serialized.
        return component;
      }
    };
    // Return Public API object.
    return controller;
  };
});

/*global define: false, $: false, d3: false */
// ------------------------------------------------------------
//
//   Semantic Layout
//
// ------------------------------------------------------------

define('common/layout/semantic-layout',['require','lab.config','common/alert'],function (require) {

  var labConfig = require('lab.config'),
      alert     = require('common/alert'),

      // Minimum width of the model.
      minModelWidth = 150,

      // Canonical dimensions of the interactive, deciding about font size.
      basicInteractiveWidth = 1000,
      basicInteractiveHeight = 600,

      // Font scaling function.
      fontScale =  d3.scale.linear()
        // Domain: actual interactive size to basic interactive size ratio.
        // Note that 0.4 is "small" size, 0.6 is "medium" size and 1.0 is "large" size.
        .domain([0.4, 0.6, 1.1, 5])
        // Range: font sizes in "em".
        .range([0.6, 0.8, 0.9, 5])
        // Clamp to ensure that font is not smaller than minimum font size
        // (first value in range array above).
        .clamp(true),

      containerColors = [
        "rgba(0,0,255,0.1)", "rgba(255,0,0,0.1)", "rgba(0,255,0,0.1)", "rgba(255,255,0,0.1)",
        "rgba(0,255,255,0.1)", "rgba(255,255,128,0.1)", "rgba(128,255,0,0.1)", "rgba(255,128,0,0.1)"
      ];

  return function SemanticLayout($interactiveContainer, containers, componentLocations, components, modelController) {

    var layout,
        $modelContainer,
        $containers,

        modelWidth = minModelWidth,
        modelTop = 0,
        modelLeft = 0;

    function getDimensionOfContainer($container, dim) {
      var position = $container.position();

      switch (dim) {
        case "top":
          return position.top;
        case "bottom":
          return position.top + $container.outerHeight();
        case "left":
          return position.left;
        case "right":
          return position.left + $container.outerWidth();
        case "height":
          return $container.outerHeight();
        case "width":
          return $container.outerWidth();
      }
    }

    function setFontSize() {
      var xRatio = $interactiveContainer.width() / basicInteractiveWidth,
          yRatio = $interactiveContainer.height() / basicInteractiveHeight,
          ratio = Math.min(xRatio, yRatio);

      // Set font-size of #responsive-content element. So, if application author
      // wants to avoid rescaling of font-size for some elements, they should not
      // be included in #responsive-content DIV.
      // TODO: #responsive-content ID is hardcoded, change it?
      $("#responsive-content").css("font-size", fontScale(ratio) + "em");
    }

    // Calculate width for containers which doesn't explicitly specify its width.
    // In such case, width is determined by the content, no reflow will be allowed.
    function setMinDimensions() {
      var maxMinWidth, $container, i, len;

      function setRowMinWidth() {
        var minWidth = 0;
        // $(this) refers to one row.
        $(this).children().each(function () {
          // $(this) refers to element in row.
          minWidth += $(this).outerWidth(true);
        });
        $(this).css("min-width", Math.ceil(minWidth));
        if (minWidth > maxMinWidth) {
          maxMinWidth = minWidth;
        }
      }

      for (i = 0, len = containers.length; i < len; i++) {
        $container = $containers[containers[i].id];
        if (containers[i].width === undefined) {
          // Set min-width only for containers, which DO NOT specify
          // "width" explicitly in their definitions.
          maxMinWidth = -Infinity;
          $container.children().each(setRowMinWidth);
          $container.css("min-width", maxMinWidth);
        }
        if (containers[i]["min-width"] !== undefined) {
          $container.css("min-width", containers[i]["min-width"]);
        }
      }
    }

    function setupBackground() {
      var id, i, len;

      for (i = 0, len = containers.length; i < len; i++) {
        id = containers[i].id;
        $containers[id].css("background", labConfig.authoring ? containerColors[i % containerColors.length] : "");
      }
    }

    function createContainers() {
      var container, id, prop, i, ii;

      $containers = {};

      $modelContainer = $interactiveContainer.find("#model-container");
      $containers.model = $modelContainer;

      for (i = 0, ii = containers.length; i<ii; i++) {
        container = containers[i];
        id = container.id;
        $containers[id] = $("<div id='"+id+"'>").appendTo($interactiveContainer);
        $containers[id].css("display", "inline-block");
        // add any padding-* properties directly to the container's style
        for (prop in container) {
          if (!container.hasOwnProperty(prop)) continue;
          if (/^padding-/.test(prop)) {
            $containers[id].css(prop, container[prop]);
          }
        }
      }
    }

    function placeComponentsInContainers() {
      var id, container, divContents, items, $row,
          lastContainer, $rows, comps,
          i, ii, j, jj, k, kk;

      comps = $.extend({}, components);

      for (i = 0, ii = containers.length; i<ii; i++) {
        container = containers[i];
        if (componentLocations) {
          divContents = componentLocations[container.id];
        }
        if (!divContents) continue;

        if (Object.prototype.toString.call(divContents[0]) !== "[object Array]") {
          divContents = [divContents];
        }

        for (j = 0, jj = divContents.length; j < jj; j++) {
          items = divContents[j];
          $row = $('<div class="interactive-' + container.id + '-row"/>');
          // Each row should have width 100% of its parent container.
          $row.css("width", "100%");
          // When there is only one row, ensure that it fills whole container.
          if (jj === 1) {
            $row.css("height", "100%");
          }
          $containers[container.id].append($row);
          for (k = 0, kk = items.length; k < kk; k++) {
            id = items[k];
            if (comps[id] !== undefined) {
              $row.append(comps[id].getViewContainer());
              delete comps[id];
            } else {
              alert("Incorrect layout definition. Component with ID '" + id + "'' is not defined.");
            }
          }
        }
      }

      // add any remaining components to "bottom" or last container
      lastContainer = getObject(containers, "bottom") || containers[containers.length-1];
      for (id in comps) {
        if (!comps.hasOwnProperty(id)) continue;
        $rows = $containers[lastContainer.id].children();
        $row = $rows.last();
        if (!$row.length) {
          $row = $('<div class="interactive-' + container.id + '-row"/>');
          $containers[container.id].append($row);
        }
        $row.append(comps[id].getViewContainer());
      }
    }

    function positionContainers() {
      var container, $container,
          left, top, right, bottom, i, ii;

      $modelContainer.css({
        width:  modelWidth,
        height: modelController.getHeightForWidth(modelWidth),
        left:   modelLeft,
        top:    modelTop,
        position: "absolute"
      });

      for (i = 0, ii = containers.length; i<ii; i++) {
        container = containers[i];
        $container = $containers[container.id];

        if (!container.left && !container.right) {
          container.left = "model.left";
        }
        if (!container.top && !container.bottom) {
          container.top = "model.top";
        }

        if (!container.top && !container.bottom) {
          container.top = "model.top";
        }
        if (!container.left && !container.right) {
          container.left = "model.left";
        }
        if (container.left) {
          left = parseDimension(container.left);
          $container.css("left", left);
        }
        if (container.top) {
          top = parseDimension(container.top);
          $container.css("top", top);
        }
        if (container.height) {
          $container.css("height", parseDimension(container.height));
        }
        if (container.width) {
          $container.css("width", parseDimension(container.width));
        }
        if (container.right) {
          right = parseDimension(container.right);
          left = right - $container.outerWidth();
          $container.css("left", left);
        }
        if (container.bottom) {
          bottom = parseDimension(container.bottom);
          top = bottom - $container.outerHeight();
          $container.css("top", top);
        }
        $container.css("position", "absolute");
      }
    }

    // shrinks the model to fit in the interactive, given the sizes
    // of the other containers around it.
    function resizeModelContainer() {
      var speed = 0.3,
          maxX = -Infinity,
          maxY = -Infinity,
          minX = Infinity,
          minY = Infinity,
          id, $container,
          right, bottom, top, left,
          availableWidth, availableHeight, ratio;

      // Calculate boundaries of the interactive.
      for (id in $containers) {
        if (!$containers.hasOwnProperty(id)) continue;
        $container = $containers[id];
        right = getDimensionOfContainer($container, "right");
        if (right > maxX) {
          maxX = right;
        }
        bottom = getDimensionOfContainer($container, "bottom");
        if (bottom > maxY) {
          maxY = bottom;
        }
        left = getDimensionOfContainer($container, "left");
        if (left < minX) {
          minX = left;
        }
        top = getDimensionOfContainer($container, "top");
        if (top < minY) {
          minY = top;
        }
      }

      availableWidth  = $interactiveContainer.width();
      availableHeight = $interactiveContainer.height();

      // TODO: this is quite naive approach.
      // It should be changed to some fitness function defining quality of the layout.
      // Using current algorithm, very often we follow some local minima.
      if ((maxX <= availableWidth && maxY <= availableHeight) &&
          (availableWidth - maxX < 1 || availableHeight - maxY < 1) &&
          (minX < 1 && minY < 1)) {
        // Perfect solution found!
        // (TODO: not so perfect, see above)
        return true;
      }

      if (maxX > availableWidth || maxY > availableHeight) {
        ratio = Math.min(1 - speed * (maxX - availableWidth) / availableWidth, 1 - speed * (maxY - availableHeight) / availableHeight);
      }
      if (maxX < availableWidth && maxY < availableHeight) {
        ratio = Math.min(1 + speed * (availableWidth - maxX) / availableWidth, 1 + speed * (availableHeight - maxY) / availableHeight);
      }
      if (ratio !== undefined) {
        modelWidth = modelWidth * ratio;
      }

      if (modelWidth < minModelWidth) {
        modelWidth = minModelWidth;
      }

      modelLeft -= minX;
      modelTop -= minY;

      return false;
    }

    // parses arithmetic such as "model.height/2"
    function parseDimension(dim) {
      var vars, i, ii, value;

      if (typeof dim === "number" || /^[0-9]+(em)?$/.test(dim)) {
        return dim;
      }

      // find all strings of the form x.y
      vars = dim.match(/[a-zA-Z\-]+\.[a-zA-Z]+/g);

      // replace all x.y's with the actual dimension
      for (i=0, ii=vars.length; i<ii; i++) {
        value = getDimension(vars[i]);
        dim = dim.replace(vars[i], value);
      }
      // eval only if we contain no more alphabetic letters
      if (/^[^a-zA-Z]*$/.test(dim)) {
        return eval(dim);
      } else {
        return 0;
      }
    }

    // parses a container's dimension, such as "model.height"
    function getDimension(dim) {
      var id, $container, attr;

      id = dim.split(".")[0];
      if (id === "interactive") {
        $container = $interactiveContainer;
      } else {
        $container = $containers[id];
      }
      attr = dim.split(".")[1];

      return getDimensionOfContainer($container, attr);
    }

    function getObject(arr, id) {
      for (var i = 0, ii = arr.length; i<ii; i++) {
        if (arr[i].id === id) {
          return arr[i];
        }
      }
    }

    // Public API.
    layout = {
      layoutInteractive: function () {
        var redraws = 0, id;

        // 0. Set font size of the interactive-container based on its size.
        setFontSize();

        // 1. Calculate dimensions of containers which don't specify explicitly define it.
        //    It's necessary to do it each time, as when size of the container is changed,
        //    also size of the components can be changed (e.g. due to new font size).
        setMinDimensions();

        // 2. Calculate optimal layout.
        modelWidth = $interactiveContainer.width();
        positionContainers();
        while (redraws < 35 && !resizeModelContainer()) {
          positionContainers();
          redraws++;
        }

        // 3. Notify components that their containers have new sizes.
        modelController.resize();
        for (id in components) {
          if (components.hasOwnProperty(id) && components[id].resize !== undefined) {
            components[id].resize();
          }
        }

        // 4. Set / remove colors of containers depending on the value of Lab.config.authoring
        setupBackground();
      }
    };

    //
    // Initialize.
    //
    createContainers();
    placeComponentsInContainers();

    return layout;
  };

});
/*global define*/
define('common/layout/templates',[],function () {
  return {
    "simple": [
      {
        "id": "top",
        "bottom": "model.top"
      },
      {
        "id": "right",
        "left": "model.right",
        "height": "model.height",
        "padding-left": "1em"
      },
      {
        "id": "bottom",
        "top": "model.bottom",
        "width": "interactive.width",
        "padding-bottom": "1em"
      }
    ],
    "narrow-right": [
      {
        "id": "top",
        "bottom": "model.top"
      },
      {
        "id": "right",
        "left": "model.right",
        "height": "model.height",
        "padding-left": "1em",
        "width": "model.width / 4",
        "min-width": "6em"
      },
      {
        "id": "bottom",
        "top": "model.bottom",
        "width": "interactive.width",
        "padding-bottom": "1em"
      }
    ],
    "wide-right": [
      {
        "id": "top",
        "bottom": "model.top"
      },
      {
        "id": "right",
        "left": "model.right",
        "height": "model.height",
        "padding-left": "1em",
        "width": "model.width",
        "min-width": "6em"
      },
      {
        "id": "bottom",
        "top": "model.bottom",
        "width": "interactive.width",
        "padding-bottom": "1em"
      }
    ],
    "split-right": [
      {
        "id": "top",
        "bottom": "model.top"
      },
      {
        "id": "right-top",
        "left": "model.right",
        "height": "model.height/2",
        "padding-left": "1em"
      },
      {
        "id": "right-bottom",
        "left": "model.right",
        "top": "model.top + model.height/2",
        "height": "model.height/2",
        "padding-left": "1em"
      },
      {
        "id": "bottom",
        "top": "model.bottom",
        "width": "interactive.width",
        "padding-top": "1em"
      }
    ],
    "big-top": [
      {
        "id": "top",
        "bottom": "model.top",
        "height": "model.height/3",
        "width": "model.width + right.width",
        "padding-bottom": "1em"
      },
      {
        "id": "right",
        "left": "model.right",
        "height": "model.height",
        "padding-left": "1em"
      },
      {
        "id": "bottom",
        "top": "model.bottom",
        "width": "interactive.width",
        "padding-top": "1em"
      }
    ]
  };
});

(function() {

  define('cs!common/components/model_player',['require'],function(require) {
    var ModelPlayer;
    return ModelPlayer = (function() {

      function ModelPlayer(model) {
        this.model = model;
      }

      ModelPlayer.prototype.play = function() {
        return this.model.resume();
      };

      ModelPlayer.prototype.stop = function() {
        return this.model.stop();
      };

      ModelPlayer.prototype.forward = function() {
        this.stop();
        return this.model.stepForward();
      };

      ModelPlayer.prototype.back = function() {
        this.stop();
        return this.model.stepBack();
      };

      ModelPlayer.prototype.seek = function(float_index) {
        this.stop();
        return this.model.seek(float_index);
      };

      ModelPlayer.prototype.reset = function() {
        return this.model.reset();
      };

      ModelPlayer.prototype.isPlaying = function() {
        return !this.model.is_stopped();
      };

      return ModelPlayer;

    })();
  });

}).call(this);

/*global

  define
  DEVELOPMENT
  $
  d3
  alert
  model: true
  model_player: true
*/
/*jslint onevar: true*/
define('common/controllers/model-controller',['require','arrays','cs!common/components/model_player'],function (require) {
  // Dependencies.
  var arrays            = require('arrays'),
      ModelPlayer       = require('cs!common/components/model_player');

  return function modelController(modelViewId, modelUrl, modelConfig, interactiveViewConfig, interactiveModelConfig,
                                  Model, ModelContainer, ScriptingAPI, Benchmarks) {
    var controller = {},

        // event dispatcher
        dispatch = d3.dispatch('modelReset'),

        // Options after processing performed by processOptions().
        modelOptions,
        viewOptions,

        benchmarks,

        modelContainer,

        // We pass this object to the "ModelPlayer" to intercept messages for the model
        // instead of allowing the ModelPlayer to talk to the model directly.
        // This allows us, for example, to reload the model instead of trying to call a 'reset' event
        // on models which don't know how to reset themselves.

        modelProxy = {
          resume: function() {
            model.resume();
          },

          stop: function() {
            model.stop();
          },

          reset: function() {
            model.stop();
            // if the model has a reset function then call it so anything the application
            // sets up outside the interactive itself that is listening for a model.reset
            // event gets notified. Example the Energy Graph Extra Item.
            if (model.reset) {
              model.reset();
            }
            reload(modelUrl, modelConfig);
          },

          is_stopped: function() {
            return model.is_stopped();
          }
        };

      // ------------------------------------------------------------
      //
      // Main callback from model process
      //
      // Pass this function to be called by the model on every model step
      //
      // ------------------------------------------------------------
      function tickHandler() {
        modelContainer.update();
      }


      function processOptions() {
        var meldOptions = function(base, overlay) {
          var p;
          for(p in base) {
            if (overlay[p] === undefined) {
              if (arrays.isArray(base[p])) {
                // Array.
                overlay[p] = $.extend(true, [], base[p]);
              } else if (typeof base[p] === "object") {
                // Object.
                overlay[p] = $.extend(true, {}, base[p]);
              } else {
                // Basic type.
                overlay[p] = base[p];
              }
            } else if (typeof overlay[p] === "object" && !(overlay[p] instanceof Array)) {
              overlay[p] = meldOptions(base[p], overlay[p]);
            }
          }
          return overlay;
        };

        // 1. Process view options.
        // Do not modify initial configuration.
        viewOptions = $.extend(true, {}, interactiveViewConfig);
        // Merge view options defined in interactive (interactiveViewConfig)
        // with view options defined in the basic model description.
        viewOptions = meldOptions(modelConfig.viewOptions || {}, viewOptions);

        // 2. Process model options.
        // Do not modify initial configuration.
        modelOptions = $.extend(true, {}, interactiveModelConfig);
        // Merge model options defined in interactive (interactiveModelConfig)
        // with the basic model description.
        modelOptions = meldOptions(modelConfig || {}, modelOptions);

        // Update view options in the basic model description after merge.
        // Note that many unnecessary options can be passed to Model constructor
        // because of that (e.g. view-only options defined in the interactive).
        // However, all options which are unknown for Model will be discarded
        // during options validation, so this is not a problem
        // (but significantly simplifies configuration).
        modelOptions.viewOptions = viewOptions;
      }

      // ------------------------------------------------------------
      //
      //   Benchmarks Setup
      //

      function setupBenchmarks() {
        benchmarks = new Benchmarks(controller);
      }

      // ------------------------------------------------------------
      //
      //   Model Setup
      //

      function setupModel() {
        processOptions();
        model = new Model(modelOptions);
        model.resetTime();
        model.on('tick', tickHandler);
      }

      // ------------------------------------------------------------
      //
      // Create Model Player
      //
      // ------------------------------------------------------------

      function setupModelPlayer() {

        // ------------------------------------------------------------
        //
        // Create player and container view for model
        //
        // ------------------------------------------------------------

        model_player = new ModelPlayer(modelProxy, false);
        model_player.forward = function() {
          model.stepForward();
          if (!model.isNewStep()) {
            modelContainer.update();
          }
        };
        model_player.back = function() {
          model.stepBack();
          modelContainer.update();
        };

        modelContainer = new ModelContainer(modelViewId, modelUrl, model);
      }

      function resetModelPlayer() {

        // ------------------------------------------------------------
        //
        // reset player and container view for model
        //
        // ------------------------------------------------------------
        modelContainer.reset(modelUrl, model);
      }

      /**
        Note: newModelConfig, newinteractiveViewConfig are optional. Calling this without
        arguments will simply reload the current model.
      */
      function reload(newModelUrl, newModelConfig, newInteractiveViewConfig, newInteractiveModelConfig) {
        modelUrl = newModelUrl || modelUrl;
        modelConfig = newModelConfig || modelConfig;
        interactiveViewConfig = newInteractiveViewConfig || interactiveViewConfig;
        interactiveModelConfig = newInteractiveModelConfig || interactiveModelConfig;
        setupModel();
        resetModelPlayer();
        dispatch.modelReset();
      }

      function repaint() {
        modelContainer.repaint();
      }

      function resize() {
        modelContainer.resize();
      }

      function getHeightForWidth(width) {
        return modelContainer.getHeightForWidth(width);
      }

      function state() {
        return model.serialize();
      }

      // ------------------------------------------------------------
      //
      // Initial setup of this modelController:
      //
      // ------------------------------------------------------------

      if (typeof DEVELOPMENT === 'undefined') {
        try {
          setupModel();
        } catch(e) {
          alert(e);
          throw new Error(e);
        }
      } else {
        setupModel();
      }

      setupBenchmarks();
      setupModelPlayer();
      dispatch.modelReset();

      // ------------------------------------------------------------
      //
      // Public methods
      //
      // ------------------------------------------------------------

      controller.on = function(type, listener) {
        dispatch.on(type, listener);
      };

      controller.reload = reload;
      controller.repaint = repaint;
      controller.resize = resize;
      controller.getHeightForWidth = getHeightForWidth;
      controller.modelContainer = modelContainer;
      controller.state = state;
      controller.benchmarks = benchmarks;
      controller.type = Model.type;
      controller.ScriptingAPI = ScriptingAPI;

      return controller;
  };
});

/*global define: true */

// Tiny module which contains definition of preferred
// array types used across whole Lab project.
// It checks whether typed arrays are available and type of browser
// (as typed arrays are slower in Safari).

define('common/array-types',['require','arrays'],function (require) {
  // Dependencies.
  var arrays = require('arrays'),

      // Check for Safari. Typed arrays are faster almost everywhere ... except Safari.
      notSafari = (function() {
        // Node.js?
        if (typeof navigator === 'undefined')
          return true;
        // Safari?
        var safarimatch  = / AppleWebKit\/([0123456789.+]+) \(KHTML, like Gecko\) Version\/([0123456789.]+) (Safari)\/([0123456789.]+)/,
            match = navigator.userAgent.match(safarimatch);
        return !match || !match[3];
      }()),

      useTyped = arrays.typed && notSafari;

  // Return all available types of arrays.
  // If you need to use new type, declare it here.
  return {
    float:  useTyped ? 'Float32Array' : 'regular',
    int32:  useTyped ? 'Int32Array'   : 'regular',
    int16:  useTyped ? 'Int16Array'   : 'regular',
    int8:   useTyped ? 'Int8Array'    : 'regular',
    uint16: useTyped ? 'Uint16Array'  : 'regular',
    uint8:  useTyped ? 'Uint8Array'   : 'regular'
  };

});

/*global define: true */
/** Provides a few simple helper functions for converting related unit types.

    This sub-module doesn't do unit conversion between compound unit types (e.g., knowing that kg*m/s^2 = N)
    only simple scaling between units measuring the same type of quantity.
*/

// Prefer the "per" formulation to the "in" formulation.
//
// If KILOGRAMS_PER_AMU is 1.660540e-27 we know the math is:
// "1 amu * 1.660540e-27 kg/amu = 1.660540e-27 kg"
// (Whereas the "in" forumulation might be slighty more error prone:
// given 1 amu and 6.022e-26 kg in an amu, how do you get kg again?)

// These you might have to look up...

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/constants/units',['require','exports','module'],function (require, exports, module) {

  var KILOGRAMS_PER_DALTON  = 1.660540e-27,
      COULOMBS_PER_ELEMENTARY_CHARGE = 1.602177e-19,

      // 1 eV = 1 e * 1 V = (COULOMBS_PER_ELEMENTARY_CHARGE) C * 1 J/C
      JOULES_PER_EV = COULOMBS_PER_ELEMENTARY_CHARGE,

      // though these are equally important!
      SECONDS_PER_FEMTOSECOND = 1e-15,
      METERS_PER_NANOMETER    = 1e-9,
      ANGSTROMS_PER_NANOMETER = 10,
      GRAMS_PER_KILOGRAM      = 1000,

      types = {
        TIME: "time",
        LENGTH: "length",
        MASS: "mass",
        ENERGY: "energy",
        ENTROPY: "entropy",
        CHARGE: "charge",
        INVERSE_QUANTITY: "inverse quantity",

        FARADS_PER_METER: "farads per meter",
        METERS_PER_FARAD: "meters per farad",

        FORCE: "force",
        VELOCITY: "velocity",

        // unused as of yet
        AREA: "area",
        PRESSURE: "pressure"
      },

    unit,
    ratio,
    convert;

  /**
    In each of these units, the reference type we actually use has value 1, and conversion
    ratios for the others are listed.
  */
  exports.unit = unit = {

    FEMTOSECOND: { name: "femtosecond", value: 1,                       type: types.TIME },
    SECOND:      { name: "second",      value: SECONDS_PER_FEMTOSECOND, type: types.TIME },

    NANOMETER:   { name: "nanometer", value: 1,                           type: types.LENGTH },
    ANGSTROM:    { name: "Angstrom",  value: 1 * ANGSTROMS_PER_NANOMETER, type: types.LENGTH },
    METER:       { name: "meter",     value: 1 * METERS_PER_NANOMETER,    type: types.LENGTH },

    DALTON:   { name: "Dalton",   value: 1,                                             type: types.MASS },
    GRAM:     { name: "gram",     value: 1 * KILOGRAMS_PER_DALTON * GRAMS_PER_KILOGRAM, type: types.MASS },
    KILOGRAM: { name: "kilogram", value: 1 * KILOGRAMS_PER_DALTON,                      type: types.MASS },

    MW_ENERGY_UNIT: {
      name: "MW Energy Unit (Dalton * nm^2 / fs^2)",
      value: 1,
      type: types.ENERGY
    },

    JOULE: {
      name: "Joule",
      value: KILOGRAMS_PER_DALTON *
             METERS_PER_NANOMETER * METERS_PER_NANOMETER *
             (1/SECONDS_PER_FEMTOSECOND) * (1/SECONDS_PER_FEMTOSECOND),
      type: types.ENERGY
    },

    EV: {
      name: "electron volt",
      value: KILOGRAMS_PER_DALTON *
              METERS_PER_NANOMETER * METERS_PER_NANOMETER *
              (1/SECONDS_PER_FEMTOSECOND) * (1/SECONDS_PER_FEMTOSECOND) *
              (1/JOULES_PER_EV),
      type: types.ENERGY
    },

    EV_PER_KELVIN:     { name: "electron volts per Kelvin", value: 1,                 type: types.ENTROPY },
    JOULES_PER_KELVIN: { name: "Joules per Kelvin",         value: 1 * JOULES_PER_EV, type: types.ENTROPY },

    ELEMENTARY_CHARGE: { name: "elementary charge", value: 1,                             type: types.CHARGE },
    COULOMB:           { name: "Coulomb",           value: COULOMBS_PER_ELEMENTARY_CHARGE, type: types.CHARGE },

    INVERSE_MOLE: { name: "inverse moles", value: 1, type: types.INVERSE_QUANTITY },

    FARADS_PER_METER: { name: "Farads per meter", value: 1, type: types.FARADS_PER_METER },

    METERS_PER_FARAD: { name: "meters per Farad", value: 1, type: types.METERS_PER_FARAD },

    MW_FORCE_UNIT: {
      name: "MW force units (Dalton * nm / fs^2)",
      value: 1,
      type: types.FORCE
    },

    NEWTON: {
      name: "Newton",
      value: 1 * KILOGRAMS_PER_DALTON * METERS_PER_NANOMETER * (1/SECONDS_PER_FEMTOSECOND) * (1/SECONDS_PER_FEMTOSECOND),
      type: types.FORCE
    },

    EV_PER_NM: {
      name: "electron volts per nanometer",
      value: 1 * KILOGRAMS_PER_DALTON * METERS_PER_NANOMETER * METERS_PER_NANOMETER *
             (1/SECONDS_PER_FEMTOSECOND) * (1/SECONDS_PER_FEMTOSECOND) *
             (1/JOULES_PER_EV),
      type: types.FORCE
    },

    MW_VELOCITY_UNIT: {
      name: "MW velocity units (nm / fs)",
      value: 1,
      type: types.VELOCITY
    },

    METERS_PER_SECOND: {
      name: "meters per second",
      value: 1 * METERS_PER_NANOMETER * (1 / SECONDS_PER_FEMTOSECOND),
      type: types.VELOCITY
    }

  };


  /** Provide ratios for conversion of one unit to an equivalent unit type.

     Usage: ratio(units.GRAM, { per: units.KILOGRAM }) === 1000
            ratio(units.GRAM, { as: units.KILOGRAM }) === 0.001
  */
  exports.ratio = ratio = function(from, to) {
    var checkCompatibility = function(fromUnit, toUnit) {
      if (fromUnit.type !== toUnit.type) {
        throw new Error("Attempt to convert incompatible type '" + fromUnit.name + "'' to '" + toUnit.name + "'");
      }
    };

    if (to.per) {
      checkCompatibility(from, to.per);
      return from.value / to.per.value;
    } else if (to.as) {
      checkCompatibility(from, to.as);
      return to.as.value / from.value;
    } else {
      throw new Error("units.ratio() received arguments it couldn't understand.");
    }
  };

  /** Scale 'val' to a different unit of the same type.

    Usage: convert(1, { from: unit.KILOGRAM, to: unit.GRAM }) === 1000
  */
  exports.convert = convert = function(val, fromTo) {
    var from = fromTo && fromTo.from,
        to   = fromTo && fromTo.to;

    if (!from) {
      throw new Error("units.convert() did not receive a \"from\" argument");
    }
    if (!to) {
      throw new Error("units.convert() did not receive a \"to\" argument");
    }

    return val * ratio(to, { per: from });
  };
});

/*global define: true */
/*jslint loopfunc: true */

/** A list of physical constants. To access any given constant, require() this module
    and call the 'as' method of the desired constant to get the constant in the desired unit.

    This module also provides a few helper functions for unit conversion.

    Usage:
      var constants = require('./constants'),

          ATOMIC_MASS_IN_GRAMS = constants.ATOMIC_MASS.as(constants.unit.GRAM),

          GRAMS_PER_KILOGRAM = constants.ratio(constants.unit.GRAM, { per: constants.unit.KILOGRAM }),

          // this works for illustration purposes, although the preferred method would be to pass
          // constants.unit.KILOGRAM to the 'as' method:

          ATOMIC_MASS_IN_KILOGRAMS = constants.convert(ATOMIC_MASS_IN_GRAMS, {
            from: constants.unit.GRAM,
            to:   constants.unit.KILOGRAM
          });
*/

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/constants/index',['require','exports','module','./units'],function (require, exports, module) {

  var units = require('./units'),
      unit  = units.unit,
      ratio = units.ratio,
      convert = units.convert,

      constants = {

        ELEMENTARY_CHARGE: {
          value: 1,
          unit: unit.ELEMENTARY_CHARGE
        },

        ATOMIC_MASS: {
          value: 1,
          unit: unit.DALTON
        },

        BOLTZMANN_CONSTANT: {
          value: 1.380658e-23,
          unit: unit.JOULES_PER_KELVIN
        },

        AVAGADRO_CONSTANT: {
          // N_A is numerically equal to Dalton per gram
          value: ratio( unit.DALTON, { per: unit.GRAM }),
          unit: unit.INVERSE_MOLE
        },

        PERMITTIVITY_OF_FREE_SPACE: {
          value: 8.854187e-12,
          unit: unit.FARADS_PER_METER
        }
      },

      constantName, constant;


  // Derived units
  constants.COULOMB_CONSTANT = {
    value: 1 / (4 * Math.PI * constants.PERMITTIVITY_OF_FREE_SPACE.value),
    unit: unit.METERS_PER_FARAD
  };

  // Exports

  exports.unit = unit;
  exports.ratio = ratio;
  exports.convert = convert;

  // Require explicitness about units by publishing constants as a set of objects with only an 'as' property,
  // which will return the constant in the specified unit.

  for (constantName in constants) {
    if (constants.hasOwnProperty(constantName)) {
      constant = constants[constantName];

      exports[constantName] = (function(constant) {
        return {
          as: function(toUnit) {
            return units.convert(constant.value, { from: constant.unit, to: toUnit });
          }
        };
      }(constant));
    }
  }
});

/*global define: false */
define('md2d/models/aminoacids-props',[],function() {
  return [
    {
      "fullName": "Alanine",
      "abbreviation": "Ala",
      "symbol": "A",
      "molWeight": 89.09,
      "charge": 0,
      "hydrophobicityRB": 2.15,
      "pK": 0,
      "surface": 115,
      "volume": 88.6,
      "solubility": 16.65,
      "hydrophobicity": 1,
      "property": "Total aliphatic; hydrophobic"
    },
    {
      "fullName": "Arginine",
      "abbreviation": "Arg",
      "symbol": "R",
      "molWeight": 174.2,
      "charge": 1,
      "hydrophobicityRB": 2.23,
      "pK": 12,
      "surface": 225,
      "volume": 173.4,
      "solubility": 15,
      "hydrophobicity": -2,
      "property": "Acidic side chains; strongly polar; cationic"
    },
    {
      "fullName": "Asparagine",
      "abbreviation": "Asn",
      "symbol": "N",
      "molWeight": 132.12,
      "charge": 0,
      "hydrophobicityRB": 1.05,
      "pK": 0,
      "surface": 160,
      "volume": 114.1,
      "solubility": 3.53,
      "hydrophobicity": -1,
      "property": "Strongly polar"
    },
    {
      "fullName": "Asparticacid",
      "abbreviation": "Asp",
      "symbol": "D",
      "molWeight": 133.1,
      "charge": -1,
      "hydrophobicityRB": 1.13,
      "pK": 4.4,
      "surface": 150,
      "volume": 111.1,
      "solubility": 0.778,
      "hydrophobicity": -2,
      "property": "Acidic side chains; strongly polar; anionic"
    },
    {
      "fullName": "Cysteine",
      "abbreviation": "Cys",
      "symbol": "C",
      "molWeight": 121.15,
      "charge": 0,
      "hydrophobicityRB": 1.2,
      "pK": 8.5,
      "surface": 135,
      "volume": 108.5,
      "solubility": 1000,
      "hydrophobicity": 1,
      "property": "Polar side chains; semipolar"
    },
    {
      "fullName": "Glutamine",
      "abbreviation": "Gln",
      "symbol": "Q",
      "molWeight": 146.15,
      "charge": 0,
      "hydrophobicityRB": 1.65,
      "pK": 0,
      "surface": 180,
      "volume": 143.8,
      "solubility": 2.5,
      "hydrophobicity": -1,
      "property": "Strongly polar"
    },
    {
      "fullName": "Glutamicacid",
      "abbreviation": "Glu",
      "symbol": "E",
      "molWeight": 147.13,
      "charge": -1,
      "hydrophobicityRB": 1.73,
      "pK": 4.4,
      "surface": 190,
      "volume": 138.4,
      "solubility": 0.864,
      "hydrophobicity": -2,
      "property": "Acidic side chains; strongly polar; anionic"
    },
    {
      "fullName": "Glycine",
      "abbreviation": "Gly",
      "symbol": "G",
      "molWeight": 75.07,
      "charge": 0,
      "hydrophobicityRB": 1.18,
      "pK": 0,
      "surface": 75,
      "volume": 60.1,
      "solubility": 24.99,
      "hydrophobicity": 1,
      "property": "Semipolar"
    },
    {
      "fullName": "Histidine",
      "abbreviation": "His",
      "symbol": "H",
      "molWeight": 155.16,
      "charge": 1,
      "hydrophobicityRB": 2.45,
      "pK": 6.5,
      "surface": 195,
      "volume": 153.2,
      "solubility": 4.19,
      "hydrophobicity": -2,
      "property": "Basic side chains; strongly polar; cationic"
    },
    {
      "fullName": "Isoleucine",
      "abbreviation": "Ile",
      "symbol": "I",
      "molWeight": 131.17,
      "charge": 0,
      "hydrophobicityRB": 3.88,
      "pK": 0,
      "surface": 175,
      "volume": 166.7,
      "solubility": 4.117,
      "hydrophobicity": 1,
      "property": "Branched chain aliphatic; hydrophobic"
    },
    {
      "fullName": "Leucine",
      "abbreviation": "Leu",
      "symbol": "L",
      "molWeight": 131.17,
      "charge": 0,
      "hydrophobicityRB": 4.1,
      "pK": 10,
      "surface": 170,
      "volume": 166.7,
      "solubility": 2.426,
      "hydrophobicity": 1,
      "property": "Branched chain aliphatic; hydrophobic"
    },
    {
      "fullName": "Lysine",
      "abbreviation": "Lys",
      "symbol": "K",
      "molWeight": 146.19,
      "charge": 1,
      "hydrophobicityRB": 3.05,
      "pK": 0,
      "surface": 200,
      "volume": 168.6,
      "solubility": 1000,
      "hydrophobicity": -2,
      "property": "Acidic side chains; strongly polar; cationic"
    },
    {
      "fullName": "Methionine",
      "abbreviation": "Met",
      "symbol": "M",
      "molWeight": 149.21,
      "charge": 0,
      "hydrophobicityRB": 3.43,
      "pK": 0,
      "surface": 185,
      "volume": 162.9,
      "solubility": 3.81,
      "hydrophobicity": 1,
      "property": "Totally alyphatic"
    },
    {
      "fullName": "Phenylalanine",
      "abbreviation": "Phe",
      "symbol": "F",
      "molWeight": 165.19,
      "charge": 0,
      "hydrophobicityRB": 3.46,
      "pK": 0,
      "surface": 210,
      "volume": 189.9,
      "solubility": 2.965,
      "hydrophobicity": 2,
      "property": "Totally aromatic"
    },
    {
      "fullName": "Proline",
      "abbreviation": "Pro",
      "symbol": "P",
      "molWeight": 115.13,
      "charge": 0,
      "hydrophobicityRB": 3.1,
      "pK": 0,
      "surface": 145,
      "volume": 112.7,
      "solubility": 162.3,
      "hydrophobicity": 1,
      "property": "Totally alyphatic"
    },
    {
      "fullName": "Serine",
      "abbreviation": "Ser",
      "symbol": "S",
      "molWeight": 105.09,
      "charge": 0,
      "hydrophobicityRB": 1.4,
      "pK": 0,
      "surface": 115,
      "volume": 89,
      "solubility": 5.023,
      "hydrophobicity": -1,
      "property": "Semipolar"
    },
    {
      "fullName": "Threonine",
      "abbreviation": "Thr",
      "symbol": "T",
      "molWeight": 119.12,
      "charge": 0,
      "hydrophobicityRB": 2.25,
      "pK": 0,
      "surface": 140,
      "volume": 116.1,
      "solubility": 1000,
      "hydrophobicity": -1,
      "property": "Semipolar"
    },
    {
      "fullName": "Tryptophan",
      "abbreviation": "Trp",
      "symbol": "W",
      "molWeight": 204.23,
      "charge": 0,
      "hydrophobicityRB": 4.11,
      "pK": 0,
      "surface": 255,
      "volume": 227.8,
      "solubility": 1.136,
      "hydrophobicity": 2,
      "property": "Totally aromatic"
    },
    {
      "fullName": "Tyrosine",
      "abbreviation": "Tyr",
      "symbol": "Y",
      "molWeight": 181.19,
      "charge": 0,
      "hydrophobicityRB": 2.81,
      "pK": 10,
      "surface": 230,
      "volume": 193.6,
      "solubility": 0.045,
      "hydrophobicity": 1,
      "property": "Hydrophobic; total aromatic"
    },
    {
      "fullName": "Valine",
      "abbreviation": "Val",
      "symbol": "V",
      "molWeight": 117.15,
      "charge": 0,
      "hydrophobicityRB": 3.38,
      "pK": 0,
      "surface": 155,
      "volume": 140,
      "solubility": 8.85,
      "hydrophobicity": 1,
      "property": "Branched chain aliphatic; hydrophobic"
    }
  ];
});


/*
Module which provides convenience functions related to amino acids.
*/


(function() {

  define('cs!md2d/models/aminoacids-helper',['require','md2d/models/aminoacids-props'],function(require) {
    var FIST_ELEMENT_ID, RNA_CODON_TABLE, aminoacidsProps;
    aminoacidsProps = require('md2d/models/aminoacids-props');
    FIST_ELEMENT_ID = 5;
    RNA_CODON_TABLE = {
      "UUU": "Phe",
      "UUC": "Phe",
      "UUA": "Leu",
      "UUG": "Leu",
      "CUU": "Leu",
      "CUC": "Leu",
      "CUA": "Leu",
      "CUG": "Leu",
      "AUU": "Ile",
      "AUC": "Ile",
      "AUA": "Ile",
      "AUG": "Met",
      "GUU": "Val",
      "GUC": "Val",
      "GUA": "Val",
      "GUG": "Val",
      "UCU": "Ser",
      "UCC": "Ser",
      "UCA": "Ser",
      "UCG": "Ser",
      "AGU": "Ser",
      "AGC": "Ser",
      "CCU": "Pro",
      "CCC": "Pro",
      "CCA": "Pro",
      "CCG": "Pro",
      "ACU": "Thr",
      "ACC": "Thr",
      "ACA": "Thr",
      "ACG": "Thr",
      "GCU": "Ala",
      "GCC": "Ala",
      "GCA": "Ala",
      "GCG": "Ala",
      "UAU": "Tyr",
      "UAC": "Tyr",
      "CAU": "His",
      "CAC": "His",
      "CAA": "Gln",
      "CAG": "Gln",
      "AAU": "Asn",
      "AAC": "Asn",
      "AAA": "Lys",
      "AAG": "Lys",
      "GAU": "Asp",
      "GAC": "Asp",
      "GAA": "Glu",
      "GAG": "Glu",
      "UGU": "Cys",
      "UGC": "Cys",
      "UGG": "Trp",
      "CGU": "Arg",
      "CGC": "Arg",
      "CGA": "Arg",
      "CGG": "Arg",
      "AGA": "Arg",
      "AGG": "Arg",
      "GGU": "Gly",
      "GGC": "Gly",
      "GGA": "Gly",
      "GGG": "Gly",
      "UAA": "STOP",
      "UAG": "STOP",
      "UGA": "STOP"
    };
    return {
      /*
        ID of an element representing the first amino acid in the elements collection.
      */

      firstElementID: FIST_ELEMENT_ID,
      /*
        ID of an element representing the last amino acid in the elements collection.
      */

      lastElementID: FIST_ELEMENT_ID + aminoacidsProps.length - 1,
      /*
        Element ID of the cysteine amino acid.
        Note that it should be stored in this class (instead of hard-coded in the engine),
        as it can be changed in the future.
      */

      cysteineElement: 9,
      /*
        Converts @abbreviation of amino acid to element ID.
      */

      abbrToElement: function(abbreviation) {
        var aminoacid, i, _i, _len;
        for (i = _i = 0, _len = aminoacidsProps.length; _i < _len; i = ++_i) {
          aminoacid = aminoacidsProps[i];
          if (aminoacid.abbreviation === abbreviation) {
            return i + this.firstElementID;
          }
        }
      },
      /*
        Returns properties (hash) of amino acid which is represented by a given @elementID.
      */

      getAminoAcidByElement: function(elementID) {
        return aminoacidsProps[elementID - this.firstElementID];
      },
      /*
        Checks if given @elementID represents amino acid.
      */

      isAminoAcid: function(elementID) {
        return elementID >= this.firstElementID && elementID <= this.lastElementID;
      },
      /*
        Returns polar amino acids (array of their element IDs).
      */

      getPolarAminoAcids: function() {
        var abbr, _i, _len, _ref, _results;
        _ref = ["Asn", "Gln", "Ser", "Thr"];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          abbr = _ref[_i];
          _results.push(this.abbrToElement(abbr));
        }
        return _results;
      },
      /*
        Converts RNA Codon to amino acid abbreviation
      */

      codonToAbbr: function(codon) {
        return RNA_CODON_TABLE[codon];
      }
    };
  });

}).call(this);

/*global define: true */
/*jslint eqnull: true */

// Simple (Box-Muller) univariate-normal random number generator.
//
// The 'science.js' library includes a Box-Muller implementation which is likely to be slower, especially in a
// modern Javascript engine, because it uses a rejection method to pick the random point in the unit circle.
// See discussion on pp. 1-3 of:
// http://www.math.nyu.edu/faculty/goodman/teaching/MonteCarlo2005/notes/GaussianSampling.pdf
//

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/math/distributions',['require','exports','module'],function (require, exports, module) {

  exports.normal = (function() {
    var next = null;

    return function(mean, sd) {
      if (mean == null) mean = 0;
      if (sd == null)   sd = 1;

      var r, ret, theta, u1, u2;

      if (next) {
        ret  = next;
        next = null;
        return ret;
      }

      u1    = Math.random();
      u2    = Math.random();
      theta = 2 * Math.PI * u1;
      r     = Math.sqrt(-2 * Math.log(u2));

      next = mean + sd * (r * Math.sin(theta));
      return mean + sd * (r * Math.cos(theta));
    };
  }());
});

/*global define: true */
/*jslint eqnull: true */
/**
  Returns a function which accepts a single numeric argument and returns:

   * the arithmetic mean of the windowSize most recent inputs, including the current input
   * NaN if there have not been windowSize inputs yet.

  The default windowSize is 1000.

*/

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/math/utils',['require','exports','module'],function (require, exports, module) {

  exports.getWindowedAverager = function(windowSize) {

    if (windowSize == null) windowSize = 1000;      // default window size

    var i = 0,
        vals = [],
        sum_vals = 0;

    return function(val) {
      sum_vals -= (vals[i] || 0);
      sum_vals += val;
      vals[i] = val;

      if (++i === windowSize) i = 0;

      if (vals.length === windowSize) {
        return sum_vals / windowSize;
      }
      else {
        // don't allow any numerical comparisons with result to be true
        return NaN;
      }
    };
  };
});

/*global define: true */
/*jshint eqnull:true */
/**
  Simple, good-enough minimization via gradient descent.
*/

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/math/minimizer',['require','exports','module','common/console'],function (require, exports, module) {
  // Dependencies.
  var console = require('common/console');

  exports.minimize = function(f, x0, opts) {
    opts = opts || {};

    if (opts.precision == null) opts.precision = 0.01;

    var // stop when the absolute difference between successive values of f is this much or less
        precision = opts.precision,

        // array of [min, max] boundaries for each component of x
        bounds    = opts.bounds,

        // maximum number of iterations
        maxiter   = opts.maxiter   || 1000,

        // optionally, stop when f is less than or equal to this value
        stopval   = opts.stopval   || -Infinity,

        // maximum distance to move x between steps
        maxstep   = opts.maxstep   || 0.01,

        // multiplied by the gradient
        eps       = opts.eps       || 0.01,
        dim       = x0.length,
        x,
        res,
        f_cur,
        f_prev,
        grad,
        maxstepsq,
        gradnormsq,
        iter,
        i,
        a;

    maxstepsq = maxstep*maxstep;

    // copy x0 into x (which we will mutate)
    x = [];
    for (i = 0; i < dim; i++) {
      x[i] = x0[i];
    }

    // evaluate f and get the gradient
    res = f.apply(null, x);
    f_cur = res[0];
    grad = res[1];

    iter = 0;
    do {
      if (f_cur <= stopval) {
        break;
      }

      if (iter > maxiter) {
        console.log("maxiter reached");
        // don't throw on error, but return some diagnostic information
        return { error: "maxiter reached", f: f_cur, iter: maxiter, x: x };
      }

      // Limit gradient descent step size to maxstep
      gradnormsq = 0;
      for (i = 0; i < dim; i++) {
        gradnormsq += grad[i]*grad[i];
      }
      if (eps*eps*gradnormsq > maxstepsq) {
        a = Math.sqrt(maxstepsq / gradnormsq) / eps;
        for (i = 0; i < dim; i++) {
          grad[i] = a * grad[i];
        }
      }

      // Take a step in the direction opposite the gradient
      for (i = 0; i < dim; i++) {
        x[i] -= eps * grad[i];

        // check bounds
        if (bounds && x[i] < bounds[i][0]) {
          x[i] = bounds[i][0];
        }
        if (bounds && x[i] > bounds[i][1]) {
          x[i] = bounds[i][1];
        }
      }

      f_prev = f_cur;

      res = f.apply(null, x);
      f_cur = res[0];
      grad = res[1];

      iter++;
    } while ( Math.abs(f_cur-f_prev) > precision );

    return [f_cur, x];
  };
});

/*global define: true */

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/math/index',['require','exports','module','./distributions','./utils','./minimizer'],function (require, exports, module) {
  exports.normal              = require('./distributions').normal;
  exports.getWindowedAverager = require('./utils').getWindowedAverager;
  exports.minimize            = require('./minimizer').minimize;
});

/*global define: true */

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/potentials/coulomb',['require','exports','module','../constants/index'],function (require, exports, module) {

  var
  constants = require('../constants/index'),
  unit      = constants.unit,

  // Classic MW uses a value for Coulomb's constant that is effectively 0.346 of the real value
  CLASSIC_MW_FUDGE_FACTOR = 0.346,

  COULOMB_CONSTANT_IN_METERS_PER_FARAD = constants.COULOMB_CONSTANT.as( constants.unit.METERS_PER_FARAD ),

  NANOMETERS_PER_METER = constants.ratio(unit.NANOMETER, { per: unit.METER }),
  COULOMBS_SQ_PER_ELEMENTARY_CHARGE_SQ = Math.pow( constants.ratio(unit.COULOMB, { per: unit.ELEMENTARY_CHARGE }), 2),

  EV_PER_JOULE = constants.ratio(unit.EV, { per: unit.JOULE }),
  MW_FORCE_UNITS_PER_NEWTON = constants.ratio(unit.MW_FORCE_UNIT, { per: unit.NEWTON }),

  // Coulomb constant for expressing potential in eV given elementary charges, nanometers
  k_ePotential = CLASSIC_MW_FUDGE_FACTOR *
                 COULOMB_CONSTANT_IN_METERS_PER_FARAD *
                 COULOMBS_SQ_PER_ELEMENTARY_CHARGE_SQ *
                 NANOMETERS_PER_METER *
                 EV_PER_JOULE,

  // Coulomb constant for expressing force in Dalton*nm/fs^2 given elementary charges, nanometers
  k_eForce = CLASSIC_MW_FUDGE_FACTOR *
             COULOMB_CONSTANT_IN_METERS_PER_FARAD *
             COULOMBS_SQ_PER_ELEMENTARY_CHARGE_SQ *
             NANOMETERS_PER_METER *
             NANOMETERS_PER_METER *
             MW_FORCE_UNITS_PER_NEWTON,

  // Exports

  /** Input:
       r: distance in nanometers,
       q1, q2: elementary charges,
       dC: dielectric constant, unitless,
       rDE: realistic dielectric effect switch, boolean.

      Output units: eV
  */
  potential = exports.potential = function(r, q1, q2, dC, rDE) {
    if (rDE && dC > 1 && r < 1.2) {
      // "Realistic Dielectric Effect" mode:
      // Diminish dielectric constant value using distance between particles.
      // Function based on: http://en.wikipedia.org/wiki/Generalized_logistic_curve
      // See plot for dC = 80: http://goo.gl/7zU6a
      // For optimization purposes it returns asymptotic value when r > 1.2.
      dC = 1 + (dC - 1)/(1 + Math.exp(-12 * r + 7));
    }
    return k_ePotential * ((q1 * q2) / r) / dC;
  },


  /** Input:
       rSq: squared distance in nanometers^2,
       q1, q2: elementary charges,
       dC: dielectric constant, unitless,
       rDE: realistic dielectric effect switch, boolean.

      Output units: "MW Force Units" (Dalton * nm / fs^2)
  */
  forceFromSquaredDistance = exports.forceFromSquaredDistance = function(rSq, q1, q2, dC, rDE) {
    var r = Math.sqrt(rSq);
    if (rDE && dC > 1 && r < 1.2) {
      // "Realistic Dielectric Effect" mode:
      // Diminish dielectric constant value using distance between particles.
      // Function based on: http://en.wikipedia.org/wiki/Generalized_logistic_curve
      // See plot for dC = 80: http://goo.gl/7zU6a
      // For optimization purposes it returns asymptotic value when r > 1.2.
      dC = 1 + (dC - 1)/(1 + Math.exp(-12 * r + 7));
    }
    return -k_eForce * ((q1 * q2) / rSq) / dC;
  },


  forceOverDistanceFromSquaredDistance = exports.forceOverDistanceFromSquaredDistance = function(rSq, q1, q2, dC, rDE) {
    return forceFromSquaredDistance(rSq, q1, q2, dC, rDE) / Math.sqrt(rSq);
  },

  /** Input:
       r: distance in nanometers,
       q1, q2: elementary charges,
       dC: dielectric constant, unitless,
       rDE: realistic dielectric effect switch, boolean.

      Output units: "MW Force Units" (Dalton * nm / fs^2)
  */
  force = exports.force = function(r, q1, q2, dC, rDE) {
    return forceFromSquaredDistance(r*r, q1, q2, dC, rDE);
  };
});

/*global define: true */
/*jshint eqnull:true boss:true */

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/potentials/lennard-jones',['require','exports','module','../constants/index'],function (require, exports, module) {

  var constants = require('../constants/index'),
      unit      = constants.unit,

      NANOMETERS_PER_METER = constants.ratio( unit.NANOMETER, { per: unit.METER }),
      MW_FORCE_UNITS_PER_NEWTON = constants.ratio( unit.MW_FORCE_UNIT, { per: unit.NEWTON });

  /**
    Helper function that returns the correct pairwise epsilon value to be used
    when elements each have epsilon values epsilon1, epsilon2
  */
  exports.pairwiseEpsilon = function(epsilon1, epsilon2) {
    return 0.5 * (epsilon1 + epsilon2);
  },

  /**
    Helper function that returns the correct pairwise sigma value to be used
    when elements each have sigma values sigma1, sigma2
  */
  exports.pairwiseSigma = function(sigma1, sigma2) {
    return Math.sqrt(sigma1 * sigma2);
  },

  /**
    Helper function that returns the correct rmin value for a given sigma
  */
  exports.rmin = function(sigma) {
    return Math.pow(2, 1/6) * sigma;
  };

  /**
    Helper function that returns the correct atomic radius for a given sigma
  */
  exports.radius = function(sigma) {
    // See line 637 of Atom.java (org.concord.mw2d.models.Atom)
    // This assumes the "VdW percentage" is 100%. In classic MW the VdW percentage is settable.
    return 0.5 * sigma;
  };

  /**
    Returns a new object with methods for calculating the force and potential for a Lennard-Jones
    potential with particular values of its parameters epsilon and sigma. These can be adjusted.

    To avoid the needing to take square roots during calculation of pairwise forces, there are
    also methods which calculate the inter-particle potential directly from a squared distance, and
    which calculate the quantity (force/distance) directly from a squared distance.

    This function also accepts a callback function which will be called with a hash representing
    the new coefficients, whenever the LJ coefficients are changed for the returned calculator.
  */
  exports.newLJCalculator = function(params, cb) {

    var epsilon,          // parameter; depth of the potential well, in eV
        sigma,            // parameter: characteristic distance from particle, in nm

        rmin,             // distance from particle at which the potential is at its minimum
        alpha_Potential,  // precalculated; units are eV * nm^12
        beta_Potential,   // precalculated; units are eV * nm^6
        alpha_Force,      // units are "MW Force Units" * nm^13
        beta_Force,       // units are "MW Force Units" * nm^7

        initialized = false, // skip callback during initialization

        setCoefficients = function(e, s) {
          // Input units:
          //  epsilon: eV
          //  sigma:   nm

          epsilon = e;
          sigma   = s;
          rmin    = exports.rmin(sigma);

          if (epsilon != null && sigma != null) {
            alpha_Potential = 4 * epsilon * Math.pow(sigma, 12);
            beta_Potential  = 4 * epsilon * Math.pow(sigma, 6);

            // (1 J * nm^12) = (1 N * m * nm^12)
            // (1 N * m * nm^12) * (b nm / m) * (c MWUnits / N) = (abc MWUnits nm^13)
            alpha_Force = 12 * constants.convert(alpha_Potential, { from: unit.EV, to: unit.JOULE }) * NANOMETERS_PER_METER * MW_FORCE_UNITS_PER_NEWTON;
            beta_Force =  6 * constants.convert(beta_Potential,  { from: unit.EV, to: unit.JOULE }) * NANOMETERS_PER_METER * MW_FORCE_UNITS_PER_NEWTON;
          }

          if (initialized && typeof cb === 'function') cb(getCoefficients(), this);
        },

        getCoefficients = function() {
          return {
            epsilon: epsilon,
            sigma  : sigma,
            rmin   : rmin
          };
        },

        validateEpsilon = function(e) {
          if (e == null || parseFloat(e) !== e) {
            throw new Error("lennardJones: epsilon value " + e + " is invalid");
          }
        },

        validateSigma = function(s) {
          if (s == null || parseFloat(s) !== s || s <= 0) {
            throw new Error("lennardJones: sigma value " + s + " is invalid");
          }
        },

        // this object
        calculator;

        // At creation time, there must be a valid epsilon and sigma ... we're not gonna check during
        // inner-loop force calculations!
        validateEpsilon(params.epsilon);
        validateSigma(params.sigma);

        // Initialize coefficients to passed-in values, skipping setCoefficients callback
        setCoefficients(params.epsilon, params.sigma);
        initialized = true;

    return calculator = {

      getCoefficients: getCoefficients,

      setEpsilon: function(e) {
        validateEpsilon(e);
        setCoefficients(e, sigma);
      },

      setSigma: function(s) {
        validateSigma(s);
        setCoefficients(epsilon, s);
      },

      /**
        Input units: r_sq: nm^2
        Output units: eV

        minimum is at r=rmin, V(rmin) = 0
      */
      potentialFromSquaredDistance: function(r_sq) {
        if (!r_sq) return -Infinity;
        return alpha_Potential*Math.pow(r_sq, -6) - beta_Potential*Math.pow(r_sq, -3);
      },

      /**
        Input units: r: nm
        Output units: eV
      */
      potential: function(r) {
        return calculator.potentialFromSquaredDistance(r*r);
      },

      /**
        Input units: r_sq: nm^2
        Output units: MW Force Units / nm (= Dalton / fs^2)
      */
      forceOverDistanceFromSquaredDistance: function(r_sq) {
        // optimizing divisions actually does appear to be *slightly* faster
        var r_minus2nd  = 1 / r_sq,
            r_minus6th  = r_minus2nd * r_minus2nd * r_minus2nd,
            r_minus8th  = r_minus6th * r_minus2nd,
            r_minus14th = r_minus8th * r_minus6th;

        return alpha_Force*r_minus14th - beta_Force*r_minus8th;
      },

      /**
        Input units: r: nm
        Output units: MW Force Units (= Dalton * nm / fs^2)
      */
      force: function(r) {
        return r * calculator.forceOverDistanceFromSquaredDistance(r*r);
      }
    };
  };
});

/*global define: true */

// Module can be used both in Node.js environment and in Web browser
// using RequireJS. RequireJS Optimizer will strip out this if statement.


define('md2d/models/engine/potentials/index',['require','exports','module','./coulomb','./lennard-jones'],function (require, exports, module) {
  exports.coulomb = require('./coulomb');
  exports.lennardJones = require('./lennard-jones');
});

/*global define: false */

define('md2d/models/metadata',[],function() {

  return {
    mainProperties: {
      type: {
        defaultValue: "md2d",
        immutable: true
      },
      width: {
        defaultValue: 10,
        immutable: true
      },
      height: {
        defaultValue: 10,
        immutable: true
      },
      lennardJonesForces: {
        defaultValue: true
      },
      coulombForces: {
        defaultValue: true
      },
      temperatureControl: {
        defaultValue: false
      },
      targetTemperature: {
        defaultValue: 300
      },
      modelSampleRate: {
        defaultValue: "default"
      },
      gravitationalField: {
        defaultValue: false
      },
      timeStep: {
        defaultValue: 1
      },
      dielectricConstant: {
        defaultValue: 1
      },
      realisticDielectricEffect: {
        defaultValue: true
      },
      solventForceFactor: {
        defaultValue: 1.25
      },
      solventForceType: {
        //  0 - vacuum.
        //  1 - water.
        // -1 - oil.
        defaultValue: 0
      },
      // Additional force applied to amino acids that depends on distance from the center of mass. It affects
      // only AAs which are pulled into the center of mass (to stabilize shape of the protein).
      // 'additionalSolventForceMult'      - maximum multiplier applied to solvent force when AA is in the center of mass.
      // 'additionalSolventForceThreshold' - maximum distance from the center of mass which triggers this increase of the force.
      // The additional force is described by the linear function of the AA distance from the center of mass
      // that passes through two points:
      // (0, additionalSolventForceMult) and (additionalSolventForceThreshold, 1).
      additionalSolventForceMult: {
        defaultValue: 4
      },
      additionalSolventForceThreshold: {
        defaultValue: 10
      },
      polarAAEpsilon: {
        defaultValue: -2
      },
      viscosity: {
        defaultValue: 1
      },
      viewRefreshInterval: {
        defaultValue: 50
      }
    },

    viewOptions: {
      backgroundColor: {
        defaultValue: "#eeeeee"
      },
      showClock: {
        defaultValue: true
      },
      keShading: {
        defaultValue: false
      },
      chargeShading: {
        defaultValue: false
      },
      useThreeLetterCode: {
        defaultValue: true
      },
      aminoAcidColorScheme: {
        defaultValue: "hydrophobicity"
      },
      showChargeSymbols: {
        defaultValue: true
      },
      showVDWLines: {
        defaultValue: false
      },
      VDWLinesCutoff: {
        defaultValue: "medium"
      },
      showVelocityVectors: {
        defaultValue: false
      },
      showForceVectors: {
        defaultValue: false
      },
      showAtomTrace: {
        defaultValue: false
      },
      atomTraceId: {
        defaultValue: 0
      },
      images: {
        defaultValue: []
      },
      imageMapping: {
        defaultValue: {}
      },
      textBoxes: {
        defaultValue: []
      },
      fitToParent: {
        defaultValue: false
      },
      xlabel: {
        defaultValue: false
      },
      ylabel: {
        defaultValue: false
      },
      xunits: {
        defaultValue: false
      },
      yunits: {
        defaultValue: false
      },
      controlButtons: {
        defaultValue: "play"
      },
      gridLines: {
        defaultValue: false
      },
      atomNumbers: {
        defaultValue: false
      },
      enableAtomTooltips: {
        defaultValue: false
      },
      enableKeyboardHandlers: {
        defaultValue: true
      },
      atomTraceColor: {
        defaultValue: "#6913c5"
      },
      velocityVectors: {
        defaultValue: {
          color: "#000",
          width: 0.01,
          length: 2
        }
      },
      forceVectors: {
        defaultValue: {
          color: "#169C30",
          width: 0.01,
          length: 2
        }
      }
    },

    atom: {
      // Required properties:
      x: {
        required: true
      },
      y: {
        required: true
      },
      // Optional properties:
      element: {
        defaultValue: 0
      },
      vx: {
        defaultValue: 0
      },
      vy: {
        defaultValue: 0
      },
      ax: {
        defaultValue: 0,
        serialize: false
      },
      ay: {
        defaultValue: 0,
        serialize: false
      },
      charge: {
        defaultValue: 0
      },
      friction: {
        defaultValue: 0
      },
      visible: {
        defaultValue: 1
      },
      pinned: {
        defaultValue: 0
      },
      marked: {
        defaultValue: 0
      },
      draggable: {
        defaultValue: 0
      },
      // Read-only values, can be set only by engine:
      radius: {
        readOnly: true,
        serialize: false
      },
      px: {
        readOnly: true,
        serialize: false
      },
      py: {
        readOnly: true,
        serialize: false
      },
      speed: {
        readOnly: true,
        serialize: false
      }
    },

    element: {
      mass: {
        defaultValue: 120
      },
      sigma: {
        defaultValue: 0.3
      },
      epsilon: {
        defaultValue: -0.1
      },
      radius: {
        readOnly: true,
        serialize: false
      },
      color: {
        defaultValue: -855310
      }
    },

    pairwiseLJProperties: {
      element1: {
        defaultValue: 0
      },
      element2: {
        defaultValue: 0
      },
      sigma: {
      },
      epsilon: {
      }
    },

    obstacle: {
      // Required properties:
      width: {
        required: true
      },
      height: {
        required: true
      },
      // Optional properties:
      x: {
        defaultValue: 0
      },
      y: {
        defaultValue: 0
      },
      mass: {
        defaultValue: Infinity
      },
      vx: {
        defaultValue: 0
      },
      vy: {
        defaultValue: 0
      },
      // External horizontal force, per mass unit.
      externalFx: {
        defaultValue: 0
      },
      // External vertical force, per mass unit.
      externalFy: {
        defaultValue: 0
      },
      // Damping force, per mass unit.
      friction: {
        defaultValue: 0
      },
      // Pressure probe, west side.
      westProbe: {
        defaultValue: false
      },
      // Final value of pressure in Bars.
      westProbeValue: {
        readOnly: true,
        serialize: false
      },
      // Pressure probe, north side.
      northProbe: {
        defaultValue: false
      },
      // Final value of pressure in Bars.
      northProbeValue: {
        readOnly: true,
        serialize: false
      },
      // Pressure probe, east side.
      eastProbe: {
        defaultValue: false
      },
      // Final value of pressure in Bars.
      eastProbeValue: {
        readOnly: true,
        serialize: false
      },
      // Pressure probe, south side.
      southProbe: {
        defaultValue: false
      },
      // Final value of pressure in Bars.
      southProbeValue: {
        readOnly: true,
        serialize: false
      },
      // View options.
      colorR: {
        defaultValue: 128
      },
      colorG: {
        defaultValue: 128
      },
      colorB: {
        defaultValue: 128
      },
      visible: {
        defaultValue: true
      }
    },

    radialBond: {
      atom1: {
        defaultValue: 0
      },
      atom2: {
        defaultValue: 0
      },
      length: {
        required: true
      },
      strength: {
        required: true
      },
      type: {
        defaultValue: 101
      }
    },

    angularBond: {
      atom1: {
        defaultValue: 0
      },
      atom2: {
        defaultValue: 0
      },
      atom3: {
        defaultValue: 0
      },
      strength: {
        required: true
      },
      angle: {
        required: true
      }
    },

    restraint: {
      atomIndex: {
        required: true
      },
      k: {
        defaultValue: 2000
      },
      x0: {
        defaultValue: 0
      },
      y0: {
        defaultValue: 0
      }
    },

    geneticProperties: {
      DNA: {
        defaultValue: ""
      },
      DNAComplement: {
        readOnly: true,
        serialize: false
      },
      mRNA: {
        // Immutable directly via set method.
        // Use provided API to generate mRNA.
        immutable: true
      },
      translationStep: {
        // When this property is undefined, it means that the translation
        // hasn't been yet started. Note that when translation is finished,
        // translationStep will be equal to "end".
        // Immutable directly via set method.
        // Use provided API to translate step by step.
        immutable: true
      },
      x: {
        defaultValue: 0.01
      },
      y: {
        defaultValue: 0.01
      },
      height: {
        defaultValue: 0.12
      },
      width: {
        defaultValue: 0.08
      }
    },

    textBox: {
      text: {
        defaultValue: ""
      },
      x: {
        defaultValue: 0
      },
      y: {
        defaultValue: 0
      },
      layer: {
        defaultValue: 1
      },
      width: {},
      frame: {},
      color: {},
      backgroundColor: {},
      hostType: {},
      hostIndex: {},
      textAlign: {}
    }
  };
});


/*
Custom pairwise Lennard Jones properties.
*/


(function() {
  var __hasProp = {}.hasOwnProperty;

  define('cs!md2d/models/engine/pairwise-lj-properties',['require','md2d/models/metadata','common/validator'],function(require) {
    var PairwiseLJProperties, metadata, validator;
    metadata = require("md2d/models/metadata");
    validator = require("common/validator");
    return PairwiseLJProperties = (function() {

      function PairwiseLJProperties(engine) {
        this._engine = engine;
        this._data = {};
      }

      PairwiseLJProperties.prototype.registerChangeHooks = function(changePreHook, changePostHook) {
        this._changePreHook = changePreHook;
        return this._changePostHook = changePostHook;
      };

      PairwiseLJProperties.prototype.set = function(i, j, props) {
        var key;
        props = validator.validate(metadata.pairwiseLJProperties, props);
        this._changePreHook();
        if (!(this._data[i] != null)) {
          this._data[i] = {};
        }
        if (!(this._data[j] != null)) {
          this._data[j] = {};
        }
        if (!(this._data[i][j] != null)) {
          this._data[i][j] = this._data[j][i] = {};
        }
        for (key in props) {
          if (!__hasProp.call(props, key)) continue;
          this._data[i][j][key] = props[key];
        }
        this._engine.setPairwiseLJProperties(i, j);
        return this._changePostHook();
      };

      PairwiseLJProperties.prototype.remove = function(i, j) {
        this._changePreHook();
        delete this._data[i][j];
        delete this._data[j][i];
        this._engine.setPairwiseLJProperties(i, j);
        return this._changePostHook();
      };

      PairwiseLJProperties.prototype.get = function(i, j) {
        if (this._data[i] && this._data[i][j]) {
          return this._data[i][j];
        } else {
          return void 0;
        }
      };

      PairwiseLJProperties.prototype.deserialize = function(array) {
        var el1, el2, props, _i, _len;
        for (_i = 0, _len = array.length; _i < _len; _i++) {
          props = array[_i];
          props = validator.validateCompleteness(metadata.pairwiseLJProperties, props);
          el1 = props.element1;
          el2 = props.element2;
          delete props.element1;
          delete props.element2;
          this.set(el1, el2, props);
        }
      };

      PairwiseLJProperties.prototype.serialize = function() {
        var innerObj, key1, key2, props, result, _ref;
        result = [];
        _ref = this._data;
        for (key1 in _ref) {
          if (!__hasProp.call(_ref, key1)) continue;
          innerObj = _ref[key1];
          for (key2 in innerObj) {
            if (!__hasProp.call(innerObj, key2)) continue;
            if (key1 < key2) {
              props = this.get(key1, key2);
              props.element1 = Number(key1);
              props.element2 = Number(key2);
              result.push(props);
            }
          }
        }
        return result;
      };

      /*
          Clone-Restore Interface.
      */


      PairwiseLJProperties.prototype.clone = function() {
        return $.extend(true, {}, this._data);
      };

      PairwiseLJProperties.prototype.restore = function(state) {
        var innerObj, key1, key2, _ref;
        this._data = state;
        _ref = this._data;
        for (key1 in _ref) {
          if (!__hasProp.call(_ref, key1)) continue;
          innerObj = _ref[key1];
          for (key2 in innerObj) {
            if (!__hasProp.call(innerObj, key2)) continue;
            if (key1 < key2) {
              this._engine.setPairwiseLJProperties(key1, key2);
            }
          }
        }
      };

      return PairwiseLJProperties;

    })();
  });

}).call(this);

/*global define: false, $ */

define('common/serialize',['require','arrays'],function(require) {

  var arrays = require('arrays'),

      infinityToString = function (obj) {
        var i, len;
        if (arrays.isArray(obj)) {
          for (i = 0, len = obj.length; i < len; i++) {
            if (obj[i] === Infinity || obj[i] === -Infinity) {
              obj[i] = obj[i].toString();
            }
          }
        } else {
          for (i in obj) {
            if (obj.hasOwnProperty(i)) {
              if (obj[i] === Infinity || obj[i] === -Infinity) {
                obj[i] = obj[i].toString();
              }
              if (typeof obj[i] === 'object' || arrays.isArray(obj[i])) {
                infinityToString(obj[i]);
              }
            }
          }
        }
      };

  return function serialize(metaData, propertiesHash, count) {
    var result = {}, propName, prop;
    for (propName in metaData) {
      if (metaData.hasOwnProperty(propName)) {
        if (propertiesHash[propName] !== undefined && metaData[propName].serialize !== false) {
          prop = propertiesHash[propName];
          if (arrays.isArray(prop)) {
            result[propName] = count !== undefined ? arrays.copy(arrays.extend(prop, count), []) : arrays.copy(prop, []);
          }
          else if (typeof prop === 'object') {
            result[propName] = $.extend(true, {}, prop);
          }
          else {
            result[propName] = prop;
          }
        }
      }
    }
    // JSON doesn't allow Infinity values so convert them to strings.
    infinityToString(result);
    // TODO: to make serialization faster, replace arrays.copy(prop, [])
    // with arrays.clone(prop) to use typed arrays whenever they are available.
    // Also, do not call "infinityToString" function. This can be useful when
    // we decide to use serialization in tick history manager.
    // Then we can provide toString() function which will use regular arrays,
    // replace each Infinity value with string and finally call JSON.stringify().
    return result;
  };

});

/*global d3, define */

define('md2d/models/engine/genetic-properties',['require','common/validator','common/serialize','md2d/models/metadata','cs!md2d/models/aminoacids-helper'],function (require) {

  var validator        = require('common/validator'),
      serialize        = require('common/serialize'),
      metadata         = require('md2d/models/metadata'),
      aminoacidsHelper = require('cs!md2d/models/aminoacids-helper'),

      ValidationError = validator.ValidationError;


  return function GeneticProperties() {
    var api,
        changePreHook,
        changePostHook,
        data,
        remainingAAs,

        dispatch = d3.dispatch("change"),

        calculateComplementarySequence = function () {
          // A-T (A-U)
          // G-C
          // T-A (U-A)
          // C-G

          // Use lower case during conversion to
          // avoid situation when you change A->T,
          // and later T->A again.
          var compSeq = data.DNA
            .replace(/A/g, "t")
            .replace(/G/g, "c")
            .replace(/T/g, "a")
            .replace(/C/g, "g");

          data.DNAComplement = compSeq.toUpperCase();
        },

        customValidate = function (props) {
          if (props.DNA) {
            // Allow user to use both lower and upper case.
            props.DNA = props.DNA.toUpperCase();

            if (props.DNA.search(/[^AGTC]/) !== -1) {
              // Character other than A, G, T or C is found.
              throw new ValidationError("DNA", "DNA code on sense strand can be defined using only A, G, T or C characters.");
            }
          }
          return props;
        },

        create = function (props) {
          changePreHook();

          // Note that validator always returns a copy of the input object, so we can use it safely.
          props = validator.validateCompleteness(metadata.geneticProperties, props);
          props = customValidate(props);

          // Note that validator always returns a copy of the input object, so we can use it safely.
          data = props;
          calculateComplementarySequence();

          changePostHook();
          dispatch.change();
        },

        update = function (props) {
          var key;

          changePreHook();

          // Validate and update properties.
          props = validator.validate(metadata.geneticProperties, props);
          props = customValidate(props);

          for (key in props) {
            if (props.hasOwnProperty(key)) {
              data[key] = props[key];
            }
          }

          if (props.DNA) {
            // New DNA code specified, update related properties.
            // 1. DNA complementary sequence.
            calculateComplementarySequence();
            // 2. mRNA is no longer valid. Do not recalculate it automatically
            //    (transribeDNA method should be used).
            delete data.mRNA;
            // 3. Any translation in progress should be reseted.
            delete data.translationStep;
          }

          changePostHook();
          dispatch.change();
        };

    // Public API.
    api = {
      registerChangeHooks: function (newChangePreHook, newChangePostHook) {
        changePreHook = newChangePreHook;
        changePostHook = newChangePostHook;
      },

      // Sets (updates) genetic properties.
      set: function (props) {
        if (data === undefined) {
          // Use other method of validation, ensure that the data hash is complete.
          create(props);
        } else {
          // Just update existing genetic properties.
          update(props);
        }
      },

      // Returns genetic properties.
      get: function () {
        return data;
      },

      // Deserializes genetic properties.
      deserialize: function (props) {
        create(props);
      },

      // Serializes genetic properties.
      serialize: function () {
        return data ? serialize(metadata.geneticProperties, data) : undefined;
      },

      // Convenient method for validation. It doesn't throw an exception,
      // instead a special object with validation status is returned. It can
      // be especially useful for UI classes to avoid try-catch sequences with
      // "set". The returned status object always has a "valid" property,
      // which contains result of the validation. When validation fails, also
      // "errors" hash is provided which keeps error for property causing
      // problems.
      // e.g. {
      //   valid: false,
      //   errors: {
      //     DNA: "DNA code on sense strand can be defined using only A, G, T or C characters."
      //   }
      // }
      validate: function (props) {
        var status = {
          valid: true
        };
        try {
          // Validation based on metamodel definition.
          props = validator.validate(metadata.geneticProperties, props);
          // Custom validation.
          customValidate(props);
        } catch (e) {
          status.valid = false;
          status.errors = {};
          status.errors[e.prop] = e.message;
        }
        return status;
      },

      on: function(type, listener) {
        dispatch.on(type, listener);
      },

      // Transcribes mRNA from DNA.
      // Result is saved in the mRNA property.
      transcribeDNA: function() {
        changePreHook();
        // A-U
        // G-C
        // T-A
        // C-G

        // Use lower case during conversion to
        // avoid situation when you change G->C,
        // and later C->G again.
        var mRNA = data.DNAComplement
          .replace(/A/g, "u")
          .replace(/G/g, "c")
          .replace(/T/g, "a")
          .replace(/C/g, "g");

        data.mRNA = mRNA.toUpperCase();

        changePostHook();
        dispatch.change();
      },

      // Translates mRNA into amino acids chain.
      translate: function() {
        var result = [],
            mRNA, abbr, i, len;

        // Make sure that mRNA is available.
        if (data.mRNA === undefined) {
          api.transcribeDNA();
        }
        mRNA = data.mRNA;

        for (i = 0, len = mRNA.length; i + 3 <= len; i += 3) {
          abbr = aminoacidsHelper.codonToAbbr(mRNA.substr(i, 3));
          if (abbr === "STOP" || abbr === undefined) {
            return result;
          }
          result.push(abbr);
        }

        return result;
      },

      translateStepByStep: function() {
        var aaSequence, aaAbbr;

        changePreHook();

        aaSequence = api.translate();
        if (data.translationStep === undefined) {
          data.translationStep = 0;
        } else {
          data.translationStep += 1;
        }
        aaAbbr = aaSequence[data.translationStep];
        if (aaAbbr === undefined) {
          data.translationStep = "end";
        }
        changePostHook();
        dispatch.change();

        return aaAbbr;
      }
    };

    return api;
  };

});

/*global define */

// Simple wrapper for cloning and restoring hash of arrays.
// Such structure is widely used in md2d engine for keeping
// state of various objects (like atoms and obstacles).
// Use it in the following way:
// var obj = saveRestoreWrapper(hashOfArrays)
// var state = obj.clone();
// (...)
// obj.restore(state);

define('common/models/engines/clone-restore-wrapper',['require','arrays'],function (require) {
  // Dependencies.
  var arrays = require('arrays');

  return function CloneRestoreWrapper(hashOfArrays) {
    // Public API.
    return {
      // Clone hash of arrays
      clone: function() {
        var copy = {},
            prop;

        for (prop in hashOfArrays) {
          if (hashOfArrays.hasOwnProperty(prop)) {
            copy[prop] = arrays.clone(hashOfArrays[prop]);
          }
        }

        return copy;
      },

      // Restore internal arrays using saved state.
      restore: function (state) {
        var prop;

        for (prop in hashOfArrays) {
          if (hashOfArrays.hasOwnProperty(prop)) {
            arrays.copy(state[prop], hashOfArrays[prop]);
          }
        }
      }
    };
  };

});

/*global define */

// Cell lists (also sometimes referred to as Cell linked-lists) are a tool for
// finding all atom pairs within a given cut-off distance of each other in
// Molecular dynamics simulations.
// See: http://en.wikipedia.org/wiki/Cell_lists

define('md2d/models/engine/cell-list',[],function () {

  return function CellList(width, height, cellSize) {
    var api,
        colsNum,
        rowsNum,
        cellsNum,
        cell,

        init = function () {
          var i;
          colsNum = Math.ceil(width / cellSize);
          rowsNum = Math.ceil(height / cellSize);
          cellsNum = colsNum * rowsNum;
          cell = new Array(cellsNum);
          for(i = 0; i < cellsNum; i++) {
            cell[i] = [];
          }
        };

    init ();

    // Public API.
    api = {
      reinitialize: function (newCellSize) {
        if (newCellSize !== cellSize) {
          cellSize = newCellSize;
          init();
        }
      },

      addToCell: function (atomIdx, x, y) {
        var cellIdx = Math.floor(y / cellSize) * colsNum + Math.floor(x / cellSize);
        cell[cellIdx].push(atomIdx);
      },

      getCell: function (idx) {
        return cell[idx];
      },

      getRowsNum: function () {
        return rowsNum;
      },

      getColsNum: function () {
        return colsNum;
      },

      getNeighboringCells: function (rowIdx, colIdx) {
        var cellIdx = rowIdx * colsNum + colIdx,
            result = [];

        // Upper right.
        if (colIdx + 1 < colsNum && rowIdx + 1 < rowsNum) result.push(cell[cellIdx + colsNum + 1]);
        // Right.
        if (colIdx + 1 < colsNum) result.push(cell[cellIdx + 1]);
        // Bottom right.
        if (colIdx + 1 < colsNum && rowIdx - 1 >= 0) result.push(cell[cellIdx - colsNum + 1]);
        // Bottom.
        if (rowIdx - 1 >= 0) result.push(cell[cellIdx - colsNum]);

        return result;
      },

      clear: function () {
        var i;
        for (i = 0; i < cellsNum; i++) {
          cell[i].length = 0;
        }
      }
    };

    return api;
  };

});

/*global define */

// A Verlet list (named after Loup Verlet) is a data structure in molecular dynamics simulations
// to efficiently maintain a list of all particles within a given cut-off distance of each other.
// See: http://en.wikipedia.org/wiki/Verlet_list

define('md2d/models/engine/neighbor-list',['require','arrays','common/array-types'],function (require) {
  // Dependencies.
  var arrays     = require('arrays'),
      arrayTypes = require('common/array-types');

  return function NeighborList(atomsNum, maxDisplacement) {
    var api,
        maxAtomsNum,
        listIdx,
        listCapacity,
        list,
        head,
        tail,
        x,
        y,
        forceUpdate,

        init = function () {
          // Keep maximum capacity of lists bigger than actual number of atoms.
          maxAtomsNum = atomsNum + 10;
          listIdx = 0;
          listCapacity = maxAtomsNum * (maxAtomsNum - 1) / 2;
          forceUpdate = true;

          list = arrays.create(listCapacity, 0, arrayTypes.int16);
          head = arrays.create(maxAtomsNum, -1, arrayTypes.int16);
          tail = arrays.create(maxAtomsNum, -1, arrayTypes.int16);
          // Fill x and y with Infinity, so shouldUpdate(..)
          // will return true during first call after initialization.
          x    = arrays.create(maxAtomsNum, Infinity, arrayTypes.float);
          y    = arrays.create(maxAtomsNum, Infinity, arrayTypes.float);
        };

    init();

    // Public API.
    api = {
      reinitialize: function (newAtomsNum, newMaxDisplacement) {
        atomsNum = newAtomsNum;
        maxDisplacement = newMaxDisplacement;
        forceUpdate = true;

        if (atomsNum > maxAtomsNum) {
          init();
        }
      },
      clear: function () {
        var i;
        listIdx = 0;
        for (i = 0; i < atomsNum; i++) {
          head[i] = tail[i] = -1;
        }
      },
      getList: function () {
        return list;
      },
      markNeighbors: function (i, j) {
        if (head[i] < 0) {
          head[i] = listIdx;
        }
        list[listIdx] = j;
        listIdx++;
        tail[i] = listIdx;
      },
      getStartIdxFor: function (i) {
        return head[i];
      },
      getEndIdxFor: function (i) {
        return tail[i];
      },
      saveAtomPosition: function (i, xCoord, yCoord) {
        x[i] = xCoord;
        y[i] = yCoord;
      },
      invalidate: function () {
        forceUpdate = true;
      },
      shouldUpdate: function (newX, newY) {
        var maxDx = -Infinity,
            maxDy = -Infinity,
            i;

        if (forceUpdate) {
          forceUpdate = false;
          return true;
        }

        for (i = 0; i < atomsNum; i++) {
          if (Math.abs(newX[i] - x[i]) > maxDx) {
            maxDx = Math.abs(newX[i] - x[i]);
          }
          if (Math.abs(newY[i] - y[i]) > maxDy) {
            maxDy = Math.abs(newY[i] - y[i]);
          }
        }

        return Math.sqrt(maxDx * maxDx + maxDy * maxDy) > maxDisplacement;
      }
    };

    return api;
  };

});

/*global define: true */
/*jslint eqnull: true, boss: true, loopfunc: true*/

define('md2d/models/engine/md2d',['require','exports','module','arrays','common/array-types','common/console','./constants/index','cs!md2d/models/aminoacids-helper','./math/index','./potentials/index','./potentials/index','cs!./pairwise-lj-properties','./genetic-properties','common/models/engines/clone-restore-wrapper','./cell-list','./neighbor-list'],function (require, exports, module) {

  var arrays               = require('arrays'),
      arrayTypes           = require('common/array-types'),
      console              = require('common/console'),
      constants            = require('./constants/index'),
      unit                 = constants.unit,
      aminoacidsHelper     = require('cs!md2d/models/aminoacids-helper'),
      math                 = require('./math/index'),
      coulomb              = require('./potentials/index').coulomb,
      lennardJones         = require('./potentials/index').lennardJones,
      PairwiseLJProperties = require('cs!./pairwise-lj-properties'),
      GeneticProperties    = require('./genetic-properties'),
      CloneRestoreWrapper  = require('common/models/engines/clone-restore-wrapper'),
      CellList             = require('./cell-list'),
      NeighborList         = require('./neighbor-list'),

      // from A. Rahman "Correlations in the Motion of Atoms in Liquid Argon", Physical Review 136 pp. A405–A411 (1964)
      ARGON_LJ_EPSILON_IN_EV = -120 * constants.BOLTZMANN_CONSTANT.as(unit.EV_PER_KELVIN),
      ARGON_LJ_SIGMA_IN_NM   = 0.34,

      ARGON_MASS_IN_DALTON = 39.95,
      ARGON_MASS_IN_KG = constants.convert(ARGON_MASS_IN_DALTON, { from: unit.DALTON, to: unit.KILOGRAM }),

      BOLTZMANN_CONSTANT_IN_JOULES = constants.BOLTZMANN_CONSTANT.as( unit.JOULES_PER_KELVIN ),

      cross = function(a0, a1, b0, b1) {
        return a0*b1 - a1*b0;
      },

      sumSquare = function(a,b) {
        return a*a + b*b;
      },

      /**
        Convert total kinetic energy in the container of N atoms to a temperature in Kelvin.

        Input units:
          KE: "MW Energy Units" (Dalton * nm^2 / fs^2)
        Output units:
          T: K
      */
      convertKEtoT = function(totalKEinMWUnits, N) {
        // In 2 dimensions, kT = (2/N_df) * KE

        var N_df = 2 * N,
            averageKEinMWUnits = (2 / N_df) * totalKEinMWUnits,
            averageKEinJoules = constants.convert(averageKEinMWUnits, { from: unit.MW_ENERGY_UNIT, to: unit.JOULE });

        return averageKEinJoules / BOLTZMANN_CONSTANT_IN_JOULES;
      },

      /**
        Convert a temperature in Kelvin to the total kinetic energy in the container of N atoms.

        Input units:
          T: K
        Output units:
          KE: "MW Energy Units" (Dalton * nm^2 / fs^2)
      */
      convertTtoKE = function(T, N) {
        var N_df = 2 * N,
            averageKEinJoules  = T * BOLTZMANN_CONSTANT_IN_JOULES,
            averageKEinMWUnits = constants.convert(averageKEinJoules, { from: unit.JOULE, to: unit.MW_ENERGY_UNIT }),
            totalKEinMWUnits = averageKEinMWUnits * N_df / 2;

        return totalKEinMWUnits;
      },

      validateTemperature = function(t) {
        var temperature = parseFloat(t);

        if (isNaN(temperature)) {
          throw new Error("md2d: requested temperature " + t + " could not be understood.");
        }
        if (temperature < 0) {
          throw new Error("md2d: requested temperature " + temperature + " was less than zero");
        }
        if (temperature === Infinity) {
          throw new Error("md2d: requested temperature was Infinity!");
        }
      };

  exports.createEngine = function() {

    var // the object to be returned
        engine,

        // Whether system dimensions have been set. This is only allowed to happen once.
        sizeHasBeenInitialized = false,

        // Whether to simulate Coulomb forces between particles.
        useCoulombInteraction = false,

        // Dielectric constant, it influences Coulomb interaction.
        // E.g. a dielectric of 80 means a Coulomb force 1/80th as strong.
        dielectricConst = 1,

        // Whether dielectric effect should be realistic or simplified. Realistic
        // version takes into account distance between charged particles and reduces
        // dielectric constant when particles are closer to each other.
        realisticDielectricEffect = true,

        // Parameter that reflects the watery extent of the solvent, when an effective
        // hydrophobic/hydrophilic interaction is used. A negative value represents oil environment
        // (usually -1). A positive one represents water environment (usually 1). A zero value means vacuum.
        solventForceType = 0,

        // Parameter that influences strength of force applied to amino acids by water of oil (solvent).
        solventForceFactor = 1,

        // Additional force applied to amino acids that depends on distance from the center of mass. It affects
        // only AAs which are pulled into the center of mass (to stabilize shape of the protein).
        additionalSolventForceMult = 25,
        additionalSolventForceThreshold = 3,

        // Whether to simulate Lennard Jones forces between particles.
        useLennardJonesInteraction = true,

        // Whether to use the thermostat to maintain the system temperature near T_target.
        useThermostat = false,

        // A value to use in calculating if two atoms are close enough for a VDW line to be displayed
        vdwLinesRatio = 1.67,

        // If a numeric value include gravitational field in force calculations,
        // otherwise value should be false
        gravitationalField = false,

        // Whether a transient temperature change is in progress.
        temperatureChangeInProgress = false,

        // Desired system temperature, in Kelvin.
        T_target,

        // Tolerance for (T_actual - T_target) relative to T_target
        tempTolerance = 0.001,

        // System dimensions as [x, y] in nanometers. Default value can be changed until particles are created.
        size = [10, 10],

        // Viscosity of the medium of the model
        viscosity,

        // The current model time, in femtoseconds.
        time = 0,

        // The current integration time step, in femtoseconds.
        dt,

        // Square of integration time step, in fs^2.
        dt_sq,

        // ####################################################################
        //                      Atom Properties

        // Individual property arrays for the atoms, indexed by atom number
        radius, px, py, x, y, vx, vy, speed, ax, ay, charge, element, friction, pinned, mass, hydrophobicity,
        // Helper array, which may be used by various engine routines traversing atoms in untypical order.
        // Make sure that you reset it before use. At the moment, it's used by updateAminoAcidForces() function.
        visited,

        // An object that contains references to the above atom-property arrays
        atoms,

        // The number of atoms in the system.
        N = 0,

        // ####################################################################
        //                      Element Properties

        // Individual property arrays for the elements
        elementMass,
        elementEpsilon,
        elementSigma,
        elementRadius,
        elementColor,

        // An object that contains references to the above element-property arrays
        elements,

        // Number of actual elements (may be smaller than the length of the property arrays).
        N_elements = 0,

        // Additional structure, keeping information if given element is represented by
        // some atom in the model. Necessary for effective max cut-off distance calculation.
        elementUsed = [],

        // ####################################################################
        //                      Custom Pairwise LJ Properties
        pairwiseLJProperties,

        // ####################################################################
        //                      Radial Bond Properties

        // Individual property arrays for the "radial" bonds, indexed by bond number
        radialBondAtom1Index,
        radialBondAtom2Index,
        radialBondLength,
        radialBondStrength,
        radialBondType,

        // An object that contains references to the above radial-bond-property arrays.
        // Left undefined if there are no radial bonds.
        radialBonds,

        // An array of individual radial bond index values and properties.
        // Each object contains all radial bond properties (atom1, atom2, length, strength, style)
        // and additionally (x,y) coordinates of bonded atoms defined as x1, y1, x2, y2 properties.
        radialBondResults,

        // radialBondMatrix[i][j] === true when atoms i and j are "radially bonded"
        // radialBondMatrix[i][j] === undefined otherwise
        radialBondMatrix,

        // Number of actual radial bonds (may be smaller than the length of the property arrays).
        N_radialBonds = 0,

        // ####################################################################
        //                      Restraint Properties

        // Individual property arrays for the "restraint" bonds, indexed by bond number.
        restraintAtomIndex,
        restraintK,
        restraintX0,
        restraintY0,

        // An object that contains references to the above restraint-property arrays.
        // Left undefined if there are no restraints.
        restraints,

        // Number of actual restraint bonds (may be smaller than the length of the property arrays).
        N_restraints = 0,

        // ####################################################################
        //                      Angular Bond Properties

        // Individual property arrays for the "angular" bonds, indexed by bond number.
        angularBondAtom1Index,
        angularBondAtom2Index,
        angularBondAtom3Index,
        angularBondAngle,
        angularBondStrength,

        // An object that contains references to the above angular-bond-property arrays.
        // Left undefined if there are no angular bonds.
        angularBonds,

        // Number of actual angular bonds (may be smaller than the length of the property arrays).
        N_angularBonds = 0,

        // ####################################################################
        //                      Obstacle Properties

        // Individual properties for the obstacles
        obstacleX,
        obstacleY,
        obstacleWidth,
        obstacleHeight,
        obstacleVX,
        obstacleVY,
        obstacleExtFX,
        obstacleExtFY,
        obstacleFriction,
        obstacleMass,
        obstacleWestProbe,
        obstacleNorthProbe,
        obstacleEastProbe,
        obstacleSouthProbe,
        obstacleColorR,
        obstacleColorG,
        obstacleColorB,
        obstacleVisible,

        // Properties used only during internal calculations (e.g. shouldn't
        // be returned during getObstacleProperties(i) call - TODO!).
        obstacleXPrev,
        obstacleYPrev,

        // ### Pressure calculation ###
        // Arrays containing sum of impulses 2mv/dt from atoms hitting the probe.
        // These values are later stored in pressureBuffers object, interpolated
        // (last average of last PRESSURE_BUFFERS_LEN values) and converted
        // to value in Bar by getPressureFromProbe() function.
        obstacleWProbeValue,
        obstacleNProbeValue,
        obstacleEProbeValue,
        obstacleSProbeValue,

        // An object that contains references to the above obstacle-property arrays.
        // Left undefined if there are no obstacles.
        obstacles,

        // Number of actual obstacles
        N_obstacles = 0,

        // ####################################################################
        geneticProperties,

        // ####################################################################
        //                      Misc Properties
        // Hash of arrays containing VdW pairs
        vdwPairs,

        // Number of VdW pairs
        N_vdwPairs,

        // Arrays of VdW pair atom #1 and atom #2 indices
        vdwPairAtom1Index,
        vdwPairAtom2Index,

        // Arrays for spring forces, which are forces defined between an atom and a point in space
        springForceAtomIndex,
        springForceX,
        springForceY,
        springForceStrength,

        // An array whose members are the above spring-force-property arrays
        springForces,

        // The number of spring forces currently being applied in the model.
        N_springForces = 0,

        // Cell list structure.
        cellList,

        // Neighbor (Verlet) list structure.
        neighborList,

        // Information whether neighbor list should be
        // recalculated in the current integration step.
        updateNeighborList,

        //
        // The location of the center of mass, in nanometers.
        x_CM, y_CM,

        // Linear momentum of the system, in Dalton * nm / fs.
        px_CM, py_CM,

        // Velocity of the center of mass, in nm / fs.
        vx_CM, vy_CM,

        // Angular momentum of the system wrt its center of mass
        L_CM,

        // (Instantaneous) moment of inertia of the system wrt its center of mass
        I_CM,

        // Angular velocity of the system about the center of mass, in radians / fs.
        // (= angular momentum about CM / instantaneous moment of inertia about CM)
        omega_CM,

        // instantaneous system temperature, in Kelvin
        T,

        // cutoff for force calculations, as a factor of sigma
        cutoff = 2,
        cutoffDistance_LJ_sq = [],

        // cutoff for neighbor list calculations, as a factor of sigma
        cutoffList = 2.5,
        cutoffNeighborListSquared = [],

        // Each object at ljCalculator[i,j] can calculate the magnitude of the Lennard-Jones force and
        // potential between elements i and j
        ljCalculator = [],

        // Optimization related variables:
        // Whether any atoms actually have charges
        hasChargedAtoms = false,

        // List of atoms with charge.
        chargedAtomsList = [],

        // List of particles representing cysteine amino acid, which can possibly create disulphide bonds.
        // So, each cysteine in this list is NOT already connected to other cysteine.
        freeCysteinesList = [],

        // Initializes basic data structures.
        initialize = function () {
          createElementsArray(0);
          createAtomsArray(0);
          createAngularBondsArray(0);
          createRadialBondsArray(0);
          createRestraintsArray(0);
          createVdwPairsArray(0);
          createSpringForcesArray(0);
          createObstaclesArray(0);

          // Custom pairwise properties.
          pairwiseLJProperties = new PairwiseLJProperties(engine);

          // Genetic properties (like DNA, mRNA etc.).
          geneticProperties = new GeneticProperties();

          radialBondMatrix = [];
          //  Initialize radialBondResults[] array consisting of hashes of radial bond
          //  index numbers and transposed radial bond properties.
          radialBondResults = engine.radialBondResults = [];
        },

        // Throws an informative error if a developer tries to use the setCoefficients method of an
        // in-use LJ calculator. (Hint: for an interactive LJ chart, create a new LJ calculator with
        // the desired coefficients; call setElementProperties to change the LJ properties in use.)
        ljCoefficientChangeError = function() {
          throw new Error("md2d: Don't change the epsilon or sigma parameters of the LJ calculator being used by MD2D. Use the setElementProperties method instead.");
        },

        // Initialize epsilon, sigma, cutoffDistance_LJ_sq, cutoffNeighborListSquared, and ljCalculator
        // array elements for element pair i and j
        setPairwiseLJProperties = function(i, j) {
          var epsilon_i   = elementEpsilon[i],
              epsilon_j   = elementEpsilon[j],
              sigma_i     = elementSigma[i],
              sigma_j     = elementSigma[j],
              customProps = pairwiseLJProperties.get(i, j),
              e,
              s;

          if (customProps && customProps.epsilon !== undefined) {
            e = customProps.epsilon;
          } else {
            e = lennardJones.pairwiseEpsilon(epsilon_i, epsilon_j);
          }

          if (customProps && customProps.sigma !== undefined) {
            s = customProps.sigma;
          } else {
            s = lennardJones.pairwiseSigma(sigma_i, sigma_j);
          }

          // Cutoff for Lennard-Jones interactions.
          cutoffDistance_LJ_sq[i][j] = cutoffDistance_LJ_sq[j][i] = (cutoff * s) * (cutoff * s);
          // Cutoff for neighbor lists calculations.
          cutoffNeighborListSquared[i][j] = cutoffNeighborListSquared[j][i] = (cutoffList * s) * (cutoffList * s);

          ljCalculator[i][j] = ljCalculator[j][i] = lennardJones.newLJCalculator({
            epsilon: e,
            sigma:   s
          }, ljCoefficientChangeError);
        },

        // Calculates maximal cut-off used in the current model. Functions checks all used
        // elements at the moment. When new atom is added, maximum cut-off distance should
        // be recalculated.
        computeMaxCutoff = function() {
          var maxCutoff = 0,
              customProps,
              sigma,
              i, j;

          for (i = 0; i < N_elements; i++) {
            for (j = 0; j <= i; j++) {
              if (elementUsed[i] && elementUsed[j]) {
                customProps = pairwiseLJProperties.get(i, j);
                if (customProps && customProps.sigma !== undefined) {
                  sigma = customProps.sigma;
                } else {
                  sigma = lennardJones.pairwiseSigma(elementSigma[i], elementSigma[j]);
                }
                // Use cutoffList, as cell lists are used to calculate neighbor lists.
                if (cutoffList * sigma > maxCutoff) {
                  maxCutoff = cutoffList * sigma;
                }
              }
            }
          }
          // If maxCutoff === 0, return size of the model
          // as a default cutoff distance for empty model.
          return maxCutoff || Math.max(size[0], size[1]);
        },

        // Returns a minimal difference between "real" cutoff
        // and cutoff used in neighbor list. This can be considered
        // as a minimal displacement of atom, which triggers neighbor
        // list recalculation (or maximal allowed displacement to avoid
        // recalculation).
        computeNeighborListMaxDisplacement = function() {
          var maxDisplacement = Infinity,
              customProps,
              sigma,
              i, j;

          for (i = 0; i < N_elements; i++) {
            for (j = 0; j <= i; j++) {
              if (elementUsed[i] && elementUsed[j]) {
                customProps = pairwiseLJProperties.get(i, j);
                if (customProps && customProps.sigma !== undefined) {
                  sigma = customProps.sigma;
                } else {
                  sigma = lennardJones.pairwiseSigma(elementSigma[i], elementSigma[j]);
                }

                if ((cutoffList - cutoff) * sigma < maxDisplacement) {
                  maxDisplacement = (cutoffList - cutoff) * sigma;
                }
              }
            }
          }
          return maxDisplacement;
        },

        // Initializes special structure for short-range forces calculation
        // optimization. Cell lists support neighbor list.
        initializeCellList = function () {
          if (cellList === undefined) {
            cellList = new CellList(size[0], size[1], computeMaxCutoff());
          } else {
            cellList.reinitialize(computeMaxCutoff());
          }
        },

        // Initializes special structure for short-range forces calculation
        // optimization. Neighbor list cooperates with cell list.
        initializeNeighborList = function () {
          if (neighborList === undefined) {
            neighborList = new NeighborList(N, computeNeighborListMaxDisplacement());
          } else {
            neighborList.reinitialize(N, computeNeighborListMaxDisplacement());
          }
        },

        // Calculates radial bond matrix using existing radial bonds.
        calculateRadialBondMatrix = function () {
          var i, atom1, atom2;

          radialBondMatrix = [];

          for (i = 0; i < N_radialBonds; i++) {
            atom1 = radialBondAtom1Index[i];
            atom2 = radialBondAtom2Index[i];
            radialBondMatrix[atom1] = radialBondMatrix[atom1] || [];
            radialBondMatrix[atom1][atom2] = true;
            radialBondMatrix[atom2] = radialBondMatrix[atom2] || [];
            radialBondMatrix[atom2][atom1] = true;
          }
        },

        /**
          Extend all arrays in arrayContainer to `newLength`. Here, arrayContainer is expected to be `atoms`
          `elements`, `radialBonds`, etc. arrayContainer might be an array or an object.
          TODO: this is just interim solution, in the future only objects will be expected.
        */
        extendArrays = function(arrayContainer, newLength) {
          var i, len;
          if (Array.isArray(arrayContainer)) {
            // Array of arrays.
            for (i = 0, len = arrayContainer.length; i < len; i++) {
              if (arrays.isArray(arrayContainer[i]))
                arrayContainer[i] = arrays.extend(arrayContainer[i], newLength);
            }
          } else {
            // Object with arrays defined as properties.
            for (i in arrayContainer) {
              if(arrayContainer.hasOwnProperty(i)) {
                if (arrays.isArray(arrayContainer[i]))
                  arrayContainer[i] = arrays.extend(arrayContainer[i], newLength);
              }
            }
          }
        },

        /**
          Set up "shortcut" references, e.g., x = atoms.x
        */
        assignShortcutReferences = {

          atoms: function() {
            radius         = atoms.radius;
            px             = atoms.px;
            py             = atoms.py;
            x              = atoms.x;
            y              = atoms.y;
            vx             = atoms.vx;
            vy             = atoms.vy;
            speed          = atoms.speed;
            ax             = atoms.ax;
            ay             = atoms.ay;
            charge         = atoms.charge;
            friction       = atoms.friction;
            element        = atoms.element;
            pinned         = atoms.pinned;
            mass           = atoms.mass;
            hydrophobicity = atoms.hydrophobicity;
            visited        = atoms.visited;
          },

          radialBonds: function() {
            radialBondAtom1Index  = radialBonds.atom1;
            radialBondAtom2Index  = radialBonds.atom2;
            radialBondLength      = radialBonds.length;
            radialBondStrength    = radialBonds.strength;
            radialBondType        = radialBonds.type;
          },

          restraints: function() {
            restraintAtomIndex  = restraints.atomIndex;
            restraintK          = restraints.k;
            restraintX0         = restraints.x0;
            restraintY0         = restraints.y0;
          },

          angularBonds: function() {
            angularBondAtom1Index  = angularBonds.atom1;
            angularBondAtom2Index  = angularBonds.atom2;
            angularBondAtom3Index  = angularBonds.atom3;
            angularBondAngle       = angularBonds.angle;
            angularBondStrength    = angularBonds.strength;
          },

          elements: function() {
            elementMass    = elements.mass;
            elementEpsilon = elements.epsilon;
            elementSigma   = elements.sigma;
            elementRadius  = elements.radius;
            elementColor   = elements.color;
          },

          obstacles: function() {
            obstacleX           = obstacles.x;
            obstacleY           = obstacles.y;
            obstacleWidth       = obstacles.width;
            obstacleHeight      = obstacles.height;
            obstacleMass        = obstacles.mass;
            obstacleVX          = obstacles.vx;
            obstacleVY          = obstacles.vy;
            obstacleExtFX       = obstacles.externalFx;
            obstacleExtFY       = obstacles.externalFy;
            obstacleFriction    = obstacles.friction;
            obstacleWestProbe   = obstacles.westProbe;
            obstacleNorthProbe  = obstacles.northProbe;
            obstacleEastProbe   = obstacles.eastProbe;
            obstacleSouthProbe  = obstacles.southProbe;
            obstacleWProbeValue = obstacles.westProbeValue;
            obstacleNProbeValue = obstacles.northProbeValue;
            obstacleEProbeValue = obstacles.eastProbeValue;
            obstacleSProbeValue = obstacles.southProbeValue;
            obstacleXPrev       = obstacles.xPrev;
            obstacleYPrev       = obstacles.yPrev;
            obstacleColorR      = obstacles.colorR;
            obstacleColorG      = obstacles.colorG;
            obstacleColorB      = obstacles.colorB;
            obstacleVisible     = obstacles.visible;
          },

          springForces: function() {
            springForceAtomIndex = springForces[0];
            springForceX         = springForces[1];
            springForceY         = springForces[2];
            springForceStrength  = springForces[3];
          },

          vdwPairs: function () {
            vdwPairAtom1Index = vdwPairs.atom1;
            vdwPairAtom2Index = vdwPairs.atom2;
          }

        },

        createElementsArray = function(num) {
          elements = engine.elements = {};

          elements.mass    = arrays.create(num, 0, arrayTypes.float);
          elements.epsilon = arrays.create(num, 0, arrayTypes.float);
          elements.sigma   = arrays.create(num, 0, arrayTypes.float);
          elements.radius  = arrays.create(num, 0, arrayTypes.float);
          elements.color   = arrays.create(num, 0, arrayTypes.Int32Array);

          assignShortcutReferences.elements();
        },

        createAtomsArray = function(num) {
          atoms  = engine.atoms  = {};

          // TODO. DRY this up by letting the property list say what type each array is
          atoms.radius         = arrays.create(num, 0, arrayTypes.float);
          atoms.px             = arrays.create(num, 0, arrayTypes.float);
          atoms.py             = arrays.create(num, 0, arrayTypes.float);
          atoms.x              = arrays.create(num, 0, arrayTypes.float);
          atoms.y              = arrays.create(num, 0, arrayTypes.float);
          atoms.vx             = arrays.create(num, 0, arrayTypes.float);
          atoms.vy             = arrays.create(num, 0, arrayTypes.float);
          atoms.speed          = arrays.create(num, 0, arrayTypes.float);
          atoms.ax             = arrays.create(num, 0, arrayTypes.float);
          atoms.ay             = arrays.create(num, 0, arrayTypes.float);
          atoms.charge         = arrays.create(num, 0, arrayTypes.float);
          atoms.friction       = arrays.create(num, 0, arrayTypes.float);
          atoms.element        = arrays.create(num, 0, arrayTypes.uint8);
          atoms.pinned         = arrays.create(num, 0, arrayTypes.uint8);
          atoms.mass           = arrays.create(num, 0, arrayTypes.float);
          atoms.hydrophobicity = arrays.create(num, 0, arrayTypes.int8);
          atoms.visited        = arrays.create(num, 0, arrayTypes.uint8);
          // For the sake of clarity, manage all atoms properties in one
          // place (engine). In the future, think about separation of engine
          // properties and view-oriented properties like these:
          atoms.marked         = arrays.create(num, 0, arrayTypes.uint8);
          atoms.visible        = arrays.create(num, 0, arrayTypes.uint8);
          atoms.draggable      = arrays.create(num, 0, arrayTypes.uint8);

          assignShortcutReferences.atoms();
        },

        createRadialBondsArray = function(num) {
          radialBonds = engine.radialBonds = {};

          radialBonds.atom1    = arrays.create(num, 0, arrayTypes.uint16);
          radialBonds.atom2    = arrays.create(num, 0, arrayTypes.uint16);
          radialBonds.length   = arrays.create(num, 0, arrayTypes.float);
          radialBonds.strength = arrays.create(num, 0, arrayTypes.float);
          radialBonds.type     = arrays.create(num, 0, arrayTypes.uint8);

          assignShortcutReferences.radialBonds();
        },

        createRestraintsArray = function(num) {
          restraints = engine.restraints = {};

          restraints.atomIndex = arrays.create(num, 0, arrayTypes.uint16);
          restraints.k         = arrays.create(num, 0, arrayTypes.float);
          restraints.x0        = arrays.create(num, 0, arrayTypes.float);
          restraints.y0        = arrays.create(num, 0, arrayTypes.float);

          assignShortcutReferences.restraints();
        },

        createAngularBondsArray = function(num) {
          angularBonds = engine.angularBonds = {};

          angularBonds.atom1    = arrays.create(num, 0, arrayTypes.uint16);
          angularBonds.atom2    = arrays.create(num, 0, arrayTypes.uint16);
          angularBonds.atom3    = arrays.create(num, 0, arrayTypes.uint16);
          angularBonds.angle    = arrays.create(num, 0, arrayTypes.float);
          angularBonds.strength = arrays.create(num, 0, arrayTypes.float);

          assignShortcutReferences.angularBonds();
        },

        createVdwPairsArray = function(num) {
          vdwPairs = engine.vdwPairs = {};

          vdwPairs.count = 0;
          vdwPairs.atom1 = arrays.create(num, 0, arrayTypes.uint16);
          vdwPairs.atom2 = arrays.create(num, 0, arrayTypes.uint16);
        },

        createSpringForcesArray = function(num) {
          springForces = engine.springForces = [];

          // TODO: not very descriptive. Use hash of arrays like elsewhere.
          springForces[0] = arrays.create(num, 0, arrayTypes.uint16);
          springForces[1] = arrays.create(num, 0, arrayTypes.float);
          springForces[2] = arrays.create(num, 0, arrayTypes.float);
          springForces[3] = arrays.create(num, 0, arrayTypes.float);

          assignShortcutReferences.springForces();
        },

        createObstaclesArray = function(num) {
          obstacles = engine.obstacles = {};

          obstacles.x           = arrays.create(num, 0, arrayTypes.float);
          obstacles.y           = arrays.create(num, 0, arrayTypes.float);
          obstacles.width       = arrays.create(num, 0, arrayTypes.float);
          obstacles.height      = arrays.create(num, 0, arrayTypes.float);
          obstacles.mass        = arrays.create(num, 0, arrayTypes.float);
          obstacles.vx          = arrays.create(num, 0, arrayTypes.float);
          obstacles.vy          = arrays.create(num, 0, arrayTypes.float);
          obstacles.externalFx  = arrays.create(num, 0, arrayTypes.float);
          obstacles.externalFy  = arrays.create(num, 0, arrayTypes.float);
          obstacles.friction    = arrays.create(num, 0, arrayTypes.float);
          obstacles.westProbe   = arrays.create(num, 0, arrayTypes.uint8);
          obstacles.northProbe  = arrays.create(num, 0, arrayTypes.uint8);
          obstacles.eastProbe   = arrays.create(num, 0, arrayTypes.uint8);
          obstacles.southProbe  = arrays.create(num, 0, arrayTypes.uint8);
          obstacles.westProbeValue = arrays.create(num, 0, arrayTypes.float);
          obstacles.northProbeValue = arrays.create(num, 0, arrayTypes.float);
          obstacles.eastProbeValue = arrays.create(num, 0, arrayTypes.float);
          obstacles.southProbeValue = arrays.create(num, 0, arrayTypes.float);
          obstacles.xPrev       = arrays.create(num, 0, arrayTypes.float);
          obstacles.yPrev       = arrays.create(num, 0, arrayTypes.float);
          obstacles.colorR      = arrays.create(num, 0, arrayTypes.float);
          obstacles.colorG      = arrays.create(num, 0, arrayTypes.float);
          obstacles.colorB      = arrays.create(num, 0, arrayTypes.float);
          obstacles.visible     = arrays.create(num, 0, arrayTypes.uint8);

          assignShortcutReferences.obstacles();
        },

        // Function that accepts a value T and returns an average of the last n values of T (for some n).
        getTWindowed,

        // Dynamically determine an appropriate window size for use when measuring a windowed average of the temperature.
        getWindowSize = function() {
          return useCoulombInteraction && hasChargedAtoms ? 1000 : 1000;
        },

        // Whether or not the thermostat is not being used, begins transiently adjusting the system temperature; this
        // causes the adjustTemperature portion of the integration loop to rescale velocities until a windowed average of
        // the temperature comes within `tempTolerance` of `T_target`.
        beginTransientTemperatureChange = function()  {
          temperatureChangeInProgress = true;
          getTWindowed = math.getWindowedAverager( getWindowSize() );
        },

        // Calculates & returns instantaneous temperature of the system.
        computeTemperature = function() {
          var twoKE = 0,
              i;

          // Particles.
          for (i = 0; i < N; i++) {
            twoKE += mass[i] * (vx[i] * vx[i] + vy[i] * vy[i]);
          }
          // Obstacles.
          for (i = 0; i < N_obstacles; i++) {
            if (obstacleMass[i] !== Infinity) {
              twoKE += obstacleMass[i] *
                  (obstacleVX[i] * obstacleVX[i] + obstacleVY[i] * obstacleVY[i]);
            }
          }

          return convertKEtoT(twoKE / 2, N);
        },

        // Adds the velocity vector (vx_t, vy_t) to the velocity vector of particle i
        addVelocity = function(i, vx_t, vy_t) {
          vx[i] += vx_t;
          vy[i] += vy_t;

          px[i] = vx[i]*mass[i];
          py[i] = vy[i]*mass[i];
        },

        // Adds effect of angular velocity omega, relative to (x_CM, y_CM), to the velocity vector of particle i
        addAngularVelocity = function(i, omega) {
          vx[i] -= omega * (y[i] - y_CM);
          vy[i] += omega * (x[i] - x_CM);

          px[i] = vx[i]*mass[i];
          py[i] = vy[i]*mass[i];
        },

        // Subtracts the center-of-mass linear velocity and the system angular velocity from the velocity vectors
        removeTranslationAndRotationFromVelocities = function() {
          for (var i = 0; i < N; i++) {
            addVelocity(i, -vx_CM, -vy_CM);
            addAngularVelocity(i, -omega_CM);
          }
        },

        // currently unused, implementation saved here for future reference:

        // // Adds the center-of-mass linear velocity and the system angular velocity back into the velocity vectors
        // addTranslationAndRotationToVelocities = function() {
        //   for (var i = 0; i < N; i++) {
        //     addVelocity(i, vx_CM, vy_CM);
        //     addAngularVelocity(i, omega_CM);
        //   }
        // },

        // Subroutine that calculates the position and velocity of the center of mass, leaving these in x_CM, y_CM,
        // vx_CM, and vy_CM, and that then computes the system angular velocity around the center of mass, leaving it
        // in omega_CM.
        computeSystemTranslation = function() {
          var x_sum = 0,
              y_sum = 0,
              px_sum = 0,
              py_sum = 0,
              totalMass = engine.getTotalMass(),
              i;

          for (i = 0; i < N; i++) {
            x_sum += x[i];
            y_sum += y[i];
            px_sum += px[i];
            py_sum += py[i];
          }

          x_CM = x_sum / N;
          y_CM = y_sum / N;
          px_CM = px_sum;
          py_CM = py_sum;
          vx_CM = px_sum / totalMass;
          vy_CM = py_sum / totalMass;
        },

        // Subroutine that calculates the angular momentum and moment of inertia around the center of mass, and then
        // uses these to calculate the weighted angular velocity around the center of mass.
        // Updates I_CM, L_CM, and omega_CM.
        // Requires x_CM, y_CM, vx_CM, vy_CM to have been calculated.
        computeSystemRotation = function() {
          var L = 0,
              I = 0,
              m,
              i;

          for (i = 0; i < N; i++) {
            m = mass[i];
            // L_CM = sum over N of of mr_i x p_i (where r_i and p_i are position & momentum vectors relative to the CM)
            L += m * cross( x[i]-x_CM, y[i]-y_CM, vx[i]-vx_CM, vy[i]-vy_CM);
            I += m * sumSquare( x[i]-x_CM, y[i]-y_CM );
          }

          L_CM = L;
          I_CM = I;
          omega_CM = L_CM / I_CM;
        },

        computeCMMotion = function() {
          computeSystemTranslation();
          computeSystemRotation();
        },

        // ####################################################################
        // #              Functions handling different collisions.            #
        // ####################################################################

        // Constrain obstacle i to the area between the walls by simulating perfectly elastic collisions with the walls.
        bounceObstacleOffWalls = function(i) {
          var leftwall   = 0,
              bottomwall = 0,
              width  = size[0],
              height = size[1],
              rightwall = width - obstacleWidth[i],
              topwall   = height - obstacleHeight[i];

          // Bounce off vertical walls.
          if (obstacleX[i] < leftwall) {
            while (obstacleX[i] < leftwall - width) {
              obstacleX[i] += width;
            }
            obstacleX[i]  = leftwall + (leftwall - obstacleX[i]);
            obstacleVX[i] *= -1;
          } else if (obstacleX[i] > rightwall) {
            while (obstacleX[i] > rightwall + width) {
              obstacleX[i] -= width;
            }
            obstacleX[i]  = rightwall - (obstacleX[i] - rightwall);
            obstacleVX[i] *= -1;
          }

          // Bounce off horizontal walls.
          if (obstacleY[i] < bottomwall) {
            while (obstacleY[i] < bottomwall - height) {
              obstacleY[i] += height;
            }
            obstacleY[i]  = bottomwall + (bottomwall - obstacleY[i]);
            obstacleVY[i] *= -1;
          } else if (obstacleY[i] > topwall) {
            while (obstacleY[i] > topwall + width) {
              obstacleY[i] -= width;
            }
            obstacleY[i]  = topwall - (obstacleY[i] - topwall);
            obstacleVY[i] *= -1;
          }
        },

        // Constrain particle i to the area between the walls by simulating perfectly elastic collisions with the walls.
        // Note this may change the linear and angular momentum.
        bounceParticleOffWalls = function(i) {
          var r = radius[i],
              leftwall = r,
              bottomwall = r,
              width = size[0],
              height = size[1],
              rightwall = width - r,
              topwall = height - r;

          // Bounce off vertical walls.
          if (x[i] < leftwall) {
            while (x[i] < leftwall - width) {
              x[i] += width;
            }
            x[i]  = leftwall + (leftwall - x[i]);
            vx[i] *= -1;
            px[i] *= -1;
          } else if (x[i] > rightwall) {
            while (x[i] > rightwall + width) {
              x[i] -= width;
            }
            x[i]  = rightwall - (x[i] - rightwall);
            vx[i] *= -1;
            px[i] *= -1;
          }

          // Bounce off horizontal walls
          if (y[i] < bottomwall) {
            while (y[i] < bottomwall - height) {
              y[i] += height;
            }
            y[i]  = bottomwall + (bottomwall - y[i]);
            vy[i] *= -1;
            py[i] *= -1;
          } else if (y[i] > topwall) {
            while (y[i] > topwall + height) {
              y[i] -= height;
            }
            y[i]  = topwall - (y[i] - topwall);
            vy[i] *= -1;
            py[i] *= -1;
          }
        },

        bounceParticleOffObstacles = function(i, x_prev, y_prev, updatePressure) {
          // fast path if no obstacles
          if (N_obstacles < 1) return;

          var r,
              xi,
              yi,

              j,

              x_left,
              x_right,
              y_top,
              y_bottom,
              x_left_prev,
              x_right_prev,
              y_top_prev,
              y_bottom_prev,
              vxPrev,
              vyPrev,
              obs_vxPrev,
              obs_vyPrev,
              atom_mass,
              obs_mass,
              totalMass,
              bounceDirection;

          r = radius[i];
          xi = x[i];
          yi = y[i];

          for (j = 0; j < N_obstacles; j++) {

            x_left = obstacleX[j] - r;
            x_right = obstacleX[j] + obstacleWidth[j] + r;
            y_top = obstacleY[j] + obstacleHeight[j] + r;
            y_bottom = obstacleY[j] - r;

            x_left_prev = obstacleXPrev[j] - r;
            x_right_prev = obstacleXPrev[j] + obstacleWidth[j] + r;
            y_top_prev = obstacleYPrev[j] + obstacleHeight[j] + r;
            y_bottom_prev = obstacleYPrev[j] - r;

            // Reset bounceDirection, which indicates collision type.
            bounceDirection = 0;
            // Check all possibilities for a collision with the rectangular obstacle.
            if (xi > x_left && xi < x_right && yi > y_bottom && yi < y_top) {
              if (x_prev <= x_left_prev) {
                x[i] = x_left - (xi - x_left);
                bounceDirection = 1; // West wall collision.
              } else if (x_prev >= x_right_prev) {
                x[i] = x_right + (x_right - xi);
                bounceDirection = 2; // East wall collision.
              } else if (y_prev <= y_bottom_prev) {
                y[i] = y_bottom - (yi - y_bottom);
                bounceDirection = -1; // South wall collision.
              } else if (y_prev >= y_top_prev) {
                y[i] = y_top  + (y_top - yi);
                bounceDirection = -2; // North wall collision.
              }
            }

            obs_mass = obstacleMass[j];

            if (bounceDirection !== 0) {
              if (obs_mass !== Infinity) {
                // if we have real mass, perform a perfectly-elastic collision
                atom_mass = mass[i];
                totalMass = obs_mass + atom_mass;
                if (bounceDirection > 0) {
                  vxPrev = vx[i];
                  obs_vxPrev = obstacleVX[j];

                  vx[i] = (vxPrev * (atom_mass - obs_mass) + (2 * obs_mass * obs_vxPrev)) / totalMass;
                  obstacleVX[j] = (obs_vxPrev * (obs_mass - atom_mass) + (2 * px[i])) / totalMass;
                } else {
                  vyPrev = vy[i];
                  obs_vyPrev = obstacleVY[j];

                  vy[i] = (vyPrev * (atom_mass - obs_mass) + (2 * obs_mass * obs_vyPrev)) / totalMass;
                  obstacleVY[j] = (obs_vyPrev * (obs_mass - atom_mass) + (2 * py[i])) / totalMass;
                }
              } else {
                // if we have infinite mass, just reflect (like a wall)
                if (bounceDirection > 0) {
                  vx[i] *= -1;
                } else {
                  vy[i] *= -1;
                }
              }

              if (updatePressure) {
                // Update pressure probes if there are any.
                if (obstacleWestProbe[j] && bounceDirection === 1) {
                  // 1 is west wall collision.
                  obstacleWProbeValue[j] += mass[i] * ((vxPrev ? vxPrev : -vx[i]) - vx[i]);
                } else if (obstacleEastProbe[j] && bounceDirection === 2) {
                  // 2 is west east collision.
                  obstacleEProbeValue[j] += mass[i] * (vx[i] - (vxPrev ? vxPrev : -vx[i]));
                } else if (obstacleSouthProbe[j] && bounceDirection === -1) {
                  // -1 is south wall collision.
                  obstacleSProbeValue[j] += mass[i] * ((vyPrev ? vyPrev : -vy[i]) - vy[i]);
                } else if (obstacleNorthProbe[j] && bounceDirection === -2) {
                  // -2 is north wall collision.
                  obstacleNProbeValue[j] += mass[i] * (vy[i] - (vyPrev ? vyPrev : -vy[i]));
                }
              }

            }
          }
        },

        // ####################################################################
        // #         Functions calculating forces and accelerations.          #
        // ####################################################################

        // Calculate distance and force (if distance < cut-off distance).
        calculateLJInteraction = function(i, j) {
          // Fast path.
          if (radialBondMatrix && radialBondMatrix[i] && radialBondMatrix[i][j]) return;

          var elI = element[i],
              elJ = element[j],
              dx  = x[j] - x[i],
              dy  = y[j] - y[i],
              rSq = dx * dx + dy * dy,
              fOverR, fx, fy;

          if (updateNeighborList && rSq < cutoffNeighborListSquared[elI][elJ]) {
            neighborList.markNeighbors(i, j);
          }

          if (rSq < cutoffDistance_LJ_sq[elI][elJ]) {
            fOverR = ljCalculator[elI][elJ].forceOverDistanceFromSquaredDistance(rSq);
            fx = fOverR * dx;
            fy = fOverR * dy;
            ax[i] += fx;
            ay[i] += fy;
            ax[j] -= fx;
            ay[j] -= fy;
          }
        },

        updateShortRangeForces = function () {
          // Fast path if Lennard Jones interaction is disabled.
          if (!useLennardJonesInteraction) return;

          if (updateNeighborList) {
            console.time('cell lists');
            shortRangeForcesCellList();
            console.timeEnd('cell lists');
          } else {
            console.time('neighbor list');
            shortRangeForcesNeighborList();
            console.timeEnd('neighbor list');
          }
        },

        shortRangeForcesCellList = function () {
          var rows = cellList.getRowsNum(),
              cols = cellList.getColsNum(),
              i, j, temp, cellIdx, cell1, cell2,
              a, b, atom1Idx, cell1Len, cell2Len,
              n, nLen, cellNeighbors;

          for (i = 0; i < rows; i++) {
            temp = i * cols;
            for (j = 0; j < cols; j++) {
              cellIdx = temp + j;

              cell1 = cellList.getCell(cellIdx);
              cellNeighbors = cellList.getNeighboringCells(i, j);

              for (a = 0, cell1Len = cell1.length; a < cell1Len; a++) {
                atom1Idx = cell1[a];

                // Interactions inside the cell.
                for (b = 0; b < a; b++) {
                  calculateLJInteraction(atom1Idx, cell1[b]);
                }
                // Interactions between neighboring cells.
                for (n = 0, nLen = cellNeighbors.length; n < nLen; n++) {
                  cell2 = cellNeighbors[n];
                  for (b = 0, cell2Len = cell2.length; b < cell2Len; b++) {
                    calculateLJInteraction(atom1Idx, cell2[b]);
                  }
                }
              }
            }
          }
        },

        shortRangeForcesNeighborList = function () {
          var nlist = neighborList.getList(),
              atom1Idx, atom2Idx, i, len;

          for (atom1Idx = 0; atom1Idx < N; atom1Idx++) {
            for (i = neighborList.getStartIdxFor(atom1Idx), len = neighborList.getEndIdxFor(atom1Idx); i < len; i++) {
              atom2Idx = nlist[i];
              calculateLJInteraction(atom1Idx, atom2Idx);
            }
          }
        },

        updateLongRangeForces = function() {
          // Fast path if Coulomb interaction is disabled or there are no charged atoms.
          if (!useCoulombInteraction || !hasChargedAtoms) return;

          var i, j, len, dx, dy, rSq, fOverR, fx, fy,
              charge1, atom1Idx, atom2Idx,
              bondingPartners;

          for (i = 0, len = chargedAtomsList.length; i < len; i++) {
            atom1Idx = chargedAtomsList[i];
            charge1 = charge[atom1Idx];
            bondingPartners = radialBondMatrix && radialBondMatrix[atom1Idx];
            for (j = 0; j < i; j++) {
              atom2Idx = chargedAtomsList[j];
              if (bondingPartners && bondingPartners[atom2Idx]) continue;

              dx = x[atom2Idx] - x[atom1Idx];
              dy = y[atom2Idx] - y[atom1Idx];
              rSq = dx*dx + dy*dy;

              fOverR = coulomb.forceOverDistanceFromSquaredDistance(rSq, charge1, charge[atom2Idx],
                dielectricConst, realisticDielectricEffect);

              fx = fOverR * dx;
              fy = fOverR * dy;
              ax[atom1Idx] += fx;
              ay[atom1Idx] += fy;
              ax[atom2Idx] -= fx;
              ay[atom2Idx] -= fy;
            }
          }
        },

        updateFrictionForces = function() {
          if (!viscosity) return;

          var i,
              drag;

          for (i = 0; i < N; i++) {
            drag = viscosity * friction[i];

            ax[i] += (-vx[i] * drag);
            ay[i] += (-vy[i] * drag);
          }
        },

        updateRadialBondForces = function() {
          // fast path if no radial bonds have been defined
          if (N_radialBonds < 1) return;

          var i, i1, i2, dx, dy,
              rSq, r, k, r0,
              fOverR, fx, fy;

          for (i = 0; i < N_radialBonds; i++) {
            i1 = radialBondAtom1Index[i];
            i2 = radialBondAtom2Index[i];

            dx = x[i2] - x[i1];
            dy = y[i2] - y[i1];
            rSq = dx*dx + dy*dy;
            r = Math.sqrt(rSq);

            // eV/nm^2
            k = radialBondStrength[i];

            // nm
            r0 = radialBondLength[i];

            // "natural" Next Gen MW force units / nm
            fOverR = constants.convert(k*(r-r0), { from: unit.EV_PER_NM, to: unit.MW_FORCE_UNIT }) / r;

            fx = fOverR * dx;
            fy = fOverR * dy;

            ax[i1] += fx;
            ay[i1] += fy;
            ax[i2] -= fx;
            ay[i2] -= fy;
          }
        },

        updateAngularBondForces = function() {
          // Fast path if no angular bonds have been defined.
          if (N_angularBonds < 1) return;

          var i, i1, i2, i3,
              dxij, dyij, dxkj, dykj, rijSquared, rkjSquared, rij, rkj,
              k, angle, theta, cosTheta, sinTheta,
              forceInXForI, forceInYForI, forceInXForK, forceInYForK,
              commonPrefactor, temp;

          for (i = 0; i < N_angularBonds; i++) {
            i1 = angularBondAtom1Index[i];
            i2 = angularBondAtom2Index[i];
            i3 = angularBondAtom3Index[i];

            // radian
            angle = angularBondAngle[i];

            // eV/radian^2
            k = angularBondStrength[i];

            // Calculate angle (theta) between two vectors:
            // Atom1-Atom3 and Atom2-Atom3
            // Atom1 -> i, Atom2 -> k, Atom3 -> j
            dxij = x[i1] - x[i3];
            dxkj = x[i2] - x[i3];
            dyij = y[i1] - y[i3];
            dykj = y[i2] - y[i3];
            rijSquared = dxij * dxij + dyij * dyij;
            rkjSquared = dxkj * dxkj + dykj * dykj;
            rij = Math.sqrt(rijSquared);
            rkj = Math.sqrt(rkjSquared);
            // Calculate cos using dot product definition.
            cosTheta = (dxij * dxkj + dyij * dykj) / (rij * rkj);
            if (cosTheta > 1.0) cosTheta = 1.0;
            else if (cosTheta < -1.0) cosTheta = -1.0;
            // Pythagorean trigonometric identity.
            sinTheta = Math.sqrt(1.0 - cosTheta * cosTheta);
            // Finally:
            theta = Math.acos(cosTheta);

            if (sinTheta < 0.0001) sinTheta = 0.0001;

            // Calculate force.
            // "natural" Next Gen MW force units / nm
            commonPrefactor = constants.convert(k * (theta - angle) / (sinTheta * rij),
                { from: unit.EV_PER_NM, to: unit.MW_FORCE_UNIT }) / rkj;

            // nm^2
            temp = dxij * dxkj + dyij * dykj;
            // Terms in brackets end up with nm unit.
            // commonPrefactor is in "natural" Next Gen MW force units / nm,
            // so everything is correct.
            forceInXForI = commonPrefactor * (dxkj - temp * dxij / rijSquared);
            forceInYForI = commonPrefactor * (dykj - temp * dyij / rijSquared);
            forceInXForK = commonPrefactor * (dxij - temp * dxkj / rkjSquared);
            forceInYForK = commonPrefactor * (dyij - temp * dykj / rkjSquared);

            ax[i1] += forceInXForI;
            ay[i1] += forceInYForI;
            ax[i2] += forceInXForK;
            ay[i2] += forceInYForK;
            ax[i3] -= (forceInXForI + forceInXForK);
            ay[i3] -= (forceInYForI + forceInYForK);
          }
        },

        // FIXME: eliminate duplication with springForces
        updateRestraintForces = function() {
          // fast path if no restraints have been defined
          if (N_restraints < 1) return;

          var i,
              dx, dy,
              r, r_sq,
              k,
              f_over_r,
              fx, fy,
              a;

          for (i = 0; i < N_restraints; i++) {
            a = restraintAtomIndex[i];

            dx = restraintX0[i] - x[a];
            dy = restraintY0[i] - y[a];

            if (dx === 0 && dy === 0) continue;   // force will be zero

            r_sq = dx*dx + dy*dy;
            r = Math.sqrt(r_sq);

            // eV/nm^2
            k = restraintK[i];

            f_over_r = constants.convert(k*r, { from: unit.EV_PER_NM, to: unit.MW_FORCE_UNIT }) / r;

            fx = f_over_r * dx;
            fy = f_over_r * dy;

            ax[a] += fx;
            ay[a] += fy;
          }
        },

        updateSpringForces = function() {
          if (N_springForces < 1) return;

          var i,
              dx, dy,
              r, r_sq,
              k,
              f_over_r,
              fx, fy,
              a;

          for (i = 0; i < N_springForces; i++) {
            a = springForceAtomIndex[i];

            dx = springForceX[i] - x[a];
            dy = springForceY[i] - y[a];

            if (dx === 0 && dy === 0) continue;   // force will be zero

            r_sq = dx*dx + dy*dy;
            r = Math.sqrt(r_sq);

            // eV/nm^2
            k = springForceStrength[i];

            f_over_r = constants.convert(k*r, { from: unit.EV_PER_NM, to: unit.MW_FORCE_UNIT }) / r;

            fx = f_over_r * dx;
            fy = f_over_r * dy;

            ax[a] += fx;
            ay[a] += fy;
          }
        },

        // Returns center of mass of given atoms set (molecule).
        getMoleculeCenterOfMass = function (molecule) {
          var xcm = 0,
              ycm = 0,
              totalMass = 0,
              atomIdx, atomMass, i, len;

          for (i = 0, len = molecule.length; i < len; i++) {
            atomIdx = molecule[i];
            atomMass = mass[atomIdx];
            xcm += x[atomIdx] * atomMass;
            ycm += y[atomIdx] * atomMass;
            totalMass += atomMass;
          }
          xcm /= totalMass;
          ycm /= totalMass;
          return {x: xcm, y: ycm};
        },

        updateAminoAcidForces = function () {
          // Fast path if there is no solvent defined or it doesn't have impact on AAs.
          if (solventForceType === 0 || solventForceFactor === 0 || N < 2) return;

          var moleculeAtoms, atomIdx, cm, solventFactor,
              dx, dy, r, fx, fy, temp, i, j, len;

          // Reset helper array.
          for (i = 0; i < N; i++) {
            visited[i] = 0;
          }

          // Set multiplier of force produced by the solvent.
          // Constants used in Classic MW: 5 * 0.00001 = 0.00005.
          // Multiply it by 0.01 * 120 = 1.2 to convert from
          // 0.1A * 120amu / fs^2 to nm * amu / fs^2.
          // solventForceType is the same like in Classic MW (unitless).
          // solventForceFactor is a new variable used only in Next Gen MW.
          solventFactor = 0.00006 * solventForceType * solventForceFactor;

          for (i = 0; i < N; i++) {
            // Calculate forces only *once* for amino acid.
            if (visited[i] === 1) continue;

            moleculeAtoms = engine.getMoleculeAtoms(i);
            moleculeAtoms.push(i);

            cm = getMoleculeCenterOfMass(moleculeAtoms);

            for (j = 0, len = moleculeAtoms.length; j < len; j++) {
              atomIdx = moleculeAtoms[j];
              // Mark that atom was part of processed molecule to avoid
              // calculating its molecule again.
              visited[atomIdx] = 1;

              if (hydrophobicity[atomIdx] !== 0) {
                dx = x[atomIdx] - cm.x;
                dy = y[atomIdx] - cm.y;
                r = Math.sqrt(dx * dx + dy * dy);

                temp = hydrophobicity[atomIdx] * solventFactor;

                // AAs being pulled into the center of mass should feel an additional force factor that depends
                // on distance from the center of mass, ranging between 1 and 25, with 1 being furthest away from the CoM
                // and 25 being the max when at the CoM or within a certain radius of the CoM. In some ways this
                // is closer to nature as the core of a protein is less exposed to solvent and thus even more stable.
                if (temp > 0 && r < additionalSolventForceThreshold) {
                  // Force towards the center of mass, distance from the CoM less than a given threshold.
                  // Multiply force by an additional factor defined by the linear function of 'r' defined by two points:
                  // (0, additionalSolventForceMult) and (additionalSolventForceThreshold, 1).
                  temp *= (1 - additionalSolventForceMult) * r / additionalSolventForceThreshold + additionalSolventForceMult;
                }

                fx = temp * dx / r;
                fy = temp * dy / r;
                ax[atomIdx] -= fx;
                ay[atomIdx] -= fy;
              }
            }
          }
        },

        updateGravitationalAccelerations = function() {
          // fast path if there is no gravitationalField
          if (!gravitationalField) return;
          var i;

          for (i = 0; i < N; i++) {
            ay[i] -= gravitationalField;
          }
        },

        // ####################################################################
        // #               Integration main helper functions.                 #
        // ####################################################################

        // For now, calculate only structures used by proteins engine.
        // TODO: move there calculation of various optimization structures like chargedAtomLists.
        calculateOptimizationStructures = function () {
          var cysteineEl = aminoacidsHelper.cysteineElement,
              idx, i;

          // Reset optimization data structure.
          freeCysteinesList.length = 0;

          for (i = 0; i < N; i++) {
            if (element[i] === cysteineEl) {
              // At the beginning, assume that each cysteine is "free" (ready to create disulfide bond).
              freeCysteinesList.push(i);
            }
          }

          for (i = 0; i < N_radialBonds; i++) {
            if (element[radialBondAtom1Index[i]] === cysteineEl && element[radialBondAtom2Index[i]] === cysteineEl) {
              // Two cysteines are already bonded, so remove them from freeCysteinsList.
              idx = freeCysteinesList.indexOf(radialBondAtom1Index[i]);
              if (idx !== -1) arrays.remove(freeCysteinesList, idx);
              idx = freeCysteinesList.indexOf(radialBondAtom2Index[i]);
              if (idx !== -1) arrays.remove(freeCysteinesList, idx);
            }
          }
        },

        // Accumulate acceleration into a(t + dt) from all possible interactions, fields
        // and forces connected with atoms.
        updateParticlesAccelerations = function () {
          var i, inverseMass;

          if (N === 0) return;

          // Zero out a(t) for accumulation of forces into a(t + dt).
          for (i = 0; i < N; i++) {
            ax[i] = ay[i] = 0;
          }

          // Check if the neighbor list should be recalculated.
          updateNeighborList = neighborList.shouldUpdate(x, y);

          if (updateNeighborList) {
            // Clear both lists.
            cellList.clear();
            neighborList.clear();

            for (i = 0; i < N; i++) {
              // Add particle to appropriate cell.
              cellList.addToCell(i, x[i], y[i]);
              // And save its initial position
              // ("initial" = position during neighbor list creation).
              neighborList.saveAtomPosition(i, x[i], y[i]);
            }
          }

          // ######################################
          // ax and ay are FORCES below this point
          // ######################################

          // Accumulate forces into a(t + dt) for all pairwise interactions between
          // particles:
          // Short-range forces (Lennard-Jones interaction).
          console.time('short-range forces');
          updateShortRangeForces();
          console.timeEnd('short-range forces');
          // Long-range forces (Coulomb interaction).
          console.time('long-range forces');
          updateLongRangeForces();
          console.timeEnd('long-range forces');

          // Accumulate forces from radially bonded interactions into a(t + dt).
          updateRadialBondForces();

          // Accumulate forces from angularly bonded interactions into a(t + dt).
          updateAngularBondForces();

          // Accumulate forces from restraint forces into a(t + dt).
          updateRestraintForces();

          // Accumulate forces from spring forces into a(t + dt).
          updateSpringForces();

          // Accumulate drag forces into a(t + dt).
          updateFrictionForces();

          // Apply forces caused by the hydrophobicity.
          // Affects only amino acids in the water or oil solvent.
          updateAminoAcidForces();

          // Convert ax, ay from forces to accelerations!
          for (i = 0; i < N; i++) {
            inverseMass = 1/mass[i];
            ax[i] *= inverseMass;
            ay[i] *= inverseMass;
          }

          // ############################################
          // ax and ay are ACCELERATIONS below this point
          // ############################################

          // Accumulate optional gravitational accelerations into a(t + dt).
          updateGravitationalAccelerations();
        },

        // Half of the update of v(t + dt) and p(t + dt) using a. During a single integration loop,
        // call once when a = a(t) and once when a = a(t+dt).
        halfUpdateVelocity = function() {
          var i, m;
          for (i = 0; i < N; i++) {
            m = mass[i];
            vx[i] += 0.5 * ax[i] * dt;
            px[i] = m * vx[i];
            vy[i] += 0.5 * ay[i] * dt;
            py[i] = m * vy[i];
          }
        },

        // Calculate r(t + dt, i) from v(t + 0.5 * dt).
        updateParticlesPosition = function() {
          var width100  = size[0] * 100,
              height100 = size[1] * 100,
              xPrev, yPrev, i;

          for (i = 0; i < N; i++) {
            xPrev = x[i];
            yPrev = y[i];

            x[i] += vx[i] * dt;
            y[i] += vy[i] * dt;

            // Simple check if model has diverged. Prevents web browser from crashing.
            // isNaN tests not only x, y, but also vx, vy, ax, ay as test is done after
            // updateParticlesPosition(). If a displacement during one step is larger than width * 100
            // (or height * 100) it means that the velocity is far too big for the current time step.
            if (isNaN(x[i]) || isNaN(y[i]) ||
                Math.abs(x[i]) > width100 || Math.abs(y[i]) > height100) {
              throw new Error("Model has diverged!");
            }

            // Bounce off walls.
            bounceParticleOffWalls(i);
            // Bounce off obstacles, update pressure probes.
            bounceParticleOffObstacles(i, xPrev, yPrev, true);
          }
        },

        // Removes velocity and acceleration from pinned atoms.
        pinAtoms = function() {
          var i;

          for (i = 0; i < N; i++) {
            if (pinned[i]) {
              vx[i] = vy[i] = ax[i] = ay[i] = 0;
            }
          }
        },

        // Update speed using velocities.
        updateParticlesSpeed = function() {
          var i;

          for (i = 0; i < N; i++) {
            speed[i] = Math.sqrt(vx[i] * vx[i] + vy[i] * vy[i]);
          }
        },

        // Calculate new obstacles position using simple integration method.
        updateObstaclesPosition = function() {
          var ax, ay, vx, vy,
              drag, extFx, extFy, i;

          for (i = 0; i < N_obstacles; i++) {
            // Fast path when obstacle isn't movable.
            if (obstacleMass[i] === Infinity) continue;

            vx = obstacleVX[i],
            vy = obstacleVY[i],
            // External forces are defined per mass unit!
            // So, they are accelerations in fact.
            extFx = obstacleExtFX[i],
            extFy = obstacleExtFY[i];

            if (vx || vy || extFx || extFy || gravitationalField) {
              drag = viscosity * obstacleFriction[i];
              ax = extFx - drag * vx;
              ay = extFy - drag * vy - gravitationalField;

              obstacleXPrev[i] = obstacleX[i];
              obstacleYPrev[i] = obstacleY[i];

              // Update positions.
              obstacleX[i] += vx * dt + 0.5 * ax * dt_sq;
              obstacleY[i] += vy * dt + 0.5 * ay * dt_sq;

              // Update velocities.
              obstacleVX[i] += ax * dt;
              obstacleVY[i] += ay * dt;

              bounceObstacleOffWalls(i);
            }
          }
        },

        // Sets total momentum of each molecule to zero.
        // Useful for proteins engine.
        zeroTotalMomentumOfMolecules = function() {
          var moleculeAtoms, atomIdx, sumX, sumY, invMass,
              i, j, len;

          for (i = 0; i < N; i++) {
            visited[i] = 0;
          }

          for (i = 0; i < N; i++) {
            // Process each particular atom only *once*.
            if (visited[i] === 1) continue;

            moleculeAtoms = engine.getMoleculeAtoms(i);
            if (moleculeAtoms.length === 0) continue;
            moleculeAtoms.push(i);

            sumX = sumY = invMass = 0;
            for (j = 0, len = moleculeAtoms.length; j < len; j++) {
              atomIdx = moleculeAtoms[j];
              // Mark that atom was part of processed molecule to avoid
              // calculating its molecule again.
              visited[atomIdx] = 1;
              if (!pinned[atomIdx]) {
                sumX += vx[atomIdx] * mass[atomIdx];
                sumY += vy[atomIdx] * mass[atomIdx];
                invMass += mass[atomIdx];
              }
            }
            invMass = 1.0 / invMass;
            for (j = 0, len = moleculeAtoms.length; j < len; j++) {
              atomIdx = moleculeAtoms[j];
              if (!pinned[atomIdx]) {
                vx[atomIdx] -= sumX * invMass;
                vy[atomIdx] -= sumY * invMass;
                // Update momentum.
                px[atomIdx] = vx[atomIdx] * mass[atomIdx];
                py[atomIdx] = vy[atomIdx] * mass[atomIdx];
              }
            }
          }
        },

        adjustTemperature = function(target, forceAdjustment) {
          var rescalingFactor, i;

          if (target == null) target = T_target;

          T = computeTemperature();

          if (T === 0) {
            // Special case when T is 0.
            for (i = 0; i < N; i++) {
              if (pinned[i] === false) {
                // Add some random velocity to unpinned atoms.
                vx[i] = Math.random() * 0.02 - 0.01;
                vy[i] = Math.random() * 0.02 - 0.01;
              }
            }
            // Update temperature.
            T = computeTemperature();

            if (T === 0) {
              // This means that all atoms are pinned. Nothing to do.
              return;
            }
          }

          if (temperatureChangeInProgress && Math.abs(getTWindowed(T) - target) <= target * tempTolerance) {
            temperatureChangeInProgress = false;
          }

          if (forceAdjustment || useThermostat || temperatureChangeInProgress && T > 0) {
            rescalingFactor = Math.sqrt(target / T);

            // Scale particles velocity.
            for (i = 0; i < N; i++) {
              vx[i] *= rescalingFactor;
              vy[i] *= rescalingFactor;
              px[i] *= rescalingFactor;
              py[i] *= rescalingFactor;
            }

            // Scale obstacles velocity.
            for (i = 0; i < N_obstacles; i++) {
              obstacleVX[i] *= rescalingFactor;
              obstacleVY[i] *= rescalingFactor;
            }

            T = target;
          }
        },

        // Two cysteine AAs can form a covalent bond between their sulphur atoms. We could model this such that
        // when two Cys AAs come close enough a covalent bond is formed (only one between a pair of cysteines).
        createDisulfideBonds = function () {
          var cys1Idx, cys2Idx, xDiff, yDiff, rSq, i, j, len;

          for (i = 0, len = freeCysteinesList.length; i < len; i++) {
            cys1Idx = freeCysteinesList[i];
            for (j = i + 1; j < len; j++) {
              cys2Idx = freeCysteinesList[j];

              xDiff = x[cys1Idx] - x[cys2Idx];
              yDiff = y[cys1Idx] - y[cys2Idx];
              rSq = xDiff * xDiff + yDiff * yDiff;

              // Check whether cysteines are close enough to each other.
              // As both are in the freeCysteinesList, they are not connected.
              if (rSq < 0.07) {
                // Connect cysteines.
                engine.addRadialBond({
                  atom1: cys1Idx,
                  atom2: cys2Idx,
                  length: Math.sqrt(rSq),
                  // Default strength of bonds between amino acids.
                  strength: 10000,
                  // Disulfide bond type.
                  type: 109
                });

                // Remove both cysteines from freeCysteinesList.
                arrays.remove(freeCysteinesList, i);
                arrays.remove(freeCysteinesList, j);

                // Update len, cys1Idx, j as freeCysteinesList has changed.
                // Not very pretty, but probably the fastest way.
                len = freeCysteinesList.length;
                cys1Idx = freeCysteinesList[i];
                j = i + 1;
              }
            }
          }
        },

        // ### Pressure calculation ###

        // Zero values of pressure probes. It should be called
        // at the beginning of the integration step.
        zeroPressureValues = function () {
          var i;
          for (i = 0; i < N_obstacles; i++) {
            if (obstacleNorthProbe[i]) {
              obstacleNProbeValue[i] = 0;
            }
            if (obstacleSouthProbe[i]) {
              obstacleSProbeValue[i] = 0;
            }
            if (obstacleEastProbe[i]) {
              obstacleEProbeValue[i] = 0;
            }
            if (obstacleWestProbe[i]) {
              obstacleWProbeValue[i] = 0;
            }
          }
        },

        // Update probes values so they contain final pressure value in Bar.
        // It should be called at the end of the integration step.
        calculateFinalPressureValues = function (duration) {
          var mult, i;
          // Classic MW converts impulses 2mv/dt to pressure in Bar using constant: 1666667.
          // See: the header of org.concord.mw2d.models.RectangularObstacle.
          // However, Classic MW also uses different units for mass and length:
          // - 120amu instead of 1amu,
          // - 0.1A instead of 1nm.
          // We should convert mass, velocity and obstacle height to Next Gen units.
          // Length units reduce themselves (velocity divided by height or width), only mass is left.
          // So, divide classic MW constant 1666667 by 120 - the result is 13888.89.
          // [ There is unit module available, however for reduction of computational cost,
          // include conversion in the pressure constant, especially considering the fact that
          // conversion from 120amu to amu is quite simple. ]
          mult = 13888.89 / duration;
          for (i = 0; i < N_obstacles; i++) {
            if (obstacleNorthProbe[i]) {
              obstacleNProbeValue[i] *= mult / obstacleWidth[i];
            }
            if (obstacleSouthProbe[i]) {
              obstacleSProbeValue[i] *= mult / obstacleWidth[i];
            }
            if (obstacleEastProbe[i]) {
              obstacleEProbeValue[i] *= mult / obstacleHeight[i];
            }
            if (obstacleWestProbe[i]) {
              obstacleWProbeValue[i] *= mult / obstacleHeight[i];
            }
          }
        };

        // ####################################################################
        // ####################################################################

    engine = {

      useCoulombInteraction: function(v) {
        useCoulombInteraction = !!v;
      },

      useLennardJonesInteraction: function(v) {
        useLennardJonesInteraction = !!v;
      },

      useThermostat: function(v) {
        useThermostat = !!v;
      },

      setVDWLinesRatio: function(vdwlr) {
        if (typeof vdwlr === "number" && vdwlr !== 0) {
          vdwLinesRatio = vdwlr;
        }
      },

      setGravitationalField: function(gf) {
        if (typeof gf === "number" && gf !== 0) {
          gravitationalField = gf;
        } else {
          gravitationalField = false;
        }
      },

      setTargetTemperature: function(v) {
        validateTemperature(v);
        T_target = v;
      },

      setDielectricConstant: function(dc) {
        dielectricConst = dc;
      },

      setRealisticDielectricEffect: function (r) {
        realisticDielectricEffect = r;
      },

      setSolventForceType: function(sft) {
        solventForceType = sft;
      },

      setSolventForceFactor: function(sff) {
        solventForceFactor = sff;
      },

      setAdditionalSolventForceMult: function(asfm) {
        additionalSolventForceMult = asfm;
      },

      setAdditionalSolventForceThreshold: function(asft) {
        additionalSolventForceThreshold = asft;
      },

      // Our timekeeping is really a convenience for users of this lib, so let them reset time at will
      setTime: function(t) {
        time = t;
      },

      setSize: function(v) {
        // NB. We may want to create a simple state diagram for the md engine (as well as for the 'modeler' defined in
        // lab.molecules.js)
        if (sizeHasBeenInitialized) {
          throw new Error("The molecular model's size has already been set, and cannot be reset.");
        }
        var width  = (v[0] && v[0] > 0) ? v[0] : 10,
            height = (v[1] && v[1] > 0) ? v[1] : 10;
        size = [width, height];
        sizeHasBeenInitialized = true;
      },

      getSize: function() {
        return [size[0], size[1]];
      },

      getLJCalculator: function() {
        return ljCalculator;
      },

      setAtomProperties: function (i, props) {
        var cysteineEl = aminoacidsHelper.cysteineElement,
            key, idx, rest, amino, j;

        if (props.element !== undefined) {
          if (props.element < 0 || props.element >= N_elements) {
            throw new Error("md2d: Unknown element " + props.element + ", an atom can't be created.");
          }

          // Special case when cysteine AA is morphed into other AA type,
          // which can't create disulphide bonds. Remove a connected
          // disulphide bond if it exists.
          if (element[i] === cysteineEl && props.element !== cysteineEl) {
            for (j = 0; j < N_radialBonds; j++) {
              if ((radialBondAtom1Index[j] === i || radialBondAtom2Index[j] === i) &&
                   radialBondType[j] === 109) {
                // Remove the radial bond representing disulphide bond.
                engine.removeRadialBond(j);
                // One cysteine can create only one disulphide bond so there is no need to continue the loop.
                break;
              }
            }
          }

          // Mark element as used by some atom (used by performance optimizations).
          elementUsed[props.element] = true;

          // Update mass and radius when element is changed.
          props.mass   = elementMass[props.element];
          props.radius = elementRadius[props.element];

          if (aminoacidsHelper.isAminoAcid(props.element)) {
            amino = aminoacidsHelper.getAminoAcidByElement(props.element);
            // Setup properties which are relevant to amino acids.
            props.charge = amino.charge;
            // Note that we overwrite value set explicitly in the hash.
            // So, while setting element of atom, it's impossible to set also its charge.
            props.hydrophobicity = amino.hydrophobicity;
          }
        }

        // Update charged atoms list (performance optimization).
        if (!charge[i] && props.charge) {
          // !charge[i]   => shortcut for charge[i] === 0 || charge[i] === undefined (both cases can occur).
          // props.charge => shortcut for props.charge !== undefined && props.charge !== 0.
          // Save index of charged atom.
          chargedAtomsList.push(i);
        } else if (charge[i] && props.charge === 0) {
          // charge[i] => shortcut for charge[i] !== undefined && charge[i] !== 0 (both cases can occur).
          // Remove index from charged atoms list.
          idx = chargedAtomsList.indexOf(i);
          rest = chargedAtomsList.slice(idx + 1);
          chargedAtomsList.length = idx;
          Array.prototype.push.apply(chargedAtomsList, rest);
        }
        // Update optimization flag.
        hasChargedAtoms = !!chargedAtomsList.length;

        // Set all properties from props hash.
        for (key in props) {
          if (props.hasOwnProperty(key)) {
            atoms[key][i] = props[key];
          }
        }

        // Update properties which depend on other properties.
        px[i]    = vx[i] * mass[i];
        py[i]    = vy[i] * mass[i];
        speed[i] = Math.sqrt(vx[i] * vx[i] + vy[i] * vy[i]);
      },

      setRadialBondProperties: function(i, props) {
        var key, atom1Idx, atom2Idx;

        // Unset current radial bond matrix entry.
        // Matrix will be updated when new properties are set.
        atom1Idx = radialBondAtom1Index[i];
        atom2Idx = radialBondAtom2Index[i];
        if (radialBondMatrix[atom1Idx] && radialBondMatrix[atom1Idx][atom2Idx])
          radialBondMatrix[atom1Idx][atom2Idx] = false;
        if (radialBondMatrix[atom2Idx] && radialBondMatrix[atom2Idx][atom1Idx])
          radialBondMatrix[atom2Idx][atom1Idx] = false;

        // Set all properties from props hash.
        for (key in props) {
          if (props.hasOwnProperty(key)) {
            radialBonds[key][i]       = props[key];
            // Update radial bond results also.
            radialBondResults[i][key] = props[key];
          }
        }

        // Update radial bond matrix.
        atom1Idx = radialBondAtom1Index[i];
        atom2Idx = radialBondAtom2Index[i];
        if (!radialBondMatrix[atom1Idx]) radialBondMatrix[atom1Idx] = [];
        radialBondMatrix[atom1Idx][atom2Idx] = true;
        if (!radialBondMatrix[atom2Idx]) radialBondMatrix[atom2Idx] = [];
        radialBondMatrix[atom2Idx][atom1Idx] = true;
      },

      setAngularBondProperties: function(i, props) {
        var key;
        // Set all properties from props hash.
        for (key in props) {
          if (props.hasOwnProperty(key)) {
            angularBonds[key][i] = props[key];
          }
        }
      },

      setRestraintProperties: function(i, props) {
        var key;
        // Set all properties from props hash.
        for (key in props) {
          if (props.hasOwnProperty(key)) {
            restraints[key][i] = props[key];
          }
        }
      },

      setElementProperties: function(i, properties) {
        var j, newRadius;
        // FIXME we cached mass into its own array, which is now probably unnecessary (position-update
        // calculations have since been speeded up by batching the computation of accelerations from
        // forces.) If we remove the mass[] array we also remove the need for the loop below:

        if (properties.mass != null && properties.mass !== elementMass[i]) {
            elementMass[i] = properties.mass;
          for (j = 0; j < N; j++) {
            if (element[j] === i) mass[j] = properties.mass;
          }
        }

        if (properties.sigma != null) {
          elementSigma[i] = properties.sigma;
          newRadius = lennardJones.radius(properties.sigma);

          if (elementRadius[i] !== newRadius) {
            elementRadius[i] = newRadius;
            for (j = 0; j < N; j++) {
              if (element[j] === i) radius[j] = newRadius;
            }
          }
        }

        if (properties.epsilon != null) elementEpsilon[i] = properties.epsilon;

        if (properties.color != null) {
          elementColor[i] = properties.color;
        }

        for (j = 0; j < N_elements; j++) {
          setPairwiseLJProperties(i, j);
        }
        // Reinitialize optimization structures, as sigma can be changed.
        initializeCellList();
        initializeNeighborList();
      },

      setPairwiseLJProperties: function (i, j) {
        // Call private (closure) version of this funcion.
        setPairwiseLJProperties(i, j);
        // Reinitialize optimization structures, as sigma can be changed.
        initializeCellList();
        initializeNeighborList();
      },

      setObstacleProperties: function (i, props) {
        var key;

        if (!engine.canPlaceObstacle(props.x, props.y, props.width, props.height, i))
          throw new Error("Obstacle can't be placed at " + props.x + ", " + props.y);

        // If position is manually changed, update previous
        // position also.
        if (props.x !== undefined) {
          props.xPrev = props.x;
        }
        if (props.y !== undefined) {
          props.yPrev = props.y;
        }
        // Try to parse mass, as it may be string "Infinity".
        if (typeof props.mass === 'string') {
          props.mass = parseFloat(props.mass);
        }

        // Set properties from props hash.
        for (key in props) {
          if (props.hasOwnProperty(key)) {
            obstacles[key][i] = props[key];
          }
        }
      },

      /**
        The canonical method for adding an atom to the collections of atoms.

        If there isn't enough room in the 'atoms' array, it (somewhat inefficiently)
        extends the length of the typed arrays by ten to have room for more atoms.

        @returns the index of the new atom
      */
      addAtom: function(props) {
        if (N + 1 > atoms.x.length) {
          extendArrays(atoms, N + 10);
          assignShortcutReferences.atoms();
        }

        // Set acceleration of new atom to zero.
        props.ax = props.ay = 0;

        // Increase number of atoms.
        N++;

        // Set provided properties of new atom.
        engine.setAtomProperties(N - 1, props);

        // Initialize helper structures for optimizations.
        initializeCellList();
        initializeNeighborList();
      },

      removeAtom: function(idx) {
        var i, len, prop,
            l, list, lists;

        if (idx >= N) {
          throw new Error("Atom " + idx + " doesn't exist, so it can't be removed.");
        }

        // Start from removing all bonds connected to this atom.
        // Note that we are removing only radial bonds. Angular bonds
        // will be removed while removing radial bond, not atom!

        // Use such "strange" form of loop, as while removing one bonds,
        // other change their indexing. So, after removal of bond 5, we
        // should check bond 5 again, as it would be another bond (previously
        // indexed as 6).
        i = 0;
        while (i < N_radialBonds) {
          if (radialBondAtom1Index[i] === idx || radialBondAtom2Index[i] === idx)
            engine.removeRadialBond(i);
          else
            i++;
        }

        // Try to remove atom from charged atoms list.
        i = chargedAtomsList.indexOf(idx);
        if (i !== -1) {
          arrays.remove(chargedAtomsList, i);
        }


        // Finally, remove atom.

        // Shift atoms properties and zero last element.
        // It can be optimized by just replacing the last
        // atom with atom 'i', however this approach
        // preserves more expectable atoms indexing.
        for (i = idx; i < N; i++) {
          for (prop in atoms) {
            if (atoms.hasOwnProperty(prop)) {
              if (i === N - 1)
                atoms[prop][i] = 0;
              else
                atoms[prop][i] = atoms[prop][i + 1];
            }
          }
        }

        // Update number of atoms!
        N--;

        // Shift indices of atoms in various lists.
        lists = [
          chargedAtomsList,
          radialBondAtom1Index, radialBondAtom2Index,
          angularBondAtom1Index, angularBondAtom2Index, angularBondAtom3Index
        ];

        for (l = 0; l < lists.length; l++) {
          list = lists[l];
          for (i = 0, len = list.length; i < len; i++) {
            if (list[i] > idx)
              list[i]--;
          }
        }

        // Also in radial bonds results...
        // TODO: they should be recalculated while computing output state.
        for (i = 0, len = radialBondResults.length; i < len; i++) {
          if (radialBondResults[i].atom1 > idx)
            radialBondResults[i].atom1--;
          if (radialBondResults[i].atom2 > idx)
            radialBondResults[i].atom2--;
        }

        // Recalculate radial bond matrix, as indices have changed.
        calculateRadialBondMatrix();

        // (Re)initialize helper structures for optimizations.
        initializeCellList();
        initializeNeighborList();

        neighborList.invalidate();

        // Update accelerations of atoms.
        updateParticlesAccelerations();
      },

      /**
        The canonical method for adding an element.
      */
      addElement: function(props) {
        var i;

        if (N_elements >= elementEpsilon.length) {
          extendArrays(elements, N_elements + 10);
          assignShortcutReferences.elements();
        }

        elementMass[N_elements]    = props.mass;
        elementEpsilon[N_elements] = props.epsilon;
        elementSigma[N_elements]   = props.sigma;
        elementRadius[N_elements]  = lennardJones.radius(props.sigma);
        elementColor[N_elements]   = props.color;

        ljCalculator[N_elements]              = [];
        cutoffDistance_LJ_sq[N_elements]      = [];
        cutoffNeighborListSquared[N_elements] = [];

        for (i = 0; i <= N_elements; i++) {
          setPairwiseLJProperties(N_elements, i);
        }
        // Note that we don't have to reinitialize optimization
        // structures (cell lists and neighbor list). They are
        // based only on the properties of *used* elements, so
        // adding a new atom should trigger reinitialization instead.

        N_elements++;
      },

      /**
        The canonical method for adding a radial bond to the collection of radial bonds.
      */
      addRadialBond: function(props) {
        if (N_radialBonds + 1 > radialBondAtom1Index.length) {
          extendArrays(radialBonds, N_radialBonds + 10);
          assignShortcutReferences.radialBonds();
        }

        N_radialBonds++;

        // Add results object.
        radialBondResults[N_radialBonds - 1] = {idx: N_radialBonds - 1};
        // Set new radial bond properties.
        engine.setRadialBondProperties(N_radialBonds - 1, props);
      },

      removeRadialBond: function(idx) {
        var i, prop, atom1, atom2;

        if (idx >= N_radialBonds) {
          throw new Error("Radial bond " + idx + " doesn't exist, so it can't be removed.");
        }

        // Start from removing angular bonds.
        atom1 = radialBondAtom1Index[idx];
        atom2 = radialBondAtom2Index[idx];

        // Use such "strange" form of loop, as while removing one bonds,
        // other change their indexing. So, after removal of bond 5, we
        // should check bond 5 again, as it would be another bond (previously
        // indexed as 6).
        i = 0;
        while (i < N_angularBonds) {
          // Remove angular bond only when one of atoms is the CENTRAL atom of the given angular bond.
          // It means that this radial bond creates given angular bond.
          // Atom3Index is index of central atom in angular bonds.
          if (angularBondAtom3Index[i] === atom1 || angularBondAtom3Index[i] === atom2)
            engine.removeAngularBond(i);
          else
            i++;
        }

        // Shift radial bonds properties and zero last element.
        // It can be optimized by just replacing the last
        // radial bond with radial bond 'i', however this approach
        // preserves more expectable indexing.
        // TODO: create some general function for that, as it's duplicated
        // in each removeObject method.
        for (i = idx; i < N_radialBonds; i++) {
          for (prop in radialBonds) {
            if (radialBonds.hasOwnProperty(prop)) {
              if (i === N_radialBonds - 1)
                radialBonds[prop][i] = 0;
              else
                radialBonds[prop][i] = radialBonds[prop][i + 1];
            }
          }
        }

        N_radialBonds--;

        arrays.remove(radialBondResults, idx);

        // Recalculate radial bond matrix.
        calculateRadialBondMatrix();
      },

      /**
        The canonical method for adding an 'restraint' bond to the collection of restraints.

        If there isn't enough room in the 'restraints' array, it (somewhat inefficiently)
        extends the length of the typed arrays by ten to have room for more bonds.
      */
      addRestraint: function(props) {
        if (N_restraints + 1 > restraints.atomIndex.length) {
          extendArrays(restraints, N_restraints + 10);
          assignShortcutReferences.restraints();
        }

        N_restraints++;

        // Set new restraint properties.
        engine.setRestraintProperties(N_restraints - 1, props);
      },

      /**
        The canonical method for adding an angular bond to the collection of angular bonds.

        If there isn't enough room in the 'angularBonds' array, it (somewhat inefficiently)
        extends the length of the typed arrays by ten to have room for more bonds.
      */
      addAngularBond: function(props) {
        if (N_angularBonds + 1 > angularBonds.atom1.length) {
          extendArrays(angularBonds, N_angularBonds + 10);
          assignShortcutReferences.angularBonds();
        }

        N_angularBonds++;

        // Set new angular bond properties.
        engine.setAngularBondProperties(N_angularBonds - 1, props);
      },

      removeAngularBond: function(idx) {
        var i, prop;

        if (idx >= N_angularBonds) {
          throw new Error("Angular bond " + idx + " doesn't exist, so it can't be removed.");
        }

        // Shift angular bonds properties and zero last element.
        // It can be optimized by just replacing the last
        // angular bond with angular bond 'i', however this approach
        // preserves more expectable indexing.
        // TODO: create some general function for that, as it's duplicated
        // in each removeObject method.
        for (i = idx; i < N_angularBonds; i++) {
          for (prop in angularBonds) {
            if (angularBonds.hasOwnProperty(prop)) {
              if (i === N_angularBonds - 1)
                angularBonds[prop][i] = 0;
              else
                angularBonds[prop][i] = angularBonds[prop][i + 1];
            }
          }
        }

        N_angularBonds--;
      },

      /**
        Adds a spring force between an atom and an x, y location.

        @returns the index of the new spring force.
      */
      addSpringForce: function(atomIndex, x, y, strength) {
        // conservatively just add one spring force
        if (N_springForces + 1 > springForces[0].length) {
          extendArrays(springForces, N_springForces + 1);
          assignShortcutReferences.springForces();
        }

        springForceAtomIndex[N_springForces]  = atomIndex;
        springForceX[N_springForces]          = x;
        springForceY[N_springForces]          = y;
        springForceStrength[N_springForces]   = strength;

        return N_springForces++;
      },

      updateSpringForce: function(i, x, y) {
        springForceX[i] = x;
        springForceY[i] = y;
      },

      removeSpringForce: function(i) {
        if (i >= N_springForces) return;
        N_springForces--;
      },

      springForceAtomIndex: function(i) {
        return springForceAtomIndex[i];
      },

      addObstacle: function(props) {
        if (!engine.canPlaceObstacle(props.x, props.y, props.width, props.height))
          throw new Error("Obstacle can't be placed at " + props.x + ", " + props.y + ".");

        if (N_obstacles + 1 > obstacles.x.length) {
          // Extend arrays each time (as there are only
          // a few obstacles in typical model).
          extendArrays(obstacles, N_obstacles + 1);
          assignShortcutReferences.obstacles();
        }

        N_obstacles++;

        // Set properties of new obstacle.
        engine.setObstacleProperties(N_obstacles - 1, props);
      },

      removeObstacle: function(idx) {
        var i, prop;

        if (idx >= N_obstacles) {
          throw new Error("Obstacle " + idx + " doesn't exist, so it can't be removed.");
        }

        N_obstacles--;

        // Shift obstacles properties.
        // It can be optimized by just replacing the last
        // obstacle with obstacle 'i', however this approach
        //  preserves more expectable obstacles indexing.
        for (i = idx; i < N_obstacles; i++) {
          for (prop in obstacles) {
            if (obstacles.hasOwnProperty(prop)) {
              obstacles[prop][i] = obstacles[prop][i + 1];
            }
          }
        }

        // FIXME: This shouldn't be necessary, however various modules
        // (e.g. views) use obstacles.x.length as the real number of obstacles.
        extendArrays(obstacles, N_obstacles);
        assignShortcutReferences.obstacles();
      },

      atomInBounds: function(_x, _y, i) {
        var r = radius[i], j;

        if (_x < r || _x > size[0] - r || _y < r || _y > size[1] - r) {
          return false;
        }
        for (j = 0; j < N_obstacles; j++) {
          if (_x > (obstacleX[j] - r) && _x < (obstacleX[j] + obstacleWidth[j] + r) &&
              _y > (obstacleY[j] - r) && _y < (obstacleY[j] + obstacleHeight[j] + r)) {
            return false;
          }
        }
        return true;
      },

      /**
        Checks to see if an uncharged atom could be placed at location x,y
        without increasing the PE (i.e. overlapping with another atom), and
        without being on an obstacle or past a wall.

        Optionally, an atom index i can be included which will tell the function
        to ignore the existance of atom i. (Used when moving i around.)
      */
      canPlaceAtom: function(element, _x, _y, i) {
        var orig_x,
            orig_y,
            PEAtLocation;

        // first do the simpler check to see if we're outside the walls or intersect an obstacle
        if ( !engine.atomInBounds(_x, _y, i) ) {
          return false;
        }

        // then check PE at location
        if (typeof i === "number") {
          orig_x = x[i];
          orig_y = y[i];
          x[i] = y[i] = Infinity;   // move i atom away
        }

        PEAtLocation = engine.newPotentialCalculator(element, 0, false)(_x, _y);

        if (typeof i === "number") {
          x[i] = orig_x;
          y[i] = orig_y;
        }

        return PEAtLocation <= 0;
      },

      /**
        Checks to see if an obstacle could be placed at location x, y
        without being on an atom, another obstacle or past a wall.

        idx parameter is optional. It should be defined and equal to id
        of an existing obstacle when the existing obstacle should be checked.
        It prevents an algorithm from comparing the obstacle with itself during
        collisions detection.
      */
      canPlaceObstacle: function (obsX, obsY, obsWidth, obsHeight, idx) {
        var obsXMax = obsX + obsWidth,
            obsYMax = obsY + obsHeight,
            testX, testY, testXMax, testYMax,
            r, i;

        // Check collision with walls.
        if (obsX < 0 || obsXMax > size[0] || obsY < 0 || obsYMax > size[0]) {
          return false;
        }

        // Check collision with atoms.
        for (i = 0; i < N; i++) {
          r = radius[i];
          if (x[i] > (obsX - r) && x[i] < (obsXMax + r) &&
              y[i] > (obsY - r) && y[i] < (obsYMax + r)) {
            return false;
          }
        }

        // Check collision with other obstacles.
        for (i = 0; i < N_obstacles; i++) {
          if (idx !== undefined && idx === i) {
            // If we are checking existing obstacle,
            // avoid comparing it with itself.
            continue;
          }
          testX = obstacleX[i];
          testY = obstacleY[i];
          testXMax = testX + obstacleWidth[i];
          testYMax = testY + obstacleHeight[i];
          if ((obsXMax > testX && obsX < testXMax) &&
              (obsYMax > testY && obsY < testYMax)) {
            return false;
          }
        }

        return true;
      },

      setupAtomsRandomly: function(options) {

        var // if a temperature is not explicitly requested, we just need any nonzero number
            temperature = options.temperature || 100,

            nrows = Math.floor(Math.sqrt(N)),
            ncols = Math.ceil(N/nrows),

            i, r, c, rowSpacing, colSpacing,
            vMagnitude, vDirection, props;

        validateTemperature(temperature);

        colSpacing = size[0] / (1 + ncols);
        rowSpacing = size[1] / (1 + nrows);

        // Arrange molecules in a lattice. Not guaranteed to have CM exactly on center, and is an artificially low-energy
        // configuration. But it works OK for now.
        i = -1;

        for (r = 1; r <= nrows; r++) {
          for (c = 1; c <= ncols; c++) {
            i++;
            if (i === N) break;
            vMagnitude = math.normal(1, 1/4);
            vDirection = 2 * Math.random() * Math.PI;

            props = {
              element: Math.floor(Math.random() * options.userElements), // random element
              x:       c * colSpacing,
              y:       r * rowSpacing,
              vx:      vMagnitude * Math.cos(vDirection),
              vy:      vMagnitude * Math.sin(vDirection),
              charge:  2 * (i % 2) - 1 // alternate negative and positive charges
            };
            engine.setAtomProperties(i, props);
          }
        }

        // now, remove all translation of the center of mass and rotation about the center of mass
        computeCMMotion();
        removeTranslationAndRotationFromVelocities();

        // Scale randomized velocities to match the desired initial temperature.
        //
        // Note that although the instantaneous temperature will be 'temperature' exactly, the temperature will quickly
        // settle to a lower value because we are initializing the atoms spaced far apart, in an artificially low-energy
        // configuration.
        //
        adjustTemperature(temperature, true);
      },

      /**
        Generates a protein. It returns a real number of created amino acids.

        'aaSequence' parameter defines expected sequence of amino acids. Pass undefined
        and provide 'expectedLength' if you want to generate a random protein.

        'expectedLength' parameter controls the maximum (and expected) number of amino
        acids of the resulting protein. Provide this parameter only when 'aaSequence'
        is undefined. When expected length is too big (due to limited area of the model),
        the protein will be truncated and its real length returned.
      */
      generateProtein: function (aaSequence, expectedLength) {
        var width = size[0],
            height = size[1],
            xStep = 0,
            yStep = 0,
            aaCount = aminoacidsHelper.lastElementID - aminoacidsHelper.firstElementID + 1,
            i, xPos, yPos, el, bondLen,

            // This function controls how X coordinate is updated,
            // using current Y coordinate as input.
            turnHeight = 0.6,
            xStepFunc = function(y) {
              if (y > height - turnHeight || y < turnHeight) {
                // Close to the boundary increase X step.
                return 0.1;
              }
              return 0.02 - Math.random() * 0.04;
            },

            // This function controls how Y coordinate is updated,
            // using current Y coordinate and previous result as input.
            changeHeight = 0.3,
            yStepFunc = function(y, prev) {
              if (prev === 0) {
                // When previously 0 was returned,
                // now it's time to switch direction of Y step.
                if (y > 0.5 * size[1]) {
                  return -0.1;
                }
                return 0.1;
              }
              if (yPos > height - changeHeight || yPos < changeHeight) {
                // Close to the boundary return 0 to make smoother turn.
                return 0;
              }
              // In a typical situation, just return previous value.
              return prev;
            },

            getRandomAA = function() {
              return Math.floor(aaCount * Math.random()) + aminoacidsHelper.firstElementID;
            };

        // Process arguments.
        if (aaSequence !== undefined) {
          expectedLength = aaSequence.length;
        }

        // First, make sure that model is empty.
        while(N > 0) {
          engine.removeAtom(N - 1);
        }

        // Start from the lower-left corner, add first Amino Acid.
        xPos = 0.1;
        yPos = 0.1;
        el = aaSequence ? aminoacidsHelper.abbrToElement(aaSequence[0]) : getRandomAA();
        engine.addAtom({x: xPos, y: yPos, element: el, visible: true});
        engine.minimizeEnergy();

        // Add remaining amino acids.
        for (i = 1; i < expectedLength; i++) {
          xPos = x[N - 1];
          yPos = y[N - 1];

          // Update step.
          xStep = xStepFunc(yPos);
          yStep = yStepFunc(yPos, yStep);

          // Update coordinates of new AA.
          xPos += xStep;
          yPos += yStep;

          if (xPos > width - 0.1) {
            // No space left for new AA. Stop here, return
            // real number of created AAs.
            return i;
          }

          el = aaSequence ? aminoacidsHelper.abbrToElement(aaSequence[i]) : getRandomAA();
          engine.addAtom({x: xPos, y: yPos, element: el, visible: true});
          // Length of bond is based on the radii of AAs.
          bondLen = (radius[N - 1] + radius[N - 2]) * 1.25;
          // 10000 is a typical strength for bonds between AAs.
          engine.addRadialBond({atom1: N - 1, atom2: N - 2, length: bondLen, strength: 10000});

          engine.minimizeEnergy();
        }

        // Center protein (X coords only).
        // Use last X coordinate to calculate available space on the right.
        xStep = (width - xPos) / 2;
        // Shift all AAs.
        for (i = 0; i < N; i++) {
          x[i] += xStep;
        }

        // Return number of created AA.
        return i;
      },

      extendProtein: function (xPos, yPos, aaAbbr) {
        var aaCount = aminoacidsHelper.lastElementID - aminoacidsHelper.firstElementID + 1,
            cx = size[0] / 2,
            cy = size[1] / 2,
            el, bondLen, i,

            getRandomAA = function() {
              return Math.floor(aaCount * Math.random()) + aminoacidsHelper.firstElementID;
            },

            xcm, ycm,
            getCenterOfMass = function () {
              var totalMass = 0,
                  atomMass, i;
              xcm = ycm = 0;
              for (i = 0; i < N; i++) {
                atomMass = mass[i];
                xcm += x[i] * atomMass;
                ycm += y[i] * atomMass;
                totalMass += atomMass;
              }
              xcm /= totalMass;
              ycm /= totalMass;
            };

        xPos = xPos !== undefined ? xPos : cx / 10;
        yPos = yPos !== undefined ? yPos : cy / 2;

        if (N === 0) {
          el = aaAbbr ? aminoacidsHelper.abbrToElement(aaAbbr) : getRandomAA();
          engine.addAtom({x: xPos, y: yPos, element: el, pinned: true, visible: true});
          engine.minimizeEnergy();
        } else {
          getCenterOfMass();
          for (i = 0; i < N; i++) {
            pinned[i] = false;
            x[i] += (cx - xcm) / 5 + Math.random() * 0.04 - 0.02;
            y[i] += (cy - ycm) / 5 + Math.random() * 0.04 - 0.02;
          }
          el = aaAbbr ? aminoacidsHelper.abbrToElement(aaAbbr) : getRandomAA();
          engine.addAtom({x: xPos, y: yPos, element: el, pinned: true, visible: true});
          // Length of bond is based on the radii of AAs.
          bondLen = (radius[N - 1] + radius[N - 2]) * 1.25;
          // 10000 is a typical strength for bonds between AAs.
          engine.addRadialBond({atom1: N - 1, atom2: N - 2, length: bondLen, strength: 10000});
          engine.minimizeEnergy();
        }
      },

      getVdwPairsArray: function() {
        var i,
            j,
            dx,
            dy,
            r_sq,
            x_i,
            y_i,
            sigma_i,
            epsilon_i,
            sigma_j,
            epsilon_j,
            index_i,
            index_j,
            sig,
            eps,
            distanceCutoff_sq = vdwLinesRatio * vdwLinesRatio;

        N_vdwPairs = 0;

        for (i = 0; i < N; i++) {
          // pairwise interactions
          index_i = element[i];
          sigma_i   = elementSigma[index_i];
          epsilon_i = elementSigma[index_i];
          x_i = x[i];
          y_i = y[i];

          for (j = i+1; j < N; j++) {
            if (N_radialBonds !== 0 && (radialBondMatrix[i] && radialBondMatrix[i][j])) continue;

            index_j = element[j];
            sigma_j   = elementSigma[index_j];
            epsilon_j = elementSigma[index_j];

            if (charge[i]*charge[j] <= 0) {
              dx = x[j] - x_i;
              dy = y[j] - y_i;
              r_sq = dx*dx + dy*dy;


              sig = 0.5 * (sigma_i+sigma_j);
              sig *= sig;
              eps = epsilon_i * epsilon_j;

              if (r_sq < sig * distanceCutoff_sq && eps > 0) {
                if (N_vdwPairs + 1 > vdwPairs.atom1.length) {
                  extendArrays(vdwPairs, (N_vdwPairs + 1) * 2);
                  assignShortcutReferences.vdwPairs();
                }
                vdwPairAtom1Index[N_vdwPairs] = i;
                vdwPairAtom2Index[N_vdwPairs] = j;
                N_vdwPairs++;
              }
            }
          }
        }

        vdwPairs.count = N_vdwPairs;
        return vdwPairs;
      },

      relaxToTemperature: function(T) {

        // FIXME this method needs to be modified. It should rescale velocities only periodically
        // and stop when the temperature approaches a steady state between rescalings.

        if (T != null) T_target = T;

        validateTemperature(T_target);

        beginTransientTemperatureChange();
        while (temperatureChangeInProgress) {
          engine.integrate();
        }
      },

      // Velocity Verlet integration scheme.
      // See: http://en.wikipedia.org/wiki/Verlet_integration#Velocity_Verlet
      // The current implementation is:
      // 1. Calculate: v(t + 0.5 * dt) = v(t) + 0.5 * a(t) * dt
      // 2. Calculate: r(t + dt) = r(t) + v(t + 0.5 * dt) * dt
      // 3. Derive a(t + dt) from the interaction potential using r(t + dt)
      // 4. Calculate: v(t + dt) = v(t + 0.5 * dt) + 0.5 * a(t + dt) * dt
      integrate: function(duration, _dt) {
        var steps, iloop, tStart = time;

        // How much time to integrate over, in fs.
        if (duration === undefined)  duration = 100;

        // The length of an integration timestep, in fs.
        if (_dt === undefined) _dt = 1;

        dt = _dt;        // dt is a closure variable that helpers need access to
        dt_sq = dt * dt; // the squared time step is also needed by some helpers.

        // Prepare optimization structures to ensure that they are valid during integration.
        // Note that when user adds or removes various objects (like atoms, bonds), such structures
        // can become invalid. That's why we update them each time before integration.
        // It's also safer and easier to do recalculate each structure than to modify it while
        // engine state is changed by user.
        calculateOptimizationStructures();

        // Calculate accelerations a(t), where t = 0.
        // Later this is not necessary, as a(t + dt) from
        // previous step is used as a(t) in the current step.
        if (time === 0) {
          updateParticlesAccelerations();
        }

        // Number of steps.
        steps = Math.floor(duration / dt);

        // Zero values of pressure probes at the beginning of
        // each integration step.
        zeroPressureValues();

        for (iloop = 1; iloop <= steps; iloop++) {
          time = tStart + iloop * dt;

          // Calculate v(t + 0.5 * dt) using v(t) and a(t).
          halfUpdateVelocity();

          // Update r(t + dt) using v(t + 0.5 * dt).
          updateParticlesPosition();

          // Accumulate accelerations into a(t + dt) from all possible interactions, fields
          // and forces connected with atoms.
          updateParticlesAccelerations();

          // Clearing the acceleration here from pinned atoms will cause the acceleration
          // to be zero for both halfUpdateVelocity methods and updateParticlesPosition, freezing the atom.
          pinAtoms();

          // Calculate v(t + dt) using v(t + 0.5 * dt) and a(t + dt).
          halfUpdateVelocity();

          // Now that we have velocity v(t + dt), update speed.
          updateParticlesSpeed();

          // Move obstacles using very simple integration.
          updateObstaclesPosition();

          // Adjust temperature, e.g. when heat bath is enabled.
          adjustTemperature();

          // If solvent is different from vacuum (water or oil), ensure
          // that the total momentum of each molecule is equal to zero.
          // This prevents amino acids chains from drifting towards one
          // boundary of the model.
          if (solventForceType !== 0) {
            zeroTotalMomentumOfMolecules();
          }

        } // end of integration loop

        // Collisions between particles and obstacles are collected during
        // updateParticlesPosition() execution. This function takes into account
        // time which passed and converts raw data from pressure probes to value
        // in Bars.
        calculateFinalPressureValues(duration);

        // After each integration loop try to create new disulfide bonds between cysteines.
        // It's enough to do it outside the inner integration loop (performance).
        createDisulfideBonds();
      },

      // Minimize energy using steepest descend method.
      minimizeEnergy: function () {
            // Maximal length of displacement during one step of minimization.
        var stepLength   = 1e-3,
            // Maximal acceleration allowed.
            accThreshold = 1e-4,
            // Maximal number of iterations allowed.
            iterLimit    = 3000,
            maxAcc, delta, xPrev, yPrev, i, iter;

        // Calculate accelerations.
        updateParticlesAccelerations();
        pinAtoms();
        // Get maximum value.
        maxAcc = 0;
        for (i = 0; i < N; i++) {
          if (maxAcc < Math.abs(ax[i]))
            maxAcc = Math.abs(ax[i]);
          if (maxAcc < Math.abs(ay[i]))
            maxAcc = Math.abs(ay[i]);
        }

        iter = 0;
        while (maxAcc > accThreshold && iter < iterLimit) {
          iter++;

          delta = stepLength / maxAcc;
          for (i = 0; i < N; i++) {
            xPrev = x[i];
            yPrev = y[i];
            x[i] += ax[i] * delta;
            y[i] += ay[i] * delta;

            // Keep atoms in bounds.
            bounceParticleOffWalls(i);
            // Bounce off obstacles, but DO NOT update pressure probes.
            bounceParticleOffObstacles(i, xPrev, yPrev, false);
          }

          // Calculate accelerations.
          updateParticlesAccelerations();
          pinAtoms();
          // Get maximum value.
          maxAcc = 0;
          for (i = 0; i < N; i++) {
            if (maxAcc < Math.abs(ax[i]))
              maxAcc = Math.abs(ax[i]);
            if (maxAcc < Math.abs(ay[i]))
              maxAcc = Math.abs(ay[i]);
          }
        }
      },

      // Total mass of all particles in the system, in Dalton (atomic mass units).
      getTotalMass: function() {
        var totalMass = 0, i;
        for (i = 0; i < N; i++) {
          totalMass += mass[i];
        }
        return totalMass;
      },

      getRadiusOfElement: function(el) {
        return elementRadius[el];
      },

      getNumberOfAtoms: function() {
        return N;
      },

      getNumberOfElements: function() {
        return N_elements;
      },

      getNumberOfObstacles: function() {
        return N_obstacles;
      },

      getNumberOfRadialBonds: function() {
        return N_radialBonds;
      },

      getNumberOfAngularBonds: function() {
        return N_angularBonds;
      },

      getNumberOfRestraints: function() {
        return N_restraints;
      },

      /**
        Compute the model state and store into the passed-in 'state' object.
        (Avoids GC hit of throwaway object creation.)
      */
      // TODO: [refactoring] divide this function into smaller chunks?
      computeOutputState: function(state) {
        var i, j,
            i1, i2, i3,
            el1, el2,
            dx, dy,
            dxij, dyij, dxkj, dykj,
            cosTheta, theta,
            r_sq, rij, rkj,
            k, dr, angleDiff,
            gravPEInMWUnits,
            // Total kinetic energy, in MW units.
            KEinMWUnits,
            // Potential energy, in eV.
            PE;

        // Calculate potentials in eV. Note that we only want to do this once per call to integrate(), not once per
        // integration loop!
        PE = 0;
        KEinMWUnits = 0;

        for (i = 0; i < N; i++) {

          // gravitational PE
          if (gravitationalField) {
            gravPEInMWUnits = mass[i] * gravitationalField * y[i];
            PE += constants.convert(gravPEInMWUnits, { from: unit.MW_ENERGY_UNIT, to: unit.EV });
          }

          KEinMWUnits += 0.5 * mass[i] * (vx[i] * vx[i] + vy[i] * vy[i]);

          // pairwise interactions
          for (j = i+1; j < N; j++) {
            dx = x[j] - x[i];
            dy = y[j] - y[i];

            r_sq = dx*dx + dy*dy;

            // FIXME the signs here don't really make sense
            if (useLennardJonesInteraction) {
              PE -=ljCalculator[element[i]][element[j]].potentialFromSquaredDistance(r_sq);
            }
            if (useCoulombInteraction && hasChargedAtoms) {
              PE += coulomb.potential(Math.sqrt(r_sq), charge[i], charge[j], dielectricConst, realisticDielectricEffect);
            }
          }
        }

        // radial bonds
        for (i = 0; i < N_radialBonds; i++) {
          i1 = radialBondAtom1Index[i];
          i2 = radialBondAtom2Index[i];
          el1 = element[i1];
          el2 = element[i2];

          dx = x[i2] - x[i1];
          dy = y[i2] - y[i1];
          r_sq = dx*dx + dy*dy;

          // eV/nm^2
          k = radialBondStrength[i];

          // nm
          dr = Math.sqrt(r_sq) - radialBondLength[i];

          PE += 0.5*k*dr*dr;

          // Remove the Lennard Jones potential for the bonded pair
          if (useLennardJonesInteraction) {
            PE += ljCalculator[el1][el2].potentialFromSquaredDistance(r_sq);
          }
          if (useCoulombInteraction && charge[i1] && charge[i2]) {
            PE -= coulomb.potential(Math.sqrt(r_sq), charge[i1], charge[i2], dielectricConst, realisticDielectricEffect);
          }

          // Also save the updated position of the two bonded atoms
          // in a row in the radialBondResults array.
          radialBondResults[i].x1 = x[i1];
          radialBondResults[i].y1 = y[i1];
          radialBondResults[i].x2 = x[i2];
          radialBondResults[i].y2 = y[i2];
        }

        // Angular bonds.
        for (i = 0; i < N_angularBonds; i++) {
          i1 = angularBondAtom1Index[i];
          i2 = angularBondAtom2Index[i];
          i3 = angularBondAtom3Index[i];

          // Calculate angle (theta) between two vectors:
          // Atom1-Atom3 and Atom2-Atom3
          // Atom1 -> i, Atom2 -> k, Atom3 -> j
          dxij = x[i1] - x[i3];
          dxkj = x[i2] - x[i3];
          dyij = y[i1] - y[i3];
          dykj = y[i2] - y[i3];
          rij = Math.sqrt(dxij * dxij + dyij * dyij);
          rkj = Math.sqrt(dxkj * dxkj + dykj * dykj);
          // Calculate cos using dot product definition.
          cosTheta = (dxij * dxkj + dyij * dykj) / (rij * rkj);
          if (cosTheta > 1.0) cosTheta = 1.0;
          else if (cosTheta < -1.0) cosTheta = -1.0;
          theta = Math.acos(cosTheta);

          // Finally, update PE.
          // radian
          angleDiff = theta - angularBondAngle[i];
          // angularBondStrength unit: eV/radian^2
          PE += 0.5 * angularBondStrength[i] * angleDiff * angleDiff;
        }

        // update PE for 'restraint' bonds
        for (i = 0; i < N_restraints; i++) {
          i1 = restraintAtomIndex[i];
          el1 = element[i1];

          dx = restraintX0[i] - x[i1];
          dy = restraintY0[i] - y[i1];
          r_sq = dx*dx + dy*dy;

          // eV/nm^2
          k = restraintK[i];

          // nm
          dr = Math.sqrt(r_sq);

          PE += 0.5*k*dr*dr;
       }

        // Process all obstacles.
        for (i = 0; i < N_obstacles; i++) {

          if (obstacleMass[i] !== Infinity) {
            // Gravitational potential energy.
            if (gravitationalField) {
              gravPEInMWUnits = obstacleMass[i] * gravitationalField * obstacleY[i];
              PE += constants.convert(gravPEInMWUnits, { from: unit.MW_ENERGY_UNIT, to: unit.EV });
            }
            // Kinetic energy.
            KEinMWUnits += 0.5 * obstacleMass[i] *
                (obstacleVX[i] * obstacleVX[i] + obstacleVY[i] * obstacleVY[i]);
          }
        }

        // Update temperature.
        T = convertKEtoT(KEinMWUnits, N);

        // State to be read by the rest of the system:
        state.time           = time;
        state.PE             = PE;
        state.KE             = constants.convert(KEinMWUnits, { from: unit.MW_ENERGY_UNIT, to: unit.EV });
        state.temperature    = T;
        state.pCM            = [px_CM, py_CM]; // TODO: GC optimization? New array created each time.
        state.CM             = [x_CM, y_CM];
        state.vCM            = [vx_CM, vy_CM];
        state.omega_CM       = omega_CM;
      },


      /**
        Given a test element and charge, returns a function that returns for a location (x, y) in nm:
         * the potential energy, in eV, of an atom of that element and charge at location (x, y)
         * optionally, if calculateGradient is true, the gradient of the potential as an
           array [gradX, gradY]. (units: eV/nm)
      */
      newPotentialCalculator: function(testElement, testCharge, calculateGradient) {

        return function(testX, testY) {
          var PE = 0,
              fx = 0,
              fy = 0,
              gradX,
              gradY,
              ljTest = ljCalculator[testElement],
              i,
              dx,
              dy,
              r_sq,
              r,
              f_over_r,
              lj;

          for (i = 0; i < N; i++) {
            dx = testX - x[i];
            dy = testY - y[i];
            r_sq = dx*dx + dy*dy;
            f_over_r = 0;

            if (useLennardJonesInteraction) {
              lj = ljTest[element[i]];
              PE += -lj.potentialFromSquaredDistance(r_sq, testElement, element[i]);
              if (calculateGradient) {
                f_over_r += lj.forceOverDistanceFromSquaredDistance(r_sq);
              }
            }

            if (useCoulombInteraction && hasChargedAtoms && testCharge) {
              r = Math.sqrt(r_sq);
              PE += -coulomb.potential(r, testCharge, charge[i], dielectricConst, realisticDielectricEffect);
              if (calculateGradient) {
                f_over_r += coulomb.forceOverDistanceFromSquaredDistance(r_sq, testCharge, charge[i],
                  dielectricConst, realisticDielectricEffect);
              }
            }

            if (f_over_r) {
              fx += f_over_r * dx;
              fy += f_over_r * dy;
            }
          }

          if (calculateGradient) {
            gradX = constants.convert(fx, { from: unit.MW_FORCE_UNIT, to: unit.EV_PER_NM });
            gradY = constants.convert(fy, { from: unit.MW_FORCE_UNIT, to: unit.EV_PER_NM });
            return [PE, [gradX, gradY]];
          }

          return PE;
        };
      },

      /**
        Starting at (x,y), try to find a position which minimizes the potential energy change caused
        by adding at atom of element el.
      */
      findMinimumPELocation: function(el, x, y, charge) {
        var pot    = engine.newPotentialCalculator(el, charge, true),
            radius = elementRadius[el],

            res =  math.minimize(pot, [x, y], {
              bounds: [ [radius, size[0]-radius], [radius, size[1]-radius] ]
            });

        if (res.error) return false;
        return res[1];
      },

      /**
        Starting at (x,y), try to find a position which minimizes the square of the potential energy
        change caused by adding at atom of element el, i.e., find a "farthest from everything"
        position.
      */
      findMinimumPESquaredLocation: function(el, x, y, charge) {
        var pot = engine.newPotentialCalculator(el, charge, true),

            // squared potential energy, with gradient
            potsq = function(x,y) {
              var res, f, grad;

              res = pot(x,y);
              f = res[0];
              grad = res[1];

              // chain rule
              grad[0] *= (2*f);
              grad[1] *= (2*f);

              return [f*f, grad];
            },

            radius = elementRadius[el],

            res = math.minimize(potsq, [x, y], {
              bounds: [ [radius, size[0]-radius], [radius, size[1]-radius] ],
              stopval: 1e-4,
              precision: 1e-6
            });

        if (res.error) return false;
        return res[1];
      },

      atomsInMolecule: [],
      depth: 0,

      /**
        Returns all atoms in the same molecule as atom i
        (not including i itself)
      */
      getMoleculeAtoms: function(i) {
        this.atomsInMolecule.push(i);

        var moleculeAtoms = [],
            bondedAtoms = this.getBondedAtoms(i),
            depth = this.depth,
            j, jj,
            atomNo;

        this.depth++;

        for (j=0, jj=bondedAtoms.length; j<jj; j++) {
          atomNo = bondedAtoms[j];
          if (!~this.atomsInMolecule.indexOf(atomNo)) {
            moleculeAtoms = moleculeAtoms.concat(this.getMoleculeAtoms(atomNo)); // recurse
          }
        }
        if (depth === 0) {
          this.depth = 0;
          this.atomsInMolecule = [];
        } else {
          moleculeAtoms.push(i);
        }
        return moleculeAtoms;
      },

      /**
        Returns all atoms directly bonded to atom i
      */
      getBondedAtoms: function(i) {
        var bondedAtoms = [],
            j, jj;
        if (radialBonds) {
          for (j = 0, jj = N_radialBonds; j < jj; j++) {
            // console.log("looking at bond from "+radialBonds)
            if (radialBondAtom1Index[j] === i) {
              bondedAtoms.push(radialBondAtom2Index[j]);
            }
            if (radialBondAtom2Index[j] === i) {
              bondedAtoms.push(radialBondAtom1Index[j]);
            }
          }
        }
        return bondedAtoms;
      },

      /**
        Returns Kinetic Energy of single atom i, in eV.
      */
      getAtomKineticEnergy: function(i) {
        var KEinMWUnits = 0.5 * mass[i] * (vx[i] * vx[i] + vy[i] * vy[i]);
        return constants.convert(KEinMWUnits, { from: unit.MW_ENERGY_UNIT, to: unit.EV });
      },

      getAtomNeighbors: function(idx) {
        var res = [],
            list = neighborList.getList(),
            i, len;

        for (i = neighborList.getStartIdxFor(idx), len = neighborList.getEndIdxFor(idx); i < len; i++) {
          res.push(list[i]);
        }
        return res;
      },

      getNeighborList: function () {
        return neighborList;
      },

      setViscosity: function(v) {
        viscosity = v;
      },

      // ######################################################################
      //                State definition of the engine

      // Return array of objects defining state of the engine.
      // Each object in this list should implement following interface:
      // * .clone()        - returning complete state of that object.
      // * .restore(state) - restoring state of the object, using 'state'
      //                     as input (returned by clone()).
      getState: function() {
        return [
          // Use wrapper providing clone-restore interface to save the hashes-of-arrays
          // that represent model state.
          new CloneRestoreWrapper(elements),
          new CloneRestoreWrapper(atoms),
          new CloneRestoreWrapper(obstacles),
          new CloneRestoreWrapper(radialBonds),
          new CloneRestoreWrapper(angularBonds),
          new CloneRestoreWrapper(restraints),
          new CloneRestoreWrapper(springForces),
          // PairwiseLJProperties class implements Clone-Restore Interface.
          pairwiseLJProperties,
          // Save time value.
          // Create one-line wrapper to provide required interface.
          {
            clone: function () {
              return time;
            },
            restore: function(state) {
              engine.setTime(state);
            }
          }
        ];
      }
    };

    // Initialization
    initialize();

    // Export initialized objects to Public API.
    // To ensure that client code always has access to these public properties,
    // they should be initialized  only once during the engine lifetime (in the initialize method).
    engine.pairwiseLJProperties = pairwiseLJProperties;
    engine.geneticProperties = geneticProperties;

    // Finally, return Public API.
    return engine;
  };
});

/*global define: false */
/*jslint onevar: true devel:true eqnull: true */

define('common/models/tick-history',[],function() {


  /**
    Class which handles tick history. It supports saving and restoring state
    of core state objects defined by the modeler and engine. However, while
    adding a new object which should also be saved in tick history, consider
    utilization of "external objects" - this is special object which should
    implement TickHistoryCompatible Interface:
      #setHistoryLength(number)
      #push()
      #extract(index)
      #invalidate(index)

      Note that index argument is *always* limited to [0, historyLength) range.

    "External objects" handle changes of the current step itself. TickHistory
    only sends requests to perform various operations. To register new
    external object use #registerExternalObject(object) method.

    It allows to decentralize management of tick history and tight coupling
    TickTistory with API of various objects.
  */
  return function TickHistory(modelState, model, size) {
    var tickHistory = {},
        initialState,
        list,
        listState,
        defaultSize = 1000,
        // List of objects defining TickHistoryCompatible Interface.
        externalObjects = [];

    function newState() {
      return { input: {}, state: [], parameters: {} };
    }

    function reset() {
      list = [];
      listState = {
        // Equal to list.length:
        length: 0,
        // Drop oldest state in order to keep list no longer than this:
        maxSize: size,
        // Index into `list` of the current state:
        index: -1,
        // Total length of "total history" (counting valid history states that have been dropped)
        counter: -1,
        // Index in "total history" of the oldest state in the list.
        // Invariant: counter == index + startCounter
        startCounter: 0
      };
    }

    function copyModelState(destination) {
      var i,
          prop,
          state,
          parameters,
          name;

      // save model input properties
      for (i = 0; i < modelState.input.length; i++) {
        prop = modelState.input[i];
        destination.input[prop] = model.get(prop);
      }

      // save model parameters
      parameters = modelState.parameters;
      for (name in parameters) {
        if (parameters.hasOwnProperty(name) && parameters[name].isDefined) {
          destination.parameters[name] = model.get(name);
        }
      }

      // save model objects defining state
      state = modelState.state;
      for (i = 0; i < state.length; i++) {
        destination.state[i] = state[i].clone();
      }
    }

    /** Copy the current model state into the list at list[listState.index+1] and updates listState.
        Removes any (now-invalid) states in the list that come after the newly pushed state.
    */
    function push() {
      var lastState = newState(),
          i;

      copyModelState(lastState);
      list[listState.index+1] = lastState;

      // Drop the oldest state if we went over the max list size
      if (list.length > listState.maxSize) {
        list.splice(0,1);
        listState.startCounter++;
      } else {
        listState.index++;
      }
      listState.counter = listState.index + listState.startCounter;

      // Send push request to external objects defining TickHistoryCompatible Interface.
      for (i = 0; i < externalObjects.length; i++) {
        externalObjects[i].push();
      }

      invalidateFollowingState();
      listState.length = list.length;
    }

    /** Invalidate (remove) all history after current index. For example, after seeking backwards
        and then pushing new state */
    function invalidateFollowingState() {
      var i;

      list.length = listState.index+1;
      listState.length = list.length;

      // Invalidate external objects defining TickHistoryCompatible Interface.
      for (i = 0; i < externalObjects.length; i++) {
        externalObjects[i].invalidate(listState.index);
      }
    }

    function extract(savedState) {
      var i,
          state;

      // restore model input properties
      modelState.restoreProperties(savedState.input);

      // restore parameters
      modelState.restoreParameters(savedState.parameters);

      // restore model objects defining state
      state = savedState.state;
      for (i = 0; i < state.length; i++) {
        modelState.state[i].restore(state[i]);
      }

      // Send extract request to external objects defining TickHistoryCompatible Interface.
      for (i = 0; i < externalObjects.length; i++) {
        externalObjects[i].extract(listState.index);
      }
    }

    function checkIndexArg(index) {
      if (index < 0) {
        throw new Error("TickHistory: extract index [" + index + "] less than 0");
      }
      if (index >= list.length) {
        throw new Error("TickHistory: extract index [" + index + "] greater than list.length: " + list.length);
      }
      return index;
    }

    //
    // Public methods
    //
    tickHistory.isEmpty = function() {
      return listState.index === 0;
    };

    tickHistory.push = function() {
      push();
    };

    tickHistory.returnTick = function(ptr) {
      var i;
      if (typeof ptr === 'number') {
        i = ptr;
      } else {
        i = listState.index;
      }
      checkIndexArg(i);
      return list[i];
    };

    tickHistory.extract = function(ptr) {
      var i;
      if (typeof ptr === 'number') {
        i = ptr;
      } else {
        i = listState.index;
      }
      checkIndexArg(i);
      extract(list[i]);
    };

    tickHistory.restoreInitialState = function() {
      reset();
      extract(initialState);
      push();
    };

    tickHistory.reset = reset;

    tickHistory.decrementExtract = function() {
      if (listState.counter > listState.startCounter) {
        listState.index--;
        listState.counter--;
        extract(list[listState.index]);
      }
    };

    tickHistory.incrementExtract = function() {
      listState.index++;
      listState.counter++;
      extract(list[listState.index]);
    };

    tickHistory.seekExtract = function(ptr) {
      if (ptr < listState.startCounter) ptr = listState.startCounter;
      if (ptr >= listState.startCounter + listState.length) ptr = listState.startCounter + listState.length - 1;
      listState.counter = ptr;
      listState.index = ptr - listState.startCounter;
      extract(list[listState.index]);
    };

    tickHistory.invalidateFollowingState = invalidateFollowingState;

    tickHistory.get = function(key) {
      return listState[key];
    };

    tickHistory.set = function(key, val) {
      return listState[key] = val;
    };

    /**
      Registers a new external object. It is a special object, which handles changes of step itself.
      TickHistory object only sends requests for various actions.
      External object should implement TickHistoryCompatible Interface:
        #setHistoryLength(number)
        #push()
        #extract(index)
        #invalidate(index)
    */
    tickHistory.registerExternalObject = function (externalObj) {
      externalObj.setHistoryLength(listState.maxSize);
      externalObjects.push(externalObj);
    };

    //
    // Initialization
    //
    if (size == null) size = defaultSize;
    initialState = newState();
    copyModelState(initialState);

    reset();
    push();
    return tickHistory;
  };
});

(function() {

  define('cs!md2d/models/running-average-filter',['require'],function(require) {
    /*
      Filter implementing running average.
      This filter assumes that provided samples are samples of some unknown function.
      The function is interpolated using linear interpolation. Later, integration is
      used to get mean value of the function on the given time period.
    */

    var RunningAverageFilter;
    return RunningAverageFilter = (function() {
      /*
          Construct new Running Average Filter.
          @periodLength - length of time period, in fs, which is used to calculate averaged value.
      */

      function RunningAverageFilter(periodLength) {
        this.periodLength = periodLength;
        this._value = [];
        this._time = [];
        this._idx = -1;
        this._maxBufferLength = this.periodLength;
      }

      /*
          Add a new sample of a function which is going to be averaged.
          Note that samples must be provided in order, sorted by time.
          @t - time
          @val - value of the sample
      */


      RunningAverageFilter.prototype.addSample = function(t, val) {
        var _results;
        if (this._time[this._idx] === t) {
          this._value[this._idx] = val;
          return;
        } else if (this._time[this._idx] > t) {
          throw new Error("RunningAverageFilter: cannot add sample with @_time less than previous sample.");
        }
        this._idx++;
        this._value.push(val);
        this._time.push(t);
        _results = [];
        while (this._value.length > this._maxBufferLength) {
          this._time.shift();
          this._value.shift();
          _results.push(this._idx--);
        }
        return _results;
      };

      /*
          Return averaged value n the specified time period (using available samples).
      */


      RunningAverageFilter.prototype.calculate = function() {
        var i, minTime, minVal, timeDiff, timeSum, valSum;
        minTime = Math.max(this._time[this._idx] - this.periodLength, 0);
        valSum = 0;
        timeSum = 0;
        i = this._idx;
        while (i > 0 && this._time[i - 1] >= minTime) {
          timeDiff = this._time[i] - this._time[i - 1];
          timeSum += timeDiff;
          valSum += timeDiff * (this._value[i - 1] + this._value[i]) / 2.0;
          i--;
        }
        if (i > 0 && this._time[i] > minTime && this._time[i - 1] < minTime) {
          timeDiff = this._time[i] - minTime;
          timeSum += timeDiff;
          minVal = this._value[i - 1] + (this._value[i] - this._value[i - 1]) * (minTime - this._time[i - 1]) / (this._time[i] - this._time[i - 1]);
          valSum += timeDiff * (this._value[i] + minVal) / 2.0;
        }
        if (timeSum) {
          return valSum / timeSum;
        } else {
          return this._value[0] || 0;
        }
      };

      /*
          Return current length of the buffers used to store samples.
      */


      RunningAverageFilter.prototype.getCurrentBufferLength = function() {
        return this._value.length;
      };

      /*
          Set limit of the buffer which stores samples.
      */


      RunningAverageFilter.prototype.setMaxBufferLength = function(maxLength) {
        return this._maxBufferLength = maxLength;
      };

      /*
          Return current time.
      */


      RunningAverageFilter.prototype.getCurrentTime = function() {
        return this._time[this._idx];
      };

      /*
          Return current step index.
      */


      RunningAverageFilter.prototype.getCurrentStep = function() {
        return this._idx;
      };

      /*
          Set current step to @location.
          It allows to get average value of the function in various moments in time.
      */


      RunningAverageFilter.prototype.setCurrentStep = function(location) {
        if (location < -1 || location >= this._value.length) {
          throw new Error("RunningAverageFilter: cannot seek, location outside available range.");
        }
        return this._idx = location;
      };

      /*
          Remove all samples *after* @location.
      */


      RunningAverageFilter.prototype.invalidate = function(location) {
        this._value.length = location + 1;
        return this._time.length = location + 1;
      };

      return RunningAverageFilter;

    })();
  });

}).call(this);

(function() {

  define('cs!md2d/models/solvent',['require'],function(require) {
    var Solvent, TYPES;
    TYPES = {
      vacuum: {
        forceType: 0,
        dielectricConstant: 1,
        color: "#eee"
      },
      oil: {
        forceType: -1,
        dielectricConstant: 10,
        color: "#f5f1dd"
      },
      water: {
        forceType: 1,
        dielectricConstant: 80,
        color: "#a5d9da"
      }
    };
    /*
      Simple class representing a solvent.
    */

    return Solvent = (function() {
      /*
          Constructs a new Solvent.
          @type is expected to be 'oil', 'water' or 'vacuum' string.
      */

      function Solvent(type) {
        var property, propsHash, value;
        this.type = type;
        propsHash = TYPES[this.type];
        if (!(propsHash != null)) {
          throw new Error("Solvent: unknown type. Use 'vacuum', 'oil' or 'water'.");
        }
        for (property in propsHash) {
          value = propsHash[property];
          this[property] = value;
        }
      }

      return Solvent;

    })();
  });

}).call(this);

/*global define: false, d3: false, $: false */
/*jslint onevar: true devel:true eqnull: true boss: true */

define('md2d/models/modeler',['require','arrays','common/console','md2d/models/engine/md2d','md2d/models/metadata','common/models/tick-history','cs!md2d/models/running-average-filter','cs!md2d/models/solvent','common/serialize','common/validator','md2d/models/aminoacids-props','cs!md2d/models/aminoacids-helper','md2d/models/engine/constants/units','underscore'],function(require) {
  // Dependencies.
  var arrays               = require('arrays'),
      console              = require('common/console'),
      md2d                 = require('md2d/models/engine/md2d'),
      metadata             = require('md2d/models/metadata'),
      TickHistory          = require('common/models/tick-history'),
      RunningAverageFilter = require('cs!md2d/models/running-average-filter'),
      Solvent              = require('cs!md2d/models/solvent'),
      serialize            = require('common/serialize'),
      validator            = require('common/validator'),
      aminoacids           = require('md2d/models/aminoacids-props'),
      aminoacidsHelper     = require('cs!md2d/models/aminoacids-helper'),
      units                = require('md2d/models/engine/constants/units'),
      _ = require('underscore');

  return function Model(initialProperties) {

    // all models created with this constructor will be of type: "md2d"
    this.constructor.type = "md2d";

    var model = {},
        dispatch = d3.dispatch("tick", "play", "stop", "reset", "stepForward", "stepBack",
                               "seek", "addAtom", "removeAtom", "addRadialBond", "removeRadialBond",
                               "removeAngularBond", "invalidation", "textBoxesChanged"),
        VDWLinesCutoffMap = {
          "short": 1.33,
          "medium": 1.67,
          "long": 2.0
        },
        defaultMaxTickHistory = 1000,
        stopped = true,
        restart = false,
        newStep = false,
        translationAnimInProgress = false,
        lastSampleTime,
        sampleTimes = [],

        modelOutputState,
        tickHistory,

        // Molecular Dynamics engine.
        engine,

        // An array of elements object.
        editableElements,

        // ######################### Main Data Structures #####################
        // They are initialized at the end of this function. These data strucutres
        // are mainly managed by the engine.

        // A hash of arrays consisting of arrays of atom property values
        atoms,

        // A hash of arrays consisting of arrays of element property values
        elements,

        // A hash of arrays consisting of arrays of obstacle property values
        obstacles,

        // A hash of arrays consisting of arrays of radial bond property values
        radialBonds,

        // A hash of arrays consisting of arrays of angular bond property values
        angularBonds,

        // A hash of arrays consisting of arrays of restraint property values
        // (currently atom-only)
        restraints,

        // ####################################################################

        // A two dimensional array consisting of atom index numbers and atom
        // property values - in effect transposed from the atom property arrays.
        results,

        // A two dimensional array consisting of radial bond index numbers, radial bond
        // properties, and the postions of the two bonded atoms.
        radialBondResults,

        // The index of the "spring force" used to implement dragging of atoms in a running model
        liveDragSpringForceIndex,

        // Cached value of the 'friction' property of the atom being dragged in a running model
        liveDragSavedFriction,

        listeners = {},

        properties = {
          /**
            These functions are optional setters that will be called *instead* of simply setting
            a value when 'model.set({property: value})' is called, and are currently needed if you
            want to pass a value through to the engine.  The function names are automatically
            determined from the property name. If you define one of these custom functions, you
            must remember to also set the property explicitly (if appropriate) as this won't be
            done automatically
          */

          set_targetTemperature: function(t) {
            this.targetTemperature = t;
            if (engine) {
              engine.setTargetTemperature(t);
            }
          },

          set_temperatureControl: function(tc) {
            this.temperatureControl = tc;
            if (engine) {
              engine.useThermostat(tc);
            }
          },

          set_lennardJonesForces: function(lj) {
            this.lennardJonesForces = lj;
            if (engine) {
              engine.useLennardJonesInteraction(lj);
            }
          },

          set_coulombForces: function(cf) {
            this.coulombForces = cf;
            if (engine) {
              engine.useCoulombInteraction(cf);
            }
          },

          set_solventForceType: function(s) {
            this.solventForceType = s;
            if (engine) {
              engine.setSolventForceType(s);
            }
          },

          set_solventForceFactor: function(s) {
            this.solventForceFactor = s;
            if (engine) {
              engine.setSolventForceFactor(s);
            }
          },

          set_additionalSolventForceMult: function(s) {
            this.additionalSolventForceMult = s;
            if (engine) {
              engine.setAdditionalSolventForceMult(s);
            }
          },

          set_additionalSolventForceThreshold: function(s) {
            this.additionalSolventForceThreshold = s;
            if (engine) {
              engine.setAdditionalSolventForceThreshold(s);
            }
          },

          set_dielectricConstant: function(dc) {
            this.dielectricConstant = dc;
            if (engine) {
              engine.setDielectricConstant(dc);
            }
          },

          set_realisticDielectricEffect: function (rdc) {
            this.realisticDielectricEffect = rdc;
            if (engine) {
              engine.setRealisticDielectricEffect(rdc);
            }
          },

          set_VDWLinesCutoff: function(cutoff) {
            var ratio;
            this.VDWLinesCutoff = cutoff;
            ratio = VDWLinesCutoffMap[cutoff];
            if (ratio && engine) {
              engine.setVDWLinesRatio(ratio);
            }
          },

          set_gravitationalField: function(gf) {
            this.gravitationalField = gf;
            if (engine) {
              engine.setGravitationalField(gf);
            }
          },

          set_modelSampleRate: function(rate) {
            this.modelSampleRate = rate;
            if (!stopped) model.restart();
          },

          set_timeStep: function(ts) {
            this.timeStep = ts;
          },

          set_viscosity: function(v) {
            this.viscosity = v;
            if (engine) {
              engine.setViscosity(v);
            }
          },

          set_polarAAEpsilon: function (e) {
            var polarAAs, element1, element2,
                i, j, len;

            this.polarAAEpsilon = e;

            if (engine) {
              // Set custom pairwise LJ properties for polar amino acids.
              // They should attract stronger to better mimic nature.
              polarAAs = aminoacidsHelper.getPolarAminoAcids();
              for (i = 0, len = polarAAs.length; i < len; i++) {
                element1 = polarAAs[i];
                for (j = i + 1; j < len; j++) {
                  element2 = polarAAs[j];
                  // Set custom pairwise LJ epsilon (default one for AA is -0.1).
                  engine.pairwiseLJProperties.set(element1, element2, {epsilon: e});
                }
              }
            }
          }
        },

        // The list of all 'output' properties (which change once per tick).
        outputNames = [],

        // Information about the description and calculating function for 'output' properties.
        outputsByName = {},

        // The subset of outputName list, containing list of outputs which are filtered
        // by one of the built-in filters (like running average filter).
        filteredOutputNames = [],

        // Function adding new sample for filtered outputs. Other properties of filtered output
        // are stored in outputsByName object, as filtered output is just extension of normal output.
        filteredOutputsByName = {},

        // The currently-defined parameters.
        parametersByName = {};

    function notifyPropertyListeners(listeners) {
      listeners = _.uniq(listeners);
      for (var i=0, ii=listeners.length; i<ii; i++){
        listeners[i]();
      }
    }

    function notifyPropertyListenersOfEvents(events) {
      var evt,
          evts,
          waitingToBeNotified = [],
          i, ii;

      if (typeof events === "string") {
        evts = [events];
      } else {
        evts = events;
      }
      for (i=0, ii=evts.length; i<ii; i++){
        evt = evts[i];
        if (listeners[evt]) {
          waitingToBeNotified = waitingToBeNotified.concat(listeners[evt]);
        }
      }
      if (listeners["all"]){      // listeners that want to be notified on any change
        waitingToBeNotified = waitingToBeNotified.concat(listeners["all"]);
      }
      notifyPropertyListeners(waitingToBeNotified);
    }

    /**
      Restores a set of "input" properties, notifying their listeners of only those properties which
      changed, and only after the whole set of properties has been updated.
    */
    function restoreProperties(savedProperties) {
      var property,
          changedProperties = [],
          savedValue;

      for (property in savedProperties) {
        if (savedProperties.hasOwnProperty(property)) {
          // skip read-only properties
          if (outputsByName[property]) {
            throw new Error("Attempt to restore output property \"" + property + "\".");
          }
          savedValue = savedProperties[property];
          if (properties[property] !== savedValue) {
            if (properties["set_"+property]) {
              properties["set_"+property](savedValue);
            } else {
              properties[property] = savedValue;
            }
            changedProperties.push(property);
          }
        }
      }
      notifyPropertyListenersOfEvents(changedProperties);
    }

    /**
      Restores a list of parameter values, notifying their listeners after the whole list is
      updated, and without triggering setters. Sets parameters not in the passed-in list to
      undefined.
    */
    function restoreParameters(savedParameters) {
      var parameterName,
          observersToNotify = [];

      for (parameterName in savedParameters) {
        if (savedParameters.hasOwnProperty(parameterName)) {
          // restore the property value if it was different or not defined in the current time step
          if (properties[parameterName] !== savedParameters[parameterName] || !parametersByName[parameterName].isDefined) {
            properties[parameterName] = savedParameters[parameterName];
            parametersByName[parameterName].isDefined = true;
            observersToNotify.push(parameterName);
          }
        }
      }

      // remove parameter values that aren't defined at this point in history
      for (parameterName in parametersByName) {
        if (parametersByName.hasOwnProperty(parameterName) && !savedParameters.hasOwnProperty(parameterName)) {
          parametersByName[parameterName].isDefined = false;
          properties[parameterName] = undefined;
        }
      }

      notifyPropertyListenersOfEvents(observersToNotify);
    }

    function average_speed() {
      var i, s = 0, n = model.get_num_atoms();
      i = -1; while (++i < n) { s += engine.atoms.speed[i]; }
      return s/n;
    }

    function tick(elapsedTime, dontDispatchTickEvent) {
      var timeStep = model.get('timeStep'),
          // Save number of radial bonds in engine before integration,
          // as integration can create new disulfide bonds. This is the
          // only type of objects which can be created by the engine autmatically.
          prevNumOfRadialBonds = engine.getNumberOfRadialBonds(),
          t, sampleTime;

      if (!stopped) {
        t = Date.now();
        if (lastSampleTime) {
          sampleTime = t - lastSampleTime;
          sampleTimes.push(sampleTime);
          sampleTimes.splice(0, sampleTimes.length - 128);
        } else {
          lastSampleTime = t;
        }
      }

      // viewRefreshInterval is defined in Classic MW as the number of timesteps per view update.
      // However, in MD2D we prefer the more physical notion of integrating for a particular
      // length of time.
      console.time('integration');
      engine.integrate(model.get('viewRefreshInterval') * timeStep, timeStep);
      console.timeEnd('integration');
      console.time('reading model state');
      updateAllOutputProperties();
      console.timeEnd('reading model state');

      console.time('tick history push');
      tickHistory.push();
      console.timeEnd('tick history push');

      newStep = true;

      if (!dontDispatchTickEvent) {
        dispatch.tick();
      }

      if (prevNumOfRadialBonds < engine.getNumberOfRadialBonds()) {
        dispatch.addRadialBond();
      }

      return stopped;
    }

    function average_rate() {
      var i, ave, s = 0, n = sampleTimes.length;
      i = -1; while (++i < n) { s += sampleTimes[i]; }
      ave = s/n;
      return (ave ? 1/ave*1000: 0);
    }

    function set_properties(hash) {
      var property, propsChanged = [];
      for (property in hash) {
        if (hash.hasOwnProperty(property) && hash[property] !== undefined && hash[property] !== null) {
          // skip read-only properties
          if (outputsByName[property]) {
            throw new Error("Attempt to set read-only output property \"" + property + "\".");
          }
          // look for set method first, otherwise just set the property
          if (properties["set_"+property]) {
            properties["set_"+property](hash[property]);
          // why was the property not set if the default value property is false ??
          // } else if (properties[property]) {
          } else {
            properties[property] = hash[property];
          }
          propsChanged.push(property);
        }
      }
      notifyPropertyListenersOfEvents(propsChanged);
    }

    /**
      Call this method after moving to a different model time (e.g., after stepping the model
      forward or back, seeking to a different time, or on model initialization) to update all output
      properties and notify their listeners. This method is more efficient for that case than
      updateOutputPropertiesAfterChange because it can assume that all output properties are
      invalidated by the model step. It therefore does not need to calculate any output property
      values; it allows them to be evaluated lazily instead. Property values are calculated when and
      if listeners request them. This method also guarantees that all properties have their updated
      value when they are requested by any listener.

      Technically, this method first updates the 'results' array and macrostate variables, then
      invalidates any  cached output-property values, and finally notifies all output-property
      listeners.

      Note that this method and updateOutputPropertiesAfterChange are the only methods which can
      flush the cached value of an output property. Therefore, be sure to not to make changes
      which would invalidate a cached value without also calling one of these two methods.
    */
    function updateAllOutputProperties() {
      var i, j, l;

      readModelState();

      // invalidate all cached values before notifying any listeners
      for (i = 0; i < outputNames.length; i++) {
        outputsByName[outputNames[i]].hasCachedValue = false;
      }

      // Update all filtered outputs.
      // Note that this have to be performed after invalidation of all outputs
      // (as filtered output can filter another output), but before notifying
      // listeners (as we want to provide current, valid value).
      for (i = 0; i < filteredOutputNames.length; i++) {
        filteredOutputsByName[filteredOutputNames[i]].addSample();
      }

      for (i = 0; i < outputNames.length; i++) {
        if (l = listeners[outputNames[i]]) {
          for (j = 0; j < l.length; j++) {
            l[j]();
          }
        }
      }
    }

    /**
      ALWAYS CALL THIS FUNCTION before any change to model state outside a model step
      (i.e., outside a tick, seek, stepForward, stepBack)

      Note:  Changes to view-only property changes that cannot change model physics might reasonably
      by considered non-invalidating changes that don't require calling this hook.
    */
    function invalidatingChangePreHook() {
      storeOutputPropertiesBeforeChange();
    }

    /**
      ALWAYS CALL THIS FUNCTION after any change to model state outside a model step.
    */
    function invalidatingChangePostHook() {
      updateOutputPropertiesAfterChange();
      if (tickHistory) tickHistory.invalidateFollowingState();
      dispatch.invalidation();
    }

    /**
      Call this method *before* changing any "universe" property or model property (including any
      property of a model object such as the position of an atom) to save the output-property
      values before the change. This is required to enabled updateOutputPropertiesAfterChange to be
      able to detect property value changes.

      After the change is made, call updateOutputPropertiesAfterChange to notify listeners.
    */
    function storeOutputPropertiesBeforeChange() {
      var i, outputName, output, l;

      for (i = 0; i < outputNames.length; i++) {
        outputName = outputNames[i];
        if ((l = listeners[outputName]) && l.length > 0) {
          output = outputsByName[outputName];
          // Can't save previous value in output.cachedValue because, before we check it, the
          // cachedValue may be overwritten with an updated value as a side effect of the
          // calculation of the updated value of some other property
          output.previousValue = output.hasCachedValue ? output.cachedValue : output.calculate();
        }
      }
    }

    /**
      Before changing any "universe" property or model property (including any
      property of a model object such as the position of an atom), call the method
      storeOutputPropertiesBeforeChange; after changing the property, call this method  to detect
      changed output-property values and to notify listeners of the output properties which have
      changed. (However, don't call either method after a model tick or step;
      updateAllOutputProperties is more efficient for that case.)
    */
    function updateOutputPropertiesAfterChange() {
      var i, j, output, outputName, l, listenersToNotify = [];

      readModelState();

      // Mark _all_ cached values invalid ... we're not going to be checking the values of the
      // unobserved properties, so we have to assume their value changed.
      for (i = 0; i < outputNames.length; i++) {
        output = outputsByName[outputNames[i]];
        output.hasCachedValue = false;
      }

      // Update all filtered outputs.
      // Note that this have to be performed after invalidation of all outputs
      // (as filtered output can filter another output).
      for (i = 0; i < filteredOutputNames.length; i++) {
        filteredOutputsByName[filteredOutputNames[i]].addSample();
      }

      // Keep a list of output properties that are being observed and which changed ... and
      // cache the updated values while we're at it
      for (i = 0; i < outputNames.length; i++) {
        outputName = outputNames[i];
        output = outputsByName[outputName];

        if ((l = listeners[outputName]) && l.length > 0) {
          // Though we invalidated all cached values above, nevertheless some outputs may have been
          // computed & cached during a previous pass through this loop, as a side effect of the
          // calculation of some other property. Therefore we can respect hasCachedValue here.
          if (!output.hasCachedValue) {
            output.cachedValue = output.calculate();
            output.hasCachedValue = true;
          }

          if (output.cachedValue !== output.previousValue) {
            for (j = 0; j < l.length; j++) {
              listenersToNotify.push(l[j]);
            }
          }
        }
        // Now that we're done with it, allow previousValue to be GC'd. (Of course, since we're
        // using an equality test to check for changes, it doesn't make sense to let outputs be
        // objects or arrays, yet)
        output.previousValue = null;
      }

      // Finally, now that all the changed properties have been cached, notify listeners
      for (i = 0; i < listenersToNotify.length; i++) {
        listenersToNotify[i]();
      }
    }

    /**
      This method is called to refresh the results array and macrostate variables (KE, PE,
      temperature) whenever an engine integration occurs or the model state is otherwise changed.

      Normally, you should call the methods updateOutputPropertiesAfterChange or
      updateAllOutputProperties rather than calling this method. Calling this method directly does
      not cause output-property listeners to be notified, and calling it prematurely will confuse
      the detection of changed properties.
    */
    function readModelState() {
      var i, prop, n, amino;

      engine.computeOutputState(modelOutputState);

      extendResultsArray();

      // Transpose 'atoms' object into 'results' for easier consumption by view code
      for (i = 0, n = model.get_num_atoms(); i < n; i++) {
        for (prop in atoms) {
          if (atoms.hasOwnProperty(prop)) {
            results[i][prop] = atoms[prop][i];
          }
        }

        // Additional properties, used only by view.
        if (aminoacidsHelper.isAminoAcid(atoms.element[i])) {
          amino = aminoacidsHelper.getAminoAcidByElement(atoms.element[i]);
          results[i].symbol = amino.symbol;
          results[i].label = amino.abbreviation;
        }
      }
    }

    /**
      Ensure that the 'results' array of arrays is defined and contains one typed array per atom
      for containing the atom properties.
    */
    function extendResultsArray() {
      var isAminoAcid = function () {
            return aminoacidsHelper.isAminoAcid(this.element);
          },
          i, len;

      // TODO: refactor whole approach to creation of objects from flat arrays.
      // Think about more general way of detecting and representing amino acids.
      // However it would be reasonable to perform such refactoring later, when all requirements
      // related to proteins engine are clearer.

      if (!results) results = [];

      for (i = results.length, len = model.get_num_atoms(); i < len; i++) {
        if (!results[i]) {
          results[i] = {
            idx: i,
            // Provide convenience function for view, do not force it to ask
            // model / engine directly. In the future, atom objects should be
            // represented by a separate class.
            isAminoAcid: isAminoAcid
          };
        }
      }
    }

    /**
      Create set of amino acids elements. Use descriptions
      provided in 'aminoacids' array.
    */
    function createAminoAcids() {
      var sigmaIn01Angstroms,
          sigmaInNm,
          i, len;

      // Note that amino acids ALWAYS have IDs from
      // AMINO_ELEMENT_FIRST_IDX (= 5) to AMINO_ELEMENT_LAST_IDX (= 24).
      // This is enforced by backward compatibility with Classic MW.

      // At the beginning, ensure that elements from 0 to 24 exists.
      for (i = engine.getNumberOfElements(); i <= aminoacidsHelper.lastElementID; i++) {
        model.addElement({
          id: i
        });
      }

      // Set amino acids properties using elements from 5 to 24.
      for (i = 0, len = aminoacids.length; i < len; i++) {
        // Note that sigma is calculated using Classic MW approach.
        // See: org.concord.mw2d.models.AminoAcidAdapter
        // Basic length unit in Classic MW is 0.1 Angstrom.
        sigmaIn01Angstroms = 18 * Math.pow(aminoacids[i].volume / aminoacids[0].volume, 0.3333333333333);
        sigmaInNm = units.convert(sigmaIn01Angstroms / 10, { from: units.unit.ANGSTROM, to: units.unit.NANOMETER });
        // Use engine's method instead of modeler's method to avoid validation.
        // Modeler's wrapper ensures that amino acid is immutable, so it won't allow
        // to set properties of amino acid.
        engine.setElementProperties(aminoacidsHelper.firstElementID + i, {
          mass: aminoacids[i].molWeight,
          sigma: sigmaInNm
          // Don't provide epsilon, as default value should be used.
          // Classic MW uses epsilon 0.1 for all amino acids, which is default one.
          // See: org.concord.mw2d.models.AtomicModel.resetElements()
        });
      }
    }

    // ------------------------------------------------------------
    //
    // Public functions
    //
    // ------------------------------------------------------------

    model.getStats = function() {
      return {
        time        : model.get('time'),
        speed       : average_speed(),
        ke          : model.get('kineticEnergy'),
        temperature : model.get('temperature'),
        current_step: tickHistory.get("counter"),
        steps       : tickHistory.get("length")-1
      };
    };

    // A convenience for interactively getting energy averages
    model.getStatsHistory = function(num) {
      var i, len, start,
          tick,
          ke, pe,
          ret = [];

      len = tickHistory.get("length");
      if (!arguments.length) {
        start = 0;
      } else {
        start = Math.max(len-num, 0);
      }
      ret.push("time (fs)\ttotal PE (eV)\ttotal KE (eV)\ttotal energy (eV)");

      for (i = start; i < len; i++) {
        tick = tickHistory.returnTick(i);
        pe = tick.output.PE;
        ke = tick.output.KE;
        ret.push(tick.output.time + "\t" + pe + "\t" + ke + "\t" + (pe+ke));
      }
      return ret.join('\n');
    };

    /**
      Current seek position
    */
    model.stepCounter = function() {
      return tickHistory.get("counter");
    };

    /**
      Current position of first value in tick history, normally this will be 0.
      This will be greater than 0 if maximum size of tick history has been exceeded.
    */
    model.stepStartCounter = function() {
      return tickHistory.get("startCounter");
    };

    /** Total number of ticks that have been run & are stored, regardless of seek
        position
    */
    model.steps = function() {
      return tickHistory.get("length");
    };

    model.isNewStep = function() {
      return newStep;
    };

    model.seek = function(location) {
      if (!arguments.length) { location = 0; }
      stopped = true;
      newStep = false;
      tickHistory.seekExtract(location);
      updateAllOutputProperties();
      dispatch.seek();
      return tickHistory.get("counter");
    };

    model.stepBack = function(num) {
      if (!arguments.length) { num = 1; }
      var i, index;
      stopped = true;
      newStep = false;
      i=-1; while(++i < num) {
        index = tickHistory.get("index");
        if (index > 0) {
          tickHistory.decrementExtract();
          updateAllOutputProperties();
          dispatch.stepBack();
        }
      }
      return tickHistory.get("counter");
    };

    model.stepForward = function(num) {
      if (!arguments.length) { num = 1; }
      var i, index, size;
      stopped = true;
      i=-1; while(++i < num) {
        index = tickHistory.get("index");
        size = tickHistory.get("length");
        if (index < size-1) {
          tickHistory.incrementExtract();
          updateAllOutputProperties();
          dispatch.stepForward();
        } else {
          tick();
        }
      }
      return tickHistory.get("counter");
    };

    /**
      Creates a new md2d engine and leaves it in 'engine'.
    */
    model.initializeEngine = function () {
      engine = md2d.createEngine();

      engine.setSize([model.get('width'), model.get('height')]);
      engine.useLennardJonesInteraction(model.get('lennardJonesForces'));
      engine.useCoulombInteraction(model.get('coulombForces'));
      engine.useThermostat(model.get('temperatureControl'));
      engine.setViscosity(model.get('viscosity'));
      engine.setVDWLinesRatio(VDWLinesCutoffMap[model.get('VDWLinesCutoff')]);
      engine.setGravitationalField(model.get('gravitationalField'));
      engine.setTargetTemperature(model.get('targetTemperature'));
      engine.setDielectricConstant(model.get('dielectricConstant'));
      engine.setRealisticDielectricEffect(model.get('realisticDielectricEffect'));
      engine.setSolventForceType(model.get('solventForceType'));
      engine.setSolventForceFactor(model.get('solventForceFactor'));
      engine.setAdditionalSolventForceMult(model.get('additionalSolventForceMult'));
      engine.setAdditionalSolventForceThreshold(model.get('additionalSolventForceThreshold'));

      // Register invalidating change hooks.
      // pairwiseLJProperties object allows to change state which defines state of the whole simulation.
      engine.pairwiseLJProperties.registerChangeHooks(invalidatingChangePreHook, invalidatingChangePostHook);
      engine.geneticProperties.registerChangeHooks(invalidatingChangePreHook, invalidatingChangePostHook);

      window.state = modelOutputState = {};

      // Copy reference to basic properties.
      atoms = engine.atoms;
      elements = engine.elements;
      radialBonds = engine.radialBonds;
      radialBondResults = engine.radialBondResults;
      angularBonds = engine.angularBonds;
      restraints = engine.restraints;
      obstacles = engine.obstacles;
    };

    model.createElements = function(_elements) {
      // Options for addElement method.
      var options = {
        // Deserialization process, invalidating change hooks will be called manually.
        deserialization: true
      },
      i, num, prop, elementProps;

      // Call the hook manually, as addElement won't do it due to
      // deserialization option set to true.
      invalidatingChangePreHook();

      if (_elements === undefined) {
        // Special case when elements are not defined.
        // Empty object will be filled with default values.
        model.addElement({id: 0}, options);
        return;
      }

      // _elements is hash of arrays (as specified in JSON model).
      // So, for each index, create object containing properties of
      // element 'i'. Later, use these properties to add element
      // using basic addElement method.
      for (i = 0, num = _elements.mass.length; i < num; i++) {
        elementProps = {};
        for (prop in _elements) {
          if (_elements.hasOwnProperty(prop)) {
            elementProps[prop] = _elements[prop][i];
          }
        }
        model.addElement(elementProps, options);
      }

      // Call the hook manually, as addRadialBond won't do it due to
      // deserialization option set to true.
      invalidatingChangePostHook();

      return model;
    };

    /**
      Creates a new set of atoms, but new engine is created at the beginning.
      TODO: this method makes no sense. Objects like obstacles, restraints etc.,
      will be lost. It's confusing and used *only* in tests for now.
      Think about API change. Probably the best option would be to just create new
      modeler each time using constructor.

      @config: either the number of atoms (for a random setup) or
               a hash specifying the x,y,vx,vy properties of the atoms
      When random setup is used, the option 'relax' determines whether the model is requested to
      relax to a steady-state temperature (and in effect gets thermalized). If false, the atoms are
      left in whatever grid the engine's initialization leaves them in.
    */
    model.createNewAtoms = function(config) {
      model.initializeEngine();
      model.createElements(editableElements);
      model.createAtoms(config);

      return model;
    };

    /**
      Creates a new set of atoms.

      @config: either the number of atoms (for a random setup) or
               a hash specifying the x,y,vx,vy properties of the atoms
      When random setup is used, the option 'relax' determines whether the model is requested to
      relax to a steady-state temperature (and in effect gets thermalized). If false, the atoms are
      left in whatever grid the engine's initialization leaves them in.
    */
    model.createAtoms = function(config) {
          // Options for addAtom method.
      var options = {
            // Do not check the position of atom, assume that it's valid.
            supressCheck: true,
            // Deserialization process, invalidating change hooks will be called manually.
            deserialization: true
          },
          i, num, prop, atomProps;

      // Call the hook manually, as addAtom won't do it due to
      // deserialization option set to true.
      invalidatingChangePreHook();

      if (typeof config === 'number') {
        num = config;
      } else if (config.num != null) {
        num = config.num;
      } else if (config.x) {
        num = config.x.length;
      }

      // TODO: this branching based on x, y isn't very clear.
      if (config.x && config.y) {
        // config is hash of arrays (as specified in JSON model).
        // So, for each index, create object containing properties of
        // atom 'i'. Later, use these properties to add atom
        // using basic addAtom method.
        for (i = 0; i < num; i++) {
          atomProps = {};
          for (prop in config) {
            if (config.hasOwnProperty(prop)) {
              atomProps[prop] = config[prop][i];
            }
          }
          model.addAtom(atomProps, options);
        }
      } else {
        for (i = 0; i < num; i++) {
          // Provide only required values.
          atomProps = {x: 0, y: 0};
          model.addAtom(atomProps, options);
        }
        // This function rearrange all atoms randomly.
        engine.setupAtomsRandomly({
          temperature: model.get('targetTemperature'),
          // Provide number of user-defined, editable elements.
          // There is at least one default element, even if no elements are specified in JSON.
          userElements: editableElements === undefined ? 1 : editableElements.mass.length
        });
        if (config.relax)
          engine.relaxToTemperature();
      }

      // Call the hook manually, as addAtom won't do it due to
      // deserialization option set to true.
      invalidatingChangePostHook();

      // Listeners should consider resetting the atoms a 'reset' event
      dispatch.reset();

      // return model, for chaining (if used)
      return model;
    };

    model.createRadialBonds = function(_radialBonds) {
          // Options for addRadialBond method.
      var options = {
            // Deserialization process, invalidating change hooks will be called manually.
            deserialization: true
          },
          num = _radialBonds.strength.length,
          i, prop, radialBondProps;

      // Call the hook manually, as addRadialBond won't do it due to
      // deserialization option set to true.
      invalidatingChangePreHook();

      // _radialBonds is hash of arrays (as specified in JSON model).
      // So, for each index, create object containing properties of
      // radial bond 'i'. Later, use these properties to add radial bond
      // using basic addRadialBond method.
      for (i = 0; i < num; i++) {
        radialBondProps = {};
        for (prop in _radialBonds) {
          if (_radialBonds.hasOwnProperty(prop)) {
            radialBondProps[prop] = _radialBonds[prop][i];
          }
        }
        model.addRadialBond(radialBondProps, options);
      }

      // Call the hook manually, as addRadialBond won't do it due to
      // deserialization option set to true.
      invalidatingChangePostHook();

      return model;
    };

    model.createAngularBonds = function(_angularBonds) {
          // Options for addAngularBond method.
      var options = {
            // Deserialization process, invalidating change hooks will be called manually.
            deserialization: true
          },
          num = _angularBonds.strength.length,
          i, prop, angularBondProps;

      // Call the hook manually, as addAngularBond won't do it due to
      // deserialization option set to true.
      invalidatingChangePreHook();

      // _angularBonds is hash of arrays (as specified in JSON model).
      // So, for each index, create object containing properties of
      // angular bond 'i'. Later, use these properties to add angular bond
      // using basic addAngularBond method.
      for (i = 0; i < num; i++) {
        angularBondProps = {};
        for (prop in _angularBonds) {
          if (_angularBonds.hasOwnProperty(prop)) {
            angularBondProps[prop] = _angularBonds[prop][i];
          }
        }
        model.addAngularBond(angularBondProps, options);
      }

      // Call the hook manually, as addRadialBond won't do it due to
      // deserialization option set to true.
      invalidatingChangePostHook();

      return model;
    };

    model.createRestraints = function(_restraints) {
      var num = _restraints.atomIndex.length,
          i, prop, restraintsProps;

      // _restraints is hash of arrays (as specified in JSON model).
      // So, for each index, create object containing properties of
      // restraint 'i'. Later, use these properties to add restraint
      // using basic addRestraint method.
      for (i = 0; i < num; i++) {
        restraintsProps = {};
        for (prop in _restraints) {
          if (_restraints.hasOwnProperty(prop)) {
            restraintsProps[prop] = _restraints[prop][i];
          }
        }
        model.addRestraint(restraintsProps);
      }

      return model;
    };

    model.createObstacles = function(_obstacles) {
      var numObstacles = _obstacles.x.length,
          i, prop, obstacleProps;

      // _obstacles is hash of arrays (as specified in JSON model).
      // So, for each index, create object containing properties of
      // obstacle 'i'. Later, use these properties to add obstacle
      // using basic addObstacle method.
      for (i = 0; i < numObstacles; i++) {
        obstacleProps = {};
        for (prop in _obstacles) {
          if (_obstacles.hasOwnProperty(prop)) {
            obstacleProps[prop] = _obstacles[prop][i];
          }
        }
        model.addObstacle(obstacleProps);
      }

      return model;
    };

    model.reset = function() {
      model.resetTime();
      tickHistory.restoreInitialState();
      dispatch.reset();
    };

    model.resetTime = function() {
      engine.setTime(0);
    };

    model.getTotalMass = function() {
      return engine.getTotalMass();
    };

    model.getAtomKineticEnergy = function(i) {
      return engine.getAtomKineticEnergy(i);
    };

    /**
      Attempts to add an 0-velocity atom to a random location. Returns false if after 10 tries it
      can't find a location. (Intended to be exposed as a script API method.)

      Optionally allows specifying the element (default is to randomly select from all editableElements) and
      charge (default is neutral).
    */
    model.addRandomAtom = function(el, charge) {
      if (el == null) el = Math.floor( Math.random() * elements.mass.length );
      if (charge == null) charge = 0;

      var size   = model.size(),
          radius = engine.getRadiusOfElement(el),
          x,
          y,
          loc,
          numTries = 0,
          // try at most ten times.
          maxTries = 10;

      do {
        x = Math.random() * size[0] - 2*radius;
        y = Math.random() * size[1] - 2*radius;

        // findMinimimuPELocation will return false if minimization doesn't converge, in which case
        // try again from a different x, y
        loc = engine.findMinimumPELocation(el, x, y, 0, 0, charge);
        if (loc && model.addAtom({ element: el, x: loc[0], y: loc[1], charge: charge })) return true;
      } while (++numTries < maxTries);

      return false;
    },

    /**
      Adds a new atom defined by properties.
      Intended to be exposed as a script API method also.

      Adjusts (x,y) if needed so that the whole atom is within the walls of the container.

      Returns false and does not add the atom if the potential energy change of adding an *uncharged*
      atom of the specified element to the specified location would be positive (i.e, if the atom
      intrudes into the repulsive region of another atom.)

      Otherwise, returns true.

      silent = true disables this check.
    */
    model.addAtom = function(props, options) {
      var size = model.size(),
          radius;

      options = options || {};

      // Validate properties, provide default values.
      props = validator.validateCompleteness(metadata.atom, props);

      // As a convenience to script authors, bump the atom within bounds
      radius = engine.getRadiusOfElement(props.element);
      if (props.x < radius) props.x = radius;
      if (props.x > size[0] - radius) props.x = size[0] - radius;
      if (props.y < radius) props.y = radius;
      if (props.y > size[1] - radius) props.y = size[1] - radius;

      // check the potential energy change caused by adding an *uncharged* atom at (x,y)
      if (!options.supressCheck && !engine.canPlaceAtom(props.element, props.x, props.y)) {
        // return false on failure
        return false;
      }

      // When atoms are being deserialized, the deserializing function
      // should handle change hooks due to performance reasons.
      if (!options.deserialization)
        invalidatingChangePreHook();
      engine.addAtom(props);
      if (!options.deserialization)
        invalidatingChangePostHook();

      if (!options.supressEvent) {
        dispatch.addAtom();
      }

      return true;
    },

    model.removeAtom = function(i, options) {
      var prevRadBondsCount = engine.getNumberOfRadialBonds(),
          prevAngBondsCount = engine.getNumberOfAngularBonds();

      options = options || {};

      invalidatingChangePreHook();
      engine.removeAtom(i);
      // Enforce modeler to recalculate results array.
      results.length = 0;
      invalidatingChangePostHook();

      if (!options.supressEvent) {
        // Notify listeners that atoms is removed.
        dispatch.removeAtom();

        // Removing of an atom can also cause removing of
        // the connected radial bond. Detect it and notify listeners.
        if (engine.getNumberOfRadialBonds() !== prevRadBondsCount) {
          dispatch.removeRadialBond();
        }
        if (engine.getNumberOfAngularBonds() !== prevAngBondsCount) {
          dispatch.removeAngularBond();
        }
      }
    },

    model.addElement = function(props) {
      // Validate properties, use default values if there is such need.
      props = validator.validateCompleteness(metadata.element, props);
      // Finally, add radial bond.
      engine.addElement(props);
    };

    model.addObstacle = function(props) {
      var validatedProps;

      if (props.color !== undefined && props.colorR === undefined) {
        // Convert color definition.
        // Both forms are supported:
        //   color: [ 128, 128, 255 ]
        // or
        //   colorR: 128,
        //   colorB: 128,
        //   colorG: 255
        props.colorR = props.color[0];
        props.colorG = props.color[1];
        props.colorB = props.color[2];
      }
      // Validate properties, use default values if there is such need.
      validatedProps = validator.validateCompleteness(metadata.obstacle, props);
      // Finally, add obstacle.
      invalidatingChangePreHook();
      engine.addObstacle(validatedProps);
      invalidatingChangePostHook();
    };

    model.removeObstacle = function (idx) {
      invalidatingChangePreHook();
      engine.removeObstacle(idx);
      invalidatingChangePostHook();
    };

    model.addRadialBond = function(props, options) {
      // Validate properties, use default values if there is such need.
      props = validator.validateCompleteness(metadata.radialBond, props);

      // During deserialization change hooks are managed manually.
      if (!options || !options.deserialization)
        invalidatingChangePreHook();

      // Finally, add radial bond.
      engine.addRadialBond(props);

      if (!options || !options.deserialization)
        invalidatingChangePostHook();

      dispatch.addRadialBond();
    },

    model.removeRadialBond = function(idx) {
      invalidatingChangePreHook();
      engine.removeRadialBond(idx);
      invalidatingChangePreHook();
      dispatch.removeRadialBond();
    };

    model.addAngularBond = function(props, options) {
      // Validate properties, use default values if there is such need.
      props = validator.validateCompleteness(metadata.angularBond, props);

      // During deserialization change hooks are managed manually.
      if (!options || !options.deserialization)
        invalidatingChangePreHook();

      // Finally, add angular bond.
      engine.addAngularBond(props);

      if (!options || !options.deserialization)
        invalidatingChangePostHook();
    };

    model.removeAngularBond = function(idx) {
      invalidatingChangePreHook();
      engine.removeAngularBond(idx);
      invalidatingChangePostHook();
      dispatch.removeAngularBond();
    };

    model.addRestraint = function(props) {
      // Validate properties, use default values if there is such need.
      props = validator.validateCompleteness(metadata.restraint, props);
      // Finally, add restraint.
      invalidatingChangePreHook();
      engine.addRestraint(props);
      invalidatingChangePostHook();
    };

    /** Return the bounding box of the molecule containing atom 'atomIndex', with atomic radii taken
        into account.

       @returns an object with properties 'left', 'right', 'top', and 'bottom'. These are translated
       relative to the center of atom 'atomIndex', so that 'left' represents (-) the distance in nm
       between the leftmost edge and the center of atom 'atomIndex'.
    */
    model.getMoleculeBoundingBox = function(atomIndex) {

      var moleculeAtoms,
          i,
          x,
          y,
          r,
          top = -Infinity,
          left = Infinity,
          bottom = Infinity,
          right = -Infinity,
          cx,
          cy;

      moleculeAtoms = engine.getMoleculeAtoms(atomIndex);
      moleculeAtoms.push(atomIndex);

      for (i = 0; i < moleculeAtoms.length; i++) {
        x = atoms.x[moleculeAtoms[i]];
        y = atoms.y[moleculeAtoms[i]];
        r = atoms.radius[moleculeAtoms[i]];

        if (x-r < left  ) left   = x-r;
        if (x+r > right ) right  = x+r;
        if (y-r < bottom) bottom = y-r;
        if (y+r > top   ) top    = y+r;
      }

      cx = atoms.x[atomIndex];
      cy = atoms.y[atomIndex];

      return { top: top-cy, left: left-cx, bottom: bottom-cy, right: right-cx };
    },

    /**
        A generic method to set properties on a single existing atom.

        Example: setAtomProperties(3, {x: 5, y: 8, px: 0.5, charge: -1})

        This can optionally check the new location of the atom to see if it would
        overlap with another another atom (i.e. if it would increase the PE).

        This can also optionally apply the same dx, dy to any atoms in the same
        molecule (if x and y are being changed), and check the location of all
        the bonded atoms together.
      */
    model.setAtomProperties = function(i, props, checkLocation, moveMolecule) {
      var moleculeAtoms,
          dx, dy,
          new_x, new_y,
          j, jj;

      // Validate properties.
      props = validator.validate(metadata.atom, props);

      if (moveMolecule) {
        moleculeAtoms = engine.getMoleculeAtoms(i);
        if (moleculeAtoms.length > 0) {
          dx = typeof props.x === "number" ? props.x - atoms.x[i] : 0;
          dy = typeof props.y === "number" ? props.y - atoms.y[i] : 0;
          for (j = 0, jj=moleculeAtoms.length; j<jj; j++) {
            new_x = atoms.x[moleculeAtoms[j]] + dx;
            new_y = atoms.y[moleculeAtoms[j]] + dy;
            if (!model.setAtomProperties(moleculeAtoms[j], {x: new_x, y: new_y}, checkLocation, false)) {
              return false;
            }
          }
        }
      }

      if (checkLocation) {
        var x  = typeof props.x === "number" ? props.x : atoms.x[i],
            y  = typeof props.y === "number" ? props.y : atoms.y[i],
            el = typeof props.element === "number" ? props.y : atoms.element[i];

        if (!engine.canPlaceAtom(el, x, y, i)) {
          return false;
        }
      }

      invalidatingChangePreHook();
      engine.setAtomProperties(i, props);
      invalidatingChangePostHook();
      return true;
    };

    model.getAtomProperties = function(i) {
      var atomMetaData = metadata.atom,
          props = {},
          propName;
      for (propName in atomMetaData) {
        if (atomMetaData.hasOwnProperty(propName)) {
          props[propName] = atoms[propName][i];
        }
      }
      return props;
    };

    model.setElementProperties = function(i, props) {
      // Validate properties.
      props = validator.validate(metadata.element, props);
      if (aminoacidsHelper.isAminoAcid(i)) {
        throw new Error("Elements: elements with ID " + i + " cannot be edited, as they define amino acids.");
      }
      invalidatingChangePreHook();
      engine.setElementProperties(i, props);
      invalidatingChangePostHook();
    };

    model.getElementProperties = function(i) {
      var elementMetaData = metadata.element,
          props = {},
          propName;
      for (propName in elementMetaData) {
        if (elementMetaData.hasOwnProperty(propName)) {
          props[propName] = elements[propName][i];
        }
      }
      return props;
    };

    model.setObstacleProperties = function(i, props) {
      // Validate properties.
      props = validator.validate(metadata.obstacle, props);
      invalidatingChangePreHook();
      engine.setObstacleProperties(i, props);
      invalidatingChangePostHook();
    };

    model.getObstacleProperties = function(i) {
      var obstacleMetaData = metadata.obstacle,
          props = {},
          propName;
      for (propName in obstacleMetaData) {
        if (obstacleMetaData.hasOwnProperty(propName)) {
          props[propName] = obstacles[propName][i];
        }
      }
      return props;
    };

    model.setRadialBondProperties = function(i, props) {
      // Validate properties.
      props = validator.validate(metadata.radialBond, props);
      invalidatingChangePreHook();
      engine.setRadialBondProperties(i, props);
      invalidatingChangePostHook();
    };

    model.getRadialBondProperties = function(i) {
      var radialBondMetaData = metadata.radialBond,
          props = {},
          propName;
      for (propName in radialBondMetaData) {
        if (radialBondMetaData.hasOwnProperty(propName)) {
          props[propName] = radialBonds[propName][i];
        }
      }
      return props;
    };

    model.setRestraintProperties = function(i, props) {
      // Validate properties.
      props = validator.validate(metadata.restraint, props);
      invalidatingChangePreHook();
      engine.setRestraintProperties(i, props);
      invalidatingChangePostHook();
    };

    model.getRestraintProperties = function(i) {
      var restraintMetaData = metadata.restraint,
          props = {},
          propName;
      for (propName in restraintMetaData) {
        if (restraintMetaData.hasOwnProperty(propName)) {
          props[propName] = restraints[propName][i];
        }
      }
      return props;
    };

    model.setAngularBondProperties = function(i, props) {
      // Validate properties.
      props = validator.validate(metadata.angularBond, props);
      invalidatingChangePreHook();
      engine.setAngularBondProperties(i, props);
      invalidatingChangePostHook();
    };

    model.getAngularBondProperties = function(i) {
      var angularBondMetaData = metadata.angularBond,
          props = {},
          propName;
      for (propName in angularBondMetaData) {
        if (angularBondMetaData.hasOwnProperty(propName)) {
          props[propName] = angularBonds[propName][i];
        }
      }
      return props;
    };

    model.setSolvent = function (solventName) {
      var solvent = new Solvent(solventName),
          props = {
            solventForceType: solvent.forceType,
            dielectricConstant: solvent.dielectricConstant,
            backgroundColor: solvent.color
          };
      model.set(props);
    };

    /** A "spring force" is used to pull atom `atomIndex` towards (x, y). We expect this to be used
       to drag atoms interactively using the mouse cursor (in which case (x,y) is the mouse cursor
       location.) In these cases, use the liveDragStart, liveDrag, and liveDragEnd methods instead
       of this one.

       The optional springConstant parameter (measured in eV/nm^2) is used to adjust the strength
       of the "spring" pulling the atom toward (x, y)

       @returns ID (index) of the spring force among all spring forces
    */
    model.addSpringForce = function(atomIndex, x, y, springConstant) {
      if (springConstant == null) springConstant = 500;
      return engine.addSpringForce(atomIndex, x, y, springConstant);
    };

    /**
      Update the (x, y) position of a spring force.
    */
    model.updateSpringForce = function(springForceIndex, x, y) {
      engine.updateSpringForce(springForceIndex, x, y);
    };

    /**
      Remove a spring force.
    */
    model.removeSpringForce = function(springForceIndex) {
      engine.removeSpringForce(springForceIndex);
    };

    model.addTextBox = function(props) {
      props = validator.validateCompleteness(metadata.textBox, props);
      properties.textBoxes.push(props);
      dispatch.textBoxesChanged();
    };

    model.removeTextBox = function(i) {
      var text = properties.textBoxes;
      if (i >=0 && i < text.length) {
        properties.textBoxes = text.slice(0,i).concat(text.slice(i+1))
        dispatch.textBoxesChanged();
      } else {
        throw new Error("Text box \"" + i + "\" does not exist, so it cannot be removed.");
      }
    };

    model.setTextBoxProperties = function(i, props) {
      var textBox = properties.textBoxes[i];
      if (textBox) {
        props = validator.validate(metadata.textBox, props);
        for (prop in props) {
          textBox[prop] = props[prop];
        }
        dispatch.textBoxesChanged();
      } else {
        throw new Error("Text box \"" + i + "\" does not exist, so it cannot have properties set.");
      }
    };

    /**
      Implements dragging of an atom in a running model, by creating a spring force that pulls the
      atom towards the mouse cursor position (x, y) and damping the resulting motion by temporarily
      adjusting the friction of the dragged atom.
    */
    model.liveDragStart = function(atomIndex, x, y) {
      if (x == null) x = atoms.x[atomIndex];
      if (y == null) y = atoms.y[atomIndex];

      liveDragSavedFriction = model.getAtomProperties(atomIndex).friction;

      // Use setAtomProperties so that we handle things correctly if a web worker is integrating
      // the model. (Here we follow the rule that we must assume that an integration might change
      // any property of an atom, and therefore cause changes to atom properties in the main thread
      // to be be lost. This is true even though common sense tells us that the friction property
      // won't change during an integration.)

      model.setAtomProperties(atomIndex, { friction: model.LIVE_DRAG_FRICTION });

      liveDragSpringForceIndex = model.addSpringForce(atomIndex, x, y, 500);
    };

    /**
      Updates the drag location after liveDragStart
    */
    model.liveDrag = function(x, y) {
      model.updateSpringForce(liveDragSpringForceIndex, x, y);
    };

    /**
      Cancels a live drag by removing the spring force that is pulling the atom, and restoring its
      original friction property.
    */
    model.liveDragEnd = function() {
      var atomIndex = engine.springForceAtomIndex(liveDragSpringForceIndex);

      model.setAtomProperties(atomIndex, { friction: liveDragSavedFriction });
      model.removeSpringForce(liveDragSpringForceIndex);
    };

    // return a copy of the array of speeds
    model.get_speed = function() {
      return arrays.copy(engine.atoms.speed, []);
    };

    model.get_rate = function() {
      return average_rate();
    };

    model.is_stopped = function() {
      return stopped;
    };

    model.get_atoms = function() {
      return atoms;
    };

    model.get_elements = function() {
      return elements;
    };

    model.get_results = function() {
      return results;
    };

    model.get_radial_bond_results = function() {
      return radialBondResults;
    };

    model.get_num_atoms = function() {
      return engine.getNumberOfAtoms();
    };

    model.get_obstacles = function() {
      return obstacles;
    };

    model.getNumberOfElements = function () {
      return engine.getNumberOfElements();
    };

    model.getNumberOfObstacles = function () {
      return engine.getNumberOfObstacles();
    };

    model.getNumberOfRadialBonds = function () {
      return engine.getNumberOfRadialBonds();
    };

    model.getNumberOfAngularBonds = function () {
      return engine.getNumberOfAngularBonds();
    };

    model.get_radial_bonds = function() {
      return radialBonds;
    };

    model.get_restraints = function() {
      return restraints;
    };

    model.getPairwiseLJProperties = function() {
      return engine.pairwiseLJProperties;
    };

    model.getGeneticProperties = function() {
      return engine.geneticProperties;
    };

    model.get_vdw_pairs = function() {
      return engine.getVdwPairsArray();
    };

    model.on = function(type, listener) {
      dispatch.on(type, listener);
      return model;
    };

    model.tickInPlace = function() {
      dispatch.tick();
      return model;
    };

    model.tick = function(num, opts) {
      if (!arguments.length) num = 1;

      var dontDispatchTickEvent = opts && opts.dontDispatchTickEvent || false,
          i = -1;

      while(++i < num) {
        tick(null, dontDispatchTickEvent);
      }
      return model;
    };

    model.relax = function() {
      engine.relaxToTemperature();
      return model;
    };

    model.minimizeEnergy = function () {
      invalidatingChangePreHook();
      engine.minimizeEnergy();
      invalidatingChangePostHook();
      return model;
    };

    /**
      Generates a protein. It returns a real number of created amino acids.

      'aaSequence' parameter defines expected sequence of amino acids. Pass undefined
      and provide 'expectedLength' if you want to generate a random protein.

      'expectedLength' parameter controls the maximum (and expected) number of amino
      acids of the resulting protein. Provide this parameter only when 'aaSequence'
      is undefined. When expected length is too big (due to limited area of the model),
      the protein will be truncated and its real length returned.
    */
    model.generateProtein = function (aaSequence, expectedLength) {
      var generatedAACount;

      invalidatingChangePreHook();

      generatedAACount = engine.generateProtein(aaSequence, expectedLength);
      // Enforce modeler to recalculate results array.
      // TODO: it's a workaround, investigate the problem.
      results.length = 0;

      invalidatingChangePostHook();

      dispatch.addAtom();

      return generatedAACount;
    };

    model.extendProtein = function (xPos, yPos, aaAbbr) {
      invalidatingChangePreHook();

      engine.extendProtein(xPos, yPos, aaAbbr);
      // Enforce modeler to recalculate results array.
      // TODO: it's a workaround, investigate the problem.
      results.length = 0;

      invalidatingChangePostHook();

      dispatch.addAtom();
    };

    /**
      Performs only one step of translation.

      Returns true when translation is finished, false otherwise.
    */
    model.translateStepByStep = function () {
      var abbr = engine.geneticProperties.translateStepByStep(),
          markerPos = engine.geneticProperties.get().translationStep,
          symbolHeight = engine.geneticProperties.get().height,
          symbolWidth = engine.geneticProperties.get().width,
          xPos = symbolWidth * markerPos * 3 + 1.5 * symbolWidth,
          yPos = symbolHeight * 5,
          width = model.get("width"),
          height = model.get("height"),
          lastAA;

      while (xPos > width) {
        xPos -= symbolWidth * 3;
      }
      while (yPos > height) {
        yPos -= symbolHeight;
      }

      if (abbr !== undefined) {
        model.extendProtein(xPos, yPos, abbr);
      } else {
        lastAA = model.get_num_atoms() - 1;
        model.setAtomProperties(lastAA, {pinned: false});
      }

      // That means that the last step of translation has just been performed.
      return abbr === undefined;
    };

    model.animateTranslation = function () {
      var translationStep = function () {
            var lastStep = model.translateStepByStep();
            if (lastStep === false) {
              setTimeout(translationStep, 1000);
            }
          };

      // Avoid two timers running at the same time.
      if (translationAnimInProgress === true) {
        return;
      }
      translationAnimInProgress = true;

      // If model is stopped, play it.
      if (stopped) {
        model.resume();
      }

      // Start the animation.
      translationStep();
    };

    model.start = function() {
      return model.resume();
    };

    /**
      Restart the model (call model.resume()) after the next tick completes.

      This is useful for changing the modelSampleRate interactively.
    */
    model.restart = function() {
      restart = true;
    };

    model.resume = function() {

      console.time('gap between frames');
      model.timer(function timerTick(elapsedTime) {
        console.timeEnd('gap between frames');
        // Cancel the timer and refuse to to step the model, if the model is stopped.
        // This is necessary because there is no direct way to cancel a d3 timer.
        // See: https://github.com/mbostock/d3/wiki/Transitions#wiki-d3_timer)
        if (stopped) return true;

        if (restart) {
          setTimeout(model.resume, 0);
          return true;
        }

        tick(elapsedTime, false);

        console.time('gap between frames');
        return false;
      });

      restart = false;
      if (stopped) {
        stopped = false;
        dispatch.play();
      }

      return model;
    };

    /**
      Repeatedly calls `f` at an interval defined by the modelSampleRate property, until f returns
      true. (This is the same signature as d3.timer.)

      If modelSampleRate === 'default', try to run at the "requestAnimationFrame rate"
      (i.e., using d3.timer(), after running f, also request to run f at the next animation frame)

      If modelSampleRate !== 'default', instead uses setInterval to schedule regular calls of f with
      period (1000 / sampleRate) ms, corresponding to sampleRate calls/s
    */
    model.timer = function(f) {
      var intervalID,
          sampleRate = model.get("modelSampleRate");

      if (sampleRate === 'default') {
        // use requestAnimationFrame via d3.timer
        d3.timer(f);
      } else {
        // set an interval to run the model more slowly.
        intervalID = window.setInterval(function() {
          if ( f() ) {
            window.clearInterval(intervalID);
          }
        }, 1000/sampleRate);
      }
    };

    model.stop = function() {
      stopped = true;
      dispatch.stop();
      return model;
    };

    model.ave_ke = function() {
      return modelOutputState.KE / model.get_num_atoms();
    };

    model.ave_pe = function() {
      return modelOutputState.PE / model.get_num_atoms();
    };

    model.speed = function() {
      return average_speed();
    };

    model.size = function(x) {
      if (!arguments.length) return engine.getSize();
      engine.setSize(x);
      return model;
    };

    model.set = function(hash) {
      // Perform validation in case of setting main properties or
      // model view properties. Attempts to set immutable or read-only
      // properties will be caught.
      validator.validate(metadata.mainProperties, hash);
      validator.validate(metadata.viewOptions, hash);

      if (engine) invalidatingChangePreHook();
      set_properties(hash);
      if (engine) invalidatingChangePostHook();
    };

    model.get = function(property) {
      var output;

      if (properties.hasOwnProperty(property)) return properties[property];

      if (output = outputsByName[property]) {
        if (output.hasCachedValue) return output.cachedValue;
        output.hasCachedValue = true;
        output.cachedValue = output.calculate();
        return output.cachedValue;
      }
    };

    /**
      Add a listener callback that will be notified when any of the properties in the passed-in
      array of properties is changed. (The argument `properties` can also be a string, if only a
      single name needs to be passed.) This is a simple way for views to update themselves in
      response to property changes.

      Observe all properties with `addPropertiesListener('all', callback);`
    */
    model.addPropertiesListener = function(properties, callback) {
      var i;

      function addListener(prop) {
        if (!listeners[prop]) listeners[prop] = [];
        listeners[prop].push(callback);
      }

      if (typeof properties === 'string') {
        addListener(properties);
      } else {
        for (i = 0; i < properties.length; i++) {
          addListener(properties[i]);
        }
      }
    };


    /**
      Add an "output" property to the model. Output properties are expected to change at every
      model tick, and may also be changed indirectly, outside of a model tick, by a change to the
      model parameters or to the configuration of atoms and other objects in the model.

      `name` should be the name of the parameter. The property value will be accessed by
      `model.get(<name>);`

      `description` should be a hash of metadata about the property. Right now, these metadata are not
      used. However, example metadata include the label and units name to be used when graphing
      this property.

      `calculate` should be a no-arg function which should calculate the property value.
    */
    model.defineOutput = function(name, description, calculate) {
      outputNames.push(name);
      outputsByName[name] = {
        description: description,
        calculate: calculate,
        hasCachedValue: false,
        // Used to keep track of whether this property changed as a side effect of some other change
        // null here is just a placeholder
        previousValue: null
      };
    };

    /**
      Add an "filtered output" property to the model. This is special kind of output property, which
      is filtered by one of the built-in filters based on time (like running average). Note that filtered
      outputs do not specify calculate function - instead, they specify property which should filtered.
      It can be another output, model parameter or custom parameter.

      Filtered output properties are extension of typical output properties. They share all features of
      output properties, so they are expected to change at every model tick, and may also be changed indirectly,
      outside of a model tick, by a change to the model parameters or to the configuration of atoms and other
      objects in the model.

      `name` should be the name of the parameter. The property value will be accessed by
      `model.get(<name>);`

      `description` should be a hash of metadata about the property. Right now, these metadata are not
      used. However, example metadata include the label and units name to be used when graphing
      this property.

      `property` should be name of the basic property which should be filtered.

      `type` should be type of filter, defined as string. For now only "RunningAverage" is supported.

      `period` should be number defining length of time period used for calculating filtered value. It should
      be specified in femtoseconds.

    */
    model.defineFilteredOutput = function(name, description, property, type, period) {
      // Filter object.
      var filter, initialValue;

      if (type === "RunningAverage") {
        filter = new RunningAverageFilter(period);
      } else {
        throw new Error("FilteredOutput: unknown filter type " + type + ".");
      }

      initialValue = model.get(property);
      if (initialValue === undefined || isNaN(Number(initialValue))) {
        throw new Error("FilteredOutput: property is not a valid numeric value or it is undefined.");
      }

      // Add initial sample.
      filter.addSample(model.get('time'), initialValue);

      filteredOutputNames.push(name);
      // filteredOutputsByName stores properties which are unique for filtered output.
      // Other properties like description or calculate function are stored in outputsByName hash.
      filteredOutputsByName[name] = {
        addSample: function () {
          filter.addSample(model.get('time'), model.get(property));
        }
      };

      // Create simple adapter implementing TickHistoryCompatible Interface
      // and register it in tick history.
      tickHistory.registerExternalObject({
        push: function () {
          // Push is empty, as we store samples during each tick anyway.
        },
        extract: function (idx) {
          filter.setCurrentStep(idx);
        },
        invalidate: function (idx) {
          filter.invalidate(idx);
        },
        setHistoryLength: function (length) {
          filter.setMaxBufferLength(length);
        }
      });

      // Extend description to contain information about filter.
      description.property = property;
      description.type = type;
      description.period = period;

      // Filtered output is still an output.
      // Reuse existing, well tested logic for caching, observing etc.
      model.defineOutput(name, description, function () {
        return filter.calculate();
      });
    };

    /**
      Define a property of the model to be treated as a custom parameter. Custom parameters are
      (generally, user-defined) read/write properties that trigger a setter action when set, and
      whose values are automatically persisted in the tick history.

      Because custom parameters are not intended to be interpreted by the engine, but instead simply
      *represent* states of the model that are otherwise fully specified by the engine state and
      other properties of the model, and because the setter function might not limit itself to a
      purely functional mapping from parameter value to model properties, but might perform any
      arbitrary stateful change, (stopping the model, etc.), the setter is NOT called when custom
      parameters are updated by the tick history.
    */
    model.defineParameter = function(name, description, setter) {
      parametersByName[name] = {
        description: description,
        setter: setter,
        isDefined: false
      };

      properties['set_'+name] = function(value) {
        properties[name] = value;
        parametersByName[name].isDefined = true;
        // set a useful 'this' binding in the setter:
        parametersByName[name].setter.call(model, value);
      };
    };

    /**
      Retrieve (a copy of) the hash describing property 'name', if one exists. This hash can store
      an arbitrary set of key-value pairs, but is expected to have 'label' and 'units' properties
      describing, respectively, the property's human-readable label and the short name of the units
      in which the property is enumerated.

      Right now, only output properties and custom parameters have a description hash.
    */
    model.getPropertyDescription = function(name) {
      var property = outputsByName[name] || parametersByName[name];
      if (property) {
        return _.extend({}, property.description);
      }
    };

    model.getPropertyType = function(name) {
      if (outputsByName[name]) {
        return 'output'
      }
      if (parametersByName[name]) {
        return 'parameter'
      }
    };

    // FIXME: Broken!! Includes property setter methods, does not include radialBonds, etc.
    model.serialize = function() {
      var propCopy = {},
          ljProps, i, len,

          removeAtomsArrayIfDefault = function(name, defaultVal) {
            if (propCopy.atoms[name].every(function(i) {
              return i === defaultVal;
            })) {
              delete propCopy.atoms[name];
            }
          };

      propCopy = serialize(metadata.mainProperties, properties);
      propCopy.viewOptions = serialize(metadata.viewOptions, properties);
      propCopy.atoms = serialize(metadata.atom, atoms, engine.getNumberOfAtoms());

      if (engine.getNumberOfRadialBonds()) {
        propCopy.radialBonds = serialize(metadata.radialBond, radialBonds, engine.getNumberOfRadialBonds());
      }
      if (engine.getNumberOfAngularBonds()) {
        propCopy.angularBonds = serialize(metadata.angularBond, angularBonds, engine.getNumberOfAngularBonds());
      }
      if (engine.getNumberOfObstacles()) {
        propCopy.obstacles = serialize(metadata.obstacle, obstacles, engine.getNumberOfObstacles());

        propCopy.obstacles.color = [];
        // Convert color from internal representation to one expected for serialization.
        for (i = 0, len = propCopy.obstacles.colorR.length; i < len; i++) {
          propCopy.obstacles.color.push([
            propCopy.obstacles.colorR[i],
            propCopy.obstacles.colorG[i],
            propCopy.obstacles.colorB[i]
          ]);

          // Silly, but allows to pass current serialization tests.
          // FIXME: try to create more flexible tests for serialization.
          propCopy.obstacles.westProbe[i] = Boolean(propCopy.obstacles.westProbe[i]);
          propCopy.obstacles.northProbe[i] = Boolean(propCopy.obstacles.northProbe[i]);
          propCopy.obstacles.eastProbe[i] = Boolean(propCopy.obstacles.eastProbe[i]);
          propCopy.obstacles.southProbe[i] = Boolean(propCopy.obstacles.southProbe[i]);
        }
        delete propCopy.obstacles.colorR;
        delete propCopy.obstacles.colorG;
        delete propCopy.obstacles.colorB;
      }
      if (engine.getNumberOfRestraints() > 0) {
        propCopy.restraints = serialize(metadata.restraint, restraints, engine.getNumberOfRestraints());
      }

      if (engine.geneticProperties.get() !== undefined) {
        propCopy.geneticProperties = engine.geneticProperties.serialize();
      }

      // FIXME: for now Amino Acid elements are *not* editable and should not be serialized
      // -- only copy first five elements
      propCopy.elements = serialize(metadata.element, elements, 5);

      // The same situation for Custom LJ Properties. Do not serialize properties for amino acids.
      propCopy.pairwiseLJProperties = [];
      ljProps = engine.pairwiseLJProperties.serialize();
      for (i = 0, len = ljProps.length; i < len; i++) {
        if (ljProps[i].element1 <= 5 && ljProps[i].element2 <= 5) {
          propCopy.pairwiseLJProperties.push(ljProps[i]);
        }
      }

      // Do the weird post processing of the JSON, which is also done by MML parser.
      // Remove targetTemperature when heat-bath is disabled.
      if (propCopy.temperatureControl === false) {
        delete propCopy.targetTemperature;
      }
      // Remove atomTraceId when atom tracing is disabled.
      if (propCopy.viewOptions.showAtomTrace === false) {
        delete propCopy.viewOptions.atomTraceId;
      }
      if (propCopy.modelSampleRate === "default") {
        delete propCopy.modelSampleRate;
      }

      removeAtomsArrayIfDefault("marked", metadata.atom.marked.defaultValue);
      removeAtomsArrayIfDefault("visible", metadata.atom.visible.defaultValue);
      removeAtomsArrayIfDefault("draggable", metadata.atom.draggable.defaultValue);

      return propCopy;
    };

    // ------------------------------
    // finish setting up the model
    // ------------------------------

    // Friction parameter temporarily applied to the live-dragged atom.
    model.LIVE_DRAG_FRICTION = 10;

    // Define some default output properties.
    model.defineOutput('time', {
      label: "Time",
      units: "fs"
    }, function() {
      return modelOutputState.time;
    });

    model.defineOutput('kineticEnergy', {
      label: "Kinetic Energy",
      units: "eV"
    }, function() {
      return modelOutputState.KE;
    });

    model.defineOutput('potentialEnergy', {
      label: "Potential Energy",
      units: "eV"
    }, function() {
      return modelOutputState.PE;
    });

    model.defineOutput('totalEnergy', {
      label: "Total Energy",
      units: "eV"
    }, function() {
      return modelOutputState.KE + modelOutputState.PE;
    });

    model.defineOutput('temperature', {
      label: "Temperature",
      units: "K"
    }, function() {
      return modelOutputState.temperature;
    });


    // Set the regular, main properties.
    // Note that validation process will return hash without all properties which are
    // not defined in meta model as mainProperties (like atoms, obstacles, viewOptions etc).
    set_properties(validator.validateCompleteness(metadata.mainProperties, initialProperties));

    // Set the model view options.
    set_properties(validator.validateCompleteness(metadata.viewOptions, initialProperties.viewOptions || {}));

    // Setup engine object.
    model.initializeEngine();

    // Finally, if provided, set up the model objects (elements, atoms, bonds, obstacles and the rest).
    // However if these are not provided, client code can create atoms, etc piecemeal.

    // TODO: Elements are stored and treated different from other objects.
    // This is enforced by current createNewAtoms() method which should be
    // depreciated. When it's changed, change also editableElements handling.
    editableElements = initialProperties.elements;
    // Create editable elements.
    model.createElements(editableElements);
    // Create elements which specify amino acids also.
    createAminoAcids();

    // Trigger setter of polarAAEpsilon again when engine is initialized and
    // amino acids crated.
    // TODO: initialize engine before set_properties calls, so properties
    // will be injected to engine automatically.
    model.set({polarAAEpsilon: model.get('polarAAEpsilon')});

    if (initialProperties.atoms) {
      model.createAtoms(initialProperties.atoms);
    } else if (initialProperties.mol_number) {
      model.createAtoms(initialProperties.mol_number);
      if (initialProperties.relax) model.relax();
    }

    if (initialProperties.radialBonds)  model.createRadialBonds(initialProperties.radialBonds);
    if (initialProperties.angularBonds) model.createAngularBonds(initialProperties.angularBonds);
    if (initialProperties.restraints)   model.createRestraints(initialProperties.restraints);
    if (initialProperties.obstacles)    model.createObstacles(initialProperties.obstacles);
    // Basically, this #deserialize method is more or less similar to other #create... methods used
    // above. However, this is the first step to delegate some functionality from modeler to smaller classes.
    if (initialProperties.pairwiseLJProperties)
      engine.pairwiseLJProperties.deserialize(initialProperties.pairwiseLJProperties);
    if (initialProperties.geneticProperties)
      engine.geneticProperties.deserialize(initialProperties.geneticProperties);

    // Initialize tick history.
    tickHistory = new TickHistory({
      input: [
        "targetTemperature",
        "lennardJonesForces",
        "coulombForces",
        "temperatureControl",
        "keShading",
        "chargeShading",
        "showVDWLines",
        "showVelocityVectors",
        "showForceVectors",
        "showClock",
        "viewRefreshInterval",
        "timeStep",
        "viscosity",
        "gravitationalField"
      ],
      restoreProperties: restoreProperties,
      parameters: parametersByName,
      restoreParameters: restoreParameters,
      state: engine.getState()
    }, model, defaultMaxTickHistory);

    newStep = true;
    updateAllOutputProperties();

    return model;
  };
});

(function() {

  define('cs!common/components/model_controller_component',['require','common/console'],function(require) {
    var ModelControllerComponent, console;
    console = require('common/console');
    return ModelControllerComponent = (function() {

      function ModelControllerComponent(svg_element, playable, xpos, ypos, scale) {
        var _this = this;
        this.svg_element = svg_element;
        this.playable = playable != null ? playable : null;
        this.width = 200;
        this.height = 34;
        this.xpos = xpos;
        this.ypos = ypos;
        this.scale = scale || 1;
        this.unit_width = this.width / 9;
        this.vertical_padding = (this.height - this.unit_width) / 2;
        this.stroke_width = this.unit_width / 10;
        this.init_view();
        this.setup_buttons();
        if (this.playable.isPlaying()) {
          this.hide(this.play);
        } else {
          this.hide(this.stop);
        }
        model.on('play', function() {
          return _this.update_ui();
        });
        model.on('stop', function() {
          return _this.update_ui();
        });
      }

      ModelControllerComponent.prototype.offset = function(offset) {
        return offset * (this.unit_width * 2) + this.unit_width;
      };

      ModelControllerComponent.prototype.setup_buttons = function() {};

      ModelControllerComponent.prototype.make_button = function(_arg) {
        var action, art, art2, button_bg, button_group, button_highlight, offset, point, point_set, points, points_string, type, x, y, _i, _j, _len, _len1,
          _this = this;
        action = _arg.action, offset = _arg.offset, type = _arg.type, point_set = _arg.point_set;
        if (type == null) {
          type = "svg:polyline";
        }
        if (point_set == null) {
          point_set = this.icon_shapes[action];
        }
        offset = this.offset(offset);
        button_group = this.group.append('svg:g');
        button_group.attr("class", "component playbacksvgbutton").attr('x', offset).attr('y', this.vertical_padding).attr('width', this.unit_width).attr('height', this.unit_width * 2).attr('style', 'fill: #cccccc');
        button_bg = button_group.append('rect');
        button_bg.attr('class', 'bg').attr('x', offset).attr('y', this.vertical_padding / 3).attr('width', this.unit_width * 2).attr('height', this.unit_width * 1.5).attr('rx', '0');
        for (_i = 0, _len = point_set.length; _i < _len; _i++) {
          points = point_set[_i];
          art = button_group.append(type);
          art.attr('class', "" + action + " button-art");
          points_string = "";
          for (_j = 0, _len1 = points.length; _j < _len1; _j++) {
            point = points[_j];
            x = offset + 10 + point['x'] * this.unit_width;
            y = this.vertical_padding / .75 + point['y'] * this.unit_width;
            points_string = points_string + (" " + x + "," + y);
            art.attr('points', points_string);
          }
          if (action === 'stop') {
            art2 = button_group.append('rect');
            art2.attr('class', 'pause-center').attr('x', x + this.unit_width / 3).attr('y', this.vertical_padding / .75 - 1).attr('width', this.unit_width / 3).attr('height', this.unit_width + 2);
          }
        }
        button_highlight = button_group.append('rect');
        button_highlight.attr('class', 'highlight').attr('x', offset + 1).attr('y', this.vertical_padding / 1.85).attr('width', this.unit_width * 2 - 2).attr('height', this.unit_width / 1.4).attr('rx', '0');
        button_group.on('click', function() {
          return _this.action(action);
        });
        return button_group;
      };

      ModelControllerComponent.prototype.action = function(action) {
        console.log("running " + action + " ");
        if (this.playable) {
          switch (action) {
            case 'play':
              this.playable.play();
              break;
            case 'stop':
              this.playable.stop();
              break;
            case 'forward':
              this.playable.forward();
              break;
            case 'back':
              this.playable.back();
              break;
            case 'seek':
              this.playable.seek(1);
              break;
            case 'reset':
              this.playable.reset();
              break;
            default:
              console.log("cant find action for " + action);
          }
        } else {
          console.log("no @playable defined");
        }
        return this.update_ui();
      };

      ModelControllerComponent.prototype.init_view = function() {
        this.svg = this.svg_element.append("svg:svg").attr("class", "component model-controller playbacksvg").attr("x", this.xpos).attr("y", this.ypos);
        return this.group = this.svg.append("g").attr("transform", "scale(" + this.scale + "," + this.scale + ")").attr("width", this.width).attr("height", this.height);
      };

      ModelControllerComponent.prototype.position = function(xpos, ypos, scale) {
        this.xpos = xpos;
        this.ypos = ypos;
        this.scale = scale || 1;
        this.svg.attr("x", this.xpos).attr("y", this.ypos);
        return this.group.attr("transform", "scale(" + this.scale + "," + this.scale + ")").attr("width", this.width).attr("height", this.height);
      };

      ModelControllerComponent.prototype.update_ui = function() {
        if (this.playable) {
          if (this.playable.isPlaying()) {
            this.hide(this.play);
            return this.show(this.stop);
          } else {
            this.hide(this.stop);
            return this.show(this.play);
          }
        }
      };

      ModelControllerComponent.prototype.hide = function(thing) {
        return thing.style('visibility', 'hidden');
      };

      ModelControllerComponent.prototype.show = function(thing) {
        return thing.style('visibility', 'visible');
      };

      ModelControllerComponent.prototype.icon_shapes = {
        play: [
          [
            {
              x: 0,
              y: 0
            }, {
              x: 1,
              y: 0.5
            }, {
              x: 0,
              y: 1
            }
          ]
        ],
        stop: [
          [
            {
              x: 0,
              y: 0
            }, {
              x: 1,
              y: 0
            }, {
              x: 1,
              y: 1
            }, {
              x: 0,
              y: 1
            }, {
              x: 0,
              y: 0
            }
          ]
        ],
        reset: [
          [
            {
              x: 1,
              y: 0
            }, {
              x: 0.3,
              y: 0.5
            }, {
              x: 1,
              y: 1
            }
          ], [
            {
              x: 0,
              y: 0
            }, {
              x: 0.3,
              y: 0
            }, {
              x: 0.3,
              y: 1
            }, {
              x: 0,
              y: 1
            }, {
              x: 0,
              y: 0
            }
          ]
        ],
        back: [
          [
            {
              x: 0.5,
              y: 0
            }, {
              x: 0,
              y: 0.5
            }, {
              x: 0.5,
              y: 1
            }
          ], [
            {
              x: 1,
              y: 0
            }, {
              x: 0.5,
              y: 0.5
            }, {
              x: 1,
              y: 1
            }
          ]
        ],
        forward: [
          [
            {
              x: 0.5,
              y: 0
            }, {
              x: 1,
              y: 0.5
            }, {
              x: 0.5,
              y: 1
            }
          ], [
            {
              x: 0,
              y: 0
            }, {
              x: 0.5,
              y: 0.5
            }, {
              x: 0,
              y: 1
            }
          ]
        ]
      };

      return ModelControllerComponent;

    })();
  });

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define('cs!common/components/play_reset_svg',['require','cs!common/components/model_controller_component'],function(require) {
    var ModelControllerComponent, PlayResetComponentSVG;
    ModelControllerComponent = require('cs!common/components/model_controller_component');
    return PlayResetComponentSVG = (function(_super) {

      __extends(PlayResetComponentSVG, _super);

      function PlayResetComponentSVG() {
        return PlayResetComponentSVG.__super__.constructor.apply(this, arguments);
      }

      PlayResetComponentSVG.prototype.setup_buttons = function() {
        this.reset = this.make_button({
          action: 'reset',
          offset: 0
        });
        this.play = this.make_button({
          action: 'play',
          offset: 1
        });
        return this.stop = this.make_button({
          action: 'stop',
          offset: 1
        });
      };

      return PlayResetComponentSVG;

    })(ModelControllerComponent);
  });

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define('cs!common/components/play_only_svg',['require','cs!common/components/model_controller_component'],function(require) {
    var ModelControllerComponent, PlayOnlyComponentSVG;
    ModelControllerComponent = require('cs!common/components/model_controller_component');
    return PlayOnlyComponentSVG = (function(_super) {

      __extends(PlayOnlyComponentSVG, _super);

      function PlayOnlyComponentSVG() {
        return PlayOnlyComponentSVG.__super__.constructor.apply(this, arguments);
      }

      PlayOnlyComponentSVG.prototype.setup_buttons = function() {
        this.play = this.make_button({
          action: 'play',
          offset: 0
        });
        return this.stop = this.make_button({
          action: 'stop',
          offset: 0
        });
      };

      return PlayOnlyComponentSVG;

    })(ModelControllerComponent);
  });

}).call(this);

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define('cs!common/components/playback_svg',['require','cs!common/components/model_controller_component'],function(require) {
    var ModelControllerComponent, PlaybackComponentSVG;
    ModelControllerComponent = require('cs!common/components/model_controller_component');
    return PlaybackComponentSVG = (function(_super) {

      __extends(PlaybackComponentSVG, _super);

      function PlaybackComponentSVG() {
        return PlaybackComponentSVG.__super__.constructor.apply(this, arguments);
      }

      PlaybackComponentSVG.prototype.setup_buttons = function() {
        this.reset = this.make_button({
          action: 'reset',
          offset: 0
        });
        this.back = this.make_button({
          action: 'back',
          offset: 1
        });
        this.play = this.make_button({
          action: 'play',
          offset: 2
        });
        this.stop = this.make_button({
          action: 'stop',
          offset: 2
        });
        return this.forward = this.make_button({
          action: 'forward',
          offset: 3
        });
      };

      return PlaybackComponentSVG;

    })(ModelControllerComponent);
  });

}).call(this);

/*global define: false console: true */

define('common/views/gradients',['require'],function (require) {
  // Dependencies.
  var publicAPI;

  publicAPI = {
    // Hash which defines the main color of a given created gradient.
    // E.g. useful for radial bonds, which can adjust their color to gradient.
    // Note that for convenience, keys are in forms of URLs (e.g. url(#some-gradient)).
    mainColorOfGradient: {},
    createRadialGradient: function (id, lightColor, medColor, darkColor, mainContainer) {
      var gradientUrl,
          gradient = mainContainer.append("defs")
          .append("radialGradient")
          .attr("id", id)
          .attr("cx", "50%")
          .attr("cy", "47%")
          .attr("r", "53%")
          .attr("fx", "35%")
          .attr("fy", "30%");
      gradient.append("stop")
          .attr("stop-color", lightColor)
          .attr("offset", "0%");
      gradient.append("stop")
          .attr("stop-color", medColor)
          .attr("offset", "40%");
      gradient.append("stop")
          .attr("stop-color", darkColor)
          .attr("offset", "80%");
      gradient.append("stop")
          .attr("stop-color", medColor)
          .attr("offset", "100%");

      gradientUrl = "url(#" + id + ")";
      // Store main color (for now - dark color) of the gradient.
      // Useful for radial bonds. Keys are URLs for convenience.
      publicAPI.mainColorOfGradient[gradientUrl] = darkColor;
      return gradientUrl;
    }
  };

  return publicAPI;
});

/*global $ model_player define: false, d3: false */
// ------------------------------------------------------------
//
//   PTA View Container
//
// ------------------------------------------------------------
define('common/views/model-view',['require','lab.config','cs!common/components/play_reset_svg','cs!common/components/play_only_svg','cs!common/components/playback_svg','common/views/gradients'],function (require) {
  // Dependencies.
  var labConfig             = require('lab.config'),
      PlayResetComponentSVG = require('cs!common/components/play_reset_svg'),
      PlayOnlyComponentSVG  = require('cs!common/components/play_only_svg'),
      PlaybackComponentSVG  = require('cs!common/components/playback_svg'),
      gradients             = require('common/views/gradients');

  return function ModelView(e, modelUrl, model, Renderer) {
        // Public API object to be returned.
    var api = {},
        renderer,
        containers = {},
        elem = d3.select(e),
        node = elem.node(),
        // in fit-to-parent mode, the d3 selection containing outermost container
        outerElement,
        cx = elem.property("clientWidth"),
        cy = elem.property("clientHeight"),
        width, height,
        emsize,
        imagePath,
        vis1, vis, plot,
        playbackComponent,
        padding, size, modelSize,
        dragged,
        playbackXPos, playbackYPos,
        timePrefix = "",
        timeSuffix = " (fs)",

        // Basic scaling function, it transforms model units to "pixels".
        // Use it for dimensions of objects rendered inside the view.
        model2px,
        // Inverted scaling function transforming model units to "pixels".
        // Use it for Y coordinates, as model coordinate system has (0, 0) point
        // in lower left corner, but SVG has (0, 0) point in upper left corner.
        model2pxInv,

        // "Containers" - SVG g elements used to position layers of the final visualization.
        mainContainer,
        gridContainer,
        radialBondsContainer,
        VDWLinesContainer,
        imageContainerBelow,
        imageContainerTop,
        textContainerBelow,
        textContainerTop,

        offsetLeft, offsetTop;

    function processOptions(newModelUrl, newModel) {
      modelUrl = newModelUrl || modelUrl;
      model = newModel || model;
      if (modelUrl) {
        imagePath = labConfig.actualRoot + modelUrl.slice(0, modelUrl.lastIndexOf("/") + 1);
      }
    }

    // Padding is based on the calculated font-size used for the model view container.
    function updatePadding() {
      emsize = $(e).css('font-size');
      // Remove "px", convert to number.
      emsize = Number(emsize.substring(0, emsize.length - 2));
      // Convert value to "em", using 18px as a basic font size.
      // It doesn't have to reflect true 1em value in current context.
      // It just means, that we assume that for 18px font-size,
      // padding and playback have scale 1.
      emsize /= 18;

      padding = {
         "top":    10 * emsize,
         "right":  10 * emsize,
         "bottom": 10 * emsize,
         "left":   10 * emsize
      };

      if (model.get("xunits")) {
        padding.bottom += (15  * emsize);
      }

      if (model.get("yunits")) {
        padding.left += (15  * emsize);
      }

      if (model.get("controlButtons")) {
        padding.bottom += (40  * emsize);
      } else {
        padding.bottom += (15  * emsize);
      }
    }

    function scale() {
      var modelWidth = model.get('width'),
          modelHeight = model.get('height'),
          aspectRatio = modelWidth / modelHeight;

      updatePadding();

      cx = elem.property("clientWidth");
      width = cx - padding.left  - padding.right;
      height = width / aspectRatio;
      cy = height + padding.top  + padding.bottom;
      node.style.height = cy + "px";

      // Container size in px.
      size = {
        "width":  width,
        "height": height
      };
      // Model size in model units.
      modelSize = {
        "width":  modelWidth,
        "height": modelHeight
      };

      offsetTop  = node.offsetTop + padding.top;
      offsetLeft = node.offsetLeft + padding.left;

      switch (model.get("controlButtons")) {
        case "play":
          playbackXPos = padding.left + (size.width - (75 * emsize))/2;
          break;
        case "play_reset":
          playbackXPos = padding.left + (size.width - (140 * emsize))/2;
          break;
        case "play_reset_step":
          playbackXPos = padding.left + (size.width - (230 * emsize))/2;
          break;
        default:
          playbackXPos = padding.left + (size.width - (230 * emsize))/2;
      }

      playbackYPos = cy - 42 * emsize;

      // Basic model2px scaling function.
      model2px = d3.scale.linear()
          .domain([0, modelSize.width])
          .range([0, size.width]);

      // Inverted model2px scaling function (for y-coordinates, inverted domain).
      model2pxInv = d3.scale.linear()
          .domain([modelSize.height, 0])
          .range([0, size.height]);

      dragged = null;
      return [cx, cy, width, height];
    }

    function modelTimeLabel() {
      return timePrefix + modelTimeFormatter(model.get('time')) + timeSuffix;
    }

    function redraw() {
      var tx = function(d) { return "translate(" + model2px(d) + ",0)"; },
          ty = function(d) { return "translate(0," + model2pxInv(d) + ")"; },
          stroke = function(d) { return d ? "#ccc" : "#666"; },
          fx = model2px.tickFormat(5),
          fy = model2pxInv.tickFormat(5);

      if (d3.event && d3.event.transform) {
          d3.event.transform(model2px, model2pxInv);
      }

      // Regenerate x-ticks…
      var gx = gridContainer.selectAll("g.x")
          .data(model2px.ticks(5), String)
          .attr("transform", tx)
          .classed("axes", true);

      gx.select("text").text(fx);

      var gxe = gx.enter().insert("g", "a")
          .attr("class", "x")
          .attr("transform", tx);

      if (model.get("gridLines")) {
        gxe.append("line")
            .attr("stroke", stroke)
            .attr("y1", 0)
            .attr("y2", size.height);
      } else {
        gxe.selectAll("line").remove();
      }

      if (model.get("xunits")) {
        gxe.append("text")
            .attr("y", size.height)
            .attr("dy", "1.25em")
            .attr("text-anchor", "middle")
            .text(fx);
      } else {
        gxe.select("text").remove();
      }

      gx.exit().remove();

      // Regenerate y-ticks…
      var gy = gridContainer.selectAll("g.y")
          .data(model2pxInv.ticks(5), String)
          .attr("transform", ty)
          .classed("axes", true);

      gy.select("text")
          .text(fy);

      var gye = gy.enter().insert("g", "a")
          .attr("class", "y")
          .attr("transform", ty)
          .attr("background-fill", "#FFEEB6");

      if (model.get("gridLines")) {
        gye.append("line")
            .attr("stroke", stroke)
            .attr("x1", 0)
            .attr("x2", size.width);
      } else {
        gye.selectAll("line").remove();
      }

      if (model.get("yunits")) {
        gye.append("text")
            .attr("x", "-0.15em")
            .attr("dy", "0.30em")
            .attr("text-anchor", "end")
            .text(fy);
      } else {
        gye.select("text").remove();
      }

      gy.exit().remove();
    }

    function createGradients() {
      // "Marked" particle gradient.
      gradients.createRadialGradient("mark-grad", "#fceabb", "#fccd4d", "#f8b500", mainContainer);

      // "Charge" gradients.
      gradients.createRadialGradient("neg-grad", "#ffefff", "#fdadad", "#e95e5e", mainContainer);
      gradients.createRadialGradient("pos-grad", "#dfffff", "#9abeff", "#767fbf", mainContainer);
      gradients.createRadialGradient("neutral-grad", "#FFFFFF", "#f2f2f2", "#A4A4A4", mainContainer);

      // "Marked" atom gradient.
      gradients.createRadialGradient("mark-grad", "#fceabb", "#fccd4d", "#f8b500", mainContainer);

      // Colored gradients, used for MD2D Editable element
      gradients.createRadialGradient("green-grad", "#dfffef", "#75a643", "#2a7216", mainContainer);
      gradients.createRadialGradient("blue-grad", "#dfefff", "#7543a6", "#2a1672", mainContainer);
      gradients.createRadialGradient("purple-grad", "#EED3F0", "#D941E0", "#84198A", mainContainer);
      gradients.createRadialGradient("aqua-grad", "#DCF5F4", "#41E0D8", "#12827C", mainContainer);
      gradients.createRadialGradient("orange-grad", "#F0E6D1", "#E0A21B", "#AD7F1C", mainContainer);
    }

    // Setup background.
    function setupBackground() {
      // Just set the color.
      plot.style("fill", model.get("backgroundColor"));
    }

    function mousedown() {
      setFocus();
    }

    function setFocus() {
      if (model.get("enableKeyboardHandlers")) {
        node.focus();
      }
    }

    // ------------------------------------------------------------
    //
    // Handle keyboard shortcuts for model operation
    //
    // ------------------------------------------------------------

    function setupKeyboardHandler() {
      if (!model.get("enableKeyboardHandlers")) return;
      $(node).keydown(function(event) {
        var keycode = event.keycode || event.which;
        switch(keycode) {
          case 13:                 // return
          event.preventDefault();
          if (!model_player.isPlaying()) {
            model_player.play();
          }
          break;

          case 32:                 // space
          event.preventDefault();
          if (model_player.isPlaying()) {
            model_player.stop();
          } else {
            model_player.play();
          }
          break;

          case 37:                 // left-arrow
          event.preventDefault();
          if (model_player.isPlaying()) {
            model_player.stop();
          } else {
            model_player.back();
          }
          break;

          case 39:                 // right-arrow
          event.preventDefault();
          if (model_player.isPlaying()) {
            model_player.stop();
          } else {
            model_player.forward();
          }
          break;
        }
      });
    }

    function renderContainer() {
      scale();
      // create container, or update properties if it already exists
      if (vis === undefined) {

        outerElement = elem;
        vis1 = d3.select(node).append("svg")
          .attr({
            width: cx,
            height: cy
          })
          .style({
            width: cx,
            height: cy
          });

        vis = vis1.append("g").attr("class", "particle-container-vis");

        plot = vis.append("rect")
            .attr("class", "plot");

        if (model.get("enableKeyboardHandlers")) {
          d3.select(node)
            .attr("tabindex", 0)
            .on("mousedown", mousedown);
        }

        // Create and arrange "layers" of the final image (g elements).
        // Note that order of their creation is significant.
        gridContainer        = vis.append("g").attr("class", "grid-container");
        imageContainerBelow  = vis.append("g").attr("class", "image-container-below");
        textContainerBelow   = vis.append("g").attr("class", "text-container-below");
        radialBondsContainer = vis.append("g").attr("class", "radial-bonds-container");
        VDWLinesContainer    = vis.append("g").attr("class", "vdw-lines-container");
        mainContainer        = vis.append("g").attr("class", "main-container");
        imageContainerTop    = vis.append("g").attr("class", "image-container-top");
        textContainerTop     = vis.append("g").attr("class", "text-container-top");

        containers = {
          node: node,
          gridContainer:        gridContainer,
          imageContainerBelow:  imageContainerBelow,
          textContainerBelow:   textContainerBelow,
          radialBondsContainer: radialBondsContainer,
          VDWLinesContainer:    VDWLinesContainer,
          mainContainer:        mainContainer,
          imageContainerTop:    imageContainerTop,
          textContainerTop:     textContainerTop
        };

        setupKeyboardHandler();
        createGradients();
      } else {
        // TODO: ?? what g, why is it here?
        vis.selectAll("g.x").remove();
        vis.selectAll("g.y").remove();
      }

      // Set new dimensions of the top-level SVG container.
      vis1
        .attr({
          width: cx,
          height: cy
        })
        .style({
          width: cx,
          height: cy
        });

      // Update padding, as it can be changed after rescaling.
      vis
        .attr("transform", "translate(" + padding.left + "," + padding.top + ")");

      // Rescale main plot.
      vis.select("rect.plot")
        .attr({
          width: size.width,
          height: size.height
        });

      redraw();
    }

    function setupPlaybackControls() {
      d3.select('.model-controller').remove();
      switch (model.get("controlButtons")) {
        case "play":
          playbackComponent = new PlayOnlyComponentSVG(vis1, model_player, playbackXPos, playbackYPos, emsize);
          break;
        case "play_reset":
          playbackComponent = new PlayResetComponentSVG(vis1, model_player, playbackXPos, playbackYPos, emsize);
          break;
        case "play_reset_step":
          playbackComponent = new PlaybackComponentSVG(vis1, model_player, playbackXPos, playbackYPos, emsize);
          break;
        default:
          playbackComponent = null;
      }
    }

    //
    // *** Main Renderer functions ***
    //

    //
    // init
    //
    // Called when Model View Container is created.
    //
    function init() {
      // render model container ... the chrome around the model
      renderContainer();
      setupPlaybackControls();

      // dynamically add modelUrl as a model property so the renderer
      // can find resources on paths relative to the model
      model.url = modelUrl;

      // create a model renderer ... if one hasn't already been created
      if (!renderer) {
        renderer = new Renderer(model, containers, model2px, model2pxInv);
      } else {
        renderer.reset(model, containers, model2px, model2pxInv);
      }

      repaint();

      // Redraw container each time when some visual-related property is changed.
      model.addPropertiesListener([ "backgroundColor"], repaint);
      model.addPropertiesListener(["gridLines", "xunits", "yunits"],
        function() {
          renderContainer();
          setupPlaybackControls();
          repaint();
        }
      );
    }

    //
    // repaint
    //
    // Call when container changes size.
    //
    function repaint() {
      setupBackground();
      renderer.repaint(model2px, model2pxInv);
    }

    api = {
      update: null,
      node: null,
      outerNode: null,
      scale: scale,
      setFocus: setFocus,
      resize: function() {
        scale();
        processOptions();
        init();
      },
      getHeightForWidth: function (width) {
        var modelWidth = model.get('width'),
            modelHeight = model.get('height'),
            aspectRatio = modelWidth / modelHeight,
            height;

        updatePadding();

        width = width - padding.left - padding.right;
        height = width / aspectRatio;
        return height + padding.top  + padding.bottom;
      },
      repaint: function() {
        repaint();
      },
      reset: function(newModelUrl, newModel) {
        processOptions(newModelUrl, newModel);
        init();
      },
      model2px: function(val) {
        // Note that we shouldn't just do:
        // api.model2px = model2px;
        // as model2px local variable can be reinitialized
        // many times due container rescaling process.
        return model2px(val);
      },
      model2pxInv: function(val) {
        // See comments for model2px.
        return model2pxInv(val);
      }
    };

    // Initialization.
    processOptions();
    init();

    // Extend Public withExport initialized object to initialized objects
    api.update = renderer.update;
    api.node = node;
    api.outerNode = outerElement.node();

    return api;
  };
});


/*
Simple module which provides context menu for amino acids. It allows
to dynamically change type of amino acids in a convenient way.
It uses jQuery.contextMenu plug-in.

CSS style definition: sass/lab/_aminoacid-context-menu.sass
*/


(function() {

  define('cs!md2d/views/aminoacid-context-menu',['require','cs!md2d/models/aminoacids-helper'],function(require) {
    var HYDROPHILIC_CAT_CLASS, HYDROPHILIC_CLASS, HYDROPHOBIC_CAT_CLASS, HYDROPHOBIC_CLASS, MARKED_CLASS, MENU_CLASS, NEG_CHARGE_CLASS, POS_CHARGE_CLASS, aminoacids, showCategory;
    aminoacids = require('cs!md2d/models/aminoacids-helper');
    MENU_CLASS = "aminoacids-menu";
    HYDROPHOBIC_CLASS = "hydrophobic";
    HYDROPHOBIC_CAT_CLASS = "hydrophobic-category";
    HYDROPHILIC_CLASS = "hydrophilic";
    HYDROPHILIC_CAT_CLASS = "hydrophilic-category";
    POS_CHARGE_CLASS = "pos-charge";
    NEG_CHARGE_CLASS = "neg-charge";
    MARKED_CLASS = "marked";
    showCategory = function(type, animate) {
      var func;
      func = {
        show: animate ? "slideDown" : "show",
        hide: animate ? "slideUp" : "hide"
      };
      if (type === "hydrophobic") {
        $("." + HYDROPHOBIC_CLASS)[func.show]();
        $("." + HYDROPHILIC_CLASS)[func.hide]();
        $("." + HYDROPHOBIC_CAT_CLASS).addClass("expanded");
        return $("." + HYDROPHILIC_CAT_CLASS).removeClass("expanded");
      } else {
        $("." + HYDROPHOBIC_CLASS)[func.hide]();
        $("." + HYDROPHILIC_CLASS)[func.show]();
        $("." + HYDROPHOBIC_CAT_CLASS).removeClass("expanded");
        return $("." + HYDROPHILIC_CAT_CLASS).addClass("expanded");
      }
    };
    return {
      /*
        Register context menu for DOM elements defined by @selector.
        @model, @view are associated model and view, used to set
        properties and redraw view.
      */

      register: function(model, view, selector) {
        $.contextMenu("destroy", selector);
        $.contextMenu({
          selector: selector,
          appendTo: "#responsive-content",
          className: MENU_CLASS,
          animation: {
            show: "show",
            hide: "hide"
          },
          callback: function(key, options) {
            var elemId, marked, props;
            props = d3.select(options.$trigger[0]).datum();
            marked = aminoacids.getAminoAcidByElement(props.element).abbreviation;
            options.items[marked].$node.removeClass(MARKED_CLASS);
            elemId = aminoacids.abbrToElement(key);
            model.setAtomProperties(props.idx, {
              element: elemId
            });
            return view.repaint();
          },
          position: function(opt, x, y) {
            var $win, bottom, height, offset, right, triggerIsFixed, width;
            $win = $(window);
            if (!x && !y) {
              opt.determinePosition.call(this, opt.$menu);
              return;
            } else if (x === "maintain" && y === "maintain") {
              offset = opt.$menu.position();
            } else {
              triggerIsFixed = opt.$trigger.parents().andSelf().filter(function() {
                return $(this).css('position') === "fixed";
              }).length;
              if (triggerIsFixed) {
                y -= $win.scrollTop();
                x -= $win.scrollLeft();
              }
              offset = {
                top: y,
                left: x
              };
            }
            bottom = $win.scrollTop() + $win.height();
            right = $win.scrollLeft() + $win.width();
            /*
                    !!! Workaround for the correct positioning:
                    Use scrollHeight / scrollWidth as these functions return correct height / width
                    in contrast to opt.$menu.height() / opt.$menu.width().
            */

            height = opt.$menu[0].scrollHeight;
            width = opt.$menu[0].scrollWidth;
            if (offset.top + height > bottom) {
              offset.top -= height;
            }
            if (offset.left + width > right) {
              offset.left -= width;
            }
            offset.left += 1;
            return opt.$menu.css(offset);
          },
          events: {
            show: function(options) {
              var $node, key, props;
              props = d3.select(options.$trigger[0]).datum();
              key = aminoacids.getAminoAcidByElement(props.element).abbreviation;
              $node = options.items[key].$node;
              $node.addClass(MARKED_CLASS);
              if ($node.hasClass(HYDROPHOBIC_CLASS)) {
                showCategory("hydrophobic");
              } else {
                showCategory("hydrophilic");
              }
              return true;
            },
            hide: function(options) {
              var key, props;
              props = d3.select(options.$trigger[0]).datum();
              key = aminoacids.getAminoAcidByElement(props.element).abbreviation;
              options.items[key].$node.removeClass(MARKED_CLASS);
              return true;
            }
          },
          items: {
            "Hydrophobic": {
              name: "Hydrophobic",
              className: "" + HYDROPHOBIC_CAT_CLASS,
              callback: function() {
                showCategory("hydrophobic", true);
                return false;
              }
            },
            "Gly": {
              name: "Glycine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Ala": {
              name: "Alanine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Val": {
              name: "Valine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Leu": {
              name: "Leucine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Ile": {
              name: "Isoleucine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Phe": {
              name: "Phenylalanine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Pro": {
              name: "Proline",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Trp": {
              name: "Tryptophan",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Met": {
              name: "Methionine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Cys": {
              name: "Cysteine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Tyr": {
              name: "Tyrosine",
              className: "" + HYDROPHOBIC_CLASS
            },
            "Hydrophilic": {
              name: "Hydrophilic",
              className: "" + HYDROPHILIC_CAT_CLASS,
              callback: function() {
                showCategory("hydrophilic", true);
                return false;
              }
            },
            "Asn": {
              name: "Asparagine",
              className: "" + HYDROPHILIC_CLASS
            },
            "Gln": {
              name: "Glutamine",
              className: "" + HYDROPHILIC_CLASS
            },
            "Ser": {
              name: "Serine",
              className: "" + HYDROPHILIC_CLASS
            },
            "Thr": {
              name: "Threonine",
              className: "" + HYDROPHILIC_CLASS
            },
            "Asp": {
              name: "Asparticacid",
              className: "" + HYDROPHILIC_CLASS + " " + NEG_CHARGE_CLASS
            },
            "Glu": {
              name: "Glutamicacid",
              className: "" + HYDROPHILIC_CLASS + " " + NEG_CHARGE_CLASS
            },
            "Lys": {
              name: "Lysine",
              className: "" + HYDROPHILIC_CLASS + " " + POS_CHARGE_CLASS
            },
            "Arg": {
              name: "Arginine",
              className: "" + HYDROPHILIC_CLASS + " " + POS_CHARGE_CLASS
            },
            "His": {
              name: "Histidine",
              className: "" + HYDROPHILIC_CLASS + " " + POS_CHARGE_CLASS
            }
          }
        });
        return showCategory("hydrophobic");
      }
    };
  });

}).call(this);

/*global define: false */

define('md2d/views/genetic-renderer',['require'],function (require) {

  return function GeneticRenderer(container, parentView, model) {
    var api,
        model2px,
        model2pxInv,

        init = function() {
          // Save shortcuts.
          model2px = parentView.model2px;
          model2pxInv = parentView.model2pxInv;
          // Redraw DNA / mRNA on every genetic properties change.
          model.getGeneticProperties().on("change", api.setup);
        },

        renderText = function(container, txt, fontSize, dx, dy, markerPos) {
          var x = 0,
              xAttr = "",
              textElement,
              i, len;

          // Necessary for example in Firefox.
          fontSize += "px";

          for (i = 0, len = txt.length; i < len; i++) {
            xAttr += x + "px ";
            x += dx;
          }

          if (markerPos === undefined || markerPos === "end") {
            markerPos = txt.length / 3;
          }
          markerPos *= 3;

          // Text shadow.
          container.append("text")
            .text(txt)
            .attr({
              "class": "shadow",
              "x": xAttr,
              "dy": dy
            })
            .style({
                "stroke-width": model2px(0.01),
                "font-size": fontSize
            });

          // Final text.
          textElement = container.append("text")
            .attr({
              "class": "front",
              "x": xAttr,
              "dy": dy
            })
            .style("font-size", fontSize);

          textElement.append("tspan")
            .text(txt.substring(0, markerPos));
          textElement.append("tspan")
            .attr("class", "marked-mrna")
            .text(txt.substring(markerPos, markerPos + 3));
          textElement.append("tspan")
            .text(txt.substring(markerPos + 3));
        };

    api = {
      setup: function () {
        var props = model.getGeneticProperties().get(),
            dnaGElement, fontSize, dx;

        if (props === undefined) {
          return;
        }

        container.selectAll("g.dna").remove();

        dnaGElement = container.append("g").attr({
          "class": "dna",
          // (0nm, 0nm) + small, constant offset in px.
          "transform": "translate(" + model2px(props.x) + "," + model2pxInv(props.y) + ")"
        });

        fontSize = model2px(props.height);
        dx = model2px(props.width);

        // DNA code on sense strand.
        renderText(dnaGElement, props.DNA, fontSize, dx, -fontSize);
        // DNA complementary sequence.
        renderText(dnaGElement, props.DNAComplement, fontSize, dx, 0);
        // mRNA (if available).
        if (props.mRNA !== undefined) {
          renderText(dnaGElement, props.mRNA, fontSize, dx, -2.5 * fontSize, props.translationStep);
        }
      }
    };

    init();

    return api;
  };
});


/*
  A simple function to wrap a string of text into an SVG text node of a given width
  by creating tspans and adding words to them until the computedTextLength of the
  tspan is greater than the desired width. Returns the number of lines.

  If no wrapping is desired, use maxWidth=-1
*/


(function() {

  define('cs!common/layout/wrap-svg-text',['require'],function(require) {
    var svgUrl, wrapSVGText;
    svgUrl = "http://www.w3.org/2000/svg";
    return wrapSVGText = window.wrapSVGText = function(text, svgTextNode, maxWidth, x, dy) {
      var computedTextLength, curLineLength, dashArray, dashes, i, lastWord, line, numLines, result, tempText, textNode, tspanNode, widestWidth, word, words, _i, _len;
      dashes = /-/gi;
      dashArray = (function() {
        var _results;
        _results = [];
        while (result = dashes.exec(text)) {
          _results.push(result.index);
        }
        return _results;
      })();
      words = text.split(/[\s-]/);
      curLineLength = 0;
      computedTextLength = 0;
      numLines = 1;
      widestWidth = 0;
      if (maxWidth === -1) {
        maxWidth = Infinity;
      }
      for (i = _i = 0, _len = words.length; _i < _len; i = ++_i) {
        word = words[i];
        curLineLength += word.length + 1;
        if (computedTextLength > maxWidth || i === 0) {
          if (i > 0) {
            tempText = tspanNode.firstChild.nodeValue;
            if (tempText.length > words[i - 1].length + 1) {
              lastWord = tempText.slice(tempText.length - words[i - 1].length - 1);
              tspanNode.firstChild.nodeValue = tempText.slice(0, tempText.length - words[i - 1].length - 1);
            } else if (tempText.length === words[i - 1].length + 1) {
              tspanNode.firstChild.nodeValue = tempText.slice(0, tempText.length - 1);
            }
            widestWidth = Math.max(tspanNode.getComputedTextLength(), widestWidth);
            numLines++;
          }
          tspanNode = document.createElementNS(svgUrl, "tspan");
          tspanNode.setAttributeNS(null, "x", x);
          tspanNode.setAttributeNS(null, "dy", i === 0 ? 0 : dy);
          textNode = document.createTextNode(line);
          tspanNode.appendChild(textNode);
          svgTextNode.appendChild(tspanNode);
          if (~dashArray.indexOf(curLineLength - 1)) {
            line = word + "-";
          } else {
            line = word + " ";
          }
          if (i && lastWord) {
            line = lastWord + line;
          }
        } else {
          if (~dashArray.indexOf(curLineLength - 1)) {
            line += word + "-";
          } else {
            line += word + " ";
          }
        }
        tspanNode.firstChild.nodeValue = line;
        computedTextLength = tspanNode.getComputedTextLength();
        if (i && i === words.length - 1 && computedTextLength > maxWidth) {
          tempText = tspanNode.firstChild.nodeValue;
          tspanNode.firstChild.nodeValue = tempText.slice(0, tempText.length - words[i].length - 1);
          tspanNode = document.createElementNS(svgUrl, "tspan");
          tspanNode.setAttributeNS(null, "x", x);
          tspanNode.setAttributeNS(null, "dy", dy);
          textNode = document.createTextNode(words[i]);
          tspanNode.appendChild(textNode);
          svgTextNode.appendChild(tspanNode);
          numLines++;
        }
      }
      if (widestWidth === 0) {
        widestWidth = svgTextNode.childNodes[0].getComputedTextLength();
      }
      return {
        lines: numLines,
        width: widestWidth
      };
    };
  });

}).call(this);

/*global $ alert define: false, d3: false */
// ------------------------------------------------------------
//
//   MD2D View Renderer
//
// ------------------------------------------------------------
define('md2d/views/renderer',['require','lab.config','common/console','cs!md2d/views/aminoacid-context-menu','md2d/views/genetic-renderer','cs!common/layout/wrap-svg-text','common/views/gradients'],function (require) {
  // Dependencies.
  var labConfig             = require('lab.config'),
      console               = require('common/console'),
      amniacidContextMenu   = require('cs!md2d/views/aminoacid-context-menu'),
      GeneticRenderer       = require('md2d/views/genetic-renderer'),
      wrapSVGText           = require('cs!common/layout/wrap-svg-text'),
      gradients             = require('common/views/gradients'),

      RADIAL_BOND_TYPES = {
        STANDARD_STICK  : 101,
        LONG_SPRING     : 102,
        BOND_SOLID_LINE : 103,
        GHOST           : 104,
        UNICOLOR_STICK  : 105,
        SHORT_SPRING    : 106,
        DOUBLE_BOND     : 107,
        TRIPLE_BOND     : 108,
        DISULPHIDE_BOND : 109
      };

  return function MD2DView(model, containers, model2px, model2pxInv) {
        // Public API object to be returned.
    var api = {},

        // The model function get_results() returns a 2 dimensional array
        // of particle indices and properties that is updated every model tick.
        // This array is not garbage-collected so the view can be assured that
        // the latest modelResults will be in this array when the view is executing
        modelResults,
        modelElements,
        modelWidth,
        modelHeight,
        aspectRatio,

        // "Containers" - SVG g elements used to position layers of the final visualization.
        mainContainer        = containers.mainContainer,
        radialBondsContainer = containers.radialBondsContainer,
        VDWLinesContainer    = containers.VDWLinesContainer,
        imageContainerBelow  = containers.imageContainerBelow,
        imageContainerTop    = containers.imageContainerTop,
        textContainerBelow   = containers.textContainerBelow,
        textContainerTop     = containers.textContainerTop,

        dragOrigin,

        // Renderers specific for MD2D
        // TODO: for now only DNA is rendered in a separate class, try to create
        // new renderers in separate files for clarity and easier testing.
        geneticRenderer,

        gradientNameForElement,
        // Set of gradients used for Kinetic Energy Shading.
        gradientNameForKELevel = [],
        // Number of gradients used for Kinetic Energy Shading.
        KE_SHADING_STEPS = 25,
        // Array which defines a gradient assigned to a given particle.
        gradientNameForParticle = [],

        atomTooltipOn,

        particle, label, labelEnter,
        moleculeDiv, moleculeDivPre,

        // for model clock
        timeLabel,
        modelTimeFormatter = d3.format("5.1f"),
        timePrefix = "",
        timeSuffix = " (ps)",

        radialBonds,
        radialBondResults,
        obstacle,
        obstacles,
        mockObstaclesArray = [],
        radialBond1, radialBond2,
        vdwPairs = [],
        vdwLines,
        chargeShadingMode,
        keShadingMode,
        drawVdwLines,
        drawVelocityVectors,
        velocityVectorColor,
        velocityVectorWidth,
        velocityVectorLength,
        drawForceVectors,
        forceVectorColor,
        forceVectorWidth,
        forceVectorLength,
        velVector,
        forceVector,
        imageProp,
        imageMapping,
        imageSizes = [],
        textBoxes,
        imagePath,
        drawAtomTrace,
        atomTraceId,
        atomTraceColor,
        atomTrace,
        atomTracePath,
        showClock,

        VELOCITY_STR = "velocity",
        FORCE_STR    = "force";


    function modelTimeLabel() {
      return timePrefix + modelTimeFormatter(model.get('time')/1000) + timeSuffix;
    }

    function setAtomPosition(i, xpos, ypos, checkPosition, moveMolecule) {
      return model.setAtomProperties(i, {x: xpos, y: ypos}, checkPosition, moveMolecule);
    }

    function getObstacleColor(i) {
      return "rgb(" +
        obstacles.colorR[i] + "," +
        obstacles.colorG[i] + "," +
        obstacles.colorB[i] + ")";
    }

    // Pass in the signed 24-bit Integer used for Java MW elementColors
    // See: https://github.com/mbostock/d3/wiki/Colors
    function createElementColorGradient(id, signedInt, mainContainer) {
      var colorstr = (signedInt + Math.pow(2, 24)).toString(16),
          color,
          medColor,
          lightColor,
          darkColor,
          i;

      for (i = colorstr.length; i < 6; i++) {
        colorstr = String(0) + colorstr;
      }
      color      = d3.rgb("#" + colorstr);
      medColor   = color.toString();
      lightColor = color.brighter(1).toString();
      darkColor  = color.darker(1).toString();
      return gradients.createRadialGradient(id, lightColor, medColor, darkColor, mainContainer);
    }

    function createAdditionalGradients() {
          // Scale used for Kinetic Energy Shading gradients.
      var medColorScale = d3.scale.linear()
            .interpolate(d3.interpolateRgb)
            .range(["#F2F2F2", "#FF8080"]),
          // Scale used for Kinetic Energy Shading gradients.
          darkColorScale = d3.scale.linear()
            .interpolate(d3.interpolateRgb)
            .range(["#A4A4A4", "#FF2020"]),
          gradientName,
          gradientUrl,
          KELevel,
          i;

      // Kinetic Energy Shading gradients
      for (i = 0; i < KE_SHADING_STEPS; i++) {
        gradientName = "ke-shading-" + i;
        KELevel = i / KE_SHADING_STEPS;
        gradientUrl = gradients.createRadialGradient(gradientName, "#FFFFFF", medColorScale(KELevel),
          darkColorScale(KELevel), mainContainer);
        gradientNameForKELevel[i] = gradientUrl;
      }

      for (i= 0; i < 4; i++) {
        createElementColorGradient("elem" + i + "-grad", modelElements.color[i], mainContainer);
      }
      gradientNameForElement = ["url(#elem0-grad)", "url(#elem1-grad)", "url(#elem2-grad)", "url(#elem3-grad)"];
    }

    function createVectorArrowHeads(color, name) {
      var arrowHead = mainContainer.append("defs")
        .append("marker")
        .attr("id", "Triangle-"+name)
        .attr("viewBox", "0 0 10 10")
        .attr("refX", "0")
        .attr("refY", "5")
        .attr("markerUnits", "strokeWidth")
        .attr("markerWidth", "4")
        .attr("markerHeight", "3")
        .attr("orient", "auto")
        .attr("stroke", color)
        .attr("fill", color);
      arrowHead.append("path")
          .attr("d", "M 0 0 L 10 5 L 0 10 z");
    }

    // Returns gradient appropriate for a given atom.
    // d - atom data.
    function getParticleGradient(d) {
        var ke, keIndex, charge;

        if (d.marked) return "url(#mark-grad)";

        if (keShadingMode) {
          ke  = model.getAtomKineticEnergy(d.idx),
          // Convert Kinetic Energy to [0, 1] range
          // using empirically tested transformations.
          // K.E. shading should be similar to the classic MW K.E. shading.
          keIndex = Math.min(5 * ke, 1);

          return gradientNameForKELevel[Math.round(keIndex * (KE_SHADING_STEPS - 1))];
        }

        if (chargeShadingMode) {
          charge = d.charge;

          if (charge === 0) return "url(#neutral-grad)";
          return charge > 0 ? "url(#pos-grad)" : "url(#neg-grad)";
        }

        if (!d.isAminoAcid()) {
          return gradientNameForElement[d.element % 4];
        }
        // Particle represents amino acid.
        switch (model.get("aminoAcidColorScheme")) {
          case "none":
            return "url(#neutral-grad)";
          case "hydrophobicity":
            return d.hydrophobicity > 0 ? "url(#orange-grad)" : "url(#green-grad)";
          case "charge":
            if (d.charge === 0) return "url(#neutral-grad)";
            return d.charge > 0 ? "url(#pos-grad)" : "url(#neg-grad)";
          case "chargeAndHydro":
            if (d.charge < -0.000001)
              return "url(#neg-grad)";
            if (d.charge > 0.000001)
              return "url(#pos-grad)";
            return d.hydrophobicity > 0 ? "url(#orange-grad)" : "url(#green-grad)";
          default:
            throw new Error("ModelContainer: unknown amino acid color scheme.");
        }
    }

    // Returns first color appropriate for a given radial bond (color next to atom1).
    // d - radial bond data.
    function getBondAtom1Color(d) {
      if (isSpringBond(d)) {
        return "#888";
      } else {
        return gradients.mainColorOfGradient[gradientNameForParticle[d.atom1]];
      }
    }

    // Returns second color appropriate for a given radial bond (color next to atom2).
    // d - radial bond data.
    function getBondAtom2Color(d) {
      if (isSpringBond(d)) {
        return "#888";
      } else {
        return gradients.mainColorOfGradient[gradientNameForParticle[d.atom2]];
      }
    }

    // Create key images which can be shown in the
    // upper left corner in different situations.
    // IMPORTANT: use percentage values whenever possible,
    // especially for *height* attribute!
    // It will allow to properly calculate images
    // placement in drawSymbolImages() function.
    function createSymbolImages() {
      var xMargin = "1%";
      // only add these images if they don't already exist
      if ($("#heat-bath").length === 0) {
        // Heat bath key image.
        mainContainer.append("image")
            .attr({
              "id": "heat-bath",
              "x": xMargin,
              "width": "3%",
              "height": "3%",
              "preserveAspectRatio": "xMinYMin",
              "xlink:href": "../../resources/heatbath.gif"
            });
      }
      if ($("#ke-gradient").length === 0) {
        // Kinetic Energy Shading gradient image.
        mainContainer.append("image")
            .attr({
              "id": "ke-gradient",
              "x": xMargin,
              "width": "12%",
              "height": "12%",
              "preserveAspectRatio": "xMinYMin",
              "xlink:href": "../../resources/ke-gradient.png"
            });
      }
    }

    // Draw key images in the upper left corner.
    // Place them in one row, dynamically calculate
    // y position.
    function drawSymbolImages() {
        var heatBath = model.get('temperatureControl'),
            imageSelect, imageHeight,
            // Variables used for calculating proper y positions.
            // The unit for these values is percentage points!
            yPos = 0,
            yMargin = 1;

        // Heat bath symbol.
        if (heatBath) {
            yPos += yMargin;
            imageSelect = d3.select("#heat-bath")
              .attr("y", yPos + "%")
              .style("display", "");

            imageHeight = imageSelect.attr("height");
            // Truncate % symbol and convert to Number.
            imageHeight = Number(imageHeight.substring(0, imageHeight.length - 1));
            yPos += imageHeight;
        } else {
            d3.select("#heat-bath").style("display","none");
        }

        // Kinetic Energy shading gradient.
        // Put it under heat bath symbol.
        if (keShadingMode) {
            yPos += yMargin;
            d3.select("#ke-gradient")
              .attr("y", yPos + "%")
              .style("display", "");
        } else {
            d3.select("#ke-gradient").style("display", "none");
        }
    }

    function updateParticleRadius() {
      mainContainer.selectAll("circle").data(modelResults).attr("r",  function(d) { return model2px(d.radius); });
    }

    /**
      Call this wherever a d3 selection is being used to add circles for atoms
    */

    function particleEnter() {
      particle.enter().append("circle")
          .attr({
            "class": function (d) { return d.isAminoAcid() ? "draggable amino-acid" : "draggable"; },
            "r":  function(d) { return model2px(d.radius); },
            "cx": function(d) { return model2px(d.x); },
            "cy": function(d) { return model2pxInv(d.y); }
          })
          .style({
            "fill-opacity": function(d) { return d.visible; },
            "fill": function (d, i) { return gradientNameForParticle[i]; }
          })
          .on("mousedown", moleculeMouseDown)
          .on("mouseover", moleculeMouseOver)
          .on("mouseout", moleculeMouseOut)
          .call(d3.behavior.drag()
            .on("dragstart", nodeDragStart)
            .on("drag", nodeDrag)
            .on("dragend", nodeDragEnd)
          );
    }

    function vectorEnter(vector, pathFunc, widthFunc, color, name) {
      vector.enter().append("path")
        .attr({
          "class": "vector-"+name,
          "marker-end": "url(#Triangle-"+name+")",
          "d": pathFunc
        })
        .style({
          "stroke-width": widthFunc,
          "stroke": color,
          "fill": "none"
        });
    }

    function atomTraceEnter() {
      atomTrace.enter().append("path")
        .attr({
          "class": "atomTrace",
          "d": getAtomTracePath
        })
        .style({
          "stroke-width": model2px(0.01),
          "stroke": atomTraceColor,
          "fill": "none",
          "stroke-dasharray": "6, 6"
        });
    }

    function obstacleEnter() {
      var obstacleGroup = obstacle.enter().append("g");

      obstacleGroup
        .attr("class", "obstacle")
        .attr("transform",
          function (d, i) {
            return "translate(" + model2px(obstacles.x[i]) + " " + model2pxInv(obstacles.y[i] + obstacles.height[i]) + ")";
          }
        );
      obstacleGroup.append("rect")
        .attr({
          "class": "obstacle-shape",
          "x": 0,
          "y": 0,
          "width": function(d, i) {return model2px(obstacles.width[i]); },
          "height": function(d, i) {return model2px(obstacles.height[i]); }
        })
        .style({
          "fill": function(d, i) { return obstacles.visible[i] ? getObstacleColor(i) : "rgba(128,128,128, 0)"; },
          "stroke-width": function(d, i) { return obstacles.visible[i] ? 0.2 : 0.0; },
          "stroke": function(d, i) { return obstacles.visible[i] ? getObstacleColor(i) : "rgba(128,128,128, 0)"; }
        });

      // Append external force markers.
      obstacleGroup.each(function (d, i) {
        // Fast path, if no forces are defined.
        if (!obstacles.externalFx[i] && !obstacles.externalFy[i])
          return;

        // Note that arrows indicating obstacle external force use
        // the same options for styling like arrows indicating atom force.
        // Only their length is fixed.
        var obstacleGroupEl = d3.select(this),
            obsHeight = obstacles.height[i],
            obsWidth = obstacles.width[i],
            obsFx = obstacles.externalFx[i],
            obsFy = obstacles.externalFy[i],
            // Use fixed length of force vectors (in nm).
            vecLen = 0.06,
            space = 0.06,
            step, coords;

        // Set arrows indicating horizontal force.
        if (obsFx) {
          // Make sure that arrows keep constant distance between both ends of an obstacle.
          step = (obsHeight - 2 * space) / Math.round((obsHeight - 2 * space) / 0.2);
          coords = d3.range(space, obsHeight, step);
          obstacleGroupEl.selectAll("path.obstacle-force-hor").data(coords).enter().append("path")
            .attr({
              "class": "obstacle-force-hor",
              "d": function (d) {
                if (obsFx < 0)
                  return "M " + model2px(obsWidth + vecLen + space) + "," + model2px(d) + " L " + model2px(obsWidth + space) + "," + model2px(d);
                else
                  return "M " + model2px(-vecLen - space) + "," + model2px(d) + " L " + model2px(-space) + "," + model2px(d);
              }
            });
        }
        // Later set arrows indicating vertical force.
        if (obsFy) {
          // Make sure that arrows keep constant distance between both ends of an obstacle.
          step = (obsWidth - 2 * space) / Math.round((obsWidth - 2 * space) / 0.2);
          coords = d3.range(space, obsWidth, step);
          obstacleGroupEl.selectAll("path.obstacle-force-vert").data(coords).enter().append("path")
            .attr({
              "class": "obstacle-force-vert",
              "d": function (d) {
                if (obsFy < 0)
                  return "M " + model2px(d) + "," + model2px(-vecLen - space) + " L " + model2px(d) + "," + model2px(-space);
                else
                  return "M " + model2px(d) + "," + model2px(obsHeight + vecLen + space) + " L " + model2px(d) + "," + model2px(obsHeight + space);
              }
            });
        }
        // Finally, set common attributes and stying for both vertical and horizontal forces.
        obstacleGroupEl.selectAll("path.obstacle-force-hor, path.obstacle-force-vert")
          .attr({
            "marker-end": "url(#Triangle-"+ FORCE_STR +")"
          })
          .style({
            "stroke-width": model2px(forceVectorWidth),
            "stroke": forceVectorColor,
            "fill": "none"
          });
      });
    }

    function radialBondEnter() {
      radialBond1.enter().append("path")
          .attr("d", function (d) {
            return findPoints(d,1);})
          .classed("radialbond1", true)
          .classed("disulphideBond", function (d) {
            return d.type === RADIAL_BOND_TYPES.DISULPHIDE_BOND;
          })
          .style("stroke-width", function (d) {
            if (isSpringBond(d)) {
              return Math.log(d.strength) / 4 + model2px(0.005);
            } else {
              return model2px(Math.min(modelResults[d.atom1].radius, modelResults[d.atom2].radius)) * 0.75;
            }
          })
          .style("stroke", getBondAtom1Color)
          .style("fill", "none");

      radialBond2.enter().append("path")
          .attr("d", function (d) {
            return findPoints(d,2); })
          .classed("radialbond2", true)
          .classed("disulphideBond", function (d) {
            return d.type === RADIAL_BOND_TYPES.DISULPHIDE_BOND;
          })
          .style("stroke-width", function (d) {
            if (isSpringBond(d)) {
              return Math.log(d.strength) / 4 + model2px(0.005);
            } else {
              return model2px(Math.min(modelResults[d.atom1].radius, modelResults[d.atom2].radius)) * 0.75;
            }
          })
          .style("stroke", getBondAtom2Color)
          .style("fill", "none");
    }

    function findPoints(d, num) {
      var pointX, pointY,
          j,
          dx, dy,
          x1, x2,
          y1, y2,
          radius_x1, radius_x2, radiusFactorX,
          radius_y1, radius_y2, radiusFactorY,
          path,
          costheta,
          sintheta,
          length,
          strength,
          numTurns,
          springDiameter,
          cosThetaDiameter,
          sinThetaDiameter,
          cosThetaSpikes,
          sinThetaSpikes;

      x1 = model2px(d.x1);
      y1 = model2pxInv(d.y1);
      x2 = model2px(d.x2);
      y2 = model2pxInv(d.y2);
      dx = x2 - x1;
      dy = y2 - y1;

      strength = d.strength;
      length = Math.sqrt(dx*dx + dy*dy) / model2px(0.01);

      numTurns = Math.floor(d.length * 24);
      springDiameter = length / numTurns;

      costheta = dx / length;
      sintheta = dy / length;
      cosThetaDiameter = costheta * springDiameter;
      sinThetaDiameter = sintheta * springDiameter;
      cosThetaSpikes = costheta * numTurns;
      sinThetaSpikes = sintheta * numTurns;

      radius_x1 = model2px(modelResults[d.atom1].radius) * costheta;
      radius_x2 = model2px(modelResults[d.atom2].radius) * costheta;
      radius_y1 = model2px(modelResults[d.atom1].radius) * sintheta;
      radius_y2 = model2px(modelResults[d.atom2].radius) * sintheta;
      radiusFactorX = radius_x1 - radius_x2;
      radiusFactorY = radius_y1 - radius_y2;

      if (isSpringBond(d)) {
        path = "M "+x1+","+y1+" " ;
        for (j = 0; j < numTurns; j++) {
          if (j % 2 === 0) {
            pointX = x1 + (j + 0.5) * cosThetaDiameter - 0.5 * sinThetaSpikes;
            pointY = y1 + (j + 0.5) * sinThetaDiameter + 0.5 * cosThetaSpikes;
          }
          else {
            pointX = x1 + (j + 0.5) * cosThetaDiameter + 0.5 * sinThetaSpikes;
            pointY = y1 + (j + 0.5) * sinThetaDiameter - 0.5 * cosThetaSpikes;
          }
          path += " L "+pointX+","+pointY;
        }
        return path += " L "+x2+","+y2;
      } else {
        if (num === 1) {
          return "M "+x1+","+y1+" L "+((x2+x1+radiusFactorX)/2)+" , "+((y2+y1+radiusFactorY)/2);
        } else {
          return "M "+((x2+x1+radiusFactorX)/2)+" , "+((y2+y1+radiusFactorY)/2)+" L "+x2+","+y2;
        }
      }
    }

    function isSpringBond(d){
      return d.type === RADIAL_BOND_TYPES.SHORT_SPRING;
    }

    function vdwLinesEnter() {
      // update existing lines
      vdwLines.attr({
        "x1": function(d) { return model2px(modelResults[d[0]].x); },
        "y1": function(d) { return model2pxInv(modelResults[d[0]].y); },
        "x2": function(d) { return model2px(modelResults[d[1]].x); },
        "y2": function(d) { return model2pxInv(modelResults[d[1]].y); }
      });

      // append new lines
      vdwLines.enter().append('line')
        .attr({
          "class": "attractionforce",
          "x1": function(d) { return model2px(modelResults[d[0]].x); },
          "y1": function(d) { return model2pxInv(modelResults[d[0]].y); },
          "x2": function(d) { return model2px(modelResults[d[1]].x); },
          "y2": function(d) { return model2pxInv(modelResults[d[1]].y); }
        })
        .style({
          "stroke-width": model2px(0.02),
          "stroke-dasharray": model2px(0.03) + " " + model2px(0.02)
        });

      // remove old lines
      vdwLines.exit().remove();
    }

    function getImagePath(imgProp) {
      return imagePath + (imageMapping[imgProp.imageUri] || imgProp.imageUri);
    }

    function drawImageAttachment() {
      var img = [],
          img_height,
          img_width,
          imgHost,
          imgHostType,
          imglayer,
          imgX, imgY,
          container,
          i;

      imageContainerTop.selectAll("image").remove();
      imageContainerBelow.selectAll("image").remove();

      if (!imageProp) return;

      for (i = 0; i < imageProp.length; i++) {
        img[i] = new Image();
        img[i].src = getImagePath(imageProp[i]);
        img[i].onload = (function(i) {
          return function() {
            imageContainerTop.selectAll("image.image_attach"+i).remove();
            imageContainerBelow.selectAll("image.image_attach"+i).remove();

            imgHost = modelResults[imageProp[i].imageHostIndex];
            imgHostType = imageProp[i].imageHostType;
            imglayer = imageProp[i].imageLayer;
            imgX = model2px(imageProp[i].imageX);
            imgY = model2pxInv(imageProp[i].imageY);
            // Cache the image width and height.
            // In Classic MW model size is defined in 0.1A.
            // Model unit (0.1A) - pixel ratio is always 1. The same applies
            // to images. We can assume that their pixel dimensions are
            // in 0.1A also. So convert them to nm (* 0.01).
            imageSizes[i] = [0.01 * img[i].width, 0.01 * img[i].height];
            img_width = model2px(imageSizes[i][0]);
            img_height = model2px(imageSizes[i][1]);

            container = imglayer === 1 ? imageContainerTop : imageContainerBelow;
            container.append("image")
              .attr("x", function() { if (imgHostType === "") { return imgX; } else { return model2px(imgHost.x) - img_width / 2; } })
              .attr("y", function() { if (imgHostType === "") { return imgY; } else { return model2pxInv(imgHost.y) - img_height / 2; } })
              .attr("class", "image_attach"+i+" draggable")
              .attr("xlink:href", img[i].src)
              .attr("width", img_width)
              .attr("height", img_height)
              .attr("pointer-events", "none");
          };
        })(i);
      }
    }

    function getTextBoxCoords(d, i) {
      var x, y, frameX, frameY;
      if (d.hostType) {
        if (d.hostType === "Atom") {
          x = modelResults[d.hostIndex].x;
          y = modelResults[d.hostIndex].y;
        } else {
          x = obstacles.x[d.hostIndex] + (obstacles.width[d.hostIndex] / 2);
          y = obstacles.y[d.hostIndex] + (obstacles.height[d.hostIndex] / 2);
        }
      } else {
        x = d.x;
        y = d.y;
      }
      frameX = x - 0.1;
      frameY = y + 0.15;
      return [model2px(x), model2pxInv(y), model2px(frameX), model2pxInv(frameY)];
    }

    function updateTextBoxes() {
      var layers = [textContainerTop, textContainerBelow],
          updateText;

      updateText = function (layerNum) {
        var layer = layers[layerNum - 1];

        layerTextBoxes = textBoxes.filter(function(t) { return t.layer == layerNum; });

        layer.selectAll("g.textBoxWrapper rect")
          .data(layerTextBoxes.filter( function(d) { return d.frame; } ))
          .attr({
            "x": function(d,i) { return getTextBoxCoords(d,i)[2]; },
            "y": function(d,i) { return getTextBoxCoords(d,i)[3]; }
          });

        layer.selectAll("g.textBoxWrapper text")
          .data(layerTextBoxes)
          .attr({
            "y": function(d,i) {
              $(this).find("tspan").attr("x", getTextBoxCoords(d,i)[0]);
              return getTextBoxCoords(d,i)[1];
            }
          });
      };

      updateText(1);
      updateText(2);
    }

    function drawTextBoxes() {
      var size, layers, appendTextBoxes;

      textBoxes = model.get('textBoxes');

      size = model.size();

      layers = [textContainerTop, textContainerBelow];

      // Append to either top or bottom layer depending on item's layer #.
      appendTextBoxes = function (layerNum) {
        var layer = layers[layerNum - 1],
            text, layerTextBoxes, selection;

        layer.selectAll("g.textBoxWrapper").remove();

        layerTextBoxes = textBoxes.filter(function(t) { return t.layer == layerNum; });

        selection = layer.selectAll("g.textBoxWrapper")
          .data(layerTextBoxes);
        text = selection.enter().append("svg:g")
          .attr("class", "textBoxWrapper");

        text.filter(function (d) { return d.frame; })
          .append("rect")
          .attr({
            "class": function(d, i) { return "textBoxFrame text-"+i; },
            "style": function(d) {
              var backgroundColor = d.backgroundColor || "white";
              return "fill:"+backgroundColor+";opacity:1.0;fill-opacity:1;stroke:#000000;stroke-width:0.5;stroke-opacity:1";
            },
            "width": 0,
            "height": 0,
            "rx": function(d)  { return d.frame == "rounded rectangle" ? 8  : 0; },
            "ry": function(d)  { return d.frame == "rounded rectangle" ? 10 : 0; },
            "x": function(d,i) { return getTextBoxCoords(d,i)[2]; },
            "y": function(d,i) { return getTextBoxCoords(d,i)[3]; }
          });

        text.append("text")
          .attr({
            "class": function() { return "textBox" + (AUTHORING ? " draggable" : ""); },
            "x-data": function(d,i) { return getTextBoxCoords(d,i)[0]; },
            "y": function(d,i)      { return getTextBoxCoords(d,i)[1]; },
            "width-data": function(d) { return model2px(d.width); },
            "width":  model2px(size[0]),
            "height": model2px(size[1]),
            "xml:space": "preserve",
            "font-family": "'Open Sans', sans-serif",
            "font-size": model2px(0.12),
            "fill": function(d) { return d.color || "black"; },
            "text-data": function(d) { return d.text; },
            "text-anchor": function(d) {
              var align = d.textAlign || "left";
              if (align === "center") align = "middle";
              return align;
            },
            "has-host": function(d) { return !!d.hostType; }
          })
          .call(d3.behavior.drag()
            .on("drag", textDrag)
            .on("dragend", function(d) {
              // simple output to console for now, eventually should just get
              // serialized back to interactive (or model?) JSON on author save
              console.log('"x": '+d.x+",");
              console.log('"y": '+d.y+",");
            })
          );
        selection.exit().remove();
      };

      appendTextBoxes(1);
      appendTextBoxes(2);

      // wrap text
      $(".textBox").each( function() {
        var text  = this.getAttributeNS(null, "text-data"),
            x     = this.getAttributeNS(null, "x-data"),
            width = this.getAttributeNS(null, "width-data") || -1,
            dy    = model2px(0.16),
            hasHost = this.getAttributeNS(null, "has-host"),
            textAlign = this.getAttributeNS(null, "text-anchor"),
            result, frame, dx;

        while (this.firstChild) {     // clear element first
          this.removeChild(this.firstChild);
        }

        result = wrapSVGText(text, this, width, x, dy);

        if (this.parentNode.childElementCount > 1) {
          frame = this.parentNode.childNodes[0];
          frame.setAttributeNS(null, "width", result.width + model2px(0.2));
          frame.setAttributeNS(null, "height", (result.lines * dy) + model2px(0.06));
        }

        // center all hosted labels simply by tweaking the g.transform
        if (textAlign === "middle") {
          dx = result.width / 2;
          $(this).attr("transform", "translate("+dx+",0)");
        }
        if (hasHost === "true") {
          dx = -result.width / 2;
          dy = (result.lines-1) * dy / -2 + 4.5;
          $(this.parentNode).attr("transform", "translate("+dx+","+dy+")");
        }
      });
    }

    function setupColorsOfParticles() {
      var i, len;

      chargeShadingMode = model.get("chargeShading");
      keShadingMode = model.get("keShading");

      gradientNameForParticle.length = modelResults.length;
      for (i = 0, len = modelResults.length; i < len; i++)
        gradientNameForParticle[i] = getParticleGradient(modelResults[i]);
    }

    function setupParticles() {
      var showChargeSymbols = model.get("showChargeSymbols"),
          useThreeLetterCode = model.get("useThreeLetterCode");

      mainContainer.selectAll("circle").remove();
      mainContainer.selectAll("g.label").remove();

      particle = mainContainer.selectAll("circle").data(modelResults);
      updateParticleRadius();

      particleEnter();

      label = mainContainer.selectAll("g.label")
          .data(modelResults);

      labelEnter = label.enter().append("g")
          .attr("class", "label")
          .attr("transform", function(d) {
            return "translate(" + model2px(d.x) + "," + model2pxInv(d.y) + ")";
          });

      labelEnter.each(function (d) {
        var selection = d3.select(this),
            txtValue, txtSelection;
        // Append appropriate label. For now:
        // If 'atomNumbers' option is enabled, use indices.
        // If not and there is available 'label'/'symbol' property, use one of them
        // (check 'useThreeLetterCode' option to decide which one).
        // If not and 'showChargeSymbols' option is enabled, use charge symbols.
        if (model.get("atomNumbers")) {
          selection.append("text")
            .text(d.idx)
            .style("font-size", model2px(1.4 * d.radius) + "px");
        }
        else if (useThreeLetterCode && d.label) {
          // Add shadow - a white stroke, which increases readability.
          selection.append("text")
            .text(d.label)
            .attr("class", "shadow")
            .style("font-size", model2px(d.radius) + "px");
          selection.append("text")
            .text(d.label)
            .style("font-size", model2px(d.radius) + "px");
        }
        else if (!useThreeLetterCode && d.symbol) {
          // Add shadow - a white stroke, which increases readability.
          selection.append("text")
            .text(d.symbol)
            .attr("class", "shadow")
            .style("font-size", model2px(1.4 * d.radius) + "px");
          selection.append("text")
            .text(d.symbol)
            .style("font-size", model2px(1.4 * d.radius) + "px");
        }
        else if (showChargeSymbols) {
          if (d.charge > 0){
            txtValue = "+";
          } else if (d.charge < 0){
            txtValue = "-";
          } else {
            return;
          }
          selection.append("text")
            .text(txtValue)
            .style("font-size", model2px(1.6 * d.radius) + "px");
        }
        // Set common attributes for labels (+ shadows).
        txtSelection = selection.selectAll("text");
        // Check if node exists and if so, set appropriate attributes.
        if (txtSelection.node()) {
          txtSelection
            .attr("pointer-events", "none")
            .style({
              "font-weight": "bold",
              "opacity": 0.7
            });
          txtSelection
            .attr({
              // Center labels, use real width and height.
              // Note that this attrs should be set *after* all previous styling options.
              // .node() will return first node in selection. It's OK - both texts
              // (label and its shadow) have the same dimension.
              "x": -txtSelection.node().getComputedTextLength() / 2,
              "y": "0.31em"//bBox.height / 4
            });
        }
        // Set common attributes for shadows.
        selection.select("text.shadow")
          .style({
            "stroke": "#fff",
            "stroke-width": 0.15 * model2px(d.radius),
            "stroke-opacity": 0.7
          });
      });
    }

    function setupObstacles() {
      obstacles = model.get_obstacles();
      mainContainer.selectAll("g.obstacle").remove();
      if (obstacles) {
        mockObstaclesArray.length = obstacles.x.length;
        obstacle = mainContainer.selectAll("g.obstacle").data(mockObstaclesArray);
        obstacleEnter();
      }
    }

    function setupRadialBonds() {
      radialBondsContainer.selectAll("path.radialbond1").remove();
      radialBondsContainer.selectAll("path.radialbond2").remove();
      radialBonds = model.get_radial_bonds();
      radialBondResults = model.get_radial_bond_results();
      if (radialBondResults) {
        radialBond1 = radialBondsContainer.selectAll("path.radialbond1").data(radialBondResults);
        radialBond2 = radialBondsContainer.selectAll("path.radialbond2").data(radialBondResults);
        radialBondEnter();
      }
    }

    function setupVdwPairs() {
      VDWLinesContainer.selectAll("line.attractionforce").remove();
      updateVdwPairsArray();
      drawVdwLines = model.get("showVDWLines");
      if (drawVdwLines) {
        vdwLines = VDWLinesContainer.selectAll("line.attractionforce").data(vdwPairs);
        vdwLinesEnter();
      }
    }

    // The vdw hash returned by md2d consists of typed arrays of length N*N-1/2
    // To make these d3-friendly we turn them into an array of atom pairs, only
    // as long as we need.
    function updateVdwPairsArray() {
      var vdwHash = model.get_vdw_pairs();
      for (var i = 0; i < vdwHash.count; i++) {
        vdwPairs[i] = [vdwHash.atom1[i], vdwHash.atom2[i]];
      }
      // if vdwPairs was longer at the previous tick, trim the end
      vdwPairs.splice(vdwHash.count);
    }

    function setupVectors() {
      mainContainer.selectAll("path.vector-"+VELOCITY_STR).remove();
      mainContainer.selectAll("path.vector-"+FORCE_STR).remove();

      drawVelocityVectors = model.get("showVelocityVectors");
      drawForceVectors    = model.get("showForceVectors");
      if (drawVelocityVectors) {
        velVector = mainContainer.selectAll("path.vector-"+VELOCITY_STR).data(modelResults);
        vectorEnter(velVector, getVelVectorPath, getVelVectorWidth, velocityVectorColor, VELOCITY_STR);
      }
      if (drawForceVectors) {
        forceVector = mainContainer.selectAll("path.vector-"+FORCE_STR).data(modelResults);
        vectorEnter(forceVector, getForceVectorPath, getForceVectorWidth, forceVectorColor, FORCE_STR);
      }
    }

    function setupAtomTrace() {
      mainContainer.selectAll("path.atomTrace").remove();
      atomTracePath = "";

      drawAtomTrace = model.get("showAtomTrace");
      atomTraceId = model.get("atomTraceId");
      if (drawAtomTrace) {
        atomTrace = mainContainer.selectAll("path.atomTrace").data([modelResults[atomTraceId]]);
        atomTraceEnter();
      }
    }

    function updateVdwPairs() {
      // Get new set of pairs from model.
      updateVdwPairsArray();

      vdwLines = VDWLinesContainer.selectAll("line.attractionforce").data(vdwPairs);
      vdwLinesEnter();
    }

    function mousedown() {
      setFocus();
    }

    function setFocus() {
      if (model.get("enableKeyboardHandlers")) {
        containers.node.focus();
      }
    }

    function moleculeMouseOver(d, i) {
      if (model.get("enableAtomTooltips")) {
        renderAtomTooltip(i);
      }
    }

    function moleculeMouseDown(d, i) {
      containers.node.focus();
      if (model.get("enableAtomTooltips")) {
        if (atomTooltipOn !== false) {
          moleculeDiv.style("opacity", 1e-6);
          moleculeDiv.style("display", "none");
          atomTooltipOn = false;
        } else {
          if (d3.event.shiftKey) {
            atomTooltipOn = i;
          } else {
            atomTooltipOn = false;
          }
          renderAtomTooltip(i);
        }
      }
    }

    function renderAtomTooltip(i) {
      moleculeDiv
            .style("opacity", 1.0)
            .style("display", "inline")
            .style("background", "rgba(100%, 100%, 100%, 0.7)")
            .style("left", model2px(modelResults[i].x) + 60 + "px")
            .style("top",  model2pxInv(modelResults[i].y) + 30 + "px")
            .style("zIndex", 100)
            .transition().duration(250);

      moleculeDivPre.text(
          "atom: " + i + "\n" +
          "time: " + modelTimeLabel() + "\n" +
          "speed: " + d3.format("+6.3e")(modelResults[i].speed) + "\n" +
          "vx:    " + d3.format("+6.3e")(modelResults[i].vx)    + "\n" +
          "vy:    " + d3.format("+6.3e")(modelResults[i].vy)    + "\n" +
          "ax:    " + d3.format("+6.3e")(modelResults[i].ax)    + "\n" +
          "ay:    " + d3.format("+6.3e")(modelResults[i].ay)    + "\n"
        );
    }

    function moleculeMouseOut() {
      if (!atomTooltipOn && atomTooltipOn !== 0) {
        moleculeDiv.style("opacity", 1e-6).style("zIndex" -1);
      }
    }

    function updateDrawablePositions() {
      console.time('view update');
      if (obstacles) {
        obstacle.attr("transform", function (d, i) {
          return "translate(" + model2px(obstacles.x[i]) + " " + model2pxInv(obstacles.y[i] + obstacles.height[i]) + ")";
        });
      }

      if (drawVdwLines) {
        updateVdwPairs();
      }
      // When Kinetic Energy Shading is enabled, update style of atoms
      // during each frame.
      if (keShadingMode) {
        setupColorsOfParticles();
      }
      if (radialBondResults) {
        updateRadialBonds();
      }
      updateParticles();
      if (drawVelocityVectors) {
        updateVectors(velVector, getVelVectorPath, getVelVectorWidth);
      }
      if (drawForceVectors) {
        updateVectors(forceVector, getForceVectorPath, getForceVectorWidth);
      }
      if (drawAtomTrace) {
        updateAtomTrace();
      }
      if(imageProp && imageProp.length !== 0) {
        updateImageAttachment();
      }
      if (textBoxes && textBoxes.length > 0) {
        updateTextBoxes();
      }
      console.timeEnd('view update');
    }

    // TODO: this function name seems to be inappropriate to
    // its content.
    function updateParticles() {
      particle.attr({
        "cx": function(d) { return model2px(d.x); },
        "cy": function(d) { return model2pxInv(d.y); }
      });

      if (keShadingMode) {
        // Update particles color. Array of colors should be already updated.
        particle.style("fill", function (d, i) { return gradientNameForParticle[i]; });
      }

      label.attr("transform", function (d) {
        return "translate(" + model2px(d.x) + "," + model2pxInv(d.y) + ")";
      });

      if (atomTooltipOn === 0 || atomTooltipOn > 0) {
        renderAtomTooltip(atomTooltipOn);
      }
    }

    function getVelVectorPath(d) {
      var x_pos = model2px(d.x),
          y_pos = model2pxInv(d.y),
          path = "M "+x_pos+","+y_pos,
          scale = velocityVectorLength * 100;
      return path + " L "+(x_pos + model2px(d.vx*scale))+","+(y_pos - model2px(d.vy*scale));
    }

    function getForceVectorPath(d) {
      var x_pos = model2px(d.x),
          y_pos = model2pxInv(d.y),
          mass  = d.mass,
          scale = forceVectorLength * 100,
          path  = "M "+x_pos+","+y_pos;
      return path + " L "+(x_pos + model2px(d.ax*mass*scale))+","+(y_pos - model2px(d.ay*mass*scale));
    }

    function getVelVectorWidth(d) {
      return Math.abs(d.vx) + Math.abs(d.vy) > 1e-6 ? model2px(velocityVectorWidth) : 0;
    }

    function getForceVectorWidth(d) {
      return Math.abs(d.ax) + Math.abs(d.ay) > 1e-8 ? model2px(forceVectorWidth) : 0;
    }

    function updateVectors(vector, pathFunc, widthFunc) {
      vector.attr({
         "d": pathFunc
      })
      .style({
        "stroke-width": widthFunc
      });
    }

    function getAtomTracePath(d) {
      // until we implement buffered array model output properties,
      // we just keep the path history in the path string
      var dx = Math.floor(model2px(d.x) * 100) / 100,
          dy = Math.floor(model2pxInv(d.y) * 100) / 100,
          lIndex, sIndex;
      if (!atomTracePath) {
        atomTracePath = "M"+dx+","+dy+"L";
        return "M "+dx+","+dy;
      } else {
        atomTracePath += dx+","+dy + " ";
      }

      // fake buffered array functionality by knocking out the first
      // element of the string when we get too big
      if (atomTracePath.length > 4000) {
        lIndex = atomTracePath.indexOf("L");
        sIndex = atomTracePath.indexOf(" ");
        atomTracePath = "M" + atomTracePath.slice(lIndex+1, sIndex) + "L" + atomTracePath.slice(sIndex+1);
      }
      return atomTracePath;
    }

    function updateAtomTrace() {
      atomTrace.attr({
        "d": getAtomTracePath
      });
    }

    function updateRadialBonds() {
      radialBond1.attr("d", function (d) { return findPoints(d, 1); });
      radialBond2.attr("d", function (d) { return findPoints(d, 2); });

      if (keShadingMode) {
        // Update also radial bonds color when keShading is on.
        radialBond1.style("stroke", getBondAtom1Color);
        radialBond2.style("stroke", getBondAtom2Color);
      }
    }

    function updateImageAttachment(){
      var numImages, img_height, img_width, imgHost, imgHostType, imglayer, imgX, imgY, container, i;
      numImages= imageProp.length;
      for(i = 0; i < numImages; i++) {
        if (!imageSizes || !imageSizes[i]) continue;
        imgHost =  modelResults[imageProp[i].imageHostIndex];
        imgHostType =  imageProp[i].imageHostType;
        imgX = model2px(imageProp[i].imageX);
        imgY = model2pxInv(imageProp[i].imageY);
        imglayer = imageProp[i].imageLayer;
        img_width = model2px(imageSizes[i][0]);
        img_height = model2px(imageSizes[i][1]);
        container = imglayer === 1 ? imageContainerTop : imageContainerBelow;
        container.selectAll("image.image_attach"+i)
          .attr("x",  function() { if (imgHostType === "") { return imgX; } else { return model2px(imgHost.x) - img_width / 2; } })
          .attr("y",  function() { if (imgHostType === "") { return imgY; } else { return model2pxInv(imgHost.y) - img_height / 2; } });
      }
    }

    function nodeDragStart(d, i) {
      if (model.is_stopped()) {
        // cache the *original* atom position so we can go back to it if drag is disallowed
        dragOrigin = [d.x, d.y];
      }
      else if ( d.draggable ) {
        model.liveDragStart(i);
      }
    }

    /**
      Given x, y, and a bounding box (object with keys top, left, bottom, and right relative to
      (x, y), returns an (x, y) constrained to keep the bounding box within the molecule container.
    */
    function dragBoundingBox(x, y, bbox) {
      if (bbox.left + x < 0)                x = 0 - bbox.left;
      if (bbox.right + x > modelWidth) x = modelWidth - bbox.right;
      if (bbox.bottom + y < 0)              y = 0 - bbox.bottom;
      if (bbox.top + y > modelHeight)  y = modelHeight - bbox.top;

      return { x: x, y: y };
    }

    function clip(value, min, max) {
      if (value < min) return min;
      if (value > max) return max;
      return value;
    }

    /**
      Given x, y, make sure that x and y are clipped to remain within the model container's
      boundaries
    */
    function dragPoint(x, y) {
      return { x: clip(x, 0, modelWidth), y: clip(y, 0, modelHeight) };
    }

    function nodeDrag(d, i) {
      var dragX = model2px.invert(d3.event.x),
          dragY = model2pxInv.invert(d3.event.y),
          drag;

      if (model.is_stopped()) {
        drag = dragBoundingBox(dragX, dragY, model.getMoleculeBoundingBox(i));
        setAtomPosition(i, drag.x, drag.y, false, true);
        updateDrawablePositions();
      }
      else if ( d.draggable ) {
        drag = dragPoint(dragX, dragY);
        model.liveDrag(drag.x, drag.y);
      }
    }

    function textDrag(d, i) {
      var dragDx = model2px.invert(d3.event.dx),
          dragDy = model2px.invert(d3.event.dy);

      if (!(AUTHORING && model.is_stopped())) {
      // for now we don't have user-draggable textBoxes
        return;
      }
      else {
        d.x = d.x + dragDx;
        d.y = d.y - dragDy;
        updateTextBoxes();
      }
    }

    function nodeDragEnd(d, i) {
      if (model.is_stopped()) {

        if (!setAtomPosition(i, d.x, d.y, true, true)) {
          alert("You can't drop the atom there");     // should be changed to a nice Lab alert box
          setAtomPosition(i, dragOrigin[0], dragOrigin[1], false, true);
        }
        updateDrawablePositions();
      }
      else if (d.draggable) {
        // here we just assume we are removing the one and only spring force.
        // This assumption will have to change if we can have more than one.
        model.liveDragEnd();
      }
    }

    function setupTooTips() {
      if ( moleculeDiv === undefined) {
        moleculeDiv = d3.select("body").append("div")
            .attr("class", "tooltip")
            .style("opacity", 1e-6);
        moleculeDivPre = moleculeDiv.append("pre");
      }
    }

    function setupClock() {
      var clockColor = d3.lab(model.get("backgroundColor"));
      // This ensures that color will be visible on background.
      // Decide between white and black usingL value of background color in LAB space.
      clockColor.l = clockColor.l > 50 ? 0 : 100;
      clockColor.a = clockColor.b = 0;
      // Add model time display.
      mainContainer.selectAll('.modelTimeLabel').remove();
      // Update clock status.
      showClock = model.get("showClock");
      if (showClock) {
        timeLabel = mainContainer.append("text")
          .attr("class", "modelTimeLabel")
          .text(modelTimeLabel())
          // Set text position to (0nm, 0nm) (model domain) and add small, constant offset in px.
          .attr("x", model2px(0) + 3)
          .attr("y", model2pxInv(0) - 3)
          .style("text-anchor", "start")
          .style("fill", clockColor.rgb());
      }
    }

    function setupRendererOptions() {
      imageProp = model.get("images");
      imageMapping = model.get("imageMapping");
      if (model.url) {
        imagePath = labConfig.actualRoot + model.url.slice(0, model.url.lastIndexOf("/") + 1);
      }

      velocityVectorColor = model.get("velocityVectors").color;
      velocityVectorWidth  = model.get("velocityVectors").width;
      velocityVectorLength = model.get("velocityVectors").length;

      forceVectorColor = model.get("forceVectors").color;
      forceVectorWidth  = model.get("forceVectors").width;
      forceVectorLength = model.get("forceVectors").length;

      atomTraceColor = model.get("atomTraceColor");

      createSymbolImages();
      createVectorArrowHeads(velocityVectorColor, VELOCITY_STR);
      createVectorArrowHeads(forceVectorColor, FORCE_STR);

      createAdditionalGradients();

      // Register additional controls, context menus etc.
      // Note that special selector for class is used. Typical class selectors
      // (e.g. '.amino-acid') cause problems when interacting with SVG nodes.
      amniacidContextMenu.register(model, api, '[class~="amino-acid"]');

      // Initialize renderers.
      geneticRenderer = new GeneticRenderer(mainContainer, api, model);
    }

    //
    // *** Main Renderer functions ***
    //

    //
    // MD2D Renderer: init
    //
    // Called when Renderer is created.
    //
    function init() {
      mainContainer        = containers.mainContainer,
      radialBondsContainer = containers.radialBondsContainer,
      VDWLinesContainer    = containers.VDWLinesContainer,
      imageContainerBelow  = containers.imageContainerBelow,
      imageContainerTop    = containers.imageContainerTop,
      textContainerBelow   = containers.textContainerBelow,
      textContainerTop     = containers.textContainerTop,

      modelResults  = model.get_results();
      modelElements = model.get_elements();
      modelWidth    = model.get('width');
      modelHeight   = model.get('height');
      aspectRatio   = modelWidth / modelHeight;

      setupTooTips();
      setupRendererOptions();

      repaint();

      // Subscribe for model events.
      model.addPropertiesListener(["temperatureControl"], drawSymbolImages);

      // Redraw container each time when some visual-related property is changed.
      model.addPropertiesListener([
        "keShading", "chargeShading", "showChargeSymbols", "useThreeLetterCode",
        "showVDWLines", "VDWLinesCutoff",
        "showVelocityVectors", "showForceVectors",
        "showAtomTrace", "atomTraceId", "aminoAcidColorScheme",
        "showClock", "backgroundColor"],
          repaint);

      model.on('addAtom', repaint);
      model.on('removeAtom', repaint);
      model.on('addRadialBond', setupRadialBonds);
      model.on('removeRadialBond', setupRadialBonds);
      model.on('textBoxesChanged', drawTextBoxes);

    }

    //
    // MD2D Renderer: reset
    //
    // Call when model is reset or reloaded.
    //
    function reset(mod, cont, m2px, m2pxInv) {
      model = mod;
      containers = cont;
      model2px = m2px;
      model2pxInv = m2pxInv;
      init();
    }

    //
    // MD2D Renderer: repaint
    //
    // Call when container being rendered into changes size, in that case
    // pass in new D3 scales for model2pcx transformations.
    //
    // Also call when the number of objects changes suc that the conatiner
    // must be setup again.
    //
    function repaint(m2px, m2pxInv) {
      if (arguments.length) {
        model2px = m2px;
        model2pxInv = m2pxInv;
      }
      setupClock();
      setupObstacles();
      setupVdwPairs();
      setupColorsOfParticles();
      setupRadialBonds();
      setupParticles();
      geneticRenderer.setup();
      setupVectors();
      setupAtomTrace();
      drawSymbolImages();
      drawImageAttachment();
      drawTextBoxes();
    }

    //
    // MD2D Renderer: update
    //
    // Call to update visualization when model result state changes.
    // Normally called on every model tick.
    //
    function update() {
      console.time('view update');
      if (obstacles) {
        obstacle.attr("transform", function (d, i) {
          return "translate(" + model2px(obstacles.x[i]) + " " + model2pxInv(obstacles.y[i] + obstacles.height[i]) + ")";
        });
      }

      if (drawVdwLines) {
        updateVdwPairs();
      }
      // When Kinetic Energy Shading is enabled, update style of atoms
      // during each frame.
      if (keShadingMode) {
        setupColorsOfParticles();
      }

      if (radialBondResults) {
        updateRadialBonds();
      }

      // update model time display
      if (showClock) {
        timeLabel.text(modelTimeLabel());
      }

      updateParticles();

      if (drawVelocityVectors) {
        updateVectors(velVector, getVelVectorPath, getVelVectorWidth);
      }
      if (drawForceVectors) {
        updateVectors(forceVector, getForceVectorPath, getForceVectorWidth);
      }
      if (drawAtomTrace) {
        updateAtomTrace();
      }
      if(imageProp && imageProp.length !== 0) {
        updateImageAttachment();
      }
      if (textBoxes && textBoxes.length > 0) {
        updateTextBoxes();
      }
      console.timeEnd('view update');
    }

    //
    // Public API to instantiated Renderer
    //
    api = {
      // Expose private methods.
      update: update,
      repaint: repaint,
      reset: reset,
      model2px: function(val) {
        // Note that we shouldn't just do:
        // api.nm2px = nm2px;
        // as nm2px local variable can be reinitialized
        // many times due container rescaling process.
        return model2px(val);
      },
      model2pxInv: function(val) {
        // See comments for nm2px.
        return model2pxInv(val);
      }
    };

    // Initialization.
    init();

    return api;
  };
});

/*global $ define: false */
// ------------------------------------------------------------
//
//   MD2D View Container
//
// ------------------------------------------------------------
define('md2d/views/view',['require','common/console','common/views/model-view','md2d/views/renderer'],function (require) {
  // Dependencies.
  var console               = require('common/console'),
      ModelView             = require("common/views/model-view"),
      Renderer              = require("md2d/views/renderer");

  return function (e, modelUrl, model) {
    return new ModelView(e, modelUrl, model, Renderer);
  }

});

/*global $, define, model */

define('md2d/views/dna-edit-dialog',[],function () {

  return function DNAEditDialog() {
    var api,
        $dialogDiv,
        $dnaTextInput,
        $errorMsg,
        $submitButton,

        init = function() {
          // Basic dialog elements.
          $dialogDiv = $('<div></div>');
          $dnaTextInput = $('<input type="text" id="dna-sequence-input" size="45"></input>');
          $dnaTextInput.appendTo($dialogDiv);
          $errorMsg = $('<p class="error"></p>');
          $errorMsg.appendTo($dialogDiv);

          // jQuery UI Dialog.
          $dialogDiv.dialog({
            dialogClass: "dna-edit-dialog",
            // Ensure that font is being scaled dynamically.
            appendTo: "#responsive-content",
            title: "DNA Code on Sense Strand",
            autoOpen: false,
            width: "35em",
            buttons: {
              "Apply": function () {
                model.getGeneticProperties().set({
                  DNA: $dnaTextInput.val()
                });
                $(this).dialog("close");
              }
            }
          });

          // Dynamic validation on input.
          $submitButton = $(".dna-edit-dialog button:contains('Apply')");
          $dnaTextInput.on("input", function () {
            var props = {
                  DNA: $dnaTextInput.val()
                },
                status;
            status = model.getGeneticProperties().validate(props);
            if (status.valid === false) {
              $submitButton.button("disable");
              $errorMsg.text(status.errors["DNA"]);
            } else {
              $submitButton.button("enable");
              $errorMsg.text("");
            }
          });
        };

    api = {
      open: function () {
        // Clear previous errors.
        $errorMsg.text("");
        $submitButton.removeAttr("disabled");
        // Set current value of DNA code.
        $dnaTextInput.val(model.getGeneticProperties().get().DNA);
        $dialogDiv.dialog("open");
      }
    };

    init();

    return api;
  };
});

/*global define model */

define('md2d/controllers/scripting-api',['require','md2d/views/dna-edit-dialog'],function (require) {

  var DNAEditDialog = require('md2d/views/dna-edit-dialog');

  /**
    Define the model-specific MD2D scripting API used by 'action' scripts on interactive elements.

    The universal Interactive scripting API is extended with the properties of the
    object below which will be exposed to the interactive's 'action' scripts as if
    they were local vars. All other names (including all globals, but excluding
    Javascript builtins) will be unavailable in the script context; and scripts
    are run in strict mode so they don't accidentally expose or read globals.

    @param: api
  */

  return function MD2DScriptingAPI (api) {

    var dnaEditDialog = new DNAEditDialog();

    return {
      /* Returns number of atoms in the system. */
      getNumberOfAtoms: function getNumberOfAtoms() {
        return model.get_num_atoms();
      },

      /* Returns number of obstacles in the system. */
      getNumberOfObstacles: function getNumberOfObstacles() {
        return model.getNumberOfObstacles();
      },

      /* Returns number of elements in the system. */
      getNumberOfElements: function getNumberOfElements() {
        return model.getNumberOfElements();
      },

      /* Returns number of radial bonds in the system. */
      getNumberOfRadialBonds: function getNumberOfRadialBonds() {
        return model.getNumberOfRadialBonds();
      },

      /* Returns number of angular bonds in the system. */
      getNumberOfAngularBonds: function getNumberOfAngularBonds() {
        return model.getNumberOfAngularBonds();
      },

      addAtom: function addAtom(props, options) {
        if (options && options.supressRepaint) {
          // Translate supressRepaint option to
          // option understable by modeler.
          // supresRepaint is a conveniance option for
          // Scripting API users.
          options.supressEvent = true;
        }
        return model.addAtom(props, options);
      },

      /*
        Removes atom 'i'.
      */
      removeAtom: function removeAtom(i, options) {
        if (options && options.supressRepaint) {
          // Translate supressRepaint option to
          // option understable by modeler.
          // supresRepaint is a conveniance option for
          // Scripting API users.
          options.supressEvent = true;
          delete options.supressRepaint;
        }
        try {
          model.removeAtom(i, options);
        } catch (e) {
          if (!options || !options.silent)
            throw e;
        }
      },

      /*
        Removes radial bond 'i'.
      */
      removeRadialBond: function removeRadialBond(i, options) {
        try {
          model.removeRadialBond(i);
        } catch (e) {
          if (!options || !options.silent)
            throw e;
        }

        api.repaint();
      },

      /*
        Removes angular bond 'i'.
      */
      removeAngularBond: function removeAngularBond(i, options) {
        try {
          model.removeAngularBond(i);
        } catch (e) {
          if (!options || !options.silent)
            throw e;
        }

        api.repaint();
      },

      addRandomAtom: function addRandomAtom() {
        return model.addRandomAtom.apply(model, arguments);
      },

      adjustTemperature: function adjustTemperature(fraction) {
        model.set({targetTemperature: fraction * model.get('temperature')});
      },

      limitHighTemperature: function limitHighTemperature(t) {
        if (model.get('targetTemperature') > t) model.set({targetTemperature: t});
      },

      /** returns a list of integers corresponding to atoms in the system */
      randomAtoms: function randomAtoms(n) {
        var numAtoms = model.get_num_atoms();

        if (n === null) n = 1 + api.randomInteger(numAtoms-1);

        if (!api.isInteger(n)) throw new Error("randomAtoms: number of atoms requested, " + n + ", is not an integer.");
        if (n < 0) throw new Error("randomAtoms: number of atoms requested, " + n + ", was less be greater than zero.");

        if (n > numAtoms) n = numAtoms;
        return api.choose(n, numAtoms);
      },

      /**
        Accepts atom indices as arguments, or an array containing atom indices.
        Unmarks all atoms, then marks the requested atom indices.
        Repaints the screen to make the marks visible.
      */
      markAtoms: function markAtoms() {
        var i,
            len;

        if (arguments.length === 0) return;

        // allow passing an array instead of a list of atom indices
        if (api.isArray(arguments[0])) {
          return markAtoms.apply(null, arguments[0]);
        }

        api.unmarkAllAtoms();

        // mark the requested atoms
        for (i = 0, len = arguments.length; i < len; i++) {
          model.setAtomProperties(arguments[i], {marked: 1});
        }
        api.repaint();
      },

      unmarkAllAtoms: function unmarkAllAtoms() {
        for (var i = 0, len = model.get_num_atoms(); i < len; i++) {
          model.setAtomProperties(i, {marked: 0});
        }
        api.repaint();
      },

      traceAtom: function traceAtom(i) {
        if (i === null) return;

        model.set({atomTraceId: i});
        model.set({showAtomTrace: true});
      },

      untraceAtom: function untraceAtom() {
        model.set({showAtomTrace: false});
      },

      /**
        Sets individual atom properties using human-readable hash.
        e.g. setAtomProperties(5, {x: 1, y: 0.5, charge: 1})
      */
      setAtomProperties: function setAtomProperties(i, props, checkLocation, moveMolecule, options) {
        model.setAtomProperties(i, props, checkLocation, moveMolecule);
        if (!(options && options.supressRepaint)) {
          api.repaint();
        }
      },

      /**
        Returns atom properties as a human-readable hash.
        e.g. getAtomProperties(5) --> {x: 1, y: 0.5, charge: 1, ... }
      */
      getAtomProperties: function getAtomProperties(i) {
        return model.getAtomProperties(i);
      },

      setElementProperties: function setElementProperties(i, props) {
        model.setElementProperties(i, props);
        api.repaint();
      },

      /**
        Sets custom pairwise LJ properties (epsilon or sigma), which will
        be used instead of the mean values of appropriate element properties.
        i, j - IDs of the elements which should have custom pairwise LJ properties.
        props - object containing sigma, epsilon or both.
        e.g. setPairwiseLJProperties(0, 1, {epsilon: -0.2})
      */
      setPairwiseLJProperties: function setPairwiseLJProperties(i, j, props) {
        model.getPairwiseLJProperties().set(i, j, props);
      },

      getElementProperties: function getElementProperties(i) {
        return model.getElementProperties(i);
      },

      /**
        Adds an obstacle using human-readable hash of properties.
        e.g. addObstacle({x: 1, y: 0.5, width: 1, height: 1})
      */
      addObstacle: function addObstacle(props, options) {
        try {
          model.addObstacle(props);
        } catch (e) {
          if (!options || !options.silent)
            throw e;
        }
        api.repaint();
      },

      /**
        Sets individual obstacle properties using human-readable hash.
        e.g. setObstacleProperties(0, {x: 1, y: 0.5, externalFx: 0.00001})
      */
      setObstacleProperties: function setObstacleProperties(i, props) {
        model.setObstacleProperties(i, props);
        api.repaint();
      },

      /**
        Returns obstacle properties as a human-readable hash.
        e.g. getObstacleProperties(0) --> {x: 1, y: 0.5, externalFx: 0.00001, ... }
      */
      getObstacleProperties: function getObstacleProperties(i) {
        return model.getObstacleProperties(i);
      },

      /**
        Removes obstacle 'i'.
      */
      removeObstacle: function removeObstacle(i, options) {
        try {
          model.removeObstacle(i);
        } catch (e) {
          if (!options || !options.silent)
            throw e;
        }

        api.repaint();
      },

      setRadialBondProperties: function setRadialBondProperties(i, props) {
        model.setRadialBondProperties(i, props);
        api.repaint();
      },

      getRadialBondProperties: function getRadialBondProperties(i) {
        return model.getRadialBondProperties(i);
      },

      setAngularBondProperties: function setAngularBondProperties(i, props) {
        model.setAngularBondProperties(i, props);
        api.repaint();
      },

      getAngularBondProperties: function getAngularBondProperties(i) {
        return model.getAngularBondProperties(i);
      },

      /**
        Sets genetic properties using human-readable hash.
        e.g. setGeneticProperties({ DNA: "ATCG" })
      */
      setGeneticProperties: function setGeneticProperties(props) {
        model.getGeneticProperties().set(props);
      },

      /**
        Returns genetic properties as a human-readable hash.
        e.g. getGeneticProperties() --> {DNA: "ATCG", DNAComplement: "TAGC", x: 0.01, y: 0.01, height: 0.12}
      */
      getGeneticProperties: function getGeneticProperties() {
        return model.getGeneticProperties().get();
      },

      /**
        Opens DNA properties dialog, which allows to set DNA code.
      */
      openDNADialog: function showDNADialog() {
        dnaEditDialog.open();
      },

      /**
        Triggers transcription of mRNA from DNA.
        Result should be rendered. It is also stored in genetic properties.

        e.g. getGeneticProperties() --> {DNA: "ATCG", DNAComplement: "TAGC", mRNA: "AUCG", ...}
      */
      transcribe: function transcribeDNA() {
        model.getGeneticProperties().transcribeDNA();
      },

      /**
        Triggers translation of mRNA to protein.
      */
      translate: function translate() {
        var aaSequence = model.getGeneticProperties().translate();
        model.generateProtein(aaSequence);
      },

      translateStepByStep: function translateStepByStep() {
        model.translateStepByStep();
      },

      animateTranslation: function animateTranslation() {
        model.animateTranslation();
      },

      /**
        Generates a random protein.

        'expectedLength' parameter controls the maximum (and expected) number of amino
        acids of the resulting protein. When expected length is too big (due to limited
        area of the model), protein will be truncated and warning shown.
      */
      generateRandomProtein: function (expectedLength) {
        var realLength = model.generateProtein(undefined, expectedLength);

        if (realLength !== expectedLength) {
          throw new Error("Generated protein was truncated due to limited area of the model. Only" +
            realLength + " amino acids were generated.");
        }
      },

      /**
        Sets solvent. You can use three predefined solvents: "water", "oil" or "vacuum".
        This is only a convenience method. The same effect can be achieved by manual setting
        of 'solventForceFactor', 'dielectricConstant' and 'backgroundColor' properties.
      */
      setSolvent: function setSolvent(type) {
        model.setSolvent(type);
      },

      pe: function pe() {
        return model.get('potentialEnergy');
      },

      ke: function ke() {
        return model.get('kineticEnergy');
      },

      atomsKe: function atomsKe(atomsList) {
        var sum = 0, i;
        for (i = 0; i < atomsList.length; i++) {
          sum += model.getAtomKineticEnergy(atomsList[i]);
        }
        return sum;
      },

      minimizeEnergy: function minimizeEnergy() {
        model.minimizeEnergy();
        api.repaint();
      },

      addTextBox: function(props) {
        model.addTextBox(props);
      },

      removeTextBox: function(i) {
        model.removeTextBox(i);
      },

      setTextBoxProperties: function(i, props) {
        model.setTextBoxProperties(i, props);
      }

    };

  };
});

/*global define model */

define('md2d/benchmarks/benchmarks',['require'],function (require) {

  return function Benchmarks(controller) {

    var benchmarks = [
      {
        name: "commit",
        numeric: false,
        run: function(done) {
          var link = "<a href='"+Lab.version.repo.commit.url+"' class='opens-in-new-window' target='_blank'>"+Lab.version.repo.commit.short_sha+"</a>";
          if (Lab.version.repo.dirty) {
            link += " <i>dirty</i>";
          }
          done(link);
        }
      },
      {
        name: "atoms",
        numeric: true,
        run: function(done) {
          done(model.get_num_atoms());
        }
      },
      {
        name: "temperature",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          done(model.get("temperature"));
        }
      },
      {
        name: "just graphics (steps/s)",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          var elapsed, start, i;

          model.stop();
          start = +Date.now();
          i = -1;
          while (i++ < 100) {
            controller.modelContainer.update();
          }
          elapsed = Date.now() - start;
          done(100/elapsed*1000);
        }
      },
      {
        name: "model (steps/s)",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          var elapsed, start, i;

          model.stop();
          start = +Date.now();
          i = -1;
          while (i++ < 100) {
            // advance model 1 tick, but don't paint the display
            model.tick(1, { dontDispatchTickEvent: true });
          }
          elapsed = Date.now() - start;
          done(100/elapsed*1000);
        }
      },
      {
        name: "model+graphics (steps/s)",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          var start, elapsed, i;

          model.stop();
          start = +Date.now();
          i = -1;
          while (i++ < 100) {
            model.tick();
          }
          elapsed = Date.now() - start;
          done(100/elapsed*1000);
        }
      },
      {
        name: "fps",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          // warmup
          model.start();
          setTimeout(function() {
            model.stop();
            var start = model.get('time');
            setTimeout(function() {
              // actual fps calculation
              model.start();
              setTimeout(function() {
                model.stop();
                var elapsedModelTime = model.get('time') - start;
                done( elapsedModelTime / (model.get('viewRefreshInterval') * model.get('timeStep')) / 2 );
              }, 2000);
            }, 100);
          }, 1000);
        }
      },
      {
        name: "interactive",
        numeric: false,
        run: function(done) {
          done(window.location.pathname + window.location.hash);
        }
      }
    ];

    return benchmarks;

  }

});

/*global
  define
*/
/*jslint onevar: true*/
define('md2d/controllers/controller',['require','common/controllers/model-controller','md2d/models/modeler','md2d/views/view','md2d/controllers/scripting-api','md2d/benchmarks/benchmarks'],function (require) {
  // Dependencies.
  var ModelController   = require("common/controllers/model-controller"),
      Model             = require('md2d/models/modeler'),
      ModelContainer    = require('md2d/views/view'),
      ScriptingAPI      = require('md2d/controllers/scripting-api'),
      Benchmarks        = require('md2d/benchmarks/benchmarks');

  return function (modelViewId, modelUrl, modelConfig, interactiveViewConfig, interactiveModelConfig) {
    return new ModelController(modelViewId, modelUrl, modelConfig, interactiveViewConfig, interactiveModelConfig,
                                     Model, ModelContainer, ScriptingAPI, Benchmarks);
  }
});

/*global define: true */
/*jslint eqnull: true, boss: true, loopfunc: true*/

define('pta/models/engine/pta',['require','exports','module','arrays','common/array-types','common/console','common/models/engines/clone-restore-wrapper'],function (require, exports, module) {

  var arrays               = require('arrays'),
      arrayTypes           = require('common/array-types'),
      console              = require('common/console'),
      CloneRestoreWrapper  = require('common/models/engines/clone-restore-wrapper');

  exports.createEngine = function() {

    var // the object to be returned
        engine,

        // Whether system dimensions have been set. This is only allowed to happen once.
        sizeHasBeenInitialized = false,

        // System dimensions as [x, y]. Default value can be changed until turles are created.
        size = [50, 50],

        // The current model time in ticks.
        time = 0,

        // The current integration time step
        dt,

        // Square of integration time step.
        dt_sq,

        // ####################################################################
        //                      Turtle Properties

        // Individual property arrays for the turtles, indexed by turtle number
        radius, x, y, vx, vy, px, py, ax, ay, speed, shape,

        // An object that contains references to the above turtle-property arrays
        turtles,

        // The number of turtles in the system.
        N = 0,

        // booleans indicating whether the turtle world wraps
        horizontalWrapping,
        verticalWrapping,

        // Initializes basic data structures.
        initialize = function () {
          createTurtlesArray(0);
        },

        /**
          Extend all arrays in arrayContainer to `newLength`. Here, arrayContainer is expected to be `turtles`
          `elements`, `radialBonds`, etc. arrayContainer might be an array or an object.
          TODO: this is just interim solution, in the future only objects will be expected.
        */
        extendArrays = function(arrayContainer, newLength) {
          var i, len;
          if (Array.isArray(arrayContainer)) {
            // Array of arrays.
            for (i = 0, len = arrayContainer.length; i < len; i++) {
              if (arrays.isArray(arrayContainer[i]))
                arrayContainer[i] = arrays.extend(arrayContainer[i], newLength);
            }
          } else {
            // Object with arrays defined as properties.
            for (i in arrayContainer) {
              if(arrayContainer.hasOwnProperty(i)) {
                if (arrays.isArray(arrayContainer[i]))
                  arrayContainer[i] = arrays.extend(arrayContainer[i], newLength);
              }
            }
          }
        },

        /**
          Set up "shortcut" references, e.g., x = turtles.x
        */
        assignShortcutReferences = {

          turtles: function() {
            radius         = turtles.radius;
            x              = turtles.x;
            y              = turtles.y;
            vx             = turtles.vx;
            vy             = turtles.vy;
            px             = turtles.px;
            py             = turtles.py;
            ax             = turtles.ax;
            ay             = turtles.ay;
            speed          = turtles.speed;
            shape          = turtles.shape;
          }

        },


        createTurtlesArray = function(num) {
          turtles  = engine.turtles  = {};

          // TODO. DRY this up by letting the property list say what type each array is
          turtles.radius         = arrays.create(num, 0, arrayTypes.float);
          turtles.x              = arrays.create(num, 0, arrayTypes.float);
          turtles.y              = arrays.create(num, 0, arrayTypes.float);
          turtles.vx             = arrays.create(num, 0, arrayTypes.float);
          turtles.vy             = arrays.create(num, 0, arrayTypes.float);
          turtles.px             = arrays.create(num, 0, arrayTypes.float);
          turtles.py             = arrays.create(num, 0, arrayTypes.float);
          turtles.ax             = arrays.create(num, 0, arrayTypes.float);
          turtles.ay             = arrays.create(num, 0, arrayTypes.float);
          turtles.speed          = arrays.create(num, 0, arrayTypes.float);

          // For the sake of clarity, manage all turtles properties in one
          // place (engine).
          turtles.shape          = arrays.create(num, 0, arrayTypes.uint8);
          turtles.marked         = arrays.create(num, 0, arrayTypes.uint8);
          turtles.visible        = arrays.create(num, 0, arrayTypes.uint8);

          assignShortcutReferences.turtles();
        },

        // Constrain Turtle i to the area between the walls by simulating perfectly elastic collisions with the walls.
        // Note this may change the linear and angular momentum.
        bounceTurtleOffWalls = function(i) {
          var r = radius[i],
              leftwall = r,
              bottomwall = r,
              width = size[0],
              height = size[1],
              rightwall = width - r,
              topwall = height - r;

          if (horizontalWrapping) {
            // wrap around vertical walls
            if (x[i] + radius[i] < leftwall) {
              x[i] += width;
            } else if (x[i] - radius[i] > rightwall) {
              x[i] -= width;
            }
          } else {
            // Bounce off vertical walls.
            if (x[i] < leftwall) {
              while (x[i] < leftwall - width) {
                x[i] += width;
              }
              x[i]  = leftwall + (leftwall - x[i]);
              vx[i] *= -1;
              px[i] *= -1;
            } else if (x[i] > rightwall) {
              while (x[i] > rightwall + width) {
                x[i] -= width;
              }
              x[i]  = rightwall - (x[i] - rightwall);
              vx[i] *= -1;
              px[i] *= -1;
            }
          }

          if (verticalWrapping) {
            // wrap around horizontal walls
            if (y[i] + radius[i] < bottomwall) {
              y[i] += height;
            } else if (y[i] - radius[i] > topwall) {
              y[i] -= height;
            }
          } else {
            // Bounce off horizontal walls
            if (y[i] < bottomwall) {
              while (y[i] < bottomwall - height) {
                y[i] += height;
              }
              y[i]  = bottomwall + (bottomwall - y[i]);
              vy[i] *= -1;
              py[i] *= -1;
            } else if (y[i] > topwall) {
              while (y[i] > topwall + height) {
                y[i] -= height;
              }
              y[i]  = topwall - (y[i] - topwall);
              vy[i] *= -1;
              py[i] *= -1;
            }
          }
        },

        // Accumulate acceleration into a(t + dt) from all possible interactions, fields
        // and forces connected with turtles.
        updateTurtlesAccelerations = function () {
          var i, inverseMass;

          if (N === 0) return;

          // Zero out a(t) for accumulation of forces into a(t + dt).
          for (i = 0; i < N; i++) {
            ax[i] = ay[i] = 0;
          }
        },

        // Half of the update of v(t + dt) and p(t + dt) using a. During a single integration loop,
        // call once when a = a(t) and once when a = a(t+dt).
        halfUpdateVelocity = function() {
          var i;
          for (i = 0; i < N; i++) {
            vx[i] += 0.5 * ax[i] * dt;
            px[i] = vx[i];
            vy[i] += 0.5 * ay[i] * dt;
            py[i] = vy[i];
          }
        },

        // Calculate r(t + dt, i) from v(t + 0.5 * dt).
        updateTurtlesPosition = function() {
          var width100  = size[0] * 100,
              height100 = size[1] * 100,
              xPrev, yPrev, i;

          for (i = 0; i < N; i++) {
            xPrev = x[i];
            yPrev = y[i];

            x[i] += vx[i] * dt;
            y[i] += vy[i] * dt;

            // Bounce off walls.
            bounceTurtleOffWalls(i);
          }
        },

        // Update speed using velocities.
        updateTurtlesSpeed = function() {
          var i;

          for (i = 0; i < N; i++) {
            speed[i] = Math.sqrt(vx[i] * vx[i] + vy[i] * vy[i]);
          }
        };

        // ####################################################################
        // ####################################################################

    engine = {

      // Our timekeeping is really a convenience for users of this lib, so let them reset time at will
      setTime: function(t) {
        time = t;
      },

      setSize: function(v) {
        if (sizeHasBeenInitialized) {
          throw new Error("The PTA model's size has already been set, and cannot be reset.");
        }
        var width  = (v[0] && v[0] > 0) ? v[0] : 10,
            height = (v[1] && v[1] > 0) ? v[1] : 10;
        size = [width, height];
        sizeHasBeenInitialized = true;
      },

      getSize: function() {
        return [size[0], size[1]];
      },

      setHorizontalWrapping: function(v) {
        horizontalWrapping = !!v;
      },

      setVerticalWrapping: function(v) {
        verticalWrapping = !!v;
      },

      setTurtleProperties: function (i, props) {
        var key, idx, rest, j;

        props.radius = 1;

        // Set all properties from props hash.
        for (key in props) {
          if (props.hasOwnProperty(key)) {
            turtles[key][i] = props[key];
          }
        }

        // Update properties which depend on other properties.
        speed[i] = Math.sqrt(vx[i] * vx[i] + vy[i] * vy[i]);
      },

      /**
        The canonical method for adding an turtle to the collections of turtles.

        If there isn't enough room in the 'turtles' array, it (somewhat inefficiently)
        extends the length of the typed arrays by ten to have room for more turtles.

        @returns the index of the new turtle
      */
      addTurtle: function(props) {
        if (N + 1 > turtles.x.length) {
          extendArrays(turtles, N + 10);
          assignShortcutReferences.turtles();
        }

        // Set acceleration of new turtle to zero.
        props.ax = props.ay = 0;

        // Increase number of turtles.
        N++;

        // Set provided properties of new turtle.
        engine.setTurtleProperties(N - 1, props);

      },

      removeTurtle: function(idx) {
        var i, len, prop,
            l, list, lists;

        if (idx >= N) {
          throw new Error("Turtle " + idx + " doesn't exist, so it can't be removed.");
        }

        // Shift turtles properties and zero last element.
        // It can be optimized by just replacing the last
        // turtle with turtle 'i', however this approach
        // preserves more expectable turtles indexing.
        for (i = idx; i < N; i++) {
          for (prop in turtles) {
            if (turtles.hasOwnProperty(prop)) {
              if (i === N - 1)
                turtles[prop][i] = 0;
              else
                turtles[prop][i] = turtles[prop][i + 1];
            }
          }
        }

        // Update number of turtles!
        N--;

        // Update accelerations of turtles.
        updateParticlesAccelerations();
      },

      setupTurtlesRandomly: function(options) {

        var // if a temperature is not explicitly requested, we just need any nonzero number

            nrows = Math.floor(Math.sqrt(N)),
            ncols = Math.ceil(N/nrows),

            i, r, c, rowSpacing, colSpacing,
            vMagnitude, vDirection, props;

        colSpacing = size[0] / (1 + ncols);
        rowSpacing = size[1] / (1 + nrows);

        // Arrange turtles in a lattice.
        i = -1;

        for (r = 1; r <= nrows; r++) {
          for (c = 1; c <= ncols; c++) {
            i++;
            if (i === N) break;
            vMagnitude = math.normal(1, 1/4);
            vDirection = 2 * Math.random() * Math.PI;

            props = {
              x:       c * colSpacing,
              y:       r * rowSpacing,
              vx:      vMagnitude * Math.cos(vDirection),
              vy:      vMagnitude * Math.sin(vDirection)
            };
            engine.setTurtleProperties(i, props);
          }
        }
      },

      // Velocity Verlet integration scheme.
      // See: http://en.wikipedia.org/wiki/Verlet_integration#Velocity_Verlet
      // The current implementation is:
      // 1. Calculate: v(t + 0.5 * dt) = v(t) + 0.5 * a(t) * dt
      // 2. Calculate: r(t + dt) = r(t) + v(t + 0.5 * dt) * dt
      // 3. Derive a(t + dt) from the interaction potential using r(t + dt)
      // 4. Calculate: v(t + dt) = v(t + 0.5 * dt) + 0.5 * a(t + dt) * dt
      integrate: function(duration, _dt) {
        var steps, iloop, tStart = time;

        // How much time to integrate over, in fs.
        if (duration === undefined)  duration = 100;

        // The length of an integration timestep, in fs.
        if (_dt === undefined) _dt = 1;

        dt = _dt;        // dt is a closure variable that helpers need access to
        dt_sq = dt * dt; // the squared time step is also needed by some helpers.

        // Calculate accelerations a(t), where t = 0.
        // Later this is not necessary, as a(t + dt) from
        // previous step is used as a(t) in the current step.
        if (time === 0) {
          updateTurtlesAccelerations();
        }

        // Number of steps.
        steps = Math.floor(duration / dt);

        for (iloop = 1; iloop <= steps; iloop++) {
          time = tStart + iloop * dt;

          // Calculate v(t + 0.5 * dt) using v(t) and a(t).
          halfUpdateVelocity();

          // Update r(t + dt) using v(t + 0.5 * dt).
          updateTurtlesPosition();

          // Accumulate accelerations into a(t + dt) from all possible interactions, fields
          // and forces connected with atoms.
          updateTurtlesAccelerations();

          // Calculate v(t + dt) using v(t + 0.5 * dt) and a(t + dt).
          halfUpdateVelocity();

          // Now that we have velocity v(t + dt), update speed.
          updateTurtlesSpeed();

        } // end of integration loop

      },


      getNumberOfTurtles: function() {
        return N;
      },

      /**
        Compute the model state and store into the passed-in 'state' object.
        (Avoids GC hit of throwaway object creation.)
      */
      // TODO: [refactoring] divide this function into smaller chunks?
      computeOutputState: function(state) {
        var i, j,
            i1, i2, i3,
            el1, el2,
            dx, dy,
            dxij, dyij, dxkj, dykj,
            cosTheta, theta,
            r_sq, rij, rkj,
            k, dr, angleDiff,
            gravPEInMWUnits,
            // Total kinetic energy, in MW units.
            KEinMWUnits,
            // Potential energy, in eV.
            PE;

        // State to be read by the rest of the system:
        state.time           = time;
      },

      // ######################################################################
      //                State definition of the engine

      // Return array of objects defining state of the engine.
      // Each object in this list should implement following interface:
      // * .clone()        - returning complete state of that object.
      // * .restore(state) - restoring state of the object, using 'state'
      //                     as input (returned by clone()).
      getState: function() {
        return [
          // Use wrapper providing clone-restore interface to save the hashes-of-arrays
          // that represent model state.
          new CloneRestoreWrapper(turtles),

          // Save time value.
          // Create one-line wrapper to provide required interface.
          {
            clone: function () {
              return time;
            },
            restore: function(state) {
              engine.setTime(state);
            }
          }
        ];
      }
    };

    // Initialization
    initialize();

    // Finally, return Public API.
    return engine;
  };
});

/*global define: false */

define('pta/models/metadata',[],function() {

  return {
    mainProperties: {
      type: {
        defaultValue: "pta",
        immutable: true
      },
      width: {
        defaultValue: 50
      },
      height: {
        defaultValue: 50
      },
      modelSampleRate: {
        defaultValue: "default"
      },
      timeStep: {
        defaultValue: 1
      },
      viewRefreshInterval: {
        defaultValue: 50
      },
      horizontalWrapping: {
        defaultValue: false
      },
      verticalWrapping: {
        defaultValue: false
      },
    },

    viewOptions: {
      backgroundColor: {
        defaultValue: "#eeeeee"
      },
      showClock: {
        defaultValue: true
      },
      showTurtleTrace: {
        defaultValue: false
      },
      turtleTraceId: {
        defaultValue: 0
      },
      images: {
        defaultValue: []
      },
      imageMapping: {
        defaultValue: {}
      },
      textBoxes: {
        defaultValue: []
      },
      fitToParent: {
        defaultValue: false
      },
      xunits: {
        defaultValue: false
      },
      yunits: {
        defaultValue: false
      },
      controlButtons: {
        defaultValue: "play"
      },
      gridLines: {
        defaultValue: false
      },
      turtleNumbers: {
        defaultValue: false
      },
      enableTurtleTooltips: {
        defaultValue: false
      },
      enableKeyboardHandlers: {
        defaultValue: true
      },
      turtleTraceColor: {
        defaultValue: "#6913c5"
      }
    },

    turtle: {
      // Required properties:
      x: {
        required: true
      },
      y: {
        required: true
      },
      vx: {
        defaultValue: 0
      },
      vy: {
        defaultValue: 0
      },
      ax: {
        defaultValue: 0,
        serialize: false
      },
      ay: {
        defaultValue: 0,
        serialize: false
      },
      visible: {
        defaultValue: 1
      },
      marked: {
        defaultValue: 0
      },
      // Read-only values, can be set only by engine:
      radius: {
        readOnly: true,
        serialize: false
      },
      px: {
        readOnly: true,
        serialize: false
      },
      py: {
        readOnly: true,
        serialize: false
      },
      speed: {
        readOnly: true,
        serialize: false
      },
      shape: {
        defaultValue: 0
      }
    },

    textBox: {
      text: {
        defaultValue: ""
      },
      x: {
        defaultValue: 0
      },
      y: {
        defaultValue: 0
      },
      layer: {
        defaultValue: 1
      },
      width: {},
      frame: {},
      color: {},
      backgroundColor: {},
      hostType: {},
      hostIndex: {},
      textAlign: {}
    }
  };
});

/*global define: false, d3: false, $: false */
/*jslint onevar: true devel:true eqnull: true boss: true */

define('pta/models/modeler',['require','arrays','common/console','pta/models/engine/pta','pta/models/metadata','common/models/tick-history','common/serialize','common/validator','underscore'],function(require) {
  // Dependencies.
  var arrays               = require('arrays'),
      console              = require('common/console'),
      pta                  = require('pta/models/engine/pta'),
      metadata             = require('pta/models/metadata'),
      TickHistory          = require('common/models/tick-history'),
      serialize            = require('common/serialize'),
      validator            = require('common/validator'),
      _ = require('underscore');

  return function Model(initialProperties) {

    // all models created with this constructor will be of type: "md2d"
    this.constructor.type = "pta";

    var model = {},
        dispatch = d3.dispatch("tick", "play", "stop", "reset", "stepForward", "stepBack",
            "seek", "addTurtle", "removeTurtle", "invalidation", "textBoxesChanged"),
        defaultMaxTickHistory = 1000,
        stopped = true,
        restart = false,
        newStep = false,

        lastSampleTime,
        sampleTimes = [],

        modelOutputState,
        tickHistory,

        // PTA engine.
        engine,

        // ######################### Main Data Structures #####################
        // They are initialized at the end of this function. These data strucutres
        // are mainly managed by the engine.

        // A hash of arrays consisting of arrays of turtle property values
        turtles,

        // A hash of arrays consisting of arrays of patches property values
        patches,

        // ####################################################################

        // A two dimensional array consisting of turtle index numbers and turtle
        // property values - in effect transposed from the turtle property arrays.
        results,

        listeners = {},

        properties = {
          /**
            These functions are optional setters that will be called *instead* of simply setting
            a value when 'model.set({property: value})' is called, and are currently needed if you
            want to pass a value through to the engine.  The function names are automatically
            determined from the property name. If you define one of these custom functions, you
            must remember to also set the property explicitly (if appropriate) as this won't be
            done automatically
          */

          set_timeStep: function(ts) {
            this.timeStep = ts;
          },

          set_horizontalWrapping: function(hw) {
            this.horizontalWrapping = hw;
            if (engine) {
              engine.setHorizontalWrapping(hw);
            }
          },

          set_verticalWrapping: function(vw) {
            this.verticalWrapping = vw;
            if (engine) {
              engine.setVerticalWrapping(vw);
            }
          }

        },

        // The list of all 'output' properties (which change once per tick).
        outputNames = [],

        // Information about the description and calculating function for 'output' properties.
        outputsByName = {},

        // The subset of outputName list, containing list of outputs which are filtered
        // by one of the built-in filters (like running average filter).
        filteredOutputNames = [],

        // Function adding new sample for filtered outputs. Other properties of filtered output
        // are stored in outputsByName object, as filtered output is just extension of normal output.
        filteredOutputsByName = {},

        // The currently-defined parameters.
        parametersByName = {};

    function notifyPropertyListeners(listeners) {
      listeners = _.uniq(listeners);
      for (var i=0, ii=listeners.length; i<ii; i++){
        listeners[i]();
      }
    }

    function notifyPropertyListenersOfEvents(events) {
      var evt,
          evts,
          waitingToBeNotified = [],
          i, ii;

      if (typeof events === "string") {
        evts = [events];
      } else {
        evts = events;
      }
      for (i=0, ii=evts.length; i<ii; i++){
        evt = evts[i];
        if (listeners[evt]) {
          waitingToBeNotified = waitingToBeNotified.concat(listeners[evt]);
        }
      }
      if (listeners["all"]){      // listeners that want to be notified on any change
        waitingToBeNotified = waitingToBeNotified.concat(listeners["all"]);
      }
      notifyPropertyListeners(waitingToBeNotified);
    }

    /**
      Restores a set of "input" properties, notifying their listeners of only those properties which
      changed, and only after the whole set of properties has been updated.
    */
    function restoreProperties(savedProperties) {
      var property,
          changedProperties = [],
          savedValue;

      for (property in savedProperties) {
        if (savedProperties.hasOwnProperty(property)) {
          // skip read-only properties
          if (outputsByName[property]) {
            throw new Error("Attempt to restore output property \"" + property + "\".");
          }
          savedValue = savedProperties[property];
          if (properties[property] !== savedValue) {
            if (properties["set_"+property]) {
              properties["set_"+property](savedValue);
            } else {
              properties[property] = savedValue;
            }
            changedProperties.push(property);
          }
        }
      }
      notifyPropertyListenersOfEvents(changedProperties);
    }

    /**
      Restores a list of parameter values, notifying their listeners after the whole list is
      updated, and without triggering setters. Sets parameters not in the passed-in list to
      undefined.
    */
    function restoreParameters(savedParameters) {
      var parameterName,
          observersToNotify = [];

      for (parameterName in savedParameters) {
        if (savedParameters.hasOwnProperty(parameterName)) {
          // restore the property value if it was different or not defined in the current time step
          if (properties[parameterName] !== savedParameters[parameterName] || !parametersByName[parameterName].isDefined) {
            properties[parameterName] = savedParameters[parameterName];
            parametersByName[parameterName].isDefined = true;
            observersToNotify.push(parameterName);
          }
        }
      }

      // remove parameter values that aren't defined at this point in history
      for (parameterName in parametersByName) {
        if (parametersByName.hasOwnProperty(parameterName) && !savedParameters.hasOwnProperty(parameterName)) {
          parametersByName[parameterName].isDefined = false;
          properties[parameterName] = undefined;
        }
      }

      notifyPropertyListenersOfEvents(observersToNotify);
    }

    function tick(elapsedTime, dontDispatchTickEvent) {
      var timeStep = model.get('timeStep'),
          t, sampleTime;

      // viewRefreshInterval is defined as the model integration time period
      console.time('integration');
      engine.integrate(model.get('viewRefreshInterval') * timeStep, timeStep);
      console.timeEnd('integration');
      console.time('reading model state');
      updateAllOutputProperties();
      console.timeEnd('reading model state');

      console.time('tick history push');
      tickHistory.push();
      console.timeEnd('tick history push');

      newStep = true;

      if (!dontDispatchTickEvent) {
        dispatch.tick();
      }

      return stopped;
    }

    function set_properties(hash) {
      var property, propsChanged = [];
      for (property in hash) {
        if (hash.hasOwnProperty(property) && hash[property] !== undefined && hash[property] !== null) {
          // skip read-only properties
          if (outputsByName[property]) {
            throw new Error("Attempt to set read-only output property \"" + property + "\".");
          }
          // look for set method first, otherwise just set the property
          if (properties["set_"+property]) {
            properties["set_"+property](hash[property]);
          // why was the property not set if the default value property is false ??
          // } else if (properties[property]) {
          } else {
            properties[property] = hash[property];
          }
          propsChanged.push(property);
        }
      }
      notifyPropertyListenersOfEvents(propsChanged);
    }

    /**
      Call this method after moving to a different model time (e.g., after stepping the model
      forward or back, seeking to a different time, or on model initialization) to update all output
      properties and notify their listeners. This method is more efficient for that case than
      updateOutputPropertiesAfterChange because it can assume that all output properties are
      invalidated by the model step. It therefore does not need to calculate any output property
      values; it allows them to be evaluated lazily instead. Property values are calculated when and
      if listeners request them. This method also guarantees that all properties have their updated
      value when they are requested by any listener.

      Technically, this method first updates the 'results' array and macrostate variables, then
      invalidates any  cached output-property values, and finally notifies all output-property
      listeners.

      Note that this method and updateOutputPropertiesAfterChange are the only methods which can
      flush the cached value of an output property. Therefore, be sure to not to make changes
      which would invalidate a cached value without also calling one of these two methods.
    */
    function updateAllOutputProperties() {
      var i, j, l;

      readModelState();

      // invalidate all cached values before notifying any listeners
      for (i = 0; i < outputNames.length; i++) {
        outputsByName[outputNames[i]].hasCachedValue = false;
      }

      // Update all filtered outputs.
      // Note that this have to be performed after invalidation of all outputs
      // (as filtered output can filter another output), but before notifying
      // listeners (as we want to provide current, valid value).
      for (i = 0; i < filteredOutputNames.length; i++) {
        filteredOutputsByName[filteredOutputNames[i]].addSample();
      }

      for (i = 0; i < outputNames.length; i++) {
        if (l = listeners[outputNames[i]]) {
          for (j = 0; j < l.length; j++) {
            l[j]();
          }
        }
      }
    }

    /**
      ALWAYS CALL THIS FUNCTION before any change to model state outside a model step
      (i.e., outside a tick, seek, stepForward, stepBack)

      Note:  Changes to view-only property changes that cannot change model physics might reasonably
      by considered non-invalidating changes that don't require calling this hook.
    */
    function invalidatingChangePreHook() {
      storeOutputPropertiesBeforeChange();
    }

    /**
      ALWAYS CALL THIS FUNCTION after any change to model state outside a model step.
    */
    function invalidatingChangePostHook() {
      updateOutputPropertiesAfterChange();
      if (tickHistory) tickHistory.invalidateFollowingState();
      dispatch.invalidation();
    }

    /**
      Call this method *before* changing any "universe" property or model property (including any
      property of a model object such as the position of an turtle) to save the output-property
      values before the change. This is required to enabled updateOutputPropertiesAfterChange to be
      able to detect property value changes.

      After the change is made, call updateOutputPropertiesAfterChange to notify listeners.
    */
    function storeOutputPropertiesBeforeChange() {
      var i, outputName, output, l;

      for (i = 0; i < outputNames.length; i++) {
        outputName = outputNames[i];
        if ((l = listeners[outputName]) && l.length > 0) {
          output = outputsByName[outputName];
          // Can't save previous value in output.cachedValue because, before we check it, the
          // cachedValue may be overwritten with an updated value as a side effect of the
          // calculation of the updated value of some other property
          output.previousValue = output.hasCachedValue ? output.cachedValue : output.calculate();
        }
      }
    }

    /**
      Before changing any "universe" property or model property (including any
      property of a model object such as the position of an turtle), call the method
      storeOutputPropertiesBeforeChange; after changing the property, call this method  to detect
      changed output-property values and to notify listeners of the output properties which have
      changed. (However, don't call either method after a model tick or step;
      updateAllOutputProperties is more efficient for that case.)
    */
    function updateOutputPropertiesAfterChange() {
      var i, j, output, outputName, l, listenersToNotify = [];

      readModelState();

      // Mark _all_ cached values invalid ... we're not going to be checking the values of the
      // unobserved properties, so we have to assume their value changed.
      for (i = 0; i < outputNames.length; i++) {
        output = outputsByName[outputNames[i]];
        output.hasCachedValue = false;
      }

      // Update all filtered outputs.
      // Note that this have to be performed after invalidation of all outputs
      // (as filtered output can filter another output).
      for (i = 0; i < filteredOutputNames.length; i++) {
        filteredOutputsByName[filteredOutputNames[i]].addSample();
      }

      // Keep a list of output properties that are being observed and which changed ... and
      // cache the updated values while we're at it
      for (i = 0; i < outputNames.length; i++) {
        outputName = outputNames[i];
        output = outputsByName[outputName];

        if ((l = listeners[outputName]) && l.length > 0) {
          // Though we invalidated all cached values above, nevertheless some outputs may have been
          // computed & cached during a previous pass through this loop, as a side effect of the
          // calculation of some other property. Therefore we can respect hasCachedValue here.
          if (!output.hasCachedValue) {
            output.cachedValue = output.calculate();
            output.hasCachedValue = true;
          }

          if (output.cachedValue !== output.previousValue) {
            for (j = 0; j < l.length; j++) {
              listenersToNotify.push(l[j]);
            }
          }
        }
        // Now that we're done with it, allow previousValue to be GC'd. (Of course, since we're
        // using an equality test to check for changes, it doesn't make sense to let outputs be
        // objects or arrays, yet)
        output.previousValue = null;
      }

      // Finally, now that all the changed properties have been cached, notify listeners
      for (i = 0; i < listenersToNotify.length; i++) {
        listenersToNotify[i]();
      }
    }

    /**
      This method is called to refresh the results array and macrostate variables (KE, PE,
      temperature) whenever an engine integration occurs or the model state is otherwise changed.

      Normally, you should call the methods updateOutputPropertiesAfterChange or
      updateAllOutputProperties rather than calling this method. Calling this method directly does
      not cause output-property listeners to be notified, and calling it prematurely will confuse
      the detection of changed properties.
    */
    function readModelState() {
      var i, prop, n, amino;

      engine.computeOutputState(modelOutputState);

      extendResultsArray();

      // Transpose 'turtles' object into 'results' for easier consumption by view code
      for (i = 0, n = model.get_num_turtles(); i < n; i++) {
        for (prop in turtles) {
          if (turtles.hasOwnProperty(prop)) {
            results[i][prop] = turtles[prop][i];
          }
        }
      }
    }

    /**
      Ensure that the 'results' array of arrays is defined and contains one typed array per turtle
      for containing the turtle properties.
    */
    function extendResultsArray() {
      var i, len;

      if (!results) results = [];

      for (i = results.length, len = model.get_num_turtles(); i < len; i++) {
        if (!results[i]) {
          results[i] = {
            idx: i
          };
        }
      }
    }

    // ------------------------------------------------------------
    //
    // Public functions
    //
    // ------------------------------------------------------------

    /**
      Current seek position
    */
    model.stepCounter = function() {
      return tickHistory.get("counter");
    };

    /**
      Current position of first value in tick history, normally this will be 0.
      This will be greater than 0 if maximum size of tick history has been exceeded.
    */
    model.stepStartCounter = function() {
      return tickHistory.get("startCounter");
    };

    /** Total number of ticks that have been run & are stored, regardless of seek
        position
    */
    model.steps = function() {
      return tickHistory.get("length");
    };

    model.isNewStep = function() {
      return newStep;
    };

    model.seek = function(location) {
      if (!arguments.length) { location = 0; }
      stopped = true;
      newStep = false;
      tickHistory.seekExtract(location);
      updateAllOutputProperties();
      dispatch.seek();
      return tickHistory.get("counter");
    };

    model.stepBack = function(num) {
      if (!arguments.length) { num = 1; }
      var i, index;
      stopped = true;
      newStep = false;
      i=-1; while(++i < num) {
        index = tickHistory.get("index");
        if (index > 0) {
          tickHistory.decrementExtract();
          updateAllOutputProperties();
          dispatch.stepBack();
        }
      }
      return tickHistory.get("counter");
    };

    model.stepForward = function(num) {
      if (!arguments.length) { num = 1; }
      var i, index, size;
      stopped = true;
      i=-1; while(++i < num) {
        index = tickHistory.get("index");
        size = tickHistory.get("length");
        if (index < size-1) {
          tickHistory.incrementExtract();
          updateAllOutputProperties();
          dispatch.stepForward();
        } else {
          tick();
        }
      }
      return tickHistory.get("counter");
    };

    /**
      Creates a new pta engine and leaves it in 'engine'.
    */
    model.initializeEngine = function () {
      engine = pta.createEngine();

      engine.setSize([model.get('width'), model.get('height')]);
      engine.setHorizontalWrapping(model.get('horizontalWrapping'));
      engine.setVerticalWrapping(model.get('verticalWrapping'));

      window.state = modelOutputState = {};

      // Copy reference to basic properties.
      turtles = engine.turtles;
      patches = engine.patches;
    };

    /**
      Creates a new set of turtles.

      @config: either the number of turtles (for a random setup) or
               a hash specifying the x,y,vx,vy properties of the turtles
      When random setup is used, the option 'relax' determines whether the model is requested to
      relax to a steady-state temperature (and in effect gets thermalized). If false, the turtles are
      left in whatever grid the engine's initialization leaves them in.
    */
    model.createTurtles = function(config) {
          // Options for addTurtle method.
      var options = {
            // Do not check the position of turtle, assume that it's valid.
            supressCheck: true,
            // Deserialization process, invalidating change hooks will be called manually.
            deserialization: true
          },
          i, num, prop, turtleProps;

      // Call the hook manually, as addTurtle won't do it due to
      // deserialization option set to true.
      invalidatingChangePreHook();

      if (typeof config === 'number') {
        num = config;
      } else if (config.num != null) {
        num = config.num;
      } else if (config.x) {
        num = config.x.length;
      }

      // TODO: this branching based on x, y isn't very clear.
      if (config.x && config.y) {
        // config is hash of arrays (as specified in JSON model).
        // So, for each index, create object containing properties of
        // turtle 'i'. Later, use these properties to add turtle
        // using basic addTurtle method.
        for (i = 0; i < num; i++) {
          turtleProps = {};
          for (prop in config) {
            if (config.hasOwnProperty(prop)) {
              turtleProps[prop] = config[prop][i];
            }
          }
          model.addTurtle(turtleProps, options);
        }
      } else {
        for (i = 0; i < num; i++) {
          // Provide only required values.
          turtleProps = {x: 0, y: 0};
          model.addTurtle(turtleProps, options);
        }
        // This function rearrange all turtles randomly.
        engine.setupTurtlesRandomly();
      }

      // Call the hook manually, as addTurtle won't do it due to
      // deserialization option set to true.
      invalidatingChangePostHook();

      // Listeners should consider resetting the turtles a 'reset' event
      dispatch.reset();

      // return model, for chaining (if used)
      return model;
    };

    model.reset = function() {
      model.resetTime();
      tickHistory.restoreInitialState();
      dispatch.reset();
    };

    model.resetTime = function() {
      engine.setTime(0);
    };

    /**
      Attempts to add an 0-velocity turtle to a random location. Returns false if after 10 tries it
      can't find a location. (Intended to be exposed as a script API method.)

      Optionally allows specifying the element (default is to randomly select from all editableElements) and
      charge (default is neutral).
    */
    model.addRandomTurtle = function() {
      var size   = model.size(),
          radius = 1,
          x, y,
          vx, vy,
          loc;

      x = Math.random() * size[0] - 2*radius;
      y = Math.random() * size[1] - 2*radius;
      vx = (Math.random() - 0.5) / 100;
      vy = (Math.random() - 0.5) / 100;
      model.addTurtle({ x: x, y: x, vx: vx, vy: vy });
      return false;
    },

    /**
      Adds a new turtle defined by properties.
      Intended to be exposed as a script API method also.

      Adjusts (x,y) if needed so that the whole turtle is within the walls of the container.

      Returns false and does not add the turtle if the potential energy change of adding an *uncharged*
      turtle of the specified element to the specified location would be positive (i.e, if the turtle
      intrudes into the repulsive region of another turtle.)

      Otherwise, returns true.

      silent = true disables this check.
    */
    model.addTurtle = function(props, options) {
      var size = model.size(),
          radius = 1;

      options = options || {};

      // Validate properties, provide default values.
      props = validator.validateCompleteness(metadata.turtle, props);

      // When turtles are being deserialized, the deserializing function
      // should handle change hooks due to performance reasons.
      if (!options.deserialization)
        invalidatingChangePreHook();
      engine.addTurtle(props);
      if (!options.deserialization)
        invalidatingChangePostHook();

      if (!options.supressEvent) {
        dispatch.addTurtle();
      }

      return true;
    },

    model.removeTurtle = function(i, options) {

      options = options || {};

      invalidatingChangePreHook();
      engine.removeTurtle(i);
      // Enforce modeler to recalculate results array.
      results.length = 0;
      invalidatingChangePostHook();

      if (!options.supressEvent) {
        // Notify listeners that turtles is removed.
        dispatch.removeturtle();
      }
    },

    /**
        A generic method to set properties on a single existing turtle.

        Example: setturtleProperties(3, {x: 5, y: 8, px: 0.5, charge: -1})

        This can optionally check the new location of the turtle to see if it would
        overlap with another another turtle (i.e. if it would increase the PE).

        This can also optionally apply the same dx, dy to any turtles in the same
        molecule (if x and y are being changed), and check the location of all
        the bonded turtles together.
      */
    model.setTurtleProperties = function(i, props, checkLocation, moveMolecule) {
      var dx, dy,
          new_x, new_y,
          j, jj;

      // Validate properties.
      props = validator.validate(metadata.turtle, props);


      if (checkLocation) {
        var x  = typeof props.x === "number" ? props.x : turtles.x[i],
            y  = typeof props.y === "number" ? props.y : turtles.y[i];

        if (!engine.canPlaceturtle(el, x, y, i)) {
          return false;
        }
      }

      invalidatingChangePreHook();
      engine.setTurtleProperties(i, props);
      invalidatingChangePostHook();
      return true;
    };

    model.getTurtleProperties = function(i) {
      var turtleMetaData = metadata.turtle,
          props = {},
          propName;
      for (propName in turtleMetaData) {
        if (turtleMetaData.hasOwnProperty(propName)) {
          props[propName] = turtles[propName][i];
        }
      }
      return props;
    };

    model.addTextBox = function(props) {
      props = validator.validateCompleteness(metadata.textBox, props);
      properties.textBoxes.push(props);
      dispatch.textBoxesChanged();
    };

    model.removeTextBox = function(i) {
      var text = properties.textBoxes;
      if (i >=0 && i < text.length) {
        properties.textBoxes = text.slice(0,i).concat(text.slice(i+1))
        dispatch.textBoxesChanged();
      } else {
        throw new Error("Text box \"" + i + "\" does not exist, so it cannot be removed.");
      }
    };

    model.setTextBoxProperties = function(i, props) {
      var textBox = properties.textBoxes[i];
      if (textBox) {
        props = validator.validate(metadata.textBox, props);
        for (prop in props) {
          textBox[prop] = props[prop];
        }
        dispatch.textBoxesChanged();
      } else {
        throw new Error("Text box \"" + i + "\" does not exist, so it cannot have properties set.");
      }
    };

    model.is_stopped = function() {
      return stopped;
    };

    model.get_turtles = function() {
      return turtles;
    };

    model.get_results = function() {
      return results;
    };

    model.get_num_turtles = function() {
      return engine.getNumberOfTurtles();
    };

    model.on = function(type, listener) {
      dispatch.on(type, listener);
      return model;
    };

    model.tickInPlace = function() {
      dispatch.tick();
      return model;
    };

    model.tick = function(num, opts) {
      if (!arguments.length) num = 1;

      var dontDispatchTickEvent = opts && opts.dontDispatchTickEvent || false,
          i = -1;

      while(++i < num) {
        tick(null, dontDispatchTickEvent);
      }
      return model;
    };

    model.start = function() {
      return model.resume();
    };

    /**
      Restart the model (call model.resume()) after the next tick completes.

      This is useful for changing the modelSampleRate interactively.
    */
    model.restart = function() {
      restart = true;
    };

    model.resume = function() {

      console.time('gap between frames');
      model.timer(function timerTick(elapsedTime) {
        console.timeEnd('gap between frames');
        // Cancel the timer and refuse to to step the model, if the model is stopped.
        // This is necessary because there is no direct way to cancel a d3 timer.
        // See: https://github.com/mbostock/d3/wiki/Transitions#wiki-d3_timer)
        if (stopped) return true;

        if (restart) {
          setTimeout(model.resume, 0);
          return true;
        }

        tick(elapsedTime, false);

        console.time('gap between frames');
        return false;
      });

      restart = false;
      if (stopped) {
        stopped = false;
        dispatch.play();
      }

      return model;
    };

    /**
      Repeatedly calls `f` at an interval defined by the modelSampleRate property, until f returns
      true. (This is the same signature as d3.timer.)

      If modelSampleRate === 'default', try to run at the "requestAnimationFrame rate"
      (i.e., using d3.timer(), after running f, also request to run f at the next animation frame)

      If modelSampleRate !== 'default', instead uses setInterval to schedule regular calls of f with
      period (1000 / sampleRate) ms, corresponding to sampleRate calls/s
    */
    model.timer = function(f) {
      var intervalID,
          sampleRate = model.get("modelSampleRate");

      if (sampleRate === 'default') {
        // use requestAnimationFrame via d3.timer
        d3.timer(f);
      } else {
        // set an interval to run the model more slowly.
        intervalID = window.setInterval(function() {
          if ( f() ) {
            window.clearInterval(intervalID);
          }
        }, 1000/sampleRate);
      }
    };

    model.stop = function() {
      stopped = true;
      dispatch.stop();
      return model;
    };

    model.size = function(x) {
      if (!arguments.length) return engine.getSize();
      engine.setSize(x);
      return model;
    };

    model.set = function(hash) {
      // Perform validation in case of setting main properties or
      // model view properties. Attempts to set immutable or read-only
      // properties will be caught.
      validator.validate(metadata.mainProperties, hash);
      validator.validate(metadata.viewOptions, hash);

      if (engine) invalidatingChangePreHook();
      set_properties(hash);
      if (engine) invalidatingChangePostHook();
    };

    model.get = function(property) {
      var output;

      if (properties.hasOwnProperty(property)) return properties[property];

      if (output = outputsByName[property]) {
        if (output.hasCachedValue) return output.cachedValue;
        output.hasCachedValue = true;
        output.cachedValue = output.calculate();
        return output.cachedValue;
      }
    };

    /**
      Add a listener callback that will be notified when any of the properties in the passed-in
      array of properties is changed. (The argument `properties` can also be a string, if only a
      single name needs to be passed.) This is a simple way for views to update themselves in
      response to property changes.

      Observe all properties with `addPropertiesListener('all', callback);`
    */
    model.addPropertiesListener = function(properties, callback) {
      var i;

      function addListener(prop) {
        if (!listeners[prop]) listeners[prop] = [];
        listeners[prop].push(callback);
      }

      if (typeof properties === 'string') {
        addListener(properties);
      } else {
        for (i = 0; i < properties.length; i++) {
          addListener(properties[i]);
        }
      }
    };


    /**
      Add an "output" property to the model. Output properties are expected to change at every
      model tick, and may also be changed indirectly, outside of a model tick, by a change to the
      model parameters or to the configuration of turtles and other objects in the model.

      `name` should be the name of the parameter. The property value will be accessed by
      `model.get(<name>);`

      `description` should be a hash of metadata about the property. Right now, these metadata are not
      used. However, example metadata include the label and units name to be used when graphing
      this property.

      `calculate` should be a no-arg function which should calculate the property value.
    */
    model.defineOutput = function(name, description, calculate) {
      outputNames.push(name);
      outputsByName[name] = {
        description: description,
        calculate: calculate,
        hasCachedValue: false,
        // Used to keep track of whether this property changed as a side effect of some other change
        // null here is just a placeholder
        previousValue: null
      };
    };

    /**
      Add an "filtered output" property to the model. This is special kind of output property, which
      is filtered by one of the built-in filters based on time (like running average). Note that filtered
      outputs do not specify calculate function - instead, they specify property which should filtered.
      It can be another output, model parameter or custom parameter.

      Filtered output properties are extension of typical output properties. They share all features of
      output properties, so they are expected to change at every model tick, and may also be changed indirectly,
      outside of a model tick, by a change to the model parameters or to the configuration of turtles and other
      objects in the model.

      `name` should be the name of the parameter. The property value will be accessed by
      `model.get(<name>);`

      `description` should be a hash of metadata about the property. Right now, these metadata are not
      used. However, example metadata include the label and units name to be used when graphing
      this property.

      `property` should be name of the basic property which should be filtered.

      `type` should be type of filter, defined as string. For now only "RunningAverage" is supported.

      `period` should be number defining length of time period used for calculating filtered value. It should
      be specified in femtoseconds.

    */
    model.defineFilteredOutput = function(name, description, property, type, period) {
      // Filter object.
      var filter, initialValue;

      if (type === "RunningAverage") {
        filter = new RunningAverageFilter(period);
      } else {
        throw new Error("FilteredOutput: unknown filter type " + type + ".");
      }

      initialValue = model.get(property);
      if (initialValue === undefined || isNaN(Number(initialValue))) {
        throw new Error("FilteredOutput: property is not a valid numeric value or it is undefined.");
      }

      // Add initial sample.
      filter.addSample(model.get('time'), initialValue);

      filteredOutputNames.push(name);
      // filteredOutputsByName stores properties which are unique for filtered output.
      // Other properties like description or calculate function are stored in outputsByName hash.
      filteredOutputsByName[name] = {
        addSample: function () {
          filter.addSample(model.get('time'), model.get(property));
        }
      };

      // Create simple adapter implementing TickHistoryCompatible Interface
      // and register it in tick history.
      tickHistory.registerExternalObject({
        push: function () {
          // Push is empty, as we store samples during each tick anyway.
        },
        extract: function (idx) {
          filter.setCurrentStep(idx);
        },
        invalidate: function (idx) {
          filter.invalidate(idx);
        },
        setHistoryLength: function (length) {
          filter.setMaxBufferLength(length);
        }
      });

      // Extend description to contain information about filter.
      description.property = property;
      description.type = type;
      description.period = period;

      // Filtered output is still an output.
      // Reuse existing, well tested logic for caching, observing etc.
      model.defineOutput(name, description, function () {
        return filter.calculate();
      });
    };

    /**
      Define a property of the model to be treated as a custom parameter. Custom parameters are
      (generally, user-defined) read/write properties that trigger a setter action when set, and
      whose values are automatically persisted in the tick history.

      Because custom parameters are not intended to be interpreted by the engine, but instead simply
      *represent* states of the model that are otherwise fully specified by the engine state and
      other properties of the model, and because the setter function might not limit itself to a
      purely functional mapping from parameter value to model properties, but might perform any
      arbitrary stateful change, (stopping the model, etc.), the setter is NOT called when custom
      parameters are updated by the tick history.
    */
    model.defineParameter = function(name, description, setter) {
      parametersByName[name] = {
        description: description,
        setter: setter,
        isDefined: false
      };

      properties['set_'+name] = function(value) {
        properties[name] = value;
        parametersByName[name].isDefined = true;
        // set a useful 'this' binding in the setter:
        parametersByName[name].setter.call(model, value);
      };
    };

    /**
      Retrieve (a copy of) the hash describing property 'name', if one exists. This hash can store
      an arbitrary set of key-value pairs, but is expected to have 'label' and 'units' properties
      describing, respectively, the property's human-readable label and the short name of the units
      in which the property is enumerated.

      Right now, only output properties and custom parameters have a description hash.
    */
    model.getPropertyDescription = function(name) {
      var property = outputsByName[name] || parametersByName[name];
      if (property) {
        return _.extend({}, property.description);
      }
    };

    // FIXME: Broken!! Includes property setter methods, does not include radialBonds, etc.
    model.serialize = function() {
      var propCopy = {},
          ljProps, i, len,

          removeturtlesArrayIfDefault = function(name, defaultVal) {
            if (propCopy.turtles[name].every(function(i) {
              return i === defaultVal;
            })) {
              delete propCopy.turtles[name];
            }
          };

      propCopy = serialize(metadata.mainProperties, properties);
      propCopy.viewOptions = serialize(metadata.viewOptions, properties);
      propCopy.turtles = serialize(metadata.turtle, turtles, engine.getNumberOfTurtles());

      removeturtlesArrayIfDefault("marked", metadata.turtle.marked.defaultValue);
      removeturtlesArrayIfDefault("visible", metadata.turtle.visible.defaultValue);

      return propCopy;
    };

    // ------------------------------
    // finish setting up the model
    // ------------------------------

    // Define some default output properties.
    model.defineOutput('time', {
      label: "Time",
      units: "fs"
    }, function() {
      return modelOutputState.time;
    });

    // Set the regular, main properties.
    // Note that validation process will return hash without all properties which are
    // not defined in meta model as mainProperties (like turtles, viewOptions etc).
    set_properties(validator.validateCompleteness(metadata.mainProperties, initialProperties));

    // Set the model view options.
    set_properties(validator.validateCompleteness(metadata.viewOptions, initialProperties.viewOptions || {}));

    // Setup engine object.
    model.initializeEngine();

    // Finally, if provided, set up the model objects (turtles).
    // However if these are not provided, client code can create turtles, etc piecemeal.

    if (initialProperties.turtles) {
      model.createTurtles(initialProperties.turtles);
    }

    // Initialize tick history.
    tickHistory = new TickHistory({
      input: [
        "showClock",
        "viewRefreshInterval",
        "timeStep"
      ],
      restoreProperties: restoreProperties,
      parameters: parametersByName,
      restoreParameters: restoreParameters,
      state: engine.getState()
    }, model, defaultMaxTickHistory);

    newStep = true;
    updateAllOutputProperties();

    return model;
  };
});

/*global define: false, $: false, model: false */
// ------------------------------------------------------------
//
//   Screen Layout
//
// ------------------------------------------------------------

define('common/layout/layout',['require'],function (require) {

  var layout = { version: "0.0.1" };

  layout.selection = "";

  layout.display = {};

  layout.canonical = {
    width:  1280,
    height: 800
  };

  layout.regularDisplay = false;

  layout.notRendered = true;
  layout.fontsize = false;
  layout.emsize = 1;
  layout.cancelFullScreen = false;
  layout.checkboxFactor = 1.1;
  layout.checkboxScale = 1.1;
  layout.fullScreenRender = false;

  layout.canonical.width  = 1280;
  layout.canonical.height = 800;

  layout.getDisplayProperties = function(obj) {
    if (!arguments.length) {
      obj = {};
    }
    obj.screen = {
        width:  screen.width,
        height: screen.height
    };
    obj.client = {
        width:  document.body.clientWidth,
        height: document.body.clientHeight
    };
    obj.window = {
        width:  $(window).width(),
        height: $(window).height()
    };
    obj.page = {
        width: layout.getPageWidth(),
        height: layout.getPageHeight()
    };
    obj.screenFactorWidth  = obj.window.width / layout.canonical.width;
    obj.screenFactorHeight = obj.window.height / layout.canonical.height;
    obj.emsize = Math.max(obj.screenFactorWidth * 1.1, obj.screenFactorHeight);
    return obj;
  };

  layout.setBodyEmsize = function(scale) {
    var emsize,
        $componentsWithText = $("#interactive-container  p,label,button,select,option").filter(":visible"),
        $headerContent = $("#content-banner div"),
        $popupPanes = $("#credits-pane, #share-pane, #about-pane").find("div,textarea,label,select"),
        minFontSize;
    if (!layout.display) {
      layout.display = layout.getDisplayProperties();
    }
    emsize = Math.max(layout.display.screenFactorWidth * 1.2, layout.display.screenFactorHeight * 1.2);
    if (scale) { emsize *= scale; }
    $('body').css('font-size', emsize + 'em');
    applyMinFontSizeFilter(emsize, $componentsWithText, "9px");
    applyMinFontSizeFilter(emsize, $headerContent, "10px");
    applyMinFontSizeFilter(emsize, $popupPanes, "9px");
    layout.emsize = emsize;
  };

  function applyMinFontSizeFilter(emsize, $elements, minSize) {
    if (emsize <= 0.5) {
      $elements.css("font-size", minSize);
    } else {
      $elements.each(function() {
        var style,
            index;
        if (!style) {
          style = $(this).attr('style');
        }
        if (style) {
          index = style.indexOf('font-size');
          if (index !== -1) {
            style = style.replace(/font-size: .*;/g, '');
            $(this).attr('style', style);
          }
        }
      });
    }
  }

  layout.getVizProperties = function(obj) {
    var $viz = $('#viz');

    if (!arguments.length) {
      obj = {};
    }
    obj.width = $viz.width();
    obj.height = $viz.height();
    obj.screenFactorWidth  = obj.width / layout.canonical.width;
    obj.screenFactorHeight = obj.height / layout.canonical.height;
    obj.emsize = Math.min(obj.screenFactorWidth * 1.1, obj.screenFactorHeight);
    return obj;
  };

  layout.setVizEmsize = function() {
    var emsize,
        $viz = $('#viz');

    if (!layout.vis) {
      layout.vis = layout.getVizProperties();
    }
    emsize = Math.min(layout.viz.screenFactorWidth * 1.2, layout.viz.screenFactorHeight * 1.2);
    $viz.css('font-size', emsize + 'em');
  };

  layout.screenEqualsPage = function() {
    return ((layout.display.screen.width  === layout.display.page.width) ||
            (layout.display.screen.height === layout.display.page.height));
  };

  layout.checkForResize = function() {
    if ((layout.display.screen.width  !== screen.width) ||
        (layout.display.screen.height !== screen.height) ||
        (layout.display.window.width  !== document.width) ||
        (layout.display.window.height !== document.height)) {
      layout.setupScreen();
    }
  };

  layout.views = {};

  layout.addView = function(type, view) {
    if (!layout.views[type]) {
      layout.views[type] = [];
    }
    layout.views[type].push(view);
  };

  layout.setView = function(type, viewArray) {
    layout.views[type] = viewArray;
  };

  layout.setupScreen = function(event) {
    var emsize,
        viewLists  = layout.views,
        fullscreen = document.fullScreen ||
                     document.webkitIsFullScreen ||
                     document.mozFullScreen;

    if (event && event.forceRender) {
      layout.notRendered = true;
    }

    layout.display = layout.getDisplayProperties();
    layout.viz = layout.getVizProperties();

    if (!layout.regularDisplay) {
      layout.regularDisplay = layout.getDisplayProperties();
    }


    if(fullscreen || layout.fullScreenRender  || layout.screenEqualsPage()) {
      layout.fullScreenRender = true;
      layout.screenFactorWidth  = layout.display.page.width / layout.canonical.width;
      layout.screenFactorHeight = layout.display.page.height / layout.canonical.height;
      layout.checkboxFactor = Math.max(0.8, layout.checkboxScale * layout.emsize);
      $('body').css('font-size', layout.emsize + "em");
      layout.notRendered = true;
      switch (layout.selection) {

        // only fluid on page load (and when resizing on transition to and from full-screen)
        default:
        if (layout.notRendered) {
          setupFullScreen();
        }
        break;
      }
    } else {
      if (layout.cancelFullScreen || layout.fullScreenRender) {
        layout.cancelFullScreen = false;
        layout.fullScreenRender = false;
        layout.notRendered = true;
        layout.regularDisplay = layout.previous_display;
      } else {
        layout.regularDisplay = layout.getDisplayProperties();
      }
      layout.screenFactorWidth  = layout.display.page.width / layout.canonical.width;
      layout.screenFactorHeight = layout.display.page.height / layout.canonical.height;
      layout.checkboxFactor = Math.max(0.8, layout.checkboxScale * layout.emsize);
      switch (layout.selection) {

        // all component position definitions are set from properties
        case "interactive-iframe":
        layout.setBodyEmsize();
        setupInteractiveIFrameScreen();
        break;

        // like interactive-iframe, but has editor on left
        case "interactive-author-iframe":
        layout.setBodyEmsize(0.7);
        setupInteractiveAuthorIFrameScreen();
        break;

        default:
        layout.setVizEmsize();
        setupRegularScreen();
        break;
      }
      layout.regularDisplay = layout.getDisplayProperties();
    }

    //
    //
    // Interactive iframe Screen Layout
    //
    function setupInteractiveIFrameScreen() {
      var i,
          modelWidth,
          modelHeight,
          modelDimensions,
          modelAspectRatio,
          modelWidthFactor,
          modelPaddingFactor,
          modelHeightFactor = 0.85,
          bottomFactor = 0.0015,
          viewSizes = {},
          viewType,
          containerWidth = $(window).width(),
          containerHeight = $(window).height(),
          mcWidth = $('#model-container').width();

      modelDimensions = viewLists.modelContainers[0].scale();
      modelAspectRatio = modelDimensions[2] / modelDimensions[3];
      modelWidthFactor = 0.85;

      modelWidthPaddingFactor = modelDimensions[0]/modelDimensions[2] - 1.05;
      modelWidthFactor -= modelWidthPaddingFactor;

      modelHeightPaddingFactor = modelDimensions[1]/modelDimensions[3] - 1.05;
      modelHeightFactor -= modelHeightPaddingFactor;

      if (viewLists.thermometers) {
        modelWidthFactor -= 0.10;
      }

      if (viewLists.energyGraphs) {
        modelWidthFactor -= 0.35;
      }

      // account for proportionally larger buttons when embeddable size gets very small
      if (layout.emsize <= 0.5) {
        bottomFactor *= 0.5/layout.emsize;
      }

      viewLists.bottomItems = $('#bottom').children().length;
      if (viewLists.bottomItems) {
        modelHeightFactor -= ($('#bottom').height() * bottomFactor);
      }

      modelWidth = containerWidth * modelWidthFactor;
      modelHeight = modelWidth / modelAspectRatio;
      if (modelHeight > containerHeight * modelHeightFactor) {
        modelHeight = containerHeight * modelHeightFactor;
        modelWidth = modelHeight * modelAspectRatio;
      }
      viewSizes.modelContainers = [modelWidth, modelHeight];
      if (viewLists.energyGraphs) {
        viewSizes.energyGraphs = [containerWidth * 0.40];
      }

      // Resize modelContainer first to determine actual container height for right-side
      // Probably a way to do this with CSS ...
      viewLists.modelContainers[0].resize(modelWidth, modelHeight);

      modelHeight = $("#model-container").height();
      $("#rightwide").height(modelHeight);

      if (viewLists.barGraphs) {
        // Keep width of the bar graph proportional to its height.
        viewSizes.barGraphs = [35 + modelHeight * 0.22];
      }

      for (viewType in viewLists) {
        // if (viewType === "modelContainers") continue;
        if (viewLists.hasOwnProperty(viewType) && viewLists[viewType].length) {
          i = -1;  while(++i < viewLists[viewType].length) {
            if (viewSizes[viewType]) {
              viewLists[viewType][i].resize(viewSizes[viewType][0], viewSizes[viewType][1]);
            } else {
              viewLists[viewType][i].resize();
            }
          }
        }
      }
    }

    //
    //
    // Interactive authoring iframe Screen Layout
    //
    function setupInteractiveAuthorIFrameScreen() {
      var i,
          modelWidth,
          modelHeight,
          modelDimensions,
          modelAspectRatio,
          modelWidthFactor,
          modelPaddingFactor,
          modelHeightFactor = 0.85,
          bottomFactor = 0.0015,
          viewSizes = {},
          viewType,
          containerWidth = $("#content").width(),
          containerHeight = $("#content").height();

      modelDimensions = viewLists.modelContainers[0].scale();
      modelAspectRatio = modelDimensions[2] / modelDimensions[3];
      modelWidthFactor = 0.85;

      modelWidthPaddingFactor = modelDimensions[0]/modelDimensions[2] - 1.05;
      modelWidthFactor -= modelWidthPaddingFactor;

      modelHeightPaddingFactor = modelDimensions[1]/modelDimensions[3] - 1.05;
      modelHeightFactor -= modelHeightPaddingFactor;

      if (viewLists.thermometers) {
        modelWidthFactor -= 0.05;
      }

      if (viewLists.barGraphs) {
        modelWidthFactor -= 0.15;
      }

      if (viewLists.energyGraphs) {
        modelWidthFactor -= 0.35;
      }

      // account for proportionally larger buttons when embeddable size gets very small
      if (layout.emsize <= 0.5) {
        bottomFactor *= 0.5/layout.emsize;
      }

      viewLists.bottomItems = $('#bottom').children().length;
      if (viewLists.bottomItems) {
        modelHeightFactor -= ($('#bottom').height() * bottomFactor);
      }

      modelWidth = containerWidth * modelWidthFactor;
      modelHeight = modelWidth / modelAspectRatio;
      if (modelHeight > containerHeight * modelHeightFactor) {
        modelHeight = containerHeight * modelHeightFactor;
        modelWidth = modelHeight * modelAspectRatio;
      }
      viewSizes.modelContainers = [modelWidth, modelHeight];
      if (viewLists.energyGraphs) {
        viewSizes.energyGraphs = [containerWidth * 0.40];
      }

      // Resize modelContainer first to determine actual container height for right-side
      // Probably a way to do this with CSS ...
      viewLists.modelContainers[0].resize(modelWidth, modelHeight);

      modelHeight = $("#model-container").height();
      $("#rightwide").height(modelHeight);

      if (viewLists.barGraphs) {
        // Keep width of the bar graph proportional to its height.
        viewSizes.barGraphs = [35 + modelHeight * 0.22];
      }

      for (viewType in viewLists) {
        if (viewType === "modelContainers") continue;
        if (viewLists.hasOwnProperty(viewType) && viewLists[viewType].length) {
          i = -1;  while(++i < viewLists[viewType].length) {
            if (viewSizes[viewType]) {
              viewLists[viewType][i].resize(viewSizes[viewType][0], viewSizes[viewType][1]);
            } else {
              viewLists[viewType][i].resize();
            }
          }
        }
      }
    }

    //
    // Compare Screen Layout
    //
    function compareScreen() {
      var i, width, height, mcsize, modelAspectRatio,
          pageWidth = layout.display.page.width,
          pageHeight = layout.display.page.height;

      mcsize = viewLists.modelContainers[0].scale();
      modelAspectRatio = mcsize[0] / mcsize[1];
      width = pageWidth * 0.40;
      height = width * 1/modelAspectRatio;
      // HACK that will normally only work with one modelContainer
      // or if all the modelContainers end up the same width
      i = -1;  while(++i < viewLists.modelContainers.length) {
        viewLists.modelContainers[i].resize(width, height);
      }
      if (viewLists.appletContainers) {
        i = -1;  while(++i < viewLists.appletContainers.length) {
          viewLists.appletContainers[i].resize(width, height);
        }
      }
    }

    //
    // Full Screen Layout
    //
    function setupFullScreen() {
      var i, width, height, mcsize,
          rightHeight, rightHalfWidth, rightQuarterWidth,
          widthToPageRatio, modelAspectRatio,
          pageWidth = layout.display.page.width,
          pageHeight = layout.display.page.height;

      mcsize = viewLists.modelContainers[0].scale();
      modelAspectRatio = mcsize[0] / mcsize[1];
      widthToPageRatio = mcsize[0] / pageWidth;
      width = pageWidth * 0.46;
      height = width * 1/modelAspectRatio;
      if (height > pageHeight*0.70) {
        height = pageHeight * 0.70;
        width = height * modelAspectRatio;
      }
      i = -1;  while(++i < viewLists.modelContainers.length) {
        viewLists.modelContainers[i].resize(width, height);
      }
      rightQuarterWidth = (pageWidth - width) * 0.41;
      rightHeight = height * 0.42;
      i = -1;  while(++i < viewLists.potentialCharts.length) {
        viewLists.potentialCharts[i].resize(rightQuarterWidth, rightHeight);
      }
      i = -1;  while(++i < viewLists.speedDistributionCharts.length) {
        viewLists.speedDistributionCharts[i].resize(rightQuarterWidth, rightHeight);
      }
      rightHalfWidth = (pageWidth - width) * 0.86;
      rightHeight = height * 0.57;
      i = -1;  while(++i < viewLists.energyCharts.length) {
        viewLists.energyCharts[i].resize(rightHalfWidth, rightHeight);
      }
    }
  };

  layout.getPageHeight = function() {
    return $(document).height();
  };

  layout.getPageWidth = function() {
    return $(document).width();
  };

  // Finally, return ready module.
  return layout;
});

/*global $ alert ACTUAL_ROOT model_player define: false, d3: false */
// ------------------------------------------------------------
//
//   PTA View Renderer
//
// ------------------------------------------------------------
define('pta/views/renderer',['require','common/console','common/layout/layout','cs!common/layout/wrap-svg-text'],function (require) {
  // Dependencies.
  var console               = require('common/console'),
      layout                = require('common/layout/layout'),
      wrapSVGText           = require('cs!common/layout/wrap-svg-text');

  return function PTAView(model, containers, m2px, m2pxInv) {
        // Public API object to be returned.
    var api = {},

        mainContainer,

        modelWidth,
        modelHeight,
        aspectRatio,

        model2px = m2px,
        model2pxInv = m2pxInv,

        // The model function get_results() returns a 2 dimensional array
        // of particle indices and properties that is updated every model tick.
        // This array is not garbage-collected so the view can be assured that
        // the latest results will be in this array when the view is executing
        modelResults,

        // Array which defines a gradient assigned to a given turtle.
        gradientNameForTurtle = [],

        turtleTooltipOn,

        turtle,
        label, labelEnter,
        turtleDiv, turtleDivPre,

        // for model clock
        showClock,
        timeLabel,
        modelTimeFormatter = d3.format("5.0f"),
        timePrefix = "",
        timeSuffix = "",

        // Basic scaling function, it transforms model units to "pixels".
        // Use it for dimensions of objects rendered inside the view.
        model2px,
        // Inverted scaling function transforming model units to "pixels".
        // Use it for Y coordinates, as model coordinate system has (0, 0) point
        // in lower left corner, but SVG has (0, 0) point in upper left corner.
        model2pxInv;

    function modelTimeLabel() {
      return timePrefix + modelTimeFormatter(model.get('time')/100) + timeSuffix;
    }

    // Returns gradient appropriate for a given turtle.
    // d - turtle data.
    function getTurtleGradient(d) {
      if (d.marked) {
        return "url(#mark-grad)";
      } else {
        return "url(#neutral-grad)";
      }
    }

    function updateTurtleRadius() {
      mainContainer.selectAll("circle").data(modelResults).attr("r",  function(d) { return model2px(d.radius); });
    }

    function setupColorsOfTurtles() {
      var i, len;

      gradientNameForTurtle.length = modelResults.length;
      for (i = 0, len = modelResults.length; i < len; i++)
        gradientNameForTurtle[i] = getTurtleGradient(modelResults[i]);
    }

    function setupTurtles() {

      mainContainer.selectAll("circle").remove();
      mainContainer.selectAll("g.label").remove();

      turtle = mainContainer.selectAll("circle").data(modelResults);

      turtleEnter();

      label = mainContainer.selectAll("g.label")
          .data(modelResults);

      labelEnter = label.enter().append("g")
          .attr("class", "label")
          .attr("transform", function(d) {
            return "translate(" + model2px(d.x) + "," + model2pxInv(d.y) + ")";
          });

      labelEnter.each(function (d) {
        var selection = d3.select(this),
            txtValue, txtSelection;
        // Append appropriate label. For now:
        // If 'turtleNumbers' option is enabled, use indices.
        // If not and there is available 'label'/'symbol' property, use one of them
        if (model.get("turtleNumbers")) {
          selection.append("text")
            .text(d.idx)
            .style("font-size", model2px(1.4 * d.radius) + "px");
        }
        // Set common attributes for labels (+ shadows).
        txtSelection = selection.selectAll("text");
        // Check if node exists and if so, set appropriate attributes.
        if (txtSelection.node()) {
          txtSelection
            .attr("pointer-events", "none")
            .style({
              "font-weight": "bold",
              "opacity": 0.7
            });
          txtSelection
            .attr({
              // Center labels, use real width and height.
              // Note that this attrs should be set *after* all previous styling options.
              // .node() will return first node in selection. It's OK - both texts
              // (label and its shadow) have the same dimension.
              "x": -txtSelection.node().getComputedTextLength() / 2,
              "y": "0.31em"//bBox.height / 4
            });
        }
        // Set common attributes for shadows.
        selection.select("text.shadow")
          .style({
            "stroke": "#fff",
            "stroke-width": 0.15 * model2px(d.radius),
            "stroke-opacity": 0.7
          });
      });
    }

    /**
      Call this wherever a d3 selection is being used to add circles for turtles
    */

    function turtleEnter() {
      turtle.enter().append("circle")
          .attr({
            "r":  function(d) {
              return model2px(d.radius); },
            "cx": function(d) {
              return model2px(d.x); },
            "cy": function(d) {
              return model2pxInv(d.y); }
          })
          .style({
            "fill-opacity": function(d) { return d.visible; },
            "fill": function (d, i) { return gradientNameForTurtle[i]; }
          })
          .on("mousedown", turtleMouseDown)
          .on("mouseover", turtleMouseOver)
          .on("mouseout", turtleMouseOut);
    }

    function turtleUpdate() {
      turtle.attr({
        "r":  function(d) {
          return model2px(d.radius); },
        "cx": function(d) {
          return model2px(d.x); },
        "cy": function(d) {
          return model2pxInv(d.y); }
      });

      if (turtleTooltipOn === 0 || turtleTooltipOn > 0) {
        renderTurtleTooltip(turtleTooltipOn);
      }
    }

    function turtleMouseOver(d, i) {
      if (model.get("enableTurtleTooltips")) {
        renderTurtleTooltip(i);
      }
    }

    function turtleMouseDown(d, i) {
      containers.node.focus();
      if (model.get("enableTurtleTooltips")) {
        if (turtleTooltipOn !== false) {
          turtleDiv.style("opacity", 1e-6);
          turtleDiv.style("display", "none");
          turtleTooltipOn = false;
        } else {
          if (d3.event.shiftKey) {
            turtleTooltipOn = i;
          } else {
            turtleTooltipOn = false;
          }
          renderTurtleTooltip(i);
        }
      }
    }

    function renderTurtleTooltip(i) {
      turtleDiv
            .style("opacity", 1.0)
            .style("display", "inline")
            .style("background", "rgba(100%, 100%, 100%, 0.7)")
            .style("left", model2px(modelResults[i].x) + 60 + "px")
            .style("top",  model2pxInv(modelResults[i].y) + 30 + "px")
            .style("zIndex", 100)
            .transition().duration(250);

      turtleDivPre.text(
          "turtle: " + i + "\n" +
          "time: " + modelTimeLabel() + "\n" +
          "speed: " + d3.format("+6.3e")(modelResults[i].speed) + "\n" +
          "vx:    " + d3.format("+6.3e")(modelResults[i].vx)    + "\n" +
          "vy:    " + d3.format("+6.3e")(modelResults[i].vy)    + "\n" +
          "ax:    " + d3.format("+6.3e")(modelResults[i].ax)    + "\n" +
          "ay:    " + d3.format("+6.3e")(modelResults[i].ay)    + "\n"
        );
    }

    function turtleMouseOut() {
      if (!turtleTooltipOn && turtleTooltipOn !== 0) {
        turtleDiv.style("opacity", 1e-6).style("zIndex" -1);
      }
    }

    function setupTooTips() {
      if ( turtleDiv === undefined) {
        turtleDiv = d3.select("body").append("div")
            .attr("class", "tooltip")
            .style("opacity", 1e-6);
        turtleDivPre = turtleDiv.append("pre");
      }
    }

    function setupClock() {
      var xunitOffset;
      xunitOffset = model.get("xunits") ? 30 : 0;
      // add model time display
      mainContainer.selectAll('.modelTimeLabel').remove();
      // Update clock status.
      showClock = model.get("showClock");
      if (showClock) {
        timeLabel = mainContainer.append("text")
          .attr("class", "modelTimeLabel")
          .text(modelTimeLabel())
          // Set text position to (0nm, 0nm) (model domain) and add small, constant offset in px.
          .attr("x", model2px(0) + 5 * emsize)
          .attr("y", model2pxInv(0) + 30 * emsize + xunitOffset * emsize)
          .style("text-anchor","start");
      }
    }

    //
    // *** Main Renderer functions ***
    //

    //
    // PTA Renderer: init
    //
    // Called when Renderer is created.
    //
    function init() {
      mainContainer = containers.mainContainer,
      modelResults  = model.get_results();
      modelWidth    = model.get('width');
      modelHeight   = model.get('height');
      aspectRatio   = modelWidth / modelHeight;

      setupTooTips();
      repaint();
      model.on('addTurtle', repaint);
      model.on('removeTurtle', repaint);
    }

    //
    // MD2D Renderer: reset
    //
    // Call when model is reset or reloaded.
    //
    function reset(mod, cont, m2px, m2pxInv) {
      model = mod;
      containers = cont;
      model2px = m2px;
      model2pxInv = m2pxInv;
      init();
    }

    //
    // PTA Renderer: repaint
    //
    // Call when container being rendered into changes size, in that case
    // pass in new D3 scales for model2pcx transformations.
    //
    // Also call when the number of objects changes suc that the conatiner
    // must be setup again.
    //
    function repaint(m2px, m2pxInv) {
      if (arguments.length) {
        model2px = m2px;
        model2pxInv = m2pxInv;
      }
      emsize = layout.getVizProperties().emsize;
      setupClock();
      setupColorsOfTurtles();
      setupTurtles();
    }

    //
    // PTA Renderer: update
    //
    // Call to update visualization when model result state changes.
    // Normally called on every model tick.
    //
    function update() {
      console.time('view update');

      // update model time display
      if (showClock) {
        timeLabel.text(modelTimeLabel());
      }

      turtleUpdate();

      console.timeEnd('view update');
    }

    //
    // Public API to instantiated Renderer
    //
    api = {
      // Expose private methods.
      update: update,
      repaint: repaint,
      reset: reset,
      model2px: function(val) {
        // Note that we shouldn't just do:
        // api.nm2px = nm2px;
        // as nm2px local variable can be reinitialized
        // many times due container rescaling process.
        return model2px(val);
      },
      model2pxInv: function(val) {
        // See comments for nm2px.
        return model2pxInv(val);
      }
    };

    // Initialization.
    init();

    return api;
  };
});

/*global $ define: false */
// ------------------------------------------------------------
//
//   PTA View Container
//
// ------------------------------------------------------------
define('pta/views/view',['require','common/console','common/views/model-view','pta/views/renderer'],function (require) {
  // Dependencies.
  var console               = require('common/console'),
      ModelView             = require("common/views/model-view"),
      Renderer              = require("pta/views/renderer");

  return function (e, modelUrl, model) {
    return new ModelView(e, modelUrl, model, Renderer);
  }

});

/*global define model */

define('pta/controllers/scripting-api',['require'],function (require) {

  /**
    Define the model-specific PTA scripting API used by 'action' scripts on interactive elements.

    The universal Interactive scripting API is extended with the properties of the
    object below which will be exposed to the interactive's 'action' scripts as if
    they were local vars. All other names (including all globals, but excluding
    Javascript builtins) will be unavailable in the script context; and scripts
    are run in strict mode so they don't accidentally expose or read globals.

    @param: api
  */

  return function PTAScriptingAPI (api) {

    return {
      /* Returns number of turtles in the system. */
      getNumberOfTurtles: function getNumberOfTurtles() {
        return model.get_num_turtles();
      },

      addTurtle: function addTurtle(props, options) {
        if (options && options.supressRepaint) {
          // Translate supressRepaint option to
          // option understable by modeler.
          // supresRepaint is a conveniance option for
          // Scripting API users.
          options.supressEvent = true;
        }
        return model.addTurtle(props, options);
      },

      /*
        Removes turtle 'i'.
      */
      removeTurtle: function removeTurtle(i, options) {
        if (options && options.supressRepaint) {
          // Translate supressRepaint option to
          // option understable by modeler.
          // supresRepaint is a conveniance option for
          // Scripting API users.
          options.supressEvent = true;
          delete options.supressRepaint;
        }
        try {
          model.removeTurtle(i, options);
        } catch (e) {
          if (!options || !options.silent)
            throw e;
        }
      },

      addRandomTurtle: function addRandomTurtle() {
        return model.addRandomTurtle.apply(model, arguments);
      },

      /** returns a list of integers corresponding to turtles in the system */
      randomTurtles: function randomTurtles(n) {
        var numTurtles = model.get_num_turtles();

        if (n === null) n = 1 + api.randomInteger(numTurtles-1);

        if (!api.isInteger(n)) throw new Error("randomTurtles: number of turtles requested, " + n + ", is not an integer.");
        if (n < 0) throw new Error("randomTurtles: number of turtles requested, " + n + ", was less be greater than zero.");

        if (n > numTurtles) n = numTurtles;
        return api.choose(n, numTurtles);
      },

      /**
        Accepts turtle indices as arguments, or an array containing turtle indices.
        Unmarks all turtles, then marks the requested turtle indices.
        Repaints the screen to make the marks visible.
      */
      markTurtles: function markTurtles() {
        var i,
            len;

        if (arguments.length === 0) return;

        // allow passing an array instead of a list of turtle indices
        if (api.isArray(arguments[0])) {
          return markTurtles.apply(null, arguments[0]);
        }

        api.unmarkAllTurtles();

        // mark the requested turtles
        for (i = 0, len = arguments.length; i < len; i++) {
          model.setTurtleProperties(arguments[i], {marked: 1});
        }
        api.repaint();
      },

      unmarkAllTurtles: function unmarkAllTurtles() {
        for (var i = 0, len = model.get_num_turtles(); i < len; i++) {
          model.setTurtleProperties(i, {marked: 0});
        }
        api.repaint();
      },

      /**
        Sets individual turtle properties using human-readable hash.
        e.g. setTurtleProperties(5, {x: 1, y: 0.5, charge: 1})
      */
      setTurtleProperties: function setTurtleProperties(i, props, checkLocation, moveMolecule, options) {
        model.setTurtleProperties(i, props, checkLocation, moveMolecule);
        if (!(options && options.supressRepaint)) {
          api.repaint();
        }
      },

      /**
        Returns turtle properties as a human-readable hash.
        e.g. getTurtleProperties(5) --> {x: 1, y: 0.5, charge: 1, ... }
      */
      getTurtleProperties: function getTurtleProperties(i) {
        return model.getTurtleProperties(i);
      },

      addTextBox: function(props) {
        model.addTextBox(props);
      },

      removeTextBox: function(i) {
        model.removeTextBox(i);
      },

      setTextBoxProperties: function(i, props) {
        model.setTextBoxProperties(i, props);
      }

    };

  };
});

/*global define model */

define('pta/benchmarks/benchmarks',['require'],function (require) {

  return function Benchmarks(controller) {

    var benchmarks = [
      {
        name: "commit",
        numeric: false,
        run: function(done) {
          var link = "<a href='"+Lab.version.repo.commit.url+"' class='opens-in-new-window' target='_blank'>"+Lab.version.repo.commit.short_sha+"</a>";
          if (Lab.version.repo.dirty) {
            link += " <i>dirty</i>";
          }
          done(link);
        }
      },
      {
        name: "turtles",
        numeric: true,
        run: function(done) {
          done(model.get_num_turtles());
        }
      },
      {
        name: "just graphics (steps/s)",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          var elapsed, start, i;

          model.stop();
          start = +Date.now();
          i = -1;
          while (i++ < 100) {
            controller.modelContainer.update();
          }
          elapsed = Date.now() - start;
          done(100/elapsed*1000);
        }
      },
      {
        name: "model (steps/s)",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          var elapsed, start, i;

          model.stop();
          start = +Date.now();
          i = -1;
          while (i++ < 100) {
            // advance model 1 tick, but don't paint the display
            model.tick(1, { dontDispatchTickEvent: true });
          }
          elapsed = Date.now() - start;
          done(100/elapsed*1000);
        }
      },
      {
        name: "model+graphics (steps/s)",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          var start, elapsed, i;

          model.stop();
          start = +Date.now();
          i = -1;
          while (i++ < 100) {
            model.tick();
          }
          elapsed = Date.now() - start;
          done(100/elapsed*1000);
        }
      },
      {
        name: "fps",
        numeric: true,
        formatter: d3.format("5.1f"),
        run: function(done) {
          // warmup
          model.start();
          setTimeout(function() {
            model.stop();
            var start = model.get('time');
            setTimeout(function() {
              // actual fps calculation
              model.start();
              setTimeout(function() {
                model.stop();
                var elapsedModelTime = model.get('time') - start;
                done( elapsedModelTime / (model.get('viewRefreshInterval') * model.get('timeStep')) / 2 );
              }, 2000);
            }, 100);
          }, 1000);
        }
      },
      {
        name: "interactive",
        numeric: false,
        run: function(done) {
          done(window.location.pathname + window.location.hash);
        }
      }
    ];

    return benchmarks;

  }

});

/*global
  define
*/
/*jslint onevar: true*/
define('pta/controllers/controller',['require','common/controllers/model-controller','pta/models/modeler','pta/views/view','pta/controllers/scripting-api','pta/benchmarks/benchmarks'],function (require) {
  // Dependencies.
  var ModelController   = require("common/controllers/model-controller"),
      Model             = require('pta/models/modeler'),
      ModelContainer    = require('pta/views/view'),
      ScriptingAPI      = require('pta/controllers/scripting-api'),
      Benchmarks        = require('pta/benchmarks/benchmarks');

  return function (modelViewId, modelUrl, modelConfig, interactiveViewConfig, interactiveModelConfig) {
    return new ModelController(modelViewId, modelUrl, modelConfig, interactiveViewConfig, interactiveModelConfig,
                                     Model, ModelContainer, ScriptingAPI, Benchmarks);
  }
});

/*global define model $ */

define('common/controllers/interactives-controller',['require','lab.config','arrays','common/alert','common/controllers/interactive-metadata','common/validator','common/controllers/bar-graph-controller','common/controllers/graph-controller','common/controllers/export-controller','common/controllers/scripting-api','common/controllers/button-controller','common/controllers/checkbox-controller','common/controllers/radio-controller','common/controllers/slider-controller','common/controllers/pulldown-controller','common/controllers/numeric-output-controller','common/controllers/parent-message-api','common/controllers/thermometer-controller','common/layout/semantic-layout','common/layout/templates','md2d/controllers/controller','pta/controllers/controller'],function (require) {
  // Dependencies.
  var labConfig               = require('lab.config'),
      arrays                  = require('arrays'),
      alert                   = require('common/alert'),
      metadata                = require('common/controllers/interactive-metadata'),
      validator               = require('common/validator'),
      BarGraphController      = require('common/controllers/bar-graph-controller'),
      GraphController         = require('common/controllers/graph-controller'),
      ExportController        = require('common/controllers/export-controller'),
      ScriptingAPI            = require('common/controllers/scripting-api'),
      ButtonController        = require('common/controllers/button-controller'),
      CheckboxController      = require('common/controllers/checkbox-controller'),
      RadioController         = require('common/controllers/radio-controller'),
      SliderController        = require('common/controllers/slider-controller'),
      PulldownController      = require('common/controllers/pulldown-controller'),
      NumericOutputController = require('common/controllers/numeric-output-controller'),
      ParentMessageAPI        = require('common/controllers/parent-message-api'),
      ThermometerController   = require('common/controllers/thermometer-controller'),

      SemanticLayout          = require('common/layout/semantic-layout'),
      templates               = require('common/layout/templates'),

      MD2DModelController     = require('md2d/controllers/controller'),
      PTAModelController      = require('pta/controllers/controller'),

      // Set of available components.
      // - Key defines 'type', which is used in the interactive JSON.
      // - Value is a constructor function of the given component.
      // Each constructor should assume that it will be called with
      // following arguments:
      // 1. component definition (unmodified object from the interactive JSON),
      // 2. scripting API object,
      // 3. public API of the InteractiveController.
      // Of course, some of them can be passed unnecessarily, but
      // the InteractiveController follows this convention.
      //
      // The instantiated component should provide following interface:
      // # serialize()           - function returning a JSON object, which represents current state
      //                           of the component. When component doesn't change its state,
      //                           it should just return a copy (!) of the initial component definition.
      // # getViewContainer()    - function returning a jQuery object containing
      //                           DOM elements of the component.
      // # modelLoadedCallback() - optional function taking no arguments, a callback
      //                           which should be called when the model is loaded.
      ComponentConstructor = {
        'button':        ButtonController,
        'checkbox':      CheckboxController,
        'pulldown':      PulldownController,
        'radio':         RadioController,
        'thermometer':   ThermometerController,
        'barGraph':      BarGraphController,
        'graph':         GraphController,
        'slider':        SliderController,
        'numericOutput': NumericOutputController
      };

  return function interactivesController(interactive, viewSelector, modelLoadedCallbacks, layoutStyle, resizeCallbacks) {

    modelLoadedCallbacks = modelLoadedCallbacks || [];

    var controller = {},
        modelController,
        $interactiveContainer,
        models = [],
        modelsHash = {},
        propertiesListeners = [],
        componentCallbacks = [],
        onLoadScripts = [],

        // Hash of instantiated components.
        // Key   - component ID.
        // Value - array of component instances.
        componentByID = {},

        // Simple list of instantiated components.
        componentList = [],

        // List of custom parameters which are used by the interactive.
        customParametersByName = [],

        // API for scripts defined in the interactive JSON file.
        scriptingAPI,

        // additional model-specific scripting api
        modelScriptingAPI,

        // Handles exporting data to DataGames, if 'exports' are specified.
        exportController,

        // Doesn't currently have any public methods, but probably will.
        parentMessageAPI,

        semanticLayout;


    function getModel(modelId) {
      if (modelsHash[modelId]) {
        return modelsHash[modelId];
      }
      throw new Error("No model found with id "+modelId);
    }

    /**
      Load the model from the model definitions hash.
      'modelLoaded' is called after the model loads.

      @param: modelId.
      @optionalParam modelObject
    */
    function loadModel(modelId, modelConfig) {
      var modelDefinition = getModel(modelId),
          interactiveViewOptions,
          interactiveModelOptions;

      controller.currentModel = modelDefinition;

      if (modelDefinition.viewOptions) {
        // Make a deep copy of modelDefinition.viewOptions, so we can freely mutate interactiveViewOptions
        // without the results being serialized or displayed in the interactives editor.
        interactiveViewOptions = $.extend(true, {}, modelDefinition.viewOptions);
      } else {
        interactiveViewOptions = { controlButtons: 'play' };
      }
      interactiveViewOptions.fitToParent = !layoutStyle;

      onLoadScripts = [];
      if (modelDefinition.onLoad) {
        onLoadScripts.push( scriptingAPI.makeFunctionInScriptContext( getStringFromArray(modelDefinition.onLoad) ) );
      }

      if (modelDefinition.modelOptions) {
        // Make a deep copy of modelDefinition.modelOptions.
        interactiveModelOptions = $.extend(true, {}, modelDefinition.modelOptions);
      }

      if (modelConfig) {
        finishWithLoadedModel(modelDefinition.url, modelConfig);
      } else {
        $.get(labConfig.actualRoot + modelDefinition.url).done(function(modelConfig) {

          // Deal with the servers that return the json as text/plain
          modelConfig = typeof modelConfig === 'string' ? JSON.parse(modelConfig) : modelConfig;

          finishWithLoadedModel(modelDefinition.url, modelConfig);
        });
      }

      function finishWithLoadedModel(modelUrl, modelConfig) {
        if (modelController) {
          modelController.reload(modelUrl, modelConfig, interactiveViewOptions, interactiveModelOptions);
        } else {
          // Create container for model.
          // TODO: cleanup it, probably there is a better place to create this div.
          $interactiveContainer.append('<div id="model-container" class="container">');
          createModelController(modelConfig.type, modelUrl, modelConfig);
          modelLoaded(modelConfig);
          // also be sure to get notified when the underlying model changes
          modelController.on('modelReset', modelLoaded);
          controller.modelController = modelController;
        }
      }

      function createModelController(type, modelUrl, modelConfig) {
        // set default model type to "md2d"
        var modelType = type || "md2d";
        switch(modelType) {
          case "md2d":
          modelController = new MD2DModelController('#model-container', modelUrl, modelConfig, interactiveViewOptions, interactiveModelOptions);
          break;
          case "pta":
          modelController = new PTAModelController('#model-container', modelUrl, modelConfig, interactiveViewOptions, interactiveModelOptions);
          break;
        }
        // Extending universal Interactive scriptingAPI with model-specific scripting API
        if (modelController.ScriptingAPI) {
          scriptingAPI.extend(modelController.ScriptingAPI);
          scriptingAPI.exposeScriptingAPI();
        }
      }
    }

    function createComponent(component) {
          // Get type and ID of the requested component from JSON definition.
      var type = component.type,
          id = component.id,
          comp;

      // Use an appropriate constructor function and create a new instance of the given type.
      // Note that we use constant set of parameters for every type:
      // 1. component definition (exact object from interactive JSON),
      // 2. scripting API object,
      // 3. public API of the InteractiveController.
      comp = new ComponentConstructor[type](component, scriptingAPI, controller);

      // Save the new instance.
      componentByID[id] = comp;
      componentList.push(comp);

      // Register component callback if it is available.
      if (comp.modelLoadedCallback) {
        componentCallbacks.push(comp.modelLoadedCallback);
      }
    }

    /**
      Generic function that accepts either a string or an array of strings,
      and returns the complete string
    */
    function getStringFromArray(str) {
      if (typeof str === 'string') {
        return str;
      }
      return str.join('\n');
    }

    /**
      Call this after the model loads, to process any queued resize and update events
      that depend on the model's properties, then draw the screen.
    */
    function modelLoaded() {
      var i, listener, template, layout;

      setupCustomParameters(controller.currentModel.parameters, interactive.parameters);
      setupCustomOutputs("basic", controller.currentModel.outputs, interactive.outputs);
      // Setup filtered outputs after basic outputs and parameters, as filtered output require its input
      // to exist during its definition.
      setupCustomOutputs("filtered", controller.currentModel.filteredOutputs, interactive.filteredOutputs);

      for(i = 0; i < componentCallbacks.length; i++) {
        componentCallbacks[i]();
      }

      if (interactive.template) {
        if (typeof interactive.template === "string") {
          template = templates[interactive.template];
        } else {
          template = interactive.template;
        }
      }

      // the authored definition of which components go in which container
      layout = interactive.layout;

      // TODO: this should be moved out of modelLoaded (?)
      $interactiveContainer.children().not("#model-container").each(function () {
        $(this).detach();
      });
      semanticLayout = new SemanticLayout($interactiveContainer, template, layout, componentByID, modelController);

      semanticLayout.layoutInteractive();
      $(window).unbind('resize');
      $(window).on('resize', function() {
        semanticLayout.layoutInteractive();
        // Call application controller (application.js) resizeCallbacks if there are any.
        // Currently this is used for the Share pane generated <iframe> content.
        // TODO: make a model dialog component and treat the links at the top as
        // componments in the layout. New designs may put these links at the bottom ... etc
        for(i = 0; i < resizeCallbacks.length; i++) {
          if (resizeCallbacks[i].resize !== undefined) {
            resizeCallbacks[i].resize();
          }
        }
      });

      // setup messaging with embedding parent window
      parentMessageAPI = new ParentMessageAPI(model, modelController.modelContainer, controller);

      for(i = 0; i < propertiesListeners.length; i++) {
        listener = propertiesListeners[i];
        model.addPropertiesListener(listener[0], listener[1]);
      }

      for(i = 0; i < onLoadScripts.length; i++) {
        onLoadScripts[i]();
      }

      for(i = 0; i < modelLoadedCallbacks.length; i++) {
        modelLoadedCallbacks[i]();
      }
    }

    /**
      Validates interactive definition.

      Displays meaningful info in case of any errors. Also an exception is being thrown.

      @param interactive
        hash representing the interactive specification
    */
    function validateInteractive(interactive) {
      var i, len, models, parameters, outputs, filteredOutputs, components, errMsg;

      // Validate top level interactive properties.
      try {
        interactive = validator.validateCompleteness(metadata.interactive, interactive);
      } catch (e) {
        errMsg = "Incorrect interactive definition:\n" + e.message;
        alert(errMsg);
        throw new Error(errMsg);
      }

      // Set up the list of possible models.
      models = interactive.models;
      try {
        for (i = 0, len = models.length; i < len; i++) {
          models[i] = validator.validateCompleteness(metadata.model, models[i]);
          modelsHash[models[i].id] = models[i];
        }
      } catch (e) {
        errMsg = "Incorrect model definition:\n" + e.message;
        alert(errMsg);
        throw new Error(errMsg);
      }

      parameters = interactive.parameters;
      try {
        for (i = 0, len = parameters.length; i < len; i++) {
          parameters[i] = validator.validateCompleteness(metadata.parameter, parameters[i]);
        }
      } catch (e) {
        errMsg = "Incorrect parameter definition:\n" + e.message;
        alert(errMsg);
        throw new Error(errMsg);
      }

      outputs = interactive.outputs;
      try {
        for (i = 0, len = outputs.length; i < len; i++) {
          outputs[i] = validator.validateCompleteness(metadata.output, outputs[i]);
        }
      } catch (e) {
        errMsg = "Incorrect output definition:\n" + e.message;
        alert(errMsg);
        throw new Error(errMsg);
      }

      filteredOutputs = interactive.filteredOutputs;
      try {
        for (i = 0, len = filteredOutputs.length; i < len; i++) {
          filteredOutputs[i] = validator.validateCompleteness(metadata.filteredOutput, filteredOutputs[i]);
        }
      } catch (e) {
        errMsg = "Incorrect filtered output definition:\n" + e.message;
        alert(errMsg);
        throw new Error(errMsg);
      }

      components = interactive.components;
      try {
        for (i = 0, len = components.length; i < len; i++) {
          components[i] = validator.validateCompleteness(metadata[components[i].type], components[i]);
        }
      } catch (e) {
        errMsg = "Incorrect " + components[i].type + " component definition:\n" + e.message;
        alert(errMsg);
        throw new Error(errMsg);
      }

      // Validate exporter, if any...
      if (interactive.exports) {
        try {
          interactive.exports = validator.validateCompleteness(metadata.exports, interactive.exports);
        } catch (e) {
          errMsg = "Incorrect exports definition:\n" + e.message;
          alert(errMsg);
          throw new Error(errMsg);
        }
      }

      return interactive;
    }

    /**
      The main method called when this controller is created.

      Populates the element pointed to by viewSelector with divs to contain the
      molecule container (view) and the various components specified in the interactive
      definition, and

      @param newInteractive
        hash representing the interactive specification
      @param viewSelector
        jQuery selector that finds the element to put the interactive view into
    */
    function loadInteractive(newInteractive, viewSelector) {
      var componentJsons,
          $exportButton,
          i, len;

      componentCallbacks = [];

      // Validate interactive.
      interactive = validateInteractive(newInteractive);

      if (viewSelector) {
        $interactiveContainer = $(viewSelector);
      }

      // Set up the list of possible models.
      models = interactive.models;
      for (i = 0, len = models.length; i < len; i++) {
        modelsHash[models[i].id] = models[i];
      }

      // Load first model.
      loadModel(models[0].id);

      // Prepare interactive components.
      componentJsons = interactive.components || [];

      // Clear component instances.
      componentList = [];
      componentByID = {};

      for (i = 0, len = componentJsons.length; i < len; i++) {
        createComponent(componentJsons[i]);
      }

      // Setup exporter, if any...
      if (interactive.exports) {
        // Regardless of whether or not we are able to export data to an enclosing container,
        // setup export controller so you can debug exports by typing script.exportData() in the
        // console.
        exportController = new ExportController(interactive.exports);
        componentCallbacks.push(exportController.modelLoadedCallback);

        // If there is an enclosing container we can export data to (e.g., we're iframed into
        // DataGames) then add an "Analyze Data" button the bottom position of the interactive
        if (ExportController.isExportAvailable()) {
          createComponent({
            "type": "button",
            "text": "Analyze Data",
            "id": "-lab-analyze-data",
            "action": "exportData();"
          });
        }
      }
    }

    /**
      After a model loads, this method sets up the custom output properties specified in the "model"
      section of the interactive and in the interactive.

      Any output property definitions in the model section of the interactive specification override
      properties with the same that are specified in the main body if the interactive specification.

      @outputType - accept two values "basic" and "filtered", as this function can be used for processing
        both types of outputs.
    */
    function setupCustomOutputs(outputType, modelOutputs, interactiveOutputs) {
      if (!modelOutputs && !interactiveOutputs) return;

      var outputs = {},
          prop,
          output;

      function processOutputsArray(outputsArray) {
        if (!outputsArray) return;
        for (var i = 0; i < outputsArray.length; i++) {
          outputs[outputsArray[i].name] = outputsArray[i];
        }
      }

      // per-model output definitions override output definitions from interactives
      processOutputsArray(interactiveOutputs);
      processOutputsArray(modelOutputs);

      for (prop in outputs) {
        if (outputs.hasOwnProperty(prop)) {
          output = outputs[prop];
          // DOM elements (and, by analogy, Next Gen MW interactive components like slides)
          // have "ids". But, in English, properties have "names", but not "ids".
          switch (outputType) {
            case "basic":
              model.defineOutput(output.name, {
                label: output.label,
                units: output.units
              }, scriptingAPI.makeFunctionInScriptContext(getStringFromArray(output.value)));
              break;
            case "filtered":
              model.defineFilteredOutput(output.name, {
                label: output.label,
                units: output.units
              }, output.property, output.type, output.period);
              break;
          }
        }
      }
    }

    /**
      After a model loads, this method is used to set up the custom parameters specified in the
      model section of the interactive, or in the toplevel of the interactive
    */
    function setupCustomParameters(modelParameters, interactiveParameters) {
      if (!modelParameters && !interactiveParameters) return;

      var initialValues = {},
          customParameters,
          i, parameter;

      // append modelParameters second so they're processed later (and override entries of the
      // same name in interactiveParameters)
      customParameters = (interactiveParameters || []).concat(modelParameters || []);

      for (i = 0; i < customParameters.length; i++) {
        parameter = customParameters[i];
        model.defineParameter(parameter.name, {
          label: parameter.label,
          units: parameter.units
        }, scriptingAPI.makeFunctionInScriptContext('value', getStringFromArray(parameter.onChange)));

        if (parameter.initialValue !== undefined) {
          initialValues[parameter.name] = parameter.initialValue;
        }
        // Save reference to the definition which is finally used.
        // Note that if parameter is defined both in interactive top-level scope
        // and models section, one from model sections will be defined in this hash.
        // It's necessary to update correctly values of parameters during serialization.
        customParametersByName[parameter.name] = parameter;
      }

      model.set(initialValues);
    }

    //
    // Public API.
    //
    controller = {
      getDGExportController: function () {
        return exportController;
      },
      getModelController: function () {
        return modelController;
      },
      pushOnLoadScript: function (callback) {
        onLoadScripts.push(callback);
      },
      /**
        Serializes interactive, returns object ready to be stringified.
        e.g. JSON.stringify(interactiveController.serialize());
      */
      serialize: function () {
        var result, i, len, param, val;

        // This is the tricky part.
        // Basically, parameters can be defined in two places - in model definition object or just as a top-level
        // property of the interactive definition. 'customParameters' list contains references to all parameters
        // currently used by the interactive, no matter where they were specified. So, it's enough to process
        // and update only these parameters. Because of that, later we can easily serialize interactive definition
        // with updated values and avoid deciding whether this parameter is defined in 'models' section
        // or top-level 'parameters' section. It will be updated anyway.
        if (model !== undefined && model.get !== undefined) {
          for (param in customParametersByName) {
            if (customParametersByName.hasOwnProperty(param)) {
              param = customParametersByName[param];
              val = model.get(param.name);
              if (val !== undefined) {
                param.initialValue = val;
              }
            }
          }
        }

        // Copy basic properties from the initial definition, as they are immutable.
        result = {
          title: interactive.title,
          publicationStatus: interactive.publicationStatus,
          subtitle: interactive.subtitle,
          about: arrays.isArray(interactive.about) ? $.extend(true, [], interactive.about) : interactive.about,
          // Node that models section can also contain custom parameters definition. However, their initial values
          // should be already updated (take a look at the beginning of this function), so we can just serialize whole array.
          models: $.extend(true, [], interactive.models),
          // All used parameters are already updated, they contain currently used values.
          parameters: $.extend(true, [], interactive.parameters),
          // Outputs are directly bound to the model, we can copy their initial definitions.
          outputs: $.extend(true, [], interactive.outputs),
          filteredOutputs: $.extend(true, [], interactive.filteredOutputs)
        };

        // Serialize components.
        result.components = [];
        for (i = 0, len = componentList.length; i < len; i++) {
          if (componentList[i].serialize) {
            result.components.push(componentList[i].serialize());
          }
        }

        // Copy layout from the initial definition, as it is immutable.
        result.layout = $.extend(true, {}, interactive.layout);
        if (typeof interactive.template === "string") {
          result.template = interactive.template;
        } else {
          result.template = $.extend(true, {}, interactive.template);
        }

        return result;
      },
      // Make these private variables and functions available
      loadInteractive: loadInteractive,
      validateInteractive: validateInteractive,
      loadModel: loadModel
    };

    //
    // Initialization.
    //

    // Create scripting API.
    scriptingAPI = new ScriptingAPI(controller, modelScriptingAPI);
    // Expose API to global namespace (prototyping / testing using the browser console).
    scriptingAPI.exposeScriptingAPI();

    // Run this when controller is created.
    loadInteractive(interactive, viewSelector);

    return controller;
  };
});

/*globals define: false, d3: false */
/*jshint loopfunc: true*/

/*
  ------------------------------------------------------------

  Simple benchmark runner and results generator

    see: https://gist.github.com/1364172

  ------------------------------------------------------------

  Runs benchmarks and generates the results in a table.

  Setup benchmarks to run in an array of objects with two properties:

    name: a title for the table column of results
    numeric: boolean, used to decide what columns should be used to calculate averages
    formatter: (optional) a function that takes a number and returns a formmatted string, example: d3.format("5.1f")
    run: a function that is called to run the benchmark and call back with a value.
         It should accept a single argument, the callback to be called when the
         benchmark completes. It should pass the benchmark value to the callback.

  Start the benchmarks by passing the table element where the results are to
  be placed and an array of benchmarks to run.

  Example:

    var benchmarks_table = document.getElementById("benchmarks-table");

    var benchmarks_to_run = [
      {
        name: "molecules",
        run: function(done) {
          done(mol_number);
        }
      },
      {
        name: "100 Steps (steps/s)",
        run: function(done) {
          modelStop();
          var start = +Date.now();
          var i = -1;
          while (i++ < 100) {
            model.tick();
          }
          elapsed = Date.now() - start;
          done(d3.format("5.1f")(100/elapsed*1000));
        }
      },
    ];

    benchmark.run(benchmarks_table, benchmarks_to_run)

  You can optionally pass two additional arguments to the run method: start_callback, end_callback

    function run(benchmarks_table, benchmarks_to_run, start_callback, end_callback)

  These arguments are used when the last benchmark test is run using the browsers scheduling and re-painting mechanisms.

  For example this test runs a model un the browser and calculates actual frames per second combining the
  model, view, and browser scheduling and repaint operations.

    {
      name: "fps",
      numeric: true,
      formatter: d3.format("5.1f"),
      run: function(done) {
        // warmup
        model.start();
        setTimeout(function() {
          model.stop();
          var start = model.get('time');
          setTimeout(function() {
            // actual fps calculation
            model.start();
            setTimeout(function() {
              model.stop();
              var elapsedModelTime = model.get('time') - start;
              done( elapsedModelTime / (model.get('viewRefreshInterval') * model.get('timeStep')) / 2 );
            }, 2000);
          }, 100);
        }, 1000);
      }
    }

  Here's an example calling the benchmark.run method and passing in start_callback, end_callback functions:

    benchmark.run(document.getElementById("model-benchmark-results"), benchmarksToRun, function() {
      $runBenchmarksButton.attr('disabled', true);
    }, function() {
      $runBenchmarksButton.attr('disabled', false);
    });

  The "Run Benchmarks" button is disabled until the browser finishes running thelast queued test.

  The first five columns in the generated table consist of:

    browser, version, cpu/os, date, and commit

  These columns are followed by a column for each benchmark passed in.

  Subsequent calls to: benchmark.run(benchmarks_table, benchmarks_to_run) will
  add additional rows to the table.

  A special second row is created in the table which displays averages of all tests
  that generate numeric results.

  Here are some css styles for the table:

    table {
      font: 11px/24px Verdana, Arial, Helvetica, sans-serif;
      border-collapse: collapse; }
    th {
      padding: 0 1em;
      text-align: left; }
    td {
      border-top: 1px solid #cccccc;
      padding: 0 1em; }

*/

define('common/benchmark/benchmark',['require'],function (require) {

  var version = "0.0.1",
      windows_platform_token = {
        "Windows NT 6.2": "Windows 8",
        "Windows NT 6.1": "Windows 7",
        "Windows NT 6.0": "Windows Vista",
        "Windows NT 5.2": "Windows Server 2003; Windows XP x64 Edition",
        "Windows NT 5.1": "Windows XP",
        "Windows NT 5.01": "Windows 2000, Service Pack 1 (SP1)",
        "Windows NT 5.0": "Windows 2000",
        "Windows NT 4.0": "Microsoft Windows NT 4.0"
      },
      windows_feature_token = {
        "WOW64":       "64/32",
        "Win64; IA64": "64",
        "Win64; x64":  "64"
      };

  function what_browser() {
    var chromematch  = / (Chrome)\/(.*?) /,
        ffmatch      = / (Firefox)\/([0123456789ab.]+)/,
        safarimatch  = / AppleWebKit\/([0123456789.+]+) \(KHTML, like Gecko\) Version\/([0123456789.]+) (Safari)\/([0123456789.]+)/,
        iematch      = / (MSIE) ([0123456789.]+);/,
        operamatch   = /^(Opera)\/.+? Version\/([0123456789.]+)$/,
        iphonematch  = /.+?\((iPhone); CPU.+?OS .+?Version\/([0123456789._]+)/,
        ipadmatch    = /.+?\((iPad); CPU.+?OS .+?Version\/([0123456789._]+)/,
        ipodmatch    = /.+?\((iPod); CPU (iPhone.+?) like.+?Version\/([0123456789ab._]+)/,
        androidchromematch = /.+?(Android) ([0123456789.]+).*?; (.+?)\).+? Chrome\/([0123456789.]+)/,
        androidfirefoxmatch = /.+?(Android.+?\)).+? Firefox\/([0123456789.]+)/,
        androidmatch = /.+?(Android) ([0123456789ab.]+).*?; (.+?)\)/,
        match;

    match = navigator.userAgent.match(chromematch);
    if (match && match[1]) {
      return {
        browser: match[1],
        version: match[2],
        oscpu: os_platform()
      };
    }
    match = navigator.userAgent.match(ffmatch);
    if (match && match[1]) {
      var buildID = navigator.buildID,
          buildDate = "";
      if (buildID && buildID.length >= 8) {
        buildDate = "(" + buildID.slice(0,4) + "-" + buildID.slice(4,6) + "-" + buildID.slice(6,8) + ")";
      }
      return {
        browser: match[1],
        version: match[2] + ' ' + buildDate,
        oscpu: os_platform()
      };
    }
    match = navigator.userAgent.match(androidchromematch);
    if (match && match[1]) {
      return {
        browser: "Chrome",
        version: match[4],
        oscpu: match[1] + "/" + match[2] + "/" + match[3]
      };
    }
    match = navigator.userAgent.match(androidfirefoxmatch);
    if (match && match[1]) {
      return {
        browser: "Firefox",
        version: match[2],
        oscpu: match[1]
      };
    }
    match = navigator.userAgent.match(androidmatch);
    if (match && match[1]) {
      return {
        browser: "Android",
        version: match[2],
        oscpu: match[1] + "/" + match[2] + "/" + match[3]
      };
    }
    match = navigator.userAgent.match(safarimatch);
    if (match && match[3]) {
      return {
        browser: match[3],
        version: match[2] + '/' + match[1],
        oscpu: os_platform()
      };
    }
    match = navigator.userAgent.match(iematch);
    if (match && match[1]) {
      var platform_match = navigator.userAgent.match(/\(.*?(Windows.+?); (.+?)[;)].*/);
      return {
        browser: match[1],
        version: match[2],
        oscpu: windows_platform_token[platform_match[1]] + "/" + navigator.cpuClass + "/" + navigator.platform
      };
    }
    match = navigator.userAgent.match(operamatch);
    if (match && match[1]) {
      return {
        browser: match[1],
        version: match[2],
        oscpu: os_platform()
      };
    }
    match = navigator.userAgent.match(iphonematch);
    if (match && match[1]) {
      return {
        browser: "Mobile Safari",
        version: match[2],
        oscpu: match[1] + "/" + "iOS" + "/" + match[2]
      };
    }
    match = navigator.userAgent.match(ipadmatch);
    if (match && match[1]) {
      return {
        browser: "Mobile Safari",
        version: match[2],
        oscpu: match[1] + "/" + "iOS" + "/" + match[2]
      };
    }
    match = navigator.userAgent.match(ipodmatch);
    if (match && match[1]) {
      return {
        browser: "Mobile Safari",
        version: match[3],
        oscpu: match[1] + "/" + "iOS" + "/" + match[2]
      };
    }
    return {
      browser: "",
      version: navigator.appVersion,
      oscpu:   ""
    };
  }

  function os_platform() {
    var match = navigator.userAgent.match(/\((.+?)[;)] (.+?)[;)].*/);
    if (!match) { return "na"; }
    if (match[1] === "Macintosh") {
      return match[2];
    } else if (match[1].match(/^Windows/)) {
      var arch  = windows_feature_token[match[2]] || "32",
          token = navigator.userAgent.match(/\(.*?(Windows NT.+?)[;)]/);
      return windows_platform_token[token[1]] + "/" + arch;
    }
  }

  function renderToTable(benchmarks_table, benchmarksThatWereRun, results) {
    var i = 0,
        browser_info,
        averaged_row,
        results_row,
        result,
        formatter,
        col_number = 0,
        col_numbers = {},
        title_row,
        title_cells,
        len,
        rows = benchmarks_table.getElementsByTagName("tr");

    benchmarks_table.style.display = "";

    function add_column(title) {
      var title_row = benchmarks_table.getElementsByTagName("tr")[0],
          cell = title_row.appendChild(document.createElement("th"));

      cell.innerHTML = title;
      col_numbers[title] = col_number++;
    }

    function add_row(num_cols) {
      num_cols = num_cols || 0;
      var tr =  benchmarks_table.appendChild(document.createElement("tr")),
          i;

      for (i = 0; i < num_cols; i++) {
        tr.appendChild(document.createElement("td"));
      }
      return tr;
    }

    function add_result(name, content, row) {
      var cell;
      row = row || results_row;
      cell = row.getElementsByTagName("td")[col_numbers[name]];
      if (typeof content === "string" && content.slice(0,1) === "<") {
        cell.innerHTML = content;
      } else {
        cell.textContent = content;
      }
    }

    function update_averages() {
      var i, j,
          b,
          row,
          num_rows = rows.length,
          cell,
          cell_index,
          average_elements = average_row.getElementsByTagName("td"),
          total,
          average,
          samples,
          genericDecimalFormatter = d3.format("5.1f"),
          genericIntegerFormatter = d3.format("f");

      function isInteger(i) {
        return Math.floor(i) == i;
      }

      for (i = 0; i < benchmarksThatWereRun.length; i++) {
        b = benchmarksThatWereRun[i];
        cell_index = col_numbers[b.name];
        if (b.numeric === false) {
          row = rows[2];
          cell = row.getElementsByTagName("td")[cell_index];
          average_elements[cell_index].innerHTML = cell.innerHTML;
        } else {
          total = 0;
          for (j = 2; j < num_rows; j++) {
            row = rows[j];
            cell = row.getElementsByTagName("td")[cell_index];
            total += (+cell.textContent);
          }
          average = total/(num_rows-2);
          if (b.formatter) {
            average = b.formatter(average);
          } else {
            if (isInteger(average)) {
              average = genericIntegerFormatter(total/(num_rows-2));
            } else {
              average = genericDecimalFormatter(total/(num_rows-2));
            }
          }
          average_elements[cell_index].textContent = average;
        }
      }
    }

    if (rows.length === 0) {
      add_row();
      add_column("browser");
      add_column("version");
      add_column("cpu/os");
      add_column("date");
      for (i = 0; i < benchmarksThatWereRun.length; i++) {
        add_column(benchmarksThatWereRun[i].name);
      }
      average_row = add_row(col_number);
      average_row.className = 'average';
    } else {
      title_row = rows[0];
      title_cells = title_row.getElementsByTagName("th");
      for (i = 0, len = title_cells.length; i < len; i++) {
        col_numbers[title_cells[i].innerHTML] = col_number++;
      }
    }

    results_row = add_row(col_number);
    results_row.className = 'sample';

    for (i = 0; i < 4; i++) {
      result = results[i];
      add_result(result[0], result[1]);
      add_result(result[0], result[1], average_row);
    }

    for(i = 4; i < results.length; i++) {
      result = results[i];
      add_result(result[0], result[1]);
    }
    update_averages();
  }

  function bench(benchmarks_to_run, resultsCallback, start_callback, end_callback) {
    var i,
        benchmarks_completed,
        results = [],
        browser_info = what_browser(),
        formatter = d3.time.format("%Y-%m-%d %H:%M");

    results.push([ "browser", browser_info.browser]);
    results.push([ "version", browser_info.version]);
    results.push([ "cpu/os", browser_info.oscpu]);
    results.push([ "date", formatter(new Date())]);

    benchmarks_completed = 0;
    if (start_callback) start_callback();
    for (i = 0; i < benchmarks_to_run.length; i++) {
      (function(b) {
        b.run(function(result) {
          if (b.formatter) {
            results.push([ b.name, b.formatter(result) ]);
          } else {
            results.push([ b.name, result ]);
          }
         if (++benchmarks_completed === benchmarks_to_run.length) {
           if (end_callback) {
             end_callback();
           }
           if (resultsCallback) {
             resultsCallback(results);
           }
         }
        });
      }(benchmarks_to_run[i]));
      if (end_callback === undefined) {
      }
    }
    return results;
  }

  function run(benchmarks_to_run, benchmarks_table, resultsCallback, start_callback, end_callback) {
    var results;
    bench(benchmarks_to_run, function(results) {
      renderToTable(benchmarks_table, benchmarks_to_run, results);
      resultsCallback(results);
    }, start_callback, end_callback);
    return results;
  }

  // Return Public API.
  return {
    version: version,
    what_browser: function() {
      return what_browser();
    },
    // run benchmarks, add row to table, update averages row
    run: function(benchmarks_to_run, benchmarks_table, resultsCallback, start_callback, end_callback) {
      run(benchmarks_to_run, benchmarks_table, resultsCallback, start_callback, end_callback);
    },
    // run benchmarks, return results in object
    bench: function(benchmarks_to_run, resultsCallback, start_callback, end_callback) {
      return bench(benchmarks_to_run, resultsCallback, start_callback, end_callback);
    },
    // run benchmarks, add row to table, update averages row
    renderToTable: function(benchmarks_table, benchmarksThatWereRun, results) {
      renderToTable(benchmarks_table, benchmarksThatWereRun, results);
    }
  };
});

/*global define: false, window: false */

// TODO: just temporary solution, refactor it.
define('pta/public-api',['require','common/controllers/interactives-controller','common/layout/layout','common/benchmark/benchmark'],function (require) {
  var interactivesController  = require('common/controllers/interactives-controller'),
      layout                  = require('common/layout/layout'),
      benchmark               = require('common/benchmark/benchmark'),
      // Object to be returned.
      publicAPI;

  publicAPI = {
    version: "0.0.1",
    // ==========================================================================
    // Add functions and modules which should belong to this API:
    interactivesController: interactivesController
    // ==========================================================================
  };
  // Export this API under 'controllers' name.
  window.controllers = publicAPI;
  // Also export layout and benchmark.
  window.layout = layout;

  // Return public API as a module.
  return publicAPI;
});
require(['pta/public-api'], undefined, undefined, true); }());