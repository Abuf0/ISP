#!/usr/bin/python
import numpy as np
import cv2
#from scipy.ndimage import correlate

class CSC:
    'Color Space Conversion'

    def __init__(self, img, csc):
        self.img = img
        self.csc = csc

    def execute(self):
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        img_c = self.img.shape[2]
        csc_img = np.empty((img_h, img_w, img_c), np.uint32)
        # for y in range(img_h):
        #     for x in range(img_w):
        #         mulval = self.csc[:,0:3] * self.img[y,x,:]
        #         csc_img[y,x,0] = np.sum(mulval[0]) + self.csc[0,3]
        #         csc_img[y,x,1] = np.sum(mulval[1]) + self.csc[1,3]
        #         csc_img[y,x,2] = np.sum(mulval[2]) + self.csc[2,3]
        #         csc_img[y,x,:] = csc_img[y,x,:] / 1024

        csc_img[:, :, 0] = self.img[:, :, 0] * self.csc[0, 0] + self.img[:, :, 1] * self.csc[0, 1] + self.img[:, :, 2] * self.csc[0, 2] + self.csc[0, 3]
        csc_img[:, :, 1] = self.img[:, :, 0] * self.csc[1, 0] + self.img[:, :, 1] * self.csc[1, 1] + self.img[:, :, 2] * self.csc[1, 2] + self.csc[1, 3]
        csc_img[:, :, 2] = self.img[:, :, 0] * self.csc[2, 0] + self.img[:, :, 1] * self.csc[2, 1] + self.img[:, :, 2] * self.csc[2, 2] + self.csc[2, 3]
        csc_img = csc_img / 1024
        print("%d,%d,%d"%(self.img[0,0,0],self.img[0,0,1],self.img[0,0,2]))
        print("%d,%d,%d"%(csc_img[0,0,0],csc_img[0,0,1],csc_img[0,0,2]))
        print("%d,%d,%d,%d"%(self.csc[0, 0],self.csc[0, 1],self.csc[0, 2],self.csc[0, 3]))

        self.img = csc_img.astype(np.uint8)
        #print(self.img)
        return self.img
'''
csc = np.zeros((3,4))  
# csc[0][0] = 263
# csc[0][1] = 516
# csc[0][2] = 100
# csc[0][3] = 16
# csc[1][0] = -151
# csc[1][1] = -298
# csc[1][2] = 449
# csc[1][3] = 128
# csc[2][0] = 449
# csc[2][1] = -377
# csc[2][2] = -73
# csc[2][3] = 128
csc[0][0] =	0.257*1024	
csc[0][1] =	0.504*1024
csc[0][2] =	0.098*1024
csc[0][3] =	16*1024
csc[1][0] =	-0.148*1024
csc[1][1] =	-0.291*1024
csc[1][2] =	0.439*1024
csc[1][3] =	128*1024	
csc[2][0] =	0.439*1024
csc[2][1] =	-0.368*1024
csc[2][2] =	-0.071*1024
csc[2][3] =	128*1024	
raw_data = cv2.imread('img_gc.jpg',cv2.IMREAD_UNCHANGED)
obj = CSC(raw_data,csc)
csc_data_yuv = obj.execute()
cv2.imwrite('yuv_img_csc.jpg', csc_data_yuv)
csc_data_rgb = cv2.cvtColor(csc_data_yuv, cv2.COLOR_YCrCb2BGR)
cv2.imwrite('img_csc.jpg',csc_data_rgb)
'''