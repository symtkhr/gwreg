const getfile = (fname, cb) => {
    const fs = require('fs');
    return fs.readFileSync(fname, 'utf8');
};

const { execSync } = require('child_process')

let reg = getfile("gwregdone.txt").split("\n").filter(v=>v);

let table = execSync("cut ../tables/mji.00601.csv -d, -f2,3,4,6,8,30 | grep MJ027")// > jmjtestdata1000.txt");
let json = table.toString().split("\n").filter(v=>v).slice(0).map((row,i) => {
    let cell = row.split(",");
    if (reg.indexOf("jmj-"+cell[1].slice(2))!=-1) return;
    let c, jmj, u, uiv, ksk, dkw;
    [c, jmj, u, uiv, ksk, dkw] = cell;

    return [jmj,
            uiv.split("U+").join("").split("_").join("-u").toLowerCase(), ksk,
            u.split("U+").join("").split("_").join("-u").toLowerCase()];
}).filter(v=>v);

console.log(getfile("jmjtest.html").split("[[[[DUMPS]]]]")
            .join(JSON.stringify(json)));
