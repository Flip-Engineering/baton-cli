import Base

# HTTP/1.1 request framing and incremental chunk delivery over Base TCP
# only. The read loop is one self-recursive def whose parameter is the
# poll result; the re-entry after each bind is a one-use closure (the
# run_from idiom of the coordinator, receive.bend:814). Pairs open by
# destructuring let (project.bend:158).
#
# EOF semantics found by this probe: TCP.poll answers Some{""} (the empty
# string, SNil{}) when the peer closes; None{} is the poll timeout. The
# empty-read case is matched with the nested constructor pattern
# Done{Some{SNil{}}}.

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

@unsafe
def pump(read: Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>, +k: U32) -> IO(Unit):
  (sock, result) = read
  match result:
    case Fail{(code, detail)}:
      IO.print("poll failed " ++ U32.show(code))
    case Done{Some{SNil{}}}:
      do IO<Unit>:
        Socket.close(sock)
        IO.print("closed by peer (empty read at EOF)")
    case Done{None{}}:
      do IO<Unit>:
        Socket.close(sock)
        IO.print("closed by peer (poll timeout)")
    case Done{Some{chunk}}:
      do IO<Unit>:
        IO.print("chunk " ++ U32.show(k) ++ ": " ++ chunk)
        IO.bind(Socket & Result<&1, &1, U32 & String, Maybe<&1, String>>, Unit,
          TCP.poll(sock, 4096, 3000),
          next => pump(next, (k + 1 : U32)))

def main() -> IO(Unit):
  do IO<Unit>:
    sock : Socket <- IO.try(Socket, TCP.connect("127.0.0.1", 41739))
    pair : Socket & Result<&1,&1,U32 & String,Unit> <-
      TCP.send(sock, request(41739))
    sock2 : Socket <- send_ok(pair)
    first : Socket & Result<&1,&1,U32 & String,Maybe<&1, String>> <-
      TCP.poll(sock2, 4096, 3000)
    pump(first, 0)
