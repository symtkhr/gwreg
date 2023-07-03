
let DB = {};
{
    DB.regs = {};   // {dkw-%d: {retake: 登録予定データ, mt: "#"(mtnestが登録した場合)}}
    DB.mj = [];     // {d:大漢和番号, k:戸籍統一, u:UCS}のテーブル
    DB.hokans = {}; // {d:大漢和番号, s:画数}のテーブル
    const CGIPATH = "../cgi-bin/shell.cgi";

    DB.load = function(done) {
        // 読込ファイルの一覧
        const loadfiles = [
            {name:"../tables/mji_00502_pickup.txt", handler:mjhandler},
            {name:"../tables/kdbonly.htm.txt", handler:kdbhandler},
            {name:"p.retaken.dat", handler:retakenhandler},
            {name:"p.hokan.dat", handler:hokanhandler},
        ];
        let load = 0;

        let fileload = function(file) {
            $.get(file.name, function(data) {
                load++;
                if (file.handler) file.handler(data, file);
                if (load != loadfiles.length) return fileload(loadfiles[load]);
                done();
            });
        };
        fileload(loadfiles[0]);
    };

    let hokanhandler = function(data) {
        DB.hokans = data.split("\n").map(line => {
            let t = line.split("\t");
            return {d:t[0], s:(1 * t[1])};
        }).sort((a, b) => a.s - b.s);
    };

    let mjhandler = function(data) {
        DB.mj = data.split("\n").map(function(row) {
            var cols = row.split("\t");
            if (cols.length < 3) return {};
            var ret = {};
            ret.d = (d => {
                var d = d.trim().split("補").join("h").split("'").join("d");
                var n = d.match(/\d+/);
                if (!n) return;
                let digit = (d.indexOf("h") < 0) ? 5 : 4;
                return d.split(n[0]).join("0".repeat(digit - n[0].length) + n[0]);
            })(cols[0]);
            ret.k = function(k) {
                if (!k.match(/\d+/)) return;
                return k.split("ksk-").join("koseki-");
            }(cols[1]);
            ret.u = cols[2].toLowerCase().split("+").join("");
            return ret;
        }).concat(DB.mj);
    };

    let kdbhandler = function(data) {
        data.split("\n").forEach(function(line){
            if (line.indexOf(",") != 0) return;
            let ret = {};
            let cols = line.split(",").forEach(function(a) {
                if (a.indexOf("[[dkw-") == 0 && !ret.d)
                    ret.d = a.split("[[").join("").split("]]").join("");
                if (a.indexOf("[[u") == 0)
                    ret.u = a.split("[[").join("").split("]]").join("");
            });
            DB.mj.push(ret);
        });
        DB.mj.sort((a,b) => { if (!a.d) a.d ="x"; if(!b.d) b.d = "x";
                return a.d < b.d ? -1 : 1;});
    };

    let retakenhandler = function(data) {
        let ret = [];
        data.split("\n").forEach(function(line){
            let cols = line.split("\t");
            let dkw = cols.shift();
            //dkw = dkw.match(/dkw[0-9dh-]+/) || dkw.match(/^u[0-9a-z-]+/);
            dkw = dkw.match(/dkw[0-9dh-]+/) || dkw.match(/^u[0-9a-z-]+/)  || dkw.match(/^jmj-[0-9]+/);

            if (!dkw) return;
            dkw = dkw[0];
            if (!DB.regs[dkw]) DB.regs[dkw] = {};
            DB.regs[dkw]["retake"] = cols;
        });
        //console.log(DB.regs["dkw-00003"].retake);
    };

    DB.mjfind = (target) => DB.mj.filter(m => (m.u == target) || (m.k == target) || (m.d == target));
};

