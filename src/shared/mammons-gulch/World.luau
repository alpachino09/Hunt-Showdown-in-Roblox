--!strict

local World = {}

World.studsPerMetre = 3
World.heightOffsetMetres = 32.79
World.sizeMetres = 1024
World.originMetres = 512

function World.sourceToWorld(x: number, y: number, z: number): Vector3
    return Vector3.new(
        (x - 1024) * World.studsPerMetre,
        (z - World.heightOffsetMetres) * World.studsPerMetre,
        (1024 - y) * World.studsPerMetre
    )
end

function World.worldToSource(position: Vector3): (number, number, number)
    return (position.X / World.studsPerMetre + 1024),
        (1024 - position.Z / World.studsPerMetre),
        (position.Y / World.studsPerMetre + World.heightOffsetMetres)
end

return World
