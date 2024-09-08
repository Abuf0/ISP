#!/usr/bin/python
import numpy as np
import cv2

class EEH:
    'Edge Enhancement'

    def __init__(self, img, edge_filter, gain, thres, emclip):
        self.img = img
        self.edge_filter = edge_filter
        self.gain = gain
        self.thres = thres
        self.emclip = emclip

    def padding(self):
        # 对行扩充1，1
        # 对列扩充2，2
        img_pad = np.pad(self.img, ((1, 1), (2, 2)), 'constant')
        return img_pad

    def clipping(self):
        np.clip(self.img, 0, 255, out=self.img)
        return self.img

    def emlut(self, val, thres, gain, clip):
        lut = 0
        if val < -thres[1]:
            lut = gain[1] * val
        elif val < -thres[0] and val > -thres[1]:
            lut = 0
        elif val < thres[0] and val > -thres[1]:
            lut = gain[0] * val
        elif val > thres[0] and val < thres[1]:
            lut = 0
        elif val > thres[1]:
            lut = gain[1] * val
        # np.clip(lut, clip[0], clip[1], out=lut)
        lut = max(clip[0], min(lut / 256, clip[1]))
        return lut

    def execute(self):
        img_pad = self.padding()
        img_h = self.img.shape[0]
        img_w = self.img.shape[1]
        ee_img = np.empty((img_h, img_w), np.int16)
        em_img = np.empty((img_h, img_w), np.int16)
        print(img_pad.shape[0])
        print(img_pad.shape[1])
        tryy = np.zeros((4,4))
        tryy_pad = np.pad(tryy, ((1, 1), (2, 2)), 'constant')
        print(tryy_pad)
        for y in range(img_pad.shape[0] - 2):
            for x in range(img_pad.shape[1] - 4):
                #f3.write("(%d,%d):\n"%(y,x))
                #f3.write(str(np.multiply(img_pad[y:y+3, x:x+5], self.edge_filter[:, :])))
                #f3.write("\n")
                em_img[y,x] = np.sum(np.multiply(img_pad[y:y+3, x:x+5], self.edge_filter[:, :])) / 8
                ee_img[y,x] = img_pad[y+1,x+2] + self.emlut(em_img[y,x], self.thres, self.gain, self.emclip)
        self.img = ee_img
        return self.clipping(), em_img

f3 = open('./pipeline_data/eeh_p.csv','w+')
#edge_filter = np.zeros((3,5))
#ee_gain = [32,128]
#ee_thres = [32,64]
#ee_emclip = [-64,64]
#
#edge_filter[0][0] = -1	# Edge filter
#edge_filter[0][1] = 0	# Edge filter
#edge_filter[0][2] = -1	# Edge filter
#edge_filter[0][3] = 0	# Edge filter
#edge_filter[0][4] = -1	# Edge filter
#edge_filter[1][0] = -1	# Edge filter
#edge_filter[1][1] = 0	# Edge filter
#edge_filter[1][2] = 8	# Edge filter
#edge_filter[1][3] = 0	# Edge filter
#edge_filter[1][4] = -1	# Edge filter
#edge_filter[2][0] = -1	# Edge filter
#edge_filter[2][1] = 0	# Edge filter
#edge_filter[2][2] = -1	# Edge filter
#edge_filter[2][3] = 0	# Edge filter
#edge_filter[2][4] = -1	# Edge filter
#ee_gain[0] = 32	        # Edge enhancement min gain
#ee_gain[1] = 128	    # Edge enhancement max gain
#ee_thres[0] = 32	    # Edge enhancement min threshold
#ee_thres[1] = 64	    # Edge enhancement max threshold
#ee_emclip[0] = -64	    # Edge map min clip value
#ee_emclip[1] = 64	    # Edge map max clip value

#raw_data_rgb = cv2.imread('img_bnf.jpg',cv2.IMREAD_UNCHANGED)
#raw_data = cv2.imread('yuv_img_bnf_gray.jpg',cv2.IMREAD_UNCHANGED)
#obj = EEH(raw_data, edge_filter, ee_gain, ee_thres, ee_emclip)
#ee_data_yuv_0, edgemap_data_yuv_0 = obj.execute()
#cv2.imwrite('yuv_img_ee_gray.jpg', ee_data_yuv_0)
#cv2.imwrite('yuv_img_edgemap_gray.jpg', ee_data_yuv_0)
#ee_data_yuv = cv2.cvtColor(raw_data_rgb, cv2.COLOR_BGR2YCrCb)
#edgemap_data_yuv = cv2.cvtColor(raw_data_rgb, cv2.COLOR_BGR2YCrCb)
#ee_data_yuv[:,:,0] = ee_data_yuv_0
#edgemap_data_yuv[:,:,0] = edgemap_data_yuv_0
#ee_data_rgb = cv2.cvtColor(ee_data_yuv, cv2.COLOR_YCrCb2BGR)
#cv2.imwrite('img_ee.jpg',ee_data_rgb)
#edgemap_data_rgb = cv2.cvtColor(edgemap_data_yuv, cv2.COLOR_YCrCb2BGR)
#cv2.imwrite('img_edgemap.jpg',edgemap_data_rgb)