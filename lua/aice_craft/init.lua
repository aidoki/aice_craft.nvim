-- lua/aice_craft/init.lua
local M = {}

M.config = {
    api_key = os.getenv("DEEPSEEK_API_KEY"),
    model = "deepseek-chat"
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})

    if not M.config.prompts then
        M.config.prompts = require('aice_craft.prompts')
    end

    -- 创建用户命令
    vim.api.nvim_create_user_command("AIPrompt", function(opts_)
        if opts_.range == 0 then
            vim.notify("Please select text first", vim.log.levels.ERROR)
            return
        end
        require('aice_craft.ui').show_prompt_menu()
    end, {
        range = true,
        desc = "Show AI prompt menu"
    })

    -- 设置键位映射
    vim.keymap.set('x', '<leader>ai', ':AIPrompt<CR>', {
        noremap = true,
        silent = true,
        desc = "Show AI prompt menu"
    })
end

return M

