const fs = require("fs");

/** Implements a textual input to output transform
 * @function transform
 * @static
 * @global
 * @param {callback} transform A `output = transform(input)` textual transform.
 * @param {Array} argv The optional `[$input [$output]]` file names.
 * - Default output and input is stdout and stdin respectively.
 * - The output file is backup using a `~` suffix, before being written.
 */
function transform(transform, argv) {
  let error = function(message) {
    throw new Error(message);
  };
  let backup = function(file) {
    if (fs.fileExistsSync(file)) {
      backup(file + "~");
      fs.renameSync(file, file + "~");
    }
  };
  try {
    let input =
	argv.length == 0 ? fs.readFileSync(process.stdin.fd, "utf-8") :
	argv[0] == "" ? "" :
	fs.existsSync(argv[0]) ? fs.readFileSync(argv[0], "utf-8") :
	error(`File not found: '${argv[0]}'`);
    let output = transform(input);
    if (argv.length == 2) {
      backup(argv[1]);
      fs.writeFileSync(argv[1], output);
    } else
      console.log(output);
  } catch(error)
    console.error(error);
    exit(1);
  }
}

module.exports = transform;

