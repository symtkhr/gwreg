const getfile = (fname, cb) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')

console.log(process.argv);
if (process.argv.length < 3) return console.log("arg = MJ000 - MJ056");

console.log(getfile("jmjrepformat.htm"));
let update = !false;
if (update) {
    execSync(`grep " jmj-" dump_newest_only.txt |cut -d" " -f2 > gwregdone.txt`);
}
let reg = getfile("gwregdone.txt").split("\n").filter(v=>v);


// find unregistered jmj
let jmjs = execSync(`cut ../tables/mji.00601.csv -d, -f2,3,4,6,8,30 | grep ${process.argv[2]}`)
    .toString().split("\n").filter(v=>v).slice(0).map((row,i) => {
        let cell = row.split(",");
        if (reg.indexOf("jmj-"+cell[1].slice(2))!=-1) return;
        let c, jmj, u, uiv, ksk, dkw;
        [c, jmj, u, uiv, ksk, dkw] = cell;
        let p = [
            jmj,
            uiv && "u" + uiv.split("U+").join("").split("_").join("-u").toLowerCase(),
            ksk && "koseki-" + ksk,
            u && "u" + u.split("U+").join("").split("_").join("-u").toLowerCase(),
            dkw,
        ];
        return p;
    }).filter(v => v);

if (jmjs.length == 0) return;
let iskanji = (u) => (5 == u.length && "u3400" <= u && u < "ua000") || (6 == u.length && "u20000" <= u && u < "u30000");
let gwall = getfile(`dump_newest_only.txt`).split("\n").map(r => {
    let v = r.split("|").map(v=>v.trim())
    if (v[2] && v[2].indexOf("99:0:0:0:0:200:200:") == 0 && v[2].indexOf("$") < 0)
        v[2] = v[2].split("99:0:0:0:0:200:200:").join("=")
    return v;
}).filter(v =>
          v[0].indexOf("_")==-1 &&
          v[0].indexOf("itaiji") < 0 &&
          v[0].indexOf("u2ff") != 0 && v[0].indexOf("twedu") != 0 && v[0].indexOf("cdp") != 0 &&
          (v[0].slice(0,4) == "jmj-" || (
              v[1] && (iskanji(v[1]) || "u3013" == v[1]) &&
              v[2] && (v[2].slice(0,2) != "=u" || iskanji(v[2].slice(1).split("-").shift()))
          ))
         );
//return console.log(gwall.find(v=>v[0]=="koseki-361390"))

// dump jmj candidate
jmjs.map(cell => {
    let jmj, u, uiv, ksk;
    [jmj, uiv, ksk, u] = cell;

    let page = gwall.filter(v => (v[1] == u) || (uiv && v[0] == uiv) || (ksk && v[0] == ksk));
    // sort uiv -> koseki -> other
    let prio = [uiv, ksk].filter(v=>v).map(key => {
        let g = page.find(v => v[0] == key);
        if (!g) return;
        return (g[2][0] == "=") ? g[2].slice(1) : key;
    }).filter((v,i,self) => v && self.indexOf(v) == i);
    let sortpage = prio.concat(page.map(v=>v[0]).filter(v => v != ksk && v!= uiv && prio.indexOf(v) == -1));

    // find daihyo
    let priokey = [uiv, ksk, u].filter(v=>v).shift();
    let g = page.find(v => v[0] == priokey);
    if (!g) { console.log(priokey); return []; }
    if (g[2][0] == "=") g = page.find(v => v[0] == g[2].slice(1));
    let row = g[2].split("$").map(v => (v.slice(0,3) == "99:") ? v.split(":")[7] : false);

    // make pages which have parts name or related u
    let candidates = row.map((p,i) => {
        if (!p) return [];
        let name = p.split("@").shift();
        let ref = gwall.find(v => v[0] == name);
        if (!ref) { console.log(name, ":notfound"); return []; }
        if (ref[2][0] == "=") ref = gwall.find(v => v[0] == ref[2].slice(1));
        row[i] += "[" + String.fromCodePoint(parseInt(ref[1].slice(1),16)) + "]";
        let pages = gwall.filter(v => v[1] == ref[1]);
        let part = p.match(/^(u[0-9a-f]+)\-.?([012][0-9])/);
        if (part) { // && part[2] != "07") {
            let opt = new RegExp('^u[0-9a-f]+\-.?' + part[2]);
            pages = pages.filter(v => opt.test(v[0]));
            return pages;//.sort((a,b)=>a<b?1:-1);//.sort((a,b) => b-a);//a[0][0] == "u" ? -1 : b[0][0] == "u" ? 1 : 0);
        }
        pages = pages.filter(v => !v[0].match(/^u[0-9a-f]+\-.?[012][0-9]/) && (v[2][0] != "="));
        //console.log(pages);
        return pages;//.sort((a,b)=>a<b?1:-1);//.sort((a,b) => b-a);//a[0][0] == "u" ? -1 : b[0][0] == "u" ? 1 : 0);
    });
    //candidates = candidates.sort((a,b) => a[0][0] == "u" ? 1 : b[0][0] == "u" ? -1 : 0);
    //return;

    // target glyph
    let tags = [];
    let mjpng = "https://moji.or.jp/mojikibansearch/img/MJ/" + jmj +".png";
    tags.push(`<br/><a href="https://glyphwiki.org/wiki/${u}" target="_blank"><img src="${mjpng}" /></a>`);
    // suspective parts
    let parts = execSync(`grep ${String.fromCodePoint(parseInt(u.slice(1),16))} jmjparts.txt  | cut -d":" -f1`);
    if (parts.length) tags.push("<span class=susp>" + parts.toString() + "</span>");
    // replaced glyph
    tags.push(`<img class="new" loading="lazy" src="https://glyphwiki.org/glyph/${priokey}.svg" />`);
    // related glyph
    sortpage.forEach(name => tags.push(`<img loading="lazy" src="https://glyphwiki.org/glyph/${name}.svg" />`));

    // dump parts
    console.log("<br><div>", jmj, "<span class=def>" + g[2] + "</span>");
    tags.push(... candidates.map((names,i) => "<li>" + names.length + ": " + row[i] +
                                 names.map(v=>`<a>${v[0]}</a>`).join("*") + `<span class="parts"><br/></span>`));
    console.log(tags.join("") + "</div>");
});

console.log(` <br/><textarea id="checklist"></textarea>`);

`残登録数
jmj-01   2154 2h u7900-7d00
jmj-02   7594 7h u7e00-9f00
jmj-03   7155 7h
jmj-04   9399 9h
jmj-05   6453 6h
`


