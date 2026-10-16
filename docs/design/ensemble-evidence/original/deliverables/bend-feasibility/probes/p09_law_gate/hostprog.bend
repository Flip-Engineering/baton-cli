import Base
import ./tool.bend as T

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(T.Tool.twice(21)))
