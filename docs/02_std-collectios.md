# 표준 라이브러리의 컬렉션
[표준 라이브러리](https://ziglang.org/documentation/master/std/ )
   
 
# ArrayList
모든 요소가 메모리에서 연속된 영역에 배치되어 런타임에 동적으로 길이를 변경할 수 있는 컬렉션이다.  
C++의 `std::vector`, Rust의 `std::vec::Vec` 에 해당한다.  
첨자에 의한 랜덤 액세스, 말미에 요소 추가, 순방향·역방향 반복을 하고 싶은 유스 케이스에서 도움이 된다.  
  
샘플 코드    
```
test "ArrayList" {
    var list = ArrayList(usize).init(testing.allocator);
    defer list.deinit();

    {
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            try list.append(i);
        }
    }

    for (list.items) |v, i| {
        try testing.expectEqual(v, i);
    }

    try testing.expectEqual(@as(usize, 9), list.popOrNull().?);
    try testing.expectEqual(@as(usize, 9), list.items.len);
    try testing.expectEqual(@as(usize, 4), list.items[4]);
}
```  
  

# MultiArrayList
구조체를 요소로 하는 `ArrayList` 를 만들고 싶을 때는 `MultiArrayList` 이용을 검토해 보자.  
아래와 같은 구조체가 `S` 가 있을 때  
```
const S = struct {
    a: u32,
    b: []const u8,
};
```  

아래와 같이 `S`를 모아서 `ArrayList` 에 저장하는 방법이 있다.   
```
S 를 모아서 메모리 연속 영역에 저장
+-----------------------
| S_1 | S_2 | S_3 | ...
+-----------------------
```  
    
이것은에 `ArrayList(S)` 에 해당한다.  
반면에 아래와 같이 `S`의 각 필드를 별도의 목록으로 관리하는 방법이 있다. 여기가 `MultiArrayList(S)`에 해당한다.   
```
필드 a 를 메모리 연속 영역에 저장
+-----------------------
| a_1 | a_2 | a_3 | ...
+-----------------------

필드 b 를 연속 영역에 저장
+-----------------------
| b_1 | b_2 | b_3 | ...
+-----------------------
```  
  
이와 같이 필드마다 별도의 리스트를 사용해 값을 관리하는 것으로, 메모리의 절약이나 캐쉬 이용의 효율화를 도모하는 것이입니다 `MultiArrayList` 이다.
  
샘플 코드  
```
test "MultiArrayList" {
    const allocator = testing.allocator;

    const Foo = struct {
        field_one: u32,
        field_two: []const u8,
    };

    var list = MultiArrayList(Foo){};
    defer list.deinit(allocator);

    try testing.expectEqual(@as(usize, 0), list.items(.field_one).len);

    try list.append(allocator, .{
        .field_one = 1,
        .field_two = "foo",
    });
    try list.append(allocator, .{
        .field_one = 2,
        .field_two = "bar",
    });

    try testing.expectEqualSlices(u32, list.items(.field_one), &[_]u32{ 1, 2 });

    try testing.expectEqual(@as(usize, 2), list.items(.field_two).len);
    try testing.expectEqualStrings("foo", list.items(.field_two)[0]);
    try testing.expectEqualStrings("bar", list.items(.field_two)[1]);
}
```  
  
   
# SegmentedList
ArrayList 와 마찬가지로 빠른 랜덤 액세스와 끝에 추가 및 삭제할 수 있는 데이터 구조이다.  
차이는 ArrayList는 확보한 메모리 영역이 부족한 경우는 다른 큰 영역을 확보하고, 모든 요소를 ​​거기에 복사하는 것에 대해, `SegmentedList`는 추가 영역을 확보한 후에도 그때까지 저장 되고 있던 데이터는 원래의 위치에 남는다는 것이다.  
즉, ArrayList는 모든 요소가 순서대로 메모리 상에 늘어서 있는 것이 보증되고 있지만, `SegmentedList`는 어느 정도 크기 요소의 「덩어리」 마다, 다른 메모리 영역에 배치되게 된다.  
`SegmentedList`의 장점은 요소를 가리키는 포인터가 생존하는 기간이 `SegmentedList` 자체의 라이프 타임과 일치한다는 것이다. 방금 쓴 것처럼 ArrayList에서는 확보한 메모리 영역이 부족해졌을 때에 다른 영역으로 복사가 행해지기 때문에, 원래의 영역을 가리키는 포인터는 이 시점에서 부정이 된다.  한편, `SegmentedList`는 메모리 영역이 부족해졌을 경우에도 원래 요소의 복사는 행해지지 않기 때문에, 포인터가 부정하게 되는 일은 없다.  
  
샘플 코드  
```  
test "SegmentedList" {
    const L = SegmentedList(u32, 2);
    var list = L{};
    defer list.deinit(testing.allocator);

    try list.append(testing.allocator, 1);
    try list.append(testing.allocator, 2);
    try list.append(testing.allocator, 3);
    try testing.expectEqual(@as(usize, 3), list.count());

    {
        var it = list.iterator(0);
        var s: u32 = 0;
        while (it.next()) |item| {
            s += item.*;
        }
        try testing.expectEqual(@as(u32, 6), s);
    }

    {
        var it = list.constIterator(0);
        var s: u32 = 0;
        while (it.next()) |item| {
            s += item.*;
        }
        try testing.expectEqual(@as(u32, 6), s);
    }
}
```  
  
# SinglyLinkedList
단방향 연결 리스트이다. C++의 `std::forward_list` 에 해당한다.
요소의 메모리, 수명 관리는 호출자 책임이다.  

샘플 코드  
```
test "SinglyLinkedList" {
    const L = SinglyLinkedList(u32);
    var list = L{};

    try testing.expectEqual(@as(usize, 0), list.len());

    var one = L.Node{ .data = 1 };
    var two = L.Node{ .data = 2 };

    list.prepend(&two);
    list.prepend(&one);

    {
        var it = list.first;
        var val: u32 = 1;
        while (it) |node| : (it = node.next) {
            try testing.expectEqual(val, node.data);
            val += 1;
        }
    }

    try testing.expectEqual(@as(usize, 2), list.len());
    try testing.expectEqual(@as(u32, 1), list.first.?.data);
    try testing.expectEqual(@as(u32, 1), list.popFirst().?.data);
}
```
  

# TailQueue
양방향 연결 리스트이다. C++의 `std::list`, Rust의 `std::collections::LinkedList` 에 해당한다.  
요소의 메모리, 수명 관리는 호출자 책임이다.  
  
샘플 코드  
```
test "TailQueue" {
    const L = TailQueue(u32);
    var list = L{};

    try testing.expectEqual(@as(usize, 0), list.len);

    var one = L.Node{ .data = 1 };
    var two = L.Node{ .data = 2 };
    var three = L.Node{ .data = 3 };

    list.append(&two);
    list.append(&three);
    list.prepend(&one);
    try testing.expectEqual(@as(usize, 3), list.len);

    // 순방향 이터레이터
    {
        var it = list.first;
        var val: u32 = 1;
        while (it) |node| : (it = node.next) {
            try testing.expectEqual(val, node.data);
            val += 1;
        }
    }

    // 역방향 이터레이터
    {
        var it = list.last;
        var val: u32 = 3;
        while (it) |node| : (it = node.prev) {
            try testing.expectEqual(val, node.data);
            val -= 1;
        }
    }
}
```  
  
   

# HashMap
소위 연상 배열이다. C++의 `std::unordered_map`, Rust의 `std::collections::HashMap`에 해당한다.  
기본적으로는 `AutoHashMapAuto`라는 prefix가 붙은 것을 사용할 것으로 생각한다. 여기는 해시 함수나 key의 동치 판정을 실시하는 함수를 잘 생성해 준다.  
반대로, 해시 함수나 key의 동치 판정을 커스터마이즈 하고 싶은 경우는 HashMap을 사용한다.  
  
샘플 코드  
```
test "AutoHashMap" {
    var map = AutoHashMap(u32, u8).init(testing.allocator);
    defer map.deinit();

    try map.put(0, 'a');
    try map.put(1, 'b');

    try testing.expectEqual(@as(u8, 'a'), map.get(0).?);
    try testing.expectEqual(@as(u8, 'b'), map.get(1).?);
    try testing.expect(map.get(2) == null);

    const prev = try map.fetchPut(0, 'x');
    try testing.expectEqual(@as(u32, 0), prev.?.key);
    try testing.expectEqual(@as(u8, 'a'), prev.?.value);
}
```   
  
  
  
# ArrayHashMap
삽입 순서가 보관 유지되는 `HashMap` 이다. 삽입 순서를 유지한 채로 반복하고 싶은 경우나, 반복시의 퍼포먼스를 중시하는 경우는 `HashMap` 보다 `ArrayHashMap`를 이용하는 것이 좋다.  
`HashMap` 과 마찬가지로 `AutoArrayHashMap` 도 준비되어 있고, 기본적인 유스 케이스에서는 이쪽으로 부족할까 생각한다.  
  
샘플 코드  
```
test "AutoArrayHashMap" {
    var map = AutoArrayHashMap(u32, u8).init(testing.allocator);
    defer map.deinit();

    try map.put(0, 'a');
    try map.put(1, 'b');

    var it = map.iterator();
    try testing.expectEqual(@as(u8, 'a'), it.next().?.value_ptr.*);
    try testing.expectEqual(@as(u8, 'b'), it.next().?.value_ptr.*);
    try testing.expect(it.next() == null);
}
```  
  
   

# StringHashMap, StringArrayHashMap
key가 문자열 `([]const u8)`의 경우는 이것을 이용한다. 덧붙여 key가 되는 문자열의 메모리를 관리하는 것은 호출측 책임이다. 관리하는 데이터의 라이프타임을 데이터 구조와 동일하게 하고 싶은 경우는 다음에 소개하는 BufMap 이용을 검토하는 것이 좋다.  
사용법은 `HashMap`, `ArrayHashMap`과 같다.  
  


# BufMap, BufSet
BufMap는 key, 밸류가 함께 `[]const u8`인 `HashMap` 이다.
그러나 key value를 추가 할 때 문자열을 복사하여 라이프 타임을 BufMap 내부적으로 관리하는 차이점이 있다  
예를 들어, `BufMap`를 사용하고 있는 경우, 값의 덧쓰기가 발생할 때, 덧쓰기 되는 측의 메모리 영역을 자동으로 적절히 해방해 준다. 또, deinit()메소드에 의해 저장 되고 있는 모든 key, value 메모리 영역이 해방된다.  
  
`BufSet`는 key가 `[]const u8`, value가 `void`인 것 같은 `HashMap`으로, 문자열 집합을 표현하고 싶을 때에 이용할 수 있다.  
메모리 관리에 대해서는 `BufMap` 과 마찬가지이다.  
  
샘플 코드  
```
test "BufMap" {
    var bufmap = BufMap.init(testing.allocator);
    defer bufmap.deinit();

    try bufmap.put("x", "1");
    try testing.expect(mem.eql(u8, bufmap.get("x").?, "1"));
    try testing.expect(1 == bufmap.count());

    try bufmap.put("x", "2");
    try testing.expect(mem.eql(u8, bufmap.get("x").?, "2"));
    try testing.expect(1 == bufmap.count());

    bufmap.remove("x");
    try testing.expect(0 == bufmap.count());
}

test "BufSet" {
    var bufset = BufSet.init(testing.allocator);
    defer bufset.deinit();

    try bufset.insert("x");
    try testing.expect(bufset.count() == 1);
    try testing.expect(bufset.contains("x"));
    bufset.remove("x");
    try testing.expect(bufset.count() == 0);
}
```  
  


# ComptimeStringMap
key가 `[]const u8`로 컴파일시에 모든 요소를 확정하는 `Map` 같은 것을 원하는 경우에는 `ComptimeStringMap` 이다.  
컴파일시에 전 계산을 실시하는 것으로 실행시의 lookup 처리의 최적화를 실시한다. 구체적으로는 lookup 시에 key가 되는 문자열의 길이가 일치하는 부분만을 탐색하게 된다. 예를 들어 `map.get("foo")` 이렇게 하면 key 길이가 3인 것만 탐색한다.  
  
샘플 코드    
```
test "ComptimeStringMap" {
    const KV = struct {
        @"0": []const u8,
        @"1": u32,
    };
    const map = ComptimeStringMap(u32, [_]KV{
        .{ .@"0" = "foo", .@"1" = 42 },
        .{ .@"0" = "barbaz", .@"1" = 99 },
    });

    try testing.expectEqual(@as(u32, 42), map.get("foo").?);
    try testing.expectEqual(@as(u32, 99), map.get("barbaz").?);
    try testing.expect(!map.has("hello"));
    try testing.expect(map.get("hello") == null);
}
```  
  


# BoundedArray
정확한 사이즈는 런타임에 때까지 불명하지만, 최대 사이즈는 컴파일시에 알고 있다 라고 하는 배열을 원할 때 편리한 데이터 구조이다.  
컴파일시에 최대 사이즈분의 메모리 영역을 확보하기 때문에, 할당자가 불필요하다.  
  
아이디어는 Rust의 `smallvec` 에 가깝다. 다만 `smallvec`는 사전에 확보한 배열 사이즈를 넘으면 힙 영역에 이동해 주지만, `BoundedArray` 는 지정한 최대 사이즈를 넘는 요소수를 지정하면 Overflow 에러가 된다.
  
샘플 코드    
```
test "BoundedArray" {
    const BoundedArrayMax4 = BoundedArray(u8, 4);

    try testing.expectError(error.Overflow, BoundedArrayMax4.init(8));

    var a = try BoundedArrayMax4.init(2);

    try testing.expectEqual(a.capacity(), 4);
    try testing.expectEqual(a.len, 2);
    try testing.expectEqual(a.slice().len, 2);
    try testing.expectEqual(a.constSlice().len, 2);

    try a.resize(4);
    try testing.expectEqual(a.len, 4);

    a.set(0, 42);
    try testing.expectEqual(a.get(0), 42);
}
``` 
  


# StaticBitSet, DynamicBitSet
비트 집합을 나타내는 데이터 구조이다. C++의 `std::bitset` 에 해당한다.  
컴파일시에 비트 사이즈를 결정하는 경우는 `StaticBitSet`를, 런타임에 결정하는 경우 `DynamicBitSet`를 이용한다.  
비트 크기는 최적의 데이터 구조를 선택한다. 비트 사이즈가 작은 경우는 정수를 이용하고, 큰 경우는 배열을 사용한다.  

샘플 코드  
```
test "StaticBitSet" {
    var bitset = StaticBitSet(4).initEmpty();

    try testing.expectEqual(@as(usize, 0), bitset.count());

    bitset.setValue(1, true);
    try testing.expectEqual(@as(usize, 1), bitset.count());
    try testing.expect(!bitset.isSet(0));
    try testing.expect(bitset.isSet(1));

    bitset.setRangeValue(.{ .start = 2, .end = 4 }, true);
    try testing.expectEqual(@as(usize, 3), bitset.count());
}

test "DynamicBitSet" {
    const size = @intCast(usize, time.timestamp()) % 60;

    var bitset = try DynamicBitSet.initEmpty(std.testing.allocator, size);
    defer bitset.deinit();

    try testing.expectEqual(@as(usize, 0), bitset.count());

    bitset.toggleAll();
    try testing.expectEqual(size, bitset.count());
}  
```  
  
  

# EnumArray, EnumMap, EnumSet
Enum을 key(인덱스)로 하는 `Array`, `Map`, `Set` 을 원하는 경우에 편리한 데이터 구조이다.  
  
샘플 코드  
```
test "EnumArray" {
    const A = EnumArray(enum {
        foo,
        bar,
    }, u32);
    try testing.expectEqual(@as(usize, 2), A.len);

    var a = A.initFill(42);
    try testing.expectEqual(@as(u32, 42), a.get(.foo));
    try testing.expectEqual(@as(u32, 42), a.get(.bar));
}

test "EnumMap" {
    const A = EnumMap(enum {
        foo,
        bar,
    }, u32);

    try testing.expectEqual(@as(usize, 2), A.len);

    var a = A{};
    try testing.expectEqual(@as(usize, 0), a.count());
    a.put(.foo, 42);
    try testing.expectEqual(@as(usize, 1), a.count());
    try testing.expect(a.contains(.foo));
    try testing.expect(!a.contains(.bar));
}

test "EnumSet" {
    const A = EnumSet(enum {
        foo,
        bar,
    });

    try testing.expectEqual(@as(usize, 2), A.len);

    var a = A{};
    try testing.expectEqual(@as(usize, 0), a.count());
    a.insert(.foo);
    try testing.expectEqual(@as(usize, 1), a.count());
    try testing.expect(a.contains(.foo));
    try testing.expect(!a.contains(.bar));

    a.remove(.foo);
    try testing.expectEqual(@as(usize, 0), a.count());
}
```  
  


# PriorityQueue, PriorityDequeue
우선순위가 있는 큐이다. C++의 `std::priority_queue` Rust의 `std::collections::BinaryHeap` 에 해당한다.  
최대치, 혹은 최소치만을 고속으로 꺼내고 싶은 경우는 `PriorityQueue`를 사용하고, 최대치와 최소치의 양쪽 모두를 고속으로 꺼내고 싶은 경우는 `PriorityDequeue`를 이용한다.  
  
샘플 코드  
```
test "PriorityQueue" {
    {
        const MinHeap = PriorityQueue(u32, void, struct {
            fn lessThan(context: void, a: u32, b: u32) math.Order {
                _ = context;
                return math.order(a, b);
            }
        }.lessThan);
        var queue = MinHeap.init(testing.allocator, {});
        defer queue.deinit();

        try queue.add(12);
        try queue.add(7);
        try queue.add(23);
        try testing.expectEqual(@as(usize, 3), queue.len);
        try testing.expectEqual(@as(u32, 7), queue.remove());
        try testing.expectEqual(@as(u32, 12), queue.remove());
        try testing.expectEqual(@as(u32, 23), queue.remove());
    }

    {
        const MaxHeap = PriorityQueue(u32, void, struct {
            fn greaterThan(context: void, a: u32, b: u32) math.Order {
                _ = context;
                return math.order(a, b).invert();
            }
        }.greaterThan);
        var queue = MaxHeap.init(testing.allocator, {});
        defer queue.deinit();

        try queue.add(12);
        try queue.add(7);
        try queue.add(23);
        try testing.expectEqual(@as(usize, 3), queue.len);
        try testing.expectEqual(@as(u32, 23), queue.remove());
        try testing.expectEqual(@as(u32, 12), queue.remove());
        try testing.expectEqual(@as(u32, 7), queue.remove());
    }
}

test "PriorityDequeue" {
    const PQ = PriorityDequeue(u32, void, struct {
        fn lessThan(context: void, a: u32, b: u32) math.Order {
            _ = context;
            return math.order(a, b);
        }
    }.lessThan);
    var queue = PQ.init(testing.allocator, {});
    defer queue.deinit();

    try queue.add(12);
    try queue.add(7);
    try queue.add(23);
    try testing.expectEqual(@as(usize, 3), queue.len);
    try testing.expectEqual(@as(u32, 7), queue.removeMin());
    try testing.expectEqual(@as(u32, 23), queue.removeMax());
    try testing.expectEqual(@as(u32, 12), queue.removeMin());
}
```
  
  

# Treap
평형 이분 탐색 트리이다.   
레드-블랙 트리 등 다른 평형 이분 탐색 트리가 아닌 `Treap` 이 채용되고 있는 것은, [구현의 단순함이 가장 큰 이유라고 한다](https://github.com/ziglang/zig/pull/11444 ).  
  
샘플 코드  
```
test "Treap" {
    const MyTreap = Treap(u32, math.order);
    const Node = MyTreap.Node;
    var treap = MyTreap{};
    var nodes: [10]Node = undefined;

    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        var entry = treap.getEntryFor(i);
        try testing.expectEqual(i, entry.key);
        try testing.expect(entry.node == null);

        entry.set(&nodes[i]);
    }

    try testing.expectEqual(@as(u32, 9), treap.getMax().?.key);
    try testing.expectEqual(@as(u32, 0), treap.getMin().?.key);
}
```
  
    
https://zenn.dev/magurotuna/articles/zig-std-collections