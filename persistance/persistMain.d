import core.thread;
import std.concurrency;
import persistance;
void main( string[] args){
    Role role;
    if ( args.length == 2){
        role = Role.Master;
    }else{
        role = Role.Slave;
    }
    spawn( &persist , "/Users/torje/Documents/2017v/sanntid/elevator/persistMain", role);
    while(true){
        Thread.sleep(dur!"seconds"(5));
    }
}
