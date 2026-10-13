`timescale 1ns / 1ps

module traffic_controller_tb;

    //====================================================
    // INPUTS
    //====================================================

    reg clk;
    reg reset;

    reg [1:0] traffic1;
    reg [1:0] traffic2;
    reg [1:0] traffic3;
    reg [1:0] traffic4;

    reg emergency1;
    reg emergency2;
    reg emergency3;
    reg emergency4;


    //====================================================
    // OUTPUTS
    //====================================================

    wire R1, Y1, G1;
    wire R2, Y2, G2;
    wire R3, Y3, G3;
    wire R4, Y4, G4;


    //====================================================
    // DUT - DEVICE UNDER TEST
    //====================================================
    // CLOCK_FREQ is overridden to a small value here so that
    // "one_second" ticks fast enough to observe within a
    // reasonable simulation time. Leave the default
    // (50,000,000) in the design file for real FPGA use.

    smart_traffic_controller #(.CLOCK_FREQ(3)) uut (

        .clk(clk),
        .reset(reset),

        .traffic1(traffic1),
        .traffic2(traffic2),
        .traffic3(traffic3),
        .traffic4(traffic4),

        .emergency1(emergency1),
        .emergency2(emergency2),
        .emergency3(emergency3),
        .emergency4(emergency4),

        .R1(R1),
        .Y1(Y1),
        .G1(G1),

        .R2(R2),
        .Y2(Y2),
        .G2(G2),

        .R3(R3),
        .Y3(Y3),
        .G3(G3),

        .R4(R4),
        .Y4(Y4),
        .G4(G4)
    );


    //====================================================
    // DUMP FOR GTKWAVE
    //====================================================

    initial
    begin
        $dumpfile("traffic_controller.vcd");
        $dumpvars(0, traffic_controller_tb);
    end


    //====================================================
    // CLOCK GENERATION
    //====================================================

    initial
    begin
        clk = 0;

        forever
            #5 clk = ~clk;
    end


    //====================================================
    // TEST SEQUENCE
    //====================================================

    initial
    begin

        // Initial values
        reset = 1;

        traffic1 = 2'b00;
        traffic2 = 2'b00;
        traffic3 = 2'b00;
        traffic4 = 2'b00;

        emergency1 = 0;
        emergency2 = 0;
        emergency3 = 0;
        emergency4 = 0;

        // Hold reset
        #20;

        reset = 0;


        //================================================
        // TEST 1: DIFFERENT TRAFFIC DENSITIES
        //================================================

        // Road 1 = LOW
        // Road 2 = MEDIUM
        // Road 3 = HIGH
        // Road 4 = VERY HIGH

        traffic1 = 2'b00;
        traffic2 = 2'b01;
        traffic3 = 2'b10;
        traffic4 = 2'b11;

        #1000;


        //================================================
        // TEST 2: CHANGE TRAFFIC DENSITY
        //================================================

        // Road 1 = VERY HIGH
        // Road 2 = LOW
        // Road 3 = MEDIUM
        // Road 4 = HIGH

        traffic1 = 2'b11;
        traffic2 = 2'b00;
        traffic3 = 2'b01;
        traffic4 = 2'b10;

        #1000;


        //================================================
        // TEST 3: EMERGENCY ON ROAD 3
        //================================================

        emergency3 = 1;

        #200;

        emergency3 = 0;

        #500;


        //================================================
        // TEST 4: EMERGENCY ON ROAD 1
        //================================================

        emergency1 = 1;

        #200;

        emergency1 = 0;

        #500;


        //================================================
        // TEST 5: EMERGENCY ON ROAD 4
        //================================================

        emergency4 = 1;

        #200;

        emergency4 = 0;

        #500;


        //================================================
        // END SIMULATION
        //================================================

        $finish;

    end


    //====================================================
    // DISPLAY VALUES IN SIMULATION CONSOLE
    //====================================================

    initial
    begin

        $monitor(
            "Time=%0t | State=%b | T1=%b T2=%b T3=%b T4=%b | ",
            $time,
            uut.state,
            traffic1,
            traffic2,
            traffic3,
            traffic4
        );

    end

endmodule
