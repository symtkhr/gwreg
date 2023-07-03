require "stringadd"

local execcmd = function(command)
   local handle = io.popen(command, "r")
   local content = handle:read("*all")
   handle:close()
   return content
end

local help = function()
   print (" # " .. arg[0] .. " [mode] [start] [end]");
   print ("");
   print (" [mode] ");
   print ("  - dump: Only dump");
   print ();
   print (" [start][end]");
   print ("  - mj1_ishii.txt entry");
   print ("  (replace parts from using p.original.dat)");
   print ();
end


--[[ 
<<変換テーブルの縮尺変更>>
 adj=30〜100の場合、
   0   30        100                200
   +----+----------+-----------------+
   20   p          q                70
   p = 20 + (50 * 30/200) = 27.5, q = 20 + (50 * 100/200) = 45
   p = x0 + (x1-x0) * X0/200, q = x0 + (x1-x0) * X1/200
]]

--変換テーブル
local reptable = {
   --"日"
   {"u65e5",  "dkw-13733"}, -- 不要(だが入れておく)
   {"u65e5-j",  "dkw-13733"}, -- 不要
   {"u65e5-01",  "u65e5-01-var-001"},
   {"u65e5-03",  "u65e5-03-var-001"},
   {"u65e5-04",  "u65e5-04-var-001"},
   --"白"
   {"u767d", "u767d-var-003" },
   {"u767d-07", "u767d-var-003" },
   {"u767d-01", "u767d-01-var-001" },
   {"u767d-03", "u767d-03-var-002" },
   {"u767d-04", "u767d-var-003", y = {100, 200}},
   --"目"
   {"u76ee", "dkw-23105" }, -- 不要
   {"u76ee-01", "u76ee-01-var-001", x = {-5, 200} },
   {"u76ee-02", "dkw-23105", x = {81, 200}},
   --"自"
   {"u81ea", "dkw-30095"}, -- 不要
   {"u81ea-g03", "dkw-30095"}, -- 不要
    {"u81ea-07",  "dkw-30095"},
    {"u81ea-03",  "u81ea-03-var-002"},
    {"u81ea-02",  "dkw-30095", x = {60, 205}},
    {"u81ea-01",  "dkw-30095", x = {0, 105}, y = {0, 190}},
   --"門"
    {"u9580-05", "u9580-05-var-001"},
    {"u9580", "u9580-var-001"},
    {"u9580-10", "u9580-10-var-002"}, --(要作成)
    {"u9580-10-var-001", "u9580-10-var-003"}, --(要作成)
   --"貝"
    {"u8c9d", "dkw-36656"}, -- 不要
    {"u8c9d-01", "u8c9d-01-var-001" },
    {"u8c9d-02", "dkw-36656", x = {80,200}},
    {"u8c9d-04", "u8c9d-04-var-001"},
    --{"u8c9d-07", nil},
   --"頁"
    {"u9801-02-var-001", "u9801-02-var-002" },
    {"u9801-02",         "u9801-02-var-002", x = {-30, 200}}, -- 幅を15%広げる
    {"u9801-var-001",    "u9801-var-002"},
    {"u9801", "u9801-var-002"},
    {"u9801-03", "u9801-var-002", y = {0, 125}},
    {"u9801-04", "u9801-var-002", y = {60, 200}},
    --{"u9801-09"},
   --"耳"
    {"u8033-01", "u8033-01-var-001", x = {0, 220}},
    {"u8033-14", "u8033-14-var-002"},
    {"u8033-14-var-001", "u8033-14-var-002"},
    {"u8033-j",  "dkw-28999"}, -- 不要
    {"u8033-02", "dkw-28999", x = {70, 205}, y = {-10, 200}},
    --{"u8033-07", nil},
   --"身"
    {"u8eab-01", "u8eab-01-var-001"},
    {"u8eab-02", "u8eab-02-var-001" },
    {"u8eab", "dkw-38034"}, --要作成
   --"其"
    {"u5176-01", "u5176-01-var-001", x= {0, 230}},
    {"u5176-02", "u5176-02-var-001", x={-25, 200}},
    {"u5176-03", "u5176-03-var-004", y={0,182}},
    {"u5176-03-var-001","u5176-03-var-004", y={0,182}},
    {"u5176",    "dkw-01472"}, -- 不要
   --"見"
    {"u898b", "dkw-34796"}, -- 不要
    {"u898b-02", "u898b-02-var-001", x = {-20, 200}},
    {"u898b-04", "dkw-34796", y = {60, 200}},
   --"且"
    {"u4e14-01", "u4e14-01-var-001"},
    {"u4e14-02", "u4e14-02-var-001", x = {-14, 200}},
    {"u4e14", "dkw-00029"}, -- 不要
   --"酉"
    {"u9149-j",         "dkw-39763"}, -- 不要
    {"u9149",           "dkw-39763"}, -- 不要
    {"u9149-01",         "u9149-01-var-001"},
    {"u9149-01-var-005", "u9149-01-var-001"},
    {"u9149-04",         "u9149-04-var-003"},
    {"u9149-03",         "dkw-39763", y = {10, 120}},
   --"甘"
    {"u7518", "dkw-21643"}, -- 不要
    {"u7518-03", "dkw-21643", y = {0, 100}},
    {"u7518-04", "dkw-21643", y = {95, 200}},
    {"u7518-08", "dkw-21643", x = {30, 170}},
   --"示" のうち、旁にあたるもの
    {"u793a", "u793a-t"},
    {"u793a-02", "u793a-var-002", x = {70, 200}},
    {"u793a-04", "u793a-t04"},
    {"u793a-14", "u793a-t14"},
    --音
    {"u97f3", "u97f3-var-002"}, -- 要作成
    {"u97f3-j", "u97f3-var-002"}, -- 要作成
    {"u97f3-07", "u97f3-var-002"}, -- 要作成
    --{"u97f3-14", "u97f3-var-002", y = {68, 200}}, -- 要作成
    {"u97f3-01", "u97f3-01-var-002"},
    {"u97f3-02", "u97f3-02-var-003"},
    {"u97f3-02-var-001", "u97f3-02-var-002"},

-- 定義済み
    {"u3afa-var-001", "u3afa-var-002"},
    {"u51a5-02", "u51a5-02-var-002"},
    {"u533d-02", "u533d-02-var-001"},
    {"u590b-02", "u590b-02-var-001"},
    {"u590b-02-var-005", "u590b-02-var-001"},
    {"u590c-02-var-002", "u590c-02-var-001"},
    {"u914b", "u914b-var-001"},

    {"u590d-02","u590d-02-var-003"},
    {"u590d-02-var-001","u590d-02-var-003"},
{"u52a9-07","dkw-02313"}, -- 助
{"u5353-07","dkw-02741"}, -- 卓
{"u65e6-07-var-001","dkw-13734"}, -- 旦
{"u65ec-07","dkw-13746"}, -- 旬
{"u6614-07","dkw-13816"}, -- 昔
{"u66b4-07","dkw-14137"}, -- 暴
{"u6c93-07","dkw-17206"}, -- 沓
{"u752b-07","dkw-21706"}, -- 甫
{"u752c-07","dkw-21707"}, -- 甬
{"u767d-07-var-002","dkw-22678"}, -- 白
{"u767e-07","dkw-22679"}, -- 百
{"u7687-07","dkw-22701"}, -- 皇
{"u76f4-07","dkw-23136"}, -- 直
{"u8c9d-07","dkw-36656"}, -- 貝
{"u8cab-07","dkw-36681"}, -- 貫
{"u8cac-07","dkw-36682"}, -- 責
{"u25950-var-001","dkw-25474"}, -- 𥥐
{"u25a2a-var-001","dkw-25688"}, -- 𥨪
{"u263a7-var-001","dkw-28535"}, -- 𦎧
{"u26cdd-ue0102","dkw-31423"}, -- 𦳝
{"u27da0-var-001","dkw-36824"}, -- 𧶠
{"u3686-var-001","dkw-05717"}, -- 㚆
{"u3ad0-ja","dkw-13741"}, -- 㫐
{"u3b1c-var-001","dkw-14164"}, -- 㬜
{"u4165-ja","dkw-25172"}, -- 䅥
{"u44a4-var-001","dkw-30754"}, -- 䒤
{"u49a7-var-002","dkw-41405"}, -- 䦧
{"u5099-g","dkw-00967"}, -- 備
{"u5192-ue0103","dkw-01538"}, -- 冒
{"u51a5-var-001","dkw-01588"}, -- 冥
{"u51a5-var-002","dkw-01588"}, -- 冥
{"u52c7-g","dkw-02360"}, -- 勇
{"u52c7-ue0101","dkw-02360"}, -- 勇
{"u53a6-var-001","dkw-02993"}, -- 厦
{"u53b2-var-001","dkw-03041"}, -- 厲
{"u53d6-g","dkw-03158"}, -- 取
{"u53d6-t","dkw-03158"}, -- 取
--{"u53d6-itaiji-001","dkw-03158"}, -- 取
{"u54a0-var-001","dkw-03527"}, -- 咠
{"u590b-var-004","dkw-05711"}, -- 夋
{"u590c-g","dkw-05714"}, -- 夌
{"u5bbf-var-001","dkw-07195"}, -- 宿
{"u5c03-t","dkw-07433"}, -- 尃
{"u5c0a-ue0102","dkw-07445"}, -- 尊
{"u5e1b-t","dkw-08855"}, -- 帛
{"u5e55-ue0102","dkw-09051"}, -- 幕
{"u5ef4-var-001","dkw-09566"}, -- 廴
{"u5f2d-ue0101","dkw-09768"}, -- 弭
{"u5fa5-var-001","dkw-10170"}, -- 徥
{"u6220-var-002","dkw-11615"}, -- 戠
{"u64ae-var-001","dkw-12748"}, -- 撮
{"u6577-ue0103","dkw-13359"}, -- 敷
{"u658a-var-001","dkw-13459"}, -- 斊
{"u658a-var-003","dkw-13459"}, -- 斊
{"u6643-var-001","dkw-13891"}, -- 晃
{"u666f-v","dkw-13983"}, -- 景
{"u66c7-var-001","dkw-14172"}, -- 曇
{"u66e9-var-001","dkw-14258"}, -- 曩
{"u6700-t","dkw-01597"}, -- 最
{"u6714-var-001","dkw-14359"}, -- 朔
{"u671d-ue0101","dkw-14374"}, -- 朝
{"u6772-var-001","dkw-14500"}, -- 杲
{"u67d0-g","dkw-14618"}, -- 某
{"u696c-var-002","dkw-15169"}, -- 楬
{"u6b47-ue0100","dkw-16141"}, -- 歇
--
{"u7683-g","dkw-22686"}, -- 皃
{"u7683-var-001","dkw-22686"}, -- 皃
{"u7690-var-003","dkw-22727"}, -- 皐
{"u7693-ue0101","dkw-22732"}, -- 皓
{"u76f4-var-004","dkw-23136"}, -- 直
{"u76fe-var-001","dkw-23171"}, -- 盾
{"u76fe-var-002","dkw-23171"}, -- 盾
{"u76fe-var-003","dkw-23171"}, -- 盾
{"u773d-var-001","dkw-23320"}, -- 眽
{"u7aae-ue0101","dkw-25593"}, -- 窮
{"u7b97-g","dkw-26146"}, -- 算
{"u7c3f-k","dkw-26623"}, -- 簿
{"u7c3f-ue0103","dkw-26623"}, -- 簿
{"u7fd2-k","dkw-28672"}, -- 習
{"u7fd2-ue0103","dkw-28672"}, -- 習
{"u7fd2-var-001","dkw-28672"}, -- 習
{"u7fd2-var-004","dkw-28672"}, -- 習
{"u8024-g","dkw-28945"}, -- 耤
{"u8033-g","dkw-28999"}, -- 耳
{"u8033-var-001","dkw-28999"}, -- 耳
{"u8033-var-002","dkw-28999"}, -- 耳
{"u8056-ue0103","dkw-29074"}, -- 聖
{"u8076-k","dkw-29179"}, -- 聶
{"u8076-ue0101","dkw-29179"}, -- 聶
{"u8076-var-001","dkw-29179"}, -- 聶
{"u8340-var-001","dkw-30929"}, -- 荀
{"u8349-var-001","dkw-30945"}, -- 草
{"u83ab-ue0102","dkw-31078"}, -- 莫
{"u83ab-var-001","dkw-31078"}, -- 莫
{"u842c-var-001","dkw-31339"}, -- 萬
{"u8457-ue0103","dkw-31410"}, -- 著
{"u845b-ue0108","dkw-31420"}, -- 葛
{"u845b-var-001","dkw-31420"}, -- 葛
{"u84a6-ue0103","dkw-31582"}, -- 蒦
{"u84aa-ue0102","dkw-31594"}, -- 蒪
{"u8513-ue0102","dkw-31784"}, -- 蔓
{"u8584-ue0103","dkw32083"}, -- 薄
{"u862d-ue0103","dkw-32519"}, -- 蘭
{"u8658-var-001","dkw-32701"}, -- 虘
{"u898b-g","dkw-34796"}, -- 見
{"u8ca0-ue0102","dkw-36660"}, -- 負
{"u8ca7-var-001","dkw-36677"}, -- 貧
{"u8cca-ue0102","dkw-36759"}, -- 賊
{"u8eab-g","dkw-38034"}, -- 身
{"u901a-ue0101","dkw-38892"}, -- 通
{"u9053-k","dkw-39010"}, -- 道
{"u9149-var-002","dkw-39763"}, -- 酉
{"u9589-var-001","dkw-41222"}, -- 閉
{"u959e-var-001","dkw-41282"}, -- 閞
{"u95b1-var-001","dkw-41341"}, -- 閱
{"u9801-g","dkw-43333"}, -- 頁
{"u983b-var-001","dkw-43519"}, -- 頻
{"u9f3b-g","dkw-48498"}, -- 鼻
{"u90f7-ue0101","dkw-39571"}, -- 郷 
{"u6701-itaiji-001","dkw-14302"}, -- 朁

{"u590c-01","u590c-01-var-001"}, -- 夌
{"u6708-01","u6708-01-var-003"}, -- 月
{"u8033-g01","u8033-01-var-001"}, -- 耳
{"u9ed1-01","u9ed1-01-var-001"}, -- 黑
{"u590c-02","u590c-02-var-001"}, -- 夌
{"u5c03-02","u5c03-02-var-002"}, -- 尃
{"u66fc-02","u66fc-02-var-001"}, -- 曼
{"u6708-02-var-001","u6708-02-var-002"}, -- 月
{"u79ba-02","u79ba-02-var-001"}, -- 禺
{"u79bb-02-var-003","u79bb-02-var-002"}, -- 离
{"u79bb-02","u79bb-02-var-001"}, -- 离
{"u79bd-02","u79bd-02-var-001"}, -- 禽
{"u9149-g01","u9149-01-var-001"}, -- 酉
{"u914b-02","u914b-02-var-001"}, -- 酋
{"u9801-02-var-003","u9801-var-002"}, -- 頁
{"u9801-02-var-004","u9801-var-002"}, -- 頁
{"u752b-03","u752b-03-var-002"}, -- 甫
{"u8279-03","ufa5e-03"}, -- 艹
{"u590a-t04","u590a-04"}, -- 夊
{"u5902-06","u590a-var-001"}, -- 夂
{"u7528-06","u7528-06-var-001"}, -- 用
{"u9fba","u9fba-var-008"}, -- 龺
{"aj1-13642", "dkw-39134"}, -- 遺
{"aj1-13774", "dkw-36885"}, -- 購
{"aj1-13797", "dkw-36750"}, -- 資
{"aj1-13817", "dkw-28672"}, -- 習
{"aj1-13939", "dkw-38892"}, -- 通
{"aj1-13945", "dkw-22692"}, -- 的
{"aj1-13976", "dkw-02761"}, -- 博
{"aj1-13993", "dkw-48498"}, -- 鼻
{"aj1-14057", "dkw-23132"}, -- 盲
{"aj1-14112", "dkw-14298"}, -- 曼

{"j78-4e4b", "dkw-39137"}, --遼	
{"j83-3468", "dkw-43374"}, --頑	
{"j83-4852", "dkw-43378"}, --頒	
{"j83-494f", "dkw-36677"}, --貧	
{"j83-5a70", "dkw-13950"}, --晟	
{"j83-6663", "dkw-29179"}, --聶	
{"j90-632e", "dkw-24674"}, --祟	
{"jsp-4f34", "dkw-23653"}, --瞢	
{"juki-b20a", "dkw-12351"}, --揖	
{"juki-b6c9", "dkw-24666"}, --祘	
{"juki-b9d0", "dkw-31146"}, --菆	
{"juki-baed", "dkw-33694"}, --蠆	
{"juki-bbc9", "dkw-36788"}, --賓	
{"juki-bc0a", "dkw-07434"}, --射	
{"sawn-f4100", "dkw-17874"}, --湯	
{"u24c07-02","u24c07-02-var-004"},

{"u5b97-01", "dkw-07106", x = { 6.00, 124}, y = { 0,200}},
{"u65e8-01", "dkw-13738", x = {0, 115.79}, y = { 0,200}},
{"u65ec-01", "dkw-13746", x = {0, 100}, y = { 0,200}},
{"u6613-01", "dkw-13814", x = {-6.82, 131.82}, y = { 0,200}},
{"u795f-01", "dkw-24674", x = {12.06, 106.53}, y = {0,200}},
{"u7968-01", "dkw-24694", x = { 6.00, 109}, y = { 0,200}},
{"u8ccf-01", "dkw-36779", x = { 3.98, 136.32}, y = { 5.00,200}},
{"ufa64-01", "dkw-36788", x = { 8.00, 110}, y = { 0,200}},
{"u20057-02", "dkw-49012", x = {65.96, 198.94}, y = {0,200}},
{"u21b3d-02", "dkw-07456", x = {60, 194.44}, y = { 0,200}},
{"u24f56-02", "dkw-22708", x = {67.39, 202.17}, y = { 5,200}},
{"u2a277-02-var-001", "dkw-47562", x = {77.33, 202.67}, y = {5,200}},
{"u2a277-02", "dkw-47562", x = {85.33, 189.33}, y = {5,200}},
{"u3ad0-02", "dkw-13741", x = {69.77, 202.79}, y = { 0,200}},
{"u3fe1-02", "dkw-22730", x = {80, 197}, y = { 0,200}},
{"u4e98-02", "dkw-00262", x = {73.94, 204.85}, y = { 0,200}},
{"u5247-02", "dkw-01994", x = {73.51, 195.68}, y = { 0,200}},
{"u52d8-02", "dkw-02393", x = {59.41, 193.07}, y = { 0,200}},
{"u54e1-02", "dkw-03633", x = {65.31, 208}},
{"u599f-02", "dkw-06099", x = {40, 204}, y = { 0,200}},
{"u5b9c-02", "dkw-07111", x = {81.00, 191}, y = { 0,200}},
{"u5ba3-02", "dkw-07132", x = {74.26, 195}, y = { 0,200}},
{"u5d07-02", "dkw-08152", x = {68.00, 194}, y = { 0,200}},
{"u6182-02", "dkw-11170", x = {67.00, 192}, y = { 0,200}},
{"u6577-02-var-001", "dkw-13359", x = {43.75, 200}, y = { 0,200}},
{"u65e6-02", "dkw-13734", x = {82.22, 200}, y = {0,200}},
{"u65e8-02", "dkw-13738", x = {88, 197.89}, y = {5,200}},
{"u65ec-02", "dkw-13746", x = {80, 200}, y = {5,200}},
{"u6613-02", "dkw-13814", x = {70.45, 200}, y = { 0,200}},
{"u661c-02", "dkw-13832", x = {61.29, 200}, y = { 0,200}},
{"u662f-02-var-001", "dkw-13859", x = {72.63, 198.95}, y = { 0,200}},
{"u662f-02", "dkw-13859", x = {72.63, 200}, y = { 0,200}},
{"u6643-02", "dkw-13891", x = {69.07, 200}, y = {5,200}},
{"u664f-02", "dkw-13914", x = {70.53, 200}, y = { 0,200}},
{"u7085-02", "dkw-18896", x = {62.24, 207.14}, y = { 0,200}},
{"u76f8-02", "dkw-23151", x = {61.67, 191.67}, y = { 0,200}},
{"u7709-02", "dkw-23190", x = {73.17, 201.22}, y = {0,200}},
{"u777f-02", "dkw-23536", x = {75.00, 192}, y = { 0,200}},
{"u795f-02", "dkw-24674", x = {80, 198}, y = {0,200}},
{"u81ec-02", "dkw-30107", x = {81.05, 200}, y = { 0,200}},
{"u83ab-02-var-001", "dkw-31078", x = {52.08, 200}, y = {0,200}},
{"u84a6-02-var-002", "dkw-31582", x = {77.00, 197}, y = {0,200}},
{"u898f-02", "dkw-34810", x = {55.07, 195.17}, y = { 0,200}},
{"u89a7-02", "dkw-34928", x = {64.00, 200}, y = { 0,200}},
{"u89bd-02", "dkw-34977", x = {69.70, 196.97}, y = { 0,200}},
{"u8cd4-02", "dkw-36789", x = {65.00, 193}, y = { 0,200}},
{"u9598-02", "dkw-41263", x = {62.00, 193}, y = { 0,200}},
{"u9821-02", "dkw-43452", x = {44.21, 200}, y = { 0,200}},
{"u9999-02", "dkw-44518", x = {54.55, 200}, y = { 0,200}},
{"ufa5b-02", "dkw-28853", x = {56.16, 200}, y = { 0,200}},
{"u4020-03", "dkw-23217", x = {18.02, 190.99}, y = { 6.00,110}},
{"u53ad-03", "dkw-03025", x = { 4.94, 195.06}, y = { 1.36,115.65}},
{"u65f1-03-var-001", "dkw-13752", x = { 0, 200}, y = { 0,145}},
{"u6625-03", "dkw-13844", x = { 0, 200}, y = {0,130}},
{"u6d66-03-var-001", "dkw-17475", x = {0, 200}, y = { 2.00,134}},
{"u769b-03", "dkw-22766", x = { 1.00, 200}, y = { 4.52,140.27}},
{"u23140-04", "dkw-13739", x = { 0, 200}, y = {76.00,213}},
{"u4f70-04", "dkw-00553", x = {0, 187.26}, y = {48.00,200}},
{"u65e7-04", "dkw-13737", x = {16.25, 188.75}, y = {94.36,200}},
{"u6642-04-var-001", "dkw-13890", x = { 0, 200}, y = {89.00,193}},
{"u7681-k04", "dkw-22684", x = {0, 200}, y = {40,200}},
{"u7717-04", "dkw-23224", x = { 3.96, 198.02}, y = {42.00,196}},
{"ufa5b-04-var-001", "dkw-28853", x = { 0, 200}, y = {35.16,180.22}},
{"ufa5b-04", "dkw-28853", x = { 0, 200}, y = {59.34,200}},
{"u2054c-08", "dkw-01526", x = {32.00, 168}, y = { 0,200}},
{"u537d-08", "dkw-02872", x = {30, 170}, y = { 0,200}},
{"u606f-08", "dkw-10601", x = {28.00, 172}, y = {5,195}},
{"u610f-08", "dkw-10921", x = {26.00, 174}, y = {5,195}},
{"u660c-08", "dkw-13803", x = {12.73, 187.27}, y = {-3.83,200}},
{"u6f6a-08", "dkw-18267", x = {32.26, 167}, y = { 0,200}},
{"u2313c-09", "dkw-13736", x = { 2.00, 198}, y = {38.75,142.50}},
{"u23140-09", "dkw-13739", x = { 0, 200}, y = {28.00,171}},
{"u4e98-09", "dkw-00262", x = {0, 200}, y = {35,175}},
{"u65ec-09", "dkw-13746", x = {0, 200}, y = {30.48,158.10}},
{"u76f8-09", "dkw-23151", x = {0, 200}, y = {44.00,148}},
{"u662f-24", "dkw-13859", x = {15.79, 184.21}, y = {52.50,200}},
{"ufa22-02", "dkw-35743", x = {48.24, 195.98}, y = { 0.00,200.00}},
{"ufa43-02", "dkw-14051", x = {60.22, 200.00}, y = { 0.00,200.00}},
{"ufa5a-02", "dkw-28319", x = {62.37, 196.77}, y = { 0.00,198.70}},
{"ufa5c-02", "dkw-30108", x = {61.05, 203.16}, y = { 0.00,196.92}},
{"ufa6a-02", "dkw-43519", x = {60, 200}, y = { 0.00,200.00}},

{"u9999-01", "u9999-01-var-003"},

{"u209e2-01", "dkw-02802", x={0,110}, amb=true}, -- 	𠧢	1+1+日[u65e5-03]+匕[u5315-j]	 // 	⺊[u2e8a-03@2]+㫐[u3ad0-ja]
{"u27da0-01", "dkw-36824", x={0,115}, amb=true}, -- 	𧶠	1+1+1+1+1+1+2+3+1+目[u76ee]+2+2	 // 	1+1+1+1+1+1+2+3+1+貝[u8c9d-04]
{"u51a5-01", "dkw-01588", x={0,110}, amb=true}, -- 	冥	冖[u5196-08-var-001]+日[u65e5]+1+1+2+2	 // 	冖[u5196-03]+日[u65e5-03@4]+1+1+2+2
{"u539f-01", "dkw-02973", x={0,110}, amb=true}, -- 	原	1+7+2+1+1+1+1+1+1+2+2	 // 	1+7+2+1+1+1+1+1+1+2+2
{"u54e1-01", "dkw-03633", x={0,125},y={5,195}, amb=true}, -- 	員	1+1+1+1+1+1+1+1+1+1+2+2	 // 	口[u53e3]+目[u76ee]+2+2
{"u599f-01", "dkw-06099", x={0,110}, amb=true}, -- 	妟	日[u65e5]+1+2+2+1	 // 	日[u65e5-03@4]+女[u5973-04]
{"u660f-01-var-001", "dkw-13806", x={0,110}, amb=true}, -- 	昏	2+1+1+2+2+1+1+1+1+1	 // 	2+1+2+1+2+日[u65e5]
{"u666f-01", "dkw-13983", x={0,110},y={0,195}, amb=true}, -- 	景	1+1+1+1+1+1+1+1+1+1+1+1+2+2	 // 	1+1+1+1+1+1+1+1+1+1+1+1+2+2
{"u66f7-01", "dkw-14290", x={0,110}, amb=true}, -- 	曷	1+1+1+1+1+2+1+2+2+2+1+1	 // 	⿱[u2ff1-u65e5-u52f9]+2+2+1+1
{"u7687-01-var-001", "dkw-22701", x={0,110}, amb=true}, -- 	皇	白[u767d-03-var-001]+1+1+1+1	 // 	白[u767d-03-var-003]+王[u738b-04-var-001]
{"u793a-01-var-001", "dkw-24623", x={0,110}, amb=true}, -- 	示	1+1+1+2+2	 // 	nil
{"u7981-01", "dkw-24743", x={0,110}, amb=true}, -- 	禁	1+1+2+2+1+1+2+2+1+1+1+2+2	 // 	林[u6797-03]+示[u793a-04]
{"u7ae0-01", "dkw-25761", x={0,110}, amb=true}, -- 	章	1+1+2+2+1+1+1+1+1+1+1+1	 // 	立[u7acb-03-var-001]+早[u65e9-07]
{"u81ea-01-var-001", "dkw-30095", x={0,110}, y={0,180},amb=true}, -- 	自	2+目[u76ee]	 // 	nil
{"u81ef-01-var-003", "dkw-30119", x={0,120}, amb=true}, -- 	臯	自[u81ea-j]+1+1+1+1+1+1	 // 	自[u81ea-03@1]+1+1+1+1+1+1
{"u8c9e-01", "dkw-36658", x={0,120},y={0,190}, amb=true}, -- 	貞	1+1+目[u76ee]+2+2	 // 	⿱[u2ff1-u2e8a-u76ee-var-001]+2+2
{"u8cac-01", "dkw-36682", x={0,110},y={0,190}, amb=true}, -- 	責	1+1+1+1+目[u76ee]+2+2	 // 	龶[u9fb6-03]+貝[u8c9d-04]
{"u8cc1-01", "dkw-36727", x={0,115}, amb=true}, -- 	賁	1+1+1+1+1+目[u76ee]+2+2	 // 	卉[u5349-03]+貝[u8c9d-04]
{"u8ce3-01", "dkw-36825", x={0,120}, amb=true}, -- 	賣	1+1+1+罒[u7f52-j]+目[u76ee-j]+2+2	 // 	士[u58eb-03]+買[u8cb7-j]
{"u9801-01", "dkw-43333", x={0,130},y={5,195}, amb=true}, -- 	頁	1+2+1+1+1+1+1+1+2+2	 // 	nil
{"ufa5b-01", "dkw-28853", x={0, 120}, amb=true}, -- 	者	1+1+1+2+1+1+1+1+1+2	 // 	1+1+1+2+日[u65e5]+2
{"u24c07-02", "dkw-21714", x={60,200}, amb=true}, -- 	𤰇	1+1+1+1+7+1+1+1+1+1+1	 // 	用[u7528-06]+厂[u5382-05]+艹[u8279-03@5]
--{"u24c08-02-var-004", "dkw-21716", x={60,200}, amb=true}, -- 	𤰈	艹[ufa5d-03]+2+1+2+1+1+1+1+1+1	 // 	卝[u535d-03]+勹[u52f9-10]+7+1+1+1+1+1
--{"u24c08-02-var-005", "dkw-21716", x={60,200}, amb=true}, -- 	𤰈	艹[ufa5e-03]+2+1+2+1+1+1+1+1+1	 // 	卝[u535d-03]+勹[u52f9-10]+7+1+1+1+1+1
{"u27d2a-02", "dkw-36663", x={60,200}, amb=true}, -- 	𧴪	1+2+2+1+1+1+1+1+1+2+2	 // 	1+貝[u8c9d-04]+2+2
{"u27d32-02", "dkw-36671", x={60,200}, amb=true}, -- 	𧴲	巛[u5ddb-03-var-001]+貝[u8c9d-07]	 // 	巛[u5ddb]+貝[u8c9d-04]
{"u3687-02", "dkw-05718", x={65,200}, amb=true}, -- 	㚇	1+1+1+2+2+2+3+2+1+2+2	 // 	nil
{"u4eb0-02", "dkw-00307", x={60,200}, amb=true}, -- 	亰	1+1+1+1+1+1+1+1+2+2	 // 	1+1+1+1+1+1+1+0+1+2+2
{"u5192-k02", "dkw-01538", x={70,200}, amb=true}, -- 	冒	1+1+1+1+1+1+1+1+1+1+1	 // 	冃[u5183-03]+目[u76ee]
{"u527d-02", "dkw-02160", x={70,200}, amb=true}, -- 	剽	1+1+1+1+1+1+1+1+1+1+2+2+1+1	 // 	票[u7968-01]+刂[u5202-02]
{"u52c7-g02", "dkw-02360", x={60,200}, amb=true}, -- 	勇	1+2+2+1+1+1+1+1+1+1+2+2	 // 	1+2+2+1+1+1+1+1+1+力[u529b-04]
{"u539f-02", "dkw-02973", x={75,200}, amb=true}, -- 	原	1+7+2+1+1+1+1+1+1+2+2	 // 	1+7+2+1+1+1+1+1+1+2+2
{"u539f-g02", "dkw-02973", x={75,200}, amb=true}, -- 	原	1+7+2+1+1+1+1+1+1+2+2	 // 	1+7+2+1+1+1+1+1+1+2+2
{"u57fa-02", "dkw-05197", x={45,200}, amb=true}, -- 	基	1+1+1+1+1+1+2+2+1+1+1	 // 	其[u5176-03-var-003]+1+1+1
{"u590f-02", "dkw-05720", x={60,200}, amb=true}, -- 	夏	1+2+1+1+1+1+1+1+2+1+2+2	 // 	1+2+目[u76ee]+夊[u590a-t04]
{"u5b97-02", "dkw-07106", x={85,200}, amb=true}, -- 	宗	1+2+1+2+1+1+1+2+2	 // 	宀[u5b80-03]+示[u793a-04]
{"u5bbf-02", "dkw-07195", x={68,200}, amb=true}, -- 	宿	1+2+1+2+1+2+2+1+1+1+1+1+1	 // 	宀[u5b80-03]+佰[u4f70-04]
{"u5bec-02-var-002", "dkw-07322", x={72,200}, amb=true}, -- 	寬	寛[u5bdb-02-var-002]+2	 // 	宀[u5b80-03]+1+1+1+1+1+1+1+1+1+1+2+3+2
{"u5bec-02", "dkw-07322", x={60,200}, amb=true}, -- 	寬	寛[u5bdb-02]+2	 // 	宀[u5b80-03]+1+1+1+1+1+1+1+1+1+1+2+3+2
{"u5c1e-02", "dkw-07517", x={55,200}, amb=true}, -- 	尞	尞[u5c1e-08]	 // 	1+2+2+2+2+1+1+1+1+1+1+2+2
{"u5e1b-02", "dkw-08855", x={80,200}, amb=true}, -- 	帛	2+1+1+1+1+1+1+1+1+1	 // 	白[u767d-03]+1+1+1+1
{"u5e1b-g02", "dkw-08855", x={80,200}, amb=true}, -- 	帛	2+1+1+1+1+1+1+1+1+1	 // 	白[u767d-03]+1+1+1+1
{"u610f-02", "dkw-10921", x={56,200}, y={5, 195}, amb=true}, -- 	意	意[u610f-08]	 // 	1+1+2+2+1+1+1+1+1+1+心[u5fc3-04]
{"u611b-02", "dkw-10947", x={60,200}, amb=true}, -- 	愛	爫[u722b-g]+冖[u5196]+心[u5fc3-09]+夂[u5902-04]	 // 	nil
{"u656b-02", "dkw-13286", x={60,200}, amb=true}, -- 	敫	2+1+1+1+1+1+1+1+1+2+2+2+1+2+2	 // 	〓[cdp-8ce0]+攵[u6535-02]
{"u65e3-02-var-001", "dkw-13724", x={60,200}, amb=true}, -- 	旣	2+1+1+1+1+1+2+3+1+1+1+7+3	 // 	皀[u7680]+1+1+1+2+3
{"u6606-02", "dkw-13792", x={70,200}, amb=true}, -- 	昆	日[u65e5]+1+1+2+2+3	 // 	日[u65e5-03]+比[u6bd4-04]
{"u6613-02-var-001", "dkw-13814", x={65,200}, amb=true}, -- 	易	1+1+1+1+1+2+1+2+2+2	 // 	日[u65e5]+2+1+2+2+2
{"u666f-02", "dkw-13983", x={65,200}, amb=true}, -- 	景	日[u65e5]+1+1+口[u53e3]+1+2+2	 // 	1+1+1+1+1+1+1+1+1+1+1+1+2+2
{"u66f7-02", "dkw-14290", x={50,200}, amb=true}, -- 	曷	日[u65e5-j]+2+1+2+2+2+𠃊[u200ca-jv]	 // 	⿱[u2ff1-u65e5-u52f9]+2+2+1+1
{"u67d0-02", "dkw-14618", x={75,200}, amb=true}, -- 	某	1+1+1+1+1+2+2+1+1	 // 	1+1+1+1+1+1+1+2+2
{"u6c93-02", "dkw-17206", x={75,200}, amb=true}, -- 	沓	1+1+2+2+2+1+1+1+1+1	 // 	1+1+2+2+2+日[u65e5]
{"u6c93-g02", "dkw-17206", x={75,200}, amb=true}, -- 	沓	1+1+2+2+2+1+1+1+1+1	 // 	1+1+2+2+2+日[u65e5]
{"u752b-02", "dkw-21706", x={65,200}, amb=true}, -- 	甫	1+1+1+1+1+1+1+2	 // 	nil
{"u752c-02", "dkw-21707", x={75,200}, amb=true}, -- 	甬	甬[u752c-07]	 // 	1+2+2+用[u7528-06]
{"u767e-02", "dkw-22679", x={65,200}, amb=true}, -- 	百	1+2+1+1+1+1+1	 // 	1+2+1+1+1+1+1
{"u7683-02", "dkw-22686", x={70,200}, amb=true}, -- 	皃	2+1+1+1+1+1+2+3	 // 	白[u767d-03-var-001]+3+2
{"u7683-02-var-001","dkw-22686",x={70,200}, amb=true}, -- 	皃
{"u7687-02", "dkw-22701", x={70,200},y={0,195}, amb=true}, -- 	皇	2+1+1+1+1+1+1+1+1+1	 // 	白[u767d-03-var-003]+王[u738b-04-var-001]
{"u7690-02", "dkw-22727", x={55,200}, amb=true}, -- 	皐	2+1+1+1+1+1+1+1+1+1+1+1	 // 	白[u767d-07]+𠦂[u20982-04-var-001]
{"u76f4-02", "dkw-23136", x={70,200}, amb=true}, -- 	直	1+1+1+1+1+1+1+1+1+1	 // 	1+2+1+1+1+1+1+1+1+1
{"u771f-02", "dkw-23236", x={75,200}, amb=true}, -- 	真	1+1+1+1+1+1+1+1+1+2+2	 // 	1+2+1+2+2+1+1+1+1+1+1
{"u77cd-02", "dkw-23792", x={60,200}, amb=true}, -- 	矍	䀠[u4020-03]+隹[u96b9-04]+1+2+2	 // 	瞿[u77bf]+又[u53c8-04-var-001]
{"u7968-02", "dkw-24694", x={65,200}, amb=true}, -- 	票	1+1+1+1+1+1+1+1+1+1+2+2	 // 	覀[u8980-03]+示[u793a-04]
{"u7981-02", "dkw-24743", x={70,200}, amb=true}, -- 	禁	1+1+2+2+1+1+2+2+1+1+1+2+2	 // 	林[u6797-03]+示[u793a-04]
{"u7adf-02", "dkw-25757", x={75,200}, amb=true}, -- 	竟	1+1+2+2+1+1+1+1+1+1+2+3	 // 	立[u7acb-03]+日[u65e5]+2+3
{"u7ae0-02", "dkw-25761", x={60,200}, amb=true}, -- 	章	亠[u4ea0-03]+2+2+1+早[u65e9-j]	 // 	立[u7acb-03-var-001]+早[u65e9-07]
{"u7fd2-02-var-001", "dkw-28672", x={75,200}, amb=true}, -- 	習	1+1+2+2+1+1+2+2+2+1+1+1+1+1	 // 	羽[u7fbd-k03]+白[u767d-07]
{"u8006-02", "dkw-28849", x={60,200}, amb=true}, -- 	耆	1+1+1+2+2+3+日[u65e5]	 // 	老[u8001-03]+日[u65e5-04@2]
{"u8033-02-var-001", "dkw-28999", x={60,200}, amb=true}, -- 	耳	1+1+1+1+2+1	 // 	nil
{"u81ef-02-var-001", "dkw-30119", x={55,200}, amb=true}, -- 	臯	2+1+1+1+1+1+1+1+1+1+1+1+1	 // 	自[u81ea-03@1]+1+1+1+1+1+1
{"u81ef-02", "dkw-30119", x={55,200}, amb=true}, -- 	臯	2+1+1+1+1+1+1+1+1+1+1+1+1	 // 	自[u81ea-03@1]+1+1+1+1+1+1
{"u82d7-02", "dkw-30781", x={60,200}, amb=true}, -- 	苗	1+1+1+田[u7530]	 // 	nil
{"u898b-02-var-002", "dkw-34796", x={75,200}, amb=true}, -- 	見	1+1+1+1+1+1+2+3	 // 	nil
{"u898b-02-var-003", "dkw-34796", x={75,200}, amb=true}, -- 	見	1+1+1+1+1+1+2+3	 // 	nil
{"u898b-02-var-004", "dkw-34796", x={75,200}, amb=true}, -- 	見	目[u76ee]+2+3	 // 	nil
{"u8993-02-var-001", "dkw-34815", x={75,200}, y={0,195}, amb=true}, -- 	覓	爫[u722b-03]+見[u898b-02-var-002]	 // 	爫[u722b]+見[u898b-04]
{"u8993-02-var-002", "dkw-34815", x={75,200}, y={0,195}, amb=true}, -- 	覓	爫[u722b-03]+見[u898b-02-var-005]	 // 	爫[u722b]+見[u898b-04]
{"u8993-02",         "dkw-34815", x={75,200}, y={0,195}, amb=true}, -- 	覓	爫[u722b-03]+見[u898b-02]	 // 	爫[u722b]+見[u898b-04]
{"u8c9e-02", "dkw-36658", x={60,200}, amb=true}, -- 	貞	1+1+1+1+1+1+1+1+2+2	 // 	⿱[u2ff1-u2e8a-u76ee-var-001]+2+2
{"u8ca2-02", "dkw-36665", x={75,200}, amb=true}, -- 	貢	1+1+1+1+1+1+1+1+2+2+1	 // 	工[u5de5-07]+貝[u8c9d-04]
{"u8cab-02", "dkw-36681", x={75,200}, amb=true}, -- 	貫	1+1+1+1+1+1+1+1+1+1+1+1+2+2	 // 	毌[u6bcc-03]+貝[u8c9d-04]
{"u8cac-02", "dkw-36682", x={65,200}, amb=true}, -- 	責	1+1+1+1+目[u76ee]+2+2	 // 	龶[u9fb6-03]+貝[u8c9d-04]
{"u8cb4-02", "dkw-36704", x={70,200}, amb=true}, -- 	貴	1+1+1+1+1+1+1+1+1+1+1+1+2+2	 // 	𠀐[u20010-03]+貝[u8c9d-04]
{"u8cc1-02-var-001", "dkw-36737", x={70,200}, amb=true}, -- 	賁	1+1+1+1+1+1+1+1+1+1+1+1+2+2	 // 	1+1+1+1+1+1+1+1+1+1+1+1+2+2
{"u8cc1-02", "dkw-36727", x={75,200}, amb=true}, -- 	賁	賁[u8cc1-07]	 // 	卉[u5349-03]+貝[u8c9d-04]
{"u8cf4-02", "dkw-36861", x={55,200}, amb=true}, -- 	賴	1+1+1+1+1+2+2+1+1+2+2+1+1+1+1+1+1+2+2	 // 	束[u675f-01]+1+2+2+貝[u8c9d-02]
{"u8d0a-02", "dkw-36935", x={60,200}, amb=true}, -- 	贊	2+1+1+1+2+1+2+2+1+1+1+2+3+1+1+1+1+1+1+2+2	 // 	兟[u515f-03]+貝[u8c9d-04]
{"ufa64-02-var-001", "dkw-36788", x={70,200}, amb=true}, -- 	賓	1+2+1+2+1+1+2+2+1+1+1+1+1+1+2+2	 // 	宀[u5b80-03]+1+1+2+2+貝[u8c9d-04]
--{"u25117-03", "dkw-23197", y={0,110}, amb=true}, -- 	𥄗	目[u76ee]+㕚[u355a-ja]	 // 	目[u76ee-01@3]+㕚[u355a-02]
{"u3951-03", "dkw-10801", y={0,110}, amb=true}, -- 	㥑	1+2+1+1+1+1+1+2+1+2+2+3+2+2	 // 	〓[cdp-8cd4]+心[u5fc3-04-var-001]
{"u6676-03", "dkw-14000", y={0,110}, amb=true}, -- 	晶	日[u65e5]+日[u65e5]+日[u65e5]	 // 	1+1+1+1+1+0+1+1+1+1+1+0+1+1+1+1+1
{"u767e-03", "dkw-22679", y={10,115}, amb=true}, -- 	百	1+2+1+1+1+1+1	 // 	1+2+1+1+1+1+1
{"u8ccf-03", "dkw-36779", y={10,110}, amb=true}, -- 	賏	目[u76ee]+2+2+目[u76ee]+2+2	 // 	貝[u8c9d-01]+1+1+1+1+1+1+2+2
{"u9996-03", "dkw-44489", y={0,110}, amb=true}, -- 	首	2+2+1+2+目[u76ee]	 // 	nil
{"u898b-04-var-001", "dkw-34796", y={65,200}, amb=true}, -- 	見	1+1+1+1+1+1+2+3	 // 	nil
{"u898b-g04", "dkw-34796", y={65,200}, amb=true}, -- 	見	1+1+1+1+1+1+2+3	 // 	nil
 {"u591c-08", "dkw-05763", x={30,170}, amb=true}, -- 	夜	亠[u4ea0-03]+亻[u4ebb-01]+2+1+2+2+2	 // 	nil
{"u5c1e-08", "dkw-07517", x={30,180}, amb=true}, -- 	尞	1+2+2+2+2+1+1+1+1+1+1+2+2	 // 	1+2+2+2+2+1+1+1+1+1+1+2+2
{"u66fe-08", "dkw-14299", x={30,170}, amb=true}, -- 	曾	2+1+2+〓[cdp-8b62]+日[u65e5-04@2]	 // 	2+1+2+𭥴[u2d974-04]
{"u6709-08", "u6709-08"}, --x={0,200}, amb=true}, -- 	有	2+1+1+1+1+1+1	 // 	nil
{"u6772-08", "dkw-14500", x={30,170}, amb=true}, -- 	杲	1+1+1+1+1+1+1+2+2	 // 	1+1+1+1+0+1+1+2+2+1
{"u751a-08", "dkw-21648", x={30,170}, amb=true}, -- 	甚	1+1+1+1+1+1+1+1+2+3	 // 	nil
{"u9996-08", "dkw-44489", x={30,170}, amb=true}, -- 	首	2+2+1+2+1+1+1+1+1+1	 // 	nil
{"u6220-02", "u6220-var-003", x={65,200},y={5,195}, amb=true},
{"u6220-04-var-001", "u6220-var-003", x={0,200}, y={45,200},amb=true},
{"u6220-var-001", "u6220-var-003"},

