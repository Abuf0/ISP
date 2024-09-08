from PIL import Image
import numpy as np
import cv2

IMG_JPG_PATH = './img_house.jpg'
NEW_WIDTH = 128 # 1280
NEW_HEIGHT = 72 # 720
RESIZE_JPG_PATH = './img_rgb_resize.jpg'
RESIZE_BAYER_PATH = './img_bayer_resize.jpg'
BAYER_DATA_PATH = './img_bayer.txt'
BAYER_BIN_PATH = './img_bayer_bin.txt'

def int_to_bin8(number):
    binary_string = bin(number & 0xFF)[2:]  # & 0xFF 确保只取低 8 位
    return binary_string.zfill(8)  # 使用 zfill 方法补齐到 8 位

def int_to_bin16(number):
    binary_string = bin(number & 0xFFFF)[2:]  # & 0xFF 确保只取低 8 位
    return binary_string.zfill(16)  # 使用 zfill 方法补齐到 8 位

def bayer_to_bin(img_bayer,bin_path,data_path):
    print(50*'-' + '\nBayer Bin Writing......\n')
    f = open(bin_path,'w+')
    f1 = open(data_path,'w+')
    for x in range(0,img_bayer.shape[0]):
        for y in range(0,img_bayer.shape[1]):
            bayer_bin = int_to_bin16(img_bayer[x,y])
            f.write(str(bayer_bin))
            f1.write("(%d,%d):%d"%(x,y,img_bayer[x,y]))
            f.write('\n')
            f1.write('\n')
    f.close()
    f1.close()
    print('\nBayer Bin Writing Done......\n' + 50*'-')

'''
img = cv2.imread("./img.jpg",cv2.IMREAD_UNCHANGED)

(height, width) = img.shape[:2]
(B,G,R) = cv2.split(img) 
img_conf = img
img_conf[:,:,0]=B
img_conf[:,:,1]=G
img_conf[:,:,2]=R
cv2.imwrite('conf_img.jpg', img_conf)
bayer = np.empty((height, width), np.uint16)
bayer[0::2, 0::2] = R[0::2, 0::2] # top left
bayer[0::2, 1::2] = G[0::2, 1::2] # top right
bayer[1::2, 0::2] = G[1::2, 0::2] # bottom left
bayer[1::2, 1::2] = B[1::2, 1::2] # bottom right

cv2.imwrite('bayer_img.jpg', bayer)

img_rgb_conf = cv2.imread('bayer_img.jpg',cv2.COLOR_BayerRGGB2BGR)
cv2.imwrite('img_rgb_conf.jpg',img_rgb_conf)
'''

# 1. 加载 JPG 图片
print(50*'-' + '\nLoading JPG Image......\n')
image = cv2.imread(IMG_JPG_PATH, cv2.IMREAD_UNCHANGED)
# 2. resize JPG 图片
print(50*'-' + '\nResizing JPG Image......\n')
print('Resized JPG Image shape:(%d,%d)\n'%(NEW_WIDTH,NEW_HEIGHT))
resized_image = cv2.resize(image, (NEW_WIDTH,NEW_HEIGHT), interpolation=cv2.INTER_AREA)
cv2.imwrite(RESIZE_JPG_PATH, resized_image)

# 3. 转成Bayer形式（以下为RGGB）
(height, width) = resized_image.shape[:2]
(B,G,R) = cv2.split(resized_image) 
#img_conf = resized_image
#img_conf[:,:,0]=B
#img_conf[:,:,1]=G
#img_conf[:,:,2]=R
#cv2.imwrite('conf_img.jpg', img_conf)

bayer = np.empty((height, width), np.uint16)

# strided slicing for this pattern:
#   R G
#   G B
bayer[0::2, 0::2] = R[0::2, 0::2] # top left
bayer[0::2, 1::2] = G[0::2, 1::2] # top right
bayer[1::2, 0::2] = G[1::2, 0::2] # bottom left
bayer[1::2, 1::2] = B[1::2, 1::2] # bottom right

cv2.imwrite(RESIZE_BAYER_PATH, bayer)

# 4. 把bayer图片数据转成uint16格式
img_array = cv2.imread(RESIZE_BAYER_PATH,cv2.IMREAD_UNCHANGED)
img_array = img_array.astype(np.uint16)

# 打印图像数组的形状和数据类型，以确保它符合 RGB888 的要求
print('Resized Bayer Image shape:', img_array.shape)
print('Resized Bayer Image dtype:', img_array.dtype)

print('\nLoading Bayer Image Done......\n')
#img.save('img_rgb888.jpg')

# 5. 把bayer图片数据转成bin文件
#bayer_to_bin(img_array,BAYER_BIN_PATH,BAYER_DATA_PATH)


