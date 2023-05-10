# 기본 학습
  
# Hello World
아래 명령어로 프로젝트를 만든다  
`zig init-exe`  
  
아래와 같은 파일이 만들어진다  
<pre>
>tree
│  build.zig
│
└─src
       main.zig
</pre>    
      
src/main.zig  
```
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}	
```
  
빌드하기    
```
zig build
```      
`zig-out\bin\` 디렉토리에 실행 파일이 만들어진다    
    
<br>    
  

# 릴리즈 모드 빌드 
- `zig build -Drelease-fast`
- `zig build -Drelease-safe`
- `zig build -Drelease-small`
  
<br>    


# 외부 라이브러리 사용하기   
[이 문서](https://github.com/Sobeston/ziglearn/blob/master/chapter-3.md )를 참고했다.  
참고로 위 문서에는 라이브러리 만들기와 사용하기를 설명하고 있다  
  
외부 라이브러리가 있는 위치를 build.zig 파일에 입력한다.  
아래는 `pike` 라는 네트워크 라이브러리를 사용하는 예이다.  

`pike` 라이브러리는 이 위치에 있다. `C:\pike_samples\libs\pike`      
    
`pike`를 사용하는 실행 파일 프로젝트를 만든다.  디렉토리는 `C:\pike_samples\tcp_client`  
`build.zig`의 내용이다.  
```
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("tcp_client", "src/main.zig");
    exe.addPackagePath("table-helper", "../libs/pike/pike.zig"); //pike 디렉토리를 추가했다
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
```  
  	
`main.zig`  
```
const std = @import("std");
const pike = @import("pike").Table;

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
```	
	
<br>  	
	
  
# 대입
`(const | var) identifier[: type] = value;`  

- `const` 사용하면 상수로
- `var` 사용하면 변수로
- `identifier: type`  형식으로 형식 지정
    - 추론 가능하다면 `type` 생략 가능
- `undefined` 라는 정의되지 않은 값 사용 가능
- 사용하지 않는 변수는 컴파일 오류가 발생한다.
  
```
const constant: i32 = 5; // 정수
var variable: u32 = 5000; // 변수

std.log.info("constant {}, variable {}", .{ constant, variable });

// 변수이므로 대입 가능
variable = 10000;
std.log.info("variable can be changed {}", .{variable});

// @as(type, value) 으로 대입할 수도 있다.
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);

std.log.info("inferred, constant {}, variable {}", .{ inferred_constant, inferred_variable });

// 타입 추론 가능하다면 type 은 생략 가능
var inferred = variable;
std.log.info("inferred variable {}", .{inferred});

// type을 지정하고 있는 경우에는 `undefined` 을 대입하는 것도 가능
var a: i32 = undefined;
std.log.info("a {}", .{a}); 

// 사용하지 않은 변수는 컴파일 에러가 된다
// var unused: i32 = 0;
// src/main.zig:24:9: error: unused local variable
//     var unused: i32 = 0;
//         ^      
``` 
    
<br>  	

  
# 배열
```
[length]type
```  
  
배열의 리터럴은 아래와 같이 쓴다.  
```
[length]type{elmentA, elmentB, ...}
``` 
  
- type 은 요소의 타입
- length 는 요소 수
- length 는 배열 리터럴의 경우 추론할 수 있기 때문 `_` 라고 기술할 수 있다
- array.len 에서 length 획득 가능
- 요소는 0부터 시작
- 요소에 대한 액세스는 `identifier[index]`
- 요소수가 다르면 타입으로서는 다르므로 대입 등 할 수 없다
- `[_]` 의 추론은 배열 리터럴만 사용할 수 있다.
    
예제 코드는 아래와 같다.   
```
// a의 type은 배열 리터럴에서 추론된다
const a = [5]u8{ 'h', 'e', 'l', 'l', 'o' };

// length 는 배열 리터럴에서 추론된다
const b = [_]u8{ 'w', 'o', 'r', 'l', 'd' };

