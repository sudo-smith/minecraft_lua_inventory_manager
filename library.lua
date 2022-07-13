local component = require("component")
local sides = require("sides")
local thread = require("thread")
local term = require("term")
local sides = require("sides")
local tr = component.transposer
local event = require("event")

---------------------------------------------------------------------------------------------------
--                                       GLOBAL VARIABLES                                        --
---------------------------------------------------------------------------------------------------

-- CONSTANTS ---------------------------------------------------------------------------------------
fileName = "message.log"
dumpChestSide = sides.top
libSide = sides.front
sSide = sides.right
zSide = sides.left
numDumpChestSlots = tr.getInventorySize(dumpChestSide)
-- start archiver and store thread to suspend or kill
archiver = thread.create(archive)

-- DYNAMICS ---------------------------------------------------------------------------------------
-- index by name return quantity and slot for each itemEntry
-- xxxItemsInCollosal['xxx'] = {quantity = number, slots={slot1:number, slot2:number, ...}}
nameItemsInCollosal = {}
-- labelItemsInCollosal = {}

---------------------------------------------------------------------------------------------------
--                                           CLASSES                                             --
---------------------------------------------------------------------------------------------------
ItemEntry = {name = "", label = "", maxSlotSize = -1, quant = -1, slots={}}
function ItemEntry:new(o, name, label, slots)
    assert(o == nil or type(o) == "table")
    assert(type(name) == "string")
    assert(type(label) == "string")
    assert(type(maxSlotSize) == "number")
    assert(type(quant) == "number")
    assert(slots == nil or type(slots) == "table")

    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.name = name
    self.label = label
    self.quant = quant
    self.slots = slots

    return o
end

