const getfile = (fname, cb) => {
    const fs = require('fs');
    return fs.readFileSync(fname, 'utf8');
};
const { execSync } = require('child_process');

let table = getfile("p.gwupdate.dat").split('"')
    .map(v => (v.indexOf(",") < 0) ? v.split("\r\n").join("$") : v).join("")
    .split("\r\n").map(v => v.split(","));

table.map(v => console.log(v.slice(1,5).join("\t")));
console.log(table.length);
