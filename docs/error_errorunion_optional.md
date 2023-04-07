출처: https://qiita.com/bellbind/items/f2338fa1d82a2a79f290  
  
# 에러 세트 타입과 에러 유니온 타입
zig의 error 구문에서 정의하는 에러 세트 타입은, struct와 enum 같은 커스텀 타입의 하나로, enum와 유사한 열거형이이다. 예: `const MyError = error {Fail, Dead,};`  
  
enum과 다른 부분은, 에러 세트 타입에서는, 아래와 같이, 그 요소인 에러를 집합적으로 취급하는 점이다.  
- 모든 사용자 정의 오류 세트 타입을 수신 하는 `anyerror` 타입의 존재
- 2개의 에러 세트 타입의 합집합 에러 세트 타입을 작성할 수 있다. `const ErrorsC = ErrosA || ErrorsB;`  
- 에러 세트 타입의 에러 이름은 에러 세트 타입이 다르더라도 같은 이름을 갖는 것과 동일한 값으로 처리된다(예:  `MyError.Dead`는 `const e: MyError = error.Dead;`도 초기화 할 수 있음).
- 에러 유니온 타입(`!`이 붙은 타입)과 에러 유니온 전용 구문(`catch` 연산자, `try` 연산자)가 존재한다
  
반환 값 타입에서 `!u8` 이나 변수 타입에서의 `MyError!u8` 같은 `!` 붙은 타입은 zig의 **에러 유니온 타입** 이다.  
에러 유니온 타입은, 값 타입과 error 타입 양쪽 모두를 받을 수 있는 변수나 반환값의 타입이다.  
이 에러 유니온 타입을 반환값의 타입으로 하는 것으로, zig에서는 **에러도 return 시키는** 값이 된다.  
반환값 타입 `!u8`은 왼쪽의 에러 세트 타입이 함수 구현 코드로부터 추론되는 것으로, 실제로는, `MyError!u8` 등의 에러 유니온 타입이 된다.  
  
에러 유니온 타입에서 값 타입의 표현식으로 만들려면 zig는 `catch` 이항 연산자와 `try` 단항 연산자를 사용할 수 있다.  
- catch 이항 연산자: 오류 시 폴백 값을 전달할 수 있다. 예: `const v: u8 = errorOrInt() catch |err| 10;`  
- try 단항 연산자: 에러일 때는 그 에러를 return 하는 식이다. 예: `const v: u8 = try errorOrInt();`  
  
`catch` 연산자의 캡처 부분 `|err|`은 오류 값을 사용하지 않으면 생략할 수 있다.    
`try` 연산자를 사용하는 함수의 반환 값은 오류 유니온 타입이어야 한다.    
   
또, `if`식이나 `switch`식의 조건식으로 하는 것도, 에러 유니온 타입으로부터 에러 시를 `else`으로서 배분하는 것이 가능하다.  
- `if` 예:  `const v: u8 = if (errorOrInt()) |n| n else |err| 0;`  
- `switch`예:  `const v: u8 = switch (errorOrInt()) { n => n, else => 0, };`  
  
   
# 환경 변수 및 옵셔날 타입
환경 변수는 표준 라이브러리 `os.getEnvPosix()`로 얻을 수 있다. 이 함수의 반환 값은 `?[]const u8` 이다.  
  
이 `?`가 선두에 붙은 타입은, zig의 **옵셔널 타입** 이다. 옵셔널 타입은 zig의 `null` 값이나 값 이라는 타입이다. (이 때문에, 포인터 타입은 옵셔널 타입이 아니면 null로 할 수 없다)  
  
에러 유니온 타입과 마찬가지로, if 표현식이나 switch 표현식에서 null일 때는 `else`로 폴백 값을 제공하여 값 타입을 만들 수 있다.  
또, 에러 유니온에서의 catch 이항 연산자와 같은 위치 지정으로, 옵셔널 타입용으로 `orelse` 이항 연산자가 갖추어져 있다.  
- 예:  `const v: u8 = nullOrInt() orelse 0;`  
  
`const v: u8 = nullOrInt().?` 와 `.?`를 붙이는 것도, (`error` 타입에서의 try 단항 연산자와 같이) 강제적으로 값 타입으로 할 수 있다.  
그러나 try와 달리 에러나 null이 return 되지는 않아서 zig-0.4.0에서는 트랩 불가능한 강제 종료가 되는 것 같다.  
  
  
