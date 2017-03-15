import core.thread;
import std.concurrency;
import persistance.persist;
void main( string[] args){
  version(OSX){
    string programName = "/Users/torje/Documents/2017v/sanntid/elevator/persistMain";
  }
  version(linux){
    string programName = "/home/pvv/d/torjehoa/Documents/2017v/sanntidsheis/persistDemo";
  }
    Role role;
    if ( args.length == 2){
        role = Role.Master;
    }else{
        role = Role.Slave;
    }
    spawn( &persist , programName, role);
    while(true){
        Thread.sleep(dur!"seconds"(5));
    }
}
