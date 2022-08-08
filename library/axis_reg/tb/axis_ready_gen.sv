// File: axis_ready_trans.sv
// Brief: AXI4-Stream Ready UVM Transaction

`ifndef AXIS_READY_TRANS
`define AXIS_READY_TRANS

import uvm_pkg::*;
`include "uvm_macros.svh"

typedef enum {
  AXIS_READY_GEN_NO_BACKPRESSURE,
  AXIS_READY_GEN_RANDOM,
  AXIS_READY_GEN_SINGLE,
  AXIS_READY_GEN_OSC,
  AXIS_READY_GEN_EVENTS,
  AXIS_READY_GEN_AFTER_VALID_SINGLE,
  AXIS_READY_GEN_AFTER_VALID_OSC,
  AXIS_READY_GEN_AFTER_VALID_EVENTS
} axis_ready_gen_policy_t;

typedef enum {
  AXIS_READY_RAND_SINGLE,
  AXIS_READY_RAND_OSC,
  AXIS_READY_RAND_EVENTS,
  AXIS_READY_RAND_AFTER_VALID_SINGLE,
  AXIS_READY_RAND_AFTER_VALID_OSC,
  AXIS_READY_RAND_AFTER_VALID_EVENTS
} axis_ready_rand_policy_t;

/*
  Class: axis_ready_gen
  AXI4-Stream Ready generation transaction. Ready signal of AXI4-Stream is
    generated based is generated based on the class attributes.
    This class support different patterns of ready signal which user wants.
*/
class axis_ready_gen extends uvm_sequence_item;

  protected bit                     use_variable_ranges     = 0;

  protected axis_ready_gen_policy_t ready_policy            = AXIS_READY_GEN_SINGLE;
  rand axis_ready_rand_policy_t     ready_rand_policy       = AXIS_READY_RAND_SINGLE;

  protected int unsigned            max_low_time            = 5;
  protected int unsigned            min_low_time            = 0;
  protected int unsigned            low_time                = 2;
  rand int unsigned                 rand_low_time           = 2;

  protected int unsigned            max_high_time           = 5;
  protected int unsigned            min_high_time           = 1;
  protected int unsigned            high_time               = 5;
  rand int unsigned                 rand_high_time          = 5;

  protected int unsigned            max_event_count         = 1;
  protected int unsigned            min_event_count         = 1;
  protected int unsigned            event_count             = 1;
  rand int unsigned                 rand_event_count        = 1;

  protected int unsigned            event_cycle_count_reset = 2000;

  `uvm_object_utils_begin(axis_ready_gen)
    `uvm_field_int(use_variable_ranges, UVM_DEFAULT)

    `uvm_field_enum(axis_ready_gen_policy_t, ready_policy, UVM_DEFAULT)
    `uvm_field_enum(axis_ready_rand_policy_t, ready_rand_policy, UVM_DEFAULT)

    `uvm_field_int(max_low_time, UVM_DEFAULT)
    `uvm_field_int(min_low_time, UVM_DEFAULT)
    `uvm_field_int(low_time, UVM_DEFAULT)
    `uvm_field_int(rand_low_time, UVM_DEFAULT)

    `uvm_field_int(max_high_time, UVM_DEFAULT)
    `uvm_field_int(min_high_time, UVM_DEFAULT)
    `uvm_field_int(high_time, UVM_DEFAULT)
    `uvm_field_int(rand_high_time, UVM_DEFAULT)

    `uvm_field_int(max_event_count, UVM_DEFAULT)
    `uvm_field_int(min_event_count, UVM_DEFAULT)
    `uvm_field_int(event_count, UVM_DEFAULT)
    `uvm_field_int(rand_event_count, UVM_DEFAULT)

    `uvm_field_int(event_cycle_count_reset, UVM_DEFAULT)
  `uvm_object_utils_end

  constraint low_time_c {rand_low_time inside {[min_low_time : max_low_time]};}
  constraint high_time_c {rand_high_time inside {[min_high_time : max_high_time]};}
  constraint event_count_c {rand_event_count inside {[min_event_count : max_event_count]};}

  constraint rand_policy_c {
    ready_rand_policy dist {
      AXIS_READY_RAND_SINGLE             :/ 30,
      AXIS_READY_RAND_OSC                :/ 15,
      AXIS_READY_RAND_EVENTS             :/ 10,
      AXIS_READY_RAND_AFTER_VALID_SINGLE :/ 20,
      AXIS_READY_RAND_AFTER_VALID_OSC    :/ 15,
      AXIS_READY_RAND_AFTER_VALID_EVENTS :/ 10
    };
  }

  /*
    Function: new
    Constructor to create an new axi4stream ready gen object
  */
  function new(string name = "axis_ready_gen");
    super.new(name);
  endfunction : new

  /*
    Function: reset_to_defaults
    Reset all variables in ready generation to default value
  */
  virtual function void reset_to_defaults();
    this.use_variable_ranges = 0;

    this.max_low_time = 5;
    this.min_high_time = 0;
    this.low_time = 2;
    this.rand_low_time = 2;

    this.max_high_time = 5;
    this.min_high_time = 1;
    this.high_time = 5;
    this.rand_high_time = 5;

    this.max_event_count = 1;
    this.min_event_count = 1;
    this.event_count = 1;
    this.rand_event_count = 1;

    this.event_cycle_count_reset = 2000;

    this.ready_policy = AXIS_READY_GEN_SINGLE;
    this.ready_rand_policy = AXIS_READY_RAND_SINGLE;
  endfunction : reset_to_defaults

  /*
    Function: set_use_variable_ranges
    Sets the use of the variable ranges when the policy of ready generation is not RANDOM
  */
  virtual function void set_use_variable_ranges();
    this.use_variable_ranges = 1;
  endfunction : set_use_variable_ranges

  /*
    Function: clr_use_variable_ranges
    Clears the use of the variable ranges when the policy of ready generation is not RANDOM
  */
  virtual function void clr_use_variable_ranges();
    this.use_variable_ranges = 0;
  endfunction : clr_use_variable_ranges

  /*
    Function: get_use_variable_ranges
    Returns the current state of the variable range use feature.
  */
  virtual function bit get_use_variable_ranges();
    return (this.use_variable_ranges);
  endfunction : get_use_variable_ranges

  /*
    Function: set_ready_policy
    Sets the policy of ready generation
  */
  virtual function void set_ready_policy(input axis_ready_gen_policy_t value);
    this.ready_policy = value;
    if (value == AXIS_READY_GEN_NO_BACKPRESSURE) begin
      this.set_low_time(0);
      this.set_low_time_range(0, 0);
      this.set_high_time(1);
      this.set_high_time_range(1, 1);
      this.clr_use_variable_ranges();
    end
  endfunction

  /*
    Function: get_ready_policy
    Returns the current ready generation policy
  */
  virtual function axis_ready_gen_policy_t get_ready_policy();
    return (this.ready_policy);
  endfunction

  /*
   Function: get_ready_rand_policy
   Returns ready_rand_policy of the ready generation
  */
  virtual function axis_ready_rand_policy_t get_ready_rand_policy();
    return (this.ready_rand_policy);
  endfunction : get_ready_rand_policy

  /*
    Function: set_low_time_range
    Sets min_low_time and max_low_time of the current ready generation
  */
  virtual function void set_low_time_range(input int unsigned min, input int unsigned max);
    if (min > max) begin
      `uvm_fatal(this.get_name(),
                 $sformatf("LOW_TIME: Attempted to set the max (%d) value lower than the min (%d)",
                           max, min))
    end
    this.min_low_time = min;
    this.max_low_time = max;
  endfunction

  /*
    Function: get_low_time_range
    Returns min_low_time and max_low_time of the current ready generation
  */
  virtual function void get_low_time_range(output int unsigned min, output int unsigned max);
    min = this.min_low_time;
    max = this.max_low_time;
  endfunction


  /*
    Function: set_low_time
    Sets low_time of the current ready generation
  */
  virtual function void set_low_time(input int unsigned value);
    if ((this.get_ready_policy() == AXIS_READY_GEN_NO_BACKPRESSURE) && (value > 0)) begin
      `uvm_fatal(this.get_name(),
                 $sformatf("LOW_TIME: Attempted to set the low time(%d) when policy is %s", value,
                           this.ready_policy.name()))
    end else begin
      this.low_time = value;
    end
  endfunction

  /*
    Function: get_low_time
    Returns low time of the current ready generation
  */
  virtual function int unsigned get_low_time();
    if (this.get_ready_policy() == AXIS_READY_GEN_NO_BACKPRESSURE) begin
      return (0);
    end else if ((this.get_use_variable_ranges() == 1) || (this.get_ready_policy() == AXIS_READY_GEN_RANDOM)) begin
      return (this.rand_low_time);
    end else begin
      return (this.low_time);
    end
  endfunction

  /*
    Function: set_high_time_range
    Sets min_high_time and max_high_time of the current ready generation
  */
  virtual function void set_high_time_range(input int unsigned min, input int unsigned max);
    if (min < 1) begin
      `uvm_fatal(this.get_name(),
                 $sformatf("HIGH_TIME: Attempted to set the min(%d) value smaller than 1", min))
    end else if (min > max) begin
      `uvm_fatal(this.get_name(),
                 $sformatf("HIGH_TIME: Attempted to set the max (%d) value lower than the min (%d)",
                           max, min))
    end
    this.min_high_time = min;
    this.max_high_time = max;
  endfunction

  /*
    Function: get_high_time_range
    Returns min_high_time and max_high_time of the current ready generation
  */
  virtual function void get_high_time_range(output int unsigned min, output int unsigned max);
    min = this.min_high_time;
    max = this.max_high_time;
  endfunction

  /*
    Function: set_high_time
    Sets high_time of the current ready generation
  */
  virtual function void set_high_time(input int unsigned value);
    if (value < 1) begin
      `uvm_fatal(this.get_name(),
                 $sformatf("HIGH_TIME: Attempted to set high time (%d) smaller than 1", value))
    end else if ((this.get_ready_policy() == AXIS_READY_GEN_NO_BACKPRESSURE) && (value > 1)) begin
      `uvm_warning(this.get_name(),
                   $sformatf("HIGH_TIME: Attempted to set the high time(%d) when policy is %s",
                             value, this.ready_policy.name()))
      this.high_time = value;
    end else begin
      this.high_time = value;
    end
  endfunction

  /*
    Function: get_high_time
    Returns high time of the current ready generation
  */
  virtual function int unsigned get_high_time();
    if (this.get_ready_policy() == AXIS_READY_GEN_NO_BACKPRESSURE) begin
      return (1);
    end else if ((this.get_use_variable_ranges() == 1) || (this.get_ready_policy() == AXIS_READY_GEN_RANDOM)) begin
      return (this.rand_high_time);
    end else begin
      return (this.high_time);
    end
  endfunction

  /*
    Function: set_event_count_range
    Sets min_event_count and max_event_count of the current ready generation
  */
  virtual function void set_event_count_range(input int unsigned min, input int unsigned max);
    if (min > max) begin
      `uvm_fatal(this.get_name(),
                 $sformatf(
                     "EVENT_COUNT: Attempted to set the max (%d) value lower than the min (%d)",
                     max, min))
    end
    this.min_event_count = min;
    this.max_event_count = max;
  endfunction

  /*
    Function: get_event_count_range
    Returns min_event_count and max_event_count of the current ready generation
  */
  virtual function void get_event_count_range(output int unsigned min, output int unsigned max);
    min = this.min_event_count;
    max = this.max_event_count;
  endfunction

  /*
    Function: get_event_count
    Returns event_count of the current ready generation
  */
  virtual function int unsigned get_event_count();
    if ((this.get_use_variable_ranges() == 1) || (this.get_ready_policy() == AXIS_READY_GEN_RANDOM)) begin
      return (this.rand_event_count);
    end else begin
      return (this.event_count);
    end
  endfunction : get_event_count

  /*
    Function: set_event_count
    Sets the number of events that ready stays at high
  */
  virtual function void set_event_count(input int unsigned in);
    this.event_count = in;
  endfunction : set_event_count

  /*
   Function: set_event_cycle_count_reset
   Set event_cycle_count_reset value of ready generation
  */
  virtual function void set_event_cycle_count_reset(input int unsigned value);
    this.event_cycle_count_reset = value;
  endfunction

  /*
   Function: get_event_cycle_count_reset
   Returns the current event_cycle_count_reset
  */
  virtual function int unsigned get_event_cycle_count_reset();
    get_event_cycle_count_reset = this.event_cycle_count_reset;
  endfunction

endclass

`endif
