import Base

# Non-IO defs are what the JS loader exports (main.ts: a .bend module
# exports every filled, non-base, non-IO def).
def double(n: U32) -> U32:
  (n + n : U32)

def greet(name: String) -> String:
  "hello, " ++ name

def decide(n: U32) -> Maybe<U32>:
  match n:
    case 0:
      None{}
    case _:
      Some{n}