function ItemEntry:remove(quant, sinkSlot)
    assert(type(quant) == "number")

    repeat
        lastSlot = sinkSlot[#self.slots]
        if tr.getSlotStackSize(colossalChestSide)
end

function ItemEntry:add(quant, )



---------------------------------------------------------------------------------------------------
--                                        FUNCTIONS                                              --
---------------------------------------------------------------------------------------------------

-- UTILITY ----------------------------------------------------------------------------------------
--  function split(str)     words = {}     for w in str:gmatch("%S+") do         table.insert(words, w)     end     return words end
function split(str)
    assert(type(str) == "string")

    words = {}
    if not str then return words end
    for w in str:gmatch("%S+") do
        table.insert(words, w)
    end

    assert(type(words) == "table" and (#words > 0 and type(words[1]) == "string" or true))
    return words
end

-- PARSERS ----------------------------------------------------------------------------------------
function parseEvent(id, a, b, c, d, e)
    if id == "key_down" then
        key = string.char(b)
        playername = d

        -- if control is pressed, exit code
        if (key == "\0" and c == 29) then
            print("exiting")
            archiver:kill()
            os.exit()
        end
    elseif id == "touch" then
        playername = e
    end

    assert(type(playername) == "string")
    return playername
end

function parseFile(fileName)
    assert(type(fileName) == "string")
    for line in io.lines(fileName) do
        entry = split(line)
        name = entry[1]
        label = ""
        for w = 2, #entry-2 do
            label = label .. entry[w]
        end
        _quant = tonumber(entry[#entry-1])
        slot = tonumber(entry[#entry])
        assert(slot)
        assert(_quant)
        assert(label)
        assert(name)
        if nameItemsInCollosal[name] then
            nameItemsInCollosal[name]['quant'] = nameItemsInCollosal[name]['quant'] + _quant
            table.insert(nameItemsInCollosal[name]['slots'], slot)
        else
            nameItemsInCollosal[name] = {quant=_quant, slots={slot}}
        end
        
        -- if labelItemsInCollosal[label] then
            -- labelItemsInCollosal[label]['quant'] = labelItemsInCollosal[label]['quant'] + _quant
            -- table.insert(labelItemsInCollosal[label]['slots'], slot)
        -- else
            -- labelItemsInCollosal[label] = {quant=_quant, slots={slot}}
        -- end
    end
end

function parseQuery(query)
    assert(type(query) == "table")
    if #query == 0 then return end
    assert(type(query[1]) == "string")

    names = {}
    name = ""
    isName = (query[1]:match(":") ~= nil)

    -- if last query word is a number then use as quantity
    -- if it's "all" then take all. If it's missing then assume slot
    quant = tonumber(query[#query])
    if quant == nil then
        if query[#query] == "all" then
            quant = 0
        elseif query[#query] ~= "stack" then
            table.insert(query, "stack")
            quant = 0
        else
            print("No quantitiy specified, defaulting to one stack")
            quant = 0
        end
    end

    for w = 1, #query-1 do
        if query[w] == "," then
            table.insert(names, name)
            name = ""
        else
            name = name .. query[w]
        end
    end
    table.insert(names, name)

    assert(type(names) == "table" and type(names[1]) == "string")
    assert(type(quant) == "number")
    assert(type(isName) == "boolean")
    return names, quant, isName
end

-- FUNCTIONALITY  ---------------------------------------------------------------------------------
function archive()
    nextFreeSlot = 2800
    while true do
        message = ""
        for slot=1, numDumpChestSlots do
            stack = tr.getStackInSlot(dumpChestSide, slot)
            if stack then
                print(stack['name'] .. " " .. stack['label']  .. " " .. stack['size'] .. " " .. nextFreeSlot)
                tr.transferItem(dumpChestSide, colossalChestSide, stack['size'], slot, nextFreeSlot)
                -- message = message .. stack['name'] .. " " .. stack['size'] .. " " .. nextFreeSlot .. "\n"
                file = io.open(fileName, 'a')
                file:write(stack['name'] .. " " .. stack['label']  .. " " .. stack['size'] .. " " .. nextFreeSlot .. "\n")
                file:close()
                nextFreeSlot = nextFreeSlot + 1
            end
            os.sleep()
        end
    end
end

function moveItemToShelf(reqname, req_quant, isName, playername)
    assert(type(reqname) == "string")
    assert(type(req_quant) == "number")
    assert(type(isName) == "boolean")
    assert(type(playername) == "string")

    if playername == 'Zietau' then
        shelfChestSide = zietauShelfChestSide
    else
        shelfChestSide = sudoShelfChestSide
    end
    numShelfChestSlots = tr.getInventorySize(shelfChestSide)
    moved_quant = 0

    if isName then
        ie = nameItemsInCollosal[reqname]
    else
        -- ie = labelItemsInCollosal[reqname]
    end

    if not ie then
        print(reqname .. " not in library")
        return 0
    end

    if isName then
        reqlabel = tr.getStackInSlot(colossalChestSide, ie['slots'][1])['label']
    else
        reqlabel = reqname
        reqname = tr.getStackInSlot(colossalChestSide, ie['slots'][1])['label']
    end

    nextFreeSlotInShelf = 1
    if req_quant > avail_quant then
        term.write("Only have " .. avail_quant .. " of " .. (isName and reqname or reqlabel) .. "\n")
        req_quant = avail_quant
    end

    while moved_quant < req_quant do
        availslots = ie['slots']  -- the slots that have this item
        avail_quant = ie['quant']  -- quant total in library left
        slot_quant = tr.getSlotStackSize(colossalChestSide, availslots[1]) -- quant left in this slot

        left_quant = req_quant - moved_quant  -- quant that still needs to be moved
        moved_it = 0 -- how many items were moved in this transfer

        -- get next free slot in the shelf chest
        -- TODO this will permaloop if all slots are full
        while tr.getStackInSlot(shelfChestSide, nextFreeSlotInShelf) do
            nextFreeSlotInShelf = ((nextFreeSlotInShelf) % numShelfChestSlots) + 1
        end

        -- if there is more than enough in this slot then don't delete it
        if slot_quant > left_quant then            
            tr.transferItem(colossalChestSide, shelfChestSide, left_quant, availslots[1], nextFreeSlotInShelf)

            moved_it = left_quant
        else  -- if not then empty this slot completely and delete it
            tr.transferItem(colossalChestSide, shelfChestSide, slot_quant, availslots[1], nextFreeSlotInShelf)
            -- table.remove(labelItemsInCollosal[reqlabel]['slots'], 1)
            table.remove(nameItemsInCollosal[reqname]['slots'], 1)

            moved_it = slot_quant
        end
        
        -- reduce overall quantity of item by how much was moved
        nameItemsInCollosal[reqname]['quant'] = nameItemsInCollosal[reqname]['quant'] - moved_it
        -- labelItemsInCollosal[reqlabel]['quant'] = labelItemsInCollosal[reqlabel]['quant'] - moved_it

        -- if there are no more items then remove entry
        if nameItemsInCollosal[reqname]['quant'] <= 0 then
            -- check that label and name items are in sync
            -- assert(#labelItemsInCollosal[reqlabel]['slots'] == 0)
            -- assert(labelItemsInCollosal[reqlabel]['quant'] <= 0)

            -- make sure no more slots are there
            assert(#nameItemsInCollosal[reqname]['slots'] == 0)

            nameItemsInCollosal[reqname] = nil
            -- labelItemsInCollosal[reqlabel] = nil
        end

        -- update total moved amount
        moved_quant = moved_quant + moved_it
    end

    return moved_quant
end


---------------------------------------------------------------------------------------------------
--                                             CODE                                              --
---------------------------------------------------------------------------------------------------
while true do
    playername, key = parseEvent(event.pullMultiple("key_down", "touch"))
    archiver:suspend()

    term.write("\n\nenter request (name quantity): ")
    names, quant, isName = parseQuery(split(term.read()))
    isName = true
    if (names and quant and (isName ~= nil)) then
        parseFile(fileName)
        -- clear file
        io.open(fileName, 'w'):close()
        for nameIdx = 1, #names do
            moved_quant = moveItemToShelf(names[nameIdx], quant, isName, playername)
            print("Put " .. moved_quant .. " of " .. names[nameIdx] .. " in " .. playername .. "'s shelf chest")
        end
    else
        print("invalid input. Skipping")
    end

    print("Continuing\n\n")
    archiver:resume()
end
