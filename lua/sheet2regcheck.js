const getfile = (fname) => (require('fs')).readFileSync(fname, 'utf8');
const { execSync } = require('child_process');

const help = (argv) => {
    console.log(argv[1] + " [Filepath] [options]");
    console.log("   check if the glyphs are registered in glyphwikiupdate.csv");
    console.log(" -r: dump only result");
    console.log(" -q: include #- ");
    console.log(" -h: include #ho ");
    console.log(" -r: include #ref ");
}

let argv = process.argv.slice(2);
if (!argv.length) return help(process.argv);


let table = getfile(argv.find(v => v[0] != "-") || "glyphwikiupdate.csv").split('"')
    .map((v,i) => (i % 2) ? v.split("\r").join("$").split("\n").join("$") : v).join("")
    .split("\r\n").map(v => {
        //console.log(v);
        let row = v.split(",").map(v => v.trim());
        let no, name, c, glyph;
        [no, name, c, glyph] = row;
        if (glyph == "_") return [no, name, "_"];
        glyph = (glyph.slice(0,2) == "[[") ?
            (("99:0:0:0:0:200:200:") + glyph.slice(2,-2)) :
            glyph.split("$").filter(v=>v).join("$");
        let reg = execSync(`grep '^ ${name}.@' ../storage/dump_all_versions.txt; true`);
        if (!reg) return [no, name, "N"];
        //console.log(reg.toString());
        let regs = reg.toString().split("\n").find(row => row.split("|").pop().trim() == glyph);
        if (regs) return [no, name, "!!", regs.split("|").shift().trim()];
        return [no, name, "*"];
        //console.log(no, name, "*", regs[2]);
    }).map(v => console.log(v.join("\t")));

