local M = {}

local defaults = {
  model = "qwen2.5-coder:0.5b-base-q4_K_M",
  endpoint = "http://127.0.0.1:11434/api/generate",
  debounce_ms = 350,
  prefix_chars = 12000,
  suffix_chars = 4000,
  max_buffer_bytes = 1024 * 1024,
  max_lines = 20,
  num_predict = 96,
  keep_alive = "10m",
}

local config = vim.deepcopy(defaults)
local namespace = vim.api.nvim_create_namespace "local_completion"
local states = {}
local stopped_projects = {}
local error_was_reported = false

local excluded_filetypes = {
  [""] = true,
  TelescopePrompt = true,
  checkhealth = true,
  gitcommit = true,
  help = true,
  lazy = true,
  man = true,
  mason = true,
  netrw = true,
  notify = true,
  qf = true,
}

local function state_for(buf)
  states[buf] = states[buf] or {
    request_id = 0,
    suggestion = nil,
    process = nil,
    last_error = nil,
  }
  return states[buf]
end

local function clear(buf, cancel_request)
  if not vim.api.nvim_buf_is_valid(buf) then
    states[buf] = nil
    return
  end

  local state = state_for(buf)
  state.suggestion = nil
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)

  if cancel_request then
    state.request_id = state.request_id + 1
    if state.process then
      pcall(state.process.kill, state.process, 15)
      state.process = nil
    end
  end
end

local function is_sensitive_path(path)
  local name = vim.fs.basename(path):lower()
  return name:match "^%.env" ~= nil
    or name:match "credential" ~= nil
    or name:match "secret" ~= nil
    or name:match "^id_[er][cds][a-z0-9_]*" ~= nil
    or name:match "%.pem$" ~= nil
    or name:match "%.key$" ~= nil
end

