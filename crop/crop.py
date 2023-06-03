import cv2
import numpy as np

img = cv2.imread("0603.png")

# グレースケール
img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
img_con = img.copy()

# 2値化
_, im_bw = cv2.threshold(img_gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

# 輪郭検出
contours, hierarchy = cv2.findContours(im_bw, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

import json
#print(json.dumps(list(enumerate(contours))))

# 画像内の輪郭の端を探す
def findnum():
    ret = []
    for i,contour in enumerate(contours):
        x, y, w, h = cv2.boundingRect(contours[i])
        if (5 < w and w < 20  and 10 < h and h < 30):
            cv2.rectangle(img_con, (x,y),(x+w,y+h),(255,200,200), cv2.LINE_4)
            ret.append([x,y,w,h])
            #print(w,h , x,y)
            continue
            for point in contour:
                col = ((0, 255, 0), (255, 127, 0), (255, 0, 0), (0, 127, 255), (0, 0, 255))
                cv2.circle(img_con, point[0], 1, col[i%5], -1)

    print(ret)
    #cv2.imwrite("0603dxx.png", img_con)
    return ret
    for i,a in enumerate(ret):
        for b in ret[i+1:]:
            if (-20 < b[1] - a[1] and b[1] - a[1] < 20): b[1] = a[1]

    for y in (sorted(set(list(map(lambda x: x[1], ret))))):
        s0 = list(filter(lambda x: x[1] == y, ret))
        print(y,sorted([x[0] for x in s0]))
    return ret


# imgの中からpの位置の文字をセルフテンプレートマッチする
def find_numbers(img, p):
    x,y,w,h=p
    threshold = 0.9
    ret = []
    imgsample = img_gray[y-1:y+h+1,x-1:x+w+1]

    result = cv2.matchTemplate(img, imgsample, cv2.TM_CCOEFF_NORMED)
    loc = np.where(result >= threshold)

    locs = list(zip(*loc[::-1]))
    return len(locs)
    for pt in zip(*loc[::-1]):
        ret.append([pt[0],pt[1]])
        #print(ret)
    return len(ret)

edge = findnum()
x=edge[2]
print(x)
for i,p in enumerate(edge):
    if (p[2]<x[2] or p[3] <x[3]): continue
    s = find_numbers(img_gray[x[1]-1:x[1]+x[3]+1,x[0]-1:x[0]+x[2]+1], p);
    if (0 < s):
        cv2.rectangle(img_con, (p[0],p[1]), (p[0] + p[2], p[1] + p[3]), (255,0,0), 2)
    print(s,p)
cv2.imwrite("hoge.png", img_con);
exit()
print(x)
cv2.imwrite("testbox.png", img[x[1]-1:x[1]+x[3]+1,x[0]-1:x[0]+x[2]+1]);
ret = find_numbers(img_gray,x)
print(ret)
for pt in ret:
    cv2.rectangle(img_con, pt, (pt[0] + x[2], pt[1] + x[3]), (255,0,0), 2)
cv2.imwrite("0603dxx.png", img_con)
