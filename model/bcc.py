#!/usr/bin/python
import numpy as np
import cv2

class BCC:
    'Brightness Contrast Control'

    def __init__(self, img, brightness, contrast, clip):
        self.img = img
        self.brightness = brightness
        self.contrast = contrast
        self.clip = clip

    def clipping(self):
        np.clip(self.img, 0, self.clip, out=self.img)
        return self.img

    def execute(self):
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        bcc_img = np.empty((img_h, img_w), np.int16)
        bcc_img = self.img + self.brightness
        bcc_img = bcc_img + (self.img - 127) * self.contrast
        self.img = bcc_img
        return self.clipping()

#brightness = 10 # [-255,255]
#contrast = 10/pow(2,5)  # [-32,128]
#bcc_clip = 255
#
#raw_data_rgb = cv2.imread('img_ee.jpg',cv2.IMREAD_UNCHANGED)
#raw_data = cv2.imread('yuv_img_ee_gray.jpg',cv2.IMREAD_UNCHANGED)
#obj = BCC(raw_data, brightness, contrast, bcc_clip)
#bcc_data_yuv_0 = obj.execute()
#cv2.imwrite('yuv_img_bcc_gray.jpg', bcc_data_yuv_0)
#bcc_data_yuv = cv2.cvtColor(raw_data_rgb, cv2.COLOR_BGR2YCrCb)
#bcc_data_yuv[:,:,0] = bcc_data_yuv_0
#bcc_data_rgb = cv2.cvtColor(bcc_data_yuv, cv2.COLOR_YCrCb2BGR)
#cv2.imwrite('img_bcc.jpg',bcc_data_rgb)