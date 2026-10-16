import Base

# Expect refusal: the scrutinee is a let-bound computed value, not a
# parameter or pattern binder.
def main() -> Nat:
  n = 2n
  m = Nat.add(n, 1n)
  match m:
    case 0n:
      0n
    case 1n+p:
      p