let GUI = {};
{

    GUI.init = () => {

        // Prev/Next ボタン
        $("#ui button").click(function() {
            var k = ($(this).attr("id") || "_").slice(-1);
            var e = {key: k.toUpperCase(), altKey:true};
            GUI.scanmove(e);
        });

        // search アンカー
        $("#asearch").click(() => $("#search").show());

        // search ボックス
        $("#search").keydown(function(e) {
            if (e.keyCode != 13) return;
            var str = $("#search").val();
            location.hash = '#search_' + encodeURI(str);
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
                if (c == "!") {
	            $mbox.text("");
                    $box.find(".scan").remove();
	            return;
	        }
                
	        if (c.match(/^[^!-z]+$/)) { c = "u" + c.codePointAt(0).toString(16); }
                if (c[0] == "<") { c = c.slice(1, -1); }
                console.log(c);
	        var fs = DB.mjfind(c);
	        if (!fs) return;
	        fs.forEach(f => GUI.draw_box(f.d, $mbox));
            })
	    GUI.boxevents($mbox);
        });
        // edit ボタン
        $("#retag .editor").click(function() {
            let dkw = $("#retag .dkw").text();
            window.open("actionedit.htm#" + dkw);
        });

        // save ボタン
        $("#retag .save").click(function() {
            //sames as プルダウンの値変更時にセーブ?
            var v = $("#retag select").val();
            var $box = $("#retag");
            var dkw = $("#retag .dkw").text();
	    
            if (v == "-") {
                $.get(CGIPATH,
                      {name:dkw, origin:"_", ucs:"_", save:"_", memo:"#-"},
                      function(ret) {
                          console.log("saved:" + dkw);
                      });
                $(this).prop("disabled", true);
                return;
            }
            var r = DB.mj.find(m => m.d == dkw);
            var ucs = r.u || "";
	    
            var u = r.u;
            //var u = $box.find(".ucs").text();
            var $free = $("#retag input[name=free]");
            var glyph = function(v) {
                var free = $free.val().split("@").shift();
                if (v == "k") {
                    return "[[" + r.k + "]]";
                }
                if (v == "u") {
                    return "[[" + r.u + free + "]]";
                }
                if (v == "a") {
                    return "[[" + free + "]]";
                }
                if ($box.find("span.retaken").length > 0) {
                    return $box.find("span.retaken").attr("rglyph");
                }
                if ($box.find("img.retaken").length > 0) {
                    return $box.find(".retaken");
                }
                return "_";
            }(v);
            var memo = "#" + ((v == "k" || v == "u") ? "a" : v) + ":" + $free.val();
            var dt = new Date();
            memo += "@" + dt.toLocaleString();

            $.get(CGIPATH,
                  {name:dkw, origin:"_", ucs:u, save:glyph, memo:memo},
                  function(ret) {
                      console.log("saved:" + dkw, glyph);
                      //$("#savedone").show();
                  });
        });
        $("#scanfile").css("width", "200px").css("display","inline-box");
    
        GUI.draw();
    };


    // 60グリフ分の描画
    GUI.draw = function(n)
    {
        var p = function(n) {
            if (!n) {
                n = location.hash.slice(1);
            }
            if (n.indexOf("retaken") == 0) {
                GUI.show_retaken(n.split("retaken").pop()); //$("#rtkfrom").click();
                return;
            }
            if (n.indexOf("search") == 0) {
                $('#search').val(decodeURI(n.split('_')[1])).show();
                return;
            }
            let dkw = n;
            if (n.indexOf("dkw-") == 0)
                location.hash = "#" + dkw;

            let nth = DB.mj.findIndex(m => m.d == dkw);
            let page = scancrops.findIndex(v => nth < v.glyphsum[1]);
            return { page:page, nth: nth };
        } (n);
        if (!p) return;

        let $box = $("#result .box");
        let dkw = DB.mj[p.nth].d;
        let boxid = "p" + dkw;
        if ($box.size() == 0) {
            $box = $("<div id=" + boxid + " class=box>").appendTo("#result");
        }
        $box.text("");
        let $mbox = $("<div>").appendTo($box).addClass("mbox");
        let nth = p.nth;
        DB.mj.slice(nth, nth + 60).map(m => GUI.draw_box(m.d, $mbox));
        GUI.boxevents($mbox);
    };
    
    GUI.draw_scanimg = function(dkw, $bar)
    {
        let nth = (dkw.indexOf("h") < 0) ?
            DB.mj.findIndex(m => m.d == dkw) :
            (50306 + DB.hokans.findIndex(h => h.d == dkw));
        let scant =  scancrops.find(v => nth < v.glyphsum[1]);
        const BOXWIDTH = 70;
        if (!scant.src) return;

        let src = scant.src;
        let crop = src.split("crop").pop().split("x").map(v => parseInt(v));
        let rate = BOXWIDTH / crop[0];
        let nth0 = nth - scant.glyphsum[0];

        // 特殊行のある場合
        let row = 0;
        let rowhead = 0;
         [row, rowhead] = scant.v.reduce((sum,v,i,self) => {
             if (isNaN(sum)) return sum;
             if (nth0 < sum + 17 - v) return ["r" + i, sum];
             return sum + 17 - v;
        }, 0);
        if (scant[row]) {
            nth0 -= rowhead;
            src = scant[row];
            if (!isNaN(src)) src = scant["r" + src];
        }

        let top = parseInt(nth0 / 20) * crop[1] * rate;
        let left = nth0 % 20 * BOXWIDTH;

        $bar.css({"position": "relative", "overflow":"hidden"});
        let $img = $("<img>").attr("src", "../scancrop/" + src).appendTo($bar);
        $img.css({"top": -top + "px",
                  "left":-left + "px",
                  "position":"absolute",
                  "width": (BOXWIDTH*20) +"px",
                  "height":"auto"});
    };


    // 箱の中身の描画
    GUI.draw_box = function(dkw, $box)
    {
        var r = DB.mj.find(m => m.d == dkw) || {};
        //if (!r) return;
        var regd = DB.regs[dkw] || {};
        var koseki = r.k || "";
        var ucs = r.u || "";
        //var dir = parseInt((parseInt(dkw.substr(4,5), 10) - 1) / 1000);
        //var cat = (DB.regs[dkw][3] || "").split("##done:").pop();
        
        var m = ucs.match(/^u([0-9a-f]+)/);
        var c = (m) ? String.fromCodePoint("0x" + m[1]) : ucs;
        var retaken = regd.retake;

        //retaken文字の表示
        var draw_retaken = function(retaken, $reg) {
            if (!retaken) return;
            //console.log(retaken);
            var $sel = $reg.find("select");
            var $free = $reg.find("input[name=free]");
            var $glyph = $reg.find(".lglyph");
            var $rtk = $glyph.find(".retaken");
            //console.log($glyph.size(), $rtk.size());
            
            if (retaken[1]) {
                var rt = retaken[1].split(":");
                $sel.val(rt.shift().split("#").pop());
                $free.val(rt.join(":"));
                //if ($sel.val() == "a" || $sel.val() == "m" || $sel.val() == "ho") $free.show();
            }
            if ($sel.val() == "-") return;
            $reg.addClass("retaken").addClass("saved");
            if ($sel.val() == "sc") $reg.css('background-color', '#6f6');
            if ($sel.val() == "ho") $reg.css('background-color', '#f9f');
            if ($sel.val() == "ref") $reg.css('background-color', '#f9f');
            
            if (!$rtk.size()) $rtk = $("<span class=retaken>").prependTo($glyph);
            if (retaken[0].indexOf("[[") == 0) {
                var name = retaken[0].split("[").join("").split("]").join("");
                $free.val(name);
                GUI.kage_draw(name, $rtk);
                $rtk.attr("rglyph", name);
                return;
            }
            if (retaken[0].indexOf('$') != -1)
                GUI.kage_draw(retaken[0], $rtk);
            else if ($sel.val() != 'sc' && $sel.val() != 'jmj' && $sel.val() != 'ref')
                $rtk.css('background-color', '#f55');
            else
                $rtk.css('background-color', '#ddd');
            $rtk.attr("rglyph", retaken[0]);
        };

        var $drawn = $("#" + dkw);
        if ($drawn.size()) {
            $drawn.appendTo($box).show();
            draw_retaken(retaken, $drawn);
            return;
        }

        `{box: {reg: {dkw} {glyph: {dglyph}{retaken}{oglyph}} {ucs} {check} {koseki} } } }`
        let $reg = $("<div class=reg>").attr("id", dkw).appendTo($box).css({"height":"120px", "width":"122px"});
        let $dkw = $("<div class=dkw>").appendTo($reg);
        let $glyph = $("<div class=glyph>").appendTo($reg).css("height","110px").css("width","122px")//.css("display","block")
            //.css("border","1px solid gray");
        $("<div class=ucs>").text(c).appendTo($reg).hide();
        let $check = $("<div class=check>").appendTo($reg);
        let $sel = $("<select>").appendTo($check);
        $("<option>").text("-").appendTo($sel);
        $("<option value=k>").text("k").appendTo($sel);
        $("<option value=u>").text("u").appendTo($sel);
        $("<option value=a>").text("a").appendTo($sel);
        $("<option value=sc>").text("sc").appendTo($sel);
        $("<option value=jmj>").text("jmj").appendTo($sel);
        $("<option value=ref>").text("ref").appendTo($sel);
        $("<option value=ho>").text("ho").appendTo($sel);
        $("<option value=m>").text("他").appendTo($sel);
        var $free = $("<input name=free>").appendTo($check).css("width", "50px").hide();

        $dkw.text(dkw);
	var $koseki = $("<div class=koseki>").appendTo($reg).text(koseki).hide();
        if (!retaken) $check.hide();
        
        //dkw文字の表示
        let $lglyph = $("<div class=lglyph>").appendTo($glyph);
        var $dglyph = $("<span class=dglyph>").appendTo($lglyph);
	GUI.kage_draw(dkw, $dglyph);

        // スキャン画像
        let $oglyph = $("<span class=oglyph>").appendTo($glyph)
        GUI.draw_scanimg(dkw, $oglyph);
        $oglyph.css({"width":"70px","height":"100px", "border":"1px solid green", "overflow":"hidden","position":"relative"})
            .removeClass("scan");
      
        draw_retaken(retaken, $reg);
    };


    GUI.boxevents = function($pagebox) {
        $pagebox.find(".reg").unbind().click(function() {
            var $dkw = $(this).find(".dkw");
            var $box = $(this);

            $(this).find(".dkw a").focus();
            $("#retag select").val($(this).find("select").val());
            $("#retag input[name=free]").val($(this).find("input[name=free]").val());
            $("#retag .dkw").text($dkw.text());
            $("#retag .save").prop("disabled", false);
            $("#scanfile").text($box.find(".oglyph img").attr("src").split("/").slice(-1));
            //GUI.draw_scanimg($dkw.text(), $scan);
            return;

        });
        $pagebox.find(".check select").unbind().change(function() {
            //プルダウンの値変更時に"saved"フラグクリア
            var v = $(this).val();
            var $box = $(this).parent().parent();
            $box.removeClass("saved");

            return;

            var dkw = $box.find(".dkw").text();

            if (v == "-") {
                $box.addClass("saved");
                $.get(CGIPATH,
                      {name:dkw, origin:"_", ucs:"_", save:"_", memo:"#_"},
                      function(ret) {
                          console.log("saved:" + dkw);
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
                    $.get(CGIPATH,
                          {name:dkw, origin:"_", ucs:"_", save:"_", memo:"#-"},
                          function(ret) {
                              console.log("saved:" + dkw);
                              //$("#savedone").show();
                          });
                }
                $(this).prop("disabled", true);
                $box.removeClass("retaken");
                return;
            }
            if ($box.hasClass("saved")) return;
            $box.addClass("retaken").addClass("saved");

            if (v == "a") {
                var src = ("https://glyphwiki.org/glyph/"  + $(this).next().val() + ".50px.png");
                var $rtk = $box.find("span.retaken");
                if ($rtk.length == 0) $rtk = $("<span class=retaken>").appendTo($box.find(".glyph"));
                GUI.kage_draw($(this).next().val(), $rtk);
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
            var dt = new Date();
            memo += "@" + dt.toLocaleString();

            $.get(CGIPATH,
                  {name:dkw, origin:"_", ucs:u, save:glyph, memo:memo},
                  function(ret) {
                      console.log("saved:" + dkw, glyph);
                      //$("#savedone").show();
                  });

        }).prop("disabled", true);

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
        }).keydown(function(e){
            GUI.scanmove(e);
            // Q押下でpulldown enable
            if (e.key.toUpperCase() == "Q") 
                $(this).parent().find(".check").show().find("select").prop("disabled", false).focus();
            // .押下でクリックと同じ
            if (e.key == ".")
                $(this).click();
        }).each(function(){
            var dkw = $(this).text();
            var m = dkw.match(/dkw\-[0-9dh]+/) || dkw.match(/^u[0-9a-f]+/);
            var ref = $(this).text().split(":").shift();
            $(this).html(
                '<a target="_blank" href="https://glyphwiki.org/wiki/' + m[0] + '">' + $(this).text() + "</a>");
            //$("a").text($(this).text()).attr("href", "https://glyphwiki.org/wiki/" + m[0]).appendTo(this);
        });
    };
    
    GUI.redraw = function(n)
    {
        var file = {name:"p.retaken.dat", handler:retakenhandler};
        $.get(file.name, function(data) {
            if (file.handler) file.handler(data, file);
            //console.log(DB.regs["dkw-00003"].retake);
            location.href = "#" + n.toString();
            var $box = $("#" + "p" + n.toString());
            draw();
        });
    };


    GUI.kage_draw = function(q, $img, fill) {
        $img.text("");
        if (q.indexOf(":") < 0) {
            $("<img>").appendTo($img).attr("src",
                                           "http://glyphwiki.org/glyph/" + q + ".svg")
                .css("width","100%");
            return;
        }
        $("<img>").appendTo($img).attr("src",
                                       "http://glyphwiki.org/get_preview_glyph.cgi?data=" + q)
            .css("width","100%");
        return;
    };


    GUI.show_retaken = function(n) {
        let ret = Object.keys(DB.regs).filter(dkw => {
            let rtk = DB.regs[dkw].retake;
            return rtk && rtk[1] && (rtk[1].indexOf("#-") != 0);
	}).sort();

	//var n = $("#rtkfrom").val();
        var boxid = "rtkresult";
        var $box = $("#" + boxid);
        if (!$box.size()) {
            $box = $("<div id=" + boxid + " class=box>").appendTo("#result");
	}
	$box.text("");
        let $mbox = $("<div>").appendTo($box).addClass("mbox");
        let i = parseInt(n) || 0;
        ret.slice(i * 60, (i + 1) * 60).forEach(dkw => GUI.draw_box(dkw, $mbox));
        GUI.boxevents($box);
    };

    /*
    $("body").keydown(function(e){

        if (0 < n && e.keyCode == "Z".charCodeAt(0)) GUI.scanmove(e);
        if (e.keyCode == "X".charCodeAt(0)) GUI.draw(n + 1);
    });
    */

    // キーショートカット
    GUI.scanmove = function(e){
        
        if (!e.altKey) return;

        let key = e.key.toUpperCase();
        if (key == "R") GUI.redraw(n);

        // Previous Page
        if (key == "Z") {
            if (location.href.indexOf("#retaken") > 0) {
                var n = location.href.split("#retaken").pop();
                n = parseInt(n) || 0;
                location.hash = "#retaken" + (n<1 ? 0:n-1);
                GUI.draw();
                return;
            }
            let dkw = $(".box:visible .mbox .reg .dkw").eq(0).text();
            let nth = DB.mj.findIndex(m => m.d == dkw) || {};
            let dkwprev = (DB.mj[nth - 60] || DB.mj.slice(-60)[0]).d;
            $("#search").val("<" + dkwprev + ">");
            return GUI.draw(dkwprev);
        }

        // Next Page
        if (key == "X") {
            if (location.href.indexOf("#retaken") > 0) {
                var n = location.href.split("#retaken").pop();
                n = parseInt(n) || 0;
                location.href = "#retaken" + (n+1);
                GUI.draw();
                return;
            }
            var dkw = $(".box:visible .mbox:last-child .reg:last-child .dkw").text();
            let nth = DB.mj.findIndex(m => m.d == dkw) || {};
            let dkwnext = (DB.mj[nth + 1] || DB.mj[0]).d;
            $("#search").val("<" + dkwnext + ">");
            return GUI.draw(dkwnext);
        }

	// 拡大
	if ("567890".indexOf(key) != -1) {
            let dkw = $(".box:visible .dkw:focus").text() || $("#retag .dkw").text();
            var $img = $("#" + dkw).find(".oglyph img");

            let imgaction = (key) => {
                if (key == "5") {
                    var rtop = -1 * $img.css("top").split("px").shift() + 5;
                    $img.css("top", -rtop + "px");
                    return rtop;
                }
                if (key == "6") {
                    var rtop = -1 * $img.css("top").split("px").shift() - 5;
                    $img.css("top", -rtop + "px");
                    return rtop;
                }

                if (key == "7") {
                    var rtop = -1 * $img.css("left").split("px").shift() + 5;
                    $img.css("left", -rtop + "px");
                    return rtop;
                }
                if (key == "8") {
                    var rtop = -1 * $img.css("left").split("px").shift() - 5;
                    $img.css("left", -rtop + "px");
                    return rtop;
                }
                if (key == "9") {
                    var width = $img.css("width").split("px").shift() * 1 + 50;
                    $img.css("width", width + "px");
                    return width;
                }
                if (key == "0") {
                    var width = $img.css("width").split("px").shift() - 50;
                    $img.css("width", width + "px");
                    return width;
                }
            };
            $("#scanfile").text(imgaction(key));
        }
    };
};

$(function() {
    $.ajaxSetup({ cache: false });
    DB.load(GUI.init);
});
