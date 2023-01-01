# cron_expression_generator

[cron_expression_generator @rubygems.org](https://rubygems.org/gems/cron_expression_generator)

## About

> A **gem** to generates a set of cron expression(s) to satisfy the range of **2** given `start_datetime` and `end_datetime` and `interval minutes`.

## Table of Contents

- [About](#about)
- [Table of Contents](#table-of-contents)
- [Installation](#installation)
- [Usage](#usage)
- [Constraints](#constraints)
- [License](#license)

## Installation

Instal Gem

``` shell
$ gem install cron_expression_generator
Successfully installed cron_expression_generator-1.0.0
1 gem installed
```

Or add to your `Gemfile` and run `bundle install`:

``` ruby
gem "cron_expression_generator"
```

## Usage

In code

``` ruby
require "cron_expression_generator"

# with example datetime
CronExpressionGenerator.generate(start_time: "2022-12-31 00:000", end_time:"2023-01-01 23:59", interval_minutes: 5)
```

In Terminal

```shell
$ cron_expression_generator <start_datetime> <end_datetime> <interval_minutes>

# with example datetime
$ cron_expression_generator "2022-12-31 00:000" "2023-01-01 23:59" 5
*/ * 31-31 12 *
*/ 0-22 1 1 *
0-59/ 23 1 1 *
```

## Constraints

- No more than 1 year range
- Currently only support interval of minutes

## License

[License](https://github.com/Itaru7/cron_expression_generator/blob/main/LICENSE)
