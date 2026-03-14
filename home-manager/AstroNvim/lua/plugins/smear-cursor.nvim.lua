-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize smear-cursor.nvim

-- @type LazySpec

return {
  "sphamba/smear-cursor.nvim",
  opts = {
    -- Smear cursor when switching buffers or windows.
    smear_between_buffers = true,

    -- Smear cursor when moving within line or to neighbor lines.
    smear_between_neighbor_lines = true,

    -- Draw the smear in buffer space instead of screen space when scrolling
    scroll_buffer_space = true,

    -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
    -- Smears will blend better on all backgrounds.
    legacy_computing_symbols_support = false,

    stiffness = 1,
    trailing_stiffness = 0.2,
    trailing_exponent = 2,
    slowdown_exponent = -0.1,
    distance_stop_animating = 0.5,
    hide_target_hack = false,
    time_interval = 3,
    max_slope_horizontal = 0.5,
    min_slope_vertical = 2,
    cursor_color = "#d3cdc3",
    gamma = 5,
    max_shade_no_matrix = 0.75,
    matrix_pixel_threshold = 0,
    matrix_pixel_min_factor = 0,
    volume_reduction_exponent = 1,
    minimum_volume_factor = 0,
    max_length = 50,
    --
    vertical_bar_cursor = false,
  },
}
