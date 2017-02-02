import std.stdio, std.concurrency;
import core.stdc.stdio;
import elevatorDriver.elevatordriver;
void foo( Tid sendto){
  while ( true){
    send(sendto, cast(char)getchar());
  }
}
void main(){

  import core.sys.posix.termios;
  __gshared termios oldt;
  __gshared termios newt;
  tcgetattr(0, &oldt);
  newt = oldt;
  newt.c_lflag &= ~(ICANON | ECHO);
  tcsetattr(0, TCSANOW, &newt);

  spawn(&foo,thisTid );
  auto tcpthread = spawn(&communicator,thisTid);

  int drive = 0;
  int lastdrive = 0;
  while ( true ){

    receive(
    (char c){
      if ( c == 'a'){
        drive = 1;
        }else if ( c =='s' ){
          drive = 0;
          }else if ( c == 'd'){
            drive = -1;
          }
        }
        );

        if ( drive != lastdrive){
          writeln(drive);
          send(tcpthread, drive);
        }
        lastdrive = drive;
      }
      scope(exit){
        tcsetattr(0, TCSANOW, &oldt);
      }
    }
