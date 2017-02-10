import std.concurrency,std.socket, std.stdio, std.conv, std.algorithm, core.time;

class SimulatorCommunication{
  TcpSocket tcpSocket;
  bool queryFloor(int floor){
    tcpSend(tcpSocket, [7,floor.to!ubyte,0]);
    return atFloor();
  }
  bool atFloor(){
    ubyte[] receive= new ubyte[4];
    tcpSocket.receive(receive);
    if( receive.startsWith([7,1]) ){
      return true;
    }else{
      return false;
    }
  }
  this(ushort portno){
    auto addresses = getAddress("localhost",portno);
    tcpSocket = new TcpSocket(addresses[0]);
  }
}


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

void pollFloorstatus(TcpSocket tcp){
  //writeln("polling floors");
  tcpSend(tcp, [7,0,0,0]);
}

int[] buttonsPolled;


void communicator( Tid talkto){
  auto address = getAddress("localhost", 15657);
  writeln(address);
  auto b = find!(a=>a.addressFamily()==AddressFamily.INET)( address);
  writeln("Addresses: ",b);
  auto tcp = new TcpSocket(b[0]);
  writeln("connected!");
  tcp.blocking= false;
  int floor = 404;
  while(true){
    message toBeSent;
    message* tbs=&toBeSent;
    receiveTimeout(dur!"msecs"(0),
    (int a){
      //writeln( "received something" );
      tcpSend(tcp, [1,cast(ubyte)a,0,0]);
      }
      );
      //writeln("asdasdasd");
      pollFloorstatus(tcp);
      auto msg = readfrom(tcp);
      //writeln(msg.msg);

      if(msg.msg.length> 0){
        ubyte responsetype = msg.msg[0];
        switch(responsetype){
          case 6:
          writeln("order button");
          break;
          case 7:
          if(msg.msg[1]==1 && msg.msg[2] != floor){

            floor = msg.msg[2];
            writeln("arrived at floor", floor);
          }
          break;
          case 8:
          writeln("stop button");
          break;
          case 9:
          writeln("obstruction");
          break;
          default:
          writeln("fuck off");
          break;
        }
      }


    }
    tcp.close();
  }

  void tcpSend(TcpSocket tcp, ubyte[] data){
    //ubyte[] data = [6,0,0,0];
    //writeln("trying to send data");
    auto res = tcp.send(data);

    //writeln("sent data: ",data);
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
