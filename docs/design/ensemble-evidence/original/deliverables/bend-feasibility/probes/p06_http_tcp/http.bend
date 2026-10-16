import Base

# HTTP/1.1 request framing and incremental chunk delivery over Base TCP
# only. TCP.poll hands the socket back beside its result, so the loop is
# one self-recursive def threading the handle. Pairs open by destructuring
# let (coordinator idiom, project.bend:158).

def crlf() -> String:
  SCon{Char.from_u32(13), SCon{Char.from_u32(10), SNil{}}}

def request(port: U32) -> String:
  "GET /stream HTTP/1.1" ++ crlf() ++ "Host: 127.0.0.1" ++ crlf() ++
    "Connection: close" ++ crlf() ++ crlf()

def send_ok(pair: Socket & Result<&1, &1, U32 & String, Unit>) -> IO(Socket):
  (sock, result) = pair
  match result:
    case Fail{(code, detail)}:
      IO.die(Socket, code, "send failed")
    case Done{value}:
      IO.pure(Socket, sock)

def poll_ok(pair: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>)
  -> IO(Socket & Maybe<&1, String>):
  (sock, result) = pair
  match result:
    case Fail{(code, detail)}:
      IO.die(Socket & Maybe<&1, String>, code, "poll failed")
    case Done{value}:
      IO.pure(Socket & Maybe<&1, String>, Tuple{sock, value})

@unsafe
def pump(sock: Socket, k: U32) -> IO(Unit):
  do IO<Unit>:
    got : Socket & Maybe<&1, String> <- poll_ok(TCP.poll(sock, 4096, 3000))
    step(got, k)

def step(got: Socket & Maybe<&1, String>, k: U32) -> IO(Unit):
  (sock, chunk) = got
  match chunk:
    case None{}:
      do IO<Unit>:
        Socket.close(sock)
        IO.print("closed by peer")
    case Some{text}:
      do IO<Unit>:
        IO.print("chunk " ++ U32.show(k) ++ ": " ++ text)
        pump(sock, (k + 1 : U32))

def main() -> IO(Unit):
  do IO<Unit>:
    sock : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", 41739))
    pair : Socket & Result<&1,&1,U32 & String,Unit> <-
      TCP.send(sock, request(41739))
    sock2 : Socket <- send_ok(pair)
    pump(sock2, 0)
