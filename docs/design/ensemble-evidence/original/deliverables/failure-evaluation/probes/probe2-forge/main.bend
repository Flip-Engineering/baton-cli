import ./lease.bend as L

def main() -> IO(Unit):
  do IO<Unit>:
    forged : L.Lease = L.Mk{999}
    IO.print_err(Nat.show(U32.to_nat(L.Lease.cap(forged))))
