import std.typecons, std.concurrency;
import core.thread, core.time;
import input.elev_wrap;
import threadcom.channels, input.multistateeventgenerators, orders.ordertypes;

//alias Direction = elev_button_type_t;

import std.stdio;



shared NonBlockingChannel!(Order) ch;
shared NonBlockingChannel!(Order) inChannel;

bool defined = false;
MultiState floor;
Direction dir;
Direction lastDir;
MonoTime readyAt;
Order currentOrder;
bool  currentOrderActive=false;
double estPos = 2;
MultiState2ary[] buttonsUp;
MultiState2ary[] buttonsIn;
MultiState2ary[] buttonsDown;

struct ElevatorState{
    double  estPos;
    bool    active;
    Direction dir;
    int floors = N_FLOORS;
    this(
        double  estPos,
        bool    active,
        Direction dir){
        this.estPos = estPos;
        this.active = active;
        this.dir = dir;
    }
}

void spawn(elev_type et, shared NonBlockingChannel!(Order) ch1,shared NonBlockingChannel!(Order) toElev){
    ch = ch1;
    inChannel = toElev;
    init(et);
    stop();
    floor = MultiState(&getFloorNo);
    while(true){
        if ( defined ){
            floor.update();
            handleFloors();
            handleButtons();
            if ( MonoTime.currTime() > readyAt){
                executeOrders();
            }
        }else{
            floor_seek();
        }
        receiveTimeout(dur!"msecs"(5),
            (PollElevator dummy ){
                send(ownerTid, ElevatorState( estPos,currentOrderActive,lastDir) );
            },
            (FloorStop dummy){
                openDoor();
                readyAt = MonoTime.currTime() + dur!"seconds"(3);
            }
        );

        Thread.sleep(dur!"msecs"(50));
    }
}

// internal functions;
void floor_seek(){
    floor.update();
    floor.events = [];
    //writeln("start moving");
    if( floor.state == -1){
        down();
        floor.update();}
    else{
        defined = true;
        estPos = floor.state;
        stop();
    }
    //writeln("stop moving");
}
bool goToFloor(int floor){
    if (0==estPos-floor){
        ownerTid.send(ArrivedAtDestination());
        writeln("arrived");
        dir = Direction.STILL;
        stop();
        return true;
    }else if ( 0< estPos-floor ){
        dir = Direction.DOWN;
        lastDir = dir;
        down();
        return false;
    }else{
        dir = Direction.UP;
        lastDir = dir;
        up();
        return false;
    }
}
void executeOrders(){
    if ( currentOrderActive == true ){
        closeDoor();
        if ( goToFloor(currentOrder.floor)){
            writeln("deactivating work order");
            currentOrderActive = false;
        }
    }else{
        if ( inChannel.extract(currentOrder)){
            currentOrderActive = true;
        }
    }
}
void transferButtonEvents( MultiState2ary[] buttonGroup){
    foreach( ref button ; buttonGroup){
        button.update();
        foreach( int i,ref event; button.events){
            if (  event[0] == 0 &&  event[1] ==1 ) {
                ch.insert( Order( button.arg1, cast(OrderDirection)button.arg0, 0));
            }else if (event[0] == 1 &&  event[1] ==0 ) {
            }else{
                writeln("you suck");
            }
        }
        button.events = [];
    }
}
void handleButtons(){
    transferButtonEvents(buttonsIn);
    transferButtonEvents(buttonsUp);
    transferButtonEvents(buttonsDown);
}
void handleFloors(){
    if (floor.events.length> 1){
        writeln("emergency, you suck at coding");
    }
    foreach(event; floor.events){
        if (event[0] >= 0&& event[1] == -1){
            if (dir == Direction.UP){
                estPos = event[0]+0.5;
            }else if (dir == Direction.DOWN){
                estPos = event[0]-0.5;
            }else if ( dir == Direction.STILL    ){
                writeln("Event while still");
                defined = false;
            }else{
                writeln("Dafuq, really");
                defined = false;
            }
        }else if (event[0] ==-1 && event[1]>= 0 && event[1]< N_FLOORS){
            estPos= event[1];
        }else{
            writeln("Mishandled data: floor jump");
            writeln(event);
            defined = false;
        }
    }
    floor.events = [];
}
void init(elev_type et){
    elev_init(et);
    buttonsIn = new MultiState2ary[N_FLOORS];
    buttonsUp = new MultiState2ary[N_FLOORS];
    buttonsDown = new MultiState2ary[N_FLOORS];
    foreach( int i,ref button; buttonsIn ){
        buttonsIn[i] = MultiState2ary(&getButton,elev_button_type_t.BUTTON_COMMAND,i );
    }
    foreach (int i, ref button ; buttonsUp){
        buttonsUp[i] = MultiState2ary(&getButton,elev_button_type_t.BUTTON_CALL_UP,i );
    }
    foreach(int i, ref button ; buttonsDown){
        int buttonType = elev_button_type_t.BUTTON_CALL_DOWN;
        buttonsDown[i] = MultiState2ary(&getButton,buttonType,i );
    }
}
void resume(){

}
void stop(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_STOP);
    dir = Direction.STILL;
}
void up(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_UP);
    dir = Direction.UP;
}
void down(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_DOWN);
    dir = Direction.DOWN;
}
