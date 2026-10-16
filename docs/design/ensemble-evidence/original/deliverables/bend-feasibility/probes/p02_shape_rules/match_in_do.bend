import Base

# Expect refusal: a match may not head a term inside a do block.
def main() -> IO(Unit):
  do IO<Unit>:
    match True{}:
      case True{}:
        IO.print("in-do match ran")
      case False{}:
        IO.print("unreachable")