local function project_root(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local root = path ~= "" and vim.fs.root(path, ".git") or nil
  return vim.fs.normalize(root or vim.fn.getcwd())
end

local function buffer_is_eligible(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modifiable then
    return false
  end

  if stopped_projects[project_root(buf)] then
    return false
  end

  if vim.bo[buf].buftype ~= "" or excluded_filetypes[vim.bo[buf].filetype] then
    return false
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path ~= "" and is_sensitive_path(path) then
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  return vim.api.nvim_buf_get_offset(buf, line_count) <= config.max_buffer_bytes
end

local function context_at_cursor(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local current = lines[row] or ""

  local before = vim.list_slice(lines, 1, row - 1)
  before[#before + 1] = current:sub(1, col)

  local after = { current:sub(col + 1) }
  vim.list_extend(after, vim.list_slice(lines, row + 1))

  local prefix = table.concat(before, "\n")
  local suffix = table.concat(after, "\n")

  if #prefix > config.prefix_chars then
    prefix = prefix:sub(#prefix - config.prefix_chars + 1)
  end
  if #suffix > config.suffix_chars then
    suffix = suffix:sub(1, config.suffix_chars)
  end

  return {
    row = row,
    col = col,
    prefix = prefix,
    suffix = suffix,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
  }
end

local function clean_response(text)
  text = (text or ""):gsub("\r", "")
  text = text:gsub("<|fim_prefix|>", ""):gsub("<|fim_suffix|>", ""):gsub("<|fim_middle|>", "")
  text = text:gsub("^```[%w_-]*\n", ""):gsub("\n```%s*$", "")

  local lines = vim.split(text, "\n", { plain = true })
  if #lines > config.max_lines then
    lines = vim.list_slice(lines, 1, config.max_lines)
  end

  return table.concat(lines, "\n")
end

local function show_suggestion(buf, context, text)
  if text == "" or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local state = state_for(buf)
  state.suggestion = {
    text = text,
    row = context.row,
    col = context.col,
    changedtick = context.changedtick,
  }

  local lines = vim.split(text, "\n", { plain = true })
  local opts = {
    virt_text = { { lines[1], "Comment" } },
    virt_text_pos = "inline",
    hl_mode = "combine",
  }

  if #lines > 1 then
    opts.virt_lines = {}
    for index = 2, #lines do
      opts.virt_lines[#opts.virt_lines + 1] = { { lines[index], "Comment" } }
    end
  end

  vim.api.nvim_buf_set_extmark(buf, namespace, context.row - 1, context.col, opts)
end

local function report_error(message)
  if error_was_reported then
    return
  end

  error_was_reported = true
  vim.notify("Local completion: " .. message, vim.log.levels.WARN)
end

local function perform_request(buf, request_id, context)
  if not buffer_is_eligible(buf) then
    return
  end

  local state = state_for(buf)
  if request_id ~= state.request_id then
    return
  end

  local payload = vim.json.encode {
    model = config.model,
    prompt = context.prefix,
    suffix = context.suffix,
    stream = false,
    keep_alive = config.keep_alive,
    options = {
      temperature = 0.1,
      top_p = 0.9,
      num_predict = config.num_predict,
    },
  }

  state.process = vim.system({
    "curl",
    "--silent",
    "--show-error",
    "--max-time",
    "15",
    "--header",
    "Content-Type: application/json",
    "--data-binary",
    "@-",
    config.endpoint,
  }, { stdin = payload, text = true }, function(result)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        states[buf] = nil
        return
      end

      local current_state = state_for(buf)
      current_state.process = nil
      if request_id ~= current_state.request_id then
        return
      end

      if result.code ~= 0 then
        current_state.last_error = result.stderr ~= "" and result.stderr or "Ollama request failed"
        report_error "could not reach Ollama. Start it with `ollama serve`."
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout)
      if not ok or response.error then
        current_state.last_error = ok and response.error or "Invalid Ollama response"
        report_error(current_state.last_error)
        return
      end

      if vim.api.nvim_buf_get_changedtick(buf) ~= context.changedtick then
        return
      end

      local cursor = vim.api.nvim_win_get_cursor(0)
      if vim.api.nvim_get_current_buf() ~= buf or cursor[1] ~= context.row or cursor[2] ~= context.col then
        return
      end

      error_was_reported = false
      current_state.last_error = nil
      show_suggestion(buf, context, clean_response(response.response))
    end)
  end)
end

local function request(buf, immediate)
  clear(buf, true)
  if not buffer_is_eligible(buf) then
    return
  end

  local context = context_at_cursor(buf)
  if #context.prefix < 3 then
    return
  end

  local state = state_for(buf)
  local request_id = state.request_id
  local delay = immediate and 0 or config.debounce_ms

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) and state_for(buf).request_id == request_id then
      perform_request(buf, request_id, context)
    end
  end, delay)
end

function M.accept()
  local buf = vim.api.nvim_get_current_buf()
  local state = state_for(buf)
  local suggestion = state.suggestion
  if not suggestion then
    return false
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  if
    vim.api.nvim_buf_get_changedtick(buf) ~= suggestion.changedtick
    or cursor[1] ~= suggestion.row
    or cursor[2] ~= suggestion.col
  then
    clear(buf, true)
    return false
  end

  local lines = vim.split(suggestion.text, "\n", { plain = true })
  clear(buf, true)
  vim.api.nvim_buf_set_text(buf, suggestion.row - 1, suggestion.col, suggestion.row - 1, suggestion.col, lines)

  local final_row = suggestion.row + #lines - 1
  local final_col = #lines == 1 and suggestion.col + #lines[1] or #lines[#lines]
  vim.api.nvim_win_set_cursor(0, { final_row, final_col })
  return true
end

function M.complete()
  request(vim.api.nvim_get_current_buf(), true)
end

function M.stop_project()
  local root = project_root(vim.api.nvim_get_current_buf())
  stopped_projects[root] = true

  for buf in pairs(states) do
    if vim.api.nvim_buf_is_valid(buf) and project_root(buf) == root then
      clear(buf, true)
    end
  end

  vim.notify("Local completion stopped for " .. root .. " until Neovim restarts")
end

function M.status()
  local buf = vim.api.nvim_get_current_buf()
  local state = state_for(buf)
  local root = project_root(buf)
  return {
    enabled = not stopped_projects[root],
    model = config.model,
    project = root,
    project_stopped = stopped_projects[root] == true,
    has_suggestion = state.suggestion ~= nil,
    last_error = state.last_error,
  }
end

function M.setup(options)
  config = vim.tbl_deep_extend("force", defaults, options or {})

  local group = vim.api.nvim_create_augroup("LocalCompletion", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
    group = group,
    callback = function(args)
      request(args.buf, false)
    end,
  })
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "BufDelete" }, {
    group = group,
    callback = function(args)
      clear(args.buf, true)
    end,
  })

  vim.api.nvim_create_user_command("OllamaComplete", M.complete, { desc = "Request local AI completion" })
  vim.api.nvim_create_user_command("OllamaStopProject", M.stop_project, {
    desc = "Stop local AI completion for this project until Neovim restarts",
  })
  vim.api.nvim_create_user_command("OllamaStatus", function()
    vim.notify(vim.inspect(M.status()))
  end, { desc = "Show local AI completion status" })
end

return M
