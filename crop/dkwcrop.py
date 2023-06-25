import cv2
import numpy as np
import sys

def help() :
    #for i, n in enumerate(filter(lambda c: c %2, [1,2,3])): print(i,n)
    print("argv = [input png file, dkw_start, dkw_end],")
    exit()

if (len(sys.argv) < 4): help()
args = sys.argv[1:]
"""
w = 16
w0 = w*(digit+2)*rate
h0 = 50*rate
#print(sorted(res), len(res))
"""
img0 = cv2.imread(args[0])
imgray0 = cv2.cvtColor(img0, cv2.COLOR_BGR2GRAY)
fp = {"gray":imgray0, "load":img0, "dump":[]}
dkwrange = range(int(args[1]), int(args[2]))
croplen = int(args[3])
debug = True

# 画像内で数字っぽいサイズ感のものを拾って縮尺を返す
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
            #cv2.rectangle(fp["dump"], (x, y), (x+w, y+h), (0,255,0), 2)
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

    h0 = max([p[3] for p in row])

    #print(h0)
    if (24 < h0): return 1
    return (h0/24)

rate = profilenum()

# 画像内でdkw番号を拾う
def find_dkwnum():
    print("rate",rate)
    temp0 = cv2.imread("numfont00.png")
    temp0g = cv2.cvtColor(temp0, cv2.COLOR_BGR2GRAY)
    w = 16

    res = []
    if (debug): img = img0
    imgray = fp["gray"].copy()
    for dkw in dkwrange:
        digit = len(str(dkw))
        
        # サンプル画像を作る
        sample = np.ones((50, w * (digit + 2)), np.uint8) * 255
        for i in range(digit):

            # 補巻の場合
            if (dkw < 0 and i == 0):
                ho = cv2.imread("ho.png")
                ho = cv2.cvtColor(ho, cv2.COLOR_BGR2GRAY)
                fig = ho[0:,-33:-1]
                sample[5:45, 0:32] = fig
                sample = sample[0:,:-w]
                continue
            
            n = int(str(dkw)[i])
            fig = temp0g[0:,n*25+1:n*25+w+1]
            if (n == 1): fig = temp0g[0:,n*25-3:n*25+w-3]
            sample[5:35, (i+1)*w:(i+2)*w] = fig

        # 付録巻の場合
        #if (49002 < dkw): sample = sample[0:,w:-w]
        sample = cv2.resize(sample, None, None, rate, rate)

        cv2.imwrite("b.png", sample)
        #exit()
        
        # 当てはまる箇所を拾う
        result = cv2.matchTemplate(imgray, sample, cv2.TM_CCOEFF_NORMED)

        if (True):
            loc = np.where(result >= 0.6)
            pts = [pt for pt in zip(*loc[::-1])]
            res0 = []

            for pt in pts:
                # 見つかったところから塗りつぶしていく
                #cv2.rectangle(imgray, (pt[0],pt[1]), (pt[0]+len(sample[0]),pt[1]+len(sample)), (255,255,255), thickness=-1)
                # 近接すぎる同じ値は無視
                if (next(filter(lambda p: (p[0] - pt[0])**2 + (p[1] - pt[1]) ** 2 < 100, res0), None) == None):
                    res0.append([pt[0],pt[1],len(sample[0]),len(sample)])
                    if(debug): cv2.rectangle(img, (pt[0],pt[1]), (pt[0]+len(sample[0]),pt[1]+len(sample)), (255,0,0), 2)
            print()
            print(dkw,end=":")
            crops = [cropbox(g, dkw) for g in res0]
            crops = [list(p) for p in set(map(tuple, crops)) if p[0] != -1]
            # 見つかったところから塗りつぶしていく
            for x0,x1,y0,y1 in crops:
                if (debug): cv2.rectangle(img, (x0,y0), (x1,y1), (255,255,0), 2)
                cv2.rectangle(imgray, (x0,y0), (x1,y1), (255,255,255), thickness=-1)
                
            res += crops
        if (False):
            minVal, maxVal, minLoc, maxLoc = cv2.minMaxLoc(result)
            pt = maxLoc
            cv2.rectangle(img, (pt[0],pt[1]), (pt[0]+len(sample[0]),pt[1]+len(sample)), (0,0,255), 2)
            print(dkw,maxVal, maxLoc)
        if (debug):
            cv2.imwrite("g.png", imgray)
            cv2.imwrite("a.png", img)
        if (croplen <= len(res)): break
    #print(res)
    return res

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

