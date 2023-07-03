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

local reptable = {}

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


local getjsonlocal = (function()
   print("gw definition loading..")

   local cmd = ("grep -E '^ u(2[0-9a-f]|[3-9])[0-9a-f]{3}(-jv?)* ' ../gwdiff/cgi/gw1205/dump_newest_only.txt");
   local s = execcmd(cmd);
   local ret = {};
   for s0 in s:split_it("\n") do
      local m = s0:split('|');
      local u = m[1]:trim():match('(u%x+)');
      local glyph = m[3]:trim()
      if (not glyph:match("99:0:0:0:0:200:200:[^:]+$")) then
         ret[u] = m[2]:trim() .. '|' .. glyph;
--         print(u, m[2], glyph);
      end
   end
   return ret;
end)()


local getjson = function(page)
   local j = getjsonlocal[page];
   if (j) then
      local m = j:split("|");
      return m[2]:trim(), m[1]:trim()
   end
   local cmd = ("grep '^ %s ' ../gwdiff/cgi/gw1205/dump_newest_only.txt"):format(page);
   local ret = execcmd(cmd);
   local m = ret:split('|');

   if (m) then
      return m[3]:trim(), m[2]:trim()
   end
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


local ucs2c = function(ucs)
   local hex = ucs:match("u(%x+)");
   if (not hex) then return "〓"; end
   return utf8.char(tonumber("0x" .. hex));
end

local toparts = {}

-- 行内からpcode関連のものを探して可能なら差し替える
--[[
・foundのうち、GW実体定義から以下に分類
　- targetが単独筆画と化しているもの ==　ref
　- targetが偏化部品でその-g版が未定義なもの == undef
　-  上記以外 == success
]]
local find_and_replace = function(gline, pcode)
   local lined = gline:split(":")

   -- 部品参照しているか?
   if (lined[1] ~= "99") then
      return false, gline;
   end

   local target = ("u%x"):format(pcode);
   local alias = lined[8]:split("@")[1];   

   -- 参照名がtarget表現と異なる場合(ajとか補助漢字とか)は変換
   if (alias:match("^u2967f")) then
      alias = alias:gsub("u2967f", ("u%x"):format(utf8.codepoint("飠")), 1)
   end

   -- targetを部品参照しているか?
   if (not alias:match(target)) then
      return false, gline;
   end

   -- 処置不要なものは処置しない
   for _, p in ipairs({"u706b-01"}) do
      if (alias == p) then
         return p, table.join(lined, ":");
      end
   end

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
         (refglyph[2]:match("^dkw%-") and undone(refglyph[2])) and ("unreg:" .. refglyph[2] .."(" .. utf8.char(pcode) .. ")") or nil;
      end
   end

   -- 定義がない"99"は uXXXX-gに直差し替え
   -- 部品参照が different from j-source?
   local is_simple = (target == alias)
      or (alias:match("^" .. target .. "%-[jkth]v?$"))
      or (alias:match("^" .. target .. "%-var%-%d%d%d$"));
   if (is_simple) then
      lined[8] = target .. '-g';
      return 'success', table.join(lined, ":")
   end

   -- すでにgsrc
   if (alias:find(target.."%-g") == 1) then
       return alias, table.join(lined, ":")
   end   

   -- "-01"系偏化
   local part = alias:match(target .. "%-[tkjh]?(%d%d)")
   if (part and toparts[target .. "-g" .. part]) then
      lined[8] = target .. "-g" .. part;
      return 'success', table.join(lined, ":")
   end
   
   -- alias に "-ue0xxxx"とか"-itaiji-xxx"とかついちゃってる模様
   return "undef", gline, ("undef:" .. lined[8] .. "(" .. utf8.char(pcode)  .. ")");
end


local get_glyph = function(ucs)
   local data,c = getjson(('u%x'):format(ucs));
   -- 実体でなければ実体にアクセス
   local m = data:match("^99:0:0:0:0:200:200:([^:]+)$");
   if (m) then
      data,c = getjson(m);
   end
   return data, c;
end



local map_ucs2c = function(tbl, sep)
   local ret = ""
   sep = sep or ""
   for n, v in pairs(tbl) do
--       print(v)
      if ret == "" then
         ret = utf8.char(v)
      else
         ret = ret .. sep .. utf8.char(v)
      end
   end
   return ret;
end

local dump_result = function(ucs, glyph, cat, parts)
   print(('u%x-g[%s]    %s  %s %s'):format(ucs, utf8.char(ucs), glyph, cat, parts and map_ucs2c(parts) or ""));
end


