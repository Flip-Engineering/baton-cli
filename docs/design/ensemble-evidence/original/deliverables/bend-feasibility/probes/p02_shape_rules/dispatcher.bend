import Base

# The declarative-tool dispatcher shape: one def per tool body, one
# dispatcher def matching a Data parameter with literal constructors,
# called any number of times.
type ToolCall is Data:
  Read{path: String}
  Bash{code: String}

def dispatch(tool: ToolCall) -> String:
  match tool:
    case Read{path}:
      "read: " ++ path
    case Bash{code}:
      "bash: " ++ code

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(dispatch(Read{"/tmp/x"}))
    IO.print(dispatch(Bash{"echo hi"}))
    IO.print(dispatch(Read{"/tmp/y"}))
