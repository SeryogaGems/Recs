local st = os.clock()
for i = 1, 256 do
    local chunk = {
        0xFFFFi,
        table.create(16),
        table.create(16),
        table.create(16)
    }
end
print(os.clock() - st)

