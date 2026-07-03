// GENERATED from command_descriptor_v0_1.yaml - DO NOT EDIT
`ifndef MAGPIE_NPU_CQ_DEFS_VH
`define MAGPIE_NPU_CQ_DEFS_VH

localparam CQ_OP_MAT_CFG = 6'h01;
localparam CQ_OP_MAT_LOAD_W = 6'h02;
localparam CQ_OP_MAT_OP = 6'h03;
localparam CQ_OP_MAT_RESCALE = 6'h04;
localparam CQ_OP_MAT_STORE = 6'h05;
localparam CQ_OP_MAT_ACC_CLR = 6'h06;
localparam CQ_OP_MAT_FENCE = 6'h07;

localparam [31:0] CQ_W0_OPCODE_MASK = 32'h0000003F;
localparam integer CQ_W0_OPCODE_LSB = 0;
localparam [31:0] CQ_W0_DTYPE_MASK = 32'h000000C0;
localparam integer CQ_W0_DTYPE_LSB = 6;
localparam [31:0] CQ_W0_ACC_MASK = 32'h00000F00;
localparam integer CQ_W0_ACC_LSB = 8;
localparam [31:0] CQ_W0_IRQ_MASK = 32'h00001000;
localparam integer CQ_W0_IRQ_LSB = 12;
localparam [31:0] CQ_W0_FENCE_MASK = 32'h00002000;
localparam integer CQ_W0_FENCE_LSB = 13;
localparam [31:0] CQ_W0_LAST_MASK = 32'h00004000;
localparam integer CQ_W0_LAST_LSB = 14;
localparam [31:0] CQ_W0_RPT_MASK = 32'h00FF0000;
localparam integer CQ_W0_RPT_LSB = 16;
localparam [31:0] CQ_W0_RSVD_MASK = 32'hFF008000;

localparam [31:0] CQ_ERR_BAD_OPCODE = 32'h00000001;
localparam [31:0] CQ_ERR_RSVD_VIOLATION = 32'h00000002;
localparam [31:0] CQ_ERR_RING_OVERRUN = 32'h00000003;
localparam [31:0] CQ_ERR_ENGINE_NOT_READY = 32'h00000004;
localparam [31:0] CQ_ERR_DMA_FAULT = 32'h00000005;
localparam [31:0] CQ_ERR_DESC_ALIGN = 32'h00000006;

localparam [31:0] CQ_CORE_WINDOW_BASE = 32'h00020000;
localparam [31:0] CQ_MAILBOX_BASE = 32'h00010000;
localparam [7:0] CSR_CQ_RING_BASE = 8'h40;
localparam [7:0] CSR_CQ_RING_SIZE = 8'h44;
localparam [7:0] CSR_CQ_HEAD = 8'h48;
localparam [7:0] CSR_CQ_TAIL = 8'h4C;
localparam [7:0] CSR_CQ_CTRL = 8'h50;
localparam [7:0] CSR_CQ_STATUS = 8'h54;
localparam [7:0] CSR_ERR_CAUSE = 8'h58;
localparam [7:0] CSR_CQ_EVENT = 8'h5C;

`endif
