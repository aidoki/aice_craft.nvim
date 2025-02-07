-- plugin/your-plugin-name.lua
if vim.g.loaded_ai_helper then
    return
end
vim.g.loaded_ai_helper = true

-- 创建用户命令
vim.api.nvim_create_user_command('AIPrompt', function()
    require('ai-helper.ui').show_prompt_menu()
end, {})

-- 创建快捷键映射
-- vim.keymap.set('v', '<Leader>ai', ':AIPrompt<CR>', { noremap = true, silent = true })

