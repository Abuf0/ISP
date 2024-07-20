from PIL import Image
import numpy as np
import cv2


image = cv2.imread('img.jpg')

# 加载 JPG 图片

new_width = 128
new_height = 72
resized_image = cv2.resize(image, (new_width,new_height), interpolation=cv2.INTER_AREA)
cv2.imwrite('img_resize.jpg', resized_image)

img = Image.open('img_resize.jpg')

# 将图像转换为 RGB 模式（如果不是的话）
img = img.convert('RGB')

# 将图像转换为 NumPy 数组
img_array = np.array(img)


# 确保图像的数据类型是 uint8（即每个通道使用 8 位，即 0-255 的整数）
img_array = img_array.astype(np.uint8)

# 打印图像数组的形状和数据类型，以确保它符合 RGB888 的要求
print('Image shape:', img_array.shape)
print('Image dtype:', img_array.dtype)

# 如果需要保存为 RGB888 格式的图像，可以使用以下命令
img.save('img_rgb888.jpg')

# 显示转换后的图像
#img.show()
def int_to_bin8(number):
    binary_string = bin(number & 0xFF)[2:]  # & 0xFF 确保只取低 8 位
    return binary_string.zfill(8)  # 使用 zfill 方法补齐到 8 位

f = open('./img_rgb888.txt','w')
for x in range(0,img_array.shape[0]):
    for y in range(0,img_array.shape[1]):
        for z in range(0,img_array.shape[2]):
            rgb888_bin = int_to_bin8(img_array[x,y,z])
            if(x==2 and y==2):
                print(img_array[x,y,z])
                print(rgb888_bin)
            f.write(rgb888_bin)
        f.write('\n')


f.close()