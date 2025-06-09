--!native

export type MatrixType = {
	columns: number,
	rows: number,
	data: {[number]: {[number]: number}},
	map: (func: (cell: number, row: number, column: number, args: {any}) -> number) -> MatrixType,
	transpose: () -> MatrixType,
	multiplyParallel: (m2: MatrixType) -> MatrixType,
	mutatingAdd: (m2: MatrixType) -> MatrixType,
	mutatingSubtract: (m2: MatrixType) -> MatrixType,
	mutatingScalarMultiply: (k: number) -> MatrixType
}

local NUM_OF_ACTORS = 32
local EPSILON = 1e-10  
local WORKERS = {}

for i = 1, NUM_OF_ACTORS do
	local worker = script.Actor:Clone()
	worker.Parent = script.Actors
	table.insert(WORKERS, worker)

end

local FinishedFlags = SharedTable.new()

for i = 1, NUM_OF_ACTORS do
	FinishedFlags[i] = false
end

local Matrices = {}

local function CheckFlags()
	for i = 1, NUM_OF_ACTORS do
		if not FinishedFlags[i] then return false end
	end
	return true
end
--Used for clean indexing and methods
--that is: 
--			Matrix[i][j] instead of Matrix.data[i][j]
--			because when indexing with a number (
--			which doesnt exist), it defaults to returning
--			that row which then can be indexed by the 
--			second index
--
--			also, returns Matrices[k] in order to call
--			the method by indexing with the method
--			name
--
--	@self: is the Matrix getting operated on
-- @k: either an indexing number or a string
--
-- returns either the row of the matrix, or the
-- method defined at Matrices[k]
Matrices.__index = function(self: MatrixType, k: number | string)
	if type(k) == "number" then
		return self.data[k]
	else
		return Matrices[k]
	end
end

--Used for pretty printing
--that is:
--			|1.000, 2.000, 3.000|
--			|4.000, 5.000, 6.000|
--
--	@self: is the Matrix getting printed
--
-- returns a prettified matrix
Matrices.__tostring = function(self: MatrixType): string
	local str = "\n|"
	
	for i = 1, self.rows do
		for j = 1, self.columns do
			str ..= string.format("%3.3f", self[i][j]) .. (j == self.columns and "" or ",")
		end
		str ..= "|\n"
		if i ~= self.rows then 
			str ..= "|"
		end
	end
	return str
end

--Used for nonparallel scalar and matrix multiplication. Nonmutating
--that is:
--			m1 * m2
--			or
--			m1 * k
-- @m1: left-side matrix
-- @k: right-side matrix or a scalar
--
-- returns the result of a matrix/scalar multiplication
Matrices.__mul = function(m1: MatrixType, k: MatrixType | number): MatrixType
	assert(type(k) == "number" or type(k) == "table", "Attempt to multiply matrix by type "..type(k))
	
	if type(k) == "number" then
		local multipliedMatrix = table.create(m1.rows * m1.columns)
		for i = 1, m1.rows do
			for j = 1, m1.columns do
				table.insert(multipliedMatrix, m1[i][j] * k)
			end
		end
		return Matrices.new(m1.rows, m1.columns, multipliedMatrix)
	else
		local m2 = k :: MatrixType

		assert(m1.columns == m2.rows, "Incompatible matrices ")

		local multipliedMatrix = table.create(m1.rows * m2.columns)

		for i = 1, m1.rows do
			for j = 1, m2.columns do
				local cell = 0
				for k = 1, m1.columns do
					cell += m1[i][k] * m2[k][j]
				end
				table.insert(multipliedMatrix, cell)
			end
		end
		return Matrices.new(m1.rows, m2.columns, multipliedMatrix)
	end
end
--Used for nonparallel matrix addition. Nonmutating
--that is:
--			m1 + m2
--
--	@m1: left-side matrix
--	@m2: right-side matrix
--
-- returns the result of a matrix addition
Matrices.__add = function(m1: MatrixType, m2: MatrixType): MatrixType
	assert(m1.rows == m2.rows and m1.columns == m2.columns, "Incompatible matrices")
	local addedMatrix = table.create(m1.rows * m1.columns)
	for i = 1, m1.rows do
		for j = 1, m1.columns do
			table.insert(addedMatrix, m1[i][j] + m2[i][j])
		end
	end
	return Matrices.new(m1.rows, m1.columns, addedMatrix)
end

--Used for nonparallel matrix subtraction. Nonmutating
--that is:
--			m1 - m2
--
--	@m1: left-side matrix
--	@m2: right-side matrix
--
-- returns the result of a matrix subtraction
Matrices.__sub = function(m1: MatrixType, m2:MatrixType): MatrixType
	assert(m1.rows == m2.rows and m1.columns == m2.columns, "Incompatible matrices")
	
	return m1 + m2 * -1
end
--Used to check whether two matrices are equal with a given 
--epsilon tolerance to account for floating point errors.
--that is:
--		m1 == m2
--
--	@m1: left-side matrix
--	@m2: right-side matrix
--
-- returns whether each element in m1 and m2 is less than
-- epsilon away from each other. true if yes, false if no
Matrices.__eq = function(m1: MatrixType, m2: MatrixType): boolean
	if m1.rows ~= m2.rows or m1.columns ~= m2.columns then
		return false
	end

	for i = 1, m1.rows do
		for j = 1, m1.columns do
			if math.abs(m1[i][j] - m2[i][j]) > EPSILON then
				return false
			end
		end
	end

	return true