{"u53ad-05", "u53ad-05-var-002"},
{"u2c037",   "u2c037-var-001"},
{"u2c037-02",   "u2c037-var-001", x={66,196}},
{"u4eb6-01", "u4eb6-01-var-002"},
{"u662f-05", "u662f-05-var-002", }, --(是:dkw-13859)
{"u662f-10", "u662f-05-var-002", }, --(是:dkw-13859)
{"u7b97-03", "u7b97-03-var-002"},
{"u81ed-01", "u81ed-01-var-001"},
{"u83ab-03-var-001", "u83ab-03-var-007"},
{"u898b-05", "u898b-05-var-001"},
{"u898b-g05","u898b-05-var-001"},--(見:dkw-34796)
{"u898b-11", "u898b-05-var-001"},
{"u95cc-g", "u95cc-var-001"},
{"u9b25-05", "dkw-45632"},
{"u9b25-10", "u9b25-10-var-001"},
{"u6701-k", "u6701-var-002"},
{"u6701-02-var-001", "u6701-var-002", x={70,200}},
{"aj1-07253", "明"},
{"aj1-14052", "驀"},
{"u771f-itaiji-002","dkw-23237"},
{"u2bd56", "u5c09-var-001"},
{"u2652e", "u2652e-var-002"},
{"koseki-323760", "u2652e-var-002"},
{"u53d6-var-003", "u53d6-var-007"},
{"u53d6-itaiji-002", "u53d6-var-007"},
{"u53d6-itaiji-001", "u53d6-var-007"},
{"u53d6-04", "u53d6-var-007", y={75,195}, amb=true}, -- 	取
--##undef:u53d6-itaiji-001(取:dkw-03158)
};


