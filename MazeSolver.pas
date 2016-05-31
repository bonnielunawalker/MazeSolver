program MazeSolver;
uses SwinGame, sgTypes;

const
	COLUMNS = 25;
	ROWS = 25;
	CELL_WIDTH = 16;
	CELL_GAP = 1;

type
	CellPtr = ^Cell;
	Cell = record
	row, col, fScore, gScore, hScore: Integer;
	checked: Boolean;
	parent: CellPtr;
end;

// MazeGrid is used to determine whether a cell is a wall or open space.
type MazeGrid = array [0..COLUMNS - 1, 0..ROWS - 1] of Boolean;

// CellGrid is used by algorithms to differentiate between cells that have already been processed, and cells in the queue yet to be processed.
type CellGrid = array of Cell;

type Direction = (None, North, East, South, West);

type AStar = record
	open, closed: array of Cell;
	currentCell: Cell;
	move: Direction;
	moveList: array of Direction;
	moveIndex: Integer;
end;

type Player = record
	move: Direction;
	currentCell: Cell;
	playerNumber: Integer;
end;


//
// Sets all cells to be walls to avoid junk values changing interfering with the generation algorithm.
//
procedure InitialiseGrid(var grid: MazeGrid);
var
	col, row: Integer;
begin
	for col := 0 to COLUMNS - 1 do
		for row := 0 to ROWS - 1 do
			grid[col, row] := false;
end;


//
// Returns true if ANY cell in wallArray has not been checked yet.
//
function FindUnchecked(const wallArray: CellGrid): Boolean;
var
	i: Integer;
begin
	for i := 0 to High(wallArray) do
		if wallArray[i].checked = false then
			result := true;
end;


//
// Checks to see if the cell passed to it is actually within the bounds of the maze area.
// This function is a single line and isn't absolutely necessary, but improves readibility of various checks.
//
function RangeCheck(col, row: Integer): Boolean;
begin
	result := (col >= 0) and (col < COLUMNS) and (row >= 0) and (row < ROWS);
end;


//
// Returns true if the cell is part of the maze (ie. not a confirmed wall).
//
function CheckCellStatus(const grid: MazeGrid; col, row: Integer): Boolean;
begin
	if (RangeCheck(col, row)) and (grid[col, row]) then
		result := true
	else
		result := false;
end;


//
// Generates a random open cell.
//
procedure GetRandomCell(const grid: MazeGrid; var cell: Cell);
begin
	repeat
	begin
		cell.col := Random(COLUMNS);
		cell.row := Random(ROWS);
	end;
	until grid[cell.col, cell.row];
end;


//
// Returns the number of neighbouring cells that are not walls.
//
function CheckNeighbourCells(const grid: MazeGrid; col, row: Integer): Integer;
var
	neighbours: Integer;
begin
	neighbours := 0;

	if CheckCellStatus(grid, col + 1, row) then
		neighbours := neighbours + 1;
	if CheckCellStatus(grid, col - 1, row) then
		neighbours := neighbours + 1;
	if CheckCellStatus(grid, col, row + 1) then
		neighbours := neighbours + 1;
	if CheckCellStatus(grid, col, row - 1) then
	neighbours := neighbours + 1;

	result := neighbours;
end;


//
// Adds an individual cell to the wall array.
//
procedure AddCell(var wallArray: CellGrid; col, row: Integer);
var
	i: Integer;
begin
	if RangeCheck(col, row) then
	begin
		for i := 0 to High(wallArray) do
		begin
			// Checks if the current cell is already on the list of cells to avoid duplication.
			if (wallArray[i].col = col) and (wallArray[i].row = row) then
				exit;
		end;

		SetLength(wallArray, Length(wallArray) + 1);
		wallArray[High(wallArray)].col := col;
		wallArray[High(wallArray)].row := row;
		wallArray[High(wallArray)].checked := false;
	end;
end;


//
// Adds the cells surrounding a cell (not including diagonals) to an array of walls.
//
procedure AddWalls(var wallArray: CellGrid; col, row: Integer);
begin
	AddCell(wallArray, col + 1, row);
	AddCell(wallArray, col - 1, row);
	AddCell(wallArray, col, row + 1);
	AddCell(wallArray, col, row - 1);
