
import cv2
import numpy as np
import os

# 入出力共通
fp = {"gray":[], "load":[], "dump":[], "dir":"", "sample":[]}

# テンプレートを生成する(0102用)
def get_templates0102():
    temp0 = cv2.imread("tmpnum.png")
    temp0g = cv2.cvtColor(temp0, cv2.COLOR_BGR2GRAY)
    return [
        temp0g[
            (0 if (i<5) else 33):(33 if (i<5) else 64),
            (i%5)*17:(i%5)*17+17
        ] for i in range(10)
    ]

# テンプレートを生成する(0603用)
def get_templates(rate = 1):
    temp0 = cv2.imread("tmpnum.png")
    temp0g = cv2.cvtColor(temp0, cv2.COLOR_BGR2GRAY)
    temp0g = cv2.resize(temp0g, None, None, rate, rate)
    _, tempbw = cv2.threshold(temp0g, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    contours, hierarchy = cv2.findContours(tempbw, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # 座標位置を取得
    ps = [cv2.boundingRect(contour) for contour in contours]
    ps = sorted(ps, key=lambda p:(p[1] < 10 and p[0] or 200 + p[0]))

    wav = sum([p[2] for p in ps]) / len(ps)
    print(ps,wav)
    # テンプレ作成
    ret = []
    for p in ps:
        x,y,w,h = p
        if (w < wav):
            w = int(wav)
            x = x - int((wav-w)/2)
        ret.append(temp0g[y-1:y+h+1, x-1:x+w+1])
    ret.insert(0,ret[9])

    """
    gray = cv2.cvtColor(fp["dump"], cv2.COLOR_BGR2GRAY)
    cv2.rectangle(gray, (0,0), (250,30), (255,255,255), thickness=-1)
    for i,sample in enumerate(ret):
        if (i==1):
            gray[1:1+len(sample), 2 + i*25:i*25+len(sample[0])] = sample[0:,:-2]
        else:
            gray[1:1+len(sample), 2 + i*25: 2+i*25+len(sample[0])] = sample
    cv2.imwrite("result00.png", gray[0:30, 0:25*10])
    exit()
    """
    return ret[:-1]


# テンプレートを生成する(numfont使用)
def get_templates(rate = 1):
    # 15x25フォントを読み込む
    temp0 = cv2.imread("numfont00.png")
    temp0g = cv2.cvtColor(temp0, cv2.COLOR_BGR2GRAY)
    temp0g = cv2.resize(temp0g, None, None, rate, rate)
    _, tempbw = cv2.threshold(temp0g, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    contours, hierarchy = cv2.findContours(tempbw, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # 座標位置を取得
    ps = [cv2.boundingRect(contour) for contour in contours]
    ps = sorted(ps)
    wav = sum([p[2] for p in ps]) / len(ps)
    print(ps,wav)
    # テンプレ作成
    ret = []
    for p in ps:
        x,y,w,h = p
        if (w < wav):
            w = int(wav)
            x = x - int((wav-w)/2)
        ret.append(temp0g[y-1:y+h+1, x-1:x+w+1])
    #return [cv2.resize(s, None, None, rate, rate) for s in ret]

    return ret

# 画像内で数字っぽいサイズ感のものを洗う
def profilenum():
    img = fp["gray"]
    # 2値化して輪郭検出
    _, tempbw = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    contours, hierarchy = cv2.findContours(tempbw, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    ret = []
    # w = 5-20px, h = 10-30pxの要素を集める
    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)
        if (5 < w and w < 20  and 10 < h and h < 30):
            ret.append([x,y,w,h])
            cv2.rectangle(fp["dump"], (x, y), (x+w, y+h), (0,255,0), 2)
    ret = sorted(ret, key=lambda p: p[1])

    # y=2px 以内の要素を同列として扱う
    for i,p in enumerate(ret):
        if (i == 0):
            p.append(p[1])
        else:
            bef = ret[i - 1]
            p.append(p[1] if (2 < p[1] - bef[1]) else bef[4])
        #print(p)

    # 最も要素の多い列を拾う
    row = []
    for n in set([p[4] for p in ret]):
        ps = list(filter(lambda p: p[4] == n, ret))
        if (len(row) < len(ps)): row = ps

    x0 = min([p[0] for p in row])
    y0 = min([p[1] for p in row])
    x1 = max([p[0]+p[2] for p in row])
    y1 = max([p[1]+p[3] for p in row])
    w0 = max([p[2] for p in row])
    h0 = max([p[3] for p in row])

    print("w=", set([p[2] for p in row]), "h=",set([p[3] for p in row]))

    # 列内の要素サイズでサンプルを縮小する
    samples = get_templates()
    print("resize", w0/15, h0/24)
    samples = [cv2.resize(sample, None, None, h0/24, h0/24) for sample in samples]
    return samples, (h0/24)


# 画像内でdkw番号を拾う
def find_dkwnum():
    samples, rate = profilenum()
    temp0 = cv2.imread("numfont00.png")
    temp0g = cv2.cvtColor(temp0, cv2.COLOR_BGR2GRAY)
    w = 16

    for dkw in range(21683,21822):
#        dkw = 21737
        digit = len(str(dkw))
        sample = np.ones((50, w * (digit + 2)), np.uint8) * 255
        for i in range(digit):
            n = int(str(dkw)[i])
            fig = temp0g[0:,n*25+1:n*25+w+1]
            if (n == 1): fig = temp0g[0:,n*25-3:n*25+w-3]
            sample[5:35, (i+1)*w:(i+2)*w] = fig

            #rate = 0.7
        print("rate=",rate)
        sample = cv2.resize(sample, None, None, rate, rate)

        cv2.imwrite("b.png", sample)
        result = cv2.matchTemplate(fp["gray"], sample, cv2.TM_CCOEFF_NORMED)

        img = fp["load"]
        if (True):
            loc = np.where(result >= 0.8)
            for pt in zip(*loc[::-1]):
                cv2.rectangle(img, (pt[0],pt[1]), (pt[0]+len(sample[0]),pt[1]+len(sample)), (255,0,0), 2)
                print(pt, result[pt[1],pt[0]])
        minVal, maxVal, minLoc, maxLoc = cv2.minMaxLoc(result)
        pt = maxLoc
        cv2.rectangle(img, (pt[0],pt[1]), (pt[0]+len(sample[0]),pt[1]+len(sample)), (0,0,255), 2)
        print(dkw,maxVal, maxLoc)
    cv2.imwrite("a.png", img)

    
# 数字をテンプレートマッチする
def find_numbers(img = fp["gray"], samples = fp["sample"], threshold = 0.9):
    ret = []
    for i,sample in enumerate(samples):
        result = cv2.matchTemplate(img, sample, cv2.TM_CCOEFF_NORMED)
        loc = np.where(result >= threshold)

        for pt in zip(*loc[::-1]):
            ret.append([pt[0], pt[1], (i + 0) % 10])

        # テスト用. 画面上に生成
        if (fp["dump"].any):
            h0,w0 = sample.shape[:2]
            fp["dump"][0 : h0, 20*i : 20*i+w0] = cv2.cvtColor(sample, cv2.COLOR_GRAY2BGR)

    return ret


def draw_nump(nump):
    print(nump)
    for pt in nump:
        #print(pt)
        w = 11
        h = 18
        col = [(0,0,127),(0,0,255),(0,127,255),(0,255,255),(0,127,0),
               (255,0,0),(255,0,255),(127,127,127),
               (127,0,0),(0,127,127),
        ][pt[2]]
        cv2.rectangle(fp["dump"], (pt[0], pt[1]), (pt[0] + w, pt[1] + h), col, 2)

        
    cv2.imwrite("result.png", fp["dump"])
    

def draw_ngs(ngs):
    for g in ngs:
        print(g)
        pts = g[1]
        y = max([pt[1] for pt in pts])
        x = max([pt[0] for pt in pts])
        cv2.rectangle(fp["dump"], (pts[0][0], pts[0][1]), (x + 11, y + 18), (255,0,0), 2)
        cv2.putText(fp["dump"], g[0], (pts[0][0], pts[0][1] + 40), cv2.FONT_HERSHEY_PLAIN, 0.8, (0,0,255), 1, cv2.LINE_AA)
    cv2.imwrite("result.png", fp["dump"])

    
# 数字位置をグループ化した位置とその文字列を返す
def group_numbers(nump):
    # x軸の順に並べる
    nump = sorted(nump)
    for i,a in enumerate(nump):
        # 自分の要素値を近所マークとする
        if (len(a) == 3): a.append(i)
        # 自分より右側近所のものを探す
        for b in nump[i+1:]:
            if ((b[0] <= a[0] + 25) and
                (a[1] - 8 <= b[1]) and
                (b[1] <= a[1] + 8)):
                # 見つかったら近所マーク
                if (len(b) == 3): b.append(a[3])
                b[3] = a[3]
    ret = []

    for n in set(list(map(lambda x: x[3], nump))):
        if (n < 0): continue
        # 近所マーク同士で統合
        s0 = list(filter(lambda x: x[3] == n, nump))
        s = []
        for i,si in enumerate(s0):
            # 近接すぎる同じ値は無視
            if (i == 0 or si[2] != s0[i-1][2] or 7 < si[0]  - s0[i-1][0]):
                s.append(si[0:3])
        key = "".join([str(s0[2]) for s0 in s])
        pos = [s0[0:2] for s0 in s]
        ret.append([key,pos])
        #ret.append(s)
    return ret



# 切り出した範囲の左右上下の白幅を返す. 左右上下=1,1,1,1が返ってくれば枠内ギリギリ
def find_whitespace(fig):
    x0,y0,x1,y1 = -1,-1,-1,-1
    #print("y", len(fig), "x",len(fig[0]))
    for y,row in enumerate(fig):
        for x,p in enumerate(row):
            if (p == 255):
                if (x0 < 0 or x < x0): x0 = x
                if (y0 < 0): y0 = y
                if (x1 < 0 or x1 < x): x1 = x
                y1 = y
    return x0,len(fig[0])-1-x1,y0,len(fig)-1-y1





# group = ["filename", [position]]
def cropbox(group, rate = 1, digits = 5):
    fname = group[0]
    hits = group[1]
    hit = hits[0]
    width = len(hits)

    # グループの上端-100:上端+40、左端-30 左端+17*文字数+30の位置を切り出す
    y0 = hit[1] - int(100 * rate)
    y1 = hit[1] + int(40 * rate)
    x0 = hit[0] - int(10 * rate)
    x1 = hit[0] + int((17 * width + 10) * rate)

    # その内周5pxがすべて白である判定、だめなら拡大しながら再判定
    _, nega = cv2.threshold(fp["gray"], 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    for i in range(10):
        if (y0 < 0): y0 = 0
        if (x0 < 0): x0 = 0
        crop = nega[y0:y1, x0:x1]
        xd0,xd1,yd0,yd1 = find_whitespace(crop)
        #print(xd0,xd1,yd0,yd1)
        if (yd0 < 5): y0 -= int(10 * rate)
        #if (yd1 < 5): y1 += int(10 * rate)
        if (xd0 < 5): x0 -= int(17 * rate)
        if (xd1 < 5): x1 += int(17 * rate)
        if (xd0 < 5 or xd1 < 5 or yd0 < 5 or yd1 < 5):
            if (i == 9): fname = "m" + fname
            continue
        break

    # Todo:左右の空白調整

    # 再命名
    rename = False
    if (not("m" in fname) and (len(fname) < digits)):
        rename = True
        nump = find_numbers(fp["gray"][y1-40:y1,x0:x1], fp["sample"], 0.8)
        ngs = group_numbers(nump)
        if (len(ngs) > 0 and digits <= len(ngs[0][0])): fname = ngs[0][0]

    if (20 < (x1 - x0) - (y1 - y0)): fname = "md" + fname
    print("*", end="", flush=True)
    #print([fname, x0, x1, y0, y1], rename)
    return [fname, x0, x1, y0, y1];

    path = fp["dir"] + fname + ".png"
    i=0
    while (os.path.exists(path)):
        i+=1
        path = fp["dir"] + fname + "-" + str(i) + ".png"
    print("dump " + path, y1-y0, x1-x0)
    #cv2.imwrite(path, fp["load"][y0:y1,x0:x1])



def main(args):
    print("argv=", args)
    fpath = args[0]
    rate   = args[1]  if 1 < len(args) else 1.0
    digits = int(args[2])  if 2 < len(args) else 5

    # 読み取りデータ
    fp["load"] = cv2.imread(fpath)
    # 出力先
    fp["dump"] = fp["load"].copy()

    # 数字の位置を割り出す
    fp["gray"] = cv2.cvtColor(fp["load"], cv2.COLOR_BGR2GRAY)
    find_dkwnum()
    exit()
    if (rate == "auto"):
        fp["sample"], rate = profilenum()
    else:
        rate = float(rate)/64
        fp["sample"] = get_templates(rate)
    nump = find_numbers(fp["gray"], fp["sample"])
    #exit()
    #draw_nump(nump)

    # グループ化して位置と番号を割り出す
    ngs = group_numbers(nump)
    ngs = sorted(ngs, key=lambda p: p[1][0][1])
    #draw_ngs(ngs)

    # 切り出す
    # Todo: gがすでにcropboxの返りに含まれていれば除去
    crops = [cropbox(g, rate, 5) for g in ngs]

    # y=10px 以内の要素を同列として扱う
    for i,p in enumerate(crops):
        if (i == 0):
            p.append(p[4])
        else:
            bef = crops[i - 1]
            p.append(p[4] if (10 < p[4] - bef[4]) else bef[5])
        #print(p)
    crops = sorted(crops, key=lambda p: (p[5], -p[1], p[0]))
    # 近接する要素は消す
    for i,p in enumerate(crops):
        if (i != 0 and abs(p[1] - crops[i - 1][1]) < 10): p[5] = -1


    # 面付け
    tiles   = list(filter(lambda c: (not "m" in c[0]) and 0 <= c[5], crops))
    untiles = list(filter(lambda c: (    "m" in c[0])  or  c[5] < 0, crops))
    w0 = max([(c[2]-c[1]) for c in tiles])
    h0 = max([(c[4]-c[3]) for c in tiles])

    row = 20
    fp["dump"] = np.ones((int(1 + len(tiles) / row) * h0, row * w0), np.uint8) * 255

    fname = fpath.split("/")[-1].split(".")[0] + "crop" + str(w0) + "x" + str(h0) + ".png"
    print("<<concat>>", fname)

    for i,c in enumerate(tiles):
        x = (i % row) * w0
        y = int(i / row) * h0
        name,x0,x1,y0,y1 = c[:5]
        w = x1 - x0
        h = y1 - y0
        print(name, end=" ")
        if (w0 < w or h0 < h): continue
        fp["dump"][y:y+h, x:x+w] = fp["gray"][y0:y1,x0:x1]
    
    print([c[0] for c in untiles])
    # 出力
    cv2.imwrite(fname, fp["dump"])
    
def renamer_test():
    img = cv2.cvtColor(cv2.imread("./dump0603/4.png"), cv2.COLOR_BGR2GRAY)
    print([[len(cs), len(cs[0])] for cs in get_templates()])
    nump = find_numbers(img[-35:,0:], get_templates(), 0.8)
    ngs = group_numbers(nump)
    print(ngs)
    cv2.imwrite("tmp.png", img[-35:])
    exit()

def help() :
    #for i, n in enumerate(filter(lambda c: c %2, [1,2,3])): print(i,n)
    print("argv = [input png file, rate, digit],")
    exit()

#renamer_test()
import sys
if (len(sys.argv) < 2): help()
main(sys.argv[1:])

