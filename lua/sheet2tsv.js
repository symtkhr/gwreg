const getfile = (fname, cb) => {
    const fs = require('fs');
    return fs.readFileSync(fname, 'utf8');
};
const { execSync } = require('child_process');

const help = (argv) => {
   
    console.log(argv[1] + " [Filepath] [options]");
    console.log("   convert glyphwikiupdate.csv to TSV");
    console.log(" -u: include undefined glyph");
    console.log(" -q: include #- ");
    console.log(" -h: include #ho ");
    console.log(" -r: include #ref ");

}

let argv = process.argv.slice(2);
if (!argv.length) return help(process.argv);


let regs = {}
let table = getfile(argv.find(v => v[0] != "-") || "p.gwupdate.dat").split('"')
    .map((v,i) => (i % 2) ? v.split("\r").join("$").split("\n").join("$") : v).join("")
    .split("\r\n").map(v => v.split(","))
    .map(cols => {
        let dkw = (cols[1] || "").split("[").shift();
        if (dkw) regs[dkw] = cols;
    });

let dump = Object.keys(regs).sort().filter(key => {
    let no, name, c, glyph, cat, act, state;
    [no, name, c, glyph, cat, act, state] = regs[key];
    if (argv.indexOf("-u") < 0 && glyph == "_") return;
    if (argv.indexOf("-q") < 0 && cat.indexOf("#-") == 0) return;
    if (argv.indexOf("-h") < 0 && cat.indexOf("#ho") == 0) return;
    if (argv.indexOf("-r") < 0 && cat.indexOf("#ref") == 0) return;
    if (argv.indexOf("-o") < 0 && state != "_") return;

    console.log([name + c, glyph, cat, act].join("\t"));
    return true;
});
console.log(dump.length, table.length);
