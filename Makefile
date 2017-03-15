DC=dmd
DFLAGS=

elevatordriver:elevatordriver/elevatordriver.o
elevatordriver/elevatordriver.o: elevatordriver/elevatordriver.d
	$(DC) $(DFLAGS) -of$@$^
networkd_demo: networkd/networkd_demo.o jsond/jsonx.o networkd/udp_bcast.o networkd/peers.o
	$(DC) $^ -of$@
networkd_demo.o: networkd_demo.d
	$(DC) -c $(DFLAGS)  $^ -of$@
jsond/jsonx.o: jsond/jsonx.d
	$(DC) -c $(DFLAGS)  $^ -of$@
networkd/udp_bcast.o:networkd/udp_bcast.d
	$(DC) -c $(DFLAGS)  $^ -of$@
networkd/peers.o:networkd/peers.d
	$(DC) -c $(DFLAGS)  $^ -of$@


%.o:%.d
	$(DC) $(DFLAGS) -c $^ -of$@

persistance/persistance.o : persistance/persistance.d
	$(DC) $(DFLAGS) $^ -of$@
persistDemo: persistance/persistDemo.o persistance/persist.o
	$(DC) $(DFLAGS) $^ -of$@
schedDemo: scheduler/sched.o threadcom/channels.o input/elev_wrap.o input/elevator.o  input/multistateeventgenerators.o input/elev.o input/io.o orders/ordertypes.o orders/command.o networkd/udp_bcast.o networkd/peers.o jsond/jsonx.o
	$(DC) $(DFLAGS) $^ -of$@ -L-lcomedi
drivertest: input/drivertest.o input/multistateeventgenerators.o input/elev_wrap.o input/elevator.o threadcom/channels.o input/elev.o input/io.o orders/ordertypes.o
	$(DC) -of$@ $^ -L-lcomedi
commandDemo: orders/command.o orders/commandDemo.o networkd/udp_bcast.o networkd/peers.o jsond/jsonx.o
	$(DC) -of$@ $^
persistantElevator: scheduler/sched.o threadcom/channels.o input/elev_wrap.o input/elevator.o  input/multistateeventgenerators.o input/elev.o input/io.o orders/ordertypes.o orders/command.o networkd/udp_bcast.o networkd/peers.o jsond/jsonx.o persistance/persist.o persistance/persistantElevator.o
	$(DC) -of$@ $^ -L-lcomedi
