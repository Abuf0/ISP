from openpyxl import load_workbook
import unicodedata
# 设置寄存器寻址属性
TOP_NAME = 'pacific_top'
ACCESS_WIDTH = 16
REG_WIDTH = 16
ENDIAN_TYPE = 'littleendian'

# 设置寄存器属性title
OFFSET_TITLE = 'Offset'
REG_NAME = 'Name'
MSB_TITLE = 'MSB'
LSB_TITLE = 'LSB'
FIELD_NAME = 'Field Name'
REG_ACCESS = 'Access'
DEFAULT_VALUE = 'Default Value'
DESCRIPT = 'Description'

search_name = [OFFSET_TITLE,REG_NAME,MSB_TITLE,LSB_TITLE,FIELD_NAME,REG_ACCESS,DEFAULT_VALUE,DESCRIPT]
search_index = []
# TODO
access_type = ['RW','RO','W1C','WO']
sw_config = ['rw','r','w','w']
hw_config = ['r','w','na;\n\t\t\t\tswmod = true','na;\n\t\t\t\tswmod = true']
SW_CFG = dict(zip(access_type,sw_config))
HW_CFG = dict(zip(access_type,hw_config))

# 读取Excel文件
file_path = './reglist_GUS1.xlsx'  # 替换为你的Excel文件路径
sheet_name = 'Sheet1'  # 替换为你想读取的工作表名称

# 创建一个字典来存储结果
search_dict = {}
row_title = 0

# 加载工作簿
workbook = load_workbook(filename=file_path, data_only=True)

# 选择工作表
sheet = workbook[sheet_name]

class REG:
    def __init__(self,msb,lsb,field_name,access,default,descrip,sw_cfg,hw_cfg,rdl_file):
        self.msb = msb
        self.lsb = lsb
        self.field_name = field_name
        self.access = access
        self.default = default
        self.descrip = descrip
        self.sw_cfg = sw_cfg
        self.hw_cfg = hw_cfg
        self.rdl_file = rdl_file
    def cfg(self):
        sw = self.sw_cfg[self.access]  
        hw = self.hw_cfg[self.access]
        desc = unicodedata.normalize('NFKC',str(self.descrip))
        if desc and '\n' in desc:
            desc = desc.replace('\n','<br/>\n\t\t\t\t\t\t')
        field_name = self.field_name
        addr = '['+str(self.msb)+':'+str(self.lsb)+']'
        default = self.default
        return sw,hw,desc,field_name,addr,default
    def reg2rdl(self):
        sw,hw,desc,field_name,addr,default = self.cfg()
        file = self.rdl_file
        file.write("\t\t\tfield {\n")
        file.write("\t\t\t\tsw = %s;\n"%(sw))
        file.write("\t\t\t\thw = %s;\n"%(hw))
        file.write("\t\t\t\tdesc = \"%s\";\n"%(desc))
        file.write("\t\t\t} %s%s = %s;\n"%(field_name,addr,default))



# 逐行检查Title
for row_idx, row in enumerate(sheet.iter_rows(values_only=True), start=0):
    # 检查行是否包含任何一个搜索字段
    if all(field in row for field in search_name):
        # 获取当前行的所有单元格
        print("TITLE所在行数:",row_idx)
        row_title = row_idx
        for index, cell_value in enumerate(row, start=0):
            if cell_value in search_name:
                search_dict[cell_value] = index  # 保存单元格的值和对应的列数
if(len(search_dict) == 0):
    print("Title错误!!!")
    exit()
else:
    print("单元格值和对应列号的字典:", search_dict)

# 逐行检查寄存器信息
rdl_file = open('./regmap.rdl','w+')
#regfile_name = row[search_dict[REGFILE_NAME]]
#regfile_offset = row[search_dict[OFFSET_TITLE]]
rdl_file.write("addrmap regmap {\n")
rdl_file.write("name = \"%s\";\n"%(TOP_NAME))
rdl_file.write("default accesswidth = %s;\n"%(str(ACCESS_WIDTH)))
rdl_file.write("default regwidth = %s;\n"%(str(REG_WIDTH)))
rdl_file.write("%s;\n"%(ENDIAN_TYPE))

rdl_file.write("\tregfile dbg{\n")

reg_name = None
reg_offset = 0
for row_idx, row in enumerate(sheet.iter_rows(min_row=row_title+2,values_only=True), start=0):
    if(row[search_dict[OFFSET_TITLE]]!=None and row[search_dict[REG_NAME]]!=None):
        #print(row[search_dict[OFFSET_TITLE]])
        #print(row[search_dict[REGFILE_NAME]])
        if(reg_name!=None):
            rdl_file.write("\t\t} %s @%s;\n"%(reg_name,reg_offset))
        reg_name = row[search_dict[REG_NAME]]
        reg_offset = row[search_dict[OFFSET_TITLE]]
        rdl_file.write("\t\treg {\n")
    elif(row[search_dict[MSB_TITLE]]!=None and row[search_dict[LSB_TITLE]]!=None and row[search_dict[FIELD_NAME]]!='-'):
        obj = REG(row[search_dict[MSB_TITLE]],row[search_dict[LSB_TITLE]],row[search_dict[FIELD_NAME]],row[search_dict[REG_ACCESS]],row[search_dict[DEFAULT_VALUE]],row[search_dict[DESCRIPT]],SW_CFG,HW_CFG,rdl_file)
        obj.reg2rdl()
rdl_file.write("\t\t} %s @%s;\n"%(reg_name,reg_offset))
rdl_file.write("\t} dbg @0x0000;\n")
rdl_file.write("};\n")
rdl_file.close()