std.log.info("{} {}", .{ a.len, b.len });

// 변수의 type 을 기술하고 있어도 배열 리터럴의 type은 지정해야 한다.
var c: [3]i32 = [_]i32{ 1, 2, 3 };
// 이렇게 쓰면 컴파일 에러
//var c: [3]i32 = { 1, 2, 3 };
// 이것도 컴파일 에러
//var c: [_]i32 = [_]i32{ 1, 2, 3 };

c[1] = 10;

std.log.info("{} {} {}", .{ c[0], c[1], c[2] });

// 요소수가 서로 다르므로 대입 불가능
// var d: [4]i32 = c;
// std.log.info("{}", .{d.len});
// ./src/main.zig:53:21: error: expected type '[4]i32', found '[3]i32'
//     var d: [4]i32 = c;
//                     ^  
```   
  
  
## 배열 포인터
배열 포인터와 관계된 것으로 아래의 타입이 있다.  
- *[요소 수]요소 타입: 배열전체로의 포인터, 컴파일 시에 요수 수(.len)이 확정된다 
- []요소 타입: 실행 시에 요수 수(.len)이 얻어지는 슬라이스
       
```
const a: [12]u8 = []u8 {1} ** 12;// 배열 변수, 요소 수는 컴파일 시에 확정
const b: *const [12]u8 = &a;// 배열 전체로의 포인터 변수. 요소 수는 컴파일 시에 확정
const c: []const u8 = &a;// 슬라이스 타입. 요소 수는 실행 시에 확정
const d: [*]const u8 = &a;// 배열로의 포인터 변수. 요소 수를 가지지 않는다
```  
위 3개의 변수는 요소 수를 a.len、b.len、c.len으로 취할 수 있지만 d는 그런 수단이 없다
    
아래는 그 외 슬라이스나 배열 포인터로 대입할 때의 구문이다.  
```
const c0: []const u8 = a[0..];
const c1: []const u8 = b;
const c2: []const u8 = c[1..];
const c3: []const u8 = d[0..12];
const d1: [*]const u8 = b;
const d2: [*]const u8 = c.ptr;
const d3: [*]const u8 = d + 1;
```    
배열 포인터에서 슬라이스를 만드는 (c3)에는 종점 인덱스 지정이 필수이다    
  
<br>  	  
  
  
# if 
```
if (conditionA) {
  // ...
} else if (conditionB) {
  // ...
} else {
  // ...
}
```  
  
`if`, `else if` 의 조건부는 괄호가 필요하며, 어떤 식을 사용할 수 있다(물론 진위 값을 반환해야 함). 또 if 자체도 식이 되므로, 아래와 같이 기술할 수 있다.  
```
var v = if (condition) valueA else valueB;
```  
   
예제 코드  
```
const a = true;
if (a) {
    std.log.info("true", .{});
}

const b = false;
if (!b) {
    std.log.info("not false", .{});
}

const i = 1;
if (i == 0) {
    // unreached
} else if (i == 1) {
    std.log.info("else if", .{});
} else {
    // unreached
}

// if 는 식이므로 값을 반환 할 수 있다.
const j = if (i == 0) 10 else 20;
std.log.info("{}", .{j});
```    

<br>  
 
  
# Switch
```
const a: i8 = 5;

switch (a) {
    0...4 => std.log.info("4 이하", .{}),
    5,6 => std.log.info("5 나 6", .{})
    else => std.log.info("else", .{}),
}

const b = switch (a) {
    0 => 0,
    1 => 1,
    else => a * 2,
};
```  
  
- fall through 하지 않는다
- 값을 반환할 수 있다.
- `...`는 값의 범위를 나타낸다.
    - 양쪽 끝의 값은 포함
- 복수의 값을 같은 분기로 취급하고 싶은 경우에는 `,` 로 단락지어 복수 기술한다
- else 를 사용하면 다른 조건이 충족되지 않은 분기가 된다.
    - else 가 모든 조건을 충족시키지 못하면 컴파일 오류가 발생하는 것 같다.
     
이번에 확인한 코드는 다음과 같다.    
```
const a: i8 = 5;

