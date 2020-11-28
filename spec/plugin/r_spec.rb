require 'spec_helper'

describe "r" do
  # TODO:
  #   I don't have any background in ruby, so I'll try to my best to articulate
  #   some tests and hopefully someone with some ruby background can pitch in.
  #
  #
  # # sj#r#SplitFuncall() with named args
  #   given text and issuing split:
  #     
  #     print(1, 2, 3)
  #           ^ normal! gS
  #
  #
  #   expect the following (indentation may be altered by global vim R
  #   indentation setting `g:r_indent_align_args`):
  #     
  #     # if `let g:r_indent_align_args = 0`
  #     print(
  #       1,
  #       a = 2,
  #       3
  #     )
  #
  #     # if `let g:r_indent_align_args = 1`
  #     print(1,
  #           a = 2,
  #           3)
  #
  #
  # # sj#r#SplitFuncall() with nested calls
  #   given text and issuing split:
  #     
  #     print(1, c(1, 2, 3), 3)
  #           ^ normal! gS
  #
  #   expect output:
  #
  #     # if `let g:r_indent_align_args = 0`
  #     print(
  #       1,
  #       c(1, 2, 3),
  #       3
  #     )
  #
  #     # if `let g:r_indent_align_args = 1`
  #     print(1,
  #           c(1, 2, 3),
  #           3)
  #
  #
  # # sj#r#SplitFuncall() on a nested call function name should behave similarly
  # # as the outer parenthesis 
  #   given text and issuing split:
  #     
  #     print(1, c(1, 2, 3), 3)
  #              ^ normal! gS
  #
  #   expect output:
  #
  #     # if `let g:r_indent_align_args = 0`
  #     print(
  #       1,
  #       c(1, 2, 3),
  #       3
  #     )
  #
  #     # if `let g:r_indent_align_args = 1`
  #     print(1,
  #           c(1, 2, 3),
  #           3)
  #
  #
  # # sj#r#SplitFuncall() on a nested call function args should split inner
  # # function args
  #   given text and issuing split:
  #
  #     print(1, c(1, 2, 3), 3)
  #                ^ normal! gS
  #
  #   expect output:
  #
  #     # if `let g:r_indent_align_args = 0`
  #     print(1, c(
  #         1, 
  #         2, 
  #         3
  #         ), 3)
  #
  #     # if `let g:r_indent_align_args = 1`
  #     print(1, c(1, 
  #                2, 
  #                3), 3)
  #
  # # sj#r#JoinFuncall() on a function call should join function args
  #   given text and issuing join:
  #
  #     print(
  #       1, 
  #       2, # <- normal! gJ
  #       3
  #     )
  #
  #   expect output:
  #
  #     print(1, 2, 3)
  #
  #
  # # sj#r#JoinFuncall() on a nested call function args should join inner
  # # function args
  #   given text and issuing join:
  #
  #     print(
  #       1, 
  #       c(
  #         1, 
  #         2, # <- normal! gJ
  #         3
  #         ), 
  #       3
  #     )
  #
  #   expect output:
  #
  #     print(
  #       1, 
  #       c(1, 2, 3), 
  #       3
  #     )
  #
end
