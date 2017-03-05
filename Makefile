DC=dmd
DFLAGS=-c

elevatordriver:elevatordriver/elevatordriver.o
elevatordriver/elevatordriver.o: elevatordriver/elevatordriver.d
	$(DC) $(DFLAGS) -of$@$^
networkd_demo: networkd_demo.o jsond/jsonx.o networkd/udp_bcast.o networkd/peers.o
	$(DC) $^ -of$@
networkd_demo.o: networkd_demo.d
	$(DC) $(DFLAGS)  $^ -of$@
jsond/jsonx.o: jsond/jsonx.d
	$(DC) $(DFLAGS)  $^ -of$@
networkd/udp_bcast.o:networkd/udp_bcast.d
	$(DC) $(DFLAGS)  $^ -of$@
networkd/peers.o:networkd/peers.d
	$(DC) $(DFLAGS)  $^ -of$@

