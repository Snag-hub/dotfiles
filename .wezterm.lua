local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

---------------------------------------------------------
-- 🪄 Appearance
---------------------------------------------------------
config.font = wezterm.font("CaskaydiaCove Nerd Font")
config.font_size = 11.0
config.color_scheme = "Catppuccin Mocha"

-- Transparent + blur background
config.window_background_opacity = 0.90
config.macos_window_background_blur = 20
config.win32_system_backdrop = "Acrylic" -- Windows 11 glass-like blur

-- Layout & UI look
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.window_padding = {
	left = 6,
	right = 6,
	top = 4,
	bottom = 0,
}
config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.6,
}

-- Cursor & visuals
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600
config.animation_fps = 60
config.enable_scroll_bar = false
config.audible_bell = "Disabled"

---------------------------------------------------------
-- ⚡ Leader Key
---------------------------------------------------------
config.leader = { key = "CapsLock", mods = "NONE", timeout_milliseconds = 1000 }

---------------------------------------------------------
-- 🧠 Key Bindings
---------------------------------------------------------
config.keys = {
	-- Pane management
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = "TogglePaneZoomState" },

	-- Tab management
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "n", mods = "LEADER", action = act.SpawnWindow },

	-- Navigation
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- Resize panes
	{ key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- Tabs: Leader + 1–9
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },

	-- Misc
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
	{ key = "Enter", mods = "LEADER", action = "ActivateCopyMode" },

	-- Fullscreen toggle
	{ key = "F11", mods = "NONE", action = "ToggleFullScreen" },
}

---------------------------------------------------------
-- 🪟 Windows Specific
---------------------------------------------------------
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.default_prog = { "pwsh.exe", "-NoLogo", "-NoExit" }
end

---------------------------------------------------------
-- 🎨 Minimal tab title formatter
---------------------------------------------------------
wezterm.on("format-tab-title", function(tab)
	local title = tab.active_pane.title
	if tab.is_active then
		return { { Text = "  " .. title .. " " } }
	else
		return { { Text = "  " .. title .. " " } }
	end
end)

---------------------------------------------------------
-- 🧩 Status bar (right side)
---------------------------------------------------------
wezterm.on("update-right-status", function(window, pane)
	local date = wezterm.strftime(" %H:%M ")
	local cwd_uri = pane:get_current_working_dir()
	local cwd = ""
	if cwd_uri then
		cwd = string.gsub(cwd_uri.file_path, "(.*)/", "")
	end
	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#89B4FA" } },
		{ Text = " " .. cwd .. "  " .. date },
	}))
end)

return config
