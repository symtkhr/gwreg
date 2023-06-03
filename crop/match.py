
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
    cv2.imwrite("tmpnummini.png", temp0g)

    # 2値化して輪郭検出
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
    return ret

# 数字をテンプレートマッチする
def find_numbers(img = fp["gray"], samples = fp["sample"], threshold = 0.9):
    ret = []
    for i,sample in enumerate(samples):
        result = cv2.matchTemplate(img, sample, cv2.TM_CCOEFF_NORMED)
        loc = np.where(result >= threshold)

        for pt in zip(*loc[::-1]):
            ret.append([pt[0], pt[1], (i + 1) % 10])

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
        if (yd1 < 5): y1 += int(10 * rate)
        if (xd0 < 5): x0 -= int(17 * rate)
        if (xd1 < 5): x1 += int(17 * rate)
        if (xd0 < 5 or xd1 < 5 or yd0 < 5 or yd1 < 5):
            if (i == 9): fname = "m" + fname
            continue
        break

    rename = False
    if (not("m" in fname) and (len(fname) < digits)):
        rename = True
        nump = find_numbers(fp["gray"][y1-40:y1,x0:x1], fp["sample"], 0.8)
        ngs = group_numbers(nump)
        if (len(ngs) > 0 and digits <= len(ngs[0][0])): fname = ngs[0][0]

    if (20 < (x1 - x0) - (y1 - y0)): fname = "md" + fname
    print([fname, x0, x1, y0, y1], rename)
    return [fname, x0, x1, y0, y1];

    path = fp["dir"] + fname + ".png"
    i=0
    while (os.path.exists(path)):
        i+=1
        path = fp["dir"] + fname + "-" + str(i) + ".png"
    print("dump " + path, y1-y0, x1-x0)
    #cv2.imwrite(path, fp["load"][y0:y1,x0:x1])

def main(args):
    fpath = args[0]
    rate   = float(args[1])/64  if 1 < len(args) else 1.0
    digits = int(args[2])  if 2 < len(args) else 5

    # 読み取りデータ
    fp["load"] = cv2.imread(fpath)
    # 出力先
    fp["dump"] = fp["load"].copy()

    # 数字の位置を割り出す
    fp["sample"] = get_templates(rate)
    fp["gray"] = cv2.cvtColor(fp["load"], cv2.COLOR_BGR2GRAY)
    nump = find_numbers(fp["gray"], fp["sample"])
    #exit()
    #draw_nump(nump)

    # グループ化して位置と番号を割り出す
    ngs = group_numbers(nump)
    draw_ngs(ngs)

    # 切り出す
    # Todo: gがすでにcropboxの返りに含まれていれば除去
    crops = [cropbox(g, rate, 5) for g in ngs]
    crops = sorted(crops)

    # 面付け
    w0 = max([(0 if ("m" in c[0]) else c[2]-c[1]) for c in crops])
    h0 = max([(0 if ("m" in c[0]) else c[4]-c[3]) for c in crops])
    print(crops, "cell", w0, h0)

    row = 20
    fp["dump"] = np.ones((int(1 + len(crops) / row) * h0, row * w0), np.uint8) * 255

    for i,c in enumerate(crops):
        x = (i % row) * w0
        y = int(i / row) * h0
        name,x0,x1,y0,y1 = c
        w = x1 - x0
        h = y1 - y0
        if (w0 < w or h0 < h): continue
        print(name, end=" ")
        fp["dump"][y:y+h, x:x+w] = fp["gray"][y0:y1,x0:x1]
    print()

    # 出力
    fname = fpath.split("/")[-1].split(".")[0] + "crop" + str(w0) + "x" + str(h0) + ".png"
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
    print("argv[1] = input png")
    exit()
    
#renamer_test()
import sys
if (len(sys.argv) < 2): help()
main(sys.argv[1:])