end
--Used to construct an identity matrix
--that is:
--			Matrices.identity(n) 
--
--	@size: the number of rows and columns
--
-- returns an identity matrix of size n.
function Matrices.identity(size: number): MatrixType
	local elements = table.create(size^2)
	
	for i = 1, size do
		for j = 1, size do
			table.insert(elements, i == j and 1 or 0)
		end
	end
	return Matrices.new(size, size, elements)
end

--Used to construct a n by m matrix with cells initialize to elements
--that is:
--			Matrices.new(n,m, cells)
--
--	@rows: the number of rows
--	@columns: the number of columns
--	@elements: a 1-dimensional table of elements to be placed in the matrix
--
-- returns a new matrix of size n by m with cells initialized to elements
function Matrices.new(rows: number, columns: number, elements: {number}): MatrixType
	assert(rows * columns == #elements, "Incorrect number of elements")
	assert(elements ~= nil, "Arg3 missing")
	assert(columns ~= nil, "Arg2 missing")
	assert(rows ~= nil, "Arg1 missing") 
	assert(rows > 0, "Rows is less than or equal to zero")
	assert(columns > 0, "Columns is less than or equal to zero")
	
	local Matrix = {}
	
	Matrix.rows = rows
	Matrix.columns = columns
	Matrix.data = table.create(rows)
	
	for i = 1, rows do
		Matrix.data[i] = {}
		for j = 1, columns do
			Matrix.data[i][j] = elements[(i-1)* columns + j]
		end
	end

	setmetatable(Matrix, Matrices)
	
	return Matrix
end

--Used to construct a n by m matrix with random cells in range [-1, 1]
--that is:
--			Matrices.random(n, m)
--
--	@rows: the number of rows
--	@columns: the number of columns
--
-- returns a new matrix of size n by m with cells initialized to random values in range [-1, 1]
function Matrices.random(rows: number, columns: number): MatrixType
	local randomElements = {}
	
	for i = 1, rows * columns do
		table.insert(randomElements, math.random() * 2 - 1)
	end
	
	return Matrices.new(rows, columns, randomElements)
end
--Used to transpose two matrices. Nonmutating
--that is:
--			Matrix:transpose()
--
-- returns a new transposed matrix
function Matrices:transpose(): MatrixType
	local transposed = {}
	for i = 1, self.rows do
		for j = 1, self.columns do
			transposed[i+(j-1)*self.rows] =  self[i][j]
		end
	end

	return Matrices.new(self.columns, self.rows, transposed)
end
--Used to map a function onto each element in a matrix. Nonmutating
--that is:
--			Matrix:map(function(x) return x + 1 end)
--
--	@func: the function to be applied to each element in the matrix
--
-- returns a new matrix with the same dimensions as the original with each element
function Matrices:map(func: (cell: number, row: number, column: number, args: {any}) -> (number), args: {any}): MatrixType
	local new = {}
	for i = 1, self.rows do
		for j = 1, self.columns do
			table.insert(new, func(self[i][j], i, j, args))
		end
	end
	return Matrices.new(self.rows, self.columns, new)
end
--Used to multiply two matrices in parallel. Yields until each row is finished. Nonmutating
--that is:
--			Matrix:multiplyParallel(m2)
--
--	@m2: the matrix to be multiplied with
--
-- returns a new matrix that is the product of m1 and m2
function Matrices:multiplyParallel(m2)
	local start = os.clock()
	assert(self.columns == m2.rows, "Incompatible matrices")
	local multipliedMatrix = Matrices.new(self.rows, m2.columns, table.create(self.rows * m2.columns,0))
	
	for WorkerIndex, Actor in WORKERS do
		Actor:SendMessage("MultiplyMatrix", self.data, m2.data, self.columns, m2.columns, multipliedMatrix.data, self.rows, FinishedFlags, WorkerIndex, NUM_OF_ACTORS)
	end
	print(os.clock() - start)
	while not CheckFlags() do task.wait() end

	return multipliedMatrix
end

--Used to add two matrices. Mutating
--that is:
--			Matrix:mutatingAdd(m2)
--
--	@m2: the matrix to be added
--
-- returns the new matrix
function Matrices:mutatingAdd(m2: MatrixType): MatrixType
	assert(self.rows == m2.rows and self.columns == m2.columns, "Matrices must have the same dimensions to be added")
	for i = 1, self.rows do
		for j = 1, self.columns do
			self[i][j] += m2[i][j]
		end
	end
	return self
end
--Used to subtract two matrices. Mutating
--that is:
--			Matrix:mutatingSubtract(m2)
--
--	@m2: the matrix to be subtracted
--
-- returns the new matrix
function Matrices:mutatingSubtract(m2: MatrixType): MatrixType
	assert(self.rows == m2.rows and self.columns == m2.columns, "Matrices must have the same dimensions to be subtracted")
	for i = 1, self.rows do
		for j = 1, self.columns do
			self[i][j] -= m2[i][j]
		end
	end
	return self
end
--Used to multiply matrices by a scalar. Mutating
--that is:
--			Matrix:mutatingScalarMultiply(k)
--
--	@k: scalar
--
-- returns the new matrix
function Matrices:mutatingScalarMultiply(k: number): MatrixType
	assert(type(k) == "number", "Attempt to multiply by type "..k)
	for i = 1, self.rows do
		for j = 1, self.columns do
			self[i][j] *= k
		end
	end
	return self
end

return Matrices
