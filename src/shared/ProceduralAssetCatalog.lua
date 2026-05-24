--[[
    ProceduralAssetCatalog.lua
    Slugs Karl can request in Cursor chat — built from Parts in PropBuilder.lua.
    No Roblox upload required; syncs via Rojo.

    Imported meshes (Manus) use AssetRegistry + vendor-imports manifest instead.
]]

local ProceduralAssetCatalog = {}

export type ProceduralAssetDef = {
    slug: string,
    displayName: string,
    category: "furniture" | "plant" | "decor" | "outdoor" | "runway",
    partEstimate: number,
    itemCatalogId: string?, -- links to ItemCatalog.Furniture when placeable on plot
    promptHint: string,
}

ProceduralAssetCatalog.Assets = {
    {
        slug = "eames_lounge",
        displayName = "Eames Lounge Chair",
        category = "furniture",
        partEstimate = 12,
        itemCatalogId = "eames_lounge",
        promptHint = "Iconic MCM lounger with ottoman",
    },
    {
        slug = "starburst_clock",
        displayName = "Starburst Wall Clock",
        category = "decor",
        partEstimate = 14,
        itemCatalogId = "starburst_clock",
        promptHint = "Gold sunburst rays on wall",
    },
    {
        slug = "pool_lounger",
        displayName = "Poolside Lounger",
        category = "outdoor",
        partEstimate = 8,
        itemCatalogId = "outdoor_lounge",
        promptHint = "White recliner for pool deck",
    },
    {
        slug = "flamingo_lawn",
        displayName = "Pink Flamingo Lawn Ornament",
        category = "outdoor",
        partEstimate = 6,
        itemCatalogId = nil,
        promptHint = "Classic kitschy pool flamingo on stake",
    },
    {
        slug = "desert_rose_planter",
        displayName = "Desert Rose Planter",
        category = "plant",
        partEstimate = 10,
        itemCatalogId = "planter_box",
        promptHint = "Terracotta pot with pink succulent blooms",
    },
    {
        slug = "palm_planter",
        displayName = "Fan Palm Planter",
        category = "plant",
        partEstimate = 12,
        itemCatalogId = nil,
        promptHint = "Short palm in concrete planter",
    },
    {
        slug = "martini_table",
        displayName = "Martini Side Table",
        category = "furniture",
        partEstimate = 7,
        itemCatalogId = "boomerang_table",
        promptHint = "Tripod table with turquoise top",
    },
    {
        slug = "breeze_block_column",
        displayName = "Breeze Block Column",
        category = "decor",
        partEstimate = 9,
        itemCatalogId = nil,
        promptHint = "Perforated MCM screen column",
    },
}

function ProceduralAssetCatalog.getBySlug(slug: string): ProceduralAssetDef?
    for _, def in ipairs(ProceduralAssetCatalog.Assets) do
        if def.slug == slug then
            return def
        end
    end
    return nil
end

function ProceduralAssetCatalog.listSlugs(): { string }
    local slugs = {}
    for _, def in ipairs(ProceduralAssetCatalog.Assets) do
        table.insert(slugs, def.slug)
    end
    return slugs
end

function ProceduralAssetCatalog.resolvePlacementId(slug: string): string?
    local def = ProceduralAssetCatalog.getBySlug(slug)
    if def and def.itemCatalogId then
        return def.itemCatalogId
    end
    local byItem = ProceduralAssetCatalog.getByItemCatalogId(slug)
    if byItem then
        return byItem.itemCatalogId or byItem.slug
    end
    return nil
end

function ProceduralAssetCatalog.getByItemCatalogId(itemId: string): ProceduralAssetDef?
    for _, def in ipairs(ProceduralAssetCatalog.Assets) do
        if def.itemCatalogId == itemId or def.slug == itemId then
            return def
        end
    end
    return nil
end

return ProceduralAssetCatalog
