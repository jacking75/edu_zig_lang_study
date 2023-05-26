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
  
SinglyLinkedList
단방향 연결 목록입니다. C++에 std::forward_list해당합니다.
요소의 메모리, 수명 관리는 호출자의 책임입니다.

샘플 코드
TailQueue
양방향 연결 목록입니다. C++의 std::listRust에 std::collections::LinkedList해당합니다.
요소의 메모리, 수명 관리는 호출자의 책임입니다.

샘플 코드
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

    // 順方向イテレート
    {
        var it = list.first;
        var val: u32 = 1;
        while (it) |node| : (it = node.next) {
            try testing.expectEqual(val, node.data);
            val += 1;
        }
    }

    // 逆方向イテレート
    {
        var it = list.last;
        var val: u32 = 3;
        while (it) |node| : (it = node.prev) {
            try testing.expectEqual(val, node.data);
            val -= 1;
        }
    }
}

HashMap
소위 연상 배열입니다. C++ std::unordered_map, Rust에 std::collections::HashMap해당합니다.
기본적으로는 AutoHashMapAuto라는 prefix가 붙은 것을 사용하게 된다고 생각합니다. 여기는 해시 함수나 키의 동치 판정을 실시하는 함수를 잘 생성해 줍니다.
반대로, 해시 함수나 키의 동치 판정을 커스터마이즈 하고 싶은 경우는, HashMap를 사용합니다.

샘플 코드
ArrayHashMap
삽입 순서가 보관 유지되는 HashMap입니다. 삽입 순서를 유지한 채로 반복하고 싶은 경우나, 반복시의 퍼포먼스를 중시하는 경우는보다를 이용하는 것이 좋은 것 HashMap같습니다 ArrayHashMap.
HashMap 과 마찬가지로,도 AutoArrayHashMap준비되어 있고, 기본적인 유스 케이스에서는 이쪽으로 부족할까 생각합니다.

샘플 코드
StringHashMap,StringArrayHashMap
키가 캐릭터 라인 ( []const u8)의 경우는 이것을 이용합니다. 덧붙여 키가 되는 캐릭터 라인의 메모리를 관리하는 것은 호출측의 책임입니다. 관리하는 데이터의 라이프타임을 데이터 구조와 동일하게 하고 싶은 경우는, 다음에 소개하는 것의 BufMap이용을 검토해 주세요.
사용법은 HashMap, ArrayHashMap와 같기 때문에 할애합니다.

BufMap,BufSet
BufMap는, 키, 밸류가 함께 []const u8인 것 같은 HashMap 입니다.
그러나 키 가치를 추가 할 때 문자열을 복사하여 라이프 타임을 내부적으로 BufMap관리하는 차이점이 있습니다 [3] .
예를 들어, BufMap를 사용하고 있는 경우, 값의 덧쓰기가 발생할 때, 덧쓰기되는 측의 메모리 영역을 자동으로 적절히 해방해 줍니다. 또, deinit()메소드에 의해, 격납되고 있는 모든 키, 밸류의 메모리 영역이 해방됩니다.

BufSet는 키가 []const u8, 값이 void인 것 같은 HashMap 로, 캐릭터 라인의 집합을 표현하고 싶을 때에 이용할 수 있습니다.
메모리 관리에 대해서는 BufMap마찬가지입니다.

샘플 코드
ComptimeStringMap
키가 []const u8로, 컴파일시에 모든 요소가 확정하는 것 같은 Map 를 원하면,의 차례입니다 ComptimeStringMap.
컴파일시에 전계산을 실시하는 것으로, 실행시의 lookup 처리의 최적화를 실시합니다. 구체적으로는, lookup시에, 키가 되는 캐릭터 라인의 길이가 일치하는 부분만을 탐색하게 됩니다. 예를 들어, map.get("foo")이렇게 하면 키 길이가 3인 것만 탐색합니다.

샘플 코드
BoundedArray
정확한 사이즈는 런타임에 될 때까지 불명하지만, 최대 사이즈는 컴파일시에 알고 있다, 라고 하는 배열을 원할 때 편리한 데이터 구조입니다.
컴파일시에 최대 사이즈분의 메모리 영역을 확보하기 위해, 할당자가 불필요합니다.

아이디어는 Rust에 smallvec가깝습니다. 다만 smallvec, 사전에 확보한 배열 사이즈를 넘으면 힙 영역에 이동해 줍니다만, 는, 지정한 최대 사이즈를 넘는 요소수를 지정하면, 에러가 BoundedArray됩니다 Overflow.

샘플 코드
StaticBitSet,DynamicBitSet
비트 집합을 나타내는 데이터 구조입니다. C++에 std::bitset해당합니다.
컴파일시에 비트 사이즈가 결정하는 경우는 를 StaticBitSet, 런타임에 결정하는 경우 DynamicBitSet는를 이용합니다.
비트 크기는 최적의 데이터 구조를 선택합니다. 비트 사이즈가 작은 경우는 정수를 이용해, 큰 경우는 배열이 사용됩니다.

샘플 코드
EnumArray,, EnumMap_EnumSet
Enum 를 키 (인덱스) 로 하는 Array, Map, Set 를 원하는 경우에 편리한 데이터 구조입니다.

샘플 코드
PriorityQueue,PriorityDequeue
우선순위가 있는 큐입니다. C++ std::priority_queue또는 Rust에 std::collections::BinaryHeap해당합니다.

최대치, 혹은 최소치만을 고속으로 꺼내고 싶은 경우는 를 PriorityQueue사용해, 최대치와 최소치의 양쪽 모두를 고속으로 꺼내고 싶은 경우는를 이용 PriorityDequeue합니다.

샘플 코드
Treap
평형 이분 탐색 나무입니다. Treap - Wikipedia
적흑목 등 다른 평형 이분 탐색 트리가 아니라가 Treap채용되고 있는 것은, 구현의 단순함이라고 하는 것이 가장 큰 이유라는 것입니다.

샘플 코드
덤
C++ 의 std::dequeRust 에 std::collections::VecDeque상당하는 데이터 구조는 제공되고 있지 않다는 것을 깨닫고, 흠뻑 자작해 보았습니다.
ArrayList과 같이 랜덤 액세스와 말미에의 추가·삭제를 고속으로 실시할 수 있는 것에 더해, 선두에의 추가·삭제도 효율적으로 실시할 수 있는 데이터 구조입니다.

  

  
https://zenn.dev/magurotuna/articles/zig-std-collections