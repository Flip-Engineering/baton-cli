import Base

# Runtime native extension at the C boundary: dlopen a library from a
# declared path and call an exported entry. The checker sees only this
# declared signature; the extension carries no checker verdict. Base has
# no signed type, so the int32 entry is declared as U32.
def Host.ext_call(path: String, input: String, n: U32) ->
  IO(Result<&1, &1, U32 & String, U32>):
  import "./dl.c"
  import "./dl.js"

def main() -> IO(Unit):
  do IO<Unit>:
    answer : U32 <- IO.try(U32, Host.ext_call("./libext.so", "seed", 0))
    IO.print("extension answered " ++ U32.show(answer))
