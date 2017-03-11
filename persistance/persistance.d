import core.stdc.signal;
import std.stdio, std.socket, std.algorithm, std.process,core.thread;
enum Role {Master,Slave}

void persist(string programName , Role role){

  auto slaveAddress = getAddress("localhost",12092).find!(a=>a.addressFamily == AddressFamily.INET )[0];
  //auto masterAddress= getAddress("localhost",13092).find!(a=>a.addressFamily == AddressFamily.INET )[0];
  try{
    if ( Role.Slave == role){
      TcpSocket tcpSocket = new TcpSocket();
      tcpSocket.bind(slaveAddress);
      tcpSocket.listen(1);
      auto masterCom = tcpSocket.accept();
      writeln("accepted new connection");
      auto lastReceived = MonoTime.currTime;
      while ( true ){
	ubyte[] data = new ubyte[](20);
	writeln("slaveloop");
	long received  = masterCom.receive(data);
	if ( received > 0 ){
	  lastReceived = MonoTime.currTime();
	  writeln("msg received: " , data[0..received]);
	  //writeln("receivedData: ", masterCom.getErrorText);
	}else if (received == Socket.ERROR){
	  //writeln("socket error");
	  break;
	}else{
	  //writeln("receivedData: ", received);
	  writeln(masterCom.getErrorText);
	}
	if ( (MonoTime.currTime - lastReceived).total!"msecs"> 300){
	  //writeln("break");
	  break;
	}
	Thread.sleep(dur!"msecs"(25));
      }
      role = Role.Master;
      masterCom.shutdown(SocketShutdown.BOTH);
      masterCom.close();
      tcpSocket.shutdown(SocketShutdown.BOTH);
      tcpSocket.close();
    }
  }
  catch(Throwable t){
    writeln(t);
    Thread.sleep(dur!"seconds"(10));
  }
  version( OSX ){
    auto cmd =["/usr/bin/osascript", "-e","tell app \"iTerm2\" \n create window with default profile command \"" ~programName~      "\" \nend tell"];
  }
  version(linux){
    auto  cmd = ["gnome-terminal","-x",programName];
  }
  try{
    if ( Role.Master == role){
      writeln(cmd);
      auto pp = pipeProcess(cmd);
      //Thread.sleep(dur!"msecs"(500));
      enum MasterState{ Init, Running}
      MasterState masterState = MasterState.Init;
      TcpSocket tcpSocket;

      while(true){
	writeln("masterloop");
	if ( MasterState.Init == masterState ){
	  try {
	    tcpSocket = new TcpSocket();
	    tcpSocket.connect(slaveAddress);
	    masterState = MasterState.Running;
	    writeln("connected");
	  }catch(Throwable t){
	    writeln("slave not responding");
	    tcpSocket.shutdown(SocketShutdown.BOTH);
	    tcpSocket.close();
	    Thread.sleep(dur!"msecs"(100));
	  }
		  
	}else{

	  ubyte[] data= new ubyte[](10);
	  long sent = tcpSocket.send(data);
	  writeln("sent data: ", sent);
	  Thread.sleep(dur!"msecs"(100));
	  if (1>sent){
	    pipeProcess(cmd);
	    //writeln(tcpSocket.getErrorText);
	    tcpSocket.shutdown(SocketShutdown.BOTH);
	    tcpSocket.close();
	    writeln("isdead!");
	    masterState = MasterState.Init;

	  }
	}
      }
    }
  }  catch(Throwable t){
    writeln("exception");
    writeln(t);
    Thread.sleep(dur!"seconds"(10));
  }

}
