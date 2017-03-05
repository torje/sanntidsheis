
immutable int N_FLOORS = 4;

// Number of buttons (and corresponding lamps) on a per-floor basis
immutable N_BUTTONS =  3;
enum elev_motor_direction_t:int{
    DIRN_DOWN = -1,
    DIRN_STOP = 0,
    DIRN_UP = 1
}
enum elev_button_type_t:int{
    BUTTON_CALL_UP = 1,
    BUTTON_CALL_DOWN = 1,
    BUTTON_COMMAND = 1
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
int getButton(int button, int floor){ return elev_get_button_signal(cast(elev_button_type_t)button, floor);}
int getStop(){ return elev_get_stop_signal();}
int getObstruction(){return elev_get_obstruction_signal();}



































//fuck
