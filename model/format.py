import numpy as np # of course
from PIL import Image
import cv2
from matplotlib import pyplot as plt

img = cv2.imread("./img.jpg")
(height, width) = img.shape[:2]
(B,G,R) = cv2.split(img)

bayer = np.empty((height, width), np.uint8)

# strided slicing for this pattern:
#   G R
#   B G
bayer[0::2, 0::2] = R[0::2, 0::2] # top left
bayer[0::2, 1::2] = G[0::2, 1::2] # top right
bayer[1::2, 0::2] = G[1::2, 0::2] # bottom left
bayer[1::2, 1::2] = B[1::2, 1::2] # bottom right

cv2.imwrite('bayer_img.jpg', bayer)

