local component = require("component")
local sides = require("sides")
local event = require("event")

local tr = component.transposer
colossalChestSide = sides.front
fileName = "message.log"

event.listen("Interrupt", os.exit)

nextFreeSlot = 1
numEmptySlots = 0
while true do
    stack = tr.getStackInSlot(colossalChestSide, nextFreeSlot)
    if stack then
        numEmptySlots = 0
        print(stack['name'] .. " " .. stack['label'] .. " " .. stack['size'] .. " " .. nextFreeSlot)
        file = io.open(fileName, 'a')
        file:write(stack['name'] .. " " .. stack['label'] .. " " .. stack['size'] .. " " .. nextFreeSlot .. "\n")
        file:close()
        nextFreeSlot = nextFreeSlot + 1
    elseif numEmptySlots > 300 then
        print("\nDONE\n")
        print("used " .. nextFreeSlot - 300 .. " slots")
        break
    else
        numEmptySlots = numEmptySlots + 1
        nextFreeSlot = nextFreeSlot + 1
    end
    os.sleep()
end
