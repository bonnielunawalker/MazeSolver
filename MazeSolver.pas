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
	solved: Boolean;
end;

type RandomMouse = record
	currentCell: Cell;
	move, previousMove: Direction;
	solved: Boolean;
end;

type WallFollower = record
	currentCell: Cell;
	move, previousMove: Direction;
	solved: Boolean;
end;


//
// Forward subroutine declarations.
// Allows subroutines to be laid out in a more logical manner in the body of the program.
//
procedure InitialiseGrid(var grid: MazeGrid); forward;
function FindUnchecked(const wallArray: CellGrid): Boolean; forward;
function RangeCheck(col, row: Integer): Boolean; forward;
function CheckCellStatus(const grid: MazeGrid; col, row: Integer): Boolean; forward;
procedure GetRandomCell(const grid: MazeGrid; var cell: Cell); forward;
function CheckNeighbourCells(const grid: MazeGrid; col, row: Integer): Integer; forward;
procedure AddCell(var wallArray: CellGrid; col, row: Integer); forward;
procedure AddWalls(var wallArray: CellGrid; col, row: Integer); forward;
function InList(col, row: Integer; const list: array of Cell): Boolean; forward;
procedure DrawMaze(const grid: MazeGrid; const targetCell, primCell: Cell; const aStarEntity: AStar; const randomMouseEntity: RandomMouse; const wallFollowerEntity: WallFollower; drawAStar: Boolean); forward;
procedure GenerateMaze(var grid: MazeGrid; var startingCell: Cell; const aStarEntity: AStar; const randomMouseEntity: RandomMouse; const wallFollowerEntity: WallFollower); forward;
function CheckMoveValid(grid: MazeGrid; col, row: Integer; dir: Direction): Boolean; forward;
function Manhattan(const grid: MazeGrid; const cell, targetCell: Cell): Integer; forward;
function GetFScore(const grid: MazeGrid; const cell: Cell; const targetCell: Cell): Integer; forward;
function GetPriorityCell(const grid: MazeGrid; var aStarEntity: AStar; const targetCell: Cell): Cell; forward;
procedure AddToOpen(col, row: Integer; const parent: Cell; var aStarEntity: AStar); forward;
procedure AddNeighboursToOpen(const grid: MazeGrid; const cell: Cell; var aStarEntity: AStar); forward;
procedure AddToClosed(const cell: Cell; var aStarEntity: AStar); forward;
function GetDirection(constref currentCell, parent: Cell): Direction; forward;
procedure GetPath(var aStarEntity: AStar); forward;
procedure MoveAStar(const grid: MazeGrid; const targetCell: Cell; var aStarEntity: AStar); forward;
procedure SolveMaze(const grid: MazeGrid; const targetCell: Cell; var aStarEntity: Astar; const randomMouseEntity: RandomMouse; const wallFollowerEntity: WallFollower); forward;
function GetRandomMove(): Direction; forward;
procedure MoveMouse(const grid: MazeGrid; const targetCell: Cell; var randomMouseEntity: RandomMouse); forward;
procedure FindMouseMove(constref grid: MazeGrid; const targetCell: Cell; var randomMouseEntity: RandomMouse); forward;
procedure MoveWallFollower(var wallFollowerEntity: WallFollower; dir: Direction); forward;
procedure FindWallFollowerMove(constref grid: MazeGrid; const targetCell: Cell; var wallFollowerEntity: WallFollower); forward;
function CheckCellTarget(const targetCell, cell: Cell): Boolean; forward;


//
// MODULAR SUBROUTINES
// These are subroutines that are used many times in the program.
//


// Checks to see if the cell passed to it is actually within the bounds of the maze area.
// This function is a single line and isn't absolutely necessary, but improves readibility of various constrol structures.
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
		// Adding one to the col and row values prevents the cell from being positioned at col/row 0, which crashes the program.
		// Subtracting 2 from the possible range prevents the cell from being positioned on the upper bounds of the grid, which has the same result as above.
		cell.col := Random(COLUMNS - 2) + 1;
		cell.row := Random(ROWS - 2) + 1;
	end;
	until grid[cell.col, cell.row];
end;


//
// Modular procedure that returns whether a cell exists within an array.
//
function InList(col, row: Integer; const list: array of Cell): Boolean;
var
	i: Integer;
begin
	result := false;
	for i := 0 to High(list) do
		if (list[i].col = col) and (list[i].row = row) then
			result := true;
end;


//
// Checks if the current cell is the target cell.
//
function CheckCellTarget(const targetCell, cell: Cell): Boolean;
begin
	if (cell.col = targetCell.col) and (cell.row = targetCell.row) then
		result := true
	else
		result := false;
