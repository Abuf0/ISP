#!/usr/bin/python

import numpy as np
from PIL import Image
import cv2
from matplotlib import pyplot as plt

class AAF:
    'Anti-aliasing Filter'

    def __init__(self, img):
        self.img = img

    def padding(self):
        img_pad = np.pad(self.img, (2, 2), 'reflect')
        return img_pad
    
    def execute(self):
        img_pad = self.padding()
        raw_h = self.img.shape[0]
        raw_w = self.img.shape[1]
        aaf_img = np.empty((raw_h, raw_w), np.uint16)
        for y in range(img_pad.shape[0] - 4):
            for x in range(img_pad.shape[1] - 4):
                p0 = img_pad[y + 2, x + 2]
                p1 = img_pad[y, x]
                p2 = img_pad[y, x + 4]
                p3 = img_pad[y, x + 4]
                p4 = img_pad[y + 2, x]
                p5 = img_pad[y + 2, x + 4]
                p6 = img_pad[y + 4, x]
                p7 = img_pad[y + 4, x + 2]
                p8 = img_pad[y + 4, x + 4]
                aaf_img[y, x] = (p1+p2+p3+p4+p5+p6+p7+p8+8*p0)/16
        self.img = aaf_img
        return self.img
    
raw_data = cv2.imread('bayer_img_blc.jpg',cv2.IMREAD_UNCHANGED)
obj = AAF(raw_data)
aaf_data_bayer = obj.execute()
cv2.imwrite('bayer_img_aaf.jpg', aaf_data_bayer)
aaf_data_rgb = cv2.cvtColor(aaf_data_bayer, cv2.COLOR_BayerRGGB2BGR)
cv2.imwrite('img_aaf.jpg',aaf_data_rgb)