end;


//
// Searches a list for the given cell.
//
function InList(col, row: Integer; const list: array of Cell): Boolean;
var
	i: Integer;
begin
	result := false;
	for i := 0 to High(list) do
	begin
		if (list[i].col = col) and (list[i].row = row) then
			result := true
	end;
end;


//
// Draws the SwinGame representation of the maze.
//
procedure DrawMaze(const grid: MazeGrid; const targetCell, primCell: Cell; constref aStarSolver: AStar; constref player1, player2: Player; drawAStar: Boolean);
var
	col, row, x, y: Integer;
begin

	ClearScreen(ColorBlack);
	for col := 0 to COLUMNS - 1 do
	begin
		for row := 0 to ROWS - 1 do
		begin
			y := col * (CELL_WIDTH + CELL_GAP);
			x := row * (CELL_WIDTH + CELL_GAP);

			if drawAStar then
			begin
				// Highlights cells in the closed list in grey.
				if InList(col, row, aStarSolver.closed) then
					FillRectangle(ColorGray, x, y, CELL_WIDTH, CELL_WIDTH)

				// Highlights cells in the open list in light blue.
				else if InList(col, row, aStarSolver.open) then
					FillRectangle(ColorSkyBlue, x, y, CELL_WIDTH, CELL_WIDTH)
			end;

			// Highlights the target cell in Red.
			if (col = targetCell.col) and (row = targetCell.row) then
				FillRectangle(ColorRed, x, y, CELL_WIDTH, CELL_WIDTH)

			// Highlights the current A* cell in light green.
			else if (col = aStarSolver.currentCell.col) and (row = aStarSolver.currentCell.row) then
				FillRectangle(ColorLimeGreen, x, y, CELL_WIDTH, CELL_WIDTH)

			// Highlights the currently selected Prim's algorithm cell in light blue.
			else if (col = primCell.col) and (row = primCell.row) then
				FillRectangle(ColorSkyBlue, x, y, CELL_WIDTH, CELL_WIDTH)

			// Colours player1's cell orange.
			else if (col = player1.currentCell.col) and (row = player1.currentCell.row) then
				FillRectangle(ColorOrange, x, y, CELL_WIDTH, CELL_WIDTH)

			// Colours open cells white.
			else if grid[col, row] = true then
				FillRectangle(ColorWhite, x, y, CELL_WIDTH, CELL_WIDTH)

			else
				continue;
		end;
	end;
	RefreshScreen(60);
end;


//
// Generates the maze layout.
//
procedure GenerateMaze(var grid: MazeGrid; var startingCell: Cell; constref aStarSolver: AStar; const player1, player2: Player);
var
	col, row, randomCell: Integer;
	wallArray: CellGrid;
begin
	SetLength(wallArray, 1);

	col := startingCell.col;
	row := startingCell.row;
	grid[col, row] := true;

	// Adds the starting cell to the wall array.
	wallArray[0].col := col;
	wallArray[0].row := row;
	wallArray[0].checked := true;

	AddWalls(wallArray, col, row);

	// Iterate over all cells until there are no unchecked cells left.
	repeat
		// Selects a random cell that has not been checked yet.
		repeat
			randomCell := Random(Length(wallArray));
		until not wallArray[randomCell].checked;

		col := wallArray[randomCell].col;
		row := wallArray[randomCell].row;

		// Adds the cell to the maze if it has less than 2 open neighbours.
		if CheckNeighbourCells(grid, col, row) < 2 then
		begin
			grid[col, row] := true;
			// Adds the walls of that cell to the list of cells that need to be checked.
			AddWalls(wallArray, col, row)
		end
		else
			grid[col, row] := false;

		wallArray[randomCell].checked := true;

		DrawMaze(grid, startingCell, wallArray[randomCell], aStarSolver, player1, player2, false);

	until not FindUnchecked(wallArray);
end;


