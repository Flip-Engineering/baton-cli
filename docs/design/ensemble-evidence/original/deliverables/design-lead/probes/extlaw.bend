import Base

law twice_two_is_four:
  for n: U32
  {U32.mul(U32.mul(n, 2), 2) == U32.mul(n, 4) : U32}