switch (a) {
    // ... 는 Range 를 나타낸다. 양쪽 값은 포함된다. 0 이상 5 이하
    0...5 => std.log.info("0 이상 5 이하", .{}),
}

// 아래는 5의 경우는 처리가 없으므로 컴파일 에러가 된다. 
// switch (a) {
//     0...4 => std.log.info("5 미만", .{})
// }

switch (a) {
    // 분기의 구별은 ,
    0...4 => std.log.info("5 미만", .{}),
    else => std.log.info("else", .{}), // <- 마지막 분기의 콤마도 허용된다. 없어도 괜찮다
}

// 식으로도 된다
const b = switch (a) {
    0 => 0,
    1 => 1,
    else => a * 2,
};

std.log.info("b: {}", .{b});
```  
  

<br>  
  

# while
```
var i: u8 = 2;

// 100을 넘을 때까지 2배씩 되므로 i = 64 때는 실행된다
while (i < 100) {
    // 마지막은 64 * 2 이므로 128 이 된다
    i *= 2;
}
std.log.info("i: {}", .{i}); // i: 128

var sum: u8 = 0;
var j: u8 = 1;


// continue expression 는 루프가 반복되는 경우 블럭 코드 앞에 실행된다
while (j <= 10) : (j += 1) {
    // 1, 2 (1 + 1), 3 (2 + 1), ..., 10 까지 표시된다
    std.log.info("j: {}", .{j});
    sum += j;
}
std.log.info("sum: {}", .{sum}); // 55

while (j < 1) : (sum += 100) {
    // do nothing
}
// 이번의 continue expression 는 실행 되지 않으므로 55 이다
std.log.info("sum: {}", .{sum}); // 55

var k: u8 = 0;
while (k <= 3) : (k += 1) {
    if (k == 1) continue;
    if (k == 3) break;
    std.log.info("k: {}", .{k}); // 0, 2
}
```  
    
<br>  
  
  
# for
```
const nums = [_]u8{10, 20, 30};

// 요소, 인덱스 순으로 기술한다
for (nums) |number, index| {
    std.log.info("{} : {}", .{number, index});
}

// 1개라면 요소가 된다
for (nums) |number| {
    std.log.info("{}", .{number});
}

// _ 을 사용하여 이용하지 않는 값을 무시할 수 있다
for (nums) |_, index| {
    std.log.info("{}", .{index});

    // 물론 대상은 배열이므로 인덱스로 참조 가능
    std.log.info("{}", .{nums[index]});
}
```
   
<br>  
  

# Functions
```
fn name(value: type, ...) type {
  return return_value;
}
```   
  
- 변수명은 snake_case로 함수명은 camelCase로 기술한다
- 결과 호출을 무시하고 싶을 때 `_` 을 사용한다
- 함수의 인수는 이뮤터블
  
예제 코드  
```
fn add(x: u32, y: u32) u32 {
    // 인수는 이뮤터블이므로 재대입 할 수 없다
    // 컴파일 에러가 된다
    // x = 10;
    // ./src/main.zig:147:9: error: cannot assign to constant
    //     x = 10;
    return x + y;
}

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

