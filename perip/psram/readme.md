psram的设计文档：
1. PSRAM的状态机设计了CMD_PHASE,ADDR_PHASE,DUMMY_CYCLES,DATA_PHASE,WRITE_PHASE,ERR_T 六个状态，其中
* CMD_PHASE状态用于接收指令
* ADDR_PHASE状态用于接收读取或者写入的地址
* DUMMY_CYCLES状态表示读取数据时的延时
* DATA_PHASE状态表示读取数据
* WRITE_PHASE状态表示写入数据
* ERR_T状态表示输入的指令有误
2. psram涉及到了双向的端口，这里可以直接拿一个信号用于接收双向的端口输入的数据，这样可以避免错过输入信号，不需要去考虑什么时间去读取直接一直保存就行，可以学psram_top_apb.v的处理方式。
3. 对于写入数据时的掩码，PSRAM手册没有明确的规定，所以这里采用的方式是将根据写入数据时的counter的变化情况来判断写入的掩码是多少，同时因为这里没有学AXI一样写掩码，所以传入到dpi-c的地址还是一个非对齐的地址，在psram_write中直接将输入的数据写入到地址就行，如果dpi-c调用的时候需要传入对齐的地址，则需要增加对应的wstrb的判断逻辑，现在的wstrb如下
* 4'b0001：表示写入一个字节
* 4'b0011：表示写入两个字节
* 4'b1111：表示写入四个字节
4. 因为写入的时候，dpi-c需要传一个32位的数据，所以在写入一个或者两个字节的时候，需要对数据单独处理，写入的数据应该放在低八位或者低十六位。
------------
使用QPI协议访问PSRAM颗粒：
1. 修改了EF_PSRAM_CTRL_wb和EF_PSRAM_CTRL两个PSRAM控制器的代码，增加了开启QPI模式的代码。
2. 首先需要修改EF_PSRAM_CTRL_wb的代码，增加一个发送开启QPI模式的指令，然后需要修改EF_PSRAM_CTRL中的读取和写入模块的代码，需要修改发送指令的逻辑和发送数据的时机（即PSRAM_READER里面的counter，因为QPI模式比原来发送指令的时候少了6个周期，所以这里的counter的一些判断逻辑以及在不同的counter的时候干的事都需要修改）