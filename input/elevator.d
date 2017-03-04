import button;
import core.thread;
import std.typecons;
import channels;
struct MultiState{
    int function() foo;
    int state;
    //string msg;
    Tuple!(int,int)[] events;
    //int (*foo)();
    this(  int function ()foo){
        this.foo = foo;
    }
    void update(){
        int current = foo();
        if ( current != state){
            events~=tuple(state,current);;
        }
        state = current;
    }
}

struct MultiState2ary{
    int state;
    int function(int,int) foo;
    int arg0, arg1;
    Tuple!(int,int) events;
    this(int function(int,int) foo, int arg0, int arg1){
        this.foo = foo;
        this.arg0 = arg0;
        this.arg1 = arg1;
    }
    void update(){
        int current = foo(arg0, arg1);
        if ( current != state){
            events~=tuple(state,current);;
        }
        state = current;
    }

}

enum OrderDirection{
    DontCare,DOWN,UP
}
enum Direction{
    UP, DOWN, STILL
}




struct Order{
    int floor;
    int direction;
}
import std.stdio;



bool defined = false;
MultiState floor;
Direction dir;
shared NonBlockingChannel!(Order) ch;
double estPos;
MultiState2ary[] buttonsUp;
MultiState2ary[] buttonsIn;
MultiState2ary[] buttonsDown;



void floor_seek(){
    floor = MultiState(&getFloorNo);
    floor.update();
    floor.events = [];
    up();
    //writeln("start moving");
    while(floor.state == -1){Thread.sleep(dur!"msecs"(32));floor.update();}
    defined = true;
    estPos = floor.state;
    stop();
    //writeln("stop moving");
}
void spawn(elev_type et, shared NonBlockingChannel!(Order) ch1){
    ch = ch1;
    elev_init(et);
    stop();
    floor_seek();
    while(true){
        floor.update();
        handleFloors();
        handleButtons();
    }
}
void handleButtons(){

    elev_button_type_t cbutton;

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
    foreach( i,ref button; buttonsIn ){
        button = MultiState2ary(&getButton,elev_button_type_t.BUTTON_COMMAND,i );
    }
    foreach ( ref button ; buttonsUp){
        button = MultiState2ary(&getButton,elev_button_type_t.BUTTON_CALL_UP,i );
    }
    foreach( ref button ; buttonsDown){
        button = MultiState2ary(&getButton,elev_button_type_t.BUTTON_CALL_DOWN,i );
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
