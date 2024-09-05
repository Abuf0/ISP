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
from nlm import NLM
from bnf import BNF
from eeh import EEH
from bcc import BCC
from pic2bayer import int_to_bin8
from pic2bayer import int_to_bin16


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
bias = [10,20,30,40]
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
obj = CFA(raw_data,'malvar','rggb',clip)    ######### TODO for debug
cfa_data = obj.execute()

raw_h = cfa_data.shape[0]
raw_w = cfa_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        #f.write("(%d,%d):%d (%d)\n"%(y,x,cfa_data[y,x],cnf_data[y,x]))
        f.write("(%d,%d): %d-%d-%d (%d))\n"%(y,x,cfa_data[y,x,2],cfa_data[y,x,1],cfa_data[y,x,0],raw_data[y,x]))

print(50*'-' + '\nColor Filter Array Interpolation Done......')
cv2.imwrite('./pipeline_data/img_cfa.jpg',cfa_data)
f.close()

# Color Correction Matrix
cfa_data = cfa_data.astype(np.uint16)

f = open("./pipeline_data/ccm_data.csv","w+")
ccm = np.zeros((3,4))  
ccm[0][0] = 1024 # b
ccm[1][1] = 1024 # g
ccm[2][2] = 1024 # r

obj = CCM(cfa_data,ccm)
ccm_data = obj.execute()

raw_h = ccm_data.shape[0]
raw_w = ccm_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d-%d-%d\n"%(y,x,ccm_data[y,x,2],ccm_data[y,x,1],ccm_data[y,x,0]))


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
        f.write("(%d,%d): %d-%d-%d\n"%(y,x,gc_data[y,x,2],gc_data[y,x,1],gc_data[y,x,0]))

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
 
obj = CSC(gc_data,csc)
csc_data = obj.execute()

raw_h = csc_data.shape[0]
raw_w = csc_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d-%d-%d\n"%(y,x,csc_data[y,x,2],csc_data[y,x,1],csc_data[y,x,0]))


print(50*'-' + '\n Color Space Conversion Done......')
cv2.imwrite('./pipeline_data/yuv_img_csc.jpg',csc_data)
f.close()

# Non-local means denoising
csc_data = csc_data.astype(np.uint16)

f = open("./pipeline_data/nlm_data.csv","w+")
nlm_h = 10
nlm_clip = 250 
lut_en = 1

maxval = pow(2,16) # 255x255
ind = range(0,maxval)
val = [int(np.exp(-i/pow(nlm_h,2))*pow(2,15)) for i in ind]
#f.write(str(val))
lut_exp = dict(zip(ind,val))
f_lut = open('./pipeline_data/lut_exp_bin.txt','w+')
for i in ind:
    lut_exp_bin16 = int_to_bin16(val[i])
    #f_lut.write(str(i))
    #f_lut.write("\t")
    if(lut_exp_bin16!=int_to_bin16(0)):
        f_lut.write(str(lut_exp_bin16))
        f_lut.write('\n')
f_lut.close()

#obj = NLM(csc_data[:,:,0],1,3,nlm_h,nlm_clip,lut_en,lut_exp)
obj = NLM(gc_data[:,:,0],1,3,nlm_h,nlm_clip,lut_en,lut_exp) # debug
nlm_data = obj.execute()

raw_h = nlm_data.shape[0]
raw_w = nlm_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d (%d)\n"%(y,x,nlm_data[y,x],csc_data[y,x,0]))


print(50*'-' + '\n Non-local means denoising Done......')
cv2.imwrite('./pipeline_data/yuv_img_nlm.jpg',nlm_data)
f.close()


# Bilateral Noise Filtering
nlm_data = nlm_data.astype(np.uint16)

f = open("./pipeline_data/bnf_data.csv","w+")

bnf_dw = np.zeros((5,5))
bnf_rw = [1, 1, 1, 1]
bnf_rthres = [32, 64, 128]
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

bnf_clip = 250	# BNF clip value

#obj = BNF(nlm_data, bnf_dw, bnf_rw, bnf_rthres, bnf_clip)
obj = BNF(gc_data[:,:,0], bnf_dw, bnf_rw, bnf_rthres, bnf_clip)

bnf_data = obj.execute()

raw_h = bnf_data.shape[0]
raw_w = bnf_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d (%d)\n"%(y,x,bnf_data[y,x],nlm_data[y,x]))

print(50*'-' + '\n Bilateral Noise Filtering Done......')
cv2.imwrite('./pipeline_data/yuv_img_bnf.jpg',bnf_data)
f.close()

# Edge Enhancement
#bnf_data = bnf_data.astype(np.uint16)
bnf_data = bnf_data.astype(np.int16)

f = open("./pipeline_data/eeh_data.csv","w+")

edge_filter = np.zeros((3,5))
ee_gain = [32,128]
ee_thres = [32,64]
ee_emclip = [-64,64]

edge_filter[0][0] = -1	# Edge filter
edge_filter[0][1] = 0	# Edge filter
edge_filter[0][2] = -1	# Edge filter
edge_filter[0][3] = 0	# Edge filter
edge_filter[0][4] = -1	# Edge filter
edge_filter[1][0] = -1	# Edge filter
edge_filter[1][1] = 0	# Edge filter
edge_filter[1][2] = 8	# Edge filter
edge_filter[1][3] = 0	# Edge filter
edge_filter[1][4] = -1	# Edge filter
edge_filter[2][0] = -1	# Edge filter
edge_filter[2][1] = 0	# Edge filter
edge_filter[2][2] = -1	# Edge filter
edge_filter[2][3] = 0	# Edge filter
edge_filter[2][4] = -1	# Edge filter
ee_gain[0] = 32	        # Edge enhancement min gain
ee_gain[1] = 128	    # Edge enhancement max gain
ee_thres[0] = 32	    # Edge enhancement min threshold
ee_thres[1] = 64	    # Edge enhancement max threshold
ee_emclip[0] = -64	    # Edge map min clip value
ee_emclip[1] = 64	    # Edge map max clip value


obj = EEH(bnf_data, edge_filter, ee_gain, ee_thres, ee_emclip)
ee_data, em_data = obj.execute()

raw_h = ee_data.shape[0]
raw_w = ee_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): ee=%d, em=%d (%d)\n"%(y,x,ee_data[y,x],em_data[y,x],bnf_data[y,x]))

print(50*'-' + '\n Edge Enhancement Done......')
cv2.imwrite('./pipeline_data/yuv_img_ee.jpg',ee_data)
cv2.imwrite('./pipeline_data/yuv_img_em.jpg',em_data)
f.close()

# Brightness Contrast Control
ee_data = ee_data.astype(np.int16)

f = open("./pipeline_data/bcc_data.csv","w+")

brightness = 10 # [-255,255]
contrast = 10/pow(2,5)  # [-32,128]
bcc_clip = 250

obj = BCC(ee_data, brightness, contrast, bcc_clip)
bcc_data = obj.execute()

raw_h = bcc_data.shape[0]
raw_w = bcc_data.shape[1]
for y in range(raw_h):
    for x in range(raw_w):
        f.write("(%d,%d): %d (%d)\n"%(y,x,bcc_data[y,x],ee_data[y,x]))

print(50*'-' + '\n Brightness Contrast Control Done......')
cv2.imwrite('./pipeline_data/yuv_img_bcc.jpg',bcc_data)
f.close()