# hit = [x0,y0,w,h]
def cropbox(hit, dkw):
    imgray = fp["gray"]

    # 検出位置の上下左右端の位置を切り出す
    x0 = hit[0]
    x1 = hit[0] + hit[2]
    y0 = hit[1] - hit[3]
    y1 = hit[1] + hit[3]
    move = int(10 * rate)

    # 付録巻の場合
    if (48902 < dkw):
        y0 -= hit[3]
        move = int(5 * rate)

    # その内周5pxがすべて白である判定、だめなら拡大しながら再判定
    _, nega = cv2.threshold(imgray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    valid = True
    for i in range(5):
        if (y0 < 0): y0 = 0
        if (x0 < 0): x0 = 0
        crop = nega[y0:y1, x0:x1]
        xd0,xd1,yd0,yd1 = find_whitespace(crop)
        if (yd0 < 5): y0 -= move
        if (xd0 < 5): x0 -= move
        if (xd1 < 5): x1 += move
        if (xd0 < 5 or xd1 < 5 or yd0 < 5 or yd1 < 5):
            if (i == 4):
                print("x", end="", flush=True)
                # 付録巻の場合
                if (48902 < dkw): break
                return [-1] #valid = False
            continue
        break

    print(i, end="", flush=True)

    # 空白調整
    if (valid):
        x0 = x0 + xd0 - 5 # 左端から5px
        y0 = y0 + yd0 - 5 # 上端から5px
        y1 = y1 - yd1 + 5 # 下端から5px
        x1 = x1 - xd1 + 5 # 右端から5px

    return [x0, x1, y0, y1];

def main():
    fpath = args[0]
    img = fp["load"]
    imgray = fp["gray"]

    crops = find_dkwnum()

    for pt in crops:
        cv2.rectangle(img,
                  (pt[0],pt[2]),
                  (pt[1],pt[3]),
                  (0,0,255), 2)

    if(debug): cv2.imwrite("a.png",img)

    # y=10px 以内の要素を同列として扱う
    crops = sorted(crops, key=lambda p: p[3])
    for i,p in enumerate(crops):
        if (i == 0):
            p.append(p[3])
        else:
            bef = crops[i - 1]
            p.append(p[3] if (10 < p[3] - bef[3]) else bef[4])
        #print(p)
    crops = sorted(crops, key=lambda p: (p[4], -p[0]))

    # 面付け
    tiles = crops
    w0 = max([(c[1]-c[0]) for c in tiles])
    h0 = max([(c[3]-c[2]) for c in tiles])

    row = 20
    fp["dump"] = np.ones((int(1 + len(tiles) / row) * h0, row * w0), np.uint8) * 255

    fname = fpath.split("/")[-1].split(".")[0] + "_" + str(len(tiles)) + "crop" + str(w0) + "x" + str(h0) + ".png"
    print("<<concat>>", fname)

    for i,c in enumerate(tiles):
        x0,x1,y0,y1 = c[:4]
        w = x1 - x0
        h = y1 - y0
        x = (i % row) * w0 + int((w0 - w) / 2) # 中央
        y = int(i / row) * h0 + h0 - h # 下詰め
        if (w0 < w or h0 < h): continue
        fp["dump"][y:y+h, x:x+w] = imgray[y0:y1,x0:x1]

    # 出力
    cv2.imwrite(fname, fp["dump"])

print(args)
main()
