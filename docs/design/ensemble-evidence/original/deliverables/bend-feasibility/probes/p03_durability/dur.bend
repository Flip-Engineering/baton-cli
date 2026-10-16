import Base

# The durability family Base lacks: fsync(file), fsync(dir), rename,
# unlink, stat-size, mkdir. One C half, modeled on effs/file_write.c.

def Host.sync(file: File) -> IO(File & Result<&1, &1, U32 & String, Unit>):
  import "./dur.c"
  import "./dur.js"

def Host.sync_dir(path: String) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./dur.c"
  import "./dur.js"

def Host.rename(old: String, new: String) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./dur.c"
  import "./dur.js"

def Host.unlink(path: String) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./dur.c"
  import "./dur.js"

def Host.stat_size(path: String) -> IO(Result<&1, &1, U32 & String, U32>):
  import "./dur.c"
  import "./dur.js"

def Host.mkdir(path: String) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./dur.c"
  import "./dur.js"

# Handle effects answer File & Result; open the pair with a
# destructuring let, as the coordinator does (project.bend:158).
def keep_file(-a: Type, pair: File & Result<&1, &1, U32 & String, a>) -> IO(File):
  (file, result) = pair
  match result:
    case Fail{(code, detail)}:
      IO.die(File, code, "durability step failed")
    case Done{value}:
      IO.pure(File, file)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.try(Unit, Host.mkdir("store"))
    f1 : File <- IO.try(File, File.open("store/log.tmp", "w"))
    IO.print("step: open done")
    p1 : File & Result<&1,&1,U32 & String,Unit> <- File.write(f1, "hello-log")
    f2 : File <- keep_file(Unit, p1)
    p2 : File & Result<&1,&1,U32 & String,Unit> <- Host.sync(f2)
    f3 : File <- keep_file(Unit, p2)
    IO.print("step: write+fsync done")
    File.close(f3)
    IO.try(Unit, Host.rename("store/log.tmp", "store/log.jsonl"))
    IO.print("step: rename done")
    IO.try(Unit, Host.sync_dir("store"))
    size : U32 <- IO.try(U32, Host.stat_size("store/log.jsonl"))
    IO.print("committed store/log.jsonl")
    IO.print("size " ++ U32.show(size))
    IO.try(Unit, Host.unlink("store/log.tmp"))