end;


//
// Draws the SwinGame representation of the maze.
// This procedure accepts some redundant parameters (such as primCell when Prim's algorithm has already been generated).
// While this approach may not be ideal, it avoids duplicating the procedure for use in different parts of the program.
//
procedure DrawMaze(const grid: MazeGrid; const targetCell, primCell: Cell; const aStarEntity: AStar; const randomMouseEntity: RandomMouse; const wallFollowerEntity: WallFollower; drawAStar: Boolean);
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

			// Highlights the currently selected Prim's algorithm cell in light blue.
			if (col = primCell.col) and (row = primCell.row) then
				FillRectangle(ColorSkyBlue, x, y, CELL_WIDTH, CELL_WIDTH)

			// Colours open cells white.
			else if grid[col, row] = true then
				FillRectangle(ColorWhite, x, y, CELL_WIDTH, CELL_WIDTH);

			if drawAStar then
			begin
				// Highlights cells in the closed list in grey.
				if InList(col, row, aStarEntity.closed) then
					FillRectangle(ColorGray, x, y, CELL_WIDTH, CELL_WIDTH)

				// Highlights cells in the open list in light blue.
				else if InList(col, row, aStarEntity.open) then
					FillRectangle(ColorSkyBlue, x, y, CELL_WIDTH, CELL_WIDTH);
			end;

		// Highlights the target cell in Red.
		if (col = targetCell.col) and (row = targetCell.row) then
			FillRectangle(ColorRed, x, y, CELL_WIDTH, CELL_WIDTH);

		// Highlights the current A* cell in light green.
		if (col = aStarEntity.currentCell.col) and (row = aStarEntity.currentCell.row) then
			FillRectangle(ColorLimeGreen, x, y, CELL_WIDTH, CELL_WIDTH)

		// Highlights the current wall follower cell in orange.
		else if (col = wallFollowerEntity.currentCell.col) and (row = wallFollowerEntity.currentCell.row) then
			FillRectangle(ColorOrange, x, y, CELL_WIDTH, CELL_WIDTH)

		// Highlights the current random mouse cell in blue.
		else if (col = randomMouseEntity.currentCell.col) and (row = randomMouseEntity.currentCell.row) then
			FillRectangle(ColorBlue, x, y, CELL_WIDTH, CELL_WIDTH)
		end;
	end;
	RefreshScreen(60);
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
// NONMODULAR SUBROUTINES
// These subroutines provide specific functionality or have limited use.
//


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
// Finds the cell in the open list with the lowest f score.
//
function GetPriorityCell(const grid: MazeGrid; var aStarEntity: AStar; const targetCell: Cell): Cell;
var
	i, score, lowestScore: Integer;
begin
	// Defaults lowestScore to highest possible score.
	lowestScore := COLUMNS * ROWS;
	for i := 0 to High(aStarEntity.open) do
	begin
		score := GetFScore(grid, aStarEntity.open[i], targetCell);
		if (score <= lowestScore) and not (InList(aStarEntity.open[i].col, aStarEntity.open[i].row, aStarEntity.closed)) then
		begin
			lowestScore := score;
			result := aStarEntity.open[i];
		end;
	end;
end;


//
// Returns f(n) = g(n) + h(n) for the given cell.
//
function GetFScore(const grid: MazeGrid; const cell: Cell; const targetCell: Cell): Integer;
begin
	result := cell.gScore + Manhattan(grid, cell, targetCell);
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
// Generates the maze layout.
//
procedure GenerateMaze(var grid: MazeGrid; var startingCell: Cell; const aStarEntity: AStar; const randomMouseEntity: RandomMouse; const wallFollowerEntity: WallFollower);
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
		DrawMaze(grid, startingCell, wallArray[randomCell], aStarEntity, randomMouseEntity, wallFollowerEntity, false);
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
			AddWalls(wallArray, col, row);
		end
		else
			grid[col, row] := false;

		wallArray[randomCell].checked := true;
	until not (FindUnchecked(wallArray)) or (WindowCloseRequested());
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
// Find the solution for the maze using the A* algorithm.
//
procedure SolveMaze(const grid: MazeGrid; const targetCell: Cell; var aStarEntity: Astar; const randomMouseEntity: RandomMouse; const wallFollowerEntity: WallFollower);
var
	solved: Boolean;
	priorityCell: Cell;
