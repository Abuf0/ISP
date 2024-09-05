#!/usr/bin/python
import numpy as np
import cv2

class HSC:
    'Hue Saturation Control'

    def __init__(self, img, hue, saturation, clip):
        self.img = img
        self.hue = hue
        self.saturation = saturation
        self.clip = clip

    def clipping(self):
        np.clip(self.img, 0, self.clip, out=self.img)
        return self.img

    def lut(self):
        ind = np.array([i for i in range(360)])
        sin = np.sin(ind * np.pi / 180) * 256
        cos = np.cos(ind * np.pi / 180) * 256
        lut_sin = dict(zip(ind, [round(sin[i]) for i in ind]))
        lut_cos = dict(zip(ind, [round(cos[i]) for i in ind]))
        return lut_sin, lut_cos

    def execute(self):
        lut_sin, lut_cos = self.lut()
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        img_c = self.img.shape[2]
        hsc_img = np.empty((img_h, img_w, img_c), np.int16)
        hsc_img[:,:,0] = (self.img[:,:,0] - 128) * lut_cos[self.hue] + (self.img[:,:,1] - 128) * lut_sin[self.hue] + 128
        hsc_img[:,:,1] = (self.img[:,:,1] - 128) * lut_cos[self.hue] - (self.img[:,:,0] - 128) * lut_sin[self.hue] + 128
        #hsc_img[:,:,0] = self.saturation * (self.img[:,:,0] - 128) / 256 + 128
        #hsc_img[:,:,1] = self.saturation * (self.img[:,:,1] - 128) / 256 + 128
        hsc_img[:,:,0] = self.saturation * (hsc_img[:,:,0] - 128) / 256 + 128
        hsc_img[:,:,1] = self.saturation * (hsc_img[:,:,1] - 128) / 256 + 128
        self.img = hsc_img
        print(lut_cos[self.hue])
        print(lut_sin[self.hue])
        return self.clipping()

#hue = 128
#saturation = 256
#hsc_clip = 255
#
#raw_data = cv2.imread('yuv_img_fsc.jpg',cv2.IMREAD_UNCHANGED)
#obj = HSC(raw_data[:,:,1:3],hue,saturation,hsc_clip)
#hsc_data_yuv_12 = obj.execute()
#hsc_data_yuv = raw_data
#hsc_data_yuv [:,:,1:3] = hsc_data_yuv_12
#cv2.imwrite('yuv_img_hsc.jpg', hsc_data_yuv)
#hsc_data_rgb = cv2.cvtColor(hsc_data_yuv, cv2.COLOR_YCrCb2BGR)
#cv2.imwrite('img_hsc.jpg',hsc_data_rgb)