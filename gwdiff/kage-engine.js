var gdef = {};
var kage_draw = function(q, $img, fill, islocal) {
    $img.text("");
    if(true){
    if (q.indexOf(":") < 0) {
        $("<img>").appendTo($img).attr("src",
                                       "http://glyphwiki.org/glyph/" + q + ".svg")
            .css("width","100%");
        return;
    }
    if (!islocal) {
        $("<img>").appendTo($img).attr("src",
                                       "http://glyphwiki.org/get_preview_glyph.cgi?data=" + q)            .css("width","100%");
        return;
    }
    }
    if (q.indexOf(":") < 0) q = "99:0:0:0:0:200:200:" + q;
    

    // kageオブジェクトの作成
    var kage = new Kage();
    kage.kUseCurve = false;
    kage.kBuhin.push("sandbox", q);
    //console.log(q);
    var draw = function(kage) {
        //console.log(kage.kBuhin);
        // ポリゴンの作成
        var polygons = new Polygons();
        kage.makeGlyph(polygons, "sandbox");
        $img.html(polygons.generateSVG(false));
        var color = (fill) ? fill : "black"
        $img.find("g").attr("fill", color);
    };

    // 参照オブジェクトの取得
    {
        var needed = 0;
        var loaded = 0;
        
        var get_refglyphs = function(q) {
            var agenda = q.split("$").map(function(row) {
                var r = row.split(":");
                return (r[0] == "99") ? r[7] : undefined;
            }).filter(a => a);
            
            needed += agenda.length;
            if (needed == 0)
                draw(kage);
            
            agenda.forEach(function(gname) {
                if (gdef[gname]) {
                    q = gdef[gname];
                    kage.kBuhin.push(gname, q);
                    loaded++;
                    get_refglyphs(q);
                    if (loaded == needed) draw(kage);
                    return;
                }
                $.get("./cgi/shell.cgi", {name: gname},
                      function(q) {
                          q = q.trim();
                          kage.kBuhin.push(gname, q);
                          gdef[gname] = q;
                          loaded++;
                          get_refglyphs(q);
                          if (loaded == needed) draw(kage);
                      });
            });
        };
        
        get_refglyphs(q);
    }
};