begin
	aStarEntity.currentCell.gScore := 0;
	WriteLn('Done! Starting cell is ', aStarEntity.currentCell.col, ', ', aStarEntity.currentCell.row);

	WriteLn('Adding first cell to closed list.');
	SetLength(aStarEntity.closed, 1);
	aStarEntity.closed[0].col := aStarEntity.currentCell.col;
	aStarEntity.closed[0].row := aStarEntity.currentCell.row;
	aStarEntity.closed[0].gScore := aStarEntity.currentCell.gScore;
	WriteLn('Done!');

	WriteLn('Adding neighbours to open.');
	AddNeighboursToOpen(grid, aStarEntity.currentCell, aStarEntity);
	WriteLn('New length of open list is ', Length(aStarEntity.open));
	WriteLn('Done!');

	solved := false;

	repeat
		ProcessEvents();
		priorityCell := GetPriorityCell(grid, aStarEntity, targetCell);
		WriteLn('New priority cell is ', priorityCell.col, ', ', priorityCell.row);

		AddToClosed(priorityCell, aStarEntity);
		if (priorityCell.col = targetCell.col) and (priorityCell.row = targetCell.row) then
			solved := true;
		AddNeighboursToOpen(grid, aStarEntity.closed[High(aStarEntity.closed)], aStarEntity);
		DrawMaze(grid, targetCell, aStarEntity.currentCell, aStarEntity, randomMouseEntity, wallFollowerEntity, true);
		Delay(75);
	until (solved) or (WindowCloseRequested());
	WriteLn('Maze solved. Now getting path.');
	GetPath(aStarEntity);
	aStarEntity.moveIndex := High(aStarEntity.moveList);
end;



//
// Adds a cell to the open list and sets its parent.
//
procedure AddToOpen(col, row: Integer; const parent: Cell; var aStarEntity: AStar);
begin
	SetLength(aStarEntity.open, Length(aStarEntity.open) + 1);
	aStarEntity.open[High(aStarEntity.open)].col := col;
	aStarEntity.open[High(aStarEntity.open)].row := row;
	aStarEntity.open[High(aStarEntity.open)].gScore := parent.gScore + 1;
	aStarEntity.open[High(aStarEntity.open)].parent := @parent;
end;


//
// Adds a cell's neighbour cells to the open list.
//
procedure AddNeighboursToOpen(const grid: MazeGrid; const cell: Cell; var aStarEntity: AStar);
begin
	if (CheckMoveValid(grid, cell.col, cell.row, North)) and not (InList(cell.col - 1, cell.row, aStarEntity.open)) then
		AddToOpen(cell.col - 1, cell.row, cell, aStarEntity);

	if (CheckMoveValid(grid, cell.col, cell.row, East)) and not (InList(cell.col, cell.row + 1, aStarEntity.open)) then
		AddToOpen(cell.col, cell.row + 1, cell, aStarEntity);

	if (CheckMoveValid(grid, cell.col, cell.row, South))  and not (InList(cell.col + 1, cell.row, aStarEntity.open)) then
		AddToOpen(cell.col + 1, cell.row, cell, aStarEntity);

	if (CheckMoveValid(grid, cell.col, cell.row, West))  and not (InList(cell.col, cell.row - 1, aStarEntity.open)) then
		AddToOpen(cell.col, cell.row - 1, cell, aStarEntity);
end;


//
// Adds a given cell to the closed list.
//
procedure AddToClosed(const cell: Cell; var aStarEntity: AStar);
begin
	SetLength(aStarEntity.closed, Length(aStarEntity.closed) + 1);
	aStarEntity.closed[High(aStarEntity.closed)].col := cell.col;
	aStarEntity.closed[High(aStarEntity.closed)].row := cell.row;
	New(aStarEntity.closed[High(aStarEntity.closed)].parent);
	aStarEntity.closed[High(aStarEntity.closed)].parent^ := cell.parent^;
	aStarEntity.closed[High(aStarEntity.closed)].gScore := cell.gScore;
end;


//
// Moves the random mouse entity around the maze.
//
procedure MoveMouse(const grid: MazeGrid; const targetCell: Cell; var randomMouseEntity: RandomMouse);
begin
	if randomMouseEntity.move = North then
		randomMouseEntity.currentCell.col := randomMouseEntity.currentCell.col - 1
	else if randomMouseEntity.move = East then
		randomMouseEntity.currentCell.row := randomMouseEntity.currentCell.row + 1
	else if randomMouseEntity.move = South then
		randomMouseEntity.currentCell.col := randomMouseEntity.currentCell.col + 1
	else if randomMouseEntity.move = West then
		randomMouseEntity.currentCell.row := randomMouseEntity.currentCell.row - 1;

	if (randomMouseEntity.currentCell.row = targetCell.row) and (randomMouseEntity.currentCell.col = targetCell.col) then
		randomMouseEntity.solved := true;
