import button;
import core.thread;
import std.typecons;
struct MultiState{
    int function() foo;
    int state;
    string msg;
    Tuple!(int,int)[] events;
    //int (*foo)();
    this(  int function ()foo){
        this.foo = foo;
    }
    this (string msg){
        this.msg = msg;
    }
    void update(){
        int current = foo();
        if ( current != state){
            events~=tuple(state,current);;
        }
        state = current;
    }
    void update(int current){
        if ( current != state){
            //writeln(msg,current);
            events~=tuple(state,current);
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
double estPos;
void floor_seek(){
    floor = MultiState(&getFloorNo);
    floor.update();
    up();
    //writeln("start moving");
    while(floor.state == -1){Thread.sleep(dur!"msecs"(32));floor.update();}
    defined = true;
    estPos = floors.state;
    stop();
    //writeln("stop moving");
}
void spawn(elev_type et){
    elev_init(et);
    stop();
    floor_seek();
    while(true){
        floors.update();
    }
}
void handleFloors(){
    if (floors.events.length> 1){
        writeln("emergency, you suck at coding");
    }
    foreach(event; floors.events){
        if (event[0] >= 0&& event[1] == -1){
            if (dir == UP){
                esTtPos = event[0]+0.5;
            }else if (dir ==DOWN){
                esTtPos = event[0]-0.5;
            }else if ( dir == STOP ){
                defined = false;
            }else{
                defined = false;
            }
        }else if (event[0] ==-1 && event[1]>= 0 && event[1]< N_FLOORS){
            estPos= event[1];
        }else{
            defined = false;
        }
    }
}
void init(elev_type et){
    elev_init(et);
}
void stop(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_STOP);
    dir = STILL;
}
void up(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_UP);
    dir = UP;
}
void down(){
    elev_set_motor_direction(elev_motor_direction_t.DIRN_DOWN);
    dir = DOWN;
}
