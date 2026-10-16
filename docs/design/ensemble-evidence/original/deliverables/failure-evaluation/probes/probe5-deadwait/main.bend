import Base

def report(got: Maybe<&1, String>) -> IO(Unit):
  match got:
    case Some{v}: IO.print_err(v)
    case None{}: IO.print_err("closed")

def main() -> IO(Unit):
  do IO<Unit>:
    done : Chan(String) <- IO.fork(String,
      do IO<String>:
        IO.sleep(60000)
        IO.pure(String, "late"))
    value : Maybe<&1, String> <- Chan.recv(String, done)
    report(value)