end;


function OppositeMove(dir: Direction): Direction;
begin
	if dir = North then
		result := South
	else if dir = East then
		result := West
	else if dir = South then
		result := North
	else if dir = West then
		result := East
	else
		result := None;
end;


//
// Moves the random mouse entity around the grid.
//
procedure FindMouseMove(constref grid: MazeGrid; const targetCell: Cell; var randomMouseEntity: RandomMouse);
begin
	if randomMouseEntity.move = None then
	begin
		// Get the random mouse's initial move.
		repeat
			randomMouseEntity.move := GetRandomMove();
		until checkMoveValid(grid, randomMouseEntity.currentCell.col, randomMouseEntity.currentCell.row, randomMouseEntity.move);
	end

	// Checks if the entity has reached a junction.
	else if CheckNeighbourCells(grid, randomMouseEntity.currentCell.col, randomMouseEntity.currentCell.row) > 2 then
	begin
		repeat
			randomMouseEntity.move := GetRandomMove();
		until (randomMouseEntity.move <> OppositeMove(randomMouseEntity.previousMove)) and CheckMoveValid(grid, randomMouseEntity.currentCell.col, randomMouseEntity.currentCell.row, randomMouseEntity.move);
	end

	// Checks if the entity has reached a dead end.
	else if CheckNeighbourCells(grid, randomMouseEntity.currentCell.col, randomMouseEntity.currentCell.row) = 1 then
		randomMouseEntity.move := OppositeMove(randomMouseEntity.previousMove)

	// Checks if the entity has reached corner that isn't a junction.
	else if not CheckMoveValid(grid, randomMouseEntity.currentCell.col, randomMouseEntity.currentCell.row, randomMouseEntity.move) then
	begin
		repeat
			randomMouseEntity.move := GetRandomMove;
		until (randomMouseEntity.move <> OppositeMove(randomMouseEntity.previousMove)) and CheckMoveValid(grid, randomMouseEntity.currentCell.col, randomMouseEntity.currentCell.row, randomMouseEntity.move);
	end;

	// If none of the above conditions are met, the mouse continues moving in its current direction.
	MoveMouse(grid, targetCell, randomMouseEntity);

	randomMouseEntity.previousMove := randomMouseEntity.move;
end;


//
// Generates a radnom direction.
//
function GetRandomMove(): Direction;
var
	rand: Integer;
begin
	rand := Random(4);
	if rand = 0 then
		result := North
	else if rand = 1 then
		result := East
	else if rand = 2 then
		result := South
	else if rand = 3 then
		result := West;
end;


//
// Moves the A* entity around the maze.
//
procedure MoveAStar(const grid: MazeGrid; const targetCell: Cell; var aStarEntity: AStar);
begin
	if aStarEntity.moveList[aStarEntity.moveIndex] = North then
		aStarEntity.currentCell.col := aStarEntity.currentCell.col - 1
	else if aStarEntity.moveList[aStarEntity.moveIndex] = East then
		aStarEntity.currentCell.row := aStarEntity.currentCell.row + 1
	else if aStarEntity.moveList[aStarEntity.moveIndex] = South then
		aStarEntity.currentCell.col := aStarEntity.currentCell.col + 1
	else if aStarEntity.moveList[aStarEntity.moveIndex] = West then
		aStarEntity.currentCell.row := aStarEntity.currentCell.row - 1;

	if (aStarEntity.currentCell.row = targetCell.row) and (aStarEntity.currentCell.col = targetCell.col) then
		aStarEntity.solved := true;
	aStarEntity.moveIndex := aStarEntity.moveIndex - 1;
end;


//
// Traces the route to the target node back through pointers and adds the moves needed to an array.
//
procedure GetPath(var aStarEntity: AStar);
var
	i, totalMoves: Integer;
	currentCell: Cell;
begin
	currentCell :=  aStarEntity.closed[High(aStarEntity.closed)];
	totalMoves := currentCell.gScore - 1;

	for i := 0 to totalMoves do
	begin
		WriteLn('Getting move ', i);
		SetLength(aStarEntity.moveList, Length(aStarEntity.moveList) + 1);
		aStarEntity.moveList[High(aStarEntity.moveList)] := GetDirection(currentCell, currentCell.parent^);
		WriteLn('Current cells parent is at ', currentCell.parent^.col, ', ', currentCell.parent^.row);
		currentCell := currentCell.parent^;
	end;
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
	else
	begin
		WriteLn('ERROR :: COULD NOT FIND MOVE!');
		WriteLn(parent.col, ', ', parent.row)
	end;
