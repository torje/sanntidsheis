import std.stdio, std.algorithm, std.array, std.conv;
import std.math : round;
import core.time;
import persistance.persist;

import elevator = input.elevator;
import input.elev_wrap, channels;
import orders.command, orders.ordertypes;
import std.random;
import std.concurrency;

struct ElevatorTimings{
    Duration doorTime;
    Duration floorTime;
    ubyte id;
    void setId(ubyte id){
        this.id = id;
    }
    int calcpath(Order[] orders, Direction currentDirection ){
        return 1;
    }
}

Order[] findNext( Order[] orders, elevator.ElevatorState state, ubyte id){
    Order[] mine = filter!( a=>a.id==id )(orders).array;
    int step0;
    int step1;
    OrderDirection seek0;
    OrderDirection seek1;
    double seekfloor0 = round( state.estPos );
    double seekfloor1;
    double seekfloor2;
    if ( state.dir == Direction.UP){
        seekfloor1 = N_FLOORS-1;
        seekfloor2 = 0;
        step0 = 1;
        seek0 = OrderDirection.UP;
        step1 =-1;
        seek1 = OrderDirection.DOWN;
    }else{ // bias down if still;
        seekfloor1 = 0;
        seekfloor2 = N_FLOORS-1;
        step0 = -1;
        seek0 = OrderDirection.DOWN;
        step1 =1;
        seek1 = OrderDirection.UP;
    }
    while ( seekfloor0 >=0 && seekfloor0 < state.floors ){
         auto searchres = mine.filter!( a=> ( a.floor== seekfloor0)&&((a.direction ==seek0 )||(a.direction == OrderDirection.DontCare) )).array;
         seekfloor0 += step0;
         if (searchres.length > 0){
             return searchres;
         }
    }
    while ( seekfloor1 >=0 && seekfloor1 < state.floors ){
         auto searchres = mine.filter!( a=> ( a.floor== seekfloor1)&&((a.direction ==seek1 )||(a.direction == OrderDirection.DontCare) )).array;
         seekfloor1 += step1;
         if (searchres.length > 0){
             return searchres;
         }
    }
    while ( seekfloor2 >=0 && seekfloor2 < state.floors ){
         auto searchres = mine.filter!( a=> ( a.floor== seekfloor2)&&((a.direction ==seek0 )||(a.direction == OrderDirection.DontCare) )).array;
         seekfloor2 += step0;
         if (searchres.length > 0){
             return searchres;
         }
    }
    return [];
}

OrderDirection directionToOrderDirection(Direction dir){
    if (Direction.UP == dir) {return OrderDirection.UP;}
    else if ( Direction.DOWN == dir) { return OrderDirection.DOWN;}
    else return OrderDirection.DontCare;
}

void schedulerRun(){

    shared NonBlockingChannel!(Order) fromElev = new NonBlockingChannel!(Order);
    shared NonBlockingChannel!(Order) toElev = new NonBlockingChannel!(Order);
    auto elevDriver = spawn(&elevator.spawn,elev_type.ET_Simulation, fromElev, toElev);
    //readln();
    auto networkOrders = spawn(&command_spawn);
    ubyte id;
    networkOrders.send(RetrieveId() );
    receive((ubyte id1){id=id1;});
    //readln();
    Order currentOrder;
    bool orderActive = true;

    auto readyAt = MonoTime.currTime();

    while( true){
        //elevator.Order order;
        Order order;
        //writeln("snafu");
        while ( fromElev.extract(order) ){
            networkOrders.send(RetrievePeers());
            ubyte[] peers;
            receive( (immutable(ubyte)[] peers1){
                peers = peers1.dup;
            });
            Order[] orders;
            networkOrders.send(RetrieveOrders());
            receive( (immutable(Order)[] ords){
                orders = ords.dup;
            });
            ubyte assignTo;
            if ( OrderDirection.DontCare == order.direction ){
                assignTo = id;
            }else{
                assignTo = peers[uniform(0,peers.length)];
            }
            order.id = assignTo;
            auto newOrder = OrderExpression(order, OrderOperation.Create);
            networkOrders.send(newOrder);
        }
        //writeln("deciding orders");
        Order[] orders;
        Order[] next;
        networkOrders.send(RetrieveOrders());
        receive( (immutable(Order)[] ords){orders = ords.dup;});
        elevDriver.send(PollElevator());
        receive(
        (elevator.ElevatorState state){
            if (state.active){

            } else {
                if ( orderActive ){
                    networkOrders.send(OrderExpression(currentOrder,OrderOperation.Delete));
                    orderActive = false;
                    elevDriver.send(FloorStop());
                }
                next = findNext(orders, state, id);
            }
        }
        );
        if ( next.length>0){
            //writeln("new order",next[0] );
            currentOrder = next[0];
            toElev.insert(next[0]);
        }
    }
}
