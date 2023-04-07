const std = @import("std");
const log = std.log;
const net = std.net;


pub fn main() anyerror!void {
    log.info("init server.", .{});
    try doMain();
    log.info("start server 127.0.0.1:8888...", .{});
}

pub fn doMain() anyerror!void {
    // init server
    const address = net.Address.initIp4([4]u8{ 127, 0, 0, 1 }, 11021);
    var server = net.StreamServer.init(.{ .reuse_address = true });
    try server.listen(address);


    while (true) {
        const connection = try server.accept();
        log.info("accept client = {}", .{connection.address});

        var thread = try std.Thread.spawn(.{}, echo, .{@as(net.Stream, connection.stream)});
        _ = thread;

    }
    
}

fn echo(stream: net.Stream) void {
    while(true) {
        var buf: [2000]u8 = undefined;

        //var len = if (stream.read(&buf)) |n| n else |err| { 
        //var len = stream.read(&buf) catch {     
        var len = stream.read(&buf) catch |err| {         
            std.log.err("Fail read: {}", .{err}); 
            stream.close();
            break; 
        };
        std.log.info("read: {}", .{len});

        if (len == 0) {
            stream.close();
            break; 
        }
        

        _ = stream.write(buf[0..len]) catch |err| {
            std.log.err("Fail write: {}", .{err}); 
            stream.close();
        };
    }
}