#!/usr/bin/python
import numpy as np
from PIL import Image
import cv2
from matplotlib import pyplot as plt

# Black Level Compensation
class BLC:
    'Black Level Compensation'

    def __init__(self, img, bias, mode):
        self.img = img
        self.bias = bias
        self.mode = mode

    def comp(self):
        raw_h = self.img.shape[0]
        raw_w = self.img.shape[1]
        print(raw_h)
        print(raw_w)
        dpc_img = np.empty((raw_h, raw_w), np.uint8)
        print("hhhhhhhh")
        for y in range(raw_h):
            for x in range(raw_w):
                dpc_img[y,x] = self.img[y,x]-bias
        self.img = dpc_img
        return self.img

# 读取图像
raw_data = cv2.imread('img_dpc.jpg')
b, g, r = cv2.split(raw_data)
#plt.show()
print(50*'-' + '\nLoading RAW Image Done......')

bias = 10
obj_b = BLC(b,bias,'none')
obj_g = BLC(g,bias,'none')
obj_r = BLC(r,bias,'none')
blc_b = obj_b.comp()
blc_g = obj_g.comp()
blc_r = obj_r.comp()

blc_data = cv2.merge([blc_b, blc_g, blc_r])
print(50*'-' + '\nBlack Level Compensation Done......')

cv2.imwrite('img_blc.jpg', blc_data)

## CV2(BGR) --> PLT(RGB)

raw_data_rgb = cv2.cvtColor(raw_data, cv2.COLOR_BGR2RGB)
blc_b_rgb = cv2.cvtColor(blc_b, cv2.COLOR_BGR2RGB)
blc_g_rgb = cv2.cvtColor(blc_g, cv2.COLOR_BGR2RGB)
blc_r_rgb = cv2.cvtColor(blc_r, cv2.COLOR_BGR2RGB)
blc_data_rgb = cv2.cvtColor(blc_data, cv2.COLOR_BGR2RGB)

plt.figure()
plt.subplot(2,3,1)
plt.imshow(raw_data_rgb)
plt.subplot(2,3,4)
plt.imshow(blc_b_rgb)
plt.subplot(2,3,5)
plt.imshow(blc_g_rgb)
plt.subplot(2,3,6)
plt.imshow(blc_r_rgb)
plt.subplot(2,3,3)
plt.imshow(blc_data_rgb)
plt.show()
