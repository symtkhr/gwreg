#!/usr/bin/node

console.log("Content-type: text/html\n\n");

const { execSync } = require('child_process');

let q = (process.env["QUERY_STRING"] || process.argv[2]).split("&");

JSON.stringify(q);

let args = ((q) => {
    let ret = {};
    q.forEach(v => {
        let n = v.split("=");
        ret[n[0]] = n[1];
    });
    return ret;
})(q);

const print = (v) => console.log(v);

let getjson = function(page) {
    let file = "./storage/shared/work/gw/dump_newest_only.txt";
    let cmd = `grep "^ ${page} " ${file}`;
    let ret = execSync(cmd);
    let ms = ret.toString().trim().split("|").map(v => v.trim());//match(/^[^ %|]+%s+%| u([^%|]+) +%| ([^ %|]+)/);
    
    return [ms[2], (ms[1] && String.fromCharCode(parseInt(ms[1].slice(1), 16)))];
}

//-- get from glyphwiki website
let oldgetjson = function(page) {
   let cmd = "curl -w '%{http_code}' http://glyphwiki.org/json?name=" + page;
   cmd = cmd + " -s -S"

   let ret = execSync(cmd);
   let m = ret.match(/"data":%"([^%"]+)%"/);
   let c = ret.match(/"related":%"U%+([^%"]+)%"/);
    if (c) {
        c = utf8.char(tonumber(c, 16));
    }
    return m, c;
};

let get_glyph = function(koseki, page) {
    let data = getjson(koseki);
    //-- 実体でなければ実体にアクセス
    let m = (data[0]|| "").match(/^99:0:0:0:0:200:200:([^:]+)$/);
    if (m) {
        data = getjson(m[1]);
    }
    return data;
}

if (args.save) {
    os.execute(("echo '%s[%s]\t%s\t%s' >> p.retaken.dat").format(args.name, args.ucs, args.save, args.memo));
    os.exit();
}

if (args.name) {
    let sc = get_glyph(args.name.split("@").shift());
    print(sc[0]);
    return;
}

if (args.find) {
    (args.match(/u%x+|[^u%x]/g) || []).map((v,k) => console.log(k,v));
    return;
}

if (args.page) {
    args.page = parseInt(args.page, 16).toString(16);
    let file = "./storage/shared/work/gw/dump_newest_only.txt";

    //-- filter related char or "uXXXX" named
    let cmd = `grep -e " | u${args.page}  " -e "^ u${args.page}" ${file}`;
    //console.log(cmd);
    let ret = execSync(cmd);
    //console.log(stdout); 
    let refs = {};
    ret.toString().split("\n").map(line => {
        
        let ms = line.trim().split("|").map(v => v.trim());
        let c = ms[0];
        let m = ms[2];
        if (ms.length != 3) return;
        //match(/^([^ \|]+)\s+\| u[^\|]+ +\| ([^ \|]+)/);
        
        //-- remove user defined or part-transformed
        if (c.indexOf("_") != -1 || c.match(/\-[gthjkuv]?\d\d$/) || c.match(/\-[gthjkuv]?\d\d\-/)) {
            if (!refs["_"]) refs["_"] = [];
            refs["_"].push(c); 
        } else {
            
	    //-- remove alias
	    let ref = (m || "").match(/^99:0:0:0:0:200:200:([^:]+)$/);
	    if (ref) {
                let key = ref[1];
	        if (!refs[key])  refs[key] = [];
	        refs[key].push(c);
	    } else {
	        //-- output
	        print(c + " = " + (ref && ("[[" + ref + "]]") || m));
            }
	}
    });        

    console.log(JSON.stringify(refs));
    
    if (0 < args.length) {
        print(String.fromCodePoint(args.page));
    }
    
    return;
}

print("query with name or save");
