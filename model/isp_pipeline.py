#!/usr/bin/python

import numpy as np
from PIL import Image
import cv2
from matplotlib import pyplot as plt
from dpc import DPC
from blc import BLC
from aaf import AAF

raw_data = cv2.imread('img_bayer_resize.jpg',cv2.IMREAD_UNCHANGED)
print(50*'-' + '\nLoading RAW Image Done......')

# dead pixel correction
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