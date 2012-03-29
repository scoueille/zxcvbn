
ranked_user_inputs_dict = {}

# initialize matcher lists
DICTIONARY_MATCHERS = [
  build_dict_matcher('passwords', build_ranked_dict(passwords)),
  build_dict_matcher('male_names', build_ranked_dict(male_names)),
  build_dict_matcher('female_names', build_ranked_dict(female_names)),
  build_dict_matcher('surnames', build_ranked_dict(surnames)),
  build_dict_matcher('words', build_ranked_dict(english)),
  build_dict_matcher('user_inputs', ranked_user_inputs_dict),
]

MATCHERS = DICTIONARY_MATCHERS.concat [
  l33t_match,
  digits_match, year_match, date_match,
  repeat_match, sequence_match,
  spatial_match
]

GRAPHS =
  'qwerty': qwerty
  'dvorak': dvorak
  'keypad': keypad
  'mac_keypad': mac_keypad

time = -> (new Date()).getTime()

# now that frequency lists are loaded, replace zxcvbn stub function.
window.zxcvbn = (password, user_inputs) ->
  start = time()
  if user_inputs?
    for i in [0...user_inputs.length]
      # update ranked_user_inputs_dict.
      # i+1 instead of i b/c rank starts at 1.
      ranked_user_inputs_dict[user_inputs[i]] = i + 1
  matches = omnimatch password
  result = minimum_entropy_match_sequence password, matches
  result.calc_time = time() - start
  result

zxcvbn_load_hook?() # run load hook from user, if defined