#!/usr/bin/python
import numpy as np
import cv2

class NLM:
    'Non-Local Means Denoising'

    def __init__(self, img, ds, Ds, h, clip):
        self.img = img
        self.ds = ds    # neighbour window size - 1 /2
        self.Ds = Ds    # search window size - 1 / 2
        self.h = h
        self.clip = clip

    def padding(self):
        img_pad = np.pad(self.img, (self.Ds, self.Ds), 'reflect')
        return img_pad

    def clipping(self):
        np.clip(self.img, 0, self.clip, out=self.img)
        return self.img

    def calWeights(self, img, kernel, y, x):
        wmax = 0
        sweight = 0
        average = 0
        for j in range(2 * self.Ds + 1 - 2 * self.ds - 1):
            for i in range(2 * self.Ds + 1 - 2 * self.ds - 1):
                start_y = y - self.Ds + self.ds + j
                start_x = x - self.Ds + self.ds + i
                neighbour_w = img[start_y - self.ds:start_y + self.ds + 1, start_x - self.ds:start_x + self.ds + 1]
                center_w = img[y-self.ds:y+self.ds+1, x-self.ds:x+self.ds+1]
                if j != y or i != x:
                    sub = np.subtract(neighbour_w, center_w)
                    dist = np.sum(np.multiply(kernel, np.multiply(sub, sub)))
                    w = np.exp(-dist/pow(self.h, 2))    # replaced by look up table
                    if w > wmax:
                        wmax = w
                    sweight = sweight + w
                    average = average + w * img[start_y, start_x]
        return sweight, average, wmax

    def execute(self):
        img_pad = self.padding()
        img_pad = img_pad.astype(np.uint16)
        raw_h = self.img.shape[0]
        raw_w = self.img.shape[1]
        nlm_img = np.empty((raw_h, raw_w), np.uint16)
        kernel = np.ones((2*self.ds+1, 2*self.ds+1)) / pow(2*self.ds+1, 2)
        for y in range(img_pad.shape[0] - 2 * self.Ds):
            for x in range(img_pad.shape[1] - 2 * self.Ds):
                center_y = y + self.Ds
                center_x = x + self.Ds
                sweight, average, wmax = self.calWeights(img_pad, kernel, center_y, center_x)
                average = average + wmax * img_pad[center_y, center_x]
                sweight = sweight + wmax
                nlm_img[y,x] = average / sweight
        self.img = nlm_img
        return self.clipping()

nlm_h = 10
nlm_clip = 255
raw_data = cv2.imread('yuv_img_csc.jpg',cv2.IMREAD_UNCHANGED)
obj = NLM(raw_data[:,:,0],1,4,nlm_h,nlm_clip)
nlm_data_yuv_0 = obj.execute()
cv2.imwrite('yuv_img_nlm_gray.jpg', nlm_data_yuv_0)
nlm_data_yuv = raw_data
nlm_data_yuv[:,:,0] = nlm_data_yuv_0
nlm_data_rgb = cv2.cvtColor(nlm_data_yuv, cv2.COLOR_YCrCb2BGR)
cv2.imwrite('img_nlm.jpg',nlm_data_rgb)