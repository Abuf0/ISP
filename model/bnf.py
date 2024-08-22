#!/usr/bin/python
import numpy as np
import cv2

class BNF:
    'Bilateral Noise Filtering'

    def __init__(self, img, dw, rw, rthres, clip):
        self.img = img
        self.dw = dw
        self.rw = rw
        self.rthres = rthres
        self.clip = clip

    def padding(self):
        img_pad = np.pad(self.img, (2, 2), 'reflect')
        return img_pad

    def clipping(self):
        np.clip(self.img, 0, self.clip, out=self.img)
        return self.img

    def execute(self):
        img_pad = self.padding()
        img_pad = img_pad.astype(np.uint16)
        raw_h = self.img.shape[0]
        raw_w = self.img.shape[1]
        bnf_img = np.empty((raw_h, raw_w), np.uint16)
        rdiff = np.zeros((5,5), dtype='uint16')
        for y in range(img_pad.shape[0] - 4):
            for x in range(img_pad.shape[1] - 4):
                #print("[x,y]:["+str(x)+','+str(y)+']')
                for i in range(5):
                    for j in range(5):
                        rdiff[i,j] = abs(img_pad[y+i,x+j].astype(int) - img_pad[y+2, x+2].astype(int))
                        # rdiff[i,j] = abs(img_pad[y+i,x+j] - img_pad[y+2, x+2])
                        if rdiff[i,j] >= self.rthres[0]:
                            rdiff[i,j] = self.rw[0]
                        elif rdiff[i,j] < self.rthres[0] and rdiff[i,j] >= self.rthres[1]:
                            rdiff[i,j] = self.rw[1]
                        elif rdiff[i,j] < self.rthres[1] and rdiff[i,j] >= self.rthres[2]:
                            rdiff[i,j] = self.rw[2]
                        elif rdiff[i,j] < self.rthres[2]:
                            rdiff[i,j] = self.rw[3]
                weights = np.multiply(rdiff, self.dw)
                bnf_img[y,x] = np.sum(np.multiply(img_pad[y:y+5,x:x+5], weights[:,:])) / np.sum(weights)
        self.img = bnf_img
        return self.clipping()

bnf_dw = np.zeros((5,5))
bnf_rw = [1, 1, 1, 1]
bnf_rthres = [32, 64, 128]
bnf_clip = 255

bnf_dw[0][0] = 8	# BNF distance weights
bnf_dw[0][1] = 12	# BNF distance weights
bnf_dw[0][2] = 32	# BNF distance weights
bnf_dw[0][3] = 12	# BNF distance weights
bnf_dw[0][4] = 8	# BNF distance weights
bnf_dw[1][0] = 12	# BNF distance weights
bnf_dw[1][1] = 64	# BNF distance weights
bnf_dw[1][2] = 128	# BNF distance weights
bnf_dw[1][3] = 64	# BNF distance weights
bnf_dw[1][4] = 12	# BNF distance weights
bnf_dw[2][0] = 32	# BNF distance weights
bnf_dw[2][1] = 128	# BNF distance weights
bnf_dw[2][2] = 1024	# BNF distance weights
bnf_dw[2][3] = 128	# BNF distance weights
bnf_dw[2][4] = 32	# BNF distance weights
bnf_dw[3][0] = 12	# BNF distance weights
bnf_dw[3][1] = 64	# BNF distance weights
bnf_dw[3][2] = 128	# BNF distance weights
bnf_dw[3][3] = 64	# BNF distance weights
bnf_dw[3][4] = 12	# BNF distance weights
bnf_dw[4][0] = 8	# BNF distance weights
bnf_dw[4][1] = 12	# BNF distance weights
bnf_dw[4][2] = 32	# BNF distance weights
bnf_dw[4][3] = 12	# BNF distance weights
bnf_dw[4][4] = 8	# BNF distance weights
bnf_rw[0] =0	# BNF radiometric diff
bnf_rw[1] =8	# BNF radiometric diff
bnf_rw[2] =16	# BNF radiometric diff
bnf_rw[3] =32	# BNF radiometric diff
bnf_rthres[0] = 128	# BNF diff threshold
bnf_rthres[1] = 32	# BNF diff threshold
bnf_rthres[2] = 8	# BNF diff threshold
bnf_clip = 255	# BNF clip value

raw_data_rgb = cv2.imread('img_nlm.jpg',cv2.IMREAD_UNCHANGED)
raw_data = cv2.imread('yuv_img_nlm_gray.jpg',cv2.IMREAD_UNCHANGED)
obj = BNF(raw_data, bnf_dw, bnf_rw, bnf_rthres, bnf_clip)
bnf_data_yuv_0 = obj.execute()
cv2.imwrite('yuv_img_bnf_gray.jpg', bnf_data_yuv_0)
bnf_data_yuv = cv2.cvtColor(raw_data_rgb, cv2.COLOR_BGR2YCrCb)
bnf_data_yuv[:,:,0] = bnf_data_yuv_0
bnf_data_rgb = cv2.cvtColor(bnf_data_yuv, cv2.COLOR_YCrCb2BGR)
cv2.imwrite('img_bnf.jpg',bnf_data_rgb)