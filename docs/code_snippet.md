# zig 사용 예

## 리틀/빅 엔디언 타입
`std.builtin.Endian.Little`, `std.builtin.Endian.Big`
    
  
## 배열
    
### 배열 선언 시 초기화
```
var buffer: [1000]u8 = undefined;

const twelve = [_]u8{ 12, 0, 0, 0 };

var array: [4]u8 = [_]u8{ 11, 22, 33, 44 };

var array: [4]u8 = .{ 11, 22, 33, 44 }; 

const all_zero = [_]u16{0} ** 10;
```  
  
### 특정 값으로 채우기
```
mem.set(u8, &arr1, 0);
```
  
### 배열 복사
```
const array1 = [_]i32{ 3, 1, 4, 1, 5, 9, 2 };
var array2: [array1.len]i32 = undefined;
for (array1) |b, i| array2[i] = b;
```  
  
```
const mem = @import("std").mem;
const array1 = [_]i32{ 3, 1, 4, 1, 5, 9, 2 };
var array2: [array1.len]i32 = undefined;

mem.copy(i32, &array2, &array1);
```     

### 배열을 함수의 인자로 넘기기
```
const std = @import("std");
const print = std.debug.print;

fn printArray(array: []const i32) void {
    for (array) |value| {
        print("{}", .{value});
    }
}

pub fn main() void {
    const array = [_]i32{ 3, 1, 4, 1, 5, 9, 2 };
    printArray(&array);
}
```  
    


## 구조체 
  
### 멤버를 특정 값으로 초기화 하기
```
const Color = struct {
        r: u8,
        g: u8,
        b: u8,
        a: u8,
    };

const c = zeroInit(Color, .{ 255, 255 });
try testing.expectEqual(Color{
    .r = 255,
    .g = 255,
    .b = 0,
    .a = 0,
}, c);
```
  
### packed 구조체  
```
pub const BitmapFileHeader = packed struct {
    magic_header: [2]u8,
    size: u32,
    reserved: u32,
    pixel_offset: u32,
};
```  
     
### 멤버 함수가 있는 구조체 
```
pub const FieldMeta = struct {
    wire_type: WireType,
    number: u61,

    pub fn init(value: u64) FieldMeta {
        return FieldMeta{
            .wire_type = @intToEnum(WireType, @truncate(u3, value)),
            .number = @intCast(u61, value >> 3),
        };
    }

    pub fn encodeInto(self: FieldMeta, buffer: []u8) []u8 {
        const uint = (@intCast(u64, self.number) << 3) + @enumToInt(self.wire_type);
        return coder.Uint64Coder.encode(buffer, uint);
    }

    pub fn decode(buffer: []const u8, len: *usize) ParseError!FieldMeta {
        const raw = try coder.Uint64Coder.decode(buffer, len);
        return init(raw);
    }
};
```

### 이름 없는 구조체
```
fn FromVarintCast(comptime TargetPrimitive: type, comptime Coder: type, comptime info: FieldMeta) type {
    return struct {
        const Self = @This();

        data: TargetPrimitive = 0,

        pub const field_meta = info;

        pub fn encodeSize(self: Self) usize {
            return Coder.encodeSize(self.data);
        }

        pub fn encodeInto(self: Self, buffer: []u8) []u8 {
            return Coder.encode(buffer, self.data);
        }

        pub fn decodeFrom(self: *Self, buffer: []const u8) ParseError!usize {
            var len: usize = undefined;
            const raw = try Coder.decode(buffer, &len);
            self.data = @intCast(TargetPrimitive, raw);
            return len;
        }
    };
}
```    
  

## 함수
  
### 함수 반환 값이 에러 혹은 타입일 때 
에러 혹은  `[]u8`를 반환한다  
```
pub fn decode(buffer: []const u8, len: *usize, allocator: *std.mem.Allocator) ![]u8 {
        var header_len: usize = undefined;
        const header = try Uint64Coder.decode(buffer, &header_len);
        
        std.mem.copy(u8, data, buffer[header_len .. header_len + data.len]);
        len.* = header_len + data.len;

        return data;
    }
}
```
   
