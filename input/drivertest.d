import core.time, core.thread;
import std.stdio;
static import elevator;


void main(){

    elevator.init(elev_type.ET_Comedi);
    //MultiState floors = MultiState("floor: ");
    elevator.up();
    elevator.stop();
    elevator.down();
    elevator.stop();

    /+while( true){
        foreach(i; 0..N_FLOORS){
            floors.update( elev_get_floor_sensor_signal());
        }
    }+/
}
