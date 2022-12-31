require 'date'
require 'active_support'
require 'active_support/core_ext'

class CronExpressionGenerator
  def self.generate(start_time:, end_time:, interval_minutes:)
    @start_time = start_time
    @end_time = end_time
    @interval_minutes = interval_minutes

    self.validate_parameters
    self.initialize

    cron_expressions = []
    if @count_up_time == @terminate_time
      return cron_expressions # return empty if no time difference
    end
    @datetime_unit_to_match = self.get_largest_datetime_unit_diff
    cron_expressions = self.match_largest_datetime_unit
    cron_expressions += self.match_remaining_datetime
    cron_expressions
  end

  private # --------------------------------------------------------

  def self.initialize
    if @start_time > @end_time
      message = "start_time is larger than end_time.\n"
      message += "given, start_time: #{@start_time}, end_time: #{@end_time}"
      raise ArgumentError, message
    end

    @min     = 'min'
    @hour    = 'hour'
    @day     = 'day'
    @month   = 'month'
    @year    = 'year'

    @count_up_time = @start_time
    @terminate_time = @end_time
    @interval_minutes = @interval_minutes
  end

  def self.validate_parameters
    if @start_time.nil? || @end_time.nil? || @interval_minutes.nil?
      raise "Parameters are not satisfied.\nCommand in this format: $ cron_expression_generator <start_datetime> <end_datetime> <interval_minutes> \nCommand is like this:\n$ cron_expression_generator \"2022-12-31 00:000\" \"2023-01-01 23:59\" 5"
    end

    begin
      @start_time = DateTime.parse(@start_time) if @start_time.is_a?(String)
      @end_time = DateTime.parse(@end_time) if @end_time.is_a?(String)
    rescue
      raise "Invalid given date format in String. Please pass the string in this format: YYYY-MM-DD HH:MM"
    end
  end

  def self.carry_up_minutes_cron
    "#{@count_up_time.min}-59/#{@interval_minutes} #{@count_up_time.hour} #{@count_up_time.day} #{@count_up_time.month} *"
  end

  def self.carry_up_hour_cron
    "*/#{@interval_minutes} #{@count_up_time.hour}-23 #{@count_up_time.day} #{@count_up_time.month} *"
  end

  def self.carry_up_day_cron(last_day_of_month)
    "*/#{@interval_minutes} * #{@count_up_time.day}-#{last_day_of_month} #{@count_up_time.month} *"
  end

  def self.carry_up_months_cron
    "*/#{@interval_minutes} * * #{@count_up_time.month}-12 *"
  end

  def self.match_minutes_cron
    "#{@count_up_time.min}-#{@terminate_time.min}/#{@interval_minutes} #{@terminate_time.hour} #{@terminate_time.day} #{@terminate_time.month} *"
  end

  def self.match_hour_cron
    "*/#{@interval_minutes} #{@count_up_time.hour}-#{@terminate_time.hour.to_i - 1} #{@terminate_time.day} #{@terminate_time.month} *"
  end

  def self.match_day_cron
    "*/#{@interval_minutes} * #{@count_up_time.day}-#{@terminate_time.day.to_i - 1} #{@terminate_time.month.to_i} *"
  end

  def self.match_months_cron
    "*/#{@interval_minutes} * * #{@count_up_time.month}-#{@terminate_time.month.to_i - 1} *"
  end

  def self.get_largest_datetime_unit_diff
    if @count_up_time.year != @terminate_time.year
      @year
    elsif @count_up_time.month != @terminate_time.month
      @month
    elsif @count_up_time.day != @terminate_time.day
      @day
    elsif @count_up_time.hour != @terminate_time.hour
      @hour
    elsif @count_up_time.min != @terminate_time.min
      @min
    else
      message = "Unexpected value received to time_at & terminate_time_at.\n"
      message += "given, count_up_time: #{@count_up_time}, terminate_time: #{@terminate_time}"
      raise ArgumentError, message
    end
  end

  def self.minutes_is_carried_up?
    @datetime_unit_to_match != @min && @count_up_time.min != 0
  end

  def self.hour_is_carried_up?
    @datetime_unit_to_match != @min && @datetime_unit_to_match != @hour && @count_up_time.hour != 0
  end

  def self.day_is_carried_up?
    @datetime_unit_to_match != @min && @datetime_unit_to_match != @hour && @datetime_unit_to_match != @day && @count_up_time.day != 1
  end

  def self.months_is_carried_up?
    @datetime_unit_to_match != @min && @datetime_unit_to_match != @hour && @datetime_unit_to_match != @day && @datetime_unit_to_match != @month && @count_up_time.month != 1
  end

  def self.minutes_is_matched?
    @count_up_time.min == @terminate_time.min
  end

  def self.hour_is_matched?
    @count_up_time.hour == @terminate_time.hour
  end

  def self.day_is_matched?
    @count_up_time.day == @terminate_time.day
  end

  def self.months_is_matched?
    @count_up_time.month == @terminate_time.month
  end

  def self.carry_up_time(time:, unit:)
    if unit == @min
      @count_up_time += time.minute
    elsif unit == @hour
      @count_up_time += time.hour
    elsif unit == @day
      @count_up_time += time.day
    elsif unit == @month
      @count_up_time += time.month
    else
      message = "Unexpected value passed to received to unit.\n"
      message += "given, unit: #{unit}"
      raise ArgumentError, message
    end
  end

  def self.match_largest_datetime_unit
    cron_expressions = []

    # minutes
    if self.minutes_is_carried_up?
      cron_expressions.append(self.carry_up_minutes_cron)
      remaining_minutes = 60 - @count_up_time.min.to_i
      self.carry_up_time(time: remaining_minutes, unit: @min)
    end
    # hour
    if self.hour_is_carried_up?
      cron_expressions.append(self.carry_up_hour_cron)
      remaining_hours = 24 - @count_up_time.hour.to_i
      self.carry_up_time(time: remaining_hours, unit: @hour)
    end
    # day
    if self.day_is_carried_up?
      last_day_of_month = @count_up_time.end_of_month.strftime('%d').to_i
      cron_expressions.append(self.carry_up_day_cron(last_day_of_month))
      remaining_days = last_day_of_month - @count_up_time.day.to_i + 1
      self.carry_up_time(time: remaining_days, unit: @day)
    end
    # months
    if self.months_is_carried_up?
      cron_expressions.append(self.carry_up_months_cron)
      remaining_months = 12 - @count_up_time.month.to_i + 1
      self.carry_up_time(time: remaining_months, unit: @month)
    end

    cron_expressions
  end

  def self.match_remaining_datetime
    cron_expressions = []
    cron_expressions.append(self.match_months_cron)  unless self.months_is_matched?
    cron_expressions.append(self.match_day_cron)     unless self.day_is_matched?
    cron_expressions.append(self.match_hour_cron)    unless self.hour_is_matched?
    cron_expressions.append(self.match_minutes_cron) unless self.minutes_is_matched?
    cron_expressions
  end
end
