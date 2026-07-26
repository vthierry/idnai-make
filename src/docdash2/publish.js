// Generates an improved version of documentation output using jsdoc and the docdash template

const fs = require("fs");
const docdash = require(__dirname + "/../docdash/publish.js");

// Implements all pages improvement
const improvePage = function(file, text) {
  // Detects class that is a factory as having lower-case 1st letter name, and rename the menu
  {
    text = text.replace(new RegExp("new ([a-z][a-zA-Z0-9]+)<span[^>]*>\\(\\)</span>"), "factory $1");
    text = text.replace(new RegExp(">new ([a-z][a-zA-Z0-9]+)<"), ">$1<");
    // Rename classes as objects in the nav menu
    text = text.replace("<h3>Classes</h3>", "<h3>Objects</h3>");
  }
  // Manages inner classes navigation in menu
  {
    let name = file.replace(new RegExp(".*/([A-Za-z]*)-?[A-Za-z]*.html"), "$1");
    let i0 = text.indexOf("<nav"),
      i1 = text.indexOf("</nav>");
    if (0 <= i0 && 0 <= i1) {
      let nav = text.substring(i0, i1 + 6);
      // Manages menu inner class and section presentation 
      nav = nav.replace(new RegExp("(<li)(><a href=\"[a-zA-Z][a-z]*-)", "g"), "$1 style=\"display:none\"$2");
      nav = nav.replace(new RegExp("(<li) style=\"display:none\"(><a href=\"" + name + "-)", "g"), "$1 style=\"padding-left:20px;border-left:1px solid lightgray;margin-top:-10px\" $2");
      text = text.substring(0, i0) + nav + text.substring(i1 + 6);
      // Manages inner classes that are sections
      {
        let i0 = text.indexOf("<h3 class=\"subsection-title\">Classes</h3>"),
          i1 = text.indexOf("<h3 class=\"subsection-title\">", i0 + 1);
        if (0 <= i0 && 0 <= i1) {
          if (-1 == text.substring(i0, i1).search(new RegExp("<dt[^>]*>[^<]*<a[^>]*>[A-Z]")))
            text = text.replace("<h3 class=\"subsection-title\">Classes</h3>", "<h3 class=\"subsection-title\">Sections</h3>");
        }
      }
    }
  }
  // Improves indexing of globals
  {
    text = text.replace(new RegExp("<a href=\"global.html\">([^<]*)</a>", "g"), "<a href=\"global.html#$1\">$1</a>");
  }
  // Highlights inner classes in page
  {
    text = text.replace(new RegExp("(<dt)(><a)( href=\"[a-zA-Z][a-z]*-)", "g"), "$1 style=\"background: #6d426d; box-shadow: 0 .25em .5em #d3d3d3; border-top: 1px solid #d3d3d3; border-bottom: 1px solid #d3d3d3; margin: 1.5em 0 0.5em; padding: .75em 0 .75em 10px;\"$2 style=\"color: #eee; font-size: larger; font-weight: bold;\"$3");
  }
  // Cleans the documentation from spurious static field used to circuvent a bug regarding instance member
  // - cleans the menu entry of the spurious static '_' field
  text = text.replace(new RegExp("<li\\s+data-type='member' [^>]*><a[^>]*>_</a></li>", "g"), "");
  // - cleans the page entry of the spurious static '_' field
  text = text.replace(new RegExp("<h4 class=\"name\" id=\"._\"><span[^>]*>[^<]*</span>_<span[^>]*></span></h4>\\s*<dl[^>]*>\\s*</dl>", "g"), "");
  // - cleans the members section if empty
  text = text.replace(new RegExp("<h3 class=\"subsection-title\">Members</h3>\\s*(<h3 class=\"subsection-title\">Methods</h3>)", "g"), "$1");  
  // Cleans the documentation trailer
  {
    // Returns the present data in a YYY-MM-DD format
    const nowDate = function() {
      const int2str = function(value, length) {
	for(value = "" + value; value.length < length; value = "0" + value);
	return value;
      }
      let d = new Date();
      return [int2str(d.getFullYear(), 4), int2str(d.getMonth() + 1, 2), int2str(d.getDate(), 2)].join('-');
    }
    text = text.replace(new RegExp("Documentation generated.*theme\."), 
			"<div style='float: right;font-style: italic;'>" + nowDate() + " version.</div>");
  }
  //
  return text;
}

// Implements docdash static file modification, without modifying the modification time
const improveDocdash = function(destination) {
  // Avoids the kwd color of keywords
  {
    let prettify = destination + "/scripts/prettify/prettify.js";
    if (fs.existsSync(prettify)) {
      let mtime = fs.statSync(prettify).mtimeMs;
      fs.writeFileSync(prettify, ("" + fs.readFileSync(prettify)).replace("\"kwd\"", "\"pln\""));
      fs.utimesSync(prettify, mtime, mtime);
    }
  }
}

exports.publish = function(data, opts, tutorials) {
  // Publishs the documentation using docdash template
  docdash.publish(data, opts, tutorials);
  // Gets the user parameters
  const configuragion = "" + fs.readFileSync(opts["configure"]);
  const destination = opts["destination"];
  // Edits all documentation pages to improve the text
  {
    let files = fs.readdirSync(destination);
    for (let i in files) {
      if (files[i].match("^.*\\.html$")) {
        let file = destination + "/" + files[i];
        fs.writeFileSync(file, improvePage(file, "" + fs.readFileSync(file)));
      }
    }
  }
  // Runs this after docdash asynchroneous functions ends
  {
    const putative_delay = 10;
    setTimeout(function() {
      improveDocdash(destination)
    }, putative_delay);
  }
};
