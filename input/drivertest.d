import core.time, core.thread;
import std.stdio;
static import elevator;
import button, channels;
import std.concurrency;


void main(){
    shared NonBlockingChannel!(elevator.Order) fromElev = new NonBlockingChannel!(elevator.Order);
    shared NonBlockingChannel!(elevator.Order) toElev = new NonBlockingChannel!(elevator.Order);
    auto tid = spawn(&elevator.spawn,elev_type.ET_Comedi, fromElev, toElev);
    
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
