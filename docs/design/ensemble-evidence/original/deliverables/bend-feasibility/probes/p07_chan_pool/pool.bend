import Base

# Bounded completion pool: three workers sleeping 30/20/10 ms send their
# id to one shared completion channel; the receiver joins in completion
# order. One self-recursive def carries the loop (mutual recursion is
# refused); the re-entry is a one-use closure, the run_from idiom of the
# coordinator (receive.bend:814). Chan is a Base handle law applied
# Chan(U32), Data-kinded, shared through + binders.

def worker(+id: U32, +done: Chan(U32)) -> IO(Unit):
  do IO<Unit>:
    IO.sleep(id)
    sent : Bool <- Chan.send(U32, done, id)
    IO.print("started " ++ U32.show(id) ++ " sent=" ++ Bool.show(sent))

@unsafe
def drain_pool(got: Maybe<&1, U32>, +done: Chan(U32), left: Nat) -> IO(Unit):
  match got:
    case None{}:
      IO.print("pool: channel closed early")
    case Some{value}:
      match left:
        case 0n:
          IO.print("pool: counter underflow")
        case 1n:
          do IO<Unit>:
            IO.print("done " ++ U32.show(value))
            IO.print("pool drained")
        case 1n+rest:
          do IO<Unit>:
            IO.print("done " ++ U32.show(value))
            IO.bind(Maybe<&1, U32>, Unit, Chan.recv(U32, done),
              next => drain_pool(next, done, rest))

def start(+done: Chan(U32)) -> IO(Unit):
  do IO<Unit>:
    a : Chan(Unit) <- IO.fork(Unit, worker(30, done))
    b : Chan(Unit) <- IO.fork(Unit, worker(20, done))
    c : Chan(Unit) <- IO.fork(Unit, worker(10, done))
    got : Maybe<&1, U32> <- Chan.recv(U32, done)
    drain_pool(got, done, 3n)

def main() -> IO(Unit):
  do IO<Unit>:
    done : Chan(U32) <- Chan.new(U32, 4)
    runner : Chan(Unit) <- IO.fork(Unit, start(done))
    IO.join(Unit, runner)
