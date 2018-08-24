scoring = require('./scoring')
feedback_i18n = require('./feedback_i18n')

feedback =
  get_feedback: (score, complexity, sequence, custom_messages, language = "en") ->
    @custom_messages = custom_messages

    @messages = feedback_i18n.en
    if (language && language of feedback_i18n)
      @messages = feedback_i18n[language]

    # starting feedback
    return if sequence.length == 0
      @build_feedback(null, ['use_a_few_words', 'use_mixed_chars'])

    extra_feedback = []
    if (complexity.mixedChars < 3 or complexity.length < 8 )
      extra_feedback.push 'use_mixed_chars'

    # no feedback if score is good or great.
    return if score > 2
      @build_feedback(null, extra_feedback)

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    if(extra_feedback.length == 0)
      extra_feedback.push 'uncommon_words_are_better'
    if feedback?
      @build_feedback(feedback.warning, extra_feedback.concat feedback.suggestions)
    else
      @build_feedback(null, extra_feedback)

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'straight_rows_of_keys_are_easy'
        else
          'short_keyboard_patterns_are_easy'
        warning: warning
        suggestions: [
          'use_longer_keyboard_patterns'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'repeated_chars_are_easy'
        else
          'repeated_patterns_are_easy'
        warning: warning
        suggestions: [
          'avoid_repeated_chars'
        ]

      when 'sequence'
        warning: "sequences_are_easy"
        suggestions: [
          'avoid_sequences'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "recent_years_are_easy"
          suggestions: [
            'avoid_recent_years'
            'avoid_associated_years'
          ]

      when 'date'
        warning: "dates_are_easy"
        suggestions: [
          'avoid_associated_dates_and_years'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'top10_common_password'
        else if match.rank <= 100
          'top100_common_password'
        else
          'very_common_password'
      else if match.guesses_log10 <= 4
        'similar_to_common_password'
    else if match.dictionary_name in ['english_wikipedia', 'french_edusol']
      if is_sole_match
        'a_word_is_easy'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names', 'french_names']
      if is_sole_match
        'names_are_easy'
      else
        'common_names_are_easy'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "capitalization_doesnt_help"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "all_uppercase_doesnt_help"

    if match.reversed and match.token.length >= 4
      suggestions.push "reverse_doesnt_help"
    if match.l33t
      suggestions.push "substitution_doesnt_help"

    result =
      warning: warning
      suggestions: suggestions
    result
  
  get_message: (key) ->
    if @custom_messages? and key of @custom_messages
        @custom_messages[key] or ''
    else if @messages[key]?
      @messages[key]
    else
      throw new Error("unknown message: #{key}")

  build_feedback: (warning_key = null, suggestion_keys = []) ->
    suggestions = []
    for suggestion_key in suggestion_keys
      message = @get_message(suggestion_key)
      suggestions.push message if message? and message != ''
    feedback =
      warning: if warning_key then @get_message(warning_key) else ''
      suggestions: suggestions
    feedback

module.exports = feedback
