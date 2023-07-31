#!/usr/bin/node

const getfile = (fname, cb) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')

console.log(`HTTP/1.1 200 OK
Content-Type: text/html

`);

const DUMPTXT = `${process.argv[1].split("/").slice(0,-1).join("/")}/dump_newest_only.txt`;
let q = (process.env.QUERY_STRING || process.argv[2]).split("&").map(data => {
    let key, val;
    [key, val] = data.split("=");
    return {k:key, v:val};
});

const grep = (qs) => {
    let gopt = qs.map(v => `-e '^ ${v} '`).join(" ");
    let cmd = `grep ${gopt} ${DUMPTXT}`;
    console.log(q,cmd);
    return execSync(cmd).toString();
};
let dump = "";
let qs = q.find(q=>q.k=="q").v.split(",");
let recursive = q.find(q => q.k == "rec");

if (!qs) {
    return console.log("Set: ?q=[glyphname] (&rec=1)");
}
while (true) {
    let ret = grep(qs);
    dump += ret;
    if (!recursive) break;
    qs = ret.split("\n")
        .map(glyph => glyph.split("|").pop().trim().split("$")
             .map(v => v.indexOf("99:") == 0 && v.split(":")[7].split("@").shift()))
        .reduce((sum,v) => sum.concat(v), []).filter(v=>v);
    console.log(qs);
    if (qs.length == 0) break;
}
console.log("<JSON>");
console.log(JSON.stringify(dump.split("\n").filter(v=>v).map(v => v.split("|").map(v => v.trim()))));
