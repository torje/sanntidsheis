import core.time, core.thread;
import std.stdio;
static import elevator;
import button;
import std.concurrency;

void main(){

    elevator.init(elev_type.ET_Comedi);

    elevator.stop();
    auto tid = spawn(&elevator.spawn,elev_type.ET_Comedi);
    Thread.sleep(dur!"seconds"(2));
}