### 복수의 값 반환
```
pub fn getPosition() struct { start: i32, end: i32 } {
  const start = 1000;
  const end = 2000;
  return .{
    .start = start,
    .end = end
  };
}    
```
   
   
## 초기화 없이 변수 선언
```
var header_len: usize = undefined;
```  
  
  
## range for  
```
for (bytes) |byte, i| {
            if (i >= 10) {
                return error.Overflow;
            }
            
            if (byte & 0x80 == 0) {
                return value;
            }
        }
}       
``` 
  
## memcpy
```
pub fn encode(buffer: []u8, data: []const u8) []u8 {
    const header = Uint64Coder.encode(buffer, data.len);    
    std.mem.copy(u8, buffer[header.len..], data);
    return buffer[0 .. header.len + data.len];
}
```  
  
## error
```
pub const ParseError = error{
    Overflow,
    EndOfStream,
    OutOfMemory,
};
```  
  
## 컴파일 타임에 함수 선택 하기
```
pub const readStructLittle = switch (native_endian) {
    builtin.Endian.Little => readStructNative,
    builtin.Endian.Big => readStructForeign,
};

pub fn readStructNative(reader: io.StreamSource.Reader, comptime T: type) StructReadError!T {
    var result: T = try reader.readStruct(T);
    try checkEnumFields(&result);
    return result;
}

pub fn readStructForeign(reader: io.StreamSource.Reader, comptime T: type) StructReadError!T {
    var result: T = try reader.readStruct(T);
    try swapFieldBytes(&result);
    return result;
}
```   


## 난수(rand)
  
```
const std = @import("std");
const prng = std.rand.DefaultPrng;
const time = std.time;
const print = std.debug.print;

pub fn main() void {
    var rand = prng.init(@intCast(u64, time.milliTimestamp()));
    print("{}\n", .{rand.random().int(u32)});
}
```


## Allocator (할당자)
Allocator 유형
- c_allocator
    - libc를 링크 할 때 최적 (malloc_usable_size 사용)
- raw_c_allocator
    - malloc/free를 직접 호출 (malloc_usable_size 사용하지 않음)
- page_allocator
    - 메모리 할당 및 해제할 때마다 직접 syscall 호출(Thread-safe and lock-free.)
- 힙 할당자
    - windows에서만 사용할 수 있나? 내부에서 HANDLE 사용
- ArenaAllocator
    - 기존의 할당자를 감싸고, 모아서 해제한다.
- FixedBufferAllocator
    - 고정 길이의 버퍼로 부족한 경우에 사용
- LogToWriterAllocator
    - 다른 할당자를 사용할 때 지정된 Writer에 로그를 출력한다.
- LoggingAllocator
    - 다른 할당자를 사용할 때 std.log 로그를 출력한다.
  
기본적인 사용 방법  
```
const std = @import("std");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```  
  
LoggingAllocator를 사용하는 경우    
```
const std = @import("std");
const loggingAllocator = std.heap.loggingAllocator;

const allocator = loggingAllocator(std.heap.page_allocator).allocator();
// debug: alloc - success - len: 4602, ptr_align: 1, len_align: 1
// debug: free - len: 16384  
```  
    
    
## import
다른 파일에 정의한 함수를 import해서 호출하는 경우   
```
funcs.zig
const std = @import("std");

pub fn debug() void {
  std.log.debug("funcs#debug call", .{});
}
```  
  
↑ 호출하고 싶은 함수에 pub를 붙인다.    
```
main.zig
const funcs = @import("funcs.zig");
const debug = funcs.debug;

pub fn main() void {
    debug();
}
```  
이후 호출하는 측에서 `@import` 하면 된다.  
  
  
  
## 파일
  
### 파일 열기/닫기  
```
const std = @import("std");

pub fn main() !void {
    const file_name = "xxxx";
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();
}
``` 
    
### 파일 사이즈 얻기  
```
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const file_name = "xxxx";
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    try stdout.print("file size: {d}\n", .{file_size});
}
```  
  
### 파일 Read
```
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const file_name = "xxxx";
    const file = try std.fs.cwd().openFile(fileName, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    try stdout.print("file size: {d}\n", .{file_size});

    var reader = std.io.bufferedReader(file.reader());
    var instream = reader.reader();

    const allocator = std.heap. page_allocator;
    const contents = try instream.readAllAlloc(allocator, file_size);
    defer allocator.free(contents);

    try stdout.print("read file value: {c}\n", .{contents});
}
```  
  
  
  