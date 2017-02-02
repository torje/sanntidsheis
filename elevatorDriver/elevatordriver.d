import std.concurrency,std.socket, std.stdio, std.conv, std.algorithm,core.time;;

struct message{
  bool ismsg=false;
  ubyte[] msg;
  bool opCast(T:bool)(){
    return ismsg;
  }
  this( ubyte[] msg){
    this.msg = msg.dup;
    ismsg =true;
  }
  string toString(){
    return std.conv.to!string(this.msg);
  }
}



void communicator( Tid talkto){
  auto address = getAddress("localhost", 15657);
  writeln(address);
  auto b = find!(a=>a.addressFamily()==AddressFamily.INET)( address);
  writeln(b);
  auto tcp = new TcpSocket(b[0]);
  tcp.blocking= false;
  while(true){
    message toBeSent;
    message* tbs=&toBeSent;
    receiveTimeout(dur!"msecs"(0),
    (int a){
      tcpSend(tcp, [1,cast(ubyte)a,0,0]);
    }
    );

    auto msg = readfrom(tcp);
  }
  tcp.close();
}

void tcpSend(TcpSocket tcp, ubyte[] data){
  //ubyte[] data = [6,0,0,0];
  auto res = tcp.send(data);

  writeln("sent data: ",data);
}

message readfrom(TcpSocket tcp){
  ubyte[4] data;
  auto res = tcp.receive(data);
  if ( res == Socket.ERROR){
    //writeln( "error on receive");
    message msg;
    return msg;
  }else{
    message msg = message(data);
    //writeln("res: ",res);
    //writeln("received data:" ,msg);
    return msg;
  }
}
