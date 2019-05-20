$(function() {
    var regs = {};   // {dkw-%d: {retake: 登録予定データ, mt: "#"(mtnestが登録した場合)}}
    var mj = [];     // {d:大漢和番号, k:戸籍統一, u:UCS}のテーブル
    var tgts = {};   // {u%x(=UCS番号): 差替部首}
    var hokans = {}; // {d:大漢和番号, s:画数}のテーブル

    $.ajaxSetup({ cache: false });
    var page_init = function() {
        var load = 0;
        // 読込ファイルの一覧
        var loadfiles = [
            {name:"p.def.dat", handler:defhandler},
            {name:"mji_00502_pickup.txt", handler:mjhandler},
            {name:"kdbonly.htm.txt", handler:kdbhandler},
            {name:"p.ishiitgt.txt", handler:tgthandler},
            {name:"p.retaken.dat", handler:retakenhandler},
            {name:"p.done.dat", handler:donehandler},
            {name:"p.hokan.dat", handler:hokanhandler},
        ];

        var fileload = function(file) {
            $.get(file.name, function(data) {
                load++;
                if (file.handler) file.handler(data, file);
                if (load != loadfiles.length) return fileload(loadfiles[load]);
                draw();
            });
        };

        fileload(loadfiles[0]);
    };
    $("#editorbox").hide();

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
            if (line.indexOf("dkw-") != 0) return;
            var cols = line.split("\t");
            var dkw = cols.shift().match(/dkw[0-9dh-]+/);
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
    
    // 1ページ分の描画
    var draw = function(n)
    {
        if (isNaN(n)) {
            n = location.href.split("#").pop();
            n = parseInt(n);
            if (isNaN(n)) n = 0;
        }
        location.href = "#" + n.toString();
        var boxid = "p" + n.toString();
        $("#result .box").hide();
        if (0 < $("#" + boxid).size()) {
            $("#" + boxid).show();
            return;
        }

        var $box = $("<div id=" + boxid + " class=box>").appendTo("#result");

        // 箱と絵
        for (var i = 0; i < (320 < n && n <= 350 ? 4 : 10); i++) {
            draw_scanimg(n, i, $("<div>").appendTo($box));
            //console.log(typeof(scanimglist[n]));
            var $mbox = $("<div>").appendTo($box).addClass("mbox");
        }

        draw_lines($box);
    };

    var draw_scanimg = function(n, i, $bar)
    {
        var boxwidth = 500;
        var scant = scanimglist1[n] || [];
        var top = 0;
        var src = "";
        var rate = 1;
        if (scant["r"+i]) {
             top = scant["r"+i].top;
             src = scant["r"+i].src;
             if (!isNaN(src)) src = scant["r"+src].src;
        } else if(scant.d) {
            // boxwidth : step = 1275 : 195 = 85 : 13
            var aspect = (320 < n && n <= 350) ? (7 / 17) : (13 / 85);
            rate = boxwidth / scant.d.step * aspect;
            var offset = scant.d.top * rate;
            top = i * boxwidth * aspect + offset;
            src = scant.d.src;
        } else {
            return;
        }
        console.log(rate);
        //console.log(top,n,i,scant);
        $bar.addClass("scan");
        $bar.css({"position": "relative", "overflow":"hidden",
                  "width":boxwidth + "px",
                  "height": (boxwidth / 1275 * 100) + "px",
                  "border":"1px solid red"});
        var $img = $("<img>").attr("src", "scanimg/" + src).appendTo($bar);
        $img.css({"top": -top + "px",
                  "left":(-scant.d.left * rate) + "px",
                  "position":"absolute",
                  "width": (scant.d.width * rate) + "px",
                  "height":"auto"});
	return;
        
        /* 
[refactoring案]
1: 現状画像のnaturalwidthを1275pxに拡縮している.
  naturalwidthのままscant.d.top とscant.d.step からいい感じの縮尺に自動調整できないか?
2: scant.t で各行先頭番号を記録しているが、dash番号とか対応できてない.
  むしろ各行の17字からの差分を記録して自動算出できないか(350<n における vacantのように)
3: プルダウン編集時はキーアクションが要る仕様にしたい
*/
        $img.load(function() {
            var width = $(this)[0].naturalWidth;
            var rate  = 1; //5 / 8;
            $(this).css(
                {"width": width * rate,
                 "top": parseInt($(this).css("top")) * 1275 / width * rate,
                });
        });
    };

    var redraw = function(n)
    {
        var file = {name:"p.retaken.dat", handler:retakenhandler};
        $.get(file.name, function(data) {
            if (file.handler) file.handler(data, file);
            //console.log(regs["dkw-00003"].retake);
            location.href = "#" + n.toString();
            var $box = $("#" + "p" + n.toString());
            draw_lines($box);
        });
    };

    // 1頁行分の字並べ
    var draw_lines = function($pagebox, n0)
    {
        var n = (1 * $pagebox.attr("id").split("p").pop());

        // 先頭行リスト
        var nth = function(n) {
            if (355 < n) return 0;
            var nth = 0;
            for (var i = (350 < n ? 351 : 0); i < n; i++) {
                nth += scanimglist1[i].v.reduce((sum, v) => sum + 17 - v, 0);
            }
            return nth;
        }(n);
        console.log(brs);

        // 各行に箱を並べていく
        $pagebox.find(".reg").hide();
        scanimglist1[n].v.forEach(function(vacant, i) {
            $mbox = $pagebox.find(".mbox").eq(i);
            var boxlen = 17 - vacant;
            for (var j = 0; j < boxlen; j++) {
                var dkw = ((n <= 350 ? mj[nth] : hokans[nth]) || {d:""}) .d;
                draw_box(dkw, $mbox);
                nth++;
            }
        });
/*
        //console.log(boxes, JSON.stringify(scanimglist[n]));
        $pagebox.find(".mbox").each(function(i) {
                scanimglist[i]) return;
                dkws[i].forEach(function(dkw) {
                        draw_box(dkw, $(this));
                    });
        }); */
        boxevents($pagebox);
    };

    var boxevents = function($pagebox) {
        $pagebox.find(".check select").unbind().keydown(function(e){
            var $dkw = $(this).parent().siblings(".dkw");
            var dkw = $dkw.text();
            var $box = $(this).parents(".reg");

            // E押下でエディタの起動
            if (e.keyCode == "E".charCodeAt(0)) {
                editor_init(dkw, regs[dkw] && regs[dkw].retake ? regs[dkw].retake[0] : null);
                return;
            }
            // V押下で画像表示
            if (e.keyCode == "V".charCodeAt(0)) {
                var fdkw = function(v) { return "dkw-" + ("0000" + v).substr(-5); };
                var n = scanimglist.findIndex(obj => dkw < fdkw(obj.t[0]));
                n = (n == -1) ? (scanimglist.length - 1) : (n - 1);
                var i = scanimglist[n].t.findIndex(top => dkw < fdkw(top));
                i = (i == -1) ? (scanimglist[n].t.length - 1) : (i - 1);
                var $scan = $box.parent().prev(".scan");
                console.log($scan, $scan.size());
                if (!$scan.size()) $scan = $("<div>").insertBefore($box.parents(".mbox"));
                console.log($scan);
                draw_scanimg(n, i, $scan);
                return;
            }
            // W押下で石井自動差替
            if (e.keyCode == "W".charCodeAt(0)) {
                $box.removeClass("saved");
                var $glyph = $(this).parent().siblings(".glyph");
                console.log($glyph);
                editor_auto(dkw, $box.find(".tgt").text(), function(def) {
                    var $rtk = ($glyph.find("img.retaken").length == 0) ?
                        $("<span class=retaken>").prependTo($glyph):
                        $glyph.find("span.retaken");
                    var src = "https://glyphwiki.org/get_preview_glyph.cgi?data=" + def;
                    // $rtk.attr("src", src);
                    kage_draw(def, $rtk);
                    $rtk.attr("rglyph", def);
                });
                // todo: 生成glyphをsave + glyphの preview(要レイアウト)
                return;
            }

            // G押下でGlyphwiki表示
            if (e.keyCode == "G".charCodeAt(0)) {
                window.open("https://glyphwiki.org/wiki/" + dkw);
            }

            // "<" ">"押下で改行位置変更
            if (e.keyCode != 188 && e.keyCode != 190) return; /* <> */

            var $mbox = $(this).parents(".mbox");
            var $pagebox = $mbox.parent();
            var n = 1 * $pagebox.attr("id").split("p").pop();
            var idx = $pagebox.find(".mbox").index($mbox);
            
            if (e.keyCode == 188) idx++;
            //var c = regs.findIndex(r => r[0] == dkw);
            scanimglist[n].t[idx] = 1 * dkw.split("dkw-").pop();
            //console.log(topnums);
            draw_lines($pagebox);
            if (e.keyCode == 190)
                $mbox.find("select").eq(0).focus();
            if (e.keyCode == 188)
                $mbox.nextAll(".mbox").eq(0).find("select").eq(0).focus();
        }).change(function() {
            //プルダウンの値変更時に"saved"フラグクリア
            var v = $(this).val();
            var $box = $(this).parent().parent();
            $box.removeClass("saved");
            return;
            var dkw = $box.find(".dkw").text();

            if (v == "-") {
                $box.addClass("saved");
                $.get("./cgi/shell.cgi",
                      {name:dkw, origin:"_", ucs:"_", save:"_", memo:"#_"},
                      function(ret) {
                          console.log("saved:" + dkw);
                          //$("#savedone").show();
                      });
                return;
            }

        }).blur(function() {
            //プルダウンの値変更時にセーブ
            var v = $(this).val();
            var $box = $(this).parent().parent();
            var dkw = $box.find(".dkw").text();

            if (v == "-") {
                if ($box.hasClass("retaken")) {
                    $.get("./cgi/shell.cgi",
                          {name:dkw, origin:"_", ucs:"_", save:"_", memo:"#-"},
                          function(ret) {
                              console.log("saved:" + dkw);
                              //$("#savedone").show();
                          });
                }
                $box.removeClass("retaken");
                return;
            }
            if ($box.hasClass("saved")) return;
            $box.addClass("retaken").addClass("saved");

            if (v == "a") {
                var src = ("https://glyphwiki.org/glyph/"  + $(this).next().val() + ".50px.png");
                var $rtk = $box.find("span.retaken");
                if ($rtk.length == 0) $rtk = $("<span class=retaken>").appendTo($box.find(".glyph"));
                kage_draw($(this).next().val(), $rtk);
                $rtk.attr("rglyph", "[["+$(this).next().val()+"]]");

                //$img.attr("src", src);
            }

            var u = $box.find(".ucs").text();
            var $free = $(this).next("input");
            console.log(u, u.codePointAt(0));
            var glyph = function(v) {
                if (v == "k") {
                    return "[[" + $box.find(".koseki").text() + "]]";
                }
                if (v == "u") {
                    return "[[u" + u.codePointAt(0).toString(16) + "]]";
                }
                
                if (v == "a") {
                    return "[[" + $free.val() + "]]";
                }
                if ($box.find("span.retaken").length > 0) {
                    return $box.find("span.retaken").attr("rglyph");
                }

                if ($box.find("img.retaken").length > 0) {
                    return $box.find(".retaken");
                }
                return "_";
            }(v);
            var memo = "#" + v + ":" + $free.val();
            $.get("./cgi/shell.cgi",
                  {name:dkw, origin:"_", ucs:u, save:glyph, memo:memo},
                  function(ret) {
                      console.log("saved:" + dkw, glyph);
                      //$("#savedone").show();
                  });

        });


        $pagebox.find(".check select").change(function() {
            if ($(this).val() == "m" || $(this).val() == "a" || $(this).val() == "ho")
                return $(this).next("input").show();
            $(this).next("input").hide();
        });
        $pagebox.find(".koseki").unbind().dblclick(function() {
            console.log($(this).text(),$(this).text().split(":"));
            var ref = $(this).text().split("(").shift();
            window.open("https://glyphwiki.org/wiki/" + ref);
        });
        $pagebox.find(".dkw").unbind().dblclick(function() {
            var m = $(this).text().match(/dkw\-[0-9dh]+/)
            //window.open("https://glyphwiki.org/wiki/" + m[0]);
            var ref = $(this).text().split(":").shift();
            window.open("https://glyphwiki.org/wiki/" + m[0]);
            //window.open("./gw_edit.htm#" + m[0]);
        });

    };

    // 箱の中身の描画
    var draw_box = function(dkw, $box)
    {
        //return;
        var draw_retaken = function(retaken, $reg) {
            if (!retaken) return;
            //console.log(retaken);
            var $sel = $reg.find("select");
            var $free = $reg.find("input[name=free]");
            var $glyph = $reg.find(".glyph");
            var $rtk = $glyph.find(".retaken");
            //console.log($glyph.size(), $rtk.size());
            
            if (retaken[1]) {
                var rt = retaken[1].split(":");
                $sel.val(rt.shift().split("#").pop());
                $free.val(rt.join(":"));
                if ($sel.val() == "a" || $sel.val() == "m" || $sel.val() == "ho") $free.show();
            }
            if ($sel.val() == "-") return;
            $reg.addClass("retaken").addClass("saved");
            
            if (!$rtk.size()) $rtk = $("<span class=retaken>").prependTo($glyph);
            if (retaken[0].indexOf("[[") == 0) {
                var name = retaken[0].split("[").join("").split("]").join("");
                $free.val(name);
                kage_draw(name, $rtk);
                $rtk.attr("rglyph", name);
                return;
            }
            kage_draw(retaken[0], $rtk);
            $rtk.attr("rglyph", retaken[0]);
        };

	    var is_only_retaken = false;
        var r = mj.find(m => m.d == dkw);
        if (!r) return; 
        var regd = regs[dkw] || {};
        var koseki = r.k;
        var ucs = r.u || "";
        var glyph = ""; // ToDo:p.retaken.datの読取り値
        //var dir = parseInt((parseInt(dkw.substr(4,5), 10) - 1) / 1000);
        //var cat = (regs[dkw][3] || "").split("##done:").pop();
        var tgt = tgts[r.u];
        
        var m = ucs.match(/^u([0-9a-f]+)/);
        var c = (m) ? String.fromCodePoint("0x" + m[1]) : ucs;
        var retaken = regd.retake;

        var $drawn = $("#" + dkw);
        if ($drawn.size()) {
            $drawn.appendTo($box).show();
            draw_retaken(retaken, $drawn);
            return;
        }
        var $reg = $("<div class=reg>").attr("id", dkw).appendTo($box);
        var $dkw = $("<div class=dkw>").appendTo($reg);
        var $koseki = $("<div class=koseki>").appendTo($reg);
        var $glyph = $("<div class=glyph>").appendTo($reg);
        $("<div class=ucs>").text(c).appendTo($reg);
        var $cat = $("<div class=cat>").appendTo($reg);
        var $tgt = $("<div class=tgt>").appendTo($reg);
        var $check = $("<div class=check>").appendTo($reg);
        var $sel = $("<select>").appendTo($check);
        $("<option>").text("-").appendTo($sel);
        $("<option value=k>").text("k").appendTo($sel);
        $("<option value=i>").text("i").appendTo($sel);
        $("<option value=br>").text("br").appendTo($sel);
        $("<option value=u>").text("u").appendTo($sel);
        $("<option value=a>").text("a").appendTo($sel);
        $("<option value=ref>").text("ref").appendTo($sel);
        $("<option value=ho>").text("ho").appendTo($sel);
        $("<option value=m>").text("他").appendTo($sel);
        var $free = $("<input name=free>").appendTo($check).css("width", "50px").hide();

        $dkw.text(dkw);
        $koseki.text((koseki == "none" || koseki == "jmj") ? (ucs + "(" + koseki + ")") : koseki);


        var cat_check = function(dkw, koseki, ucs)
        {
           if (!gdef[dkw]) return "";
            var d0 = gdef[dkw].match(/^99:0:0:0:0:200:200:([^:]+)$/);
            var k0 = (gdef[koseki] || "").match(/^99:0:0:0:0:200:200:([^:]+)$/);

            if (d0 && k0 && d0[1] == k0[1]) return "k";
            if (!k0 && d0 && d0[1] == koseki) return "k";
            if (!d0 && k0 && k0[1] == dkw) return "ok";
            if (!d0) return "o";
            //console.log(dkw,koseki,d0,k0,gdef[dkw],gdef[koseki]);
            return "a:" + d0[1];
        };
        // cat表示
        var cat = (regd.mt || "") + cat_check(dkw, koseki, ucs);

        if (cat.indexOf("k") == 0)
            $cat.addClass("koseki");
        if (cat.indexOf("o") == 0)
            $cat.css("background-color", "#afa").addClass("origin");
        if (cat.indexOf("a") == 0)  {
            var ref = cat.split("a:").pop();
            if (ref == ucs && !koseki)
                cat = "u:" + ref;
            else {
                $cat.css("background-color", "#faa").addClass("alias");
            }
        }
        if(cat) {
            $cat.text(cat);
        }
        if(tgt) {
            $tgt.text(tgt);
        }

        //dkw文字の表示
        var $dglyph = $("<span class=dglyph>").appendTo($glyph);
        if (!is_only_retaken || retaken) kage_draw(dkw, $dglyph);

        //retaken文字の表示
        draw_retaken(retaken, $reg);

        //元になるkosekiまたはucsを表示
        //  dkw-XXXXXと一致するものは表示略
        //  mtnestにより登録されたものは表示略(クリックで元のkosekiまたはucsを表示)
        // --> mtnestのうち kosekiと表現するものを要抽出
        var ref = (koseki == "none" || koseki == "jmj" || koseki == "_") ? ucs.split(":").shift() : koseki;
        var src = ref ;
        if (cat.indexOf("koseki") == 0 || cat.indexOf("mtnest") == 0 || !r.k || (retaken && "[[" + ref + "]]" == retaken[0])) {
            src = "";
        }
        if (src) {
            var $kimage = $("<span class=kglyph>").attr("id", ref).appendTo($glyph);
            if (!is_only_retaken) kage_draw(ref, $kimage);
        }


        // カテゴリの推定
        var guess_k = ($cat.hasClass("alias") && r.k);
        var guess_i = tgt && ($cat.hasClass("alias") || $cat.hasClass("koseki"));

        if (guess_k || guess_i) $cat.css("border","red 1px solid");

        if (true || retaken) return;
        if (guess_k && guess_i) $sel.val("ki");
        else if (guess_k) $sel.val("k");
        else if (guess_i) $sel.val("i");

    };

    $("#search").keydown(function(e) {
        if (e.keyCode != 13) return;
	    var str = $("#search").val();
        $("#" + boxid + " .scan").remove();
        $("#result .box").hide();
        var boxid = "fresult";
        var $box = $("#" + boxid);

        if ($box.size()) {
	        $mbox = $box.show().find(".mbox");
        } else {
	        var $box = $("<div id=" + boxid + " class=box>").appendTo("#result");
	        $mbox = $("<div>").appendTo($box).addClass("mbox");
	    }

        var ret = str.match(/<[^>]+>|[\uD800-\uDBFF][\uDC00-\uDFFF]|[^\uD800-\uDFFF]/g) || [];
        ret.forEach(function(c) {
            console.log(c);
            if (c == "!") {
	            $mbox.text("");
                $box.find(".scan").remove();
	            return;
	        }

	        if (c.match(/^[^!-z]+$/)) { c = "u" + c.codePointAt(0).toString(16); }
            if (c.indexOf("<") == 0) { c = c.substr(1, c.length - 2); }
	        var fs = mjfind(c);
	        if (!fs) return;

            var dkw = function(v) { return "dkw-" + ("0000" + v).substr(-5); };
	        fs.forEach(function(f) {
                var n = scanimglist.findIndex(obj => !obj.t ? false : f.d < dkw(obj.t[0]));
                n = (n == -1) ? (scanimglist.length - 1) : (n - 1);
                if (scanimglist.length <= n + 1) return;
                var i = scanimglist[n].t.findIndex(top => f.d < dkw(top));
                i = (i == -1) ? (scanimglist[n].t.length - 1) : (i - 1);
                draw_scanimg(n, i, $("<div>").appendTo($box));
	            draw_box(f.d, $mbox);
	        });
        })
	    boxevents($mbox);
    });

    $("#rtkfrom").click(function() {
        //if (e.keyCode != 13) return;
	    var ret = Object.keys(regs);
	    ret = ret.filter(dkw => {
	        var rtk = regs[dkw].retake;
	        return rtk && rtk[1] && (rtk[1].indexOf("#-") != 0);
	    }).sort();
	    //var n = $("#rtkfrom").val();
        var boxid = "rtkresult";
        var $box = $("#" + boxid);
        if ($box.size()) {
	    $box.show();
	    return;
        } else {
	        var $box = $("<div id=" + boxid + " class=box>").appendTo("#result");
	    }
        for(var i = 0; i < ret.length / 15; i++) {
	        var $mbox = $("<div>").appendTo($box).addClass("mbox");
            ret.slice(i * 15, (i + 1) * 15)
            .forEach(function(dkw, i) {
                draw_box(dkw, $mbox);
            });
	        boxevents($box);
	    }
    });

    // キーショートカット
    $("body").keydown(function(e){
        //console.log(e);
        if (!e.altKey) return;
        //if ((e.keyCode != 0x5a) &&(e.keyCode != ("X").charCodeAt(0))) return;
        var n = location.href.split("#").pop();
        n = parseInt(n);
        if (isNaN(n)) n = 0;
        if (0 < n && e.keyCode == "Z".charCodeAt(0)) draw(n - 1);
        if (e.keyCode == "X".charCodeAt(0)) draw(n + 1);
        if (e.keyCode == "9".charCodeAt(0))
            $(".box:visible .scan").each(function(i) {
                var $img = $(this).find("img");
                console.log($img.css("width"));
                var width = $img.css("width").split("px").shift() * 1 + 5;
                $img.css("width", width + "px");
                //var rtop = -1 * $img.css("top").split("px").shift() - (i);
                //$img.css("top", -rtop + "px");
            });
        if (e.keyCode == "0".charCodeAt(0))
            $(".box:visible .scan").each(function(i) {
                var $img = $(this).find("img");
                var width = $img.css("width").split("px").shift() - 5;
                console.log(width);
                $img.css("width", width + "px");
                //var rtop = -1 * $img.css("top").split("px").shift() + (i);
                //$img.css("top", -rtop + "px");
            });
        if (e.keyCode == "6".charCodeAt(0))
            $(".box:visible .scan").each(function(i) {
                var $img = $(this).find("img");
                var rtop = -1 * $img.css("top").split("px").shift() - 5;
                $img.css("top", -rtop + "px");
            });
        if (e.keyCode == "5".charCodeAt(0))
            $(".box:visible .scan").each(function(i) {
                var $img = $(this).find("img");
                var rtop = -1 * $img.css("top").split("px").shift() + 5;
                $img.css("top", -rtop + "px");
            });
        if (e.keyCode == "8".charCodeAt(0))
            $(".box:visible .scan").each(function(i) {
                var $img = $(this).find("img");
                var rtop = -1 * $img.css("left").split("px").shift() - 5;
                $img.css("left", -rtop + "px");
            });
        if (e.keyCode == "7".charCodeAt(0))
            $(".box:visible .scan").each(function(i) {
                var $img = $(this).find("img");
                var rtop = -1 * $img.css("left").split("px").shift() + 5;
                $img.css("left", -rtop + "px");
            });
        if (e.keyCode == "R".charCodeAt(0)) redraw(n);

    });
    $("#dumpref").click(function() {
	var ret = "";
	    Object.keys(regs).filter(function(dkw) {
	        if (!regs[dkw].retake) return;
	        var retaken = regs[dkw].retake;
	        if (retaken[1] && retaken[1].indexOf("#ref:") == 0) return;
	        if (!retaken[0]) return;
	        var refs = retaken[0].split("$").map(function(r) {
		        var ps = r.split(":");
		        return (ps[0] == "99" && ps[7].indexOf("dkw-") == 0) ? ps[7] : null;
	        }).filter(a => a);
	        if (refs.length == 0) return;
	        var undefs = refs.filter(function(dkw){
		        if (dkw.indexOf("dkw-h") == 0) return true;
		        if (!regs[dkw]) { console.log(dkw); return false; }
		        var retaken  = regs[dkw].retake;
		        return (retaken && retaken[1] != "#-");
	        });
	        if (undefs.length == 0) return;
	        var m = mjfind(dkw);
	        ret += [
		        dkw + "[" + ucs2c(m[0].u || "") + "]",
		        retaken[0],
		        "#ref:" + (refs).join() + "/" + retaken[1]
	        ].join("\t") + "\n";
	    });
	    $("#retakes").val(ret);
    });
    $("#replist").click(function() {
	    var ret = "";
	    Object.keys(regs).sort().filter(function(dkw) {
	        if (!regs[dkw].retake) return;
	        var retaken = regs[dkw].retake;
                if (!retaken[0]) return;
                if (retaken[0] == "_") return;
	        if (retaken[1]) {
                    if (retaken[1].indexOf("#-:") == 0) return;
	            if (retaken[1].indexOf("#ho:") == 0) return;
	            if (retaken[1].indexOf("#ref:") == 0) return;
                }
	        var m = mjfind(dkw);
            var u = (m.length) ? m[0].u : "";
	        ret += [
		        dkw + "[" + ucs2c(u || "") + "]",
		        retaken[0],
		        retaken[1],
                    (regs[dkw].mt) ? "overwrite" : "",
	        ].join("\t") + "\n";
	    });
	    $("#retakes").val(ret);
    });
    $("#savepage").click(function() {
        var ret = $(".box").each(function() {
            var n = $(this).attr("id");
            var top = $(this).find(".scan").eq(0).find("img").css("top");
            var sec = $(this).find(".scan").eq(1).find("img").css("top");
            top = top.split("px").shift();
            sec = sec.split("px").shift();
            n = parseInt(n.split("p").join(""));
            scanimglist[n].d.top = -top;
            scanimglist[n].d.step = top - sec;
        });

        $("#retakes").val(JSON.stringify(scanimglist));
        
        return;
        var n = location.href.split("#").pop();
        n = parseInt(n);
        if (isNaN(n)) n = 0;
        var $box = $("#" + "p" + n.toString());
        var ret = "";
        $box.find("select").each(function() {
            var v = $(this).val();
            if (v == "-") return;
            var $box = $(this).parent().parent();
            var dkw = $box.find(".dkw").text();
            var koseki = $box.find(".koseki").text();
            var u = $box.find(".ucs").text();
            console.log(u);
            var $free = $(this).next("input");
            var glyph = function(v) {
                if (v == "k") {
                    return "[[" + $box.find(".koseki").text() + "]]";
                }
                if (v == "u") {
                    return "[[u" + u.codePointAt(0).string(16) + "]]";
                }
                if (v == "a") {
                    return "[[" + $free.val() + "]]";
                }

                if ($box.find("span.retaken").length > 0) {
                    return $box.find("span.retaken").attr("rglyph");
                }
                if ($box.find("img.retaken").length > 0) {
                    var glyph = $box.find("img.retaken").attr("src");
                    return glyph.split("https://glyphwiki.org/get_preview_glyph.cgi?data=").join("").split("https://glyphwiki.org/glyph/").join("[[")
                        .split(".50px.png").join("]] #a");
                }
                return "_";
            }(v);
            var memo = "#" + v + ":" + $free.val();
            $.get("./cgi/shell.cgi",
                  {name:dkw, origin:koseki, ucs:u, save:glyph, memo:memo},
                  function(ret) {
                      console.log("saved:" + dkw, glyph);
                      //$("#savedone").show();
                  });
            ret += $box.find(".dkw").text() + " " + glyph + " " + memo + "\n";
        });
        $("#retakes").val(ret);
    });


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
        console.log(def);
        kage_draw(def, $("div#preview").show(), "white");
    });

    var replace = function(q, cs, is_rel) {
        var qrows = q.split("\n").join("$").split("$");

        //1行ずつ見て差替
        var rrows = qrows.map(function(qrow) {

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
        if (cs.length == 0) return;

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
        $.get("./cgi/shell.cgi",
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
            $.get("./cgi/shell.cgi?name=" + c,
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
        if (def) {
            $("#defglyph").val(def.split("$").join("\n")).focus();
            agendadump();
        } else {
            $.get("./cgi/shell.cgi?name=" + c,
              function(def) {
                  if (def.indexOf(":") < 0) return;
                  $("#defglyph").val(def.split("$").join("\n")).focus();
                  agendadump();
              });
        }
        var fs = mjfind(c);
        if (fs.length == 0)  return;
        var $info = $("#info").text("");
        $("<button>").text(fs[0].d).appendTo($info);
        $("<button>").text(fs[0].k).appendTo($info);
        $("<button>").text(fs[0].u + ":" + ucs2c(fs[0].u)).appendTo($info);
        $("<input name=loadglyph>").appendTo($info);
        $("<button>").text("load").appendTo($info);

        $info.find("button").click(function() {
            var c = $(this).text().split(":").shift();
            if (c == "load") c = $("[name=loadglyph]").val();
            $.get("./cgi/shell.cgi?name=" + c,
                  function(def) {
                      if (def.indexOf(":") < 0) return;
                      $("#defglyph").val(def.split("$").join("\n")).focus();
                      agendadump();
                  });
        });
        //console.log(fs[0].split("[").shift());
        $("#savename").val(fs[0].d + ":" + fs[0].k + ":" + fs[0].u);
        $("#undolist").text("");
        $("#editorbox").show();
    };

    $("#editorbox .closebox").click(function() {
        $("#editorbox").hide();
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
        $.get("./cgi/shell.cgi?name=" + c, defhandler);
    };


    page_init();
});
