import Base

def main() -> IO(Unit):
  do IO<Unit>:
    match Bool.True{}:
      case True{}: IO.pure(Unit, Unit{})
