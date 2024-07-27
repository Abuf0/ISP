#!/usr/bin/python

import numpy as np
from PIL import Image
import cv2
from matplotlib import pyplot as plt

class DPC:
    'Dead Pixel Correction'

    def __init__(self, img, thres, mode, clip):
        self.img = img
        self.thres = thres
        self.mode = mode
        self.clip = clip

    def padding(self):
        #在四周放两个0 从(1080,1920) --->(1084,1924)
        img_pad = np.pad(self.img, (2, 2), 'reflect')
        return img_pad

    def clipping(self):
        
        #np.clip是一个截取函数，用于截取数组中小于或者大于某值的部分，并使得被截取部分等于固定值
        #限定在()0,1023
        np.clip(self.img, 0, self.clip, out=self.img)
        return self.img

    def execute(self):
        img_pad = self.padding()
        raw_h = self.img.shape[0]
        raw_w = self.img.shape[1]
        print(raw_h)
        print(raw_w)
        dpc_img = np.empty((raw_h, raw_w), np.uint16)
        for y in range(img_pad.shape[0] - 4):
            for x in range(img_pad.shape[1] - 4):
                p0 = img_pad[y + 2, x + 2]
                p1 = img_pad[y, x]
                p2 = img_pad[y, x + 2]
                p3 = img_pad[y, x + 4]
                p4 = img_pad[y + 2, x]
                p5 = img_pad[y + 2, x + 4]
                p6 = img_pad[y + 4, x]
                p7 = img_pad[y + 4, x + 2]
                p8 = img_pad[y + 4, x + 4]
                arr_p = np.array([((p1 - p0) > self.thres),((p2 - p0) > self.thres),((p3 - p0) > self.thres),((p4 - p0) > self.thres),((p5 - p0) > self.thres),((p6 - p0) > self.thres),((p7 - p0) > self.thres),((p8 - p0) > self.thres)])
                arr_n = np.array([(-(p1 - p0) > self.thres),(-(p2 - p0) > self.thres),(-(p3 - p0) > self.thres),(-(p4 - p0) > self.thres),(-(p5 - p0) > self.thres),(-(p6 - p0) > self.thres),(-(p7 - p0) > self.thres),(-(p8 - p0) > self.thres)])

                #if (abs(p1 - p0) > self.thres) and (abs(p2 - p0) > self.thres) and (abs(p3 - p0) > self.thres) \
                #        and (abs(p4 - p0) > self.thres) and (abs(p5 - p0) > self.thres) and (abs(p6 - p0) > self.thres) \
                #        and (abs(p7 - p0) > self.thres) and (abs(p8 - p0) > self.thres):
                if(arr_p.all() or arr_n.all()):
                    #print("go")
                    if self.mode == 'mean':
                        p0 = (p2 + p4 + p5 + p7) / 4
                    elif self.mode == 'gradient':
                        dv = abs(2 * p0 - p2 - p7)
                        dh = abs(2 * p0 - p4 - p5)
                        ddl = abs(2 * p0 - p1 - p8)
                        ddr = abs(2 * p0 - p3 - p6)
                        if (min(dv, dh, ddl, ddr) == dv):
                            p0 = (p2 + p7 + 1) / 2
                        elif (min(dv, dh, ddl, ddr) == dh):
                            p0 = (p4 + p5 + 1) / 2
                        elif (min(dv, dh, ddl, ddr) == ddl):
                            p0 = (p1 + p8 + 1) / 2
                        else:
                            p0 = (p3 + p6 + 1) / 2
                dpc_img[y, x] = p0
        self.img = dpc_img
        return self.clipping()
# 打开图像文件
#img = Image.open('img.jpg')

# 获取原始像素数据

# 读取图像
raw_data = cv2.imread('bayer_img.jpg',cv2.IMREAD_UNCHANGED)
# b, g, r = cv2.split(raw_data)
#plt.show()
print(50*'-' + '\nLoading RAW Image Done......')

# dead pixel correction
thres = 180
clip = 1000
# obj_b = DPC(b,thres,'mean',clip)
# obj_g = DPC(g,thres,'mean',clip)
# obj_r = DPC(r,thres,'mean',clip)
# dpc_b = obj_b.execute()
# dpc_g = obj_g.execute()
# dpc_r = obj_r.execute()
obj = DPC(raw_data,thres,'mean',clip)
dpc_data = obj.execute()
#dpc_data = cv2.merge([dpc_b, dpc_g, dpc_r])

print(50*'-' + '\nDead Pixel Correction Done......')

cv2.imwrite('bayer_img_dpc.jpg', dpc_data)

## CV2(BGR) --> PLT(RGB)

raw_data_rgb = cv2.cvtColor(raw_data, cv2.COLOR_BayerRGGB2BGR)
# dpc_b_rgb = cv2.cvtColor(dpc_b, cv2.COLOR_BGR2RGB)
# dpc_g_rgb = cv2.cvtColor(dpc_g, cv2.COLOR_BGR2RGB)
# dpc_r_rgb = cv2.cvtColor(dpc_r, cv2.COLOR_BGR2RGB)
dpc_data_rgb = cv2.cvtColor(dpc_data, cv2.COLOR_BayerRGGB2BGR)

cv2.imwrite('img_dpc.jpg',dpc_data_rgb)

# plt.figure()
# plt.subplot(2,3,1)
# plt.imshow(raw_data_rgb)
# plt.subplot(2,3,4)
# plt.imshow(dpc_b_rgb)
# plt.subplot(2,3,5)
# plt.imshow(dpc_g_rgb)
# plt.subplot(2,3,6)
# plt.imshow(dpc_r_rgb)
# plt.subplot(2,3,3)
# plt.imshow(dpc_data_rgb)
# plt.show()
