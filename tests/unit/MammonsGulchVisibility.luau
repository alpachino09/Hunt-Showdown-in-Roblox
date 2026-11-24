local fs = require("@lune/fs")
local luau = require("@lune/luau")

local function node(name, className)
    local object = {
        Name = name,
        ClassName = className,
        Children = {},
        LocalTransparencyModifier = 0,
    }
    function object:GetChildren()
        return self.Children
    end
    function object:FindFirstChild(childName)
        for _, child in self.Children do
            if child.Name == childName then
                return child
            end
        end
        return nil
    end
    function object:GetDescendants()
        local result = {}
        local function visit(parent)
            for _, child in parent.Children do
                table.insert(result, child)
                visit(child)
            end
        end
        visit(self)
        return result
    end
    function object:IsA(expectedClass)
        if expectedClass == "BasePart" then
            return self.ClassName == "Part" or self.ClassName == "MeshPart"
        end
        return self.ClassName == expectedClass
    end
    return object
end

local function add(parent, child)
    table.insert(parent.Children, child)
end

local compounds = node("Compounds", "Folder")
local compound = node("LaPlataMine", "Model")
local boundary = node("RegionBoundary", "Folder")
local boundaryPart = node("Edge_01", "Part")
local massingPart = node("MeasuredBoundsGreybox", "Part")
add(compounds, compound)
add(compound, boundary)
add(boundary, boundaryPart)
add(compound, massingPart)

local Visibility = luau.load(fs.readFile("src/shared/mammons-gulch/DebugVisibility.luau"), {
    environment = {},
})()
Visibility.applyBounds(compounds, 1)
assert(boundaryPart.LocalTransparencyModifier == 1, "boundary should be hidden")
assert(massingPart.LocalTransparencyModifier == 0, "debug Clear must not hide compound geometry")
Visibility.applyBounds(compounds, 0.35)
assert(boundaryPart.LocalTransparencyModifier == 0.35, "boundary should be shown")
assert(massingPart.LocalTransparencyModifier == 0, "massing remains unchanged")
print("mammons-gulch visibility: boundaries are isolated from compound geometry")
