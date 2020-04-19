local M = {
    -- UI
    TopPanelHeight = 100,
    BottomPanelHeight = 150,

    -- Типы запросов и их параметры
    ReqTypeFlood = 1, -- Флуд запросы
    ReqTypeLegal = 2, -- Легитимные запросы
    ReqColors = {}, -- Цвета запросов. Заполняется ниже

    -- Способы защиты
    TechThrottling = 1, -- Отбивает половину трафика, не разбирая тип запроса
    TechFilter = 2, -- Отбивает солидную часть флуда, но задевает и легитимный трафик
    TechFirewall = 3, -- Отбивает только флуд (и неизвестный тип?), пропуская легитимный трафик
    TechMLDPI = 4, -- Превращает неизвестный тип в конкретный
    TechBuild = 5, -- Место постройки новой платформы

    TechCosts = {}, -- Стоимости использований технологий. Заполняется ниже

    TechDurabilities = {}, -- Сколько запросов могут обработать защиты до своей поломки. Заполняется ниже

    TechFiltering = { -- Вероятности отсева запросов
        Flood_Throttling = 0.50,
        Legal_Throttling = 0.50,
        Flood_Filter = 0.75,
        Legal_Filter = 0.10,
    },
}

M.ReqColors = {
    [M.ReqTypeFlood] = { 0.7, 0.0, 0.0 },
    [M.ReqTypeLegal] = { 0, 0.7, 0 },
}

M.TechCosts = {
    [M.TechThrottling] = 20,
    [M.TechFilter] = 100,
    [M.TechFirewall] = 500,
    [M.TechMLDPI] = 200,
    --[M.TechBuild] = 0,
}

M.TechDurabilities = {
    [M.TechThrottling] = 40 * 1000,
    [M.TechFilter] = 20 * 1000,
    [M.TechFirewall] = 5 * 1000,
    [M.TechMLDPI] = 30 * 1000,
    --[M.TechBuild] = 0,
}

M.TechNames = {
    [M.TechThrottling] = 'Throttling',
    [M.TechFilter] = 'Filter',
    [M.TechFirewall] = 'Firewall',
    [M.TechMLDPI] = 'ML DPI',
    --[M.TechBuild] = '<place for build>',
}

return M
