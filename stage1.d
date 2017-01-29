import std.stdio, std.concurrency, std.socket, std.conv, std.algorithm, std.typecons;
import core.thread, core.time;

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
  }/+
  bool to(T:bool)(message msg){
  return msg.ismsg;
  }+/

  void printElevatorStatus(TcpSocket tcp){
    ubyte[] reads= [6:10];
    ubyte[] floors = [0:4];
    ubyte[] buttons = [0:3];
    foreach( floor; floors){
      foreach( button; buttons){
        ubyte[] order= [reads[0], button,floor,0];
        ubyte[] readback=[0,0,0,0];
        write(order);
        tcp.send(order);
        tcp.receive(readback);
        write(readback);
      }
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
      (ubyte a){
        writeln("threadcom!: ",a);
        },
        ( Tuple!(ubyte,ubyte,ubyte,ubyte) data){
          ubyte[] arr;
          arr~=data[0];
          arr~=data[1];
          arr~=data[2];
          arr~=data[3];

          writeln("threadcom!: ",arr);
          *tbs = message(arr);
        }

        );
        if(toBeSent){
          tcpSend(tcp,toBeSent.msg);
      }
      auto msg = readfrom(tcp);
      if ( msg  ){
        writeln("TCP received: ",msg);
      }
      Thread.sleep(dur!"msecs"(50) );
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

  void main(){
    auto tid = spawn(&communicator,thisTid);
    while (true)
    {
      //ubyte[] a=[4,4,4,5];
      ubyte[] data = [6,0,0,0];

      ubyte input = readf(" %s %s %s %s",&data[0],&data[1],&data[2],&data[3]).to!ubyte;

      Tuple!(ubyte,ubyte,ubyte,ubyte) a=Tuple!(ubyte,ubyte,ubyte,ubyte)(6,0,0,0);
      if ( data.length == 4){
        a[0]=data[0];
        a[1]=data[1];
        a[2]=data[2];
        a[3]=data[3];
      }
      send(tid,a);
      Thread.sleep(dur!"msecs"(5000));
    }
  }
