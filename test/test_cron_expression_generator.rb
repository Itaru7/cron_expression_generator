require "cron_expression_generator"
require 'rspec'

RSpec.describe CronExpressionGenerator do

  describe '#initialize' do
    subject { described_class.generate(start_time: start_time, end_time: end_time, interval_minutes: interval_minutes) }

    let(:interval_minutes) { 5 }
    let(:current_time) { Time.current }

    context 'when start_time is grater than end_time' do
      let(:start_time) { current_time.since(1.minute) }
      let(:end_time) { current_time }

      it 'raise error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when start_time is equal to end_time' do
      let(:start_time) { current_time }
      let(:end_time) { current_time }

      it 'should return empty' do
        is_expected.to eq([])
      end
    end
  end

  # The tests ceases for the combination of year, month, day, hour, min
  # Conditions:
  # - year: Cron symbol doesn't have year support, so consider only the same year or difference of +/- 1 year at maximum.
  # - month, day, hour: There are 3 combination patterns.
  #    - same: =
  #    - 1 month/day/hour difference: +1
  #    - more than 2 month/day/hour difference: 2+
  # - min: 4 combination patterns.
  #   For example:
  #     - When start and end time is both at 00. (start: 00 && end: 00)
  #     - When start_min is smaller than end_min. (start: 00 && end: 25)
  #     - When start_min is larger than end_min. (start: 25 && end: 00)
  #     - When start_min and end_min at a random min. (start: 25 && end: 45)
  #
  # It will be 216 patters, calculated by this:
  # 2(year) x 3(month) x 3(day) x 3(hour) x 4(minute) = 216


  describe '#generate' do
    subject do
      described_class.generate(
        start_time: start_time,
        end_time: end_time,
        interval_minutes: interval_minutes
      )
    end

    let(:interval_minutes) { 5 }
    let(:parser) { ActiveSupport::TimeZone['Asia/Tokyo'] }

    context 'when start_year == end_year' do
      context 'when start_months == end_months' do
        context 'when start_day == end_day' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-01 01:00') }
              it 'should return empty' do
                is_expected.to eq([])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-01 01:25') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["0-25/#{interval_minutes} 1 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-01 01:00') }
              it 'should return 1 cron symbol(s)' do
                expect { subject }.to raise_error(ArgumentError)
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-01 01:45') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["25-45/#{interval_minutes} 1 1 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-01 02:00') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-1 1 1 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-01 02:25') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-1 1 1 *", "0-25/#{interval_minutes} 2 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-01 02:00') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-01 02:45') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "0-45/#{interval_minutes} 2 1 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-01 04:00') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-3 1 1 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-01 04:25') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-3 1 1 *", "0-25/#{interval_minutes} 4 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-01 04:00') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-3 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-01 04:45') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-3 1 1 *", "0-45/#{interval_minutes} 4 1 1 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（+1）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-02 01:00') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} 0-0 2 1 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-02 01:25') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} 0-0 2 1 *", "0-25/#{interval_minutes} 1 2 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-02 01:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} 0-0 2 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-02 01:45') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} 0-0 2 1 *", "0-45/#{interval_minutes} 1 2 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-02 02:00') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} 0-1 2 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-02 02:25') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} 0-1 2 1 *", "0-25/#{interval_minutes} 2 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-02 02:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} 0-1 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-02 02:45') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} 0-1 2 1 *", "0-45/#{interval_minutes} 2 2 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-02 04:00') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} 0-3 2 1 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-02 04:25') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} 0-3 2 1 *", "0-25/#{interval_minutes} 4 2 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-02 04:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} 0-3 2 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-02 04:45') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} 0-3 2 1 *", "0-45/#{interval_minutes} 4 2 1 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（2+）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-03 01:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-0 3 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-03 01:25') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-0 3 1 *", "0-25/#{interval_minutes} 1 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-03 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-0 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-03 01:45') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-0 3 1 *", "0-45/#{interval_minutes} 1 3 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-03 02:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-1 3 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-03 02:25') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-1 3 1 *", "0-25/#{interval_minutes} 2 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-03 02:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-1 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-03 02:45') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-1 3 1 *", "0-45/#{interval_minutes} 2 3 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-03 03:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-2 3 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-01-03 03:25') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-2 3 1 *", "0-25/#{interval_minutes} 3 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-03 03:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-2 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-01-03 03:45') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-2 1 *", "*/#{interval_minutes} 0-2 3 1 *", "0-45/#{interval_minutes} 3 3 1 *"])
              end
            end
          end
        end
      end
      context 'when start_months != end_months (+1)' do
        context 'when start_day == end_day' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-01 01:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-0 1 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-01 01:25') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-0 1 2 *", "0-25/#{interval_minutes} 1 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-01 01:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-0 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-01 01:45') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-0 1 2 *", "0-45/#{interval_minutes} 1 1 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-01 02:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-1 1 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-01 02:25') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-1 1 2 *", "0-25/#{interval_minutes} 2 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-01 02:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-1 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-01 02:45') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-1 1 2 *", "0-45/#{interval_minutes} 2 1 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-01 03:00') }
              it 'should return 3 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-2 1 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-01 03:25') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-2 1 2 *", "0-25/#{interval_minutes} 3 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-01 03:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-2 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-01 03:45') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} 0-2 1 2 *", "0-45/#{interval_minutes} 3 1 2 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（+1）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-02 01:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-02 01:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *", "0-25/#{interval_minutes} 1 2 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-02 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-02 01:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *", "0-45/#{interval_minutes} 1 2 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-02 02:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-02 02:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *", "0-25/#{interval_minutes} 2 2 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-02 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-02 02:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *", "0-45/#{interval_minutes} 2 2 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-02 03:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-02 03:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *", "0-25/#{interval_minutes} 3 2 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-02 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-02 03:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *", "0-45/#{interval_minutes} 3 2 2 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（2+）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-03 01:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-03 01:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *", "0-25/#{interval_minutes} 1 3 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-03 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-03 01:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *", "0-45/#{interval_minutes} 1 3 2 *"])
              end
            end
          end

          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-03 02:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-03 02:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *", "0-25/#{interval_minutes} 2 3 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-03 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-03 02:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *", "0-45/#{interval_minutes} 2 3 2 *"])
              end
            end
          end

          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-03 03:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-02-03 03:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *", "0-25/#{interval_minutes} 3 3 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-03 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-02-03 03:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *", "0-45/#{interval_minutes} 3 3 2 *"])
              end
            end
          end
        end
      end
      context 'when start_months != end_months (2+)' do
        context 'when start_day == end_day' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-01 01:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-0 1 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-01 01:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-0 1 3 *", "0-25/#{interval_minutes} 1 1 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-01 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-0 1 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-01 01:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-0 1 3 *", "0-45/#{interval_minutes} 1 1 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-01 02:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-1 1 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-01 02:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-1 1 3 *", "0-25/#{interval_minutes} 2 1 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-01 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-1 1 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-01 02:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-1 1 3 *", "0-45/#{interval_minutes} 2 1 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-01 03:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-2 1 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-01 03:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-2 1 3 *", "0-25/#{interval_minutes} 3 1 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-01 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-2 1 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-01 03:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} 0-2 1 3 *", "0-45/#{interval_minutes} 3 1 3 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（+1）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-02 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-02 01:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *", "0-25/#{interval_minutes} 1 2 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-02 01:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-02 01:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *", "0-45/#{interval_minutes} 1 2 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-02 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-02 02:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *", "0-25/#{interval_minutes} 2 2 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-02 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-02 02:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *", "0-45/#{interval_minutes} 2 2 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-02 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-02 03:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *", "0-25/#{interval_minutes} 3 2 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-02 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-02 03:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *", "0-45/#{interval_minutes} 3 2 3 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（2+）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-03 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-03 01:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *", "0-25/#{interval_minutes} 1 3 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-03 01:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-03 01:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *", "0-45/#{interval_minutes} 1 3 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-03 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-03 02:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *", "0-25/#{interval_minutes} 2 3 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-03 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-03 02:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *", "0-45/#{interval_minutes} 2 3 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-03 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2022-03-03 03:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *", "0-25/#{interval_minutes} 3 3 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-03 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2022-03-03 03:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *", "0-45/#{interval_minutes} 3 3 3 *"])
              end
            end
          end
        end
      end
    end

    context 'when start_year != end_year (+1)' do
      context 'when start_months == end_months' do
        context 'when start_day == end_day' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-01 01:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-0 1 1 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-01 01:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-0 1 1 *", "0-25/#{interval_minutes} 1 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-01 01:00') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-0 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-01 01:45') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-0 1 1 *", "0-45/#{interval_minutes} 1 1 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-01 02:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-1 1 1 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-01 02:25') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-1 1 1 *", "0-25/#{interval_minutes} 2 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-01 02:00') }
              it 'should return 1 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-1 1 1 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-01 02:45') }
              it 'should return 2 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-1 1 1 *", "0-45/#{interval_minutes} 2 1 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-01 03:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-2 1 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-01 03:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-2 1 1 *", "0-25/#{interval_minutes} 3 1 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-01 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-2 1 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-01 03:45') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} 0-2 1 1 *", "0-45/#{interval_minutes} 3 1 1 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（+1）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-02 01:00') }
              it 'should return 4 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-0 2 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-02 01:25') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-0 2 1 *", "0-25/#{interval_minutes} 1 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-02 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-0 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-02 01:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-0 2 1 *", "0-45/#{interval_minutes} 1 2 1 *"])
              end
            end
          end

          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-02 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-1 2 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-02 02:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-1 2 1 *", "0-25/#{interval_minutes} 2 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-02 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-1 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-02 02:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-1 2 1 *", "0-45/#{interval_minutes} 2 2 1 *"])
              end
            end
          end

          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-02 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-2 2 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-02 03:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-2 2 1 *", "0-25/#{interval_minutes} 3 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-02 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-2 2 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-02 03:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-1 1 *", "*/#{interval_minutes} 0-2 2 1 *", "0-45/#{interval_minutes} 3 2 1 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（2+）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-03 01:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-0 3 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-03 01:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-0 3 1 *", "0-25/#{interval_minutes} 1 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-03 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-0 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-03 01:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-0 3 1 *", "0-45/#{interval_minutes} 1 3 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-03 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-1 3 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-03 02:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-1 3 1 *", "0-25/#{interval_minutes} 2 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-03 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-1 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-03 02:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-1 3 1 *", "0-45/#{interval_minutes} 2 3 1 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-03 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-2 3 1 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-01-03 03:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-2 3 1 *", "0-25/#{interval_minutes} 3 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-03 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-2 3 1 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-01-03 03:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * 1-2 1 *", "*/#{interval_minutes} 0-2 3 1 *", "0-45/#{interval_minutes} 3 3 1 *"])
              end
            end
          end
        end
      end
      context 'when start_months != end_months (+1)' do
        context 'when start_day == end_day' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-01 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-0 1 2 *"])
              end
            end

            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-01 01:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-0 1 2 *", "0-25/#{interval_minutes} 1 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-01 01:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-0 1 2 *"])
              end
            end

            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-01 01:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-0 1 2 *", "0-45/#{interval_minutes} 1 1 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-01 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-1 1 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-01 02:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-1 1 2 *", "0-25/#{interval_minutes} 2 1 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-01 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-1 1 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-01 02:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-1 1 2 *", "0-45/#{interval_minutes} 2 1 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-01 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-2 1 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-01 03:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-2 1 2 *", "0-25/#{interval_minutes} 3 1 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-01 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-2 1 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-01 03:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} 0-2 1 2 *", "0-45/#{interval_minutes} 3 1 2 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（+1）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-02 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-02 01:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *", "0-25/#{interval_minutes} 1 2 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-02 01:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-02 01:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-0 2 2 *", "0-45/#{interval_minutes} 1 2 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-02 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-02 02:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *", "0-25/#{interval_minutes} 2 2 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-02 02:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-02 02:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-1 2 2 *", "0-45/#{interval_minutes} 2 2 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-02 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-02 03:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *", "0-25/#{interval_minutes} 3 2 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-02 03:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-02 03:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-1 2 *", "*/#{interval_minutes} 0-2 2 2 *", "0-45/#{interval_minutes} 3 2 2 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（2+）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-03 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-03 01:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *", "0-25/#{interval_minutes} 1 3 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-03 01:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-03 01:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-0 3 2 *", "0-45/#{interval_minutes} 1 3 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-03 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-03 02:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *", "0-25/#{interval_minutes} 2 3 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-03 02:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-03 02:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-1 3 2 *", "0-45/#{interval_minutes} 2 3 2 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-03 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-02-03 03:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *", "0-25/#{interval_minutes} 3 3 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-03 03:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-02-03 03:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-1 *", "*/#{interval_minutes} * 1-2 2 *", "*/#{interval_minutes} 0-2 3 2 *", "0-45/#{interval_minutes} 3 3 2 *"])
              end
            end
          end
        end
      end
      context 'when start_months != end_months (2+)' do
        context 'when start_day == end_day' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-01 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-0 1 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-01 01:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-0 1 3 *", "0-25/#{interval_minutes} 1 1 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-01 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-0 1 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-01 01:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-0 1 3 *", "0-45/#{interval_minutes} 1 1 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-01 02:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-1 1 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-01 02:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-1 1 3 *", "0-25/#{interval_minutes} 2 1 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-01 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-1 1 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-01 02:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-1 1 3 *", "0-45/#{interval_minutes} 2 1 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-01 03:00') }
              it 'should return 5 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-2 1 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-01 03:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-2 1 3 *", "0-25/#{interval_minutes} 3 1 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-01 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-2 1 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-01 03:45') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} 0-2 1 3 *", "0-45/#{interval_minutes} 3 1 3 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（+1）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-02 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-02 01:25') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *", "0-25/#{interval_minutes} 1 2 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-02 01:00') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-02 01:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-0 2 3 *", "0-45/#{interval_minutes} 1 2 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-02 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-02 02:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *", "0-25/#{interval_minutes} 2 2 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-02 02:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-02 02:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-1 2 3 *", "0-45/#{interval_minutes} 2 2 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-02 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-02 03:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *", "0-25/#{interval_minutes} 3 2 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-02 03:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-02 03:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-1 3 *", "*/#{interval_minutes} 0-2 2 3 *", "0-45/#{interval_minutes} 3 2 3 *"])
              end
            end
          end
        end
        context 'when start_day != end_day（2+）' do
          context 'when start_hour == end_hour' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-03 01:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-03 01:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *", "0-25/#{interval_minutes} 1 3 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-03 01:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-03 01:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-0 3 3 *", "0-45/#{interval_minutes} 1 3 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (+1)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-03 02:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-03 02:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *", "0-25/#{interval_minutes} 2 3 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-03 02:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-03 02:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-1 3 3 *", "0-45/#{interval_minutes} 2 3 3 *"])
              end
            end
          end
          context 'when start_hour != end_hour (2+)' do
            context 'when start_minutes == 00, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-03 03:00') }
              it 'should return 6 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *"])
              end
            end
            context 'when start_minutes == 00, end_minutes == 25' do
              let(:start_time) { parser.parse('2022-01-01 01:00') }
              let(:end_time) { parser.parse('2023-03-03 03:25') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["*/#{interval_minutes} 1-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *", "0-25/#{interval_minutes} 3 3 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 00' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-03 03:00') }
              it 'should return 7 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *"])
              end
            end
            context 'when start_minutes == 25, end_minutes == 45' do
              let(:start_time) { parser.parse('2022-01-01 01:25') }
              let(:end_time) { parser.parse('2023-03-03 03:45') }
              it 'should return 8 cron symbol(s)' do
                is_expected.to eq(["25-59/#{interval_minutes} 1 1 1 *", "*/#{interval_minutes} 2-23 1 1 *", "*/#{interval_minutes} * 2-31 1 *", "*/#{interval_minutes} * * 2-12 *", "*/#{interval_minutes} * * 1-2 *", "*/#{interval_minutes} * 1-2 3 *", "*/#{interval_minutes} 0-2 3 3 *", "0-45/#{interval_minutes} 3 3 3 *"])
              end
            end
          end
        end
      end
    end
  end
end
