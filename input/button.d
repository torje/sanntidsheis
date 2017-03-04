
immutable int N_FLOORS = 4;

// Number of buttons (and corresponding lamps) on a per-floor basis
immutable N_BUTTONS =  3;
enum elev_motor_direction_t:int{
    DIRN_DOWN = -1,
    DIRN_STOP = 0,
    DIRN_UP = 1
}
enum elev_button_type_t:int{
    BUTTON_CALL_UP = 0,
    BUTTON_CALL_DOWN = 1,
    BUTTON_COMMAND = 2
}

enum elev_type:int{
    ET_Comedi,
    ET_Simulation
}

extern(C){

void elev_init(elev_type e);

void elev_set_motor_direction(elev_motor_direction_t dirn);
void elev_set_button_lamp(elev_button_type_t button, int floor, int value);
void elev_set_floor_indicator(int floor);
void elev_set_door_open_lamp(int value);
void elev_set_stop_lamp(int value);

int elev_get_button_signal(elev_button_type_t button, int floor);
int elev_get_floor_sensor_signal();
int elev_get_stop_signal();
int elev_get_obstruction_signal();




}
int getFloorNo(){ return elev_get_floor_sensor_signal();}
int getButton(elev_button_type_t button, int floor){ return elev_get_button_signal(button, floor);}
int getStop(){ return elev_get_stop_signal();}
int getObstruction(){return elev_get_obstruction_signal();}


struct MultiState{
    int function() foo;
    int state;
    string msg;
    //int (*foo)();
    this(  int function ()foo){
        this.foo = foo;
    }
    this (string msg){
        this.msg = msg;
    }
    void update(int current){
        if ( current != state){
            writeln(msg,current);
        }
        state = current;
    }
}




struct Elevetor {
    MultiState floor;
    static void init(){
        elev_init();
    }
    static stop(){
        elev_set_motor_direction(elev_motor_direction_t.DIRN_STOP);
    }
    static up(){
        elev_set_motor_direction(elev_motor_direction_t.DIRN_UP);
    }
    static down(){
        elev_set_motor_direction(elev_motor_direction_t.DIRN_UP);
    }
}
































//fuck
