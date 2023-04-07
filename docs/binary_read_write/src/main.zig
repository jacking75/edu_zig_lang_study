const print = std.debug.print;
const std = @import("std");
const io = std.io;
const mem = std.mem;


pub fn main() anyerror!void {
    buffer_slice_read_write();
    io_reader_writer_read_write();
}

pub fn buffer_slice_read_write() void {    
    print("buffer_slice_read_write - START\n", .{});

    //[ 초기화 ]

    //미정의 초기화
    var arr1: [16]u8 = undefined;
    print( "{}, {}, {}, {}\n", .{arr1[0], arr1[1], arr1[2], arr1[3]} );

    //memset으로 초기화 
    mem.set(u8, &arr1, 0);
    print( "{}, {}, {}, {}\n", .{arr1[0], arr1[1], arr1[2], arr1[3]} );



    //[ 쓰기 ]

    //memcpy
    var value1: i32 = 15;
    @memcpy(&arr1, @ptrCast([*]const u8, &value1), 4);  
    print( "{}, {}, {}, {}\n", .{arr1[0], arr1[1], arr1[2], arr1[3]} );

    value1 = 20;
    @memcpy(arr1[4..8], @ptrCast([*]const u8, &value1), 4);  
    print( "{}, {}, {}, {}\n", .{arr1[4], arr1[5], arr1[6], arr1[7]} );
 
    // std.mem.writeIntSlice
    value1 = 77;
    std.mem.writeIntSlice(i32, arr1[8..12], value1, std.builtin.Endian.Little);
    print( "{}, {}, {}, {}\n", .{arr1[8], arr1[9], arr1[10], arr1[11]} );

    //std.mem.toBytes
    value1 = 88;
    var arrRet = std.mem.toBytes(value1);
    print( "{}, {}, {}, {}\n", .{arrRet[0], arrRet[1], arrRet[2], arrRet[3]} );


    //[ 읽기 ]
    var value2 : i32 = 0;
    var pos : u32 = 0;

    //std.mem.readIntSliceLittle
    value2 = std.mem.readIntSliceLittle(i32, arr1[pos..4]);
    print("arr1[0-4] - {}\n", .{value2});

    //std.mem.bytesToValue
    value2 = std.mem.bytesToValue(i32, arr1[4..8]);
    print("arr1[4-8] - {}\n", .{value2});


    //std.mem.readInt
    value2 = std.mem.readInt(i32, arr1[8..12], std.builtin.Endian.Little);
    print("arr1[8-12] - {}\n", .{value2});

    // 
    //fn std.mem.readInt(comptime T: type, bytes: *const [@divExact(@typeInfo(T)..bits, 8)]u8, endian: Endian) T
    //fn std.mem.readIntSlice(comptime T: type, bytes: []const u8, endian: Endian) T
    //fn std.mem.readVarInt(comptime ReturnType: type, bytes: []const u8, endian: Endian) ReturnType

    print("buffer_slice_read_write - END\n", .{});
}

  
