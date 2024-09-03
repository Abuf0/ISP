#!/usr/bin/python
import numpy as np
import cv2

class NLM:
    'Non-Local Means Denoising'

    def __init__(self, img, ds, Ds, h, clip, lut_en, lut_exp):
        self.img = img
        self.ds = ds    # neighbour window size - 1 /2
        self.Ds = Ds    # search window size - 1 / 2
        self.h = h
        self.clip = clip
        self.lut_en = lut_en
        self.lut_exp = lut_exp

    def padding(self):
        img_pad = np.pad(self.img, (self.Ds, self.Ds), 'constant')
        return img_pad

    def clipping(self):
        np.clip(self.img, 0, self.clip, out=self.img)
        return self.img

    def calWeights(self, img, kernel, y, x, lut_en,lut_exp):
        wmax = 0
        sweight = 0
        average = 0
        #for j in range(2 * self.Ds + 1 - 2 * self.ds - 1):
        #    for i in range(2 * self.Ds + 1  - 2 * self.ds - 1):
        for j in range(2 * self.Ds + 1 - 2 * self.ds):          # modify
            for i in range(2 * self.Ds + 1  - 2 * self.ds):     # modify
                start_y = y - self.Ds + self.ds + j
                start_x = x - self.Ds + self.ds + i
                #print("(y,x)=(%d,%d), (start_y,start_x)=(%d,%d)\n"%(y,x,start_y,start_x))
                neighbour_w = img[start_y - self.ds:start_y + self.ds + 1, start_x - self.ds:start_x + self.ds + 1]
                center_w = img[y-self.ds:y+self.ds+1, x-self.ds:x+self.ds+1]
                if j != y or i != x:
                    sub = np.subtract(neighbour_w, center_w)
                    dist = np.sum(np.multiply(kernel, np.multiply(sub, sub)))
                    #dist = np.sum(np.multiply(sub, sub))
                    if(lut_en):
                        w = int(lut_exp[round(dist)])/pow(2,15)
                    else:
                        w = np.exp(-dist/pow(self.h, 2))    # replaced by look up table
                    #f1.write("w=%f\t"%(w))
                    if w > wmax:
                        wmax = w
                    sweight = sweight + w
                    average = average + w * img[start_y, start_x]
                    f1.write(str(w))
                    f1.write("(%d,%d:%d)"%(start_y,start_x,img[start_y,start_x]))
                    f1.write(", ")
                    #f1.write(str(x))
                    #f1.write("\n")
                #f1.write("(%d,%d):\n"%(j,i))
                #f1.write("dist=")
                #f1.write("\n")
                #f1.write(str(int(dist)))
                #f1.write(" , ")
            f1.write("\n")
        f1.write("sw=%d, avg=%d, wmax=%d\n"%(sweight,average,wmax))
        f1.write('\ncenter\n:')
        f1.write(str(center_w))
        f1.write("\n")
        f1.write("\n")
                #f1.write(str(w))
                #f1.write("sw=%d, avg=%d, wmax=%d\n"%(sweight,average,wmax))
        return sweight, average, wmax

    def execute(self):
        img_pad = self.padding()
        img_pad = img_pad.astype(np.uint16)
        raw_h = self.img.shape[0]
        raw_w = self.img.shape[1]
        nlm_img = np.empty((raw_h, raw_w), np.uint16)
        kernel = np.ones((2*self.ds+1, 2*self.ds+1)) / pow(2*self.ds+1, 2)
        lut_en = self.lut_en
        lut_exp = self.lut_exp
        print("kernel:\n")
        print(kernel)
        for y in range(img_pad.shape[0] - 2 * self.Ds):
            for x in range(img_pad.shape[1] - 2 * self.Ds):
                center_y = y + self.Ds
                center_x = x + self.Ds
                sweight, average, wmax = self.calWeights(img_pad, kernel, center_y, center_x, lut_en,lut_exp)
                average = average + wmax * img_pad[center_y, center_x]
                sweight = sweight + wmax
                nlm_img[y,x] = average / sweight
        self.img = nlm_img
        return self.clipping()


f1 = open("./pipeline_data/nlm_p.csv","w+")

# nlm_h = 10
# nlm_clip = 255
# raw_data = cv2.imread('yuv_img_csc.jpg',cv2.IMREAD_UNCHANGED)
# obj = NLM(raw_data[:,:,0],1,4,nlm_h,nlm_clip)
# nlm_data_yuv_0 = obj.execute()
# cv2.imwrite('yuv_img_nlm_gray.jpg', nlm_data_yuv_0)
# nlm_data_yuv = raw_data
# nlm_data_yuv[:,:,0] = nlm_data_yuv_0
# nlm_data_rgb = cv2.cvtColor(nlm_data_yuv, cv2.COLOR_YCrCb2BGR)
# cv2.imwrite('img_nlm.jpg',nlm_data_rgb)