fn function() void {
    const a = add(1, 2);
    std.log.info("a: {}", .{a});

    // 반환 값을 무시할 때는 명시적으로 기술한다
    _ = add(100, 200);

    // 반환 값을 무시하면 컴파일 에러가 된다
    // add(100, 200);
    // ./src/main.zig:158:8: error: expression value is ignored
    //     add(100, 200);

    // 재귀 호출은 오버플로우 발생 가능성이 있으므로 unsafe
    const x = fibonacci(24);
    std.log.info("x: {}", .{x});

    // 컴파일 에러가 된다
    //const y = fibonacci(25);
    //std.log.info("y: {}", .{y});

    // 25 이후는 u16 을 넘으므로 panic 이 발생한다
    // thread 1118951 panic: integer overflow
}
```  
  
<br>  


#  Defer
- defer는 현재 블록을 빠져 나올 때 호출된다.
- 동일한 블록에 대해 여러 개가 있으면 후입선출로 호출된다.
- defer로 지정할 수 있는 것은, 대입이나 void 함수의 호출 등 값을 돌려주지 않는 statement 가 된다
  
예제 코드  
```
fn defer_() void {
    std.log.info("enter", .{});
    {
        // 이 블록을 빠져 나올 때에 실행되므로 enter 다음에 출력된다
        defer std.log.info("defer1", .{});
    }
    // defer 는 뒤에서 지정된 것이 먼저 실행되므로 defer3 다음에 출력된다
    defer std.log.info("defer2", .{});

    // defer_ 를 빠져 나올 때에 실행되므로 exit 다음에 출력된다
    defer std.log.info("defer3", .{});

    std.log.info("exit", .{});
}

// 결과
// info: enter
// info: defer1
// info: exit
// info: defer3
// info: defer2
```    

<br>  


# Imports 
어떤 언어라도 언어 자체에 준비 되어 있는 표준 라이브러리를 이용하거나, 코드를 복수의 파일로 나누어 관리해서 연계시키는 일이 발생한다. Zig는 import 기능을 제공한다.  
```
const name = @import("path");
```  
  
- path 는 표준 라이브러리의 경우 제공되는 패키지 이름을 지정한다.
- 직접 관리하는 파일을 사용하는 경우 상대 경로를 작성한다. 확장자 .zig 는 필수이다.
- `@import` 는 어느 곳이든지 호출 가능
    - 파일의 시작 부분도 좋고, 함수 내에서도 좋다.
- `name` 은 선택 사항이므로 패키지 이름과 동일하지 않을 수 있다.
- `pub` 를 사용하여 함수나 변수로 한정하면 다른 파일에서 가져올 때 사용할 수 있다.
    - `pub` 이 붙어 있지 않은 것은 private가 된다.
- `pub`의 범위는 파일 단위이다.
  
예제 코드  
  
src/main.zig  
```
fn import_() void {
    // @import 인수에 파일의 상대 패스를 지정한다
    // `.zig` 확장자를 생략할 수는 없다
    // @import 는 임의의 곳에서 호출 가능
    const bar = @import("foo/bar.zig");

    // pub 가 붙은 것은 다른 파일에서도 참조가 가능하다
    bar.hello();
    _ = bar.public;

    // 붙어 있지 않은 것은 참조할 수 없으므로 컴파일 에러가 된다.
    _ = bar.private;

    // ./src/main.zig:209:12: error: 'private' is private
    //     _ = bar.private;
    //            ^
    // ./src/foo/bar.zig:4:1: note: declared here
    // const private = "private";
    // ^
}
```  
  
src/foo/bar.zig  
```
const std = @import("std");

pub const public = "public";
const private = "private";

pub fn hello() void {
    std.log.info("hello", .{});
}  
```
  
<br>  
  

# Error

## Error Set
Zig에서 에러를 정의할 때는 Error Set 을 정의한다. Enum과 같은 구문으로 작성한다.  
```
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
```  
  
하지만 `Error Set` 이 다른 `Error Set`의 서브셋(요소가 동일하거나 일부)일 때는 슈퍼셋 함께 취급할 수 있다.  
```
const AllocationError = error{OutOfMemory};
// FileOpenError ⊇ AllocationError 로 취급된다
const err: FileOpenError = AllocationError.OutOfMemory;

