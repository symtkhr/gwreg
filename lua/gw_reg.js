let arg = process.argv.slice(1);
console.log(arg);

const DUMPNEWEST = "dump_newest_only.txt";
const LOGPATH = "./reglog/";
const GWSITE = "https://glyphwiki.org/wiki/";
const UNDONE_LOG  = "./reglog/0undone";
const COOKIE = LOGPATH + "gwcookie.txt";

let ucs2c = (ucs) => (ucs[0].toLowerCase() == "u")
    ? String.fromCodePoint(parseInt(ucs.slice(1),16) || 0x3013)
    : "〓";

const getfile = (fname) => require('fs').readFileSync(fname, 'utf8');
const { execSync } = require('child_process')
const execcmd = (cmd) => execSync(cmd + "; true").toString();
const undone = (message) => arg[1] == "register" ? execcmd(`echo '${message}' >> ${UNDONE_LOG}`) : console.log("undone: " + message);

let getjson = function(page) {
    let cmd = "curl https://glyphwiki.org/json?name=" + page;
    cmd = cmd + " -s -S"
    let ret = execcmd(cmd);
    ret = JSON.parse(ret);
    let m = ret.data;
    let c = ret.related;
    if (c) c = ucs2c(c);
    if (c == "〓") return [m];
    return [m, c];
}

/*
let getjson = function(page) {
    let ret = execcmd("grep '^ ${page} ' ${DUMPNEWEST}");
    let data = ret.split("|");
    if (data.length < 3) return;

   let m = data[2].trim();
   let c = data[1].trim();

   if (c) c = ucs2c(c);
   //console.log("current = ",m,c);
   return m,c;
}
*/
let accesswiki = function(page, glyph, c, overwrite, summ) {
    console.log("#####try:", page, c, overwrite, glyph.slice(0,30) + (30 < glyph.length ? "...": "   "));

   if (arg[1] != "dryrun" && arg[1] != "register") { 
       return;
   }
   // 入れ替えの場合
   if (overwrite == "swap") { 
       let cmd = `curl -w '\\n '${GWSITE}/${page}?action=swap' -b ${COOKIE} `;
       console.log(cmd);
       if (arg[1] == "register") execcmd(cmd);
       return;
   }

    // 現行を確認
    let glyph0, c0;
    [glyph0, c0] = getjson(page);

    if (glyph0 && overwrite == "new") {
        return undone(page + "already registered");
    }

    // 参照
    let toalias = glyph.match(/^\[\[(.+)\]\]$/);
    let toalias0 = glyph0 && glyph0.match(/^99:0:0:0:0:200:200:([^:]+)$/);

    // 関連字だけ差し替える場合
    if (overwrite == "kr") { 
        glyph = glyph0;
        summ = "関連字";

    } else if (glyph0 && !toalias0 && overwrite != "force") {        // 現在最新が実体である場合

        // 自分を参照しているやつらを拾い出す
        let k = execcmd(`grep '99:0:0:0:0:200:200:${page}$' ${DUMPNEWEST}`).trim().split("\n").filter(v => v);

        if (overwrite == "isolated") {
            // 被参照あれば上書きしない, todo:swap
            if (0 < k.length) return undone(page + " as otheralias");
        } else if (overwrite == "alias")  {
            // 被参照があればそれとswap提案
            if (0 < k.length) return undone(`${GWSITE}${k[0].trim().split(" ")[0]}?action=swap`);

            // 被参照がなければ現行を"u%x-var-%d"に改名・swap提案
            let n = execcmd("grep '^ u${c.codePointAt(0).toString(16)}-var-' ${DUMPNEWEST}").split("\n").length;

            let message = `${page} as nobranch `
                + `(u${ c.codePointAt(0).toString(16) }-var-${ ("00" + (n + 1)).slice(-3) })`;
            return undone(message);

        } else {
            return undone(page + " as original");
        }
   }

    // 参照なら概要に記載
    if (!summ && toalias) {
        summ = glyph;
        // ToDo: その日のうちに変更した文字は対象外
        let data = execcmd(`grep '^ ${glyph.slice(2,-2)} ' ${DUMPNEWEST}`).split("|");
        let match = (data[2]||"").trim().match(/^99:0:0:0:0:200:200:([^:]+)$/);
        if (match) summ = "[[" + match[1] + "]]";

    }
    // 関連字
    c = c || c0;
    if (!toalias && !c) {
        // 実体にもかかわらずrelatedの指定がない場合は自動算出する
        let _c = toalias0 && execcmd(`grep '^ ${toalias0[1]} ' ${DUMPNEWEST}`).split("|")[1];
        if (!_c || _c.trim() == "u3013") return undone(`${page} no kanrenji`);
        c = ucs2c(_c.trim());
    }

    let timestamp = parseInt(Date.now()/1000);

    let cmd = `curl -w '\\n' '${GWSITE}/${page}'`
        + ` -d 'page=${page}' `
        + ` -d 'related=${c || "〓"}'`
        + ` -d 'edittime=${timestamp}'`
        + ` -d 'textbox=${glyph}'`;
    if (summ)  cmd += ` -d 'summary=${summ}'`;
    console.log(cmd);

    if (arg[1] == "register") {
        cmd += ` -d 'buttons=以上の記述を完全に理解し同意したうえで投稿する'`
            + ` -b ${COOKIE}`
            + ` >> ${LOGPATH}${page}.dat`;

        execcmd(cmd);
        execcmd("sleep 1");
    }
}

