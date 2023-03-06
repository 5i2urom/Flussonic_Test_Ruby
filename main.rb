# frozen_string_literal: true

require 'date'

# PeriodsChain Class
class PeriodsChain
  attr_reader :start_date, :periods, :curr_last

  private :curr_last

  def initialize(start_date, periods)
    @start_date = Date.parse(start_date)
    @periods = periods
  end

  def valid?
    shift = @start_date.day # изначальный сдвиг
    @curr_last = @start_date.clone
    @periods.each do |per|
      do_shift = true
      date_per = if per.include?('D') # daily
                   do_shift = false # для daily сдвиг не нужен
                   date = daily(per)
                   shift = date.last.day # daily изменил значение сдвига
                   date
                 elsif per.include?('M') # monthly
                   monthly(per)
                 else # annualy
                   annualy(per).map! { |bound| bound >> @curr_last.month - 1 } # месячный сдвиг для annualy
                 end
      if do_shift
        date_per.map! do |bound| # выполняем сдвиг
          buf = bound + shift - 1
          buf = Date.new(bound.year, bound.month, -1) if buf.month != bound.month # при выходе за границы месяца
          bound = buf
        end
      end
      return false if date_per.first != @curr_last

      @curr_last = date_per.last
    end
    true
  end

  def add(period_type)
    return unless valid?

    new_period = case period_type
                 when 'daily'
                   "#{@curr_last.year}M#{@curr_last.month}D#{@curr_last.day}"
                 when 'monthly'
                   "#{@curr_last.year}M#{@curr_last.month}"
                 when 'annually'
                   @curr_last.year.to_s
                 end
    @periods.push(new_period) if defined? new_period
  end

  private

  def daily(per)
    @year = per.slice(0..3)
    @month = per.slice(/M(.*)D/, 1)
    @day = per.slice(/D(.*)/, 1)
    date1 = Date.parse("#{@year}-#{@month}-#{@day}")
    date2 = date1.next
    [date1, date2]
  end

  def monthly(per)
    @year = per.slice(0..3)
    @month = per.slice(/M(.*)/, 1)
    @day = 1
    date1 = Date.parse("#{@year}-#{@month}-#{@day}")
    date2 = date1 >> 1 # + месяц
    [date1, date2]
  end

  def annualy(per)
    @year = per.slice(0..3)
    @month = 1
    @day = 1
    date1 = Date.parse("#{@year}-#{@month}-#{@day}")
    date2 = date1 >> 12 # + год
    [date1, date2]
  end
end