local replace_parts = function(parts, ucs)
   --glyphデータと関連字を得る
   local data,c = get_glyph(ucs);

   -- print(data,c);
   local ms = data:split("$");
   local done = {};
   local undef = {};

   -- 目的の部品があるか探す -> 
   for i, pcode in ipairs(parts) do
      -- 1行ずつ見る
      for _, line in ipairs(ms) do
         local ret, und;
         ret, line, und = find_and_replace(line, pcode);

         -- 見つかった
         if (ret) then
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
      dump_result(ucs, data, "##"..table.join(undef, ",") .. "!=", parts);
      return
   end
   -- 見つからないものがある
   if (#done ~= #parts) then
      dump_result(ucs, data, "##noparts:" .. table.join(done, ";"), parts);
      return;
   end

   -- 処置不要
   if (table.join(ms, "$") == data) then
      return dump_result(ucs, "[[" .. ("u%x"):format(ucs) .. "]]", "##success:unhandled:"..table.join(done, ";"), parts); 
   end

   return dump_result(ucs, table.join(ms, "$"), "##success:"..table.join(done, ";"), parts); 
end


-- 版5:undoneなものをすべて検証する
local crawl_table = function(e0, e1)

   local extraunhandled = "氵冫日冖灬癶艹扌土";
   local undone, unhandled, totarget = (function()
      print("undone list loading..")
      local u = {d="",h="",t=""};
      local fp = io.open("g.undone.dat","r")
      for line in fp:lines() do
          local s = line:trim():split("\t")
          if (s[2] == 'p') then
             toparts[s[1]] = true;
          elseif (extraunhandled:find(s[2])) then
            u.h = u.h .. s[2]
          else
            u[s[3]] = u[s[3]] .. s[2]
          end
      end
      fp:close();
      return u.d, u.h, u.t;
   end)()


--[[
・未登録分のうち、IDSデータから以下に分類
　- undoneを含むもの == undef
　- cdpを含むもの == jittai　→　逐次reptable/unhandledに定義しfound/a扱い
　- target＋unhandledだけからなるもの == found
　- unhandledだけからなるもの == a　→　目視確認へ
]]
   local get_target = function(ucs)
      local ucs0 = (ucs < 0x9fff and 'U+%04X' or 'U-%08X'):format(ucs);
      local cmd = ("grep '%s' ../../kids/IDS-*.txt"):format(ucs0);
      local ret = execcmd(cmd);
      rets = ret:split("\t")

      -- manual
      local set = rets[3]:match('%&[^;]+;');
      if (set) then
         --print(ret, set);
         return '#jittai:' .. set
      end

      local target = {};
      for p, c in utf8.codes(rets[3]:trim()) do
              --  print(p, ('0x%x'):format(c), utf8.char(c));
          local s = utf8.char(c);
          if (undone:find(s)) then
             return '#undef:' .. s;
          end
          if (0x3000 < c) then
             if (totarget:find(s)) then
                target[#target + 1] = c;
             elseif (not unhandled:find(s)) then
                return '#nogsrc:' .. s;
             end
          end
      end

      return target;
  end


   local pickups = function(ucs)
      local c = utf8.char(ucs);
      if (not undone:find(c)) then
         return;
      end

      local target = get_target(ucs); 

      if (type(target) == 'string') then
         return dump_result(ucs,  "_", "#" .. target);
      end
      if (#target == 0) then
         return dump_result(ucs,  "[[" .. ("u%x"):format(ucs) .. "]]", "##a");
      end

       --dump_result(ucs, "_", "##found:" .. table.join(target, ','));
       return replace_parts(target, ucs);
   end

   for i = e0, e1 do
        pickups(i);
   end
end

if (#arg ~= 3) then
   help();
   return;
end

local e0 = tonumber('0x' .. arg[2]);
local e1 = tonumber('0x' .. arg[3]);
if (e0 > e1) then
   help();
   return;
end
crawl_table(e0, e1);



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

[Design]
だいたいdkw replaceのときと同じやりかた
・GWから以下を抽出
　undone    == 未登録-g
　target    == -g と -j/t/無印 とが異なるもの
　unhandled == -g と -j/t/無印 とが同じ

・未登録分のうち、IDSデータから以下に分類
　- undoneを含むもの == undef
　- cdpを含むもの == manual　→　逐次reptable/unhandledに定義しfound/a扱い
　- target＋unhandledだけからなるもの == found
　- unhandledだけからなるもの == a　→　目視確認へ

・foundのうち、GW実体定義から以下に分類
　- targetが単独筆画と化しているもの ==　ref
　- targetが偏化部品でその-g版が未定義なもの == undef
　-  上記以外 == success
・aとsuccessを目視確認

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




]]
