from PIL import Image
import numpy as np
import cv2

img = cv2.imread("./img.jpg",cv2.IMREAD_UNCHANGED)

(height, width) = img.shape[:2]
(B,G,R) = cv2.split(img) 
img_conf = img
img_conf[:,:,0]=B
img_conf[:,:,1]=G
img_conf[:,:,2]=R
cv2.imwrite('conf_img.jpg', img_conf)

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

image = cv2.imread('bayer_img.jpg',cv2.IMREAD_UNCHANGED)

# 加载 JPG 图片

new_width = 128
new_height = 72
resized_image = cv2.resize(image, (new_width,new_height), interpolation=cv2.INTER_AREA)
cv2.imwrite('img_bayer_resize.jpg', resized_image)


# 将图像转换为 RGB 模式（如果不是的话）
#img = resized_image

# 将图像转换为 NumPy 数组
#img_array = np.array(img)


# 确保图像的数据类型是 uint8（即每个通道使用 8 位，即 0-255 的整数）
#img_array = img_array.astype(np.uint16)

img_array = cv2.imread('img_bayer_resize.jpg',cv2.IMREAD_UNCHANGED)
img_array = img_array.astype(np.uint16)

# 打印图像数组的形状和数据类型，以确保它符合 RGB888 的要求
print('Image shape:', img_array.shape)
print('Image dtype:', img_array.dtype)

# 如果需要保存为 RGB888 格式的图像，可以使用以下命令
#img.save('img_rgb888.jpg')

# 显示转换后的图像
#img.show()
def int_to_bin16(number):
    binary_string = bin(number & 0xFFFF)[2:]  # & 0xFF 确保只取低 8 位
    return binary_string.zfill(16)  # 使用 zfill 方法补齐到 8 位

f = open('./img_bayer_bin.txt','w+')
f1 = open('./img_bayer.txt','w+')
for x in range(0,img_array.shape[0]):
    for y in range(0,img_array.shape[1]):
        bayer_bin = int_to_bin16(img_array[x,y])
        if(x==2 and y==2):
            print(img_array[x,y])
            print(bayer_bin)
        f.write(str(bayer_bin))
        f1.write("(%d,%d):%d"%(x,y,img_array[x,y]))
        f.write('\n')
        f1.write('\n')

f.close()
f1.close()