# Zig-learning-docs-to-server-programmer
  
- [ZigLang 한글 공식 사이트](https://ziglang.org/ko )
    - [배우기](https://ziglang.org/ko/learn/ ) 
    - [시작하기](https://ziglang.org/ko/learn/getting-started/ )
    - [Zig Language Reference](https://ziglang.org/documentation/master/ ) [한국어](https://runebook.dev/ko/docs/zig/-index- )
    - [STD](https://ziglang.org/documentation/master/std/#root )
- [Playground](https://zig-play.dev/ )
- [GitHub](https://github.com/ziglang/zig )
- [Zig 첫인상](https://velog.io/@maxtnuk/Zig-%EC%B2%AB%EC%9D%B8%EC%83%81 ) 
- [(일어) Zig 언어의 문서를 보고 "과연" 이라고 생각한 부분](https://zenn.dev/tetsu_koba/articles/032d3a2f675f50 )
- [JetBrains Plugin - Zig Support](https://plugins.jetbrains.com/plugin/18062-zig-support/versions )
  
  
# 설치
- [Zig 언어를 Ubuntu(WSL2)에 설치](https://docs.google.com/document/d/e/2PACX-1vSK1VpNBg9P-I1Fvr0LuBlxKAuMtYeH0We7n-jAUqq4x9YDQhS3i0kSVE2O2T0bV01mLmCcZK5m74hX/pub ) 
  

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
    
	
# 릴리즈 모드 빌드 
- `zig build -Drelease-fast'
- `zig build -Drelease-safe`
- `zig build -Drelease-small`
  
  
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
   
    
# 배열 포인터
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
  
  
  
# 학습
- https://ziglearn.org/chapter-1/
- https://ziglang.org/documentation/0.9.1/
- [(일어) Zig에서 Hello World](https://qiita.com/PenguinCabinet/items/46184806f3410e37d6a7 )
- [(일어) Zig에 대해서](https://zenn.dev/hnakamur/books/memo-about-zig )
- [(일어) 대략적으로 Zig 소개](https://zenn.dev/hastur/articles/bacbe2af2c5807)
- [(일어) 문법 정리](https://qiita.com/bellbind/items/f2338fa1d82a2a79f290 )
- [exercises](https://github.com/ratfactor/ziglings/tree/main/exercises )
- [(일어) Zig 언어의 산술연산자](https://zenn.dev/yohhoy/articles/zig-exotic-arithops )  
- [(일어) Zig 표준 라이브러리에서 준비되어 있는 컬렉션 타입을 정리](https://zenn.dev/magurotuna/articles/zig-std-collections )
  
  
  
# VSCode
- [VSCode - Zig](https://marketplace.visualstudio.com/items?itemName=prime31.zig)
- [Debugging Zig with VS Code](https://dev.to/watzon/debugging-zig-with-vs-code-44ca )
- [Windows용 VS Code에서 Zig 코드 디버그](https://zhuanlan.zhihu.com/p/463740524 )
  
  
  
# 응용 
- [(일어) Zig으로 쓴 cmd 애플리케이션에 perf 사용하기](https://zenn.dev/hnakamur/articles/use-perf-to-cli-app-written-in-zig )
- [(일어) Zig에서 출력을 버퍼링하기](https://zenn.dev/woxtu/articles/output-buffering-in-zig )
- [GLFW and OpenGL in Zig on Windows](https://wirywolf.com/2020/06/glfw-and-opengl-in-zig-on-windows.html )   
- [How to use a dynamic library generated by Zig-lang in C++ codebase](https://medium.com/codex/how-to-use-a-dynamic-library-generated-by-zig-lang-in-c-codebase-f83790520e03 )    
- [(일어) C 언어의 소스 코드를 Zig으로 변환하는 기능을 해보기](https://zenn.dev/tetsu_koba/articles/421198dc669f19 )    
- [(일어) 초초보: Zig에서 C의 함수를 호출해보기](https://qiita.com/tonluqclml/items/6f4119b252056fff0870 )    
- [(일어) zig으로 OpenGL 그리고 wasm](https://qiita.com/ousttrue/items/4802b61ba340dd7d89f3 )
    
    
# 네트워크 프로그래밍
- [(일어) Zig로 UDP 통신을 하는 샘플 프로그램](https://zenn.dev/tetsu_koba/articles/4840401763bed3 )
- [(일어) Zig로 TCP 통신을 하는 샘플 프로그램](https://zenn.dev/tetsu_koba/articles/ed68ef22d2af4c )
- [(일어) Zig로 Linux의 epoll과 signalfd 시스템 콜을 사용하는 샘플 프로그램](https://zenn.dev/tetsu_koba/articles/7fb5e7d13479ba )
  

  
# Build 
- [Zig는 CMake의 대안이 될 것인가?](https://docs.google.com/document/d/e/2PACX-1vToY39cQaruHJaT43qCC9pTJk_szsFsaPG3FJusj8FpsY188ZWYPJtAdM-4bB-ten9jN9aBt547AkvZ/pub )
- [(일어) zig을 make 대신에 사용할 때의 첫걸음](https://qiita.com/tonluqclml/items/1724ac070f37c5c0948d )
- [zig build explained - part 1](https://zig.news/xq/zig-build-explained-part-1-59lf )
- [zig build explained - part 2](https://zig.news/xq/zig-build-explained-part-2-1850 )
- [zig build explained - part 3](https://zig.news/xq/zig-build-explained-part-3-1ima )  

  
  
# 라이브러리
- [Awesome Zig](https://github.com/nrdmn/awesome-zig )  
- [(일어) Zig의 TensorFlow Lite 라이브러리를 만들었다](https://zenn.dev/mattn/articles/af64c6a3eefad0 )
- [(일어) Zig의 OpenCV 라이브러리 「zigcv」을 만들고 있다](https://zenn.dev/ryoppippi/articles/a368496c19a160 )
    
## 네트워크  
- [pike](https://github.com/lithdew/pike ). 비동기 I/O 라이브러리    
- [natsmq](https://github.com/nats-io/nats.zig )
