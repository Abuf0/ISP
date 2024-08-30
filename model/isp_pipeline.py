#!/usr/bin/python

import numpy as np
from PIL import Image
import cv2
from matplotlib import pyplot as plt
from dpc import DPC
from blc import BLC
from aaf import AAF
from awb import AWB
from cnf import CNF
from cfa import CFA

raw_data = cv2.imread('img_bayer_resize.jpg',cv2.IMREAD_UNCHANGED)
print(50*'-' + '\nLoading RAW Image Done......')


# dead pixel correction
raw_data = raw_data.astype(np.uint16)

thres = 30
clip = 250
f = open("./pipeline_data/dpc_data.csv","w+")
obj = DPC(raw_data,thres,'mean',clip)
dpc_data = obj.execute()

raw_h = dpc_data.shape[0]
raw_w = dpc_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write(str(dpc_data[y,x]))
        f.write("\n")
print(50*'-' + '\nDead Pixel Correction Done......')

cv2.imwrite('./pipeline_data/bayer_img_dpc.jpg', dpc_data)
f.close()

# black level compensation
dpc_data = dpc_data.astype(np.uint16)
clip = 250
bias = [0,10,20,30]
f = open("./pipeline_data/blc_data.csv","w+")

obj = BLC(dpc_data,bias,'rggb',clip)
blc_data = obj.execute()

raw_h = blc_data.shape[0]
raw_w = blc_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d):%d\n"%(y,x,blc_data[y,x]))

print(50*'-' + '\nBlack Level Compensation Done......')
cv2.imwrite('./pipeline_data/bayer_img_blc.jpg', blc_data)
f.close()

# anti-aliasing filter
blc_data = blc_data.astype(np.uint16)
f = open("./pipeline_data/aaf_data.csv","w+")

obj = AAF(blc_data)
aaf_data = obj.execute()

raw_h = aaf_data.shape[0]
raw_w = aaf_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d):%d\n"%(y,x,aaf_data[y,x]))

print(50*'-' + '\nAnti-aliasing Filter Done......')
cv2.imwrite('./pipeline_data/bayer_img_aaf.jpg', aaf_data)
f.close()

# auto white balance gain control
aaf_data = aaf_data.astype(np.uint16)

f = open("./pipeline_data/awb_data.csv","w+")
parameter = [1.5,1,1,0.5]
#parameter = [1,1,1,1]
clip = 250
obj = AWB(aaf_data,parameter,'rggb',clip)  
awb_data = obj.execute()
raw_h = awb_data.shape[0]
raw_w = awb_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d):%d (%d)\n"%(y,x,awb_data[y,x],aaf_data[y,x]))

print(50*'-' + '\nAuto White Balance Gain Control Done......')
cv2.imwrite('./pipeline_data/bayer_img_awb.jpg', awb_data)
f.close()

# chroma noise filtering
awb_data = awb_data.astype(np.uint16)

f = open("./pipeline_data/cnf_data.csv","w+")
thres = 0
clip = 250
#obj = CNF(awb_data,'rggb',thres,parameter,clip)
obj = CNF(raw_data,'rggb',thres,parameter,clip)
cnf_data = obj.execute()

raw_h = cnf_data.shape[0]
raw_w = cnf_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        #f.write("(%d,%d):%d (%d)\n"%(y,x,cnf_data[y,x],awb_data[y,x]))
        f.write("(%d,%d):%d (%d))\n"%(y,x,cnf_data[y,x],raw_data[y,x]))

print(50*'-' + '\nchroma noise filtering Done......')
cv2.imwrite('./pipeline_data/bayer_img_cnf.jpg', cnf_data)
f.close()


#Color Filter Array Interpolation

cnf_data = cnf_data.astype(np.uint16)

f = open("./pipeline_data/cfa_data.csv","w+")
clip=250
#obj = CFA(cnf_data,'malvar','rggb',clip)
obj = CFA(raw_data,'malvar','rggb',clip)
cfa_data = obj.execute()

raw_h = cfa_data.shape[0]
raw_w = cfa_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        #f.write("(%d,%d):%d (%d)\n"%(y,x,cfa_data[y,x],cnf_data[y,x]))
        f.write("(%d,%d):%d-%d-%d (%d))\n"%(y,x,cfa_data[y,x,0],cfa_data[y,x,1],cfa_data[y,x,2],raw_data[y,x]))

print(50*'-' + '\nColor Filter Array Interpolation Done......')
cv2.imwrite('./pipeline_data/img_cfa.jpg',cfa_data)
f.close()


cfa_data = cfa_data.astype(np.uint8)
cv2.imshow('Example',cfa_data)
cv2.waitKey(0)

cnf_data_rgb = cv2.imread('./pipeline_data/bayer_img_cnf.jpg',cv2.COLOR_BayerRGGB2BGR)
cv2.imshow('Example',cnf_data_rgb)
cv2.waitKey(0)

image_path = "img_cfa.jpg"
image = Image.open(image_path)
color_mode = image.mode
print(color_mode)