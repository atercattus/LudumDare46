local M = {}

local tableRemove = table.remove

function M:new(constructor, options)
    local pool = {
        --callback = constructor,
    }

    function pool:get()
        if pool._cache == nil then
            pool._cache = {}
        end

        local item
        if #pool._cache > 0 then
            item = pool._cache[#self._cache]
            tableRemove(pool._cache, #pool._cache)
        else
            item = constructor()
        end

        return item
    end

    function pool:put(item)
        if pool._cache == nil then
            pool._cache = {}
        end

        pool._cache[#pool._cache + 1] = item
    end

    function pool:clean(cb)
        if cb ~= nil then
            for i = 1, #pool._cache do
                cb(pool._cache[i])
            end
        end
        pool._cache = {}
    end

    return pool
end

return M
