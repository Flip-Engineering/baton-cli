import Base
import ./process.bend as P

# Audit-era supervisor (222-line process-spawn.c from commit bdc234c3)
# driven on Linux. The child prints one/two on stdout, oops on stderr,
# sleeps 0.1s and exits 0. The read loop is one self-recursive def; the
# re-entry after each bind is a one-use closure.

def nl() -> String:
  SCon{Char.from_u32(10), SNil{}}

def child_command() -> String:
  "printf 'one" ++ nl() ++ "two" ++ nl() ++ "'; printf 'oops" ++ nl() ++
    "' 1>&2; sleep 0.1"

def next_line(handle: U32) -> IO(Maybe<String>):
  IO.try(Maybe<String>, P.ProcessChild.read_line(handle))

@unsafe
def drain(more: Maybe<String>, +handle: U32, +k: U32, +acc: String) -> IO(String):
  match more:
    case None{}:
      IO.pure(String, acc)
    case Some{line}:
      do IO<String>:
        IO.print("line " ++ U32.show(k) ++ ": " ++ line)
        IO.bind(Maybe<String>, String, next_line(handle),
          next => drain(next, handle, (k + 1 : U32), acc))

# Handle effects answer File & Result; open with a destructuring let
# (coordinator idiom, project.bend:158).
def stderr_text(pair: File & Result<&1, &1, U32 & String, String>) -> IO(String):
  (file, result) = pair
  match result:
    case Fail{(code, detail)}:
      IO.die(String, code, "stderr read failed")
    case Done{value}:
      do IO<String>:
        File.close(file)
        IO.pure(String, value)

def main() -> IO(Unit):
  do IO<Unit>:
    +h : U32 <- IO.try(U32, P.ProcessChild.spawn(
      P.argv(["/bin/sh", "-c", child_command()]),
      ".", "./child.stderr"))
    first : Maybe<String> <- next_line(h)
    lines : String <- drain(first, h, 0, "")
    IO.try(Unit, P.ProcessChild.close_stdin(h))
    status : String <- IO.try(String, P.ProcessChild.wait(h))
    IO.print("exit: " ++ status)
    f : File <- IO.try(File, File.open("./child.stderr", "r"))
    pair : File & Result<&1,&1,U32 & String,String> <- File.read(f, 4096)
    err : String <- stderr_text(pair)
    IO.print("child stderr file: " ++ err)
