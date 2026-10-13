# Smart Traffic Light Controller (Verilog)

A Moore FSM-based smart traffic light controller for a 4-way intersection,
supporting traffic-density-adaptive green times and emergency vehicle
preemption on any road.

## Features

- 4-way intersection, each road with Red / Yellow / Green outputs
- Green duration scales with a 2-bit traffic density input per road
  (`00` = low → 5s, `01` = medium → 10s, `10` = high → 15s, `11` = very
  high → 20s)
- Fixed 2-second yellow phase between green transitions
- Emergency preemption: any road's emergency input can interrupt the
  controller from *any* current state (not just when it's already that
  road's turn), holds the corresponding road green until the signal
  clears, then resumes normal round-robin cycling
- Priority order when multiple emergencies are asserted simultaneously:
  Road1 > Road2 > Road3 > Road4

## Project structure

```
traffic-light-controller/
├── src/
│   └── smart_traffic_controller.v   # FSM design
├── testbench/
│   └── tb_smart_traffic_controller.v
├── waveforms/
│   └── traffic_controller.vcd       # sample simulation output
└── README.md
```

## Simulating with Icarus Verilog + GTKWave

```bash
iverilog -o sim.out src/smart_traffic_controller.v testbench/tb_smart_traffic_controller.v
vvp sim.out
gtkwave waveforms/traffic_controller.vcd
```

Note: the testbench instantiates the design with `CLOCK_FREQ(3)` so the
internal 1-second tick fires quickly enough to observe within a short
simulation. For real FPGA deployment, drop the parameter override and
let the design use its default `CLOCK_FREQ` (set to match your board's
actual clock frequency, e.g. 50,000,000 for a 50 MHz clock).

## State machine

| State | Meaning |
|---|---|
| `0000` | Road 1 green |
| `0001` | Road 1 yellow |
| `0010` | Road 2 green |
| `0011` | Road 2 yellow |
| `0100` | Road 3 green |
| `0101` | Road 3 yellow |
| `0110` | Road 4 green |
| `0111` | Road 4 yellow |
| `1000` | Emergency — Road 1 |
| `1001` | Emergency — Road 2 |
| `1010` | Emergency — Road 3 |
| `1011` | Emergency — Road 4 |


