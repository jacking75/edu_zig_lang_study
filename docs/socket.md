# 소켓 프로그래밍
- [std.net](https://ziglang.org/documentation/master/std/#root;net )
    - [StreamServer](https://ziglang.org/documentation/master/std/#root;net.StreamServer ) 
    - [Stream](https://ziglang.org/documentation/master/std/#root;net.Stream )
       
- **디버그 버전으로 빌드된 경우 API에서 접속이 끊어졌을 때 등에서 스택트레이스를 출력한다. 이것은 릴리즈 버전으로 빌드하면 출력하지 않는다**
- linux에서는 `epoll`, windows에서는 `iocp`를 사용하고 있다/
    - windows는 소스 코드 중 `https://github.com/ziglang/zig/blob/master/lib/std/net.zig`의 `pub fn accept(self: *StreamServer) AcceptError!Connection`을 보면 비동기 사용 가능 여부에 따라서 다르게 동작한다.
	- 비동기를 사용하는 경우 `https://github.com/ziglang/zig/blob/master/lib/std/event/loop.zig`에 보면 각 OS별로 최적의 API를 호출하고 있고, windows에서는 IOCP 함수를 사용하고 있다.  
  
# 샘플 코드
- https://github.com/atsushi-kitazawa/zig-chat-server 
    - 채팅 서버가 완전 구현되지 않았고, 새로운 접속마다 스레드 생성
- https://github.com/theCow61/zatio  
    - async을 사용하고 있음  
  

  
# std.net 
  
## StreamServer
  
### Functions
```
fn accept(self: *StreamServer) AcceptError!Connection
If this function succeeds, the returned Connection is a caller-managed resource.

fn close(self: *StreamServer) void
Stop listening.

fn deinit(self: *StreamServer) void
Release all resources.

fn init(options: Options) StreamServer
After this call succeeds, resources have been acquired and must be released with deinit.

fn listen(self: *StreamServer, address: Address) !void  
```  
  
### Types
- Connection
    - stream: Stream,
    - address: Address,
- Options
    - kernel_backlog: u31,
    - reuse_address: bool,
     


## Stream
  
### Functions
```
fn close(self: Stream) void
fn read(self: Stream, buffer: []u8) ReadError!usize
fn reader(self: Stream) Reader
fn write(self: Stream, buffer: []const u8) WriteError!usize
TODO in evented I/O mode, this implementation incorrectly uses the event loop's file system thread instead of non-blocking.

fn writer(self: Stream) Writer
fn writev(self: Stream, iovecs: []const os.iovec_const) WriteError!usize
See https://github.

fn writevAll(self: Stream, iovecs: []os.iovec_const) WriteError!void
The iovecs parameter is mutable because this function needs to mutate the fields in order to handle partial writes from the underlying OS layer.
```  

### Fields
- handle: os.socket_t, 
  
### Values
- ReadError	   type	
- Reader	   anyopaque	
- WriteError   type	
- Writer	   anyopaque	




