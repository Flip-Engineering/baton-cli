import Base

# One AF_UNIX request: connect, send, read to EOF, close. This is the
# loopback path a program lane's nested tool calls would use (Base TCP
# is AF_INET only; see effs/tcp_connect.c).
def Host.unix_request(path: String, request: String) ->
  IO(Result<&1, &1, U32 & String, String>):
  import "./sock.c"
  import "./sock.js"

def main() -> IO(Unit):
  do IO<Unit>:
    reply : String <- IO.try(String, Host.unix_request("./lane.sock", "PING"))
    IO.print("socket said " ++ reply)