let loginwiki = function() {
    let pwd = getfile(LOGPATH + "pwd").trim();
    let cmd = "curl -w '\\n'"
        + ` ${GWSITE}/Special:Userlogin`
        + " -d 'action=page'"
        + " -d 'buttons=ログイン'"
        + " -d 'name=mtnest'"
        + " -d 'page=Special:Userlogin'"
        + ` -d 'password=${pwd}'`
        + " -d 'returnto=Special:Userlogout'"
        + " -d 'type=login'"
        + ` -b ${COOKIE}`
        + ` -c ${COOKIE}`;
    console.log(cmd);
    let t = execcmd(cmd);
    console.log(t);
    return t.match("ログイン成功");
}



//版4: reg.datのとおりに登録する
let pickups = function(buff) {
    let dkws, glyph, cat, ow, dkw, c;
    [dkws, glyph, cat, ow] = buff.split("\t");
    if (!dkws) return;
    [dkw, c] = dkws.split("[");
    c = (c || "").split("]")[0];
    ow = ow || "isolated";

    if (!dkw.match(/^u[0-9a-f]/) &&
        "dkw,cdp,nyukan,gt,jmj,toki,koseki".split(",").every(prefix => dkw.indexOf(prefix + "-") != 0)
       ) {
        console.log("##format:", dkw);
        return;
    }
    if (!glyph) {
        console.log("##no glyph:", dkw);
        return;
    }
    if (c.match(/^u([0-9a-f]+)/)) c = ucs2c(c);
    glyph = glyph.split("$").filter(v => v).join("$");
    if (!c) c = null;
    //if (!c && glyph.slice(0,2) == "[[") c = null;

    // #ho, #refは登録しない
    if (cat.match(/^#[hrs\-]/) || glyph == "_" || glyph == "[[]]") { 
        let message = `${dkw} as undef ` + cat;
        return undone(message);
    }
    accesswiki(dkw, glyph, c, ow, cat.match("Revert") && cat.split(":").pop().trim());
}

let help = function() {
    console.log(" # " + arg[0] + " [mode] [file] [start] [end]");
    console.log("");
    console.log(" [mode] ");
    console.log("  - dump: Only dump");
    console.log("  - login: Login glyphwiki test");
    console.log("  - dryrun: Access glyphwiki and dump yet-registered glyphs");
    console.log("  - register: registration (with login and dryrun) ");
    console.log();
    console.log(" [file]");
    console.log("  the path of tsv file as the following format");
    console.log("    1st column: dkw-00001[u4e00] (for example of glyphname[related])");
    console.log("    2nd column: [[u4e00-j]]      (for example of glyph data)");
    console.log("    3nd column: #a               (for example of category)");
    console.log("    4th column: (one of the following, 'isolated' by default)")
    console.log("      - force    ; overwrite anyway");
    console.log("      - isolated ; overwrite only if alias or not referred to by other glyphs");  // overwrite
    console.log("      - alias    ; overwrite only if alias (otherwise suggest rename)"); // branch
    console.log("      - new      ; register only if new"); // onlynew
    console.log("      - kr       ; register only related");
    console.log("      - swap     ; swap as substance");
    console.log();
    console.log(" [start][end]");
    console.log("  tsv lines");
    console.log();
}

if (arg.length != 5) { 
   help();
   return;
}

execcmd(`mkdir -p ${LOGPATH}`);

if ((arg[1] == "login" || (arg[1] == "register")) && !loginwiki()) { 
    return;
}

let e0 = parseInt(arg[3]);
let e1 = parseInt(arg[4]);
let fname = arg[2];
if (e0 > e1) return help();
getfile(fname).split("\n").slice(e0,e1).map(line => pickups(line));

if (false) { 
    let glyph = "99:0:0:0:0:150:200:u72ad-01:0:0:0$99:0:0:60:0:199:95:u8278:0:0:0$99:0:0:65:80:192:190:u7530:0:0:0";
    accesswiki("dkw-49181", "[[u23727-jv]]", ucs2c("u23727"), "alias");
}
