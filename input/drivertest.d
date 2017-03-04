import core.time, core.thread;
import std.stdio;
static import elevator;
import button, channels;
import std.concurrency;


void main(){
    shared NonBlockingChannel!(elevator.Order) elevatorChan = new NonBlockingChannel!(elevator.Order);
    //elevator.init(elev_type.ET_Comedi);
    //MultiState floors = MultiState("floor: ");
    /+elevator.up();
    Thread.sleep(dur!"msecs"(250));
    elevator.stop();
    Thread.sleep(dur!"msecs"(250));
    elevator.down();
    Thread.sleep(dur!"msecs"(250));+/
    //elevator.stop();
    //elevator.stop();
    auto tid = spawn(&elevator.spawn,elev_type.ET_Comedi, elevatorChan);
    //elevator.spawn( elev_type.ET_Comedi , elevatorChan);

    while( true){
        elevator.Order order;
        //writeln("snafu");
        while ( elevatorChan.extract(order) ){
            writeln(order);
        }
    }

}
