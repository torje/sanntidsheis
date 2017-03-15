import core.thread;
import std.concurrency, std.stdio;
import persistance.persist;
import scheduler.sched;
void main( string[] args){
    string programName = "/home/pvv/d/torjehoa/Documents/2017v/sanntidsheis/persistantElevator";
    Role role;
    if ( args.length == 2){
        role = Role.Master;
    }else{
        role = Role.Slave;
    }
    spawn( &persist , programName, role);
    receive( (string takeover){writeln(takeover);}  );
    schedulerRun();
}
