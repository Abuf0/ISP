#!/usr/bin/python
import numpy as np
import cv2

class CCM:
    'Color Correction Matrix'

    def __init__(self, img, ccm):
        self.img = img
        self.ccm = ccm

    def execute(self):
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        img_c = self.img.shape[2]
        ccm_img = np.empty((img_h, img_w, img_c), np.uint32)
        for y in range(img_h):
            for x in range(img_w):
                mulval = self.ccm[:,0:3] * self.img[y,x,:]  # ccm的前三列
                ccm_img[y,x,0] = np.sum(mulval[0]) + self.ccm[0,3]  # ccm的第4列==offset
                ccm_img[y,x,1] = np.sum(mulval[1]) + self.ccm[1,3]
                ccm_img[y,x,2] = np.sum(mulval[2]) + self.ccm[2,3]
                ccm_img[y,x,:] = ccm_img[y,x,:] / 1024
        self.img = ccm_img.astype(np.uint16)
        return self.img

ccm = np.zeros((3,4))  
ccm[0][0] = 1024
ccm[1][1] = 1024
ccm[2][2] = 1024
raw_data = cv2.imread('img_cfa.jpg',cv2.IMREAD_UNCHANGED)
obj = CCM(raw_data,ccm)
ccm_data_rgb = obj.execute()
#cv2.imwrite('bayer_img_cfa.jpg', cfa_data_bayer)
#cfa_data_rgb = cv2.cvtColor(cfa_data_bayer, cv2.COLOR_BayerRGGB2BGR)
cv2.imwrite('img_ccm.jpg',ccm_data_rgb)