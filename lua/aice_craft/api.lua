-- lua/aice_craft/api.lua
local M = {}
local curl = require('plenary.curl')

-- 检查响应是否成功
local function is_response_ok(response)
    return response.status == 200 and response.body ~= nil
end

-- 解析 API 响应
local function parse_response(response_body)
    local ok, decoded = pcall(vim.fn.json_decode, response_body)
    if not ok then
        return nil, "Failed to decode JSON response"
    end

    if not decoded.choices or not decoded.choices[1] or not decoded.choices[1].message then
        return nil, "Invalid response format"
    end

    return decoded.choices[1].message.content
end

-- 显示错误消息
local function show_error(msg)
    vim.schedule(function()
        vim.notify(msg, vim.log.levels.ERROR)
    end)
end

-- 主要的 API 调用函数
function M.call_ai_api(prompt, text, callback)
    -- 获取配置
    local config = require('aice_craft').config

    -- 检查 API key
    if not config.api_key then
        show_error("API key not set! Please configure your API key.")
        return
    end

    -- 创建加载指示器
    local loading_buf, loading_win
    vim.schedule(function()
        loading_buf, loading_win = require('aice_craft.ui').show_loading()
    end)

    -- 准备请求数据
    local request_data = {
        model = config.model or "gpt-3.5-turbo",
        messages = {
            {
                role = "user",
                content = prompt .. "\n\n" .. text
            }
        },
        temperature = 0.7,
    }

    -- 发起异步请求
    curl.post({
        url = "https://api.deepseek.com/v1/chat/completions",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. config.api_key,
        },
        body = vim.fn.json_encode(request_data),
        callback = vim.schedule_wrap(function(response)
            -- 清理加载指示器
            if loading_win and vim.api.nvim_win_is_valid(loading_win) then
                vim.api.nvim_win_close(loading_win, true)
            end
            if loading_buf and vim.api.nvim_buf_is_valid(loading_buf) then
                vim.api.nvim_buf_delete(loading_buf, { force = true })
            end

            -- 检查响应
            if not is_response_ok(response) then
                show_error("API request failed: " .. (response.body or "Unknown error"))
                callback(nil)
                return
            end

            -- 解析响应
            local content, err = parse_response(response.body)
            if err then
                show_error(err)
                callback(nil)
                return
            end

            -- 调用回调函数返回结果
            callback(content)
        end)
    })
end

-- 用于测试连接的函数
function M.test_connection(callback)
    local config = require('aice_craft').config

    if not config.api_key then
        callback(false, "API key not set")
        return
    end

    curl.get({
        url = "https://api.openai.com/v1/models",
        headers = {
            ["Authorization"] = "Bearer " .. config.api_key,
        },
        callback = vim.schedule_wrap(function(response)
            if response.status == 200 then
                callback(true, "Connection successful")
            else
                callback(false, "Connection failed: " .. (response.body or "Unknown error"))
            end
        end)
    })
end

return M