//
// Checks if a given move is valid.
//
function CheckMoveValid(grid: MazeGrid; col, row: Integer; dir: Direction): Boolean;
begin
	if dir = North then
		result := (RangeCheck(col - 1, row)) and (grid[col - 1, row])
	else if dir = East then
		result := (RangeCheck(col, row + 1)) and (grid[col, row + 1])
	else if dir = South then
		result := (RangeCheck(col + 1, row)) and (grid[col + 1, row])
	else
		result := (RangeCheck(col, row - 1)) and (grid[col, row - 1]);
end;


//
// Returns the estimated number of moves needed to reach the target cell based on the Manhattan heuristic.
//
function Manhattan(const grid: MazeGrid; const cell, targetCell: Cell): Integer;
var
	cols, rows: Integer;
begin
	cols := Abs(cell.col - targetCell.col);
	rows := Abs(cell.row - targetCell.row);
	result := cols + rows;
end;


//
// Returns f(n) = g(n) + h(n) for the given cell.
//
function GetFScore(const grid: MazeGrid; const cell: Cell; const targetCell: Cell): Integer;
begin
	result := cell.gScore + Manhattan(grid, cell, targetCell);
end;


//
// Finds the cell in the open list with the lowest f score.
//
function GetPriorityCell(const grid: MazeGrid; var aStarSolver: AStar; const targetCell: Cell): Cell;
var
	i, score, lowestScore: Integer;
begin
	// Defaults lowestScore to highest possible score.
	lowestScore := COLUMNS * ROWS;
	for i := 0 to High(aStarSolver.open) do
	begin
		score := GetFScore(grid, aStarSolver.open[i], targetCell);
		// WriteLn(aStarSolver.open[i].col, aStarSolver.open[i].row, 's score is ', score, ', lowest score is ', lowestScore);
		// Delay(1000);
		if (score <= lowestScore) and not (InList(aStarSolver.open[i].col, aStarSolver.open[i].row, aStarSolver.closed)) then
		begin
			lowestScore := score;
			result := aStarSolver.open[i];
		end;
	end;
end;


//
// Adds a cell to the open list and sets its parent.
//
procedure AddToOpen(col, row: Integer; const parent: Cell; var aStarSolver: AStar);
begin
	// WriteLn('Adding cell ', col, ', ', row);
	SetLength(aStarSolver.open, Length(aStarSolver.open) + 1);
	aStarSolver.open[High(aStarSolver.open)].col := col;
	aStarSolver.open[High(aStarSolver.open)].row := row;
	aStarSolver.open[High(aStarSolver.open)].gScore := parent.gScore + 1;
	// New(aStarSolver.open[Length(aStarSolver.open) - 1].parent);
	aStarSolver.open[High(aStarSolver.open)].parent := @parent;
	// WriteLn('Done!');
end;


//
// Adds a cell's neighbour cells to the open list.
//
procedure AddNeighboursToOpen(const grid: MazeGrid; const cell: Cell; var aStarSolver: AStar);
begin
	if (CheckMoveValid(grid, cell.col, cell.row, North)) and not (InList(cell.col - 1, cell.row, aStarSolver.open)) then
		AddToOpen(cell.col - 1, cell.row, cell, aStarSolver);

	if (CheckMoveValid(grid, cell.col, cell.row, East)) and not (InList(cell.col, cell.row + 1, aStarSolver.open)) then
		AddToOpen(cell.col, cell.row + 1, cell, aStarSolver);

	if (CheckMoveValid(grid, cell.col, cell.row, South))  and not (InList(cell.col + 1, cell.row, aStarSolver.open)) then
		AddToOpen(cell.col + 1, cell.row, cell, aStarSolver);

	if (CheckMoveValid(grid, cell.col, cell.row, West))  and not (InList(cell.col, cell.row - 1, aStarSolver.open)) then
		AddToOpen(cell.col, cell.row - 1, cell, aStarSolver);
end;


//
// Adds a given cell to the closed list.
//
procedure AddToClosed(const cell: Cell; var aStarSolver: AStar);
begin
	SetLength(aStarSolver.closed, Length(aStarSolver.closed) + 1);
	aStarSolver.closed[High(aStarSolver.closed)].col := cell.col;
	aStarSolver.closed[High(aStarSolver.closed)].row := cell.row;
	New(aStarSolver.closed[High(aStarSolver.closed)].parent);
	aStarSolver.closed[High(aStarSolver.closed)].parent^ := cell.parent^;
	aStarSolver.closed[High(aStarSolver.closed)].gScore := cell.gScore;
