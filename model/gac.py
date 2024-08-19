#!/usr/bin/python
import numpy as np
import cv2

class GC:
    'Gamma Correction'

    def __init__(self, img, lut,mode):
        self.img = img
        self.lut = lut
        self.modem= mode

    def execute(self):
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        img_c = self.img.shape[2]
        gc_img = np.empty((img_h, img_w, img_c), np.uint16)
        for y in range(img_h):
            for x in range(img_w):
                gc_img[y,x,0] = self.lut[self.img[y,x,0]]
                gc_img[y,x,1] = self.lut[self.img[y,x,1]]
                gc_img[y,x,2] = self.lut[self.img[y,x,2]]
                gc_img[y,x,:] = gc_img[y,x,:]/4
                #print(gc_img[y,x,:])
        self.img = gc_img
        return self.img

gamma = 1/2.2
bw = 10
maxval = pow(2,bw)
ind = range(0,maxval)
val = [round(pow(float(i)/maxval,gamma)*maxval) for i in ind]
#valt = [np.log(float(i)/maxval) for i in ind]
#print(valt)
lut = dict(zip(ind,val))
#print(lut)
raw_data = cv2.imread('img_ccm.jpg',cv2.IMREAD_UNCHANGED)
obj = GC(raw_data,lut,'rbg')
gc_data_rgb = obj.execute()
#cv2.imwrite('bayer_img_cfa.jpg', cfa_data_bayer)
#cfa_data_rgb = cv2.cvtColor(cfa_data_bayer, cv2.COLOR_BayerRGGB2BGR)
cv2.imwrite('img_gc.jpg',gc_data_rgb)