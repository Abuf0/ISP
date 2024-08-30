# ISP
# 开发日志

- 2024/8/25
    - 完成顶层集成
    - <TODO：部分数据位宽/格式未统一>

- 2024/8/26
    - 搭建testbench仿真环境
    - 服务器手动同步项目
    - fix编译error，能出波形
    - <TODO：按模块顺序验证，比对数据，是否要引入scb或简单print数据比对？>

- 2024/8/27
    - fixing dpc bug
        - add padding
        - fix timing & matched raw data
        - print dpc
        - <TODO：修改了driver&diplay的分辨率，后期需要改回来>

- 2024/8/28
    - fixed dpc bug
        - cv2 & PLI read pic are different
        - fix python runtime error: overflow
        - fixed pen slip
    - fixed blc bug
    - fixed aaf
    - <TODO: building isp_pipeline.py>

- 2024/8/29
    - fixed awb
    - fixing cnf bug

- 2024/8/30
    - fixed cnf bug
    - fixing cfa bug
        - new pipe code cannot trans bayer-to-rgb
        - <TODO: confirm raw bayer format>