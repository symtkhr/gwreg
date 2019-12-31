$(function() {
    var regs = {};   // {dkw-%d: {retake: 登録予定データ, mt: "#"(mtnestが登録した場合)}}
    var mj = [];     // {d:大漢和番号, k:戸籍統一, u:UCS}のテーブル
    var tgts = {};   // {u%x(=UCS番号): 差替部首}
    var hokans = {}; // {d:大漢和番号, s:画数}のテーブル
    var CGIPATH = "../cgi-bin/shell.cgi";
    
    $.ajaxSetup({ cache: false });
    var page_init = function() {
        var load = 0;
        // 読込ファイルの一覧
        var loadfiles = [
        //  {name:"p.def.dat", handler:defhandler},
            {name:"../tables/mji_00502_pickup.txt", handler:mjhandler},
            {name:"../tables/kdbonly.htm.txt", handler:kdbhandler},
            {name:"../tables/p.ishiitgt.txt", handler:tgthandler},
            {name:"p.retaken.dat", handler:retakenhandler},
            {name:"p.done.dat", handler:donehandler},
            {name:"p.hokan.dat", handler:hokanhandler},
        ];

        var fileload = function(file) {
            $.get(file.name, function(data) {
                load++;
		$("body").append(file.name, "<br>");
                if (file.handler) file.handler(data, file);
                if (load != loadfiles.length) return fileload(loadfiles[load]);
                var n = location.href.split("#").pop();
                var def = regs[n] && regs[n]["retake"] && regs[n]["retake"][0];
                editor_init(n, def);
            });
        };

        fileload(loadfiles[0]);
    };
    //    $("#editorbox").hide();

    var hokanhandler = function(data) {
        hokans = data.split("\n").map(function(line) {
            var t = line.split("\t");
            return {d:t[0], s:(1 * t[1])};
        }).sort(function(a, b) {
            return a.s - b.s;
        });
        //console.log(hokans);
    };
    
    var tgthandler = function(data) {
        //console.log("loadd");
        data.split("\n").forEach(function(line) {
            var rec = line.split("\t");
            var c = rec[0];
            if (!c) return;
            var u = "u" + c.codePointAt(0).toString(16);
            tgts[u] = rec[1].split("/").pop();
        });
    };

    var defhandler = function(data) {
        data.split("\n").forEach(function(line) {
            line = line.trim();
            //if (!line.match(/^dkw\-/)) return;
            var rec = line.split("|");
            if (rec.length != 3) return;
            var dkw = rec.shift().trim();
            gdef[dkw] = rec.pop().trim();
        });
    };

    // ファイルの中身の処理
    var cathandler = function(txt, file) {
        txt.split("\n").forEach(function(line) {
            if (!line.match(/^dkw\-/)) return;
            var rec = line.split("\t").join(" ").split(" ");
            var dkw = rec.shift();
            regs[dkw] = rec;
        });
    };

    var mjhandler = function(data) {
        mj = data.split("\n").map(function(row) {
            var cols = row.split("\t");
            if (cols.length < 3) return {};
            var ret = {};
            ret.d = function(d){
                var d = d.trim().split("補").join("h").split("'").join("d");
                var n = d.match(/\d+/);
                if (!n) return;
                var digit = (d.indexOf("h") < 0) ? 5 : 4;
                return d.split(n[0]).join("0".repeat(digit - n[0].length) + n[0]);
            }(cols[0]);
            ret.k = function(k) {
                if (!k.match(/\d+/)) return;
                return k.split("ksk-").join("koseki-");
            }(cols[1]);
            ret.u = cols[2].toLowerCase().split("+").join("");
            //if (ret.d == "dkw-00338") console.log(ret);
            return ret;
        }).concat(mj);
    };

    var kdbhandler = function(data) {
        data.split("\n").forEach(function(line){
            if (line.indexOf(",") != 0) return;
            var ret = {};
            var cols = line.split(",").forEach(function(a) {
                if (a.indexOf("[[dkw-") == 0 && !ret.d)
                    ret.d = a.split("[[").join("").split("]]").join("");
                if (a.indexOf("[[u") == 0)
                    ret.u = a.split("[[").join("").split("]]").join("");
            });
            mj.push(ret);
        });
        mj.sort((a,b) => { if (!a.d) a.d ="x"; if(!b.d) b.d = "x";
                return a.d < b.d ? -1 : 1;});
    };

    var retakenhandler = function(data) {
        var ret = [];
        data.split("\n").forEach(function(line){
            if (line.indexOf("dkw-") != 0 && line.indexOf("u") != 0) return;
            var cols = line.split("\t");
            var name = cols.shift();
            var dkw = name.match(/dkw[0-9dh-]+/) || name.match(/u[0-9a-z-]+/);
            //if (name.indexOf("u")==0)console.log(name, dkw);
            if (dkw) dkw = dkw[0];
            if (!regs[dkw]) regs[dkw] = {};
            regs[dkw]["retake"] = cols;
        });
        //console.log(regs["dkw-00003"].retake);
    };

    var donehandler = function(data) {
        data.split("\n").forEach(function(line){
            if (line.indexOf("dkw-") == -1) return;
            var dkw = line.match(/dkw[0-9dh-]+/);
            if (dkw) dkw = dkw[0];
            //regs[dkw]["retake"] = undefined;
            if (!regs[dkw]) regs[dkw] = {};
	        regs[dkw].mt = "#";
        });
    };
    

    var mjfind = function(target) {
        return mj.filter(m => (m.u == target) || (m.k == target) || (m.d == target));
    }

    var ucs2c = function(u) {
        if (!u) return "〓";
        var ucs = u.match(/^u([0-9a-f]+)/);
        return ucs ? String.fromCodePoint(parseInt("0x" + ucs[1])) : "〓";
    };

    var agendalist = function(def) {
        var defs = def.split("\n").join("$").split("$");
        return defs.map(function(row) {
            var r = row.split(":");
            return (r[0] == "99") ? r[7] : r[0];
        });
    };
    var agendadump = function() {
        var def = $("#defglyph").val().trim();
        var html = agendalist(def).map(function(v) {
            if (v.match(/^[0-9]$/)) return v;
            if (v.match(/[^\x20-\x7e]/)) {
                v = "u" + v.codePointAt(0).toString(16);
            }
            return "<label><input type=checkbox>" + v + "</label>" +
                "(<a href='https://glyphwiki.org/wiki/" + v + "' target='_blank'>" + ucs2c(v) + "</a>)";
        });
        $("#savedone").hide();
        $("#agenda").html(html.join(", "));
    };

    $("#dump").click(function() { agendadump(); });
    $("#draw").click(function() {
        var def = $("#defglyph").val().trim().split("\n").join("$");
        /*
        $("img#preview").attr(
            "src",
            "https://glyphwiki.org/get_preview_glyph.cgi?data=" + def);
*/
        $("#dump").click();
        $("body").append(def);
        kage_draw(def, $("div#preview").show(), "white", true);
    });

    var replace = function(q, cs, is_rel) {
        var qrows = q.split("\n").join("$").split("$");

        //1行ずつ見て差替
        var rrows = qrows.map(function(qrow) {
            var qrow = qrow.trim();
            if (qrow.indexOf('[[') == 0 && qrow.substr(-2) == ']]') {
                qrow = '99:0:0:0:0:200:200:' + qrow.slice(2, -2);
            }
            var qcols = qrow.split(":");
            if (qcols[0] != "99") return qrow;
            if (qcols[7].match(/[^\x20-\x7e]/)) {
                qcols[7] = "u" + qcols[7].codePointAt(0).toString(16);
                qrow = qcols.join(":");
            }
            if (cs.indexOf(qcols[7]) < 0) return qrow;
            qcols[7] = qcols[7].split("@").shift();
            qcols[7] = qcols[7].split("-jv").shift();
            qcols[7] = qcols[7].split("-j").shift();
            var f = reptable.find(m => m.q == qcols[7]);
            if (f) {
                if (f.r.indexOf("$") != -1)
                    return extract_parts(qcols, f.r);
                if (!f.x) f.x = [0, 200];
                if (!f.y) f.y = [0, 200];
                var r = qrow.split(":");
                r[3] = f.x[0];
                r[4] = f.y[0];
                r[5] = f.x[1];
                r[6] = f.y[1];
                r[7] = f.r;
                console.log(r.join(":"));
                return extract_parts(qcols, r.join(":"));
                //r[7] = f.r;
                // todo: x,y fix
                //return r.join(":");
            }
            var f = mjfind(qcols[7], "u");
            console.log(qcols[7],f);
            if (f.length == 0) return qrow;
            /*
            var r = qrow.split(":");
            r[3] = 0;
            r[4] = 0;
            r[5] = 200;
            r[6] = 200;
            r[7] = f[0].d;
            return extract_parts(qcols, r.join(":"));
            */
            qcols[7] = f[0].d;
            return qcols.join(":");
        });
        return rrows.join("$");
    };
    
    $("#replace").click(function() {
        //チェックを入れた部品のみ対象
        var cs = $("#agenda :checked").map(function(){return $(this).parent().text();})
            .get().map(v => v.split("(").shift())
            .filter((c, i, self) => (self.indexOf(c) == i));
        //if (cs.length == 0) return;

	    var q = $("#defglyph").val().trim();
        var r = replace(q, cs);
        var oldq = q.split("\n").join("$");
        if (oldq != r) {
            $("<span>").text(oldq).appendTo("#undolist");
        }

        $("#defglyph").val(r.split("$").join("\n"));
        $("#draw").click();
    });

    //[IN] q グリフ1行
    //[IN] r グリフ全体("$"結合)
    //[RET] 差替えグリフ("$"結合)
    var extract_parts = function(q, r)
    {
        if (q[0] != "99") return q.join(":");
        var x0 = parseInt(q[3]);
        var y0 = parseInt(q[4]);
        var x1 = parseInt(q[5]);
        var y1 = parseInt(q[6]);
        var rfix = r.split("$").map(function(rrow) {
            var rcols = rrow.split(":");
            var len = (rcols[0] == "99") ? 2 : ((rcols.length - 3) / 2);
            console.log(rrow, len);

            for(var i=0; i <len; i++) {
                var px = i * 2 + 3;
                var py = i * 2 + 4;
                rcols[px] = Math.round(x0 + (x1 - x0) * rcols[px] / 200);
                rcols[py] = Math.round(y0 + (y1 - y0) * rcols[py] / 200);
            }
            return rcols.join(":");
        });
        return rfix.join("$");
    };

    $("#save").click(function() {
        var v = $("#savename").val().split(":");
        var d = v[0].trim();
        var k = v[1].trim();
        var u = v[2].trim();
        var glyph = $("#defglyph").val().split("\n").join("$");
        $.get(CGIPATH,
              {name:d, origin:k, ucs:u, save:glyph, memo:"#m:"},
              function(ret) {
                  $("#savedone").show();
              });
    });
    $("#showorigin").click(function() {
        if (!$(this).prop("checked")) return $("#origin").hide();

        var origin = $("#info button").eq(0).text();
        if (!origin || origin.trim() == "undefined") {
            origin = $("#savename").val().split(":")[2];
        }
        if (!origin) return;
        if(0) {
            $("#origin").show()
                .attr("src",
                  "https://glyphwiki.org/glyph/" + origin.trim() + ".svg"
                 );
        }
        kage_draw(origin.trim(), $("#origin").show());
        //var $origin = $("<div id=origin>").appendTo("#previewbox");
        //$("#origin")//var $("")$origin
    });
    
    $("#undo").click(function() {
        var $log = $("#undolist span:last-child");
        if ($log.length == 0) return;
        $("#defglyph").val($log.text().split("$").join("\n"));
        $("#dump").click();
        $log.remove();
    });
    $("#extract").click(function() {
        //チェックを入れた部品のみ対象
        var cs = $("#agenda :checked").map(function(){return $(this).parent().text();}).get().map(v => v.split("(").shift()).filter((c, i, self) => (self.indexOf(c) == i));

        if (cs.length == 0) return;

        var oldg = $("#defglyph").val().trim().split("\n").join("$");
        var newg = oldg;
        var loaded = 0;
        
        cs.forEach(function(c) {
            $.get(CGIPATH + "?name=" + c,
                  function(rglyph) {
                      var qrows = newg.split("$");

                      var rrows = qrows.map(function(qrow) {
                          if (qrow.indexOf("99:") != 0) return qrow;
                          var q = qrow.split(":");
                          if (q[7] != c) return qrow;
                          console.log(q,rglyph);
                          return extract_parts(q,rglyph.trim());
                      });
                      newg = rrows.join("$");
                      loaded++;

                      if (cs.length != loaded) return;
                      if (oldg != rrows.join("$")) {
                          $("<span>").text(oldg).appendTo("#undolist");
                      }
                      $("#savedone").hide();
                      $("#defglyph").val(newg.split("$").join("\n"));
                      $("#dump").click();
                  });
        });
    });

    $("#official").click(function() {
        var t = $("#savename").val().split(":");
        var dkw = t[0];
        var ucs = t[2];
        var defglyph = encodeURI($("#defglyph").val().split("\n").join("$"));
        //console.log(defglyph)
        var src = "https://glyphwiki.org/wiki/" + dkw +"?action=preview&textbox=" + defglyph + "&related="+ ucs;
        window.open(src);
    });
    
    var editor_init = function(c, def) {
        if (def && def!='_') {
            $("#defglyph").val(def.split("$").join("\n")).focus();
            agendadump();
        } else {
            $.get(CGIPATH + "?name=" + c,
              function(def) {
                  if (def.indexOf(":") < 0) return;
                  $("#defglyph").val(def.split("$").join("\n")).focus();
                  agendadump();
              });
        }
        var fs = mjfind(c);
        var $info = $("#info").text("");
        if (fs.length == 0) {
            fs = [{d:c, u:c}];
        }
        $("<button>").text(fs[0].d).appendTo($info);
        $("<button>").text(fs[0].k).appendTo($info);
        $("<button>").text(fs[0].u + ":" + ucs2c(fs[0].u)).appendTo($info);
        $("#savename").val(fs[0].d + ":" + fs[0].k + ":" + fs[0].u);
        
        $("<input name=loadglyph>").appendTo($info);
        $("<button>").text("load").appendTo($info);

        $info.find("button").click(function() {
            var c = $(this).text().split(":").shift();
            if (c != "load") {
		$("[name=loadglyph]").val(c);
		return;
	    }
	c = $("[name=loadglyph]").val();
            $.get(CGIPATH + "?name=" + c,
                  function(def) {
                      if (def.indexOf(":") < 0) return;
                      $("#defglyph").val(def.split("$").join("\n")).focus();
                      agendadump();
                  });
        });
        //console.log(fs[0].split("[").shift());
        $("#undolist").text("");
        $("#editorbox").show();
    };

    $("#editorbox .closebox").click(function() {
            //     $("#editorbox").hide();
    });

    var editor_auto = function(c, tgt, callback) {
        var defhandler = function(def) {
            if (def.indexOf(":") < 0) return;
            var ms = Array.from(tgt).map(c => "u" + c.codePointAt(0).toString(16));
            //var ms = tgt.match(/\[(u[0-9a-f]+)\]/g);
            //ms = ms.map(m => m.substring(1, m.length - 1));

            //tgt(=ms)のうち現行定義にあてはまるものを抽出
            var tgts = agendalist(def).filter(function(v) {
                if (v.match(/^[0-9]+$/)) return;
                if (v == "aj1-13993") v = "u9f3b";
                if (v.indexOf("dkw-") == 0) {
                    var fs = mjfind(v.split("@").shift());
                    console.log(v,fs);
                    if (fs.length)
                        v = fs[0].u;
                }
                return ms.find(m => v.indexOf(m) != -1);
            });
            console.log(tgts);
            var r = def;
            tgts.forEach(function(tgt) {
                r = replace(r, tgt);
            });
            if (r == def) {
                editor_init(c, def);
                return r;
            }
            callback(r);
        };
        /*
        if (gdef[c]) {
            defhandler(gdef[c]);
            return;
        }
        */
        $.get(CGIPATH + "?name=" + c, defhandler);
    };


    page_init();
});
