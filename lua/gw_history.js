const getfile = (fname) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')

let DUMPFILE = "RecChange.html";
let argv = process.argv.slice(2);
let offset = "offset=3895312";
Array(parseInt(argv[0])).fill(0).map((x,n) => {
    console.log(`wget "https://glyphwiki.org/wiki/Special:Recentchanges?view=500&hideauto=1&user=mtnest&${offset}" -O ${DUMPFILE}`);
    execSync(`wget "https://glyphwiki.org/wiki/Special:Recentchanges?view=500&hideauto=1&user=mtnest&${offset}" -O ${DUMPFILE}`)
    let logs = getfile(DUMPFILE).split('<li class="history">').map((v,i) => {
        if (i == 0) return v.match(/offset=[0-9]+/g);
        return v.split('<div class="texts">').shift().replace(/<.+?>/g, "").split(" ")
            .filter(v => v && v != "." && v != "(履歴)" && v != "(会話)");
    });
    offset = logs[0].sort().shift();
    //console.log(offset,logs[0]);
        
    logs.slice(1).map(v => console.log(v.join("\t")));
});
