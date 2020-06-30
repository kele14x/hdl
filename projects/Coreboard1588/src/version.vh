/*
Copyright (c) 2019 Chengdu JinZhiLi Technology Co., Ltd.
All rights reserved.
*/

localparam [31:0] PRODUCT_ID = {"J", "Z", "L", 8'h9};

localparam [7:0] VERSION_MAIN  = 8'h1;
localparam [7:0] VERSION_HIGH  = 8'h4;
localparam [7:0] VERSION_LOW   = 8'h0;
localparam [7:0] VERSION_DEBUG = 8'h0;

localparam [31:0] VERSION = {VERSION_MAIN, VERSION_HIGH, VERSION_LOW, VERSION_DEBUG};
