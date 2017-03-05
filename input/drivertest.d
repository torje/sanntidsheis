import core.time, core.thread;
import std.stdio;
static import elevator;
import button, channels;
import std.concurrency;


void main(){
    shared NonBlockingChannel!(elevator.Order) fromElev = new NonBlockingChannel!(elevator.Order);
    shared NonBlockingChannel!(elevator.Order) toElev = new NonBlockingChannel!(elevator.Order);
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
    auto tid = spawn(&elevator.spawn,elev_type.ET_Comedi, fromElev, toElev);
    //elevator.spawn( elev_type.ET_Comedi , elevatorChan);

    while( true){
        elevator.Order order;
        //writeln("snafu");
        while ( fromElev.extract(order) ){
            writeln(order);
            if ( order.direction == elevator.OrderDirection.DontCare){
                toElev.insert(order);
            }
        }
    }

}
