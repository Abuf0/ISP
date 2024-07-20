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
                arr = np.array([(abs(p1 - p0) > self.thres),(abs(p2 - p0) > self.thres),(abs(p3 - p0) > self.thres),(abs(p4 - p0) > self.thres),(abs(p5 - p0) > self.thres),(abs(p6 - p0) > self.thres),(abs(p7 - p0) > self.thres),(abs(p8 - p0) > self.thres)])
                #if (abs(p1 - p0) > self.thres) and (abs(p2 - p0) > self.thres) and (abs(p3 - p0) > self.thres) \
                #        and (abs(p4 - p0) > self.thres) and (abs(p5 - p0) > self.thres) and (abs(p6 - p0) > self.thres) \
                #        and (abs(p7 - p0) > self.thres) and (abs(p8 - p0) > self.thres):
                if(arr.all()):
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
raw_data = cv2.imread('img.jpg',cv2.IMREAD_GRAYSCALE)
#plt.imshow(raw_data)
#plt.show()
# 获取原始像素数据
#raw_data = img.tobytes()
# 获取图像尺寸 (width, height)
#width, height = img.size

# 获取图像模式（颜色模式）
#img_mode = img.mode
#rawimg = np.fromfile('./img.jpg', dtype='uint16', sep='')
#rawimg_b, rawimg_g , rawimg_r = cv2.split(raw_data)

print(50*'-' + '\nLoading RAW Image Done......')
# plt.imshow(rawimg, cmap='gray')
# plt.show()

# dead pixel correction
dpc0 = DPC(raw_data, 10, 'mean', 1023)
rawimg_dpc0 = dpc0.execute()
dpc1 = DPC(raw_data, 100, 'mean', 1023)
rawimg_dpc1 = dpc1.execute()
print(50*'-' + '\nDead Pixel Correction Done......')


plt.figure()
plt.subplot(2,2,1)
plt.imshow(raw_data,cmap='gray')
plt.subplot(2,2,3)
plt.imshow(rawimg_dpc0,cmap='gray')
plt.subplot(2,2,4)
plt.imshow(rawimg_dpc1,cmap='gray')
plt.show()
