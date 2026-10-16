import Base

# Expect refusal: f is a closure parameter used twice ("consumed more
# than once"); only top-level defs may be called freely.
def apply_twice(f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def main() -> U32:
  add1 = (x => (x + 1 : U32))
  apply_twice(add1, 40)
