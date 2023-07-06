const getfile = (fname, cb) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')

console.log(`<meta charset="utf-8" /><style>
 img {width:160px; height:auto;} a img {background:#ccc;}
 body {width:800px;}
 span{vertical-align: top;width: 1em; line-height:1em; height: 160px; display:inline-block; border:1px solid red;}
</style><body>`
);
console.log(process.argv);
if (process.argv.length < 3) return console.log("arg = MJ000 - MJ056");

let update = false;
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
        ]
        return p;
    }).filter(v => v);

// make pages which have uiv/koseki name or related u
let opt = jmjs.map(p => (p.slice(1,-1).filter(v=>v).map(v => ` -e "^ ${v}"`).join("") + ` -e "| ${p[3]}"`))
    .filter((v,i,self)=>v && self.indexOf(v)==i).join("");
let pages = execSync(`grep ${opt} dump_newest_only.txt`).toString().split("\n").map(r=>r.split("|").map(v=>v.trim()))
    .filter(v => v[0].indexOf("_")==-1 && !v[0].match(/^u[0-9a-f]+\-[ktg]?[012][0-9]/) && v[1] && v[2]);
pages.map(v => { v[2] = (v[2] && v[2].indexOf("$") < 0) ? v[2].split("99:0:0:0:0:200:200:").join("=") : v[2]; });

// dump jmj candidate
jmjs.map(cell => {
    let jmj, u, uiv, ksk;
    [jmj, uiv, ksk, u] = cell;

    let page = pages.filter(v => (v[1] == u) || (uiv && v[0] == uiv) || (ksk && v[0] == ksk));
    // sort uiv -> koseki -> other
    let priokey = [uiv, ksk, u].filter(v=>v).shift();
    let g = page.find(v => v[0] == priokey);
    if (g[2][0] == "=") g = page.find(v => v[0] == g[2].slice(1));
    let row = g[2].split("$").map(v => (v.slice(0,3) == "99:") ? v.split(":")[7] : false);
    //console.log(jmj, g, priokey, row);

    // make pages which have parts name or related u
    let candidates = row.map(p => {
        if (!p) return [];
        let part = p.match(/^(u[0-9a-f]+)\-.?([012][0-9])/);
        if (part) {
            let opt = part[1] + '-.\\?' + part[2];
            let pages = execSync(`grep "^ ${opt}" dump_newest_only.txt`).toString().split("\n").map(r=>r.split("|").map(v=>v.trim()))
                .filter(v => v[0].indexOf("_") == -1 && v[1] && v[2]).map(v => v[0]);
            return pages;
        }
        let u = p.match(/^(u[0-9a-f]+)/);
        let related = u ? u[1] :
            execSync(`grep "^ ${p.split("@").shift()} " dump_newest_only.txt`).toString().split("|").slice(1,2).join("").trim();
        let pages = execSync(`grep "| ${related} " dump_newest_only.txt`).toString().split("\n").map(r=>r.split("|").map(v=>v.trim()))
            .filter(v => v[0].indexOf("_")==-1 && !v[0].match(/^u[0-9a-f]+\-.?[012][0-9]/) && v[0].indexOf("itaiji") < 0 &&
                    v[0].indexOf("u2ff") != 0 && v[0].indexOf("twedu") != 0 && v[0].indexOf("cdp") != 0 &&
                    v[1] &&
                    v[2] && (v[2].indexOf("$") != -1 || v[2].indexOf("99:0:0:0:0:200:200:") != 0)
                   ).map(v => v[0]);
        return pages
    });
    //return;
    // dump images
    console.log("<br>", jmj, row);
    let tag = candidates.map(
        names => "<li>" +
            names.map(name => `<label>`
                      +`<img loading="lazy" src="https://glyphwiki.org/glyph/${name}.svg" />`
                      //+`<input type=checkbox id="${jmj}_to_${name}"/>`
                      +`</label>`).join("") + "<br>" + names.join(", ")
    );
    tag.unshift(`<img loading="lazy" src="https://glyphwiki.org/glyph/${priokey}.svg" />`);
    // suspective parts
    let parts = execSync(`grep ${String.fromCodePoint(parseInt(u.slice(1),16))} jmjparts.txt  | cut -d":" -f1`);
    if (parts.length) tag.unshift("<span>" + parts.toString() + "</span>");
    // target glyph
    let mjpng = "https://moji.or.jp/mojikibansearch/img/MJ/" + jmj +".png";
    tag.unshift(`<a href="https://glyphwiki.org/wiki/${u}" target="_blank"><img src="${mjpng}" /></a>`);

    console.log("<br>" + tag.join(""));
});

    
    let foot = ` <br/><textarea id="checklist"></textarea>   <script>
  const $tag = (tag) => [...document.getElementsByTagName(tag)];
  const $id = (id) => document.getElementById(id);
  let save = localStorage.getItem("check");
  if (save)  JSON.parse(save).map(v => { console.log(v);if($id(v)) $id(v).checked = true; });

  $tag("input").forEach($t => $t.onchange = () => {
      console.log("change");
      let ret = $tag("input").filter($t=>$t.checked).map($t=>$t.id);
      localStorage.setItem("check", JSON.stringify(ret));
      $id("checklist").innerText = JSON.stringify(ret);
  });
if(0)
  $tag("img").forEach($i => $i.onclick = () => {
      if ($i.src.indexOf("glyphwiki") < 0) return;
      window.open($i.src.split("/glyph/").join("/wiki/").split(".svg").join(""));
  });
</script>
`
    console.log(foot);


`残登録数
jmj-01   2154 2h u7900-7d00
jmj-02   7594 7h u7e00-9f00
jmj-03   7155 7h
jmj-04   9399 9h
jmj-05   6453 6h
`