-- 処置が不要なもの
local unhandled = {
   "u6709-08",
   "u26407-02-var-001", "u26407-ue0100", "u26407-var-001", "u3687-var-001", "u3687-var-002", "u53b2-var-002",
   "u590b-02-var-001", "u590b-02-var-002", "u590b-var-003", "u590c-01-var-001", "u590c-k", "u590c-itaiji-001", "u3b05-var-003",
   "u5076-var-001", "u591c-08-var-001", "u591c-var-002", "u591c-var-003", "u591c-var-004", "u5960-01-var-003", "u5960-01-var-005", "u5bd3-var-001",
   "u5c09-h", "u5c09-var-001", "u5c0a-ue0101", "u5c5e-01-var-001", "u5c5e-var-001",
   "u65e8-var-001", "u65e9-var-001", "u66f9-var-001", "u66fc-01-var-001", "u76ee-01-var-001", "u842c-ue0103", "u914b-var-001", "u9580-05-var-001",
   "u9656-var-001", "u96e2-var-001", "u8026-var-001", "u79bd-var-001", "u79b8-04-var-001", "u79b9-var-001", "u79b9-var-002", "u79ba-02-var-001",
   "u79ba-ue0101", "u79bb-01-var-001", "u79bb-02-var-001", "u795f-var-001", "u793a-t", "u793a-ue0100", "u793a-var-001", "u793a-var-002",
   "u795f-01-var-001", "u795f-var-001", "u7968-07-var-001", "u8806-var-001", "u68f1-var-001", "u6991-var-001", "u65e5-01-var-001", "u65e5-03-var-001",
   "j83-633c","koseki-278880","koseki-201420","koseki-122920","koseki-123500","koseki-355970","koseki-385700",
   "koseki-442770","koseki-472960","koseki-050140", "cdpo-a0c4",
"u767d-var-003",--白"dkw-22"
"u53c8-01",
"u590b-01",
"u7236-01",
"u793a-01",
"u8c9d-01-var-001",
"u9149-01-var-001",
"u97f3-01-var-002",
"u9ed1-01-var-001",
"u590c-02-var-001",
"u5c03-02-var-002",
"u79bd-02-var-001",
"u914b-02-var-001",
"u590a-04",
"u793a-t04",
"u9149-04-var-003",
"u53c8-07-var-001",
"u793a-14-var-001",
"u793a-t14",
"u21f01-var-001",
"u224ed-var-003",
"u25718-var-001",
"u2a146-var-001",
"u5177-var-002",
"u53c8-var-002",
"u6703-var-001",
"u6f2b-ue0102",
"u79bb-var-001",
"u79bb-var-002",
"u84a6-var-001",
"u8b77-var-002",
"u9149-var-001",
"u9580-var-001",
"u96bb-ue0101",
"u9801-var-002",
"u9149-t01",
"u4f96-02",
"u53df-02-var-001",
"u53df-02",
"u66fc-02-var-001",
"u8005-02",
"u752b-03-var-002",
"u53df-06-var-002",
"u53df-07",
"u65e5-09-var-001",
"u53df-ue0101",
"u91ac-itaiji-002",
"aj1-14112",
"j83-633c",
"juki-aea3",

};
--[[undefの内訳
aj1,juki -> utfまたはkosekiからdkw変換(juki-ad98,juki-adccは無理だな)
koseki -> そのままdkw変換可(処置不要なものもある)->処置不要なものを処置してしまっている件
extf,j78/j83/jsp -> utfからdkw変換
cdp,zihai-000444,zihai-140730,irg2015-02715 -> 定義展開が必要か?
uXXXXX ->
・u79bb-var-001など処置不要なものがまだある
・u9149-01-var-001など定義済みのものがある
・u95cc-gとdkw-41433は若干異なるため直接置き換えできない(要比較:元字ekanji,元字koseki,incl-dkw,incl-ucsの比較テーブルがほしい)

]]
--[[
 無印と同じ処置でよいもの(たぶんTodo:当該kosekiと要比較)
u5192-ue0103 (ただし dkw-01538はリテイク)
u51a5-var-001  u51a5-var-002  u5353-07  u53b2-var-001 u52a9-07  u590c-g  u5bbf-var-001  u5e1b-t u5e55-ue0102 u5f2d-ue0101 u5fa5-var-001 u64ae-var-001 u6577-ue0103 u65e9-07  u660a-t u660c-08 u6614-07 u6714-var-001 u671d-ue0101 u6b3a-ue0100 u6b47-ue0100 u6b47-var-003 u6f6d-ue0102  u752c-07 u767e-07 u8349-var-001  u914d-g u9583-t u9589-var-001  u959e-var-002 u95b1-var-001 u975a-var-001 u9801-var-002 u9f3b-g u8ca7-var-001  u8cab-07 u898b-g u7fd2-k u7fd2-ue0103 u7fd2-var-001 u7fd2-var-004 u7aae-ue0101  u983b-var-001 u696c-var-002 
]]


