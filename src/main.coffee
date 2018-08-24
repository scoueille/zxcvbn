matching = require './matching'
scoring = require './scoring'
time_estimates = require './time_estimates'
feedback = require './feedback'

time = -> (new Date()).getTime()

zxcvbn = (password, options = {}) ->
  user_inputs = []
  feedback_messages = {}
  feedback_language = 'fr'
  if options instanceof Array
    user_inputs = options # backward-compatibility
  else
    user_inputs = options.user_inputs if options.user_inputs
    feedback_messages = options.feedback_messages if options.feedback_messages
    feedback_language = options.feedback_language if options.feedback_language

  start = time()
  # reset the user inputs matcher on a per-request basis to keep things stateless
  sanitized_inputs = []
  for arg in user_inputs
    if typeof arg in ["string", "number", "boolean"]
      sanitized_inputs.push arg.toString().toLowerCase()
  matching.set_user_input_dictionary sanitized_inputs
  matches = matching.omnimatch password
  result = scoring.most_guessable_match_sequence password, matches
  result.calc_time = time() - start
  attack_times = time_estimates.estimate_attack_times result.guesses, result.complexity, feedback_language
  for prop, val of attack_times
    result[prop] = val
  result.feedback = feedback.get_feedback result.score, result.complexity, result.sequence, feedback_messages, feedback_language
  result

module.exports = zxcvbn
