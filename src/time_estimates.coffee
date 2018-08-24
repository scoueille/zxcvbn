time_estimates_i18n = require('./time_estimates_i18n')

time_estimates =
  estimate_attack_times: (guesses, complexity, language = "en") ->
    crack_times_seconds =
      online_throttling_100_per_hour: guesses / (100 / 3600)
      online_no_throttling_10_per_second: guesses / 10
      offline_slow_hashing_1e4_per_second: guesses / 1e4
      offline_fast_hashing_1e10_per_second: guesses / 1e10

    crack_times_display = {}
    for scenario, seconds of crack_times_seconds
      crack_times_display[scenario] = @display_time seconds, language

    crack_times_seconds: crack_times_seconds
    crack_times_display: crack_times_display
    score: @guesses_to_score guesses, complexity


  guesses_to_score: (guesses, complexity) ->
    DELTA = 5
    if guesses < 1e3 + DELTA
      # risky password: "too guessable"
      0
    else if guesses < 1e6 + DELTA
      # modest protection from throttled online attacks: "very guessable"
      1
    else if guesses < 1e8 + DELTA or complexity.mixedChars < 3 or complexity.length < 8
      # modest protection from unthrottled online attacks: "somewhat guessable"
      2
    else if guesses < 1e10 + DELTA
      # modest protection from offline attacks: "safely unguessable"
      # assuming a salted, slow hash function like bcrypt, scrypt, PBKDF2, argon, etc
      3
    else
      # strong protection from offline attacks under same scenario: "very unguessable"
      4

  display_time: (seconds, language) ->
    @messages = time_estimates_i18n.en
    if (language && language of time_estimates_i18n)
      @messages = time_estimates_i18n[language]

    minute = 60
    hour = minute * 60
    day = hour * 24
    month = day * 31
    year = month * 12
    century = year * 100
    [display_num, display_str] = if seconds < 1
      [null, @get_message(null, 'less_a_second')]
    else if seconds < minute
      base = Math.round seconds
      [base, @get_message(base, "second")]
    else if seconds < hour
      base = Math.round seconds / minute
      [base, @get_message(base, "minute")]
    else if seconds < day
      base = Math.round seconds / hour
      [base, @get_message(base, "hour")]
    else if seconds < month
      base = Math.round seconds / day
      [base, @get_message(base, "day")]
    else if seconds < year
      base = Math.round seconds / month
      [base, @get_message(base, "month")]
    else if seconds < century
      base = Math.round seconds / year
      [base, @get_message(base, "year")]
    else
      [null, @get_message(null, 'centuries')]
    display_str

  get_message: (base, key) ->
    if not base? 
      @messages[key]
    else if base == 1 and @messages[key]?
      @messages[key].replace /%1%/, base
    else if base > 1 and @messages[key]?
      @messages[key.concat '_n'].replace /%1%/, base
    else
      throw new Error("unknown message: #{key}")

module.exports = time_estimates
