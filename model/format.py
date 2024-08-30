import numpy as np # of course
from PIL import Image
import cv2
from matplotlib import pyplot as plt
import csv

img = cv2.imread("./img.jpg")
(height, width) = img.shape[:2]
(B,G,R) = cv2.split(img)

bayer = np.empty((height, width), np.uint16)

# strided slicing for this pattern:
#   G R
#   B G
bayer[0::2, 0::2] = R[0::2, 0::2] # top left
bayer[0::2, 1::2] = G[0::2, 1::2] # top right
bayer[1::2, 0::2] = G[1::2, 0::2] # bottom left
bayer[1::2, 1::2] = B[1::2, 1::2] # bottom right

cv2.imwrite('bayer_img.jpg', bayer)

img_rgb_conf = cv2.imread('bayer_img.jpg',cv2.COLOR_BayerRGGB2BGR)
cv2.imwrite('img_rgb_conf.jpg',img_rgb_conf)


#rgbimg=cv2.imread('./img.jpg')
#print(rgbimg.dtype)#np.uint8
#imgshape=rgbimg.shape
#raw_path = rgbimg.tofile('./img_raw.raw')
#rawimg = np.fromfile(raw_path, dtype='uint16', sep='')
#cv2.imwrite('img_raw.jpg',rawing)