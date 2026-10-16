import Base
type Lease is Data:
  Mk{cap: U32}

def Lease.cap(self: Lease) -> U32:
  match self:
    case Mk{cap}: cap

# The module's intended minting function. Nothing in the type or the checker
# makes it the only producer of Lease.
def mint(u: U32) -> Lease:
  Mk{u}
