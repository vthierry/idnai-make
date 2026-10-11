// Implements the jsdoc2 plugin allowing to parse extra doc.

const fs = require("fs");
const path = require("path");

exports.handlers = {
  beforeParse: function(e) {
    //- console.log("documenting " + path.basename(e.filename));
    // Gets the file directory
    let dirname = path.dirname(e.filename);
    if (jsdoc2_done[dirname] == undefined) {
      // Considers all .hpp and .sh files and extracts the /** ../.. */ sections
      {
	let text = "";
        // Gets all source files
        let files = fs.readdirSync(dirname);
        // Considers all .h, .hpp, .js files
        for (let i in files)
          if (files[i].match("^.+\\.(hpp|h|sh)$")) {
            //- console.log("documenting " + files[i]);
            let input = "" + fs.readFileSync(files[i]);
            // Extracts the /** ../.. */ sections
            for (let i0 = 0, i1; i0 < input.length && (i0 = input.indexOf("/**", i0)) != -1; i0 = i1) {
              i1 = input.indexOf("*/", i0), i1 = i1 == -1 ? input.length : i1;
              text += input.substring(i0, i1 + 2) + "\n";
            }
          }
	// Cleans the start '#' char
	text = text.replace(new RegExp("\n#", "g"), "\n");
	// Appends to the documentation source
	e.source = text + e.source;
      }
      // Reduces @extends to enlighten the documentation
      e.source = e.source.replace(new RegExp("@extends\\s+([^\\s]+)", "g"), "#### Extends: <a href='./$1.html'>$1</a>, with all public methods available.")
      // Adds to each class a spurious static element of name '_' to circuvent a bug regarding instance member not appearing in menu otherwise, this is then clean on the output
      e.source = e.source.replace(new RegExp("@class\\s+([^\\s]+)(([^\\*]|\\*[^/])*)\\*/", "g"), "@class $1$2*/\n/**\n* @member _\n* @memberof $1\n* @static\n*/");
      // Expends the @frame tag
      e.source = e.source.replace(new RegExp("@frame\\s+([^\\s]+)", "g"), "<center><iframe style='width: 100%; height: calc(55vw);' src='$1'></iframe></center><a href='$1' target='_blank'>&nbsp;&nbsp;(open in new tab)</a><br/>\n\n");
      // Prevents from repeating for this directory
      jsdoc2_done[dirname] = true;
    }
  }
};

// Registers all directory already scanned
var jsdoc2_done = {};
