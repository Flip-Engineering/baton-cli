import Base

# The authority claim a checker cannot carry: a user-declared record's
# constructors export with the module, so any importer forges a value
# directly. Naming a type Capability establishes no provenance.
type Capability is Data:
  Mk{level: U32}

def release(cap: Capability) -> U32:
  match cap:
    case Mk{level}:
      level

def main() -> IO(Unit):
  do IO<Unit>:
    forged : Capability = Mk{999}
    IO.print("forged capability released level " ++ U32.show(release(forged)))
