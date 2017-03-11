DC=dmd
DFLAGS=

elevatordriver:elevatordriver/elevatordriver.o
elevatordriver/elevatordriver.o: elevatordriver/elevatordriver.d
	$(DC) $(DFLAGS) -of$@$^
networkd_demo: networkd_demo.o jsond/jsonx.o networkd/udp_bcast.o networkd/peers.o
	$(DC) $^ -of$@
networkd_demo.o: networkd_demo.d
	$(DC) -c $(DFLAGS)  $^ -of$@
jsond/jsonx.o: jsond/jsonx.d
	$(DC) -c $(DFLAGS)  $^ -of$@
networkd/udp_bcast.o:networkd/udp_bcast.d
	$(DC) -c $(DFLAGS)  $^ -of$@
networkd/peers.o:networkd/peers.d
	$(DC) -c $(DFLAGS)  $^ -of$@

persistance/persistance.o : persistance/persistance.d
	$(DC) $(DFLAGS) $^ -of$@
persistDemo: persistance/persistDemo.d persistance/persistance.d
	$(DC) $(DFLAGS) $^ -of$@

%.o:%.d
	$(DC) $(DFLAGS) -c $^ -of$@
drivertest: input/drivertest.o input/multistateeventgenerators.o input/button.o input/elevator.o threadcom/channels.o input/elev.o input/io.o
	$(DC) -of$@ $^ -L-lcomedi
command: orders/command.o networkd/udp_bcast.o networkd/peers.o jsond/jsonx.o
	$(DC) -of$@ $^ 
