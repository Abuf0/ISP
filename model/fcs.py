#!/usr/bin/python
import numpy as np
import cv2

class FCS:
    'False Color Suppresion'

    def __init__(self, img, edgemap, fcs_edge, gain, intercept, slope):
        self.img = img
        self.edgemap = edgemap
        self.fcs_edge = fcs_edge
        self.gain = gain
        self.intercept = intercept
        self.slope = slope

    def clipping(self):
        np.clip(self.img, 0, 255, out=self.img)
        return self.img

    def execute(self):
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        img_c = self.img.shape[2]
        fcs_img = np.empty((img_h, img_w, img_c), np.int16)
        for y in range(img_h):
            for x in range(img_w):
                if np.abs(self.edgemap[y,x]) <= self.fcs_edge[0]:
                    uvgain = self.gain
                elif np.abs(self.edgemap[y,x]) > self.fcs_edge[0] and np.abs(self.edgemap[y,x]) < self.fcs_edge[1]:
                    uvgain = self.intercept - self.slope * self.edgemap[y,x]
                else:
                    uvgain = 0
                fcs_img[y,x,:] = uvgain * (self.img[y,x,:]) / 256 + 128
        self.img = fcs_img
        return self.clipping()

fcs_edge = [32,64]
fcs_gain = 32
fcs_intercept = 2
fcs_slop = 3

raw_data = cv2.imread('yuv_img_csc.jpg',cv2.IMREAD_UNCHANGED)
raw_data_edgemap = cv2.imread('yuv_img_edgemap_gray.jpg',cv2.IMREAD_UNCHANGED)
obj = FCS(raw_data[:,:,1:3],raw_data_edgemap,fcs_edge,fcs_gain,fcs_intercept,fcs_slop)
fsc_data_yuv_12 = obj.execute()
fsc_data_yuv = raw_data
fsc_data_yuv [:,:,1:3] = fsc_data_yuv_12
cv2.imwrite('yuv_img_fsc.jpg', fsc_data_yuv)
fsc_data_rgb = cv2.cvtColor(fsc_data_yuv, cv2.COLOR_YCrCb2BGR)
cv2.imwrite('img_fsc.jpg',fsc_data_rgb)