local getjson = function(page)
   local cmd = "curl -w '%{http_code}' http://glyphwiki.org/json?name=" .. page;
   cmd = cmd .. " -s -S"
   print(cmd);
   local ret = execcmd(cmd);
   local m = ret:match('"data":%"([^%"]+)%"');
   local c = ret:match('"related":%"U%+([^%"]+)%"');
   if (c) then
      c = tonumber(c, 16);
      if (true or c < 0x10000) then
         c = utf8.char(c);
      else
         c = c - 0x10000;
         c = utf8.char((0xD800 | (c >> 10)), (0xDC00 | (c & 0x3FF)));
      end
   end
   return m, c;
end

local incl2array = function(incl)
   if (incl == nil) then return {}; end
   local m = ("*" .. incl:trim()):split("/");

   incl = m[2] or "";
   local ret = {};

   for p, c in utf8.codes(incl) do
      if (utf8.char(c) == "真") then c = utf8.codepoint("眞"); end
      if (utf8.char(c) == "曰") then c = utf8.codepoint("日"); end
      if (0x80 <= c) then
         ret[#ret + 1] = ("u%x"):format(c);
      end
   end
   return ret;
end

local undones;
--完了判定
local undone = function(dkw)
   if (undones ~= nil) then
      return undones[dkw];
   end

   undones = {};
   local done = {};
   local fp = io.open("done/done.dat","r")
   for line in fp:lines() do
      --print(line);
      local m = line:match("(dkw%-[^%.]+)%.dat");
      if (m) then done[m] = true;  --print("done", m);
      end
   end
   local fp = io.open("done/undone.dat","r")
   for line in fp:lines() do
      line = line:match("dkw%-[0-9d]+");
      if (line and done[line] == nil) then
         undones[line] = true;
      end
   end
   fp:close();

   return undones[dkw];
end

--ucsからdkwを得る
local uk2d;
local d2uk;
local ucs2dkw = function(key)
   if (uk2d ~= nil) then
      return uk2d[key];
   end
   uk2d = {};
   d2uk = {};
   local fp = io.open("mji_00502_pickup.txt","r")
   for gline in fp:lines() do
      local line = gline:split("\t");
      local dkw = line[1];
      local koseki = line[2];
      local ucs = line[3]:lower():gsub("^u%+", "u");
      local ivs0 = (line[4] or ""):lower();
      local ivs = (ivs0:match("^%x+_%x+$")) and "u" .. ivs0:gsub("_", "-u") or ucs;
      local page = (function(dkw)
        local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
        local n = page:match("%d+")
        return page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
      end)(dkw);

      local alias = (function(koseki)
         local glyph = koseki:match("^ksk%-(%d+)$");
         return glyph and ("koseki-%s"):format(glyph) or nil;
      end)(koseki);
      uk2d[ucs] = uk2d[ucs] and uk2d[ucs] .. "," .. page or page;
      if (ivs0:match("^u%+f[9a]") or ivs0:match("^u%+2f")) then uk2d[ivs0:gsub("u%+","u")] = page; end
      -- print("uk2d", ucs, uk2d[ucs]);
      
      if (alias) then
         uk2d[alias] = page;
         d2uk[page] = {koseki=alias, c=ivs};
      else
         d2uk[page] = {koseki="jmj",c=ivs};
      end
   end
   fp:close();
   return uk2d[key];
end

local ucs2c = function(ucs)
   --print("??",ucs);
   local hex = ucs:match("u(%x+)");
   if (not hex) then return "〓"; end
   return utf8.char(tonumber("0x"..hex));
end

-- 行内からpcode関連のものを探して可能なら差し替える
local find_and_replace = function(gline, pcode)
   -- エイリアスか?
   if (gline:match("^99:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:") == nil) then
      return false, gline;
   end
   
   local lined = gline:split(":")
   --local part = utf8.char(pcode);

   local alias = lined[8]:split("@")[1];
   --print(alias, "vs", pcode)
   -- エイリアスがpcodeで始まるか?
   if (alias:sub(1,pcode:len()) ~= pcode) then return false, gline; end
   --print("true")
   -- 定義済のものはテーブルの値に差し替え
   for _, refglyph in ipairs(reptable) do
      if ((refglyph[1] == alias) or (refglyph[1].."-j" == alias) or (refglyph[1].."-jv" == alias)) then
         lined[8] = refglyph[2];
         if (refglyph.x) then
            local x0 = lined[4];
            local x1 = lined[6];
            lined[4] = math.floor(x0 + (x1 - x0) * refglyph.x[1] / 200)
            lined[6] = math.floor(x0 + (x1 - x0) * refglyph.x[2] / 200)
         end
         if (refglyph.y) then
            local y0 = lined[5];
            local y1 = lined[7];
            lined[5] = math.floor(y0 + (y1 - y0) * refglyph.y[1] / 200)
            lined[7] = math.floor(y0 + (y1 - y0) * refglyph.y[2] / 200)
         end
         --done[#done + 1] = part;
         local cat = (refglyph.amb) and "(amb)" or "";
         cat = cat .. refglyph[1] .. "=" .. refglyph[2]
         return cat, table.join(lined, ":"),
         (refglyph[2]:match("^dkw%-") and undone(refglyph[2])) and ("unreg:" .. refglyph[2] .."(" .. ucs2c(pcode) .. ")") or nil;
      end
   end
   -- 処置不要なものは処置しない
   for _, p in ipairs(unhandled) do
      if (alias == p) then
         return p, table.join(lined, ":");
      end
   end
   --[[
   ]]
   -- 定義がない"uXXXX"/"koseki-XXXX"は dkw-XXXXXに直差し替え
   local refg = pcode:match("^(u%x+)") or pcode:match("^(koseki%-[0-9]+)$") or "";
   local dkw = uk2d[refg];
   if (dkw and dkw:find("dkw%-h")) then dkw = nil; end
   local is_simple = ((refg == alias) or (refg.."-j" == alias) or (refg.."-jv" == alias));
   if (dkw and is_simple) then
      lined[8] = dkw;
      return dkw, table.join(lined, ":"), (undone(dkw) and ("unreg:" .. dkw .."(" .. ucs2c(refg) .. ")"));
   end
   -- 対応するdkwがない
   if (not dkw and is_simple) then
      return "nodkw", gline, ("nodkw:" .. pcode .. "("..ucs2c(refg) ..")");
   end
   -- alias に "-01"とか"-ue0xxxx"とか"-itaiji-xxx"とかついちゃってる模様
   return "undef", gline, ("undef:" .. lined[8] .. "(" .. ucs2c(refg)  .. ":" .. (dkw or "") .. ")");
end

local originglyph = (function()
   local fp = io.open("p.original.dat","r")
   local p = {};
   for line in fp:lines() do
      local data = line:split(" ");
      local dkw = data[1];
      local c = data[2];
      local origin = data[3];
      if (dkw) then p[dkw] = origin; --print(dkw, origin);
      end
   end
   fp:close();

   return p;
end)()

local get_glyph = function(koseki, page)
   --glyphwikiから直接取得する場合はfalse, p.original.datから得る場合はtrue
   if (false) then
      local cmd = ("awk '$1 == \"%s\"{print $3,$2}' p.original.dat"):format(page);
      local ret = execcmd(cmd);
      --print("?", ret);
      if (ret ~= "") then
         local tmp = ret:split(" ");
         return tmp[1], tmp[2]:trim();
      end
   end
   
   local data,c = getjson(koseki);
   -- 実体でなければ実体にアクセス
   local m = data:match("^99:0:0:0:0:200:200:([^:]+)$");
   if (m) then
      data,c = getjson(m);
   end
   return data, c;
end

if(false) then
   local row = {"u610f-08"};
   local data,c = get_glyph(row[1]);
   local cmd = ("echo '%s %s %s' >> p.origina2.dat"):format(row[1], c, data);
   execcmd(cmd);
end

if (false) then
   --グリフ定義を持ってくる
   local fp = io.open("p.getdef.dat", "r");
   for line in fp:lines() do
      local row = line:split(" ");
      local data,c = get_glyph(row[2]);
      local cmd = ("echo '%s %s %s' >> p.origina2.dat"):format(row[1], c, data);
      execcmd(cmd);
   end
   fp:close();
end

if (false) then
   --グリフ定義を持ってくる
   local fp = io.open("undef1014.dat", "r");
   for line in fp:lines() do
      local m = line:match("^##[^:]+:([^(]+)%(");
      if (m) then print(m) end;
      local data,c = get_glyph(m);
      local cmd = ("echo '%s %s %s' >> p.origina3.dat"):format(m, c, data);
      execcmd(cmd);
   end
   fp:close();
end

local dump_pdat = function(dkw, koseki, ucs, glyph, cat, pstr)
   --execcmd(("echo '%s %s %s:%s %s %s %s' >> p.dat"):format(dkw, koseki, ucs, ucs2c(ucs), glyph, cat, pstr, replaced));
   print(('%s %s %s:%s %s %s %s'):format(dkw, koseki, ucs, ucs2c(ucs), glyph, cat, pstr, replaced));
end

local replace_parts = function(koseki, parts, page, c)
   --glyphデータと関連字を得る
   -- local data,c = get_glyph(koseki, page);

   local data = originglyph[page];
   --print(data);
   if (data == nil) then data = "" end
   if (c == nil) then c = "" end
   local ms = data:split("$");
   local done = {};
   local undef = {};

   local pstr = "";
   for _, p in ipairs(parts) do pstr = pstr.. (("%s[%s]"):format( p:match("^u") and ucs2c(p) or "〓", p)); end
   --print(" searching... " .. pstr);
   
   -- 目的の部品があるか探す
   for i, pcode in ipairs(parts) do
      -- 1行ずつ見る
      for _, line in ipairs(ms) do
         local ret, und;
         ret, line, und = find_and_replace(line, pcode);

         -- 見つかった
         if (ret) then
            --print("* ", ms[_], "=>", line);
            ms[_] = line;

            done[#done + 1] = ret --pcode .. "=" .. ret;
            -- 見つかったが部品用のサイズ定義がない
            if (und) then undef[#undef + 1] = und; end
            break;
         end
      end
      if (i ~= #done or #undef ~= 0) then break end
   end

   --変換結果をp.datに保存する

   -- 見つかったが定義がない
   if (#undef ~= 0) then
      --print("#### undef error: " .. table.join(undef, ";"));
      dump_pdat(page, koseki, c, data, "##"..table.join(undef, ","), pstr);
      return
   end
   -- 見つからないものがある
   if (#done ~= #parts) then
      --print("#### notfound error: ",  table.join(ms, "$"))
      
      dump_pdat(page, koseki, c, data, "##noparts:", pstr);
      return;
   end

   -- 処置不要
   if (table.join(ms, "$") == data) then
      return dump_pdat(page, koseki, c, "[[" .. koseki .. "]]", "##success:unhandled", pstr);
   end

   return dump_pdat(page, koseki, c, table.join(ms, "$"), "##success:"..table.join(done, ";"), pstr); 
end


-- 版4:mj1_ishii.txtを読んで指定パーツを差し替える
local pickups = function(buff)
   line = buff:split("\t");
   local dkw = line[1];
   local koseki = line[2];
   local incl = line[4];

   print();
   print(dkw, line[3]);
   --ひとまず完了したものは手をつけない
   if (undone(dkw) ~= true) then print("done"); return; end
   --kosekiと紐付いているものが対象
   if (koseki:match("^koseki%-") == nil) then print("## no-koseki"); return end;

   -- partsはp.noparty.datに定義されていればそちらを優先する
   local ret = execcmd(("grep '%s[^d]' p.noparty.dat"):format(dkw))
   local parts = {}
   if (ret == "") then
      parts = incl2array(incl);
   else
      local glyph = ret:split("\t")[4];
      local m = glyph:match("^<([^>]+)>");
      if (m) then
         if (m:match("^[amr]")) then print("man"); return; end
         parts = incl2array(m);
      else
         for _, d in ipairs(ret:split("\t")[4]:split(",")) do
            local m = d:match("^q.+%[(.+)%]")
            if (m) then parts[#parts  + 1] = m:split("@")[1]; end
         end
      end
   end
   if (parts == nil or #parts == 0) then print("noparts"); return; end

   return replace_parts(koseki, parts, dkw);
end

-- 版4:mj1_ishii.txtを読んで指定パーツを差し替える
local crawl_table = function(e0, e1)
   local fp = io.open("mj1_ishii.txt","r")
   local i = 0;
   for line in fp:lines() do
      i = i + 1;
      if (e0 <= i) then pickups(line) end
      if (e1 <= i) then break end
   end
   fp:close();
end

-- 版5:undoneなものをすべて検証する
local crawl_table = function(e0, e1)

   local incls = {};
   local readnoparty = function(line)
      local parts = {}
      local dkw = line:split("\t")[1];
      local glyph = line:split("\t")[4];
      if (not dkw or not dkw:match("^dkw%-") or not glyph) then return end
      local m = glyph:match("^<([^>]+)>");
      if (m) then
         if (m:match("^a")) then return dkw, {m}  end
         if (m:match("^r")) then return dkw, {m}  end
         if (m:match("^m")) then return dkw, {"m"}  end
         return dkw, incl2array("/" ..m);
      end
      for _, d in ipairs(glyph:split(",")) do
         local m = d:match("^q.+%[(.+)%]")
         if (m) then parts[#parts  + 1] = m:split("@")[1];  end
      end
      if (parts == nil or #parts == 0) then return nil; end
      return dkw, parts;
   end

   local read_ishii = function(buff)
      local line = buff:split("\t");
      local dkw = line[1];
      local koseki = line[2];
      local incl = line[4];
      if (incl == "") then return end
      return dkw, incl2array(incl);
   end

   local partsmake = function(dkw)
      local fp = io.open("mj1_ishii.txt","r")
      for line in fp:lines() do
         local dkw, ps = read_ishii(line);
         --print(dkw, table.join(ps, ","));
         if (dkw) then incls[dkw] = ps; end
      end
      fp:close();
      local fp = io.open("p.noparty.dat","r")
      for line in fp:lines() do
         local dkw, ps = readnoparty(line);
         --print(dkw, ps and table.join(ps, ","));
         if (dkw) then incls[dkw] = ps; end
      end
      fp:close();
      --Todo:ここにread_undefparty()とか
   end

   local kdbonly = (function()
      local p = {};
      local fp = io.open("kdbonly.txt","r")
      for line in fp:lines() do
         local data = line:trim():split(",");
         local c = data[1];
         local dkw = data[2];
         if (dkw) then
            local page = "dkw-" ..(function(dkw)
               local page = dkw:trim():gsub("補", "h"):gsub("%'", "d");
               local n = page:match("%d+")
               return page:gsub(n, (page:find("^h") and "%04d" or "%05d"):format(n));
            end)(dkw);
            p[page] = ("u%x"):format(utf8.codepoint(c));
            --print(page, p[page], c);
         end
      end
      return p;
   end)()
   
   local pickups = function(dkw)
      if (dkw == "dkw-48978") then
         --print (dkw, d2uk[dkw]);
      end

      local koseki, c = (function(dkw)
         if (d2uk[dkw]) then
            return d2uk[dkw].koseki, d2uk[dkw].c;
         end
         if (kdbonly[dkw]) then
            return "none", kdbonly[dkw];
         end
         return "none";
      end)(dkw);

      if (c == nil) then
         return dump_pdat(dkw, "_", "〓", "_", "##nodata");
      end
      local target = incls[dkw];

      if (("𠌻𠚳𠜧𠝱𠢀𠢄𠪕𠯎𡖷当㝹𡯣𡰄𡰑𢈬𢔝𢕖𢹄𢽈𣠌𣭂㳇𤁭𤟺𥕚䕕𦴖𧅾𧇱𧈞𧎔𧗢𧚼𧝢𧠣𧺈𨗩𨠹䥑𨯺𨰊𨹊䨙𩒋𩖻饈𩨖𩮉𩶍𩿌𪁤𪄾𪉼𪒵𪙳𣂷"):find(ucs2c(c), 1, true))
      then
         return dump_pdat(dkw, koseki, c,  "_", "##manual");
      end
      
      if (target == nil or #target == 0 or target[1] == "a") then
         return dump_pdat(dkw, koseki, c,  "[[" .. ((koseki=="none") and c or koseki) .. "]]", (target == nil) and "##success:nothing" or "##success:asis");
      end
      if (target[1]:match("^a:")) then
         dump_pdat(dkw, koseki, c, target[1]:split(":")[2], "##success:alias");
         return
      end
      if (target[1] == "m") then
         dump_pdat(dkw, koseki, c,  "_", "##manual");
         return
      end
      if (target[1] == "r") then
         dump_pdat(dkw, koseki, c,  "_", "??");
         return
      end
      --print(dkw, ucs2c(c), koseki, target and table.join(target, ","));
      return replace_parts(koseki, target, dkw, c);
   end

   -- undonesテーブルの文字をreplace
   local looptable = function()
      local b = {};
      for dkw,v in pairs(undones) do
         b[#b + 1] = dkw
      end
      table.sort(b);
      for i, dkw in ipairs(b) do
         if (e0 <= i) then pickups(dkw) end
         if (e1 <= i) then break end
      end
   end


   -- addlistテーブルの文字をreplace
   local looptable0 = function()
      --[[local addlist = {"dkw-14643","dkw-00482","dkw-00724","dkw-39939","dkw-23462","dkw-14285","dkw-23548","dkw-30120"};
      for _, u in ipairs({"冒","淂","厝","奠","嚴","叢","借","乾","俎","問","凌","伯","奭","淩","開","匍","匱","寔","𡚐"}) do
      --]]
      local addlist = {};
      for _, u in ipairs({"鼻"}) do
         local ucs = ("u%x"):format(utf8.codepoint(u));
         addlist[#addlist + 1] = uk2d[ucs]:split(",")[1];
         print(ucs, uk2d[ucs]:split(",")[1]);
      end

      for _, dkw in ipairs(addlist) do
         pickups(dkw)
      end
   end
   
   undone("dummy");  -- undones作成
   ucs2dkw("dummy"); -- d2uk,uk2d作成
   partsmake();      -- incls作成
   looptable();
end



if (#arg ~= 3) then
   help();
   return;
end

local e0 = tonumber(arg[2]);
local e1 = tonumber(arg[3]);
if (e0 > e1) then
   help();
   return;
end
crawl_table(e0, e1);


if(false) then

--要リテイク:9/17 3:04-4:00の日耳系644件(関連字), 未遂:23261
local ret = execcmd('find ~/tmp/glyphwiki/ -newermt "2018-9-17 3:04" -and ! -newermt "2018-9-17 4:00"')
for p in ret:split_it("\n") do
   local page = p:match("(dkw%-[^%.]+)%.dat")
   --getjson();
   local dash = (page:match("d$")) and 1 or 0
   local cmd = ('grep "^D%s.%d" ../kids/mj0502_pickup2.txt'):format(page:sub(5,9), dash);
   local ret = execcmd(cmd);
   local koseki = "koseki-" .. ret:split("\t")[2]:sub(2)
   local d,c = getjson(koseki);
   local glyph,c0 = getjson(page);
   if (c==c0) then
      print("No need")
   else
      print(page, ret:split("\t")[2])
      local timestump = os.time(os.date("!*t"));
      
      local cmd = "curl -w '\\n'"
      cmd = cmd .. (" 'http://glyphwiki.org/wiki/%s'"):format(page);
      cmd = cmd .. (" -d 'page=%s' "):format(page);
      cmd = cmd .. (" -d 'edittime=%d' "):format(timestump);
      cmd = cmd .. (" -d 'textbox=%s'"):format(glyph);
      if (c)  then cmd = cmd .. (" -d 'related=%s'"):format(c); end
      cmd = cmd .. (" --data-urlencode 'summary=関連字'");
      cmd = cmd .. (" --data-urlencode 'buttons=以上の記述を完全に理解し同意したうえで投稿する'");
      cmd = cmd .. " -b gwcookie.txt"
      cmd = cmd .. (" > ~/tmp/glyphwiki/%s.dat"):format(page);
      
      print(cmd);
      
      execcmd(cmd);
      execcmd("sleep 1");
   end
end
end
--[[ todo:

【登録状況テーブル作成】
a.登録済(mtnest):    33100字 (0)エ (1)主 (2)副
b.登録済(mtnest以外):11500字 (0)エ (1)主 (2)副 (9)戸籍統一文字にない文字
c.登録済(要リテイク):        (0)エ (1)主 (2)副 (9)
d.未登録:             5400字 (0)エ (1)主 (2)副 (9)

[d9で加工がいるもの]
"𠌻𠚳𠜧𠝱𠢀𠢄𠪕𠯎𡖷当㝹𡯣𡰄𡰑𢈬𢔝𢕖𢹄𢽈𣠌𣭂㳇𤁭𤟺𥕚䕕𦴖𧅾𧇱𧈞𧎔𧗢𧚼𧝢𧠣𧺈𨗩𨠹䥑𨯺𨰊𨹊䨙𩒋𩖻饈𩨖𩮉𩶍𩿌𪁤𪄾𪉼𪒵𪙳𣂷"
(筆抑え・草冠・肉月・日耳門は可能な限り除いた)※艹・筆抑えは自動抽出しないときつい
重複:𩕲(=M方Z矢可頁みたいな形になってる?)
𠧨 uでよい
𦎅 uでよい
𢙋 uでよい
搽 uでよい
𣠿 uでよい
𥤭 uでよい 
𦆤 uでよい
𦑉 Z日月だった
𦽪 uでよい
𧝢 uに近い、払いが横画右下から入る
𨱩 uでよい
𣬔 uでよい
𣀺 繭は四画艹+巾糸虫
𣠌 未確認
𣲐 L字は貫かない
𤸣 垂形

[Design](とにかくundoneを全検証する)
(1)dを抽出する
(2)aliasを得る(koseki>jmj>utf)
  - dkwから、mj1_pickupを参照する
    - あれば、alias = koseki
      - koseki不定であれば、alias = u (ほんとうはjmjがいいが)
　  - なければ、kdbonlyを参照する alias = u
　- それでもなければ、norefエラー●a

(3)targetを得る (p.noparty>ishii)
  - dkwから、p.nopartyを参照する
    - <m>なら、##manualダンプ->成功●0
    - <a>なら、エイリアス登録->成功●1
    - <r>なら、当該パーツを差し替える->成功●2
    - qなら、incl = q にてreplace
　  - なければ、mji_ishiiを参照する 
      - incl = qにてreplace
      - nilなら、そのままエイリアスで登録->成功●3
    (Todo: koseki不定(266字)およびkdbonly(1555字)で加工が必要なものはinclが必要)
    (特に艹と筆抑えはishiiでカバーしていないので要注意)

(4)replace
  - p.original.datから定義を得る
   - なければ、DLする
  - inclから、目的の部品を探す
   - 見つからなければnopartsエラー(たぶんないはず)●b
   - 見つかったら置き換え●4
     - 置き換えdkwがundoneならunreg警告●5
     - 置き換え前後で変化がない場合は、alias警告●6
   - 置き換え定義がない場合
     - "c","r","a"であれば無条件に上記と同じ処理を行う
     - suffix02,04,07-08であれば調整幅自動算出を試み、 autofix警告●7
       -> 結構無理あるかも。払いと止めでことなりがでるため。
       -> ためしにu610f-02(意:dkw-10921)で試したがめんどすぎ
       -> pngまたはsvgから直接自動算出できないか?(これもめんどい)
     - それ以外のケースであれば定義展開を試み、上記同様処理 exdef警告●8
       -> ためしにu4eb6-01(亶:dkw-00328)で試してみよう->これはいけそう
     //- 対応するdkwがない場合はnodkw警告●d
     //- undef警告●c


  ※この中でもundone判定とucs2dkw(mj1_pickup参照)を使っているため、上記(1)(2)と共通化したい。
  ※dkw-23547はなぜ漏れた?

(5) 出力
以下の書式で出力
成功0時: dkw-XXXX ucs実体 参照元定義 ##manual                         ToDo:要IDS系の定義展開(140字) 要手作業(140字)->実は<a>が結構ありそう(要koseki画像表示)
成功1時: dkw-XXXX ucs実体 __        [エイリアス] ##a　
成功3時: dkw-XXXX ucs実体 __        [エイリアス] ##nothing            (710字)->jmjはほとんど異体字セレクタでいけるかも->微妙(異体字セレクタ分は除くべきか?),kdbonlyは"加工が要るもの"リストが混じっている
成功245時:dkw-XXX ucs実体 参照元定義 変換後定義  ##unreg:XXXX(ucs実体) (success=146字,unreg=430字)
成功6時: dkw-XXXX ucs実体 参照元定義 [エイリアス] ##unhandled          (2字)
失敗a時: dkw-XXXX 〓      __        ##nodata                         (172字)->おそらくほぼ欠番
失敗b時: dkw-XXXX ucs実体 参照元定義 ##noparts:ucs実体[uXXXX]         (68字)->Todo:"q"割当
失敗c時: dkw-XXXX ucs実体 参照元定義 ##undef:XXXX(ucs実体)            (2800字)->Todo:定義展開(x)と調整幅自動算出(q),処置なし(a)・置き換え(c)リスト(既存のucs2dkwも怪しい)
失敗d時: dkw-XXXX ucs実体 参照元定義 ##nodkw:XXXX(ucs実体)            (200字)->Todo:定義展開(x)

<Next>
710+146+2+manual(18) == 876かな?
失敗cのうち<a>でもう少し##a増えそう
unregももう少しsuccess化しそう

※参照めっちゃ多くね? -> すべて対応
(1)でundone,done -> undones = {}
(2)でmj1_pickup, kdbonly -> uk2d,d2uk
(3)でp.noparty, mji_ishii -> incls
(4)でp.original.dat -> originglyph

[c1に入れるべきもの]
・a0で、9/3,10-11登録分のうちd1,d2に所属するもの
・a0で、見落とし分
・b0で、koseki=dkwでないもの
・b0で、koseki=dkwだが、d1,d2に所属するもの
・手修正済:原奈咠辠 音
・手修正予定:[乱]𠭥?
・見送り:愚离颼(既存エイリアス化すべき)
・リテイク対応:冒淂厝奠嚴叢借乾俎問凌伯奭淩開匍匱叟寔𡚐厭霸
・dkw参照では対応不可:頓匽

[d1,d2見落とし]
鬥構、且の1本ないやつ、aj1-xxxxに取り込まれたやつ、既偏、月偏、鼎
支は外す
N黑は実装したい

[b0, b1]
ほぼ完了しているはず。収録漏れは原因要調査。

【日耳門系の一律処理】

(0)戸籍統一文字のエイリアス

(1)主要素にしか含まない場合:
dkw-14004 koseki-157640 (𣇫)
    http://glyphwiki.org/json?name=koseki-156640
    --> data:"99:0:0:0:0:200:200:u231eb"
    http://glyphwiki.org/json?name=u231eb
    --> data:"99:0:0:0:0:173:200:u65e5-01@5$99:0:0:-8:0:200:200:u679c-02"
    "u65e5-01@%d" を "u65e5-01-var-001" に置換 -- テーブル参照
    dkw-14004にセット

(2)副要素に含む場合
(錯)
    http://glyphwiki.org/json?name=koseki-522190
    --> 99:0:0:3:0:164:200:u91d2-01@99:0:0:71:0:198:200:u6614-07"
    "u6614-07" を "dkw-13816" に置換 -- テーブル参照※
    dkw-40579にセット

(藺)
    http://glyphwiki.org/json?name=u85fa-ue0102
   --> "99:0:0:0:3:199:146:ufa5e-03@99:0:0:0:37:200:197:u95b5@6"
    "u95b5@6" を "dkw-41363" に置換  -- mj*pickup参照

※ dkw-XXXXX が存在しない場合は要作成
※ uXXXX-XX がdkw-XXXXXに直接置換できるかどうかは都度調べねばならない。
※ 頻出はあらかじめ作っておく必要あり。

【一律処理済テーブル p.dat】
mj1_ishii.txtで定義されたinclを参照する
p.original.datの元定義からinclの内容を差し替えた結果

(mji_ishii.txt に"夏"がない! 同じ理由で"憂首𦣻鼻"などもないので、手作業で追加予定)

・successは、置換したdkw-XXXXXが定義済み・未定義 に分類 -> unreg
・undefは、置換不要・無印と同一処置で再置換・要定義のうえ再置換・要調査 に分類(上記テーブル参照)
・nopartsは、
  - 何かのバグ(dkw-41211閂あたり) -> 済
  - CDPのUCS表現を検索した(f5e9とか) -> 済
  - dkw未収録パーツ(𣪘) -> nodkw
  - 処置不要(dkw-30754 䒤) -> <a>
  - コード表現の別(鼻:aj1-13993,愛:koseki-123500など),分離参照の別(dkw-18194㵆=汨告/氵晧),CHISEミス(昜:䞶) -> q
  - 筆画完全分離(16),IVS表現内(100),itaiji系表現内 -> <m>
-> qは再び一律処理にかける

【登録済みリテイク】
--要リテイク:"目"(dkw-23105)を含む3件->tweさんが修正済!
--要リテイク:"見"(u898b-02-var-001)を含む十数件
--要リテイク:"其"(u5176-02-var-001)を含む3件
・"票" u7968-t のエイリアス化 "禁禀奈佘"も同様
・新字体と補巻の除去
dkw-43489 99:0:0:0:0:112:185:u6210-ue0103:0:0:0$99:0:0:0:0:200:200:u9801-02-var-002:0:0:0 -> 済

【処理種別】
glyphmake でglyphデータだけ作成するモード -> このスクリプトがそれになりました。

【tweさん指摘分】
・関連字未定義(147) -> 済
・関連字不一致(78) -> 例の33字はそのまま、ABA型の半分はuXXXXのswapでOKな気がする,そうでもないな... AAB型(49647, 49882, 39276, 31695)は要調査
・エイリアス不一致(16) -> 42737,00214,32948,月/肉月はガチ・kosekiエイリアスへ、福𩄮はswap、あと2つは要調査

【マイページ】
石井明朝の字体設計として、以下の部分字形を持つ文字を機械的に差し替えています。
ただし、ダッシュ付き当用漢字や補巻収録字などで適用外になっているものも不要に処理してしまっているので、のちほど要リバート。

]]
