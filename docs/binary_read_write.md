# 바이너리 데이터 다루기
  
  
## std.mem 
    
  
## stream reader, writer
https://ziglang.org/documentation/master/std/#root;io.Reader  
https://ziglang.org/documentation/master/std/#root;io.Writer     
  
    
  
## 구조체 
- 바이너리 데이터를 구조체로 읽는 예 [bmp](https://github.com/zigimg/zigimg/blob/master/src/formats/bmp.zig )   [jpeg](https://github.com/zigimg/zigimg/blob/master/src/formats/jpeg.zig )   
  

### packed struct   
보통의 구조체와는 달리 packed struct는 메모리 내의 레이아웃이 보증된다. 필드는 선언된 순서로 나열된다.
- 필드 사이에 패딩이 없다
- Zig은 임의의 폭을 가지는 정수를 지원하고 있으며, 보통 8비트 미만의 정수는 1바이트 메모리를 사용하지만 packed struct는 이 비트 폭을 정확하게 사용한다. 
- enum 필드는 이 정수 태그 타입의 비트 폭을 그대로 사용한다.
- packed union 필드는 최대 비트 폭을 가진 union 필드 비트 폭을 정확하게 사용한다
- 비 ABI 얼라이먼트 필드는 타겟 엔디언에 따르고, 가능한 작은 API 얼라이먼트 정수에 pack 된다
  
    
### 스트림 읽기
출처: https://github.com/zigimg/zigimg/blob/master/src/formats/bmp.zig    
```
pub fn read(self: *Self, allocator: Allocator, stream: *Image.Stream, pixels_opt: *?color.PixelStorage) ImageReadError!void {
        // Read file header
        const reader = stream.reader();
        self.file_header = try utils.readStructLittle(reader, BitmapFileHeader);
        if (!mem.eql(u8, self.file_header.magic_header[0..], BitmapMagicHeader[0..])) {
            return ImageReadError.InvalidData;
        }

        // Read header size to figure out the header type, also TODO: Use PeekableStream when I understand how to use it
        const current_header_pos = try stream.getPos();
        var header_size = try reader.readIntLittle(u32);
        try stream.seekTo(current_header_pos);
```    
  
   
### @field
구조체의 멤버의 값을 읽을 수 있음  
https://ziglang.org/documentation/master/#field    
```
@field 
@field(lhs: anytype, comptime field_name: []const u8) (field)
```
   
std.meta를 사용하여 메타 프로그래밍 가능하다    
https://ziglang.org/documentation/master/std/#root;meta   
```
//https://github.com/zigimg/zigimg/blob/master/src/utils.zig

pub const readStructLittle = switch (native_endian) {
    builtin.Endian.Little => readStructNative,
    builtin.Endian.Big => readStructForeign,
};

pub fn readStructNative(reader: io.StreamSource.Reader, comptime T: type) StructReadError!T {
    var result: T = try reader.readStruct(T);
    try checkEnumFields(&result);
    return result;
}

fn checkEnumFields(data: anytype) StructReadError!void {
    const T = @typeInfo(@TypeOf(data)).Pointer.child;
    inline for (meta.fields(T)) |entry| {
        switch (@typeInfo(entry.field_type)) {
            .Enum => {
                const value = @enumToInt(@field(data, entry.name));
                _ = std.meta.intToEnum(entry.field_type, value) catch return StructReadError.InvalidData;
            },
            .Struct => {
                try checkEnumFields(&@field(data, entry.name));
            },
            else => {},
        }
    }
}
``` 
    
      


  