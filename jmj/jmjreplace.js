const getfile = (fname, cb) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')

console.log(process.argv);
if (process.argv.length < 3) return console.log("arg = MJ000 - MJ056");

console.log(`<meta charset="utf-8" /><style>
 img {width:160px; height:auto;} a img {background:#ccc;}
 body {width:800px;}
 img.new {background-color:#fdd; }
 img.selected {background-color:#cfb; }
 img.rep { border: 1px solid green; }
 span.susp {vertical-align: top;width: 1em; line-height:1em; height: 160px; display:inline-block; border:1px solid red;}
 span.def {display:none;}
 span.parts img {width: 80px;}
 li a {display:none;}
 div {border:solid gray 1px; margin: 1px 0; }
 span.parts span { border: 1px solid #99c; display:inline-block; vertical-align: top; font-family:monospace; width:80px; overflow-wrap: break-word; }
</style><body><button>DUMP</button>`
);

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

    let foot = ` <br/><textarea id="checklist"></textarea>   <script>
   const $tag = (tag,$dom) => [...($dom || document).getElementsByTagName(tag)];
   const $c = (name,$dom) => [...($dom || document).getElementsByClassName(name)];
   const $id = (id) => document.getElementById(id);
   $id("checklist").innerText = localStorage.getItem("check");

   $tag("li").forEach($li => $li.onclick = () => {
       if ($tag("img", $li).length) return;
       let $parts = $c("parts", $li)[0];
       $parts.innerHTML = "<br/>" + $tag("a", $li).map($a => {
           let name = $a.innerText;
           return "<span><img src='https://glyphwiki.org/glyph/" + name +".svg'/><br/>"
               +"<span class=gw>" + name + "</span>"
               +"</span>";
       }).join("");

       $c("gw", $li).forEach($a => $a.onclick = () => window.open("https://glyphwiki.org/wiki/" +$a.innerText));

       $tag("img", $li).forEach($i => $i.onclick = () => {
           $i.classList.toggle("selected");
           let $div = $li.parentNode;
           let $def = $c("def", $div)[0];
           let original = $def.innerText.split("$");
           let reps = $c("selected", $div).map($i => {
               let $li = $i.parentNode.parentNode.parentNode;
               let index = $tag("li", $div).indexOf($li);
               return [index, $i.src.split("/").pop().split(".").shift()];
           });
           let glyph = original.map((v,i) => {
               let part = reps.find(r=>r[0]==i);
               if (!part) return v.replace(/@[0-9]+/,"");
               let c = v.split(":");
               c[7] = part[1];
               return c.join(":");
           }).filter(v=>v!="0:0:0:0").join("$");

           let $glyph = $c("new", $div)[0];
           if (reps.length)
               $glyph.classList.add("rep");
           else
               $glyph.classList.remove("rep");
           $glyph.id = $div.innerText.match(/MJ[0-9]+/)[0];
           $glyph.src = "https://glyphwiki.org/get_preview_glyph.cgi?data=" + glyph;
           console.log(glyph);
       });
   });
   $c("new").map($i => $i.onclick = () => {
       if (!$i.id) return;
       $i.classList.toggle("rep");
       let ret = $c("rep").map($i => [$i.id,$i.src]);
       ret = JSON.stringify(ret);
       $id("checklist").innerText = ret;
       localStorage.setItem("check", ret);
       console.log(ret);
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


