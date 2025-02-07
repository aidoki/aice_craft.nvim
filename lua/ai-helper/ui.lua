-- lua/ai-helper/ui.lua
local M = {}

-- 获取选中的文本
function M.get_visual_selection()
    -- 获取选区的起始和结束位置
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- 获取行和列
    local start_row = start_pos[2]
    local start_col = start_pos[3]
    local end_row = end_pos[2]
    local end_col = end_pos[3]

    -- 获取选中的行
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    if #lines == 0 then
        vim.notify("No text selected", vim.log.levels.ERROR)
        return nil
    end

    -- 处理选中的文本
    if #lines == 1 then
        -- 单行选择
        lines[1] = string.sub(lines[1], start_col, end_col)
    else
        -- 多行选择
        lines[1] = string.sub(lines[1], start_col)
        if end_col ~= 2147483647 then  -- 检查是否是整行选择
            lines[#lines] = string.sub(lines[#lines], 1, end_col)
        end
    end

    return table.concat(lines, '\n')
end

local function handle_ai_response(text)
    if text then
        -- 创建新的缓冲区显示结果
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))

        -- 在新窗口中显示结果
        vim.api.nvim_command("vsplit")
        vim.api.nvim_win_set_buf(0, buf)
    end
end

-- 显示prompt选择菜单
function M.show_prompt_menu()
    -- 保存当前视图状态
    local saved_view = vim.fn.winsaveview()

    -- 获取选中的文本
    local text = M.get_visual_selection()
    if not text or text == "" then
        vim.notify("Please select text first", vim.log.levels.ERROR)
        return
    end

    -- 恢复视图状态
    vim.fn.winrestview(saved_view)

    local prompts = {}
    for k, _ in pairs(require('ai-helper').config.prompts) do
        table.insert(prompts, k)
    end

    vim.ui.select(prompts, {
        prompt = "选择Prompt:",
        format_item = function(item)
            return item
        end,
    }, function(choice)
        if choice then
            -- 使用异步API调用
            require('ai-helper.api').call_ai_api(
                require('ai-helper').config.prompts[choice],
                text,
                handle_ai_response
            )
        end
    end)
end

function M.show_loading()
    -- 创建一个浮动窗口显示加载状态
    local width = 30
    local height = 1
    local buf = vim.api.nvim_create_buf(false, true)

    -- 设置缓冲区文本
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Processing request..."})

    -- 计算窗口位置
    local win_width = vim.api.nvim_get_option_value("columns", {})
    local win_height = vim.api.nvim_get_option_value("lines", {})

    local row = math.floor((win_height - height) / 2)
    local col = math.floor((win_width - width) / 2)

    -- 创建浮动窗口
    local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    })

    -- 设置窗口选项
    -- vim.api.nvim_win_set_option(win, "winblend", 15)
    vim.api.nvim_set_option_value("winblend", 15, {})

    return buf, win
end


return M