end;


//
// Gets the direction of movement between 2 cells for the AStar algorithm.
// Direction is reversed since the algorithm will be traversing the array backwards.
//
function GetDirection(constref currentCell, parent: Cell): Direction;
begin
	if parent.row + 1 = currentCell.row then
		result := East
	else if parent.row - 1 = currentCell.row then
		result := West
	else if parent.col - 1 = currentCell.col then
		result := North
	else if parent.col + 1 = currentCell.col then
		result := South
end;


//
// Traces the route to the target node back through pointers and adds the moves needed to an array.
//
procedure GetPath(var aStarSolver: AStar);
var
	i, totalMoves: Integer;
	currentCell: Cell;
begin
	currentCell :=  aStarSolver.closed[High(aStarSolver.closed)];
	totalMoves := currentCell.gScore - 1;

	for i := 0 to totalMoves do
	begin
		WriteLn('Getting move ', i);
		SetLength(aStarSolver.moveList, Length(aStarSolver.moveList) + 1);
		aStarSolver.moveList[High(aStarSolver.moveList)] := GetDirection(currentCell, currentCell.parent^);
		WriteLn('Current cells parent is at ', currentCell.parent^.col, ', ', currentCell.parent^.row);
		currentCell := currentCell.parent^;
	end;
end;


//
// Reads keyboard input and assigns the corresponding move direction to the player.
//
procedure GetPlayerMove(const grid: MazeGrid; var player: Player);
begin
	ProcessEvents();
	if player.playerNumber = 1 then
	begin
		if KeyDown(VK_UP) then
			player.move := North
		else if KeyDown(vk_RIGHT) then
			player.move := East
		else if KeyDown(vk_DOWN) then
			player.move := South
		else if KeyDown(vk_LEFT) then
			player.move := West
		else
			player.move := None;
	end

	else if player.playerNumber = 2 then
	begin
		if KeyDown(vk_w) then
			player.move := North
		else if KeyDown(vk_d) then
			player.move := East
		else if KeyDown(vk_s) then
			player.move := South
		else if KeyDown(vk_a) then
			player.move := West
		else
			player.move := None;
	end;
end;


//
// Moves player entities around the maze.
//
function MovePlayer(const grid: MazeGrid; const targetCell: Cell; var player: Player): Boolean;
begin
	// Assumes maze is not solved.
	result := false;

	repeat
		GetPlayerMove(grid, player);
	until (player.move <> None) or (WindowCloseRequested());

	if (player.move = North) and CheckMoveValid(grid, player.currentCell.col, player.currentCell.row, player.move) then
		player.currentCell.col := player.currentCell.col - 1
	else if (player.move = East) and CheckMoveValid(grid, player.currentCell.col, player.currentCell.row, player.move) then
		player.currentCell.row := player.currentCell.row + 1
	else if (player.move = South) and CheckMoveValid(grid, player.currentCell.col, player.currentCell.row, player.move) then
		player.currentCell.col := player.currentCell.col + 1
	else if (player.move = West) and CheckMoveValid(grid, player.currentCell.col, player.currentCell.row, player.move) then
		player.currentCell.row := player.currentCell.row - 1;

	if (player.currentCell.row = targetCell.row) and (player.currentCell.col = targetCell.col) then
		result := true;

	// Resets player move.
	player.move := None;
end;


//
// Moves the A* entity around the maze.
//
function MoveAStar(const grid: MazeGrid; const targetCell: Cell; var aStarSolver: AStar): Boolean;
begin
	// Assumes maze is not solved.
	result := false;

	if aStarSolver.moveList[aStarSolver.moveIndex] = North then
		aStarSolver.currentCell.col := aStarSolver.currentCell.col - 1
	else if aStarSolver.moveList[aStarSolver.moveIndex] = East then
		aStarSolver.currentCell.row := aStarSolver.currentCell.row + 1
	else if aStarSolver.moveList[aStarSolver.moveIndex] = South then
		aStarSolver.currentCell.col := aStarSolver.currentCell.col + 1
	else if aStarSolver.moveList[aStarSolver.moveIndex] = West then
		aStarSolver.currentCell.row := aStarSolver.currentCell.row - 1;

	if (aStarSolver.currentCell.row = targetCell.row) and (aStarSolver.currentCell.col = targetCell.col) then
		result := true;
	aStarSolver.moveIndex := aStarSolver.moveIndex - 1;
