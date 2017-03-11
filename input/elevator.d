import input.button;
import core.thread;
import std.typecons;
import threadcom.channels, input.multistateeventgenerators;

enum OrderDirection{
    DontCare,DOWN,UP
}
enum Direction{
    UP, DOWN, STILL
}
struct Order{
    int floor;
    OrderDirection direction;
    bool active = false;
    this(int floor, OrderDirection direction){
        this.floor = floor;
        this.direction = direction;
    }
}
import std.stdio;



shared NonBlockingChannel!(Order) ch;
shared NonBlockingChannel!(Order) inChannel;

bool defined = false;
MultiState floor;
Direction dir;
Order currentOrder;
double estPos;
MultiState2ary[] buttonsUp;
MultiState2ary[] buttonsIn;
MultiState2ary[] buttonsDown;

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
            executeOrders();
        }else{
            floor_seek();
        }
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
        stop();
        return true;
    }else if ( 0< estPos-floor ){
        down();
        return false;
    }else{
        up();
        return false;
    }
}
void executeOrders(){
    if ( currentOrder.active ==true ){
        if ( goToFloor(currentOrder.floor)){
            currentOrder.active = false;
        }
    }else{
        if ( inChannel.extract(currentOrder)){
            currentOrder.active = true;
        }
    }
}
void transferButtonEvents( MultiState2ary[] buttonGroup){
    foreach( ref button ; buttonGroup){
        button.update();
        foreach( int i,ref event; button.events){
            if (  event[0] == 0 &&  event[1] ==1 ) {
                ch.insert( Order(button.arg1,OrderDirection.DontCare));
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
