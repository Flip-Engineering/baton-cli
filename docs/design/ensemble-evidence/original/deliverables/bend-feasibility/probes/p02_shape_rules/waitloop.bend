import Base

# The seat-loop shape: one self-recursive def carrying a state sum type,
# @unsafe where an arm keeps going without shrinking an argument, a do
# block inside a match arm (legal) rather than a match inside a do (not).
type Step is Data:
  Count{left: Nat}
  Stop{}

@unsafe
def loop(state: Step) -> IO(Unit):
  match state:
    case Stop{}:
      IO.print("loop: done")
    case Count{0n}:
      loop(Stop{})
    case Count{1n+p}:
      do IO<Unit>:
        IO.print("loop: tick")
        loop(Count{p})

def main() -> IO(Unit):
  loop(Count{3n})