end;


//
// Find the solution for the maze using the A* algorithm.
//
procedure SolveMaze(const grid: MazeGrid; const targetCell: Cell; var aStarSolver: Astar);
var
	solved: Boolean;
	priorityCell: Cell;
begin
	WriteLn('Getting random starting cell for A*');
	GetRandomCell(grid, aStarSolver.currentCell);
	aStarSolver.currentCell.gScore := 0;
	WriteLn('Done! Starting cell is ', aStarSolver.currentCell.col, ', ', aStarSolver.currentCell.row);

	WriteLn('Adding first cell to closed list.');
	SetLength(aStarSolver.closed, 1);
	aStarSolver.closed[0].col := aStarSolver.currentCell.col;
	aStarSolver.closed[0].row := aStarSolver.currentCell.row;
	// New(aStarSolver.closed[0].parent);
	aStarSolver.closed[0].parent := @aStarSolver.currentCell;
	aStarSolver.closed[0].gScore := aStarSolver.currentCell.gScore;
	WriteLn('Done!');

	WriteLn('Adding neighbours to open.');
	AddNeighboursToOpen(grid, aStarSolver.currentCell, aStarSolver);
	WriteLn('New length of open list is ', Length(aStarSolver.open), '.');
	WriteLn('Done!');

	solved := false;

	repeat
	begin
		ProcessEvents();
		priorityCell := GetPriorityCell(grid, aStarSolver, targetCell);
		WriteLn('New priority cell is ', priorityCell.col, ', ', priorityCell.row);

		AddToClosed(priorityCell, aStarSolver);
		if (priorityCell.col = targetCell.col) and (priorityCell.row = targetCell.row) then
			solved := true;
		AddNeighboursToOpen(grid, aStarSolver.closed[High(aStarSolver.closed)], aStarSolver);
	end;
	until (solved) or (WindowCloseRequested());
	WriteLn('Maze solved. Now getting path.');
	GetPath(aStarSolver);
	aStarSolver.moveIndex := High(aStarSolver.moveList);
end;


//
// Main procedure.
//
procedure Main();
var
	grid: MazeGrid;
	targetCell: Cell;
	aStarSolver: AStar;
	player1, player2: Player;
	openArray, closedArray: CellGrid;
	mazeSolved: Boolean;
begin
	WriteLn('Opening window and setting up graphics.');
	OpenGraphicsWindow('Maze Solver', (COLUMNS * (CELL_WIDTH + CELL_GAP)), ROWS * (CELL_WIDTH + CELL_GAP));
	LoadDefaultColors();
	WriteLn('Done!');

	WriteLn('Generating target cell.');
	GetRandomCell(grid, targetCell);
	WriteLn('Done! Target cell is ', targetCell.col, ', ', targetCell.row);

	WriteLn('Initialising grid.');
	InitialiseGrid(grid);
	WriteLn('Done!');

	WriteLn('Generating Maze');
	GenerateMaze(grid, targetCell, aStarSolver, player1, player2);
	WriteLn('Done!');

	WriteLn('Solving maze.');
	SolveMaze(grid, targetCell, aStarSolver);
	WriteLn('Done!');


	player1.playerNumber := 1;
	player2.playerNumber := 2;
	WriteLn('Getting starting cell for player.');
	GetRandomCell(grid, player1.currentCell);
	WriteLn('Done!');

	mazeSolved := false;

	repeat
		mazeSolved := MoveAStar(grid, targetCell, aStarSolver);
		DrawMaze(grid, targetCell, aStarSolver.currentCell, aStarSolver, player1, player2, false);
		mazeSolved := MovePlayer(grid, targetCell, player1);
		DrawMaze(grid, targetCell, aStarSolver.currentCell, aStarSolver, player1, player2, false);
		Delay(100);
	until (mazeSolved) or (WindowCloseRequested());
end;


begin
	Main();
end.
