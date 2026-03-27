`timescale 1 ns / 1 ps
//
`default_nettype none

module ccr_buildtime (
    output wire [31:0] stat_buildtime_0,
    output wire [31:0] stat_buildtime_1
);

  // ddddd_MMMM_yyyyyy_hhhhh_mmmmmm_ssssss
  // (bit 31) .................... (bit 0)
  // Where:
  //   ddddd  = 5 bits to represent 31 days in a month
  //   MMMM   = 4 bits to represent 12 months in a year
  //   yyyyyy = 6 bits to represent 0 to 63 (to note year 2000 to 2063)
  //   hhhhh  = 5 bits to represent 24 hours in a day
  //   mmmmmm = 6 bits to represent 60 minutes in an hour
  //   ssssss = 6 bits to represent 60 seconds in a minute

  wire [31:0] user_data;

  wire [ 4:0] user_days;
  wire [ 3:0] user_months;
  wire [ 5:0] user_years;
  wire [ 4:0] user_hours;
  wire [ 5:0] user_minutes;
  wire [ 5:0] user_seconds;

  wire [ 3:0] stat_year_a;
  wire [ 3:0] stat_year_b;
  wire [ 3:0] stat_year_c;
  wire [ 3:0] stat_year_d;

  wire [ 3:0] stat_month_a;
  wire [ 3:0] stat_month_b;

  wire [ 3:0] stat_day_a;
  wire [ 3:0] stat_day_b;

  wire [ 3:0] stat_hour_a;
  wire [ 3:0] stat_hour_b;

  wire [ 3:0] stat_minute_a;
  wire [ 3:0] stat_minute_b;

  wire [ 3:0] stat_second_a;
  wire [ 3:0] stat_second_b;

  USR_ACCESSE2 i_usr_access (
      .CFGCLK   (  /* not used */),
      .DATA     (user_data),
      .DATAVALID(  /* not used */)
  );

  assign {user_days, user_months, user_years, user_hours, user_minutes, user_seconds} = user_data;

  assign stat_buildtime_0 = {
    stat_year_a,
    stat_year_b,
    stat_year_c,
    stat_year_d,
    stat_month_a,
    stat_month_b,
    stat_day_a,
    stat_day_b
  };

  assign stat_year_a = 4'h2;
  assign stat_year_b = 4'h0;
  assign stat_year_c = (user_years / 10);
  assign stat_year_d = (user_years % 10);

  assign stat_month_a = (user_months / 10);
  assign stat_month_b = (user_months % 10);

  assign stat_day_a = (user_days / 10);
  assign stat_day_b = (user_days % 10);

  assign stat_buildtime_1 = {
    stat_hour_a, stat_hour_b, stat_minute_a, stat_minute_b, stat_second_a, stat_second_b, 8'b0
  };

  assign stat_hour_a = (user_hours / 10);
  assign stat_hour_b = (user_hours % 10);

  assign stat_minute_a = (user_minutes / 10);
  assign stat_minute_b = (user_minutes % 10);

  assign stat_second_a = (user_seconds / 10);
  assign stat_second_b = (user_seconds % 10);

endmodule

`default_nettype wire
