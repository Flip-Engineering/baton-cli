import Base

# A template that instantiates itself: expected to hit the v2.0.25
# instantiation-depth guard (bend.ts def_check z parameter, 64 levels),
# which the a4952426-era checker the prior audit reviewed did not have.
@unsafe
def spin(~f: U32 -> U32, x: U32) -> U32:
  spin(~f, f(x))

def main() -> U32:
  spin(~(x => (x + 1 : U32)), 0)