// 어느쪽이라도 `OutOfMemory` 도 같다
std.log.info("Same error: {}", .{err == FileOpenError.OutOfMemory});
std.log.info("Same error: {}", .{FileOpenError.OutOfMemory == AllocationError.OutOfMemory});
```    
  
머지   
`Error Set` 은 머지할 수 있다.  
```
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
```  
  
`anyerror`   
`anyerror`는 모든 에러 셋의 슈퍼 셋이 되는 에러 셋이다. 이 타입을 일반적으로 사용하는 것은 피하는 것이 좋다.
 
<br>  
  
  
# 구조체
https://qiita.com/bellbind/items/f2338fa1d82a2a79f290#32-%E8%A4%87%E7%B4%A0%E6%95%B0struct%E3%81%AE%E5%AE%9A%E7%BE%A9
  
  
# 비트 연산 빌트인
https://qiita.com/bellbind/items/f2338fa1d82a2a79f290#%E3%83%93%E3%83%83%E3%83%88%E6%BC%94%E7%AE%97%E3%81%AE%E3%83%93%E3%83%AB%E3%83%88%E3%82%A4%E3%83%B3
  


# 포인터 타입
https://qiita.com/bellbind/items/f2338fa1d82a2a79f290#%E3%83%9D%E3%82%A4%E3%83%B3%E3%82%BF%E5%9E%8B


# 캐스트(Cast)
zig에서는 동일 수치 타입종에서 비트 수가 증가하는 경우에만 암묵적으로 확대할 수 있다.  
이 외는 변수의 스펙에 따라서 각각의 캐스트용 빌트인 함수를 선택해서 사용해야 한다.  
   
아래는 대표적인 빌트인 캐스트 함수이다.     
- @truncate(변환 타입, 값): 변환 타입의 비트 수까지 하위 비트만 짤라내고 캐스트 시프트 연산에서는 시프트할 변수의 타입 비트 수에 딱 맞는 수치 타입으로 짤라 줄여야 한다.  32는 5승이므로, u32의 시프트 연산의 우측 값에서는 타입을 u5로 짤라줄인다.
- @bitCast(변환 타입, 값): 비트 레이아웃을 보호하는 캐스트. 비트 필드로서 f64를 u64로 변환 하는 경우 등.
- @ptrCast(변환 포인터 타입, 포인터 타입): 포인터 타입 변환
- @intCast(변환 정수 타입, 정수값): 비트 수 다른 정수값 타입 변환
- @floatCast(변환 부동소수 타입, 부동소수값): 비트 수 다른 부동 소수 값 타입 변환
- @floatToInt(변환 정수 타입, 부동소수값): 정수로 정수로 수치 변환
- @intToFloat(변환 부동소수 타입, 정수값): 부동소수로 수치 변환
- @ptrToInt(변환 정수 타입, 포인터값): 포인트 어드레스 정수로 변수
- @intToPtr(변환 포인터 타입, 정수값): 포인터 어드레스 값에서 포인터로 변환
- @boolToInt(진위값): 진위값의 정수(u1)로 변환
   
<br>    
  
  
# 문자열
- Zig 문자열은 `[]u8`. 길이로 관리되며 C와 달리 NUL 문자로 종료되지 않는다.(캐릭터 코드의 규정은 언어로서는 하지 않지만, std 라이브러리에서는 utf-8을 상정하고 있다.) 
- 문자열 리터럴은 immutable로 리드 온리의 메모리 섹션에 배치되지만, 이 때 NUL 문자로 종단된다고 사양서에 명기되어 있다.
- 따라서 C 함수에 문자열 리터럴을 전달할 때마다 NUL 문자를 추가 할 필요가 없으며 그대로 전달할 수 있다.
- 덧붙여서, 최근 Rust에서도 그 편리함이 전해진 것 같고, `c"Hello"`와 같이 머리에 `c`를 붙이면 NUL 문자로 종단하는 문자열 리터럴을 정의할 수 있는 기능이 추가 되었다. 




https://qiita.com/bellbind/items/f2338fa1d82a2a79f290