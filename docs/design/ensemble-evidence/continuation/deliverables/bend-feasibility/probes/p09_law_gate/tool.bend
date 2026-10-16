import Base

def Tool.twice(+n: U32) -> U32:
  (n + n : U32)

def Tool.four(n: U32) -> U32:
  (n * 4 : U32)

# LAW: twice composed with itself is four; left open on purpose.
law twice_four:
  for n: U32
  {Tool.twice(Tool.twice(n)) == Tool.four(n) : U32}
