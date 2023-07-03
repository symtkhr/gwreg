const getfile = (fname, cb) => {
    const fs = require('fs');
    return fs.readFileSync(fname, 'utf8');
};

console.log("<style>img {width:50px; height:auto;}</style><body>");
const { execSync } = require('child_process')

let reg = getfile("gwregdone.txt").split("\n").filter(v=>v);

console.log(process.argv);
if (process.argv.length < 3) return console.log("arg = MJ0xx | xx = 00-56");

let table = execSync(`cut ../tables/mji.00601.csv -d, -f2,3,4,6,8,30 | grep ${process.argv.slice(2)[0]}`)// > jmjtestdata1000.txt");
table.toString().split("\n").filter(v=>v).slice(0).map(row => {

    let cell = row.split(",");
    if (reg.indexOf("jmj-"+cell[1].slice(2))!=-1) return;
    //cell.unshift("_");
    let c, jmj, u, uiv, ksk, dkw;
    [c, jmj, u, uiv, ksk, dkw] = cell;
    let ucs = uiv || u;
    let p = [
        //"https://glyphwiki.org/glyph/jmj-" + jmj.slice(2) + ".svg",
        "https://moji.or.jp/mojikibansearch/img/MJ/" + jmj +".png",
        // ksk && "https://houmukyoku.moj.go.jp/KOSEKIMOJIDB/kanji-big/" + ksk + ".png",
        uiv && "https://glyphwiki.org/glyph/u" + uiv.split("U+").join("").split("_").join("-u").toLowerCase() + ".svg",
        ksk && "https://glyphwiki.org/glyph/koseki-" + ksk + ".svg",
        u && "https://glyphwiki.org/glyph/u" + u.split("U+").join("").split("_").join("-u").toLowerCase() + ".svg",
    ]

    let tag = p.map(u => (u ?  `<img src="${u}" />` :"_____"));
    //(u.indexOf("glyphwiki") < 0 ? "" : `<a href="${u.split("/glyph/").join("/wiki/").split(".svg").join("")}">[g]</a>`));
    //tag = [];
    console.log(`<br><input type=checkbox id=${cell[1]}>` + tag.join("|"));


});
    let foot = ` <textarea id="checklist"></textarea>   <script>
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
