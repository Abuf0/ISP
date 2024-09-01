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
from ccm import CCM
from gac import GC
from csc import CSC
from pic2bayer import int_to_bin8

raw_data = cv2.imread('img_bayer_resize.jpg',cv2.IMREAD_UNCHANGED)
print(50*'-' + '\nLoading RAW Image Done......')


# dead pixel correction
raw_data = raw_data.astype(np.uint16)

thres = 100
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
bias = [0,0,0,0]
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
#parameter = [1.5,1,1,0.5]
parameter = [1,1,1,1]
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
obj = CNF(awb_data,'rggb',thres,parameter,clip)
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


# Color Filter Array Interpolation

cnf_data = cnf_data.astype(np.uint16)

f = open("./pipeline_data/cfa_data.csv","w+")
clip=250
#obj = CFA(cnf_data,'malvar','rggb',clip)
obj = CFA(cnf_data,'malvar','rggb',clip)
cfa_data = obj.execute()

raw_h = cfa_data.shape[0]
raw_w = cfa_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        #f.write("(%d,%d):%d (%d)\n"%(y,x,cfa_data[y,x],cnf_data[y,x]))
        f.write("(%d,%d): %d-%d-%d (%d))\n"%(y,x,cfa_data[y,x,0],cfa_data[y,x,1],cfa_data[y,x,2],raw_data[y,x]))

print(50*'-' + '\nColor Filter Array Interpolation Done......')
cv2.imwrite('./pipeline_data/img_cfa.jpg',cfa_data)
f.close()

# Color Correction Matrix
cfa_data = cfa_data.astype(np.uint16)

f = open("./pipeline_data/ccm_data.csv","w+")
ccm = np.zeros((3,4))  
ccm[0][0] = 1024
ccm[1][1] = 1024
ccm[2][2] = 1024

obj = CCM(cfa_data,ccm)
ccm_data = obj.execute()

raw_h = ccm_data.shape[0]
raw_w = ccm_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d-%d-%d\n"%(y,x,ccm_data[y,x,0],ccm_data[y,x,1],ccm_data[y,x,2]))


print(50*'-' + '\n Color Correction Matrix Done......')
cv2.imwrite('./pipeline_data/img_ccm.jpg',ccm_data)
f.close()


# Gamma Correction
ccm_data = ccm_data.astype(np.uint16)

f = open("./pipeline_data/gac_data.csv","w+")
gamma = 1/2.2
bw = 8
maxval = pow(2,bw)
ind = range(0,maxval)
val = [round(pow(float(i)/maxval,gamma)*maxval) for i in ind]
#valt = [np.log(float(i)/maxval) for i in ind]
#print(valt)
lut = dict(zip(ind,val))
#print(lut)
f_lut = open('./pipeline_data/lut_gamma_bin.txt','w+')
for i in ind:
    lut_bin = int_to_bin8(val[i])
    f_lut.write(str(lut_bin))
    f_lut.write('\n')
f_lut.close()


obj = GC(ccm_data,lut,'rgb')
gc_data = obj.execute()

raw_h = gc_data.shape[0]
raw_w = gc_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d-%d-%d\n"%(y,x,gc_data[y,x,0],gc_data[y,x,1],gc_data[y,x,2]))

print(50*'-' + '\n Gamma Correction Done......')
cv2.imwrite('./pipeline_data/img_gc.jpg',gc_data)
f.close()

# Color Space Conversion

gc_data = gc_data.astype(np.uint16)

f = open("./pipeline_data/csc_data.csv","w+")
csc = np.zeros((3,4))  
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

obj = CSC(gc_data,ccm)
csc_data = obj.execute()

raw_h = csc_data.shape[0]
raw_w = csc_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d-%d-%d\n"%(y,x,csc_data[y,x,0],csc_data[y,x,1],csc_data[y,x,2]))


print(50*'-' + '\n Color Space Conversion Done......')
cv2.imwrite('./pipeline_data/img_csc.jpg',csc_data)
f.close()