end;


//
// Finds the next move for the wall follower entity.
//
procedure FindWallFollowerMove(constref grid: MazeGrid; const targetCell: Cell; var wallFollowerEntity: WallFollower);
begin
	if CheckNeighbourCells(grid, wallFollowerEntity.currentCell.col, wallFollowerEntity.currentCell.row) > 2 then
	begin
		if CheckMoveValid(grid, wallFollowerEntity.currentCell.col, wallFollowerEntity.currentCell.row, North) then
			MoveWallFollower(wallFollowerEntity, North)
		else if CheckMoveValid(grid, wallFollowerEntity.currentCell.col, wallFollowerEntity.currentCell.row, East) then
			MoveWallFollower(wallFollowerEntity, East)
		else if CheckMoveValid(grid, wallFollowerEntity.currentCell.col, wallFollowerEntity.currentCell.row, South) then
			MoveWallFollower(wallFollowerEntity, South)
		else
			MoveWallFollower(wallFollowerEntity, West);
	end;

	else if CheckNeighbourCells(grid, wallFollowerEntity.currentCell.col, wallFollowerEntity.currentCell.row) = 1 then
		

end;


procedure MoveWallFollower(var wallFollowerEntity: WallFollower; dir: Direction);
begin
	if dir = North then
		wallFollowerEntity.currentCell.col := wallFollowerEntity.currentCell.col - 1
	else if dir = East then
		wallFollowerEntity.currentCell.row := wallFollowerEntity.currentCell.row + 1
	else if dir = South then
		wallFollowerEntity.currentCell.col := wallFollowerEntity.currentCell.col + 1
	else if dir = West then
		wallFollowerEntity.currentCell.row := wallFollowerEntity.currentCell.row - 1;
end;


//
// Main procedure.
//
procedure Main();
var
	grid: MazeGrid;
	targetCell: Cell;
	aStarEntity: AStar;
	randomMouseEntity: RandomMouse;
	wallFollowerEntity: WallFollower;
begin
	Randomize();

	// Defaults entity positions to be out of the grid, to avoid them being drawn when the maze is being generated.
	aStarEntity.currentCell.col := -1;
	aStarEntity.currentCell.row := -1;
	randomMouseEntity.currentCell.col := -1;
	randomMouseEntity.currentCell.row := -1;

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
	// Entities are passed into this procedure, as they are required for the DrawMaze procedure.
	GenerateMaze(grid, targetCell, aStarEntity, randomMouseEntity, wallFollowerEntity);
	WriteLn('Done!');

	repeat
		// Get random starting positions for entities and initialises their moves.
		GetRandomCell(grid, aStarEntity.currentCell);
		GetRandomCell(grid, randomMouseEntity.currentCell);
		randomMouseEntity.move := None;
		GetRandomCell(grid, wallFollowerEntity.currentCell);

	// This check avoids edge cases in which entities start on the target cell.
	until not (CheckCellTarget(targetCell, aStarEntity.currentCell)) and not (CheckCellTarget(targetCell, randomMouseEntity.currentCell)) and not (CheckCellTarget(targetCell, wallFollowerEntity.currentCell));

	WriteLn('Solving maze.');
	SolveMaze(grid, targetCell, aStarEntity, randomMouseEntity, wallFollowerEntity);
	WriteLn('Done!');

	aStarEntity.solved := false;
	randomMouseEntity.solved := false;
	wallFollowerEntity.solved := false;

	// Get the wall follower's initial move.
	repeat
		wallFollowerEntity.move := GetRandomMove();
	until checkMoveValid(grid, wallFollowerEntity.currentCell.col, wallFollowerEntity.currentCell.row, wallFollowerEntity.move);

	repeat
		MoveAStar(grid, targetCell, aStarEntity);
		FindMouseMove(grid, targetCell, randomMouseEntity);
		FindWallFollowerMove(grid, targetCell, wallFollowerEntity);
		DrawMaze(grid, targetCell, aStarEntity.currentCell, aStarEntity, randomMouseEntity, wallFollowerEntity, false);
		Delay(500);
	until (aStarEntity.solved) or (randomMouseEntity.solved) or (WindowCloseRequested());

	if aStarEntity.solved then
		WriteLn('The A* entity solved the maze.');
	if randomMouseEntity.solved then
		WriteLn('The random mouse entity solved the maze.');
	if wallFollowerEntity.solved then
		WriteLn('The wall follower entity solved the maze.');

	Delay(1000);
end;


begin
  Main();
end.
