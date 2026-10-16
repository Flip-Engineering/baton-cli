import Base

def inc(x: U32) -> U32:
  U32.add(x, 1)

# A stored tool function addressed twice: the affine table constraint.
def apply2(f: U32 -> U32, x: U32) -> U32:
  U32.add(f(x), f(x))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print_err(Nat.show(apply2(inc, 1)))
