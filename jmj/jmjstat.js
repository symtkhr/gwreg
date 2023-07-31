const getfile = (fname, cb) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')

console.log(process.argv);
if (process.argv.length < 4) return console.log("arg = stat/compl, tsvfile");
const mode = process.argv[2];
const tsvfile = process.argv[3];

let origin = execSync("grep class=def done/rtest*.htm").toString().split("\n").map(v=> {
    let name = v.match(/MJ[0-9]+/);
    let glyph = v.split("class=def").pop();
    return [name && name[0].trim(), glyph];
}).filter(v => v[0]).map(g => {
    g[1] = g[1].split("</span>").join("").slice(1).split("$").filter(v=> v && v!="0:0:0:0").map(v => {
        let param = v.split(":");
        if (param[0] == "99") return param[7].split("@").shift();
        return "." + param[0];
    });
    return g;
});
//return origin.map(v => console.log(v));
let toreg = getfile(tsvfile).split("\n").map(v => v.split("\t")).filter(v => v && v[0]);
let diff = toreg.map(v => {
    let jmj, glyph;
    [jmj, glyph] = v;
    if (!glyph) return [jmj];
    jmj = jmj.split("[").shift();
    let mj = jmj.split("jmj-").join("MJ");
    let base = origin.find(v => v[0] == mj);
    if (!base || !base[1]) return [jmj]; //console.log(jmj, "<nobase>"); 
    let refs = glyph.split("$").filter(v=>v).map(v => {
        let param = v.split(":");
        return (param[0] == "99") ? param[7] : ("." + param[0]);
    });
    if (refs.length != base[1].length) return [jmj];
    let diff = base[1].map((part,i) => (refs[i] != part) && [part,refs[i]]).filter(v=>v);
    //console.log(jmj, diff);
    return [jmj, diff.map(v => v[1])];
});

if (mode == "stat") {
    let stat = {};
    diff.forEach(v => v[1] && v[1].map(gl => stat[gl] = (stat[gl] || 0) + 1));
    let stat0 = Object.keys(stat).filter(key => stat[key]).sort((a,b)=> stat[a] - stat[b]);//.map(key => console.log(key, stat[key]));
    return console.log(JSON.stringify(stat0.sort()));
}

if (mode == "compl") {
    toreg.slice(0).map(v => {
        let jmj, glyph, type, action, stat, remark;
        [jmj, glyph, type, action, stat, remark] = v;
        jmj = jmj.split("[").shift();
        glyph = glyph.split("$").map(v => v.replace(/@[0-9]+/,"")).join("$");
        let using = diff.find(v => v[0] == jmj);
        if (using && using[1] && using[1].length) remark = ("Using " + using[1].filter((v,i,self) => self.indexOf(v) == i).join(" "))
        //console.log(`grep ${ jmj.split("jmj-").join("MJ") } ../tables/mji.00601.csv | cut -d, -f2,3,4,6,8,30`);
        let c = "";
        if (jmj.slice(0,3) == "jmj") {
            let jmjs = execSync(`grep ${ jmj.split("jmj-").join("MJ") } ../tables/mji.00601.csv | cut -d, -f2,3,4,6,8,30`);
            let ref = jmjs.toString().split(",")[2] || "u3013";
            c = String.fromCodePoint(parseInt(ref.slice(1),16));
        } else {
            jmj = jmj.replace(/[^!-~]+/, v => v.codePointAt(0).toString(16));
            if (0 < jmj.indexOf("~")) {
                let base = jmj.split("~").shift();
                if (base.slice(-1)=="-") base = base.slice(0,-1);
                let vars = execSync(`grep ' ${ jmj.split("~").shift() }-var-' ./dump_newest_only.txt; true`).toString();
                let n = vars.split("\n").filter(v=>v).length;
                jmj = jmj.split("~").shift() + "-var-" + ("000" + (n + 1)).slice(-3);
                c = vars.split("|")[1] || jmj.match(/^u[0-9a-f]+/)[0];
                //console.log(c,vars.split("|")[1]);
                c = String.fromCodePoint(parseInt(c.trim().slice(1),16));
            }
        }
        jmj += "[" + c + "]";
        console.log([jmj, glyph, type, action, remark].join("\t"));
    });
}

if (mode == "preview") {
let htmlscriptdump = () => {
    const $tag = (tag,$dom) => [...($dom || document).getElementsByTagName(tag)];
    const $c = (name,$dom) => [...($dom || document).getElementsByClassName(name)];
    const $id = (id) => document.getElementById(id);
    let $img = $c("new");
    let seq = (idx) => {
        if (idx == $img.length) return;
        $img[idx].onload = () => seq(idx + 1);
        $img[idx].src = $img[idx].alt;
    };
    seq(0);

    $img.forEach($i => $i.onclick = () => {
        $i.classList.toggle("selected");
        $id("checklist").innerText = $c("selected")
            .map($i => $i.id);
    });
};
    console.log(`<meta charset="utf-8" /><style>
 img {width:200px; height:auto;border:1px solid gray;} a img {background:#ccc;}
img.selected { border:1px solid red; }
</style><body>
`);

    toreg.slice(0).map(v => {
        let jmjc, glyph, type, action, stat, remark;
        [jmjc, glyph, type, action, stat, remark] = v;
        let jmj = jmjc.split("[").shift();
        console.log("<hr>",jmjc);
        if (jmj.slice(0,4) == "jmj-") {
            console.log(`<img loading="lazy" src="https://moji.or.jp/mojikibansearch/img/MJ/${jmj.split("jmj-").join("MJ")}.png" />`);
        } else {
            console.log(`<img loading="lazy" src="https://glyphwiki.org/glyph/${jmj.split("-var-").shift()}.svg" />`);
        }
        if (glyph[0] == "[")
            console.log(`<img loading="lazy" id=${jmjc} class="new" alt="https://glyphwiki.org/glyph/${glyph.slice(2,-2)}.svg"/>`);
        else
            console.log(`<img loading="lazy" id=${jmjc} class="new" alt="https://glyphwiki.org/get_preview_glyph.cgi?data=${glyph}"/>`);
        
        console.log(v.slice(2).join("\t"));
        console.log(diff.find(v => v[0] == jmj));
    });
    let foot = ` <br/><textarea id="checklist"></textarea>`;
    console.log(foot, "<script>window.onload=");
    console.log(htmlscriptdump.toString());
    console.log("</script>");
}

