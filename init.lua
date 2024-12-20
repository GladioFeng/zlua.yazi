local state = ya.sync(function()
	return cx.active.current.cwd
end)

local function fail(s, ...)
	ya.notify({ title = "Fzf", content = string.format(s, ...), timeout = 5, level = "error" })
end

local cmd_args =
	[[eval "$(lua ~/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-skywind3000-SLASH-z.lua/z.lua --init zsh enhanced)"; _zlua -l -t | awk '{print $2}' | sed -e "s,^$HOME,~," | fzf --bind 'ctrl-y:execute-silent(echo -E {} | osc-copy -n)+abort,tab:accept,ctrl-r:toggle-sort' --reverse --inline-info +s --tac --height 100% ]]

local function entry()
	local _permit = ya.hide()
	local cwd = tostring(state())

	local child, err = Command("zsh")
		:args({ "-c", cmd_args })
		:cwd(cwd)
		:env("_ZL_HYPHEN", 1)
		:env("_ZL_ADD_ONCE", 0)
		:env("_ZL_EXCLUDE_DIRS", "/home/fengzerong/github/czmod,/home/fengzerong,/mnt")
		:stdin(Command.INHERIT)
		:stdout(Command.PIPED)
		:stderr(Command.INHERIT)
		:spawn()

	if not child then
		return fail("Failed to start `fzf`, error: " .. err)
	end

	local output, err = child:wait_with_output()
	if not output then
		return fail("Cannot read `fzf` output, error: " .. err)
	elseif not output.status.success and output.status.code ~= 130 then
		return fail("`fzf` exited with error code %s", output.status.code)
	end

	local target = output.stdout:gsub("\n$", "")
	local target = target .. "/"

	if target ~= "" then
		ya.manager_emit(target:find("[/\\]$") and "cd" or "reveal", { target })
	end
end

return { entry = entry }
