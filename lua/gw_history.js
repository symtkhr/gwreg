const getfile = (fname) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')
let argv = process.argv.slice(1).map(v => v.trim());
let DUMPFILE = "RecChange.html";

if (argv.length <= 1) {
    console.log(`${argv[0]} [options]
  -n      : not download but check local ${DUMPFILE}
  -f=xxx  : offset (get log from this value)
  -c=xxx  : count (get as many logs as this value * 500)
`);
    return;
}

let download = !argv.find(v => v.slice(0,2) == "-n");
let offset = "offset=" + ((download && argv.find(v => v.slice(0,2) == "-f")) || "").slice(3); //("offset=3895312";
let count = parseInt(((download && argv.find(v => v.slice(0,2) == "-c")) || "-c=1").slice(3));
Array(count).fill(0).map((x,n) => {
    if (download) {
        let shell = `wget "https://glyphwiki.org/wiki/Special:Recentchanges?view=500&hideauto=1&user=mtnest&${offset}" -O ${DUMPFILE}`;
        console.log(shell);
        execSync(shell);
    }
    let logs = getfile(DUMPFILE).split('<li class="history">').map((v,i) => {
        if (i == 0) return v.match(/offset=[0-9]+/g);
        v = v.split('<img class="thumb" ').join("[thumb]")
            .split(` border="0" loading="lazy" width="50" height="50">`).join("");
        return v.split('<div class="texts">').shift().replace(/<.+?>/g, "").split(" ")
            .filter(v => v && v != "." && v != "(履歴)" && v != "(会話)");
    });
    offset = logs[0].sort().shift();
    //console.log(offset,logs[0]);
        
    logs.slice(1).map(v => console.log(v.join("\t")));
});
