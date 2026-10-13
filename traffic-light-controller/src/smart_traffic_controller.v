module smart_traffic_controller(
    input clk,
    input reset,

    // Traffic density inputs
    input [1:0] traffic1,
    input [1:0] traffic2,
    input [1:0] traffic3,
    input [1:0] traffic4,

    // Emergency inputs
    input emergency1,
    input emergency2,
    input emergency3,
    input emergency4,

    // Road 1 lights
    output reg R1,
    output reg Y1,
    output reg G1,

    // Road 2 lights
    output reg R2,
    output reg Y2,
    output reg G2,

    // Road 3 lights
    output reg R3,
    output reg Y3,
    output reg G3,

    // Road 4 lights
    output reg R4,
    output reg Y4,
    output reg G4
);

    //====================================================
    // STATE DECLARATION
    //====================================================

    parameter S_R1_GREEN  = 4'b0000,
              S_R1_YELLOW = 4'b0001,
              S_R2_GREEN  = 4'b0010,
              S_R2_YELLOW = 4'b0011,
              S_R3_GREEN  = 4'b0100,
              S_R3_YELLOW = 4'b0101,
              S_R4_GREEN  = 4'b0110,
              S_R4_YELLOW = 4'b0111,

              S_EMERGENCY1 = 4'b1000,
              S_EMERGENCY2 = 4'b1001,
              S_EMERGENCY3 = 4'b1010,
              S_EMERGENCY4 = 4'b1011;

    reg [3:0] state;
    reg [3:0] next_state;

    //====================================================
    // 1 SECOND CLOCK TICK
    //====================================================

    // For actual FPGA clock, change this value according
    // to your board clock frequency. For simulation, override
    // it at instantiation time with a small value, e.g.:
    //   smart_traffic_controller #(.CLOCK_FREQ(3)) uut (...);

    parameter CLOCK_FREQ = 50000000;

    reg [25:0] clock_count;
    reg one_second;

    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            clock_count <= 0;
            one_second <= 0;
        end
        else
        begin
            if (clock_count == CLOCK_FREQ - 1)
            begin
                clock_count <= 0;
                one_second <= 1;
            end
            else
            begin
                clock_count <= clock_count + 1;
                one_second <= 0;
            end
        end
    end

    //====================================================
    // TRAFFIC DENSITY TO GREEN TIME
    //====================================================

    function [5:0] get_green_time;
        input [1:0] density;

        begin
            case(density)

                2'b00:
                    get_green_time = 5;

                2'b01:
                    get_green_time = 10;

                2'b10:
                    get_green_time = 15;

                2'b11:
                    get_green_time = 20;

                default:
                    get_green_time = 5;

            endcase
        end
    endfunction

    //====================================================
    // TIMER
    //====================================================

    reg [5:0] timer;

    always @(posedge clk or posedge reset)
    begin
        if (reset)
            timer <= 0;

        else if (one_second)
        begin
            case(state)

                S_R1_GREEN:
                begin
                    if (timer < get_green_time(traffic1))
                        timer <= timer + 1;
                    else
                        timer <= 0;
                end

                S_R2_GREEN:
                begin
                    if (timer < get_green_time(traffic2))
                        timer <= timer + 1;
                    else
                        timer <= 0;
                end

                S_R3_GREEN:
                begin
                    if (timer < get_green_time(traffic3))
                        timer <= timer + 1;
                    else
                        timer <= 0;
                end

                S_R4_GREEN:
                begin
                    if (timer < get_green_time(traffic4))
                        timer <= timer + 1;
                    else
                        timer <= 0;
                end

                S_R1_YELLOW,
                S_R2_YELLOW,
                S_R3_YELLOW,
                S_R4_YELLOW:
                begin
                    if (timer < 2)
                        timer <= timer + 1;
                    else
                        timer <= 0;
                end

                S_EMERGENCY1,
                S_EMERGENCY2,
                S_EMERGENCY3,
                S_EMERGENCY4:
                begin
                    timer <= 0;
                end

                default:
                    timer <= 0;

            endcase
        end
    end

    //====================================================
    // NEXT STATE LOGIC
    //====================================================
    // Emergency preemption is checked FIRST, independent of
    // which road currently has the green/yellow light. This
    // means an emergency vehicle on ANY road can preempt the
    // controller immediately, not just when it's already that
    // road's turn. Priority order when multiple emergencies
    // are asserted simultaneously: Road1 > Road2 > Road3 > Road4.

    always @(*)
    begin

        next_state = state;

        if (emergency1 && state != S_EMERGENCY1)
            next_state = S_EMERGENCY1;

        else if (emergency2 && state != S_EMERGENCY2)
            next_state = S_EMERGENCY2;

        else if (emergency3 && state != S_EMERGENCY3)
            next_state = S_EMERGENCY3;

        else if (emergency4 && state != S_EMERGENCY4)
            next_state = S_EMERGENCY4;

        else
        begin
            case(state)

                //============================================
                // ROAD 1
                //============================================

                S_R1_GREEN:
                begin
                    if (one_second && timer >= get_green_time(traffic1))
                        next_state = S_R1_YELLOW;
                end

                S_R1_YELLOW:
                begin
                    if (one_second && timer >= 2)
                        next_state = S_R2_GREEN;
                end

                //============================================
                // ROAD 2
                //============================================

                S_R2_GREEN:
                begin
                    if (one_second && timer >= get_green_time(traffic2))
                        next_state = S_R2_YELLOW;
                end

                S_R2_YELLOW:
                begin
                    if (one_second && timer >= 2)
                        next_state = S_R3_GREEN;
                end

                //============================================
                // ROAD 3
                //============================================

                S_R3_GREEN:
                begin
                    if (one_second && timer >= get_green_time(traffic3))
                        next_state = S_R3_YELLOW;
                end

                S_R3_YELLOW:
                begin
                    if (one_second && timer >= 2)
                        next_state = S_R4_GREEN;
                end

                //============================================
                // ROAD 4
                //============================================

                S_R4_GREEN:
                begin
                    if (one_second && timer >= get_green_time(traffic4))
                        next_state = S_R4_YELLOW;
                end

                S_R4_YELLOW:
                begin
                    if (one_second && timer >= 2)
                        next_state = S_R1_GREEN;
                end

                //============================================
                // EMERGENCY STATES
                //============================================
                // (Only reached here when the matching emergency
                // line has already gone low, since the priority
                // checks above would otherwise keep re-asserting it.)

                S_EMERGENCY1:
                    if (!emergency1)
                        next_state = S_R1_GREEN;

                S_EMERGENCY2:
                    if (!emergency2)
                        next_state = S_R2_GREEN;

                S_EMERGENCY3:
                    if (!emergency3)
                        next_state = S_R3_GREEN;

                S_EMERGENCY4:
                    if (!emergency4)
                        next_state = S_R4_GREEN;

                default:
                    next_state = S_R1_GREEN;

            endcase
        end
    end

    //====================================================
    // STATE REGISTER
    //====================================================

    always @(posedge clk or posedge reset)
    begin
        if (reset)
            state <= S_R1_GREEN;
        else
            state <= next_state;
    end

    //====================================================
    // OUTPUT LOGIC
    //====================================================

    always @(*)
    begin

        // All lights OFF initially
        R1 = 0;
        Y1 = 0;
        G1 = 0;

        R2 = 0;
        Y2 = 0;
        G2 = 0;

        R3 = 0;
        Y3 = 0;
        G3 = 0;

        R4 = 0;
        Y4 = 0;
        G4 = 0;

        case(state)

            // Road 1 Green
            S_R1_GREEN:
            begin
                G1 = 1;
                R2 = 1;
                R3 = 1;
                R4 = 1;
            end

            // Road 1 Yellow
            S_R1_YELLOW:
            begin
                Y1 = 1;
                R2 = 1;
                R3 = 1;
                R4 = 1;
            end

            // Road 2 Green
            S_R2_GREEN:
            begin
                R1 = 1;
                G2 = 1;
                R3 = 1;
                R4 = 1;
            end

            // Road 2 Yellow
            S_R2_YELLOW:
            begin
                R1 = 1;
                Y2 = 1;
                R3 = 1;
                R4 = 1;
            end

            // Road 3 Green
            S_R3_GREEN:
            begin
                R1 = 1;
                R2 = 1;
                G3 = 1;
                R4 = 1;
            end

            // Road 3 Yellow
            S_R3_YELLOW:
            begin
                R1 = 1;
                R2 = 1;
                Y3 = 1;
                R4 = 1;
            end

            // Road 4 Green
            S_R4_GREEN:
            begin
                R1 = 1;
                R2 = 1;
                R3 = 1;
                G4 = 1;
            end

            // Road 4 Yellow
            S_R4_YELLOW:
            begin
                R1 = 1;
                R2 = 1;
                R3 = 1;
                Y4 = 1;
            end

            // Emergency Road 1
            S_EMERGENCY1:
            begin
                G1 = 1;
                R2 = 1;
                R3 = 1;
                R4 = 1;
            end

            // Emergency Road 2
            S_EMERGENCY2:
            begin
                R1 = 1;
                G2 = 1;
                R3 = 1;
                R4 = 1;
            end

            // Emergency Road 3
            S_EMERGENCY3:
            begin
                R1 = 1;
                R2 = 1;
                G3 = 1;
                R4 = 1;
            end

            // Emergency Road 4
            S_EMERGENCY4:
            begin
                R1 = 1;
                R2 = 1;
                R3 = 1;
                G4 = 1;
            end

        endcase
    end

endmodule
