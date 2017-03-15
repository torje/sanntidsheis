import core.time, core.thread;
import std.stdio;
import elevator = input.elevator;
import input.elev_wrap, channels, orders.ordertypes;
import std.concurrency;


void main(){
    shared NonBlockingChannel!(Order) fromElev = new NonBlockingChannel!(Order);
    shared NonBlockingChannel!(Order) toElev = new NonBlockingChannel!(Order);
    auto tid = spawn(&elevator.spawn,elev_type.ET_Simulation, fromElev, toElev);

    while( true){
        //elevator.Order order;
        Order order;
        //writeln("snafu");
        while ( fromElev.extract(order) ){
            writeln(order);
            if ( order.direction == OrderDirection.DontCare){
                toElev.insert(order);
            }
        }
